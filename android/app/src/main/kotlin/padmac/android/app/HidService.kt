package padmac.android.app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.bluetooth.*
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Binder
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat

class HidService : Service() {

    private val binder = LocalBinder()
    private lateinit var mainHandler: Handler
    private lateinit var executor: java.util.concurrent.Executor
    
    private var sink: ((String, String) -> Unit)? = null

    private var adapter: BluetoothAdapter? = null
    private var hid: BluetoothHidDevice? = null
    private var host: BluetoothDevice? = null
    private var registered = false
    private var registering = false
    private var proxyRequested = false

    inner class LocalBinder : Binder() {
        fun getService(): HidService = this@HidService
    }

    override fun onCreate() {
        super.onCreate()
        mainHandler = Handler(Looper.getMainLooper())
        executor = ContextCompat.getMainExecutor(this)
        
        createNotificationChannel()
        adapter = (getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager).adapter
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("PadMac")
            .setContentText("Manette active")
            .setSmallIcon(android.R.drawable.ic_menu_compass)
            .build()
            
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(1, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE)
        } else {
            startForeground(1, notification)
        }
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder = binder

    fun setEventSink(sink: ((String, String) -> Unit)?) {
        this.sink = sink
    }

    private fun emit(event: String, value: String) {
        if (::mainHandler.isInitialized) {
            mainHandler.post { sink?.invoke(event, value) }
        }
    }

    private val callback = object : BluetoothHidDevice.Callback() {
        override fun onAppStatusChanged(pluggedDevice: BluetoothDevice?, registered: Boolean) {
            this@HidService.registered = registered
            this@HidService.registering = false
            emit("app", if (registered) "enregistré" else "non enregistré")
        }

        override fun onConnectionStateChanged(device: BluetoothDevice?, state: Int) {
            if (device == null) return
            when (state) {
                BluetoothProfile.STATE_CONNECTED -> {
                    host = device
                    // A host can initialise every HID axis at its logical minimum.
                    // Send a full neutral Input report as soon as the link is ready.
                    mainHandler.postDelayed({
                        if (host == device && registered) {
                            val sent = try {
                                hid?.sendReport(device, REPORT_ID, NEUTRAL_REPORT) == true
                            } catch (error: SecurityException) {
                                emit("hid", "rapport neutre initial refusé : permission Bluetooth")
                                false
                            }
                            emit("hid", "rapport neutre initial envoyé=$sent")
                        }
                    }, 180L)
                }
                BluetoothProfile.STATE_DISCONNECTED -> if (device == host) host = null
            }
            val label = when (state) {
                BluetoothProfile.STATE_CONNECTED -> "connecté"
                BluetoothProfile.STATE_CONNECTING -> "connexion…"
                BluetoothProfile.STATE_DISCONNECTING -> "déconnexion…"
                else -> "déconnecté"
            }
            emit("conn", "${device.name ?: device.address} : $label")
        }

        override fun onGetReport(device: BluetoothDevice?, type: Byte, id: Byte, bufferSize: Int) {
            if (device == null) return
            val ok = hid?.replyReport(device, type, id, NEUTRAL_REPORT) == true
            emit("hid", "GET_REPORT type=$type id=$id -> réponse=$ok")
        }

        override fun onSetReport(device: BluetoothDevice?, type: Byte, id: Byte, data: ByteArray?) {
            if (device == null) return
            hid?.reportError(device, BluetoothHidDevice.ERROR_RSP_SUCCESS)
            emit("hid", "SET_REPORT type=$type id=$id (${data?.size ?: 0} octets)")
        }

        override fun onSetProtocol(device: BluetoothDevice?, protocol: Byte) {
            emit("hid", "SET_PROTOCOL $protocol")
        }
    }

    private val serviceListener = object : BluetoothProfile.ServiceListener {
        override fun onServiceConnected(profile: Int, proxy: BluetoothProfile) {
            if (profile != BluetoothProfile.HID_DEVICE) return
            proxyRequested = false
            val h = proxy as BluetoothHidDevice
            hid = h
            emit("proxy", "service HID connecté")
            register(h)
        }

        override fun onServiceDisconnected(profile: Int) {
            if (profile == BluetoothProfile.HID_DEVICE) {
                hid = null
                host = null
                registered = false
                registering = false
                proxyRequested = false
                emit("proxy", "service HID déconnecté")
            }
        }
    }

