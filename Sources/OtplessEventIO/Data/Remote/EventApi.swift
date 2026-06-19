import Foundation

internal protocol EventApi {
    func pushDeviceEvent(headers: [String: String], event: DeviceEvent) async throws
    func pushTrackEvent(headers: [String: String], event: TrackEvent) async throws
}

internal enum EventApiConstants {
    static let baseURL = "https://events.otpless.tech/events/"
}
