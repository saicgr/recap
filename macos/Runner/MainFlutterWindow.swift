import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    // Native bridges — system audio capture (ScreenCaptureKit) + Apple ASR
    // (SFSpeechRecognizer). Same bridge files shared with iOS where applicable.
    if #available(macOS 13.0, *) {
      _ = SystemAudioCapture(messenger: flutterViewController.engine.binaryMessenger)
    }

    super.awakeFromNib()
  }
}
