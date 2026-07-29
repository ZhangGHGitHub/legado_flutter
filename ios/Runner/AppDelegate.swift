import Flutter
import UIKit
import WebKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let channel = FlutterMethodChannel(
      name: "legado_flutter/source_login_cookies",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      guard call.method == "clearForSource" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard
        let arguments = call.arguments as? [String: Any],
        let sourceUrl = arguments["sourceUrl"] as? String,
        let sourceHost = URL(string: sourceUrl)?.host?.lowercased(),
        let rawDomain = arguments["registrableDomain"] as? String
      else {
        result(FlutterError(
          code: "invalid_arguments",
          message: "sourceUrl or registrableDomain is invalid",
          details: nil
        ))
        return
      }

      let registrableDomain = rawDomain
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .trimmingCharacters(in: CharacterSet(charactersIn: "."))
        .lowercased()
      guard
        !registrableDomain.isEmpty,
        sourceHost == registrableDomain || sourceHost.hasSuffix(".\(registrableDomain)")
      else {
        result(FlutterError(
          code: "invalid_arguments",
          message: "sourceUrl or registrableDomain is invalid",
          details: nil
        ))
        return
      }

      let cookieStore = WKWebsiteDataStore.default().httpCookieStore
      cookieStore.getAllCookies { cookies in
        let matchingCookies = cookies.filter { cookie in
          let domain = cookie.domain
            .trimmingCharacters(in: CharacterSet(charactersIn: "."))
            .lowercased()
          return domain == sourceHost || domain == registrableDomain
        }
        guard !matchingCookies.isEmpty else {
          result(nil)
          return
        }

        let group = DispatchGroup()
        for cookie in matchingCookies {
          group.enter()
          cookieStore.delete(cookie) {
            group.leave()
          }
        }
        group.notify(queue: .main) {
          result(nil)
        }
      }
    }
  }
}
