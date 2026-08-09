import Foundation
import XCTest
@testable import SDLFeedbackKit

final class FeedbackPayloadBuilderTests: XCTestCase {
    private struct StubPlatformInfoProvider: PlatformInfoProvider {
        let info: PlatformInfo

        func currentInfo() -> PlatformInfo {
            info
        }
    }

    func testBuilderMapsFieldsAndNormalizesInput() throws {
        let provider = StubPlatformInfoProvider(
            info: PlatformInfo(
                appVersion: "1.2.3",
                buildNumber: "42",
                platform: .iOS,
                osVersion: "17.0",
                localeIdentifier: "ko_KR"
            )
        )
        let builder = FeedbackPayloadBuilder(platformInfoProvider: provider)
        let context = FeedbackContext(
            appID: "  my-app  ",
            appName: "  My App  ",
            metadata: ["screen": "settings"]
        )
        let attachment = FeedbackAttachment(
            data: Data([0x01, 0x02]),
            filename: "image.jpg",
            mimeType: "image/jpeg",
            pixelWidth: 320,
            pixelHeight: 240
        )
        let draft = FeedbackDraft(
            category: .bug,
            message: "  Hello\nWorld  ",
            email: " user@example.com ",
            attachment: attachment
        )
        let clientID = UUID(uuidString: "2E4199E2-907A-47C1-98CE-BC23EEA96C21")!
        let createdAt = Date(timeIntervalSince1970: 1234)

        let payload = try builder.build(
            context: context,
            draft: draft,
            configuration: .default,
            clientID: clientID,
            createdAt: createdAt
        )

        XCTAssertEqual(payload.clientID, clientID)
        XCTAssertEqual(payload.appID, "my-app")
        XCTAssertEqual(payload.appName, "My App")
        XCTAssertEqual(payload.appVersion, "1.2.3")
        XCTAssertEqual(payload.buildNumber, "42")
        XCTAssertEqual(payload.platform, .iOS)
        XCTAssertEqual(payload.osVersion, "17.0")
        XCTAssertEqual(payload.localeIdentifier, "ko_KR")
        XCTAssertEqual(payload.category.id, "bug")
        XCTAssertEqual(payload.message, "Hello\nWorld")
        XCTAssertEqual(payload.email, "user@example.com")
        XCTAssertEqual(payload.metadata["screen"], "settings")
        XCTAssertEqual(payload.attachment?.byteCount, 2)
        XCTAssertEqual(payload.createdAt, createdAt)
    }

    func testDisabledEmailAndAttachmentAreOmitted() throws {
        let provider = StubPlatformInfoProvider(
            info: PlatformInfo(
                appVersion: nil,
                buildNumber: nil,
                platform: .macOS,
                osVersion: "14.0",
                localeIdentifier: "en_US"
            )
        )
        let builder = FeedbackPayloadBuilder(platformInfoProvider: provider)
        let attachment = FeedbackAttachment(
            data: Data([0x01]),
            filename: "image.jpg",
            mimeType: "image/jpeg"
        )
        let configuration = FeedbackConfiguration(
            emailField: EmailFieldConfiguration(isEnabled: false, isRequired: true, maximumLength: 320),
            attachment: AttachmentConfiguration(isEnabled: false)
        )
        let draft = FeedbackDraft(
            category: .general,
            message: "Hello",
            email: "user@example.com",
            attachment: attachment
        )

        let payload = try builder.build(
            context: FeedbackContext(appID: "my-app", appName: "My App"),
            draft: draft,
            configuration: configuration,
            clientID: UUID(),
            createdAt: Date(timeIntervalSince1970: 1)
        )

        XCTAssertNil(payload.email)
        XCTAssertNil(payload.attachment)
    }

    func testBuilderThrowsForInvalidInput() {
        let provider = StubPlatformInfoProvider(
            info: PlatformInfo(
                appVersion: nil,
                buildNumber: nil,
                platform: .macOS,
                osVersion: "14.0",
                localeIdentifier: "en_US"
            )
        )
        let builder = FeedbackPayloadBuilder(platformInfoProvider: provider)

        XCTAssertThrowsError(
            try builder.build(
                context: FeedbackContext(appID: " ", appName: "My App"),
                draft: FeedbackDraft(category: .general, message: "Hello"),
                configuration: .default,
                clientID: UUID(),
                createdAt: Date()
            )
        ) { error in
            XCTAssertEqual(error as? FeedbackError, .invalidInput)
        }
    }
}