    private fun register(h: BluetoothHidDevice) {
        if (registered || registering) return
        registering = true
        val sdp = BluetoothHidDeviceAppSdpSettings(
            "PadMac Gamepad",
            "PadMac Bluetooth HID Controller",
            "PadMac", 
            BluetoothHidDevice.SUBCLASS2_GAMEPAD, 
            XBOX_DESCRIPTOR
        )
        val ok = h.registerApp(sdp, null, null, executor, callback)
        if (!ok) registering = false
        emit("proxy", "registerApp=$ok")
    }

    fun init() {
        val h = hid
        if (h != null) {
            if (!registered) register(h)
            return
        }
        val a = adapter
        if (a == null) {
            emit("proxy", "adaptateur Bluetooth indisponible")
            return
        }
        if (proxyRequested) return
        proxyRequested = true
        val requested = a.getProfileProxy(this, serviceListener, BluetoothProfile.HID_DEVICE)
        if (!requested) {
            proxyRequested = false
            emit("proxy", "impossible de demander le profil HID_DEVICE")
        }
    }

    fun connect(address: String): Boolean {
        val device = try {
            adapter?.getRemoteDevice(address)
        } catch (e: IllegalArgumentException) {
            emit("conn", "adresse Bluetooth invalide")
            null
        } ?: return false
        val h = hid
        if (h == null || !registered) return false
        return try {
            h.connect(device)
        } catch (e: SecurityException) {
            emit("conn", "permission Bluetooth manquante")
            false
        }
    }

    fun disconnect(): Boolean {
        val h = host ?: return false
        return hid?.disconnect(h) == true
    }

    fun sendReport(data: ByteArray): Boolean {
        if (data.size != REPORT_LENGTH) {
            emit("hid", "rapport rejeté : ${data.size} octets au lieu de $REPORT_LENGTH")
            return false
        }
        val h = host ?: return false
        return try {
            hid?.sendReport(h, REPORT_ID, data) == true
        } catch (e: SecurityException) {
            emit("hid", "permission Bluetooth manquante pour sendReport")
            false
        }
    }

    fun dispose() {
        val current = hid
        if (current != null) {
            if (registered || registering) current.unregisterApp()
            adapter?.closeProfileProxy(BluetoothProfile.HID_DEVICE, current)
        }
        hid = null
        host = null
        registered = false
        registering = false
        proxyRequested = false
        stopSelf()
    }

    override fun onDestroy() {
        val current = hid
        if (current != null) {
            if (registered || registering) current.unregisterApp()
            adapter?.closeProfileProxy(BluetoothProfile.HID_DEVICE, current)
        }
        hid = null
        host = null
        registered = false
        registering = false
        proxyRequested = false
        super.onDestroy()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val serviceChannel = NotificationChannel(
                CHANNEL_ID, "PadMac Service",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(serviceChannel)
        }
    }

