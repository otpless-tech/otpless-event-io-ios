import Foundation

internal protocol EventRepository {
    func pushDeviceEvent(event: DeviceEvent) async -> Result<Void, Error>
    func pushTrackEvent(event: TrackEvent) async -> Result<Void, Error>
    func retryFailed() async
}
