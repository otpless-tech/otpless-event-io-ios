import Foundation

internal struct PushDeviceEventUseCase {
    private let repository: EventRepository

    init(repository: EventRepository) {
        self.repository = repository
    }

    func callAsFunction(_ event: DeviceEvent) async -> Result<Void, Error> {
        await repository.pushDeviceEvent(event: event)
    }
}
