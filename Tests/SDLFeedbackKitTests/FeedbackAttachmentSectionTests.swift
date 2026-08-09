import XCTest

@testable import SDLFeedbackKit

final class FeedbackAttachmentSectionTests: XCTestCase {
    func testAttachmentSectionInitializesForEmptyState() {
        let section = FeedbackAttachmentSection(
            attachment: nil,
            state: .idle,
            isInteractionDisabled: false,
            onPrimaryAction: {},
            onRemove: {}
        )

        XCTAssertNotNil(section)
    }

    func testAttachmentSectionInitializesForAttachedState() {
        let attachment = FeedbackAttachment(
            data: Data([0x01, 0x02, 0x03]),
            filename: "feedback.jpg",
            mimeType: "image/jpeg"
        )

        let section = FeedbackAttachmentSection(
            attachment: attachment,
            state: .idle,
            isInteractionDisabled: true,
            onPrimaryAction: {},
            onRemove: {}
        )

        XCTAssertNotNil(section)
    }
}
