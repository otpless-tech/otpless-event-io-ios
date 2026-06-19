import Foundation

internal final class EventRepositoryImpl: EventRepository {

    static let typeDevice = "DEVICE"
    static let typeTrack = "MAIN"

    private let localSource: EventLocalSource
    private let eventApi: EventApi

    init(localSource: EventLocalSource, eventApi: EventApi) {
        self.localSource = localSource
        self.eventApi = eventApi
    }

    func pushDeviceEvent(event: DeviceEvent) async -> Result<Void, Error> {
        let bodyJSON: String
        do {
            bodyJSON = try encode(event.toDictionary())
        } catch {
            return .failure(error)
        }
        let id = localSource.insertPending(eventType: Self.typeDevice, body: bodyJSON)
        if id <= 0 {
            return .failure(NSError(
                domain: "OtplessEventIO",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Insert failed"]
            ))
        }
        do {
            try await eventApi.pushDeviceEvent(
                headers: ["tsid": event.sessionId],
                event: event.copy(eventId: String(id))
            )
            localSource.delete(id: id)
            return .success(())
        } catch {
            localSource.markFailed(id: id)
            return .failure(error)
        }
    }

    func pushTrackEvent(event: TrackEvent) async -> Result<Void, Error> {
        let bodyJSON: String
        do {
            bodyJSON = try encode(event.toDictionary())
        } catch {
            return .failure(error)
        }
        let id = localSource.insertPending(eventType: Self.typeTrack, body: bodyJSON)
        if id <= 0 {
            return .failure(NSError(
                domain: "OtplessEventIO",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Insert failed"]
            ))
        }
        do {
            try await eventApi.pushTrackEvent(
                headers: ["tsid": event.sessionId],
                event: event.copy(eventId: id)
            )
            localSource.delete(id: id)
            return .success(())
        } catch {
            localSource.markFailed(id: id)
            return .failure(error)
        }
    }

    func retryFailed() async {
        for pending in localSource.getFailed() {
            guard let dict = decode(pending.body) else { continue }
            do {
                switch pending.eventType {
                case Self.typeDevice:
                    guard let event = DeviceEvent.from(dictionary: dict) else { continue }
                    try await eventApi.pushDeviceEvent(
                        headers: ["tsid": event.sessionId],
                        event: event.copy(eventId: String(pending.id))
                    )
                case Self.typeTrack:
                    guard let event = TrackEvent.from(dictionary: dict) else { continue }
                    try await eventApi.pushTrackEvent(
                        headers: ["tsid": event.sessionId],
                        event: event.copy(eventId: pending.id)
                    )
                default:
                    continue
                }
                localSource.delete(id: pending.id)
            } catch {
                return
            }
        }
    }

    private func encode(_ dict: [String: Any]) throws -> String {
        let data = try JSONSerialization.data(withJSONObject: dict)
        return String(data: data, encoding: .utf8) ?? ""
    }

    private func decode(_ json: String) -> [String: Any]? {
        guard let data = json.data(using: .utf8) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
    }
}
