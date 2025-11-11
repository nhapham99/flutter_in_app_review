import Flutter
import UIKit
import StoreKit

/// A Flutter plugin that provides access to Apple's in-app review and App Store listing.
///
/// This plugin allows Flutter apps to:
/// - Trigger the system in-app review prompt (`SKStoreReviewController`)
/// - Check if in-app review is available
/// - Open the App Store listing directly for manual reviews
///
/// The plugin communicates with Dart over a `MethodChannel` named:
/// `"dev.np.flutter_in_app_review"`.
public class InAppReviewPlugin: NSObject, FlutterPlugin {

    // MARK: - Registration

    /// Registers the plugin with the Flutter engine.
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "dev.np.flutter_in_app_review",
            binaryMessenger: registrar.messenger()
        )
        let instance = InAppReviewPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    // MARK: - Method Call Handling

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        log("handle", details: call.method)

        switch call.method {
        case "requestReview":
            requestReview(result)
        case "isAvailable":
            isAvailable(result)
        case "openStoreListing":
            openStoreListing(storeId: call.arguments as? String, result: result)
        default:
            log("method not implemented")
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Plugin Methods

    /// Requests an in-app review from the user.
    ///
    /// - Note:
    ///   - iOS 16+: Uses `AppStore.requestReview(in:)`
    ///   - iOS 14–15: Uses `SKStoreReviewController.requestReview(in:)`
    ///   - iOS 10.3–13: Uses `SKStoreReviewController.requestReview()`
    ///   - Below 10.3: Returns an error indicating unavailability.
    private func requestReview(_ result: @escaping FlutterResult) {
        if #available(iOS 16.0, *) {
            log("Request review - iOS 16+")
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                DispatchQueue.main.async {
                    AppStore.requestReview(in: scene)
                }
            }
            result(nil)

        } else if #available(iOS 14.0, *) {
            log("Request review - iOS 14+")
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                SKStoreReviewController.requestReview(in: scene)
            }
            result(nil)

        } else if #available(iOS 10.3, *) {
            log("Request review - iOS 10.3+")
            SKStoreReviewController.requestReview()
            result(nil)

        } else {
            log("In-App Review unavailable on this iOS version")
            result(
                FlutterError(
                    code: "unavailable",
                    message: "In-App Review unavailable on this iOS version",
                    details: nil
                )
            )
        }
    }

    /// Checks if the in-app review API is available on the device.
    private func isAvailable(_ result: @escaping FlutterResult) {
        if #available(iOS 10.3, *) {
            log("In-App Review available")
            result(true)
        } else {
            log("In-App Review unavailable")
            result(false)
        }
    }

    /// Opens the App Store listing page for the current app.
    ///
    /// - Parameter storeId: The Apple App Store ID (e.g. `"1234567890"`).
    /// - Note:
    ///   The `storeId` must be passed from Flutter as the method argument.
    private func openStoreListing(storeId: String?, result: @escaping FlutterResult) {
        guard let storeId = storeId else {
            let message = "Missing App Store ID in method call arguments."
            log(message)
            result(
                FlutterError(
                    code: "no-store-id",
                    message: message,
                    details: nil
                )
            )
            return
        }

        let urlString = "https://apps.apple.com/app/id\(storeId)?action=write-review"
        guard let url = URL(string: urlString) else {
            let message = "Failed to construct App Store review URL"
            log(message)
            result(
                FlutterError(
                    code: "url-construct-fail",
                    message: message,
                    details: nil
                )
            )
            return
        }

        log("Opening App Store URL: \(urlString)")

        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.openURL(url)
        }

        result(nil)
    }

    // MARK: - Logging

    /// Prints a namespaced log message for debugging purposes.
    private func log(_ message: String, details: String? = nil) {
        if let details = details {
            NSLog("InAppReviewPlugin: \(message) - \(details)")
        } else {
            NSLog("InAppReviewPlugin: \(message)")
        }
    }
}
