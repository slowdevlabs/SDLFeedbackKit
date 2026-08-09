import Foundation
import XCTest
@testable import SDLFeedbackKit

final class LocalizationTests: XCTestCase {
    func testLocalizationResourcesExistForAllLanguagesAndShareKeys() throws {
        let bundle = SDLFeedbackStrings.bundle
        let languages = ["en", "ko", "es"]
        var referenceKeys: Set<String>?

        for language in languages {
            guard let path = bundle.path(forResource: "Localizable", ofType: "strings", inDirectory: nil, forLocalization: language) else {
                XCTFail("Missing Localizable.strings for \(language)")
                continue
            }

            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
            guard let dict = plist as? [String: String] else {
                XCTFail("Localization file for \(language) is not a dictionary")
                continue
            }

            let keys = Set(dict.keys)
            let duplicateKeys = duplicateKeys(in: data)
            XCTAssertTrue(duplicateKeys.isEmpty, "Duplicate keys found for \(language): \(duplicateKeys.sorted())")
            if let referenceKeys {
                XCTAssertEqual(keys, referenceKeys, "Key set mismatch for \(language)")
            } else {
                referenceKeys = keys
            }
        }
    }

    func testLocalizedLookupReturnsValues() {
        let bundle = SDLFeedbackStrings.bundle
        let keys = [
            "feedback.title",
            "feedback.submit",
            "feedback.category.bug"
        ]

        for key in keys {
            let value = bundle.localizedString(forKey: key, value: nil, table: "Localizable")
            XCTAssertFalse(value.isEmpty)
            XCTAssertNotEqual(value, key)
        }
    }

    private func duplicateKeys(in data: Data) -> [String] {
        guard let text = String(data: data, encoding: .utf8) else {
            return []
        }

        var counts: [String: Int] = [:]
        let pattern = "\"([^\"]+)\"\\s*="

        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return []
        }

        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        regex.enumerateMatches(in: text, options: [], range: range) { match, _, _ in
            guard let match, match.numberOfRanges > 1,
                  let keyRange = Range(match.range(at: 1), in: text) else {
                return
            }
            let key = String(text[keyRange])
            counts[key, default: 0] += 1
        }

        return counts.compactMap { key, count in
            count > 1 ? key : nil
        }
    }
}
