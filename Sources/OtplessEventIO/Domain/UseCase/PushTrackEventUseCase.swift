import Foundation

internal struct PushTrackEventUseCase {
    private let repository: EventRepository

    init(repository: EventRepository) {
        self.repository = repository
    }

    func callAsFunction(_ event: TrackEvent) async -> Result<Void, Error> {
        await repository.pushTrackEvent(event: event)
    }
}