    companion object {
        const val CHANNEL_ID = "padmac_hid_channel"
        const val REPORT_ID = 1
        const val REPORT_LENGTH = 16

        // Rapport neutre de 16 octets : boutons (2), quatre axes de sticks signés (8),
        // deux gâchettes Simulation Controls (4), Hat (1), Share (1).
        // Sticks au centre signé 0x0000. OJD inverse Brake/Accelerator :
        // 0xFFFF représente donc la gâchette relâchée dans son état mappé.
        val NEUTRAL_REPORT = byteArrayOf(
            0, 0,
            0, 0,       // X : LeftStickX centré (signed 0)
            0, 0,       // Y : LeftStickY centré (signed 0)
            0, 0,       // Z : RightStickX centré (signed 0)
            0, 0,       // Rz : RightStickY centré (signed 0)
            -1, -1,     // Brake : LeftTrigger relâchée (wire value 65535)
            -1, -1,     // Accelerator : RightTrigger relâchée (wire value 65535)
            8,          // Hat Switch neutre (Null State)
            0           // Consumer Record / Share relâché
        )

        /**
         * HID conforme à la forme standard d'OJD :
         * - Button usages 1,2,4,5,7,8,11,12,14,15,13 (ordre des bits PadMac)
         * - X/Y/Z/Rz signés (-32768..32767) pour les deux sticks (Rx/Ry absents)
         * - Simulation Controls Brake/Accelerator pour LT/RT (valeurs fil inversées)
         * - Hat Switch pour le D-pad
         * - Consumer Record pour Share/Capture
         * Report ID 1 ; 16 octets de données sans Report ID.
         */
        val XBOX_DESCRIPTOR: ByteArray = intArrayOf(
            0x05, 0x01,       // Usage Page (Generic Desktop)
            0x09, 0x05,       // Usage (Game Pad)
            0xA1, 0x01,       // Collection (Application)
            0x85, 0x01,       // Report ID (1)

            // Button usages dans l'ordre du rapport et de la carte HID OJD.
            0x05, 0x09,       // Usage Page (Button)
            0x09, 0x01,       // Button 1  -> A / South
            0x09, 0x02,       // Button 2  -> B / East
            0x09, 0x04,       // Button 4  -> X / West
            0x09, 0x05,       // Button 5  -> Y / North
            0x09, 0x07,       // Button 7  -> LB
            0x09, 0x08,       // Button 8  -> RB
            0x09, 0x0B,       // Button 11 -> View / Back
            0x09, 0x0C,       // Button 12 -> Menu / Start
            0x09, 0x0E,       // Button 14 -> L3
            0x09, 0x0F,       // Button 15 -> R3
            0x09, 0x0D,       // Button 13 -> Guide
            0x15, 0x00,       // Logical Minimum (0)
            0x25, 0x01,       // Logical Maximum (1)
            0x75, 0x01,       // Report Size (1 bit)
            0x95, 0x0B,       // Report Count (11)
            0x81, 0x02,       // Input (Data, Variable, Absolute)
            0x75, 0x01,       // Report Size (1 bit)
            0x95, 0x05,       // Report Count (5) padding
            0x81, 0x03,       // Input (Constant)

            // Quatre axes de sticks : X/Y = stick gauche, Z/Rz = stick droit.
            // L'absence de Rx et Ry est intentionnelle : elle sélectionne la
            // descriptorShape correspondante de la carte standard OJD.
            0x05, 0x01,       // Usage Page (Generic Desktop)
            0x09, 0x30,       // X  -> LeftStickX
            0x09, 0x31,       // Y  -> LeftStickY
            0x09, 0x32,       // Z  -> RightStickX
            0x09, 0x35,       // Rz -> RightStickY
            0x16, 0x00, 0x80, // Logical Minimum (-32768, signed 16-bit)
            0x26, 0xFF, 0x7F, // Logical Maximum (32767, signed 16-bit)
            0x75, 0x10,       // Report Size (16 bits)
            0x95, 0x04,       // Report Count (4)
            0x81, 0x02,       // Input (Data, Variable, Absolute)

            // Gâchettes analogiques : usages Simulation Controls d'OJD.
            // Les valeurs sur le fil sont inversées pour annuler la polarité de
            // la carte standard observée avec le profil OJD actuel.
            0x05, 0x02,       // Usage Page (Simulation Controls)
            0x09, 0xC5,       // Brake       -> LeftTrigger
            0x09, 0xC4,       // Accelerator -> RightTrigger
            0x15, 0x00,       // Logical Minimum (0)
            0x26, 0xFF, 0xFF, // Logical Maximum (65535)
            0x75, 0x10,       // Report Size (16 bits)
            0x95, 0x02,       // Report Count (2)
            0x81, 0x02,       // Input (Data, Variable, Absolute)

            // D-pad : Hat Switch, 0..7 plus Null State 8.
            0x05, 0x01,       // Usage Page (Generic Desktop)
            0x09, 0x39,       // Usage (Hat Switch)
            0x15, 0x00,       // Logical Minimum (0)
            0x25, 0x07,       // Logical Maximum (7)
            0x35, 0x00,       // Physical Minimum (0)
            0x46, 0x3B, 0x01, // Physical Maximum (315)
            0x65, 0x14,       // Unit (English Rotation, degrees)
            0x75, 0x04,       // Report Size (4 bits)
            0x95, 0x01,       // Report Count (1)
            0x81, 0x42,       // Input (Data, Variable, Absolute, Null State)
            0x75, 0x04,       // Report Size (4 bits)
            0x95, 0x01,       // Report Count (1)
            0x81, 0x03,       // Input (Constant)

            // Share : Consumer Control / Record (OJD Capture), 1 bit + padding.
            0x05, 0x0C,       // Usage Page (Consumer)
            0x09, 0x01,       // Usage (Consumer Control)
            0xA1, 0x02,       // Collection (Logical)
            0x09, 0xB2,       // Usage (Record)
            0x15, 0x00,       // Logical Minimum (0)
            0x25, 0x01,       // Logical Maximum (1)
            0x75, 0x01,       // Report Size (1 bit)
            0x95, 0x01,       // Report Count (1)
            0x81, 0x02,       // Input (Data, Variable, Absolute)
            0x75, 0x07,       // Report Size (7 bits)
            0x95, 0x01,       // Report Count (1)
            0x81, 0x03,       // Input (Constant)
            0xC0,             // End Consumer logical collection
            0xC0              // End Game Pad application collection
        ).map { it.toByte() }.toByteArray()
    }
}