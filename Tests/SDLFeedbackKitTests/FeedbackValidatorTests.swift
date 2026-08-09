import Foundation
import XCTest
@testable import SDLFeedbackKit

final class FeedbackValidatorTests: XCTestCase {
    private let validator = FeedbackValidator()

    func testValidDraftPasses() throws {
        let context = FeedbackContext(
            appID: "my-app",
            appName: "My App",
            metadata: ["screen": "settings"]
        )
        let draft = FeedbackDraft(
            category: .bug,
            message: "  Hello\nWorld  ",
            email: " user@example.com ",
            attachment: FeedbackAttachment(
                data: Data([0x01]),
                filename: "image.jpg",
                mimeType: "image/jpeg",
                pixelWidth: 100,
                pixelHeight: 200
            )
        )

        XCTAssertNoThrow(try validator.validate(context: context, draft: draft, configuration: .default))
    }

    func testInvalidContextFails() {
        let draft = FeedbackDraft(category: .bug, message: "Hello")
        let invalid = FeedbackContext(appID: "   ", appName: "My App")

        XCTAssertThrowsError(try validator.validate(context: invalid, draft: draft, configuration: .default)) { error in
            XCTAssertEqual(error as? FeedbackError, .invalidInput)
        }
    }

    func testInvalidCategoryFails() {
        let context = FeedbackContext(appID: "my-app", appName: "My App")
        let draft = FeedbackDraft(category: FeedbackCategory(id: "", title: "Bug"), message: "Hello")

        XCTAssertThrowsError(try validator.validate(context: context, draft: draft, configuration: .default)) { error in
            XCTAssertEqual(error as? FeedbackError, .invalidInput)
        }
    }

    func testRequiredMessageRejectsWhitespaceOnly() {
        let context = FeedbackContext(appID: "my-app", appName: "My App")
        let draft = FeedbackDraft(category: .general, message: "   ")

        XCTAssertThrowsError(try validator.validate(context: context, draft: draft, configuration: .default)) { error in
            XCTAssertEqual(error as? FeedbackError, .invalidInput)
        }
    }

    func testOptionalEmptyMessageAllowed() throws {
        let context = FeedbackContext(appID: "my-app", appName: "My App")
        let configuration = FeedbackConfiguration(
            message: MessageConfiguration(minimumLength: 1, maximumLength: 5_000, isRequired: false)
        )
        let draft = FeedbackDraft(category: .general, message: "   ")

        XCTAssertNoThrow(try validator.validate(context: context, draft: draft, configuration: configuration))
    }

    func testEmailValidation() {
        let context = FeedbackContext(appID: "my-app", appName: "My App")
        let draft = FeedbackDraft(category: .general, message: "Hello", email: "not-an-email")

        XCTAssertThrowsError(try validator.validate(context: context, draft: draft, configuration: .default)) { error in
            XCTAssertEqual(error as? FeedbackError, .invalidEmail)
        }
    }

    func testMetadataValidation() {
        let context = FeedbackContext(appID: "my-app", appName: "My App", metadata: ["": "value"])
        let draft = FeedbackDraft(category: .general, message: "Hello")

        XCTAssertThrowsError(try validator.validate(context: context, draft: draft, configuration: .default)) { error in
            XCTAssertEqual(error as? FeedbackError, .invalidInput)
        }
    }

    func testAttachmentValidation() {
        let context = FeedbackContext(appID: "my-app", appName: "My App")
        let attachment = FeedbackAttachment(
            data: Data(count: 1_000_001),
            filename: "image.jpg",
            mimeType: "image/jpeg"
        )
        let draft = FeedbackDraft(category: .general, message: "Hello", attachment: attachment)

        XCTAssertThrowsError(try validator.validate(context: context, draft: draft, configuration: .default)) { error in
            XCTAssertEqual(error as? FeedbackError, .attachmentTooLarge)
        }
    }

    func testInvalidConfigurationThrows() {
        let context = FeedbackContext(appID: "my-app", appName: "My App")
        let draft = FeedbackDraft(category: .general, message: "Hello")
        let configuration = FeedbackConfiguration(
            message: MessageConfiguration(minimumLength: 2, maximumLength: 1, isRequired: true)
        )

        XCTAssertThrowsError(try validator.validate(context: context, draft: draft, configuration: configuration)) { error in
            XCTAssertEqual(error as? FeedbackError, .invalidInput)
        }
    }

    func testCompressionQualityBelowFloorFails() {
        let context = FeedbackContext(appID: "my-app", appName: "My App")
        let draft = FeedbackDraft(category: .general, message: "Hello")
        let configuration = FeedbackConfiguration(
            attachment: AttachmentConfiguration(compressionQuality: 0.49)
        )

        XCTAssertThrowsError(try validator.validate(context: context, draft: draft, configuration: configuration)) { error in
            XCTAssertEqual(error as? FeedbackError, .invalidInput)
        }
    }
}
