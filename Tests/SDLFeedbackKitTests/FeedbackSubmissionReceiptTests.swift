import Foundation
import XCTest
@testable import SDLFeedbackKit

final class FeedbackSubmissionReceiptTests: XCTestCase {
    func testEmptyReceiptCanBeCreated() {
        let receipt = FeedbackSubmissionReceipt()

        XCTAssertNil(receipt.serverID)
        XCTAssertNil(receipt.acceptedAt)
    }

    func testReceiptRetainsValuesAndIsHashable() {
        let acceptedAt = Date(timeIntervalSince1970: 3_000)
        let receipt = FeedbackSubmissionReceipt(serverID: "mock-feedback", acceptedAt: acceptedAt)

        XCTAssertEqual(receipt.serverID, "mock-feedback")
        XCTAssertEqual(receipt.acceptedAt, acceptedAt)

        let set: Set<FeedbackSubmissionReceipt> = [receipt]
        XCTAssertEqual(set.count, 1)
    }
}
