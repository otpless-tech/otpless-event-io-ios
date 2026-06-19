import Foundation

internal struct DeviceEvent {
    let installationId: String
    let sessionId: String
    let platform: String
    let sdkVersion: String
    let deviceInfo: [String: Any]
    let appVersion: String
    let appPackageName: String
    let eventId: String

    init(
        installationId: String,
        sessionId: String,
        platform: String,
        sdkVersion: String = "",
        deviceInfo: [String: Any],
        appVersion: String,
        appPackageName: String,
        eventId: String = UUID().uuidString.lowercased()
    ) {
        self.installationId = installationId
        self.sessionId = sessionId
        self.platform = platform
        self.sdkVersion = sdkVersion
        self.deviceInfo = deviceInfo
        self.appVersion = appVersion
        self.appPackageName = appPackageName
        self.eventId = eventId
    }

    func copy(
        sdkVersion: String? = nil,
        platform: String? = nil,
        deviceInfo: [String: Any]? = nil,
        eventId: String? = nil
    ) -> DeviceEvent {
        DeviceEvent(
            installationId: installationId,
            sessionId: sessionId,
            platform: platform ?? self.platform,
            sdkVersion: sdkVersion ?? self.sdkVersion,
            deviceInfo: deviceInfo ?? self.deviceInfo,
            appVersion: appVersion,
            appPackageName: appPackageName,
            eventId: eventId ?? self.eventId
        )
    }

    func toDictionary() -> [String: Any] {
        return [
            "inid": installationId,
            "tsid": sessionId,
            "platform": platform,
            "sdkVersion": sdkVersion,
            "deviceInfo": deviceInfo,
            "appVersion": appVersion,
            "appPackageName": appPackageName,
            "eventId": eventId
        ]
    }

    static func from(dictionary dict: [String: Any]) -> DeviceEvent? {
        guard
            let inid = dict["inid"] as? String,
            let tsid = dict["tsid"] as? String,
            let platform = dict["platform"] as? String,
            let deviceInfo = dict["deviceInfo"] as? [String: Any],
            let appVersion = dict["appVersion"] as? String,
            let appPackageName = dict["appPackageName"] as? String
        else { return nil }
        let sdkVersion = (dict["sdkVersion"] as? String) ?? ""
        let eventId = (dict["eventId"] as? String) ?? UUID().uuidString.lowercased()
        return DeviceEvent(
            installationId: inid,
            sessionId: tsid,
            platform: platform,
            sdkVersion: sdkVersion,
            deviceInfo: deviceInfo,
            appVersion: appVersion,
            appPackageName: appPackageName,
            eventId: eventId
        )
    }
}
