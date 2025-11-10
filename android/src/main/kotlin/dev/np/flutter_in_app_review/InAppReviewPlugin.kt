package dev.np.flutter_in_app_review

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.util.Log
import androidx.core.net.toUri
import com.google.android.play.core.review.ReviewManagerFactory
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/**
 * Android implementation of the Flutter plugin `flutter_in_app_review`.
 *
 * This plugin enables apps to:
 *  - Check if in-app review is available on the device.
 *  - Launch the Google Play in-app review dialog.
 *  - Open the app’s Play Store listing for manual reviews.
 *
 * Communicates with Dart through a [MethodChannel] named:
 * `dev.np.flutter_in_app_review`.
 */
class InAppReviewPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {

    private lateinit var channel: MethodChannel
    private var context: Context? = null
    private var activity: Activity? = null

    private val TAG = "InAppReviewPlugin"

    companion object {
        private const val METHOD_IS_AVAILABLE = "isAvailable"
        private const val METHOD_REQUEST_REVIEW = "requestReview"
        private const val METHOD_OPEN_STORE_LISTING = "openStoreListing"
    }

    //region FlutterPlugin Lifecycle
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(
            binding.binaryMessenger,
            "dev.np.flutter_in_app_review"
        )
        channel.setMethodCallHandler(this)
        context = binding.applicationContext
        Log.i(TAG, "Plugin attached to engine")
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        context = null
        Log.i(TAG, "Plugin detached from engine")
    }
    //endregion

    //region ActivityAware Lifecycle
    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        Log.i(TAG, "Attached to activity: ${activity?.localClassName}")
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
        Log.i(TAG, "Detached from activity (config change)")
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        Log.i(TAG, "Reattached to activity after config change")
    }

    override fun onDetachedFromActivity() {
        activity = null
        Log.i(TAG, "Detached from activity")
    }
    //endregion

    //region MethodCallHandler
    override fun onMethodCall(call: MethodCall, result: Result) {
        Log.i(TAG, "Received method call: ${call.method}")

        when (call.method) {
            METHOD_IS_AVAILABLE -> isAvailable(result)
            METHOD_REQUEST_REVIEW -> requestReview(result)
            METHOD_OPEN_STORE_LISTING -> openStoreListing(result)
            else -> result.notImplemented()
        }
    }
    //endregion

    //region Plugin Methods

    /**
     * Checks if the in-app review API is available on this device.
     * Returns `true` if the Google Play Store and required services are available.
     */
    private fun isAvailable(result: Result) {
        val ctx = context ?: run { error(result, "Android context not available"); return }
        try {
            val manager = ReviewManagerFactory.create(ctx)
            val request = manager.requestReviewFlow()
            request.addOnCompleteListener { task ->
                result.success(task.isSuccessful)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error checking availability", e)
            result.success(false)
        }
    }

    /**
     * Launches the in-app review dialog if available.
     * Falls back to an error if Google Play services are not accessible.
     */
    private fun requestReview(result: Result) {
        val ctx = context ?: run { error(result, "Android context not available"); return }
        val act = activity ?: run { error(result, "Android activity not available"); return }

        try {
            val manager = ReviewManagerFactory.create(ctx)
            val request = manager.requestReviewFlow()
            request.addOnCompleteListener { task ->
                if (task.isSuccessful) {
                    Log.i(TAG, "Review flow request successful")
                    val info = task.result
                    val flow = manager.launchReviewFlow(act, info)
                    flow.addOnCompleteListener { reviewFlow ->
                        if (reviewFlow.isSuccessful) {
                            Log.i(TAG, "Review flow completed successfully")
                            result.success(null)
                        } else {
                            val msg = reviewFlow.exception?.message ?: "Unknown review flow error"
                            Log.w(TAG, "Review flow failed: $msg")
                            result.error("error", msg, null)
                        }
                    }
                } else {
                    val msg = task.exception?.message ?: "In-App Review API unavailable"
                    Log.w(TAG, msg)
                    result.error("error", msg, null)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error launching review flow", e)
            result.error("error", "An error occurred launching the review flow", e.message)
        }
    }

    /**
     * Opens the Play Store listing for the current app.
     * This provides a manual alternative if in-app review is unavailable.
     */
    private fun openStoreListing(result: Result) {
        val ctx = context ?: run { error(result, "Android context not available"); return }

        try {
            val packageName = ctx.packageName
            val intent = Intent(Intent.ACTION_VIEW)
                .setData("https://play.google.com/store/apps/details?id=$packageName".toUri())
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)

            ctx.startActivity(intent)
            result.success(null)
        } catch (e: Exception) {
            Log.e(TAG, "Error opening Play Store", e)
            result.error("error", "An error occurred while opening the Play Store", e.message)
        }
    }
    //endregion

    //region Helpers
    private fun error(result: Result, message: String) {
        Log.e(TAG, message)
        result.error("error", message, null)
    }
    //endregion
}
