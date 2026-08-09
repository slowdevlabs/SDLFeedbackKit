import Foundation
import XCTest
@testable import SDLFeedbackKit

final class DefaultPlatformInfoProviderTests: XCTestCase {
    private final class MockBundle: Bundle, @unchecked Sendable {
        private let values: [String: Any]

        init(values: [String: Any]) {
            self.values = values
            super.init()
        }

        override func object(forInfoDictionaryKey key: String) -> Any? {
            values[key]
        }
    }

    func testProviderReadsBundleAndSystemValues() {
        let bundle = MockBundle(values: [
            "CFBundleShortVersionString": "1.2.3",
            "CFBundleVersion": "42"
        ])
        let provider = DefaultPlatformInfoProvider(bundle: bundle)
        let info = provider.currentInfo()

        XCTAssertEqual(info.appVersion, "1.2.3")
        XCTAssertEqual(info.buildNumber, "42")
        #if os(macOS)
        XCTAssertEqual(info.platform, .macOS)
        #elseif os(iOS)
        XCTAssertEqual(info.platform, .iOS)
        #endif
        XCTAssertFalse(info.osVersion.isEmpty)
        XCTAssertFalse(info.localeIdentifier?.isEmpty ?? true)
    }

    func testProviderReturnsNilForMissingBundleValues() {
        let bundle = MockBundle(values: [:])
        let provider = DefaultPlatformInfoProvider(bundle: bundle)
        let info = provider.currentInfo()

        XCTAssertNil(info.appVersion)
        XCTAssertNil(info.buildNumber)
    }
}
