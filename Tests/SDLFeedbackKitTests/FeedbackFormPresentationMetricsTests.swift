import XCTest
@testable import SDLFeedbackKit

final class FeedbackFormPresentationMetricsTests: XCTestCase {
    func testCompactWidthMetricsPreservePhoneSizing() {
        XCTAssertEqual(FeedbackFormPresentationMetrics.contentSpacing(isRegularWidth: false), 24)
        XCTAssertEqual(FeedbackFormPresentationMetrics.contentTopPadding(isRegularWidth: false), 24)
        XCTAssertEqual(FeedbackFormPresentationMetrics.contentBottomPadding(isRegularWidth: false), 28)
        XCTAssertEqual(
            FeedbackFormPresentationMetrics.messageEditorMinimumHeight(
                isRegularWidth: false,
                isCompactHeight: false
            ),
            140
        )
    }

    func testRegularWidthMetricsTightenIpadSpacing() {
        XCTAssertEqual(FeedbackFormPresentationMetrics.contentSpacing(isRegularWidth: true), 20)
        XCTAssertEqual(FeedbackFormPresentationMetrics.contentTopPadding(isRegularWidth: true), 20)
        XCTAssertEqual(FeedbackFormPresentationMetrics.contentBottomPadding(isRegularWidth: true), 20)
        XCTAssertEqual(
            FeedbackFormPresentationMetrics.messageEditorMinimumHeight(
                isRegularWidth: true,
                isCompactHeight: false
            ),
            116
        )
    }

    func testRegularWidthButCompactHeightKeepsPhoneLikeEditorHeight() {
        XCTAssertEqual(
            FeedbackFormPresentationMetrics.messageEditorMinimumHeight(
                isRegularWidth: true,
                isCompactHeight: true
            ),
            140
        )
    }
}
