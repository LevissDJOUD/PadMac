package padmac.android.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var hidGamepad: HidGamepad? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        hidGamepad = HidGamepad(this, flutterEngine)
    }

    override fun onDestroy() {
        hidGamepad?.dispose()
        super.onDestroy()
    }
}