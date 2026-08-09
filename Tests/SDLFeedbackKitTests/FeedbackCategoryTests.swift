import XCTest
@testable import SDLFeedbackKit

final class FeedbackCategoryTests: XCTestCase {
    func testCustomCategoryRetainsIdAndTitle() {
        let category = FeedbackCategory(id: "translation", title: "Translation Issue")

        XCTAssertEqual(category.id, "translation")
        XCTAssertEqual(category.title, "Translation Issue")
    }

    func testDefaultCategoryIds() {
        XCTAssertEqual(FeedbackCategory.general.id, "general")
        XCTAssertEqual(FeedbackCategory.bug.id, "bug")
        XCTAssertEqual(FeedbackCategory.featureRequest.id, "feature_request")
        XCTAssertEqual(FeedbackCategory.other.id, "other")
    }

    func testDefaultCategoryTitlesAreLocalized() {
        XCTAssertFalse(FeedbackCategory.general.title.isEmpty)
        XCTAssertFalse(FeedbackCategory.bug.title.isEmpty)
        XCTAssertFalse(FeedbackCategory.featureRequest.title.isEmpty)
        XCTAssertFalse(FeedbackCategory.other.title.isEmpty)
    }
}
