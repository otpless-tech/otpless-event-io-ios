import XCTest
@testable import OtplessEventIO

private final class FakeEventRepository: EventRepository {
    var deviceEvents: [DeviceEvent] = []
    var trackEvents: [TrackEvent] = []
    var failNext = false

    func pushDeviceEvent(event: DeviceEvent) async -> Result<Void, Error> {
        if failNext {
            return .failure(NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "network error"]))
        }
        deviceEvents.append(event)
        return .success(())
    }

    func pushTrackEvent(event: TrackEvent) async -> Result<Void, Error> {
        if failNext {
            return .failure(NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "network error"]))
        }
        trackEvents.append(event)
        return .success(())
    }

    func retryFailed() async {}
}

final class PushDeviceEventUseCaseTests: XCTestCase {

    private var repo: FakeEventRepository!
    private var useCase: PushDeviceEventUseCase!

    override func setUp() {
        super.setUp()
        repo = FakeEventRepository()
        useCase = PushDeviceEventUseCase(repository: repo)
    }

    private func event() -> DeviceEvent {
        DeviceEvent(
            installationId: "inid1",
            sessionId: "tsid1",
            platform: "ios",
            deviceInfo: [:],
            appVersion: "1.0.0",
            appPackageName: "com.example"
        )
    }

    func test_delegates_to_repository_and_returns_success() async {
        let result = await useCase(event())
        if case .failure = result { XCTFail("expected success") }
        XCTAssertEqual(repo.deviceEvents.count, 1)
    }

    func test_passes_exact_event_object_to_repository() async {
        let e = event()
        _ = await useCase(e)
        XCTAssertEqual(repo.deviceEvents.first?.eventId, e.eventId)
        XCTAssertEqual(repo.deviceEvents.first?.installationId, e.installationId)
    }

    func test_propagates_repository_failure() async {
        repo.failNext = true
        let result = await useCase(event())
        switch result {
        case .success:
            XCTFail("expected failure")
        case .failure(let error):
            XCTAssertEqual((error as NSError).localizedDescription, "network error")
        }
    }
}

final class PushTrackEventUseCaseTests: XCTestCase {

    private var repo: FakeEventRepository!
    private var useCase: PushTrackEventUseCase!

    override func setUp() {
        super.setUp()
        repo = FakeEventRepository()
        useCase = PushTrackEventUseCase(repository: repo)
    }

    private func event() -> TrackEvent {
        TrackEvent(
            installationId: "inid1",
            sessionId: "tsid1",
            appId: "appX",
            eventType: .SDK,
            action: .REQUEST,
            eventName: "login"
        )
    }

    func test_delegates_to_repository_and_returns_success() async {
        let result = await useCase(event())
        if case .failure = result { XCTFail("expected success") }
        XCTAssertEqual(repo.trackEvents.count, 1)
    }

    func test_passes_exact_event_object_to_repository() async {
        let e = event()
        _ = await useCase(e)
        XCTAssertEqual(repo.trackEvents.first?.eventName, e.eventName)
        XCTAssertEqual(repo.trackEvents.first?.appId, e.appId)
    }

    func test_propagates_repository_failure() async {
        repo.failNext = true
        let result = await useCase(event())
        switch result {
        case .success:
            XCTFail("expected failure")
        case .failure(let error):
            XCTAssertEqual((error as NSError).localizedDescription, "network error")
        }
    }
}
