#if canImport(SwiftUI)
import SwiftUI
import XCTest

@testable import SDLFeedbackKit

final class FeedbackTypographyPolicyTests: XCTestCase {
    func testSystemPolicyPreservesContentSizeCategory() {
        XCTAssertEqual(
            FeedbackTypographyPolicy.system.resolvedSizeCategory(from: .accessibilityExtraExtraLarge),
            .accessibilityExtraExtraLarge
        )
    }

    func testRestrainedPolicyCapsAtExtraExtraExtraLarge() {
        XCTAssertEqual(
            FeedbackTypographyPolicy.restrained.resolvedSizeCategory(from: .accessibilityExtraExtraExtraLarge),
            .extraExtraExtraLarge
        )
        XCTAssertEqual(
            FeedbackTypographyPolicy.restrained.resolvedSizeCategory(from: .extraLarge),
            .extraLarge
        )
    }
}
#endif
