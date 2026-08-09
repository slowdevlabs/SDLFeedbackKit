import Foundation

public struct FeedbackSubmissionResult: Sendable {
    public let clientID: UUID
    public let receipt: FeedbackSubmissionReceipt

    internal init(
        clientID: UUID,
        receipt: FeedbackSubmissionReceipt
    ) {
        self.clientID = clientID
        self.receipt = receipt
    }
}
