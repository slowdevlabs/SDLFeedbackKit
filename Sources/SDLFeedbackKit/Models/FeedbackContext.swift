import Foundation

public struct FeedbackContext: Sendable, Hashable {
    public let appID: String
    public let appName: String
    public let metadata: [String: String]

    public init(
        appID: String,
        appName: String,
        metadata: [String: String] = [:]
    ) {
        self.appID = appID
        self.appName = appName
        self.metadata = metadata
    }
}
