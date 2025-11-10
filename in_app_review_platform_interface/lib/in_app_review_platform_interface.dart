import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:in_app_review_platform_interface/method_channel_in_app_review.dart';

/// {@template in_app_review_platform}
/// The abstract base class for all platform-specific implementations
/// of the In-App Review plugin.
///
/// This class defines the interface (contract) for interacting with
/// the native platform APIs related to in-app reviews.
///
/// Concrete implementations (for example, Android, iOS, or Web)
/// should **extend** this class rather than **implement** it directly.
/// Extending ensures that new methods added in future versions won't
/// break existing platform implementations, because default
/// implementations will be inherited automatically.
///
/// See also:
/// - [MethodChannelInAppReview], the default implementation using
///   Flutter's [MethodChannel] to communicate with native code.
/// {@endtemplate}
abstract class InAppReviewPlatform extends PlatformInterface {
  /// Creates an instance of [InAppReviewPlatform].
  ///
  /// The [token] is used internally by [PlatformInterface] to ensure
  /// that subclasses are properly verified and not replaced with
  /// invalid instances.
  InAppReviewPlatform() : super(token: _token);

  /// The default instance of [InAppReviewPlatform], which uses
  /// [MethodChannelInAppReview] to communicate with native code.
  static InAppReviewPlatform _instance = MethodChannelInAppReview();

  /// A unique token used by [PlatformInterface.verifyToken] to ensure
  /// that only valid subclasses can set the [instance].
  static final Object _token = Object();

  /// The current active instance of [InAppReviewPlatform].
  ///
  /// This defaults to [MethodChannelInAppReview] but can be overridden
  /// by a platform-specific implementation, such as a Web or Windows version.
  static InAppReviewPlatform get instance => _instance;

  /// Sets the active [InAppReviewPlatform] instance.
  ///
  /// Platform-specific implementations should set this during their
  /// own registration process (usually inside the plugin's `registerWith`
  /// method).
  ///
  /// Throws a [PlatformInterface] verification error if an invalid
  /// subclass attempts to replace the instance.
  static set instance(InAppReviewPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Checks if the in-app review API is available on the current platform.
  ///
  /// On Android, this requires:
  /// - Google Play Store installed
  /// - Android 5.0 (API 21) or higher
  ///
  /// On iOS, this requires:
  /// - iOS 10.3 or higher
  ///
  /// On macOS, this requires:
  /// - macOS 10.14 or higher
  ///
  /// Returns `true` if the feature is available, otherwise `false`.
  Future<bool> isAvailable() {
    throw UnimplementedError('isAvailable() has not been implemented.');
  }

  /// Requests to show the in-app review dialog.
  ///
  /// It's recommended to first check availability using [isAvailable].
  ///
  /// On Android and iOS, both platforms enforce usage limits and
  /// conditions. The dialog may not always appear even when this
  /// method succeeds. Developers should **not rely** on this for
  /// user feedback collection frequency.
  ///
  /// For more information:
  /// - Android: https://developer.android.com/guide/playcore/in-app-review
  /// - iOS: https://developer.apple.com/design/human-interface-guidelines/ios/system-capabilities/ratings-and-reviews/
  Future<void> requestReview() {
    throw UnimplementedError('requestReview() has not been implemented.');
  }

  /// Opens the app's store listing on the corresponding platform.
  ///
  /// On Android, this opens the Play Store listing.
  /// On iOS and macOS, the [appStoreId] is required to construct the App Store URL.
  /// On Windows, the [microsoftStoreId] is required.
  ///
  /// Example:
  /// ```dart
  /// await InAppReviewPlatform.instance.openStoreListing(appStoreId: '123456789');
  /// ```
  Future<void> openStoreListing({
    /// Required for iOS & macOS.
    String? appStoreId,

    /// Required for Windows.
    String? microsoftStoreId,
  }) {
    throw UnimplementedError('openStoreListing() has not been implemented.');
  }
}
