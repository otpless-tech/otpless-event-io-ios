import Foundation
import os.log

internal final class OtplessEventIOImpl: OtplessEventIOContract {

    static let shared = OtplessEventIOImpl()

    private(set) var appId: String = ""

    var trackingIds: (installationId: String, sessionId: String) {
        return (SharedInfoManager.shared.installationId, SharedInfoManager.shared.sessionId)
    }

    private let queue = DispatchQueue(label: "com.otpless.eventio.events")
    private let initLock = NSLock()
    private let retryLock = NSLock()
    private var initialized = false

    private var deviceEventUseCase: PushDeviceEventUseCase?
    private var trackEventUseCase: PushTrackEventUseCase?
    private var retryFailedUseCase: RetryFailedEventsUseCase?

    private static let log = OSLog(subsystem: "com.otpless.eventio", category: "OtplessEventIO")

    private init() {}

    func initialize(appId: String) {
        initLock.lock()
        self.appId = appId
        defer { initLock.unlock() }
        if initialized { return }
        SharedInfoManager.shared.initialize()
        let repo = EventRepositoryImpl(
            localSource: EventDatabase.getInstance(),
            eventApi: EventApiClient.shared
        )
        deviceEventUseCase = PushDeviceEventUseCase(repository: repo)
        trackEventUseCase = PushTrackEventUseCase(repository: repo)
        retryFailedUseCase = RetryFailedEventsUseCase(repository: repo)
        initialized = true
    }

    func pushDeviceEvent(sdkVersion: String, platform: String?, extras: [String: Any]?) {
        queue.async { [weak self] in
            guard let self = self, let useCase = self.deviceEventUseCase else { return }
            let base = SharedInfoManager.shared.buildDeviceEvent()
            var mergedDeviceInfo = base.deviceInfo
            if let extras = extras, !extras.isEmpty {
                for (key, value) in extras {
                    mergedDeviceInfo[key] = value
                }
            }
            let resolvedPlatform: String
            if let platform = platform, !platform.isEmpty {
                resolvedPlatform = platform
            } else {
                resolvedPlatform = base.platform
            }
            let event = base.copy(
                sdkVersion: sdkVersion,
                platform: resolvedPlatform,
                deviceInfo: mergedDeviceInfo
            )
            let group = DispatchGroup()
            group.enter()
            Task {
                let result = await useCase(event)
                if case .failure(let error) = result {
                    os_log("pushDeviceEvent failed: %{public}@", log: Self.log, type: .error, error.localizedDescription)
                }
                group.leave()
            }
            group.wait()
        }
    }

    func push(_ event: OtplessTrackEvent) {
        queue.async { [weak self] in
            guard let self = self, let useCase = self.trackEventUseCase else { return }
            let trackEvent = TrackEvent.from(
                event: event,
                installationId: SharedInfoManager.shared.installationId,
                sessionId: SharedInfoManager.shared.sessionId,
                appId: self.appId
            )
            let group = DispatchGroup()
            group.enter()
            Task {
                let result = await useCase(trackEvent)
                if case .failure(let error) = result {
                    os_log("push TrackEvent failed: %{public}@", log: Self.log, type: .error, error.localizedDescription)
                }
                group.leave()
            }
            group.wait()
        }
    }

    func retryFailedEvents() {
        guard initialized else { return }
        queue.async { [weak self] in
            guard let self = self else { return }
            guard self.retryLock.try() else { return }
            let group = DispatchGroup()
            group.enter()
            Task {
                await self.retryFailedUseCase?()
                group.leave()
            }
            group.wait()
            self.retryLock.unlock()
        }
    }
}
