package com.halchal.app

import android.graphics.Rect
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.view.View
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Android's own edge-swipe "back/home" system gesture and our in-app
 * left/right edge-swipe-back (dashboard_shell.dart's tab history + PopScope)
 * both watch the same screen edges — and both can fire on the SAME real
 * touch, independently of each other. Flutter's own gesture-detector
 * settings (HitTestBehavior etc.) only control how Flutter's widgets see a
 * touch; they have no influence over the OS's separate, parallel gesture
 * recognition, which lives outside the Flutter engine entirely.
 *
 * View.setSystemGestureExclusionRects (API 29+) helps with the OS's "back"
 * gesture category specifically, but doesn't cover home/recents-switching
 * or Samsung's own proprietary edge shortcuts at all.
 *
 * The real fix is Android's official predictive-back channel
 * (OnBackInvokedCallback, which Flutter's PopScope is supposed to drive
 * automatically) — but confirmed live (raw adb logcat, see
 * dashboard_shell.dart's comment) that Flutter's own automatic relay of
 * PopScope's canPop to native's setFrameworkHandlesBack() doesn't fire
 * reliably for a ShellRoute branch reached via go_router's context.go()
 * (which replaces the Navigator stack instead of pushing, so the route is
 * always "first"/only). Flutter's OWN internal mechanism ALSO calls
 * setFrameworkHandlesBack with ITS OWN (in this case wrong) determination,
 * on its own schedule — so simply calling the same method explicitly from
 * Dart isn't enough either, since whichever call lands last wins and
 * Flutter's automatic "false" kept landing after our explicit "true".
 * backGestureChannel below is a dedicated channel Flutter's own internals
 * never touch, so nativeWantsIntercept only ever reflects OUR explicit
 * intent from dashboard_shell.dart, and applyBackInterceptState() ORs it
 * with whatever Flutter's own mechanism most recently asked for — so our
 * intent can only ever turn interception ON that Flutter's automatic calls
 * would otherwise turn off, never the other way around.
 */
class MainActivity : FlutterActivity() {
    companion object {
        private const val EDGE_ZONE_DP = 72
        private const val BACK_GESTURE_CHANNEL = "com.halchal.app/back_gesture"
    }

    private var lastFrameworkHandlesBack = false
    private var nativeWantsIntercept = false

    override fun setFrameworkHandlesBack(frameworkHandlesBack: Boolean) {
        lastFrameworkHandlesBack = frameworkHandlesBack
        applyBackInterceptState()
    }

    private fun applyBackInterceptState() {
        val effective = lastFrameworkHandlesBack || nativeWantsIntercept
        Log.d(
            "HalchalGesture",
            "applyBackInterceptState: framework=$lastFrameworkHandlesBack native=$nativeWantsIntercept effective=$effective",
        )
        super.setFrameworkHandlesBack(effective)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d("HalchalGesture", "onCreate: SDK_INT=${Build.VERSION.SDK_INT}")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val decorView = window.decorView
            decorView.addOnLayoutChangeListener { view, _, _, _, _, _, _, _, _ ->
                applyGestureExclusion(view)
            }
            // Layout-change listeners don't reliably fire for the very first
            // layout pass on every OEM build — post() guarantees at least one
            // explicit call once the initial layout has actually happened.
            decorView.post { applyGestureExclusion(decorView) }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BACK_GESTURE_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "setInterceptEnabled") {
                    nativeWantsIntercept = call.arguments as? Boolean ?: false
                    Log.d("HalchalGesture", "setInterceptEnabled: $nativeWantsIntercept")
                    applyBackInterceptState()
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun applyGestureExclusion(view: View) {
        val width = view.width
        val height = view.height
        Log.d("HalchalGesture", "applyGestureExclusion: width=$width height=$height")
        if (width == 0 || height == 0) return

        val exclusionWidthPx = (EDGE_ZONE_DP * resources.displayMetrics.density).toInt()
        val left = Rect(0, 0, exclusionWidthPx, height)
        val right = Rect(width - exclusionWidthPx, 0, width, height)
        view.systemGestureExclusionRects = listOf(left, right)
        Log.d(
            "HalchalGesture",
            "applyGestureExclusion: set rects left=$left right=$right actual=${view.systemGestureExclusionRects}",
        )
    }
}
