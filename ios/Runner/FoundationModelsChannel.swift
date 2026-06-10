// FoundationModelsChannel.swift
//
// Bridges Dart-side AppleFoundationModelsBackend (Flutter method channel) to
// Apple's on-device LanguageModel framework. Available iff:
//   - iOS 26+
//   - Device is Apple-Intelligence-eligible (iPhone 15 Pro / 16 / M-series iPad)
//
// Wire from AppDelegate.swift:
//
//   import Flutter
//   import UIKit
//
//   @main
//   @objc class AppDelegate: FlutterAppDelegate {
//     override func application(
//       _ application: UIApplication,
//       didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
//     ) -> Bool {
//       let controller = window?.rootViewController as! FlutterViewController
//       FoundationModelsChannel.register(with: controller)
//       GeneratedPluginRegistrant.register(with: self)
//       return super.application(application, didFinishLaunchingWithOptions: launchOptions)
//     }
//   }

import Flutter
import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

@available(iOS 26.0, macOS 26.0, *)
final class FoundationModelsChannel: NSObject {

    private static let channelName = "com.recapfreenote.recap/apple_foundation_models"

    static func register(with controller: FlutterViewController) {
        let channel = FlutterMethodChannel(
            name: channelName,
            binaryMessenger: controller.binaryMessenger
        )
        let handler = FoundationModelsChannel()
        channel.setMethodCallHandler { call, result in
            handler.handle(call: call, result: result)
        }
    }

    private func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "isAvailable":
            result(isAvailable())
        case "summarize":
            guard
                let args = call.arguments as? [String: Any],
                let prompt = args["prompt"] as? String
            else {
                result(FlutterError(code: "bad_args",
                                    message: "Missing prompt argument",
                                    details: nil))
                return
            }
            Task {
                do {
                    let text = try await summarize(prompt: prompt)
                    result(["text": text, "modelId": "apple-fm-3b"])
                } catch {
                    result(FlutterError(code: "fm_error",
                                        message: error.localizedDescription,
                                        details: nil))
                }
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Foundation Models calls

    private func isAvailable() -> Bool {
#if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            return SystemLanguageModel.default.availability == .available
        }
        return false
#else
        return false
#endif
    }

    private func summarize(prompt: String) async throws -> String {
#if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            let model = SystemLanguageModel.default
            guard model.availability == .available else {
                throw NSError(domain: "FoundationModelsChannel",
                              code: 1,
                              userInfo: [NSLocalizedDescriptionKey:
                                "Apple Intelligence not available on this device."])
            }
            let session = LanguageModelSession(model: model)
            let response = try await session.respond(to: prompt)
            return response.content
        }
        throw NSError(domain: "FoundationModelsChannel",
                      code: 2,
                      userInfo: [NSLocalizedDescriptionKey: "iOS 26+ required."])
#else
        throw NSError(domain: "FoundationModelsChannel",
                      code: 3,
                      userInfo: [NSLocalizedDescriptionKey:
                        "FoundationModels framework not available at build time."])
#endif
    }
}

// Convenience entry that works on any iOS deployment — checks availability
// at runtime so older devices can fall back to Gemma / cloud cleanly.
@objc final class FoundationModelsChannelBootstrap: NSObject {
    @objc static func register(with controller: FlutterViewController) {
        if #available(iOS 26.0, *) {
            FoundationModelsChannel.register(with: controller)
        } else {
            // Below iOS 26 — register a stub that always reports unavailable
            // so the Dart side falls through to the next backend (Gemma).
            let channel = FlutterMethodChannel(
                name: "com.recapfreenote.recap/apple_foundation_models",
                binaryMessenger: controller.binaryMessenger
            )
            channel.setMethodCallHandler { call, result in
                if call.method == "isAvailable" {
                    result(false)
                } else {
                    result(FlutterMethodNotImplemented)
                }
            }
        }
    }
}
