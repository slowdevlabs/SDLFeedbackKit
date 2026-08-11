import XCTest

@testable import SDLFeedbackKit

final class FeedbackCategoryDisclosureStateTests: XCTestCase {
    func testDefaultStateIsCollapsed() {
        let state = FeedbackCategoryDisclosureState()

        XCTAssertFalse(state.isExpanded)
    }

    func testToggleExpandsAndCollapseResets() {
        var state = FeedbackCategoryDisclosureState()

        state.toggle()
        XCTAssertTrue(state.isExpanded)

        state.collapse()
        XCTAssertFalse(state.isExpanded)
    }
}
