import Foundation
#if canImport(UIKit)
import UIKit
#endif

internal final class SharedInfoManager {

    static let shared = SharedInfoManager()

    private(set) var installationId: String = ""
    private(set) var sessionId: String = ""
    private(set) var appPackageName: String = ""
    private(set) var appVersion: String = ""
    private(set) var deviceInfo: [String: Any] = [:]

    private let initLock = NSLock()
    private var isInit = false

    private static let prefsSuiteName = "otpless_event_prefs"
    private static let keyInstallationId = "inid"
    private static let platform = "ios"

    private init() {}

    func initialize() {
        initLock.lock()
        defer { initLock.unlock() }
        if isInit { return }

        installationId = Self.getOrGenerateInstallationId()
        sessionId = UUID().uuidString + "-" + String(Int64(Date().timeIntervalSince1970 * 1000))

        appPackageName = Bundle.main.bundleIdentifier ?? ""
        appVersion = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? ""
        deviceInfo = Self.buildDeviceInfo()

        isInit = true
    }

    func buildDeviceEvent() -> DeviceEvent {
        DeviceEvent(
            installationId: installationId,
            sessionId: sessionId,
            platform: Self.platform,
            deviceInfo: deviceInfo,
            appVersion: appVersion,
            appPackageName: appPackageName
        )
    }

    private static func getOrGenerateInstallationId() -> String {
        let defaults = UserDefaults(suiteName: prefsSuiteName) ?? UserDefaults.standard
        if let existing = defaults.string(forKey: keyInstallationId),
           !existing.trimmingCharacters(in: .whitespaces).isEmpty {
            return existing
        }
        let newId = UUID().uuidString + "-" + String(Int64(Date().timeIntervalSince1970 * 1000))
        defaults.set(newId, forKey: keyInstallationId)
        return newId
    }

    private static func buildDeviceInfo() -> [String: Any] {
        let (screenWidth, screenHeight) = screenSize()
        return [
            "platform": platform,
            "vendor": "Apple",
            "browser": "",
            "connection": "",
            "language": Locale.current.identifier,
            "cookieEnabled": "",
            "screenWidth": screenWidth,
            "screenHeight": screenHeight,
            "userAgent": userAgent(),
            "timezoneOffset": TimeZone.current.secondsFromGMT() / 60,
            "cpuArchitecture": cpuArchitecture()
        ]
    }

    private static func screenSize() -> (Int, Int) {
        #if canImport(UIKit)
        let bounds = UIScreen.main.bounds
        let scale = UIScreen.main.scale
        return (Int(bounds.width * scale), Int(bounds.height * scale))
        #else
        return (0, 0)
        #endif
    }

    private static func userAgent() -> String {
        let osVersion: String = {
            #if canImport(UIKit)
            return UIDevice.current.systemVersion
            #else
            let v = ProcessInfo.processInfo.operatingSystemVersion
            return "\(v.majorVersion).\(v.minorVersion).\(v.patchVersion)"
            #endif
        }()
        let model: String = {
            #if canImport(UIKit)
            return UIDevice.current.model
            #else
            return "Mac"
            #endif
        }()
        return "\(model)/\(osVersion) otplesssdk"
    }

    private static func cpuArchitecture() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let mirror = Mirror(reflecting: systemInfo.machine)
        var arch = ""
        for child in mirror.children {
            guard let value = child.value as? Int8, value != 0 else { continue }
            arch.append(Character(UnicodeScalar(UInt8(value))))
        }
        return arch
    }
}
