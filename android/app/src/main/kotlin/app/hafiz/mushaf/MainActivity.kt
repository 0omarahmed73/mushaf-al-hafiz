package app.hafiz.mushaf

import android.Manifest
import android.annotation.SuppressLint
import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.net.Uri
import android.os.Build
import android.os.CancellationSignal
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var pendingAsk: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Opens a web link in the phone's browser; the only thing the app ever sends outside itself.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "app.hafiz.mushaf/links")
            .setMethodCallHandler { call, result ->
                if (call.method != "open") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val url = call.arguments as? String
                if (url == null || !url.startsWith("https://")) {
                    result.success(false)
                    return@setMethodCallHandler
                }
                try {
                    startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url)))
                    result.success(true)
                } catch (e: ActivityNotFoundException) {
                    result.success(false)
                }
            }
        // Feature 014 (research D3): one approximate reading for prayer times. Only ACCESS_COARSE_LOCATION, asked when
        // the reader taps «حدد موقعي»; the reading stays on the phone; no network is used by the app.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "app.hafiz.mushaf/location")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "request" -> askCoarse(result)
                    "current" -> readOnce(result)
                    "openSettings" -> {
                        try {
                            startActivity(
                                Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.fromParts("package", packageName, null))
                            )
                        } catch (e: ActivityNotFoundException) {
                        }
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun coarseGranted() =
        checkSelfPermission(Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED

    private fun askCoarse(result: MethodChannel.Result) {
        if (coarseGranted()) {
            result.success("granted")
            return
        }
        if (pendingAsk != null) {
            result.success("denied")
            return
        }
        pendingAsk = result
        requestPermissions(arrayOf(Manifest.permission.ACCESS_COARSE_LOCATION), ASK_CODE)
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != ASK_CODE) return
        val result = pendingAsk ?: return
        pendingAsk = null
        val answer = when {
            grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED -> "granted"
            !shouldShowRequestPermissionRationale(Manifest.permission.ACCESS_COARSE_LOCATION) -> "deniedForever"
            else -> "denied"
        }
        result.success(answer)
    }

    @SuppressLint("MissingPermission")
    private fun readOnce(result: MethodChannel.Result) {
        if (!coarseGranted()) {
            result.success(null)
            return
        }
        val manager = getSystemService(LOCATION_SERVICE) as LocationManager
        val wanted = buildList {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) add(LocationManager.FUSED_PROVIDER)
            add(LocationManager.NETWORK_PROVIDER)
            add(LocationManager.GPS_PROVIDER)
        }
        val providers = wanted.filter {
            try {
                manager.allProviders.contains(it) && manager.isProviderEnabled(it)
            } catch (e: Exception) {
                false
            }
        }
        // A reading less than a day old is good enough for prayer times.
        for (p in providers) {
            val last = try {
                manager.getLastKnownLocation(p)
            } catch (e: Exception) {
                null
            }
            if (last != null && SystemClock.elapsedRealtimeNanos() - last.elapsedRealtimeNanos < DAY_NANOS) {
                result.success(listOf(last.latitude, last.longitude))
                return
            }
        }
        val main = Handler(Looper.getMainLooper())
        var done = false
        val signal = CancellationSignal()
        val finish: (Location?) -> Unit = { loc ->
            if (!done) {
                done = true
                signal.cancel()
                result.success(loc?.let { listOf(it.latitude, it.longitude) })
            }
        }
        main.postDelayed({ finish(null) }, TIMEOUT_MS)
        tryProvider(manager, providers, 0, signal, main, finish)
    }

    @SuppressLint("MissingPermission")
    @Suppress("DEPRECATION")
    private fun tryProvider(
        manager: LocationManager,
        providers: List<String>,
        index: Int,
        signal: CancellationSignal,
        main: Handler,
        finish: (Location?) -> Unit,
    ) {
        if (index >= providers.size) {
            finish(null)
            return
        }
        val next = { tryProvider(manager, providers, index + 1, signal, main, finish) }
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                manager.getCurrentLocation(providers[index], signal, mainExecutor) { loc ->
                    if (loc != null) finish(loc) else next()
                }
            } else {
                manager.requestSingleUpdate(providers[index], object : LocationListener {
                    override fun onLocationChanged(location: Location) = finish(location)
                }, Looper.getMainLooper())
            }
        } catch (e: Exception) {
            // GPS needs the precise permission before Android 12: go on to the next provider.
            next()
        }
    }

    companion object {
        private const val ASK_CODE = 1401
        private const val TIMEOUT_MS = 30_000L
        private const val DAY_NANOS = 24L * 60 * 60 * 1_000_000_000
    }
}
