package com.ledstudio.led_matrix_app

import android.content.Context
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
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

    private fun connectToWifi(ssid: String, pass: String, result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            // Android 10, 11, 12, 13, 14 (Chuẩn cho Honor 400 / MagicOS)
            try {
                // Giải phóng callback cũ nếu có
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
                        // Ép toàn bộ socket kết nối mạng của tiến trình chạy qua Wi-Fi card LED này
                        connectivityManager?.bindProcessToNetwork(network)
                        if (!hasResponded) {
                            hasResponded = true
                            runOnUiThread { result.success(true) }
                        }
                    }

                    override fun onUnavailable() {
                        super.onUnavailable()
                        if (!hasResponded) {
                            hasResponded = true
                            runOnUiThread { result.success(false) }
                        }
                    }

                    override fun onLost(network: Network) {
                        super.onLost(network)
                        connectivityManager?.bindProcessToNetwork(null)
                    }
                }

                currentCallback = callback
                connectivityManager?.requestNetwork(request, callback, 10000) // Timeout 10s

            } catch (e: Exception) {
                result.error("WIFI_ERR", e.message, null)
            }
        } else {
            // Android 9 trở xuống
            result.success(true)
        }
    }

    private fun disconnectWifi() {
        try {
            currentCallback?.let {
                connectivityManager?.unregisterNetworkCallback(it)
                connectivityManager?.bindProcessToNetwork(null)
                currentCallback = null
            }
        } catch (_: Exception) {}
    }
}
