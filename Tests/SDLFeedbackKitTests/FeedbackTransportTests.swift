import Foundation
import XCTest
@testable import SDLFeedbackKit

final class FeedbackTransportTests: XCTestCase {
    private struct MockTransport: FeedbackTransport {
        func submit(
            _ payload: FeedbackPayload
        ) async throws -> FeedbackSubmissionReceipt {
            XCTAssertEqual(payload.appID, "my-app")
            return FeedbackSubmissionReceipt(serverID: "mock-feedback")
        }
    }

    private enum MockError: Error {
        case failed
    }

    private struct FailingTransport: FeedbackTransport {
        func submit(
            _ payload: FeedbackPayload
        ) async throws -> FeedbackSubmissionReceipt {
            throw MockError.failed
        }
    }

    func testMockTransportCanSubmitPayload() async throws {
        let payload = FeedbackPayload(
            clientID: UUID(),
            appID: "my-app",
            appName: "My App",
            platform: .iOS,
            osVersion: "17.0",
            category: .general,
            message: "Hi",
            createdAt: Date(timeIntervalSince1970: 4_000)
        )

        let receipt = try await MockTransport().submit(payload)

        XCTAssertEqual(receipt.serverID, "mock-feedback")
    }

    func testFailingTransportThrows() async {
        let payload = FeedbackPayload(
            clientID: UUID(),
            appID: "my-app",
            appName: "My App",
            platform: .macOS,
            osVersion: "14.0",
            category: .general,
            message: "Hi",
            createdAt: Date(timeIntervalSince1970: 5_000)
        )

        do {
            _ = try await FailingTransport().submit(payload)
            XCTFail("Expected transport to throw")
        } catch is MockError {
            XCTAssertTrue(true)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
}
