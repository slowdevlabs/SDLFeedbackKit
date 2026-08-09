import Foundation
import XCTest
@testable import SDLFeedbackKit

final class FeedbackSubmissionResultTests: XCTestCase {
    func testSubmissionResultRetainsValues() {
        let clientID = UUID()
        let receipt = FeedbackSubmissionReceipt(serverID: "mock-feedback")
        let result = FeedbackSubmissionResult(clientID: clientID, receipt: receipt)

        XCTAssertEqual(result.clientID, clientID)
        XCTAssertEqual(result.receipt, receipt)
    }
}
