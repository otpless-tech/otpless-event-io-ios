import Foundation

internal final class EventApiClient: EventApi {

    static let shared: EventApi = EventApiClient()

    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 30
        self.session = URLSession(configuration: config)
    }

    func pushDeviceEvent(headers: [String: String], event: DeviceEvent) async throws {
        try await post(endpoint: "device-event", headers: headers, body: event.toDictionary())
    }

    func pushTrackEvent(headers: [String: String], event: TrackEvent) async throws {
        try await post(endpoint: "track-event", headers: headers, body: event.toDictionary())
    }

    private func post(endpoint: String, headers: [String: String], body: [String: Any]) async throws {
        guard let url = URL(string: EventApiConstants.baseURL + endpoint) else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        _ = try await dataTask(for: request)
    }

    private func dataTask(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await withCheckedThrowingContinuation { continuation in
            let task = session.dataTask(with: request) { data, response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let data = data, let response = response {
                    continuation.resume(returning: (data, response))
                } else {
                    continuation.resume(throwing: URLError(.unknown))
                }
            }
            task.resume()
        }
    }
}
