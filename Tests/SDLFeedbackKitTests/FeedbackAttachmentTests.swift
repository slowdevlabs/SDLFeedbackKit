import Foundation
import XCTest
@testable import SDLFeedbackKit

final class FeedbackAttachmentTests: XCTestCase {
    func testAttachmentRetainsValuesAndDerivesByteCountFromData() {
        let data = Data([0x01, 0x02, 0x03])
        let attachment = FeedbackAttachment(
            data: data,
            filename: "image.jpg",
            mimeType: "image/jpeg",
            pixelWidth: 640,
            pixelHeight: 480
        )

        XCTAssertEqual(attachment.data, data)
        XCTAssertEqual(attachment.filename, "image.jpg")
        XCTAssertEqual(attachment.mimeType, "image/jpeg")
        XCTAssertEqual(attachment.pixelWidth, 640)
        XCTAssertEqual(attachment.pixelHeight, 480)
        XCTAssertEqual(attachment.byteCount, data.count)
    }

    func testAttachmentAllowsNilDimensions() {
        let attachment = FeedbackAttachment(
            data: Data(),
            filename: "image.jpg",
            mimeType: "image/jpeg"
        )

        XCTAssertNil(attachment.pixelWidth)
        XCTAssertNil(attachment.pixelHeight)
        XCTAssertEqual(attachment.byteCount, 0)
    }
}
