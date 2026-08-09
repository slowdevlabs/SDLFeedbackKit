import Foundation

struct PlatformInfo: Sendable, Equatable {
    let appVersion: String?
    let buildNumber: String?
    let platform: FeedbackPlatform
    let osVersion: String
    let localeIdentifier: String?
}
