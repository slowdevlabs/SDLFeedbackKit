import XCTest

@testable import SDLFeedbackKit

final class FeedbackAttachmentSectionTests: XCTestCase {
    func testAttachmentPresentationUsesAttachmentSpecificMessage() {
        XCTAssertNotNil(FeedbackAttachmentPresentation.processingMessage(for: .processingAttachment, locale: .init(identifier: "en")))
        XCTAssertNotNil(FeedbackAttachmentPresentation.attachmentErrorMessage(for: .failure(.attachmentProcessingFailed), locale: .init(identifier: "en")))
        XCTAssertNotNil(FeedbackAttachmentPresentation.attachmentErrorMessage(for: .failure(.unsupportedAttachment), locale: .init(identifier: "en")))
        XCTAssertNil(FeedbackAttachmentPresentation.attachmentErrorMessage(for: .failure(.submissionFailed), locale: .init(identifier: "en")))
    }

    func testAttachmentPresentationSuppressesGlobalFailureForAttachmentErrors() {
        XCTAssertTrue(FeedbackAttachmentPresentation.shouldSuppressGlobalFailure(for: .attachmentProcessingFailed))
        XCTAssertTrue(FeedbackAttachmentPresentation.shouldSuppressGlobalFailure(for: .attachmentTooLarge))
        XCTAssertTrue(FeedbackAttachmentPresentation.shouldSuppressGlobalFailure(for: .unsupportedAttachment))
        XCTAssertFalse(FeedbackAttachmentPresentation.shouldSuppressGlobalFailure(for: .submissionFailed))
        XCTAssertFalse(FeedbackAttachmentPresentation.shouldSuppressGlobalFailure(for: .invalidInput))
    }

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
