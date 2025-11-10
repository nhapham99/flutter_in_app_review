import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:platform/platform.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'in_app_review_platform_interface.dart';

/// {@template method_channel_in_app_review}
/// A concrete implementation of [InAppReviewPlatform] that communicates
/// with the native platform (Android/iOS) via a Flutter [MethodChannel].
///
/// This class provides the default behavior for the `in_app_review` plugin.
/// It sends method calls to the native layer, where each platform (e.g. Android,
/// iOS) handles the actual logic of showing in-app review dialogs or
/// launching store pages.
///
/// The channel name used for communication is:
/// `"dev.np.flutter_in_app_review"`, and must match the name declared
/// in the native plugin registration (e.g. `InAppReviewPlugin.kt` on Android).
/// {@endtemplate}
class MethodChannelInAppReview extends InAppReviewPlatform {
  /// The [MethodChannel] used to send and receive messages between
  /// Dart and the native platform code.
  ///
  /// The native side listens for method calls such as:
  /// - `"isAvailable"`
  /// - `"requestReview"`
  /// - `"openStoreListing"`
  ///
  /// and performs the corresponding actions.
  MethodChannel _channel = const MethodChannel('dev.np.flutter_in_app_review');

  /// Provides access to the underlying operating system type (Android, iOS, etc.)
  /// for platform-specific branching logic.
  ///
  /// Defaults to [LocalPlatform], which automatically detects the platform
  /// at runtime.
  Platform _platform = const LocalPlatform();

  /// Allows tests to override the [MethodChannel] instance.
  ///
  /// Useful for mocking native method calls without touching real
  /// platform code during unit or widget testing.
  @visibleForTesting
  set channel(MethodChannel channel) => _channel = channel;

  /// Allows tests to override the platform type (e.g. simulate iOS or Windows).
  @visibleForTesting
  set platform(Platform platform) => _platform = platform;

  /// {@macro in_app_review_platform.isAvailable}
  ///
  /// Checks whether in-app review functionality is available on the
  /// current platform.
  ///
  /// - Returns `false` on the web (since web doesn’t support native reviews).
  /// - On Android and iOS, delegates to native code via `_channel.invokeMethod('isAvailable')`.
  ///
  /// If an error occurs or the native method returns `null`, this method
  /// will safely return `false`.
  @override
  Future<bool> isAvailable() async {
    if (kIsWeb) return false;
    return _channel
        .invokeMethod<bool>('isAvailable')
        .then((available) => available ?? false, onError: (_) => false);
  }

  /// {@macro in_app_review_platform.requestReview}
  ///
  /// Requests the native platform to show an in-app review dialog.
  ///
  /// On Android, this typically triggers the Google Play in-app review flow.
  /// On iOS, it triggers the App Store review prompt.
  ///
  /// This method relies on native logic for rate-limiting — the dialog may
  /// not always appear even when the method succeeds.
  @override
  Future<void> requestReview() => _channel.invokeMethod('requestReview');

  /// {@macro in_app_review_platform.openStoreListing}
  ///
  /// Opens the app's store page on the relevant platform.
  ///
  /// Platform behavior:
  /// - **iOS/macOS:** requires a valid [appStoreId], passed to native via the channel.
  /// - **Android:** launches Google Play Store using the package name.
  /// - **Windows:** opens the Microsoft Store using [microsoftStoreId].
  ///
  /// Throws an [UnsupportedError] for other platforms (e.g. Linux, Web).
  @override
  Future<void> openStoreListing({
    String? appStoreId,
    String? microsoftStoreId,
  }) async {
    final bool isiOS = _platform.isIOS;
    final bool isMacOS = _platform.isMacOS;
    final bool isAndroid = _platform.isAndroid;
    final bool isWindows = _platform.isWindows;

    if (isiOS || isMacOS) {
      // iOS & macOS require an App Store ID for lookup
      await _channel.invokeMethod(
        'openStoreListing',
        ArgumentError.checkNotNull(appStoreId, 'appStoreId'),
      );
    } else if (isAndroid) {
      // Android opens its own store listing via native code
      await _channel.invokeMethod('openStoreListing');
    } else if (isWindows) {
      // Windows opens the Microsoft Store via URI scheme
      ArgumentError.checkNotNull(microsoftStoreId, 'microsoftStoreId');
      await _launchUrl(
        'ms-windows-store://review/?ProductId=$microsoftStoreId',
      );
    } else {
      throw UnsupportedError(
        'Platform(${_platform.operatingSystem}) not supported',
      );
    }
  }

  /// Launches an external application or browser to open the given [url].
  ///
  /// This method uses the [`url_launcher`](https://pub.dev/packages/url_launcher)
  /// package to open URLs in a system-native way.
  ///
  /// If the URL cannot be launched, the method silently returns without error.
  Future<void> _launchUrl(String url) async {
    if (!await canLaunchUrlString(url)) return;
    await launchUrlString(url, mode: LaunchMode.externalNonBrowserApplication);
  }
}
