import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ application: UIApplication,
    supportedInterfaceOrientationsFor window: UIWindow?
  ) -> UIInterfaceOrientationMask {
    return .portrait
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    RunnerChannels.register(with: engineBridge.applicationRegistrar.messenger())
    // `osmjiritsu://` links: scene callbacks (cold start and already running)
    // and the app-delegate fallback, forwarded to IncomingUrlChannel.
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "IncomingUrlReceiver") {
      IncomingUrlReceiver.register(with: registrar)
    }
  }
}
