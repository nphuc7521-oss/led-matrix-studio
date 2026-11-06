package com.ledstudio.led_matrix_app

import android.content.Context
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.net.wifi.WifiInfo
import android.net.wifi.WifiManager
import android.net.wifi.WifiNetworkSpecifier
import android.os.Build
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.ledmatrix.wifi"
    private var connectivityManager: ConnectivityManager? = null
    private var currentCallback: ConnectivityManager.NetworkCallback? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        connectivityManager = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "bindCurrentWifi" -> {
                    val ok = bindCurrentWifi()
                    result.success(ok)
                }
                "getCurrentWifiSsid" -> {
                    val ssid = getCurrentWifiSsid()
                    result.success(ssid)
                }
                "connectWifi" -> {
                    val ssid = call.argument<String>("ssid") ?: ""
                    val password = call.argument<String>("password") ?: "88888888"
                    connectToWifi(ssid, password, result)
                }
                "disconnectWifi" -> {
                    disconnectWifi()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun bindCurrentWifi(): Boolean {
        try {
            val cm = connectivityManager ?: return false
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                for (network in cm.allNetworks) {
                    val caps = cm.getNetworkCapabilities(network)
                    if (caps != null && caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI)) {
                        val bound = cm.bindProcessToNetwork(network)
                        android.util.Log.d("MainActivity", "bindProcessToNetwork to active Wi-Fi: $bound")
                        return bound
                    }
                }
            }
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "bindCurrentWifi error: ${e.message}")
        }
        return false
    }

    private fun getCurrentWifiSsid(): String {
        try {
            val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
            val info = wifiManager.connectionInfo
            var ssid = info.ssid ?: ""
            if (ssid.startsWith("\"") && ssid.endsWith("\"") && ssid.length > 2) {
                ssid = ssid.substring(1, ssid.length - 1)
            }
            if (ssid == "<unknown ssid>") ssid = ""
            return ssid
        } catch (e: Exception) {
            return ""
        }
    }

    private fun connectToWifi(ssid: String, pass: String, result: MethodChannel.Result) {
        // Kiểm tra xem hiện tại máy đã bắt đúng Wi-Fi này chưa
        val currentSsid = getCurrentWifiSsid()
        if (currentSsid.isNotEmpty() && currentSsid.equals(ssid, ignoreCase = true)) {
            bindCurrentWifi()
            result.success(true)
            return
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            // Chuẩn kết nối Wi-Fi trên Android 10, 11, 12, 13, 14 (Honor 400 / MagicOS)
            try {
                disconnectWifi()

                val specifier = WifiNetworkSpecifier.Builder()
                    .setSsid(ssid)
                    .setWpa2Passphrase(pass)
                    .build()

                val request = NetworkRequest.Builder()
                    .addTransportType(NetworkCapabilities.TRANSPORT_WIFI)
                    .removeCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
                    .setNetworkSpecifier(specifier)
                    .build()

                var hasResponded = false
                val callback = object : ConnectivityManager.NetworkCallback() {
                    override fun onAvailable(network: Network) {
                        super.onAvailable(network)
                        // Ép toàn bộ socket kết nối mạng của app chạy thẳng qua Wi-Fi card LED này
                        connectivityManager?.bindProcessToNetwork(network)
                        if (!hasResponded) {
                            hasResponded = true
                            runOnUiThread { result.success(true) }
                        }
                    }

                    override fun onUnavailable() {
                        super.onUnavailable()
                        // Nếu user hủy popup hoặc timeout, thử bind Wi-Fi hiện tại phòng trường hợp user tự kết nối
                        bindCurrentWifi()
                        if (!hasResponded) {
                            hasResponded = true
                            runOnUiThread { result.success(false) }
                        }
                    }

                    override fun onLost(network: Network) {
                        super.onLost(network)
                    }
                }

                currentCallback = callback
                connectivityManager?.requestNetwork(request, callback, 10000) // Timeout 10 giây

            } catch (e: Exception) {
                bindCurrentWifi()
                result.error("WIFI_ERR", e.message, null)
            }
        } else {
            // Android 9 trở xuống
            bindCurrentWifi()
            result.success(true)
        }
    }

    private fun disconnectWifi() {
        try {
            currentCallback?.let {
                connectivityManager?.unregisterNetworkCallback(it)
                currentCallback = null
            }
        } catch (_: Exception) {}
    }
}
