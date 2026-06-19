import Foundation

internal struct RetryFailedEventsUseCase {
    private let repository: EventRepository

    init(repository: EventRepository) {
        self.repository = repository
    }

    func callAsFunction() async {
        await repository.retryFailed()
    }
}
