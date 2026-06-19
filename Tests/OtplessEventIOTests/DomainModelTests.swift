import XCTest
@testable import OtplessEventIO

final class DomainModelTests: XCTestCase {

    func test_DeviceEvent_auto_generates_a_UUID_eventId() {
        let event = DeviceEvent(
            installationId: "i",
            sessionId: "t",
            platform: "ios",
            deviceInfo: [:],
            appVersion: "1.0.0",
            appPackageName: "com.example"
        )
        let pattern = "^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$"
        let regex = try! NSRegularExpression(pattern: pattern)
        let range = NSRange(event.eventId.startIndex..., in: event.eventId)
        XCTAssertNotNil(regex.firstMatch(in: event.eventId, range: range))
    }

    func test_two_DeviceEvents_without_explicit_eventId_get_different_ids() {
        let e1 = DeviceEvent(installationId: "i", sessionId: "t", platform: "ios", deviceInfo: [:], appVersion: "1.0", appPackageName: "com.example")
        let e2 = DeviceEvent(installationId: "i", sessionId: "t", platform: "ios", deviceInfo: [:], appVersion: "1.0", appPackageName: "com.example")
        XCTAssertNotEqual(e1.eventId, e2.eventId)
    }

    func test_TrackEvent_occurredAt_defaults_to_current_time() {
        let before = Int64(Date().timeIntervalSince1970 * 1000)
        let event = TrackEvent(
            installationId: "i",
            sessionId: "t",
            appId: "app",
            eventType: .SDK,
            action: .RESPONSE,
            eventName: "test"
        )
        let after = Int64(Date().timeIntervalSince1970 * 1000)
        XCTAssertTrue(event.occurredAt >= before && event.occurredAt <= after)
    }
}
