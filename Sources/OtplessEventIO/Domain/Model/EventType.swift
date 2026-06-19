import Foundation

public enum EventType: String, Codable {
    case CLIENT
    case CLIENT_TO_SDK
    case SDK
    case SDK_TO_OTPLESS
}
