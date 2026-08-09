import Foundation

public struct FeedbackSubmissionReceipt: Sendable, Hashable {
    public let serverID: String?
    public let acceptedAt: Date?

    public init(
        serverID: String? = nil,
        acceptedAt: Date? = nil
    ) {
        self.serverID = serverID
        self.acceptedAt = acceptedAt
    }
}
