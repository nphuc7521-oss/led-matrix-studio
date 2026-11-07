package com.ledstudio.led_matrix_app

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.ConnectivityManager
import android.net.LinkProperties
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.net.wifi.WifiManager
import android.net.wifi.WifiNetworkSpecifier
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.ledmatrix.wifi"
    private var connectivityManager: ConnectivityManager? = null
    private var currentCallback: ConnectivityManager.NetworkCallback? = null
    private var activeBoundNetwork: Network? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    private fun requestWifiPermissionsIfNeeded() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                if (checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
                    requestPermissions(
                        arrayOf(
                            Manifest.permission.ACCESS_FINE_LOCATION,
                            Manifest.permission.ACCESS_COARSE_LOCATION
                        ),
                        1001
                    )
                }
            }
        } catch (e: Exception) {
        }
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        connectivityManager = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        requestWifiPermissionsIfNeeded()

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
                    val force = call.argument<Boolean>("force") ?: false
                    connectToWifi(ssid, password, force, result)
                }
                "disconnectWifi" -> {
                    disconnectWifi()
                    result.success(true)
                }
                "openWifiSettings" -> {
                    openWifiSettings()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun openWifiSettings() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val panelIntent = Intent(Settings.Panel.ACTION_WIFI)
                panelIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(panelIntent)
            } else {
                val wifiIntent = Intent(Settings.ACTION_WIFI_SETTINGS)
                wifiIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(wifiIntent)
            }
        } catch (e: Exception) {
            try {
                val wifiIntent = Intent(Settings.ACTION_WIFI_SETTINGS)
                wifiIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(wifiIntent)
            } catch (e2: Exception) {
            }
        }
    }

    private fun bindCurrentWifi(): Boolean {
        try {
            val cm = connectivityManager ?: return false
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                // Ưu tiên tuyệt đối network object vừa được cấp từ WifiNetworkSpecifier
                val active = activeBoundNetwork
                if (active != null) {
                    val caps = cm.getNetworkCapabilities(active)
                    if (caps != null && caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI)) {
                        return cm.bindProcessToNetwork(active)
                    }
                }

                // Duyệt ngược từ mạng mới nhất (netId cao nhất) về cũ nhất để tránh bắt nhầm netId cũ bị treo DHCP NAK
                var targetNet: Network? = null
                for (network in cm.allNetworks.reversed()) {
                    val caps = cm.getNetworkCapabilities(network)
                    val lp = cm.getLinkProperties(network)
                    if (caps != null && caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI)) {
                        val hasIp4 = lp?.linkAddresses?.any {
                            it.address.hostAddress?.startsWith("192.168.4.") == true
                        } == true
                        if (hasIp4) {
                            targetNet = network
                            break
                        }
                        if (targetNet == null) {
                            targetNet = network
                        }
                    }
                }
                if (targetNet != null) {
                    return cm.bindProcessToNetwork(targetNet)
                }
            }
        } catch (e: Exception) {
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
            if (ssid == "<unknown ssid>" || ssid == "<unknown ssid>".uppercase()) ssid = ""
            return ssid
        } catch (e: Exception) {
            return ""
        }
    }

    private fun hasActiveCardIp(): Boolean {
        try {
            val cm = connectivityManager ?: return false
            for (network in cm.allNetworks.reversed()) {
                val caps = cm.getNetworkCapabilities(network)
                val lp = cm.getLinkProperties(network)
                if (caps != null && caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI)) {
                    val hasIp4 = lp?.linkAddresses?.any {
                        it.address.hostAddress?.startsWith("192.168.4.") == true
                    } == true
                    if (hasIp4) return true
                }
            }
        } catch (e: Exception) {
        }
        return false
    }

    private fun connectToWifi(ssid: String, pass: String, force: Boolean, result: MethodChannel.Result) {
        requestWifiPermissionsIfNeeded()

        val currentSsid = getCurrentWifiSsid()
        if (!force && currentSsid.isNotEmpty() && currentSsid.equals(ssid, ignoreCase = true) && hasActiveCardIp()) {
            bindCurrentWifi()
            result.success(true)
            return
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            try {
                // Hủy đăng ký callback cũ trước khi yêu cầu mạng mới để tránh rò rỉ hoặc kẹt kết nối
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
                        activeBoundNetwork = network
                        connectivityManager?.bindProcessToNetwork(network)
                        // Chờ tối đa 1500ms nếu onLinkPropertiesChanged chưa kích hoạt để đảm bảo DHCP 192.168.4.x hoàn tất
                        mainHandler.postDelayed({
                            if (!hasResponded) {
                                hasResponded = true
                                activeBoundNetwork = network
                                connectivityManager?.bindProcessToNetwork(network)
                                result.success(true)
                            }
                        }, 1500)
                    }

                    override fun onLinkPropertiesChanged(network: Network, linkProperties: LinkProperties) {
                        super.onLinkPropertiesChanged(network, linkProperties)
                        activeBoundNetwork = network
                        connectivityManager?.bindProcessToNetwork(network)
                        val hasCardIp = linkProperties.linkAddresses.any {
                            it.address.hostAddress?.startsWith("192.168.4.") == true
                        }
                        if (hasCardIp && !hasResponded) {
                            hasResponded = true
                            // Đợi 450ms sau khi nhận IP 192.168.4.x để MIUI ConnectivityService hoàn tất Adding iface wlan0 to network
                            mainHandler.postDelayed({
                                activeBoundNetwork = network
                                connectivityManager?.bindProcessToNetwork(network)
                                result.success(true)
                            }, 450)
                        }
                    }

                    override fun onUnavailable() {
                        super.onUnavailable()
                        bindCurrentWifi()
                        if (!hasResponded) {
                            hasResponded = true
                            runOnUiThread { result.success(false) }
                        }
                    }

                    override fun onLost(network: Network) {
                        super.onLost(network)
                        if (activeBoundNetwork == network) {
                            activeBoundNetwork = null
                        }
                    }
                }

                currentCallback = callback
                // Timeout 15 giây để người dùng đủ thời gian bấm "Kết nối" trên hộp thoại hệ thống Android/MIUI và nhận DHCP
                connectivityManager?.requestNetwork(request, callback, 15000)
            } catch (e: Exception) {
                bindCurrentWifi()
                result.success(false)
            }
        } else {
            bindCurrentWifi()
            result.success(true)
        }
    }

    private fun disconnectWifi() {
        activeBoundNetwork = null
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                connectivityManager?.bindProcessToNetwork(null)
            }
        } catch (e: Exception) {
        }
        try {
            currentCallback?.let {
                connectivityManager?.unregisterNetworkCallback(it)
                currentCallback = null
            }
        } catch (e: Exception) {
        }
    }
}
