import Flutter

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
  }
}
