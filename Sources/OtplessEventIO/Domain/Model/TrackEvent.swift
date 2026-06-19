import Foundation

internal struct TrackEvent {
    let installationId: String
    let sessionId: String
    let appId: String
    let eventType: EventType
    let action: EventAction
    let eventName: String
    let url: String?
    let statusCode: Int?
    let data: [String: Any]?
    let occurredAt: Int64
    let requestId: String?
    let errorCode: String?
    let token: String?
    let asId: String?
    let eventId: Int64

    init(
        installationId: String,
        sessionId: String,
        appId: String,
        eventType: EventType,
        action: EventAction,
        eventName: String,
        url: String? = nil,
        statusCode: Int? = nil,
        data: [String: Any]? = nil,
        occurredAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        requestId: String? = nil,
        errorCode: String? = nil,
        token: String? = nil,
        asId: String? = nil,
        eventId: Int64 = 0
    ) {
        self.installationId = installationId
        self.sessionId = sessionId
        self.appId = appId
        self.eventType = eventType
        self.action = action
        self.eventName = eventName
        self.url = url
        self.statusCode = statusCode
        self.data = data
        self.occurredAt = occurredAt
        self.requestId = requestId
        self.errorCode = errorCode
        self.token = token
        self.asId = asId
        self.eventId = eventId
    }

    func copy(eventId: Int64? = nil) -> TrackEvent {
        TrackEvent(
            installationId: installationId,
            sessionId: sessionId,
            appId: appId,
            eventType: eventType,
            action: action,
            eventName: eventName,
            url: url,
            statusCode: statusCode,
            data: data,
            occurredAt: occurredAt,
            requestId: requestId,
            errorCode: errorCode,
            token: token,
            asId: asId,
            eventId: eventId ?? self.eventId
        )
    }

    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "inid": installationId,
            "tsid": sessionId,
            "appId": appId,
            "eventType": eventType.rawValue,
            "action": action.rawValue,
            "eventName": eventName,
            "occurredAt": occurredAt,
            "eventId": eventId
        ]
        if let url = url { dict["url"] = url }
        if let statusCode = statusCode { dict["statusCode"] = statusCode }
        if let data = data { dict["data"] = data }
        if let requestId = requestId { dict["xRequestId"] = requestId }
        if let errorCode = errorCode { dict["errorCode"] = errorCode }
        if let token = token { dict["token"] = token }
        if let asId = asId { dict["asId"] = asId }
        return dict
    }

    static func from(dictionary dict: [String: Any]) -> TrackEvent? {
        guard
            let inid = dict["inid"] as? String,
            let tsid = dict["tsid"] as? String,
            let appId = dict["appId"] as? String,
            let eventTypeRaw = dict["eventType"] as? String,
            let eventType = EventType(rawValue: eventTypeRaw),
            let actionRaw = dict["action"] as? String,
            let action = EventAction(rawValue: actionRaw),
            let eventName = dict["eventName"] as? String
        else { return nil }
        let occurredAt = (dict["occurredAt"] as? Int64)
            ?? Int64((dict["occurredAt"] as? NSNumber)?.int64Value ?? 0)
        let eventId = (dict["eventId"] as? Int64)
            ?? Int64((dict["eventId"] as? NSNumber)?.int64Value ?? 0)
        return TrackEvent(
            installationId: inid,
            sessionId: tsid,
            appId: appId,
            eventType: eventType,
            action: action,
            eventName: eventName,
            url: dict["url"] as? String,
            statusCode: dict["statusCode"] as? Int,
            data: dict["data"] as? [String: Any],
            occurredAt: occurredAt,
            requestId: dict["xRequestId"] as? String,
            errorCode: dict["errorCode"] as? String,
            token: dict["token"] as? String,
            asId: dict["asId"] as? String,
            eventId: eventId
        )
    }

    static func from(
        event: OtplessTrackEvent,
        installationId: String,
        sessionId: String,
        appId: String
    ) -> TrackEvent {
        TrackEvent(
            installationId: installationId,
            sessionId: sessionId,
            appId: appId,
            eventType: event.eventType,
            action: event.action,
            eventName: event.eventName,
            url: event.url,
            statusCode: event.statusCode,
            data: event.data,
            requestId: event.requestId,
            errorCode: event.errorCode,
            token: event.token,
            asId: event.asId
        )
    }
}
