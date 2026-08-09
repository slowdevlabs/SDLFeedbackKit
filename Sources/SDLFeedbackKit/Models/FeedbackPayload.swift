import Foundation

public struct FeedbackPayload: Sendable {
    public let clientID: UUID

    public let appID: String
    public let appName: String

    public let appVersion: String?
    public let buildNumber: String?

    public let platform: FeedbackPlatform
    public let osVersion: String
    public let localeIdentifier: String?

    public let category: FeedbackCategory

    public let message: String
    public let email: String?

    public let metadata: [String: String]

    public let attachment: FeedbackAttachment?

    public let createdAt: Date

    internal init(
        clientID: UUID,
        appID: String,
        appName: String,
        appVersion: String? = nil,
        buildNumber: String? = nil,
        platform: FeedbackPlatform,
        osVersion: String,
        localeIdentifier: String? = nil,
        category: FeedbackCategory,
        message: String,
        email: String? = nil,
        metadata: [String: String] = [:],
        attachment: FeedbackAttachment? = nil,
        createdAt: Date
    ) {
        self.clientID = clientID
        self.appID = appID
        self.appName = appName
        self.appVersion = appVersion
        self.buildNumber = buildNumber
        self.platform = platform
        self.osVersion = osVersion
        self.localeIdentifier = localeIdentifier
        self.category = category
        self.message = message
        self.email = email
        self.metadata = metadata
        self.attachment = attachment
        self.createdAt = createdAt
    }
}
