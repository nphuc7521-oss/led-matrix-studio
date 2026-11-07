import UIKit
import Flutter
import NetworkExtension

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let wifiChannel = FlutterMethodChannel(name: "com.ledmatrix.wifi",
                                           binaryMessenger: controller.binaryMessenger)
    
    wifiChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if call.method == "connectWifi" {
        guard let args = call.arguments as? [String: Any],
              let ssid = args["ssid"] as? String,
              let password = args["password"] as? String else {
          result(FlutterError(code: "INVALID_ARGS", message: "Missing ssid or password", details: nil))
          return
        }
        
        let hotspotConfig = NEHotspotConfiguration(ssid: ssid, passphrase: password, isWEP: false)
        hotspotConfig.joinOnce = true
        
        NEHotspotConfigurationManager.shared.apply(hotspotConfig) { error in
          if let error = error {
            let nsError = error as NSError
            if nsError.code == 13 || nsError.code == 8 {
              result(true)
            } else {
              result(FlutterError(code: "CONNECTION_FAILED", message: error.localizedDescription, details: nil))
            }
          } else {
            result(true)
          }
        }
      } else if call.method == "disconnectWifi" {
        guard let args = call.arguments as? [String: Any],
              let ssid = args["ssid"] as? String else {
          result(nil)
          return
        }
        if !ssid.isEmpty {
          NEHotspotConfigurationManager.shared.removeConfiguration(forSSID: ssid)
        }
        result(nil)
      } else if call.method == "bindCurrentWifi" {
        result(true)
      } else if call.method == "openWifiSettings" {
        if let url = URL(string: UIApplication.openSettingsURLString) {
          if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
          }
        }
        result(nil)
      } else if call.method == "getCurrentWifiSsid" {
        if #available(iOS 14.0, *) {
          NEHotspotNetwork.fetchCurrent { network in
            result(network?.ssid ?? "")
          }
        } else {
          result("")
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    })

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
