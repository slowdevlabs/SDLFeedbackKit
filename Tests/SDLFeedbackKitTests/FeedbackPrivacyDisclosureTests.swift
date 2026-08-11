import Foundation
import XCTest

@testable import SDLFeedbackKit

final class FeedbackPrivacyDisclosureTests: XCTestCase {
    func testDisclosureIsShownOnlyWhenPrivacyPolicyURLExists() {
        XCTAssertFalse(FeedbackPrivacyDisclosure.shouldDisplay(privacyPolicyURL: nil))
        XCTAssertTrue(FeedbackPrivacyDisclosure.shouldDisplay(privacyPolicyURL: URL(string: "https://example.invalid/privacy")))
    }

    func testDisclosureBodyInterpolatesAppName() {
        let body = SDLFeedbackLocalizedStrings.privacyDisclosureBody(appName: "Swipe: Flags", locale: .init(identifier: "en"))

        XCTAssertEqual(body, "Feedback sent to Swipe: Flags may include your message, optional email address, and an attached image.")
    }
}
