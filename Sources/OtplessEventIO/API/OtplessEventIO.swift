import Foundation

public enum OtplessEventIO {

    public static var shared: OtplessEventIOContract { OtplessEventIOImpl.shared }

    public static var appId: String { shared.appId }
    public static var trackingIds: (installationId: String, sessionId: String) { shared.trackingIds }

    public static func initialize(appId: String) {
        shared.initialize(appId: appId)
    }

    public static func pushDeviceEvent(sdkVersion: String, platform: String? = nil, extras: [String: Any]? = nil) {
        shared.pushDeviceEvent(sdkVersion: sdkVersion, platform: platform, extras: extras)
    }

    public static func push(_ event: OtplessTrackEvent) {
        shared.push(event)
    }

    public static func retryFailedEvents() {
        shared.retryFailedEvents()
    }
}
