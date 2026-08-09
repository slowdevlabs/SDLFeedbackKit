import Foundation
import SDLFeedbackKit

struct ExampleFeedbackTransport: FeedbackTransport {
    let mode: Mode

    func submit(
        _ payload: FeedbackPayload
    ) async throws -> FeedbackSubmissionReceipt {
        try await Task.sleep(nanoseconds: 250_000_000)

        switch mode {
        case .success:
            return FeedbackSubmissionReceipt(
                serverID: "example-feedback-id",
                acceptedAt: Date()
            )
        case .failure:
            throw ExampleTransportError.failed
        }
    }
}

private enum ExampleTransportError: Error {
    case failed
}

enum Mode: String, CaseIterable, Identifiable {
    case success
    case failure

    var id: String { rawValue }

    var title: String {
        switch self {
        case .success:
            return "Success"
        case .failure:
            return "Failure"
        }
    }
}
