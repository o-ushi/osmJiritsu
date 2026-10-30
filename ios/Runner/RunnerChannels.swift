import Flutter
import UIKit

/// Registers app-owned method/event channels on the given engine messenger.
/// Safe to call more than once (e.g. implicit engine + scene fallback).
enum RunnerChannels {
  private static var registeredMessengers = Set<ObjectIdentifier>()
  private static let lock = NSLock()

  static func register(with messenger: FlutterBinaryMessenger) {
    lock.lock()
    defer { lock.unlock() }
    let id = ObjectIdentifier(messenger)
    guard !registeredMessengers.contains(id) else { return }
    registeredMessengers.insert(id)

    ICloudKVSyncChannel.register(with: messenger)
    IncomingUrlChannel.register(with: messenger)
  }
}

/// `osmjiritsu://new?theme=…` links handed to Dart on
/// `com.osamushikubo.osmjiritsu/incoming_url`.
///
/// A link that arrives before Dart asks (`takeInitialUrl`) is held and
/// handed over once, then forgotten; later links go straight to Dart as
/// `onUrl`. Parsing (scheme / host / theme) happens on the Dart side.
enum IncomingUrlChannel {
  private static let name = "com.osamushikubo.osmjiritsu/incoming_url"
  private static var channels: [FlutterMethodChannel] = []
  private static var pendingUrl: String?
  private static var dartReady = false

  static func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: name, binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "takeInitialUrl":
        dartReady = true
        let url = pendingUrl
        pendingUrl = nil
        result(url)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    channels.append(channel)
  }

  static func receive(_ url: URL) {
    guard url.scheme?.lowercased() == "osmjiritsu" else { return }
    let text = url.absoluteString
    if dartReady, !channels.isEmpty {
      for channel in channels {
        channel.invokeMethod("onUrl", arguments: text)
      }
    } else {
      pendingUrl = text
    }
  }
}

/// Receives `osmjiritsu://` links from UIKit. FlutterSceneDelegate /
/// FlutterAppDelegate forward these callbacks to registered receivers, so the
/// Runner's SceneDelegate and AppDelegate stay plain subclasses.
final class IncomingUrlReceiver: NSObject, FlutterPlugin, FlutterSceneLifeCycleDelegate {
  private static let shared = IncomingUrlReceiver()

  static func register(with registrar: FlutterPluginRegistrar) {
    registrar.addApplicationDelegate(shared)
    registrar.addSceneDelegate(shared)
  }

  // Cold start from a link.
  func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions?
  ) -> Bool {
    guard let url = connectionOptions?.urlContexts.first?.url else { return false }
    IncomingUrlChannel.receive(url)
    return false
  }

  // Already running.
  func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) -> Bool {
    var handled = false
    for context in URLContexts where context.url.scheme?.lowercased() == "osmjiritsu" {
      IncomingUrlChannel.receive(context.url)
      handled = true
    }
    return handled
  }

  // Fallback when the app runs without scenes.
  func application(
    _ application: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    guard url.scheme?.lowercased() == "osmjiritsu" else { return false }
    IncomingUrlChannel.receive(url)
    return true
  }
}
