import XCTest
@testable import SDLFeedbackKit

final class FeedbackContextTests: XCTestCase {
    func testContextRetainsValuesAndDefaultMetadataIsEmpty() {
        let context = FeedbackContext(appID: "my-app", appName: "My App")

        XCTAssertEqual(context.appID, "my-app")
        XCTAssertEqual(context.appName, "My App")
        XCTAssertTrue(context.metadata.isEmpty)
    }

    func testContextRetainsCustomMetadata() {
        let context = FeedbackContext(
            appID: "my-app",
            appName: "My App",
            metadata: ["screen": "settings"]
        )

        XCTAssertEqual(context.metadata["screen"], "settings")
    }
}
