import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let controller = window?.rootViewController as? FlutterViewController {
      FoundationModelsChannelBootstrap.register(with: controller)
      // Native ASR bridge — SFSpeechRecognizer on-device live captions.
      // The instance retains itself via the channel handlers; we don't need
      // to hold a strong reference here.
      if #available(iOS 13.0, *) {
        _ = AppleAsrBridge(messenger: controller.binaryMessenger)
      }
    }
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
