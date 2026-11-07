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
    configurationForConnecting connectingSceneSession: UISceneSession,
    options: UIScene.ConnectionOptions
  ) -> UISceneConfiguration {
    // 一度 SwiftUI.AppSceneDelegate で保存されたシーンは、Info.plist の
    // SceneDelegate を読まずに復元される。畳んだ外側画面はプロセスが生きたまま黒くなる。
    let configuration = UISceneConfiguration(
      name: connectingSceneSession.configuration.name ?? "flutter",
      sessionRole: connectingSceneSession.role
    )
    configuration.delegateClass = SceneDelegate.self
    configuration.storyboard = UIStoryboard(name: "Main", bundle: nil)
    return configuration
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
