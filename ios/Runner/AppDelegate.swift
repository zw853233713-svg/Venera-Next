import Flutter
import UIKit
import UniformTypeIdentifiers
import Foundation // 添加此行

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let directoryAccess = ScopedDirectoryAccess()
  private var directoryTerminationObserver: NSObjectProtocol?

  // 定义插件通道名称
  private var directoryPicker: DirectoryPicker?

  // The iOS file selector still looks for its presenter on the app delegate.
  override var window: UIWindow? {
    get { activeSceneWindow ?? super.window }
    set { super.window = newValue }
  }

  private var activeSceneWindow: UIWindow? {
    UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .filter { $0.activationState == .foregroundActive }
      .flatMap { $0.windows }
      .first { $0.isKeyWindow }
  }

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    directoryTerminationObserver = NotificationCenter.default.addObserver(
      forName: UIApplication.willTerminateNotification, object: nil, queue: .main
    ) { [weak self] _ in self?.directoryAccess.close() }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let methodChannel = FlutterMethodChannel(
      name: "venera/method_channel",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    methodChannel.setMethodCallHandler { (call, result) in
      if call.method == "isIPhoneDuo" {
        #if targetEnvironment(simulator)
        let model = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"]
        #else
        var system = utsname()
        uname(&system)
        let model = withUnsafeBytes(of: &system.machine) {
          String(decoding: $0.prefix { $0 != 0 }, as: UTF8.self)
        }
        #endif
        result(model == "iPhone19,4")
      } else if call.method == "getProxy" {
        if let proxySettings = CFNetworkCopySystemProxySettings()?.takeUnretainedValue() as NSDictionary?,
          let dict = proxySettings.object(forKey: kCFNetworkProxiesHTTPProxy) as? NSDictionary,
          let host = dict.object(forKey: kCFNetworkProxiesHTTPProxy) as? String,
          let port = dict.object(forKey: kCFNetworkProxiesHTTPPort) as? Int {
          let proxyConfig = "\(host):\(port)"
          result(proxyConfig)
        } else {
          result("")
        }
      } else if call.method == "setScreenOn" {
        if let arguments = call.arguments as? Bool {
          let screenOn = arguments
          UIApplication.shared.isIdleTimerDisabled = screenOn
        }
        result(nil)
      } else if call.method == "getDirectoryPath" {
        self.getDirectoryPath(result: result)
      } else if call.method == "restoreDirectoryAccess" {
        result(self.directoryAccess.restorePersisted())
      } else if call.method == "releaseDirectoryAccess" || call.method == "retainDirectoryAccessForSession" {
        guard let token = call.arguments as? String else {
          result(FlutterError(code: "invalid_arguments", message: "Missing directory token", details: nil))
          return
        }
        do {
          if call.method == "releaseDirectoryAccess" {
            self.directoryAccess.release(token)
          } else {
            try self.directoryAccess.retainForSession(token)
          }
          result(nil)
        } catch {
          result(FlutterError(code: "directory_access", message: String(describing: error), details: nil))
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

  }

  private func getDirectoryPath(result: @escaping FlutterResult) {
    guard directoryPicker == nil else {
      result(FlutterError(code: "picker_busy", message: "Directory picker is already open", details: nil))
      return
    }
    guard let presenter = window?.rootViewController, presenter.presentedViewController == nil else {
      result(FlutterError(code: "picker_unavailable", message: "No available directory picker presenter", details: nil))
      return
    }
    let picker = DirectoryPicker()
    directoryPicker = picker
    picker.selectDirectory(from: presenter) { [weak self] url in
      guard let self = self else {
        result(FlutterError(code: "picker_closed", message: "Directory picker owner closed", details: nil))
        return
      }
      self.directoryPicker = nil
      guard let url = url else { result(nil); return }
      do { result(try self.directoryAccess.acquire(url)) }
      catch { result(FlutterError(code: "directory_access", message: String(describing: error), details: nil)) }
    }
  }

}
