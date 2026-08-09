import Foundation

public protocol FeedbackTransport: Sendable {
    func submit(
        _ payload: FeedbackPayload
    ) async throws -> FeedbackSubmissionReceipt
}
