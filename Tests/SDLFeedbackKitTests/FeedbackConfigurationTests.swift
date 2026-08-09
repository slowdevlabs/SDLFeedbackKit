import XCTest
@testable import SDLFeedbackKit

final class FeedbackConfigurationTests: XCTestCase {
    func testMessageConfigurationDefaultValues() {
        let configuration = MessageConfiguration.default

        XCTAssertEqual(configuration.minimumLength, 1)
        XCTAssertEqual(configuration.maximumLength, 5_000)
        XCTAssertTrue(configuration.isRequired)
    }

    func testEmailFieldConfigurationDefaultValues() {
        let configuration = EmailFieldConfiguration.default

        XCTAssertTrue(configuration.isEnabled)
        XCTAssertFalse(configuration.isRequired)
        XCTAssertEqual(configuration.maximumLength, 320)
    }

    func testAttachmentConfigurationDefaultValues() {
        let configuration = AttachmentConfiguration.default

        XCTAssertTrue(configuration.isEnabled)
        XCTAssertEqual(configuration.maximumAttachmentBytes, 1_000_000)
        XCTAssertEqual(configuration.maximumImageDimension, 1_800)
        XCTAssertEqual(configuration.compressionQuality, 0.8, accuracy: 0.0001)
    }

    func testFeedbackConfigurationDefaultValues() {
        let configuration = FeedbackConfiguration.default

        XCTAssertEqual(configuration.categories.count, 4)
        XCTAssertTrue(configuration.showsCancelButton)
    }
}
