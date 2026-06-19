import Foundation

public struct OtplessTrackEvent {
    public let eventType: EventType
    public let action: EventAction
    public let eventName: String
    public let url: String?
    public let statusCode: Int?
    public let data: [String: Any]?
    public let requestId: String?
    public let errorCode: String?
    public let token: String?
    public let asId: String?

    public init(
        eventType: EventType,
        action: EventAction,
        eventName: String,
        url: String? = nil,
        statusCode: Int? = nil,
        data: [String: Any]? = nil,
        requestId: String? = nil,
        errorCode: String? = nil,
        token: String? = nil,
        asId: String? = nil
    ) {
        self.eventType = eventType
        self.action = action
        self.eventName = eventName
        self.url = url
        self.statusCode = statusCode
        self.data = data
        self.requestId = requestId
        self.errorCode = errorCode
        self.token = token
        self.asId = asId
    }
}
