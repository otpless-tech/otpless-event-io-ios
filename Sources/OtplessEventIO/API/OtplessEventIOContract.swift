import Foundation

public protocol OtplessEventIOContract {
    var appId: String { get }
    var trackingIds: (installationId: String, sessionId: String) { get }
    func initialize(appId: String)
    func pushDeviceEvent(sdkVersion: String, platform: String?, extras: [String: Any]?)
    func push(_ event: OtplessTrackEvent)
    func retryFailedEvents()
}

public extension OtplessEventIOContract {
    func pushDeviceEvent(sdkVersion: String) {
        pushDeviceEvent(sdkVersion: sdkVersion, platform: nil, extras: nil)
    }
    func pushDeviceEvent(sdkVersion: String, platform: String?) {
        pushDeviceEvent(sdkVersion: sdkVersion, platform: platform, extras: nil)
    }
    func pushDeviceEvent(sdkVersion: String, extras: [String: Any]?) {
        pushDeviceEvent(sdkVersion: sdkVersion, platform: nil, extras: extras)
    }
}
