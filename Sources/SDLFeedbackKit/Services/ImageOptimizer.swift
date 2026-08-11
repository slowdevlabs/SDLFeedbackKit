import Foundation

protocol ImageOptimizer: Sendable {
    func optimize(
        data: Data,
        configuration: AttachmentConfiguration
    ) async throws -> FeedbackAttachment

    func optimize(
        fileURL: URL,
        configuration: AttachmentConfiguration
    ) async throws -> FeedbackAttachment
}

extension ImageOptimizer {
    func optimize(
        fileURL: URL,
        configuration: AttachmentConfiguration
    ) async throws -> FeedbackAttachment {
        let data = try Data(contentsOf: fileURL, options: .mappedIfSafe)
        return try await optimize(data: data, configuration: configuration)
    }
}
