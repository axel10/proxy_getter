import Flutter
import Foundation
import CFNetwork

public class ProxyGetterPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "proxy_getter/system_proxy",
      binaryMessenger: registrar.messenger()
    )
    let instance = ProxyGetterPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getSystemProxy":
      result(readSystemProxy())
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func readSystemProxy() -> [String: Any] {
    guard let settings = CFNetworkCopySystemProxySettings()?.takeRetainedValue() as? [String: Any] else {
      return emptyProxy()
    }

    let candidates: [(enabledKey: String, hostKey: String, portKey: String)] = [
      (kCFNetworkProxiesHTTPEnable as String, kCFNetworkProxiesHTTPProxy as String, kCFNetworkProxiesHTTPPort as String),
      (kCFNetworkProxiesHTTPSEnable as String, kCFNetworkProxiesHTTPSProxy as String, kCFNetworkProxiesHTTPSPort as String),
      (kCFNetworkProxiesSOCKSEnable as String, kCFNetworkProxiesSOCKSProxy as String, kCFNetworkProxiesSOCKSPort as String),
    ]

    for candidate in candidates {
      if isEnabled(settings[candidate.enabledKey]) {
        let host = settings[candidate.hostKey] as? String ?? ""
        let port = intValue(settings[candidate.portKey])
        if !host.isEmpty && port > 0 {
          return [
            "enable": true,
            "host": host,
            "port": port,
            "bypass": (settings[kCFNetworkProxiesExceptionsList as String] as? [String] ?? []).joined(separator: ","),
          ]
        }
      }
    }

    return emptyProxy()
  }

  private func emptyProxy() -> [String: Any] {
    [
      "enable": false,
      "host": "",
      "port": 0,
      "bypass": "",
    ]
  }

  private func isEnabled(_ value: Any?) -> Bool {
    if let number = value as? NSNumber {
      return number.intValue != 0
    }
    if let boolValue = value as? Bool {
      return boolValue
    }
    return false
  }

  private func intValue(_ value: Any?) -> Int {
    if let number = value as? NSNumber {
      return number.intValue
    }
    if let string = value as? String {
      return Int(string) ?? 0
    }
    return 0
  }
}
