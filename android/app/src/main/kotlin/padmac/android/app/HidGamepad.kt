package padmac.android.app

import android.annotation.SuppressLint
import android.app.Activity
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.os.Build
import android.os.IBinder
import android.util.Log
import android.view.View
import android.view.WindowInsets
import android.view.WindowInsetsController
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

@SuppressLint("MissingPermission")
class HidGamepad(
    private val activity: Activity,
    engine: FlutterEngine,
) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    private val channel = MethodChannel(engine.dartExecutor.binaryMessenger, "padmac/hid")
    private val events = EventChannel(engine.dartExecutor.binaryMessenger, "padmac/hid_events")

    private var sink: EventChannel.EventSink? = null
    private var hidService: HidService? = null
    private var isBound = false
    private var isServiceStarted = false
    private var isDisposed = false

    private val serviceIntent: Intent
        get() = Intent(activity, HidService::class.java)

    private val connection = object : ServiceConnection {
        override fun onServiceConnected(name: ComponentName?, binder: IBinder?) {
            val localBinder = binder as? HidService.LocalBinder
            if (localBinder == null) {
                Log.e(TAG, "Binder HID invalide")
                return
            }

            val service = localBinder.getService()
            hidService = service
            service.setEventSink { event, value ->
                activity.runOnUiThread {
                    if (!isDisposed) {
                        sink?.success(mapOf("event" to event, "value" to value))
                    }
                }
            }
            service.init()
        }

        override fun onServiceDisconnected(name: ComponentName?) {
            // Android peut reconnecter automatiquement le binding. On garde
            // isBound à true jusqu'à un unbind explicite ou onBindingDied().
            hidService = null
            sink?.success(mapOf("event" to "service", "value" to "service HID interrompu"))
        }

        override fun onBindingDied(name: ComponentName?) {
            hidService = null
            if (isBound) {
                try {
                    activity.unbindService(this)
                } catch (_: IllegalArgumentException) {
                    // Le binding a déjà été libéré par Android.
                }
            }
            isBound = false
            isServiceStarted = false
            sink?.success(mapOf("event" to "service", "value" to "binding HID terminé"))
        }

        override fun onNullBinding(name: ComponentName?) {
            hidService = null
            if (isBound) {
                try {
                    activity.unbindService(this)
                } catch (_: IllegalArgumentException) {
                    // Rien à libérer.
                }
            }
            isBound = false
            isServiceStarted = false
            sink?.success(mapOf("event" to "service", "value" to "binding HID vide"))
        }
    }

    init {
        channel.setMethodCallHandler(this)
        events.setStreamHandler(this)
    }

    private fun startAndBindService(): Boolean {
        if (isDisposed) return false
        if (isBound) return true

        val intent = serviceIntent
        try {
            if (!isServiceStarted) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    ContextCompat.startForegroundService(activity, intent)
                } else {
                    activity.startService(intent)
                }
                isServiceStarted = true
            }

            val bound = activity.bindService(intent, connection, Context.BIND_AUTO_CREATE)
            if (!bound) {
                Log.e(TAG, "bindService() a retourné false")
                if (isServiceStarted) {
                    activity.stopService(intent)
                    isServiceStarted = false
                }
                return false
            }

            isBound = true
            return true
        } catch (error: Exception) {
            Log.e(TAG, "Erreur démarrage/binding du service HID", error)
            return false
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "init" -> result.success(startAndBindService())

                "discoverable" -> {
                    val intent = Intent(BluetoothAdapter.ACTION_REQUEST_DISCOVERABLE)
                        .putExtra(BluetoothAdapter.EXTRA_DISCOVERABLE_DURATION, 300)
                    activity.startActivity(intent)
                    result.success(null)
                }

                "bonded" -> {
                    val manager = activity.getSystemService(Context.BLUETOOTH_SERVICE)
                        as BluetoothManager
                    val devices = manager.adapter?.bondedDevices?.map { device ->
                        mapOf(
                            "name" to (device.name ?: ""),
                            "address" to device.address,
                        )
                    } ?: emptyList<Map<String, String>>()
                    result.success(devices)
                }

                "connect" -> {
                    val address = call.argument<String>("address")
                    val service = hidService
                    result.success(address != null && service?.connect(address) == true)
                }

                "disconnect" -> result.success(hidService?.disconnect() ?: false)

                "systemUi" -> {
                    val immersive = call.argument<Boolean>("immersive") == true
                    setSystemBarsHidden(immersive)
                    result.success(true)
                }

                "send" -> {
                    val data = call.arguments as? ByteArray
                    val service = hidService
                    result.success(
                        data != null &&
                            data.size == HidService.REPORT_LENGTH &&
                            service != null &&
                            service.sendReport(data),
                    )
                }

                "dispose" -> {
                    dispose()
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        } catch (error: SecurityException) {
            Log.e(TAG, "Permission Bluetooth manquante pour ${call.method}", error)
            result.error("BLUETOOTH_PERMISSION", error.message, null)
        } catch (error: Exception) {
            Log.e(TAG, "Erreur pendant ${call.method}", error)
            result.error("HID_ERROR", error.message ?: "Erreur HID inconnue", null)
        }
    }

    /**
     * Android 16+ ignores Flutter's legacy immersiveSticky mode for apps targeting
     * API 36+. Use WindowInsetsController directly so PadMac can hide system bars
     * while the controller surface is active.
     */
    @Suppress("DEPRECATION")
    private fun setSystemBarsHidden(hidden: Boolean) {
        activity.window.decorView.post {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                val controller = activity.window.insetsController ?: return@post
                controller.systemBarsBehavior =
                    WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
                val bars = WindowInsets.Type.statusBars() or WindowInsets.Type.navigationBars()
                if (hidden) controller.hide(bars) else controller.show(bars)
            } else {
                val flags = if (hidden) {
                    View.SYSTEM_UI_FLAG_FULLSCREEN or
                        View.SYSTEM_UI_FLAG_HIDE_NAVIGATION or
                        View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY or
                        View.SYSTEM_UI_FLAG_LAYOUT_STABLE or
                        View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or
                        View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                } else {
                    View.SYSTEM_UI_FLAG_VISIBLE
                }
                activity.window.decorView.systemUiVisibility = flags
            }
        }
    }

    override fun onListen(arguments: Any?, eventSink: EventChannel.EventSink?) {
        sink = eventSink
    }

    override fun onCancel(arguments: Any?) {
        sink = null
    }

    fun dispose() {
        if (isDisposed) return
        isDisposed = true

        try {
            hidService?.setEventSink(null)
            hidService?.dispose()
        } catch (error: Exception) {
            Log.w(TAG, "Erreur pendant la libération du service HID", error)
        }
        hidService = null

        if (isBound) {
            try {
                activity.unbindService(connection)
            } catch (_: IllegalArgumentException) {
                // Déjà délié.
            }
            isBound = false
        }

        if (isServiceStarted) {
            try {
                activity.stopService(serviceIntent)
            } catch (error: Exception) {
                Log.w(TAG, "Impossible d'arrêter le service HID", error)
            }
            isServiceStarted = false
        }

        sink = null
        channel.setMethodCallHandler(null)
        events.setStreamHandler(null)
    }

    private companion object {
        const val TAG = "HidGamepad"
    }
}
