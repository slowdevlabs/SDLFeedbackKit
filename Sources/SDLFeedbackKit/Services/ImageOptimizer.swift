import Foundation

protocol ImageOptimizer: Sendable {
    func optimize(
        data: Data,
        configuration: AttachmentConfiguration
    ) async throws -> FeedbackAttachment
}
