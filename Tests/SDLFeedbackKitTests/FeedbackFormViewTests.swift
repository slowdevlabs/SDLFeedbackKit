import XCTest
import Foundation

@testable import SDLFeedbackKit

final class FeedbackFormViewTests: XCTestCase {
    func testFeedbackFormViewInitializerCompiles() {
        let view = FeedbackFormView(
            context: FeedbackContext(
                appID: "test-app",
                appName: "Test App"
            ),
            transport: MockTransport()
        )

        XCTAssertNotNil(view)
    }

    func testFeedbackFormViewInitializerWithCallbacksCompiles() {
        let view = FeedbackFormView(
            context: FeedbackContext(
                appID: "test-app",
                appName: "Test App"
            ),
            transport: MockTransport(),
            configuration: .default,
            onSubmitted: { result in
                _ = result.clientID
            },
            onCancelled: {}
        )

        XCTAssertNotNil(view)
    }

    func testFeedbackFormViewInitializerAcceptsPrivacyPolicyURL() {
        let view = FeedbackFormView(
            context: FeedbackContext(
                appID: "test-app",
                appName: "Test App"
            ),
            transport: MockTransport(),
            configuration: FeedbackConfiguration(
                privacyPolicyURL: URL(string: "https://example.invalid/privacy")!
            )
        )

        XCTAssertNotNil(view)
    }
}

private struct MockTransport: FeedbackTransport {
    func submit(_ payload: FeedbackPayload) async throws -> FeedbackSubmissionReceipt {
        FeedbackSubmissionReceipt()
    }
}
