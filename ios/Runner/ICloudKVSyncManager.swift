import Flutter
import Foundation

/// iCloud KVS sync — ported from osmSolver's `ICloudKVSyncManager`
/// (itself mirroring osmPod's `ICloudSyncManager`), using
/// `NSUbiquitousKeyValueStore` to mirror the whole project library between
/// devices signed into the same iCloud account.
final class ICloudKVSyncManager {
  static let shared = ICloudKVSyncManager()

  private let kvStore = NSUbiquitousKeyValueStore.default
  private let dataKey = "osmJiritsu-sync-v1"
  private let timestampKey = "osmJiritsu-sync-v1-ts"
  private let maxBytes = 1_000_000

  private var eventSink: FlutterEventSink?

  private init() {}

  var isAvailable: Bool {
    FileManager.default.ubiquityIdentityToken != nil
  }

  func startObserving(eventSink: @escaping FlutterEventSink) {
    self.eventSink = eventSink
    NotificationCenter.default.addObserver(
      forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
      object: kvStore,
      queue: .main
    ) { [weak self] notification in
      guard let self else { return }
      let keys = notification.userInfo?[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String] ?? []
      guard keys.contains(self.dataKey) else { return }
      self.eventSink?("changed")
    }
    kvStore.synchronize()
  }

  func stopObserving() {
    eventSink = nil
    NotificationCenter.default.removeObserver(
      self,
      name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
      object: kvStore
    )
  }

  func synchronize() {
    kvStore.synchronize()
  }

  func accountStatus() -> String {
    isAvailable ? "available" : "noAccount"
  }

  /// `manualSync`: remote newer → download JSON, else upload local JSON.
  func manualSync(
    localJSON: String,
    localSyncReferenceTS: Double,
    completion: @escaping (Result<[String: Any], Error>) -> Void
  ) {
    guard isAvailable else {
      completion(.failure(ICloudKVSyncError.noAccount))
      return
    }

    kvStore.synchronize()
    let remoteTS = kvStore.double(forKey: timestampKey)

    if remoteTS > localSyncReferenceTS,
       let data = kvStore.data(forKey: dataKey),
       let remoteJSON = String(data: data, encoding: .utf8) {
      let syncedAt = Date().timeIntervalSinceReferenceDate
      DispatchQueue.main.async {
        completion(.success([
          "action": "download",
          "json": remoteJSON,
          "syncedAt": syncedAt,
        ]))
      }
      return
    }

    do {
      try upload(json: localJSON)
      let syncedAt = Date().timeIntervalSinceReferenceDate
      DispatchQueue.main.async {
        completion(.success([
          "action": "upload",
          "syncedAt": syncedAt,
        ]))
      }
    } catch {
      DispatchQueue.main.async { completion(.failure(error)) }
    }
  }

  func upload(json: String) throws {
    guard let data = json.data(using: .utf8) else {
      throw ICloudKVSyncError.invalidJSON
    }
    guard data.count < maxBytes else {
      throw ICloudKVSyncError.dataTooLarge(data.count)
    }
    kvStore.set(data, forKey: dataKey)
    kvStore.set(Date().timeIntervalSinceReferenceDate, forKey: timestampKey)
    kvStore.synchronize()
  }

  /// Removes only osmJiritsu's KVS payload. Local data and unrelated
  /// iCloud keys are intentionally untouched.
  func deleteCloudCopy() throws {
    guard isAvailable else {
      throw ICloudKVSyncError.noAccount
    }
    kvStore.removeObject(forKey: dataKey)
    kvStore.removeObject(forKey: timestampKey)
    kvStore.synchronize()
  }
}

enum ICloudKVSyncError: LocalizedError {
  case invalidJSON
  case dataTooLarge(Int)
  case noAccount

  var errorDescription: String? {
    switch self {
    case .invalidJSON:
      return "Invalid UTF-8 payload"
    case .dataTooLarge(let bytes):
      let mb = String(format: "%.1f", Double(bytes) / 1_000_000)
      return "Library data (\(mb) MB) exceeds the iCloud sync limit (1 MB)."
    case .noAccount:
      return "iCloud is not available. Sign in to iCloud in Settings."
    }
  }
}

enum ICloudKVSyncChannel {
  static func register(with messenger: FlutterBinaryMessenger) {
    let methodChannel = FlutterMethodChannel(
      name: "com.osamushikubo.osmjiritsu/icloud_sync",
      binaryMessenger: messenger
    )
    methodChannel.setMethodCallHandler { call, result in
      let manager = ICloudKVSyncManager.shared
      switch call.method {
      case "accountStatus":
        result(manager.accountStatus())

      case "manualSync":
        guard let args = call.arguments as? [String: Any],
              let localJSON = args["localJson"] as? String else {
          result(FlutterError(code: "BAD_ARGS", message: "Expected localJson", details: nil))
          return
        }
        let localTS = (args["localSyncReferenceTS"] as? NSNumber)?.doubleValue ?? 0
        manager.manualSync(localJSON: localJSON, localSyncReferenceTS: localTS) { outcome in
          switch outcome {
          case .success(let payload): result(payload)
          case .failure(let error): result(flutterError(error))
          }
        }

      case "upload":
        guard let json = call.arguments as? String else {
          result(FlutterError(code: "BAD_ARGS", message: "Expected JSON string", details: nil))
          return
        }
        do {
          try manager.upload(json: json)
          result(nil)
        } catch {
          result(flutterError(error))
        }

      case "deleteCloudCopy":
        do {
          try manager.deleteCloudCopy()
          result(nil)
        } catch {
          result(flutterError(error))
        }

      default:
        result(FlutterMethodNotImplemented)
      }
    }

    let eventChannel = FlutterEventChannel(
      name: "com.osamushikubo.osmjiritsu/icloud_sync_events",
      binaryMessenger: messenger
    )
    eventChannel.setStreamHandler(ICloudKVSyncStreamHandler())
  }

  private static func flutterError(_ error: Error) -> FlutterError {
    FlutterError(code: "ICLOUD_SYNC_ERROR", message: error.localizedDescription, details: nil)
  }
}

private final class ICloudKVSyncStreamHandler: NSObject, FlutterStreamHandler {
  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    ICloudKVSyncManager.shared.startObserving(eventSink: events)
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    ICloudKVSyncManager.shared.stopObserving()
    return nil
  }
}
