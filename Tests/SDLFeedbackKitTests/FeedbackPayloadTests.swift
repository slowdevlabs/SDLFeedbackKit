import Foundation
import XCTest
@testable import SDLFeedbackKit

final class FeedbackPayloadTests: XCTestCase {
    func testPayloadRetainsAllValues() {
        let attachment = FeedbackAttachment(
            data: Data([0x01]),
            filename: "image.jpg",
            mimeType: "image/jpeg",
            pixelWidth: 100,
            pixelHeight: 50
        )
        let clientID = UUID()
        let createdAt = Date(timeIntervalSince1970: 1_000)

        let payload = FeedbackPayload(
            clientID: clientID,
            appID: "my-app",
            appName: "My App",
            appVersion: "1.2.3",
            buildNumber: "456",
            platform: .iOS,
            osVersion: "17.0",
            localeIdentifier: "en_US",
            category: .bug,
            message: "Something broke",
            email: "user@example.com",
            metadata: ["screen": "settings"],
            attachment: attachment,
            createdAt: createdAt
        )

        XCTAssertEqual(payload.clientID, clientID)
        XCTAssertEqual(payload.appID, "my-app")
        XCTAssertEqual(payload.appName, "My App")
        XCTAssertEqual(payload.appVersion, "1.2.3")
        XCTAssertEqual(payload.buildNumber, "456")
        XCTAssertEqual(payload.platform, .iOS)
        XCTAssertEqual(payload.osVersion, "17.0")
        XCTAssertEqual(payload.localeIdentifier, "en_US")
        XCTAssertEqual(payload.category.id, "bug")
        XCTAssertEqual(payload.message, "Something broke")
        XCTAssertEqual(payload.email, "user@example.com")
        XCTAssertEqual(payload.metadata["screen"], "settings")
        XCTAssertEqual(payload.attachment?.byteCount, 1)
        XCTAssertEqual(payload.createdAt, createdAt)
    }

    func testPayloadSupportsNilEmailNilAttachmentAndEmptyMetadata() {
        let payload = FeedbackPayload(
            clientID: UUID(),
            appID: "my-app",
            appName: "My App",
            platform: .macOS,
            osVersion: "14.0",
            category: .general,
            message: "Hello",
            createdAt: Date(timeIntervalSince1970: 2_000)
        )

        XCTAssertNil(payload.email)
        XCTAssertNil(payload.attachment)
        XCTAssertTrue(payload.metadata.isEmpty)
    }
}
