import Foundation

internal struct PendingEvent {
    let id: Int64
    let eventType: String
    let body: String
}

internal protocol EventLocalSource {
    func insertPending(eventType: String, body: String) -> Int64
    func delete(id: Int64)
    func markFailed(id: Int64)
    func getFailed() -> [PendingEvent]
    func deleteAllFailed()
}
