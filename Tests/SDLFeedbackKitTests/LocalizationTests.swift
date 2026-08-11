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
            "feedback.category.bug",
            "feedback.privacy.policy",
            "feedback.privacy.disclosure.body"
        ]

        for key in keys {
            let value = bundle.localizedString(forKey: key, value: nil, table: "Localizable")
            XCTAssertFalse(value.isEmpty)
            XCTAssertNotEqual(value, key)
        }
    }

    func testLocalizedStringsResolveForExplicitLocales() {
        let english = Locale(identifier: "en")
        let korean = Locale(identifier: "ko")
        let spanish = Locale(identifier: "es")

        XCTAssertEqual(SDLFeedbackLocalizedStrings.title(locale: english), "Send Feedback")
        XCTAssertEqual(SDLFeedbackLocalizedStrings.title(locale: korean), "의견 보내기")
        XCTAssertEqual(SDLFeedbackLocalizedStrings.title(locale: spanish), "Enviar comentarios")

        XCTAssertEqual(SDLFeedbackLocalizedStrings.categoryGeneral(locale: english), "General Feedback")
        XCTAssertEqual(SDLFeedbackLocalizedStrings.categoryGeneral(locale: korean), "일반 의견")
        XCTAssertEqual(SDLFeedbackLocalizedStrings.categoryGeneral(locale: spanish), "Comentarios generales")

        XCTAssertEqual(SDLFeedbackLocalizedStrings.categoryCollapsed(locale: english), "Collapsed")
        XCTAssertEqual(SDLFeedbackLocalizedStrings.categoryCollapsed(locale: korean), "접힘")
        XCTAssertEqual(SDLFeedbackLocalizedStrings.categoryCollapsed(locale: spanish), "Colapsado")

        XCTAssertEqual(SDLFeedbackLocalizedStrings.categoryExpanded(locale: english), "Expanded")
        XCTAssertEqual(SDLFeedbackLocalizedStrings.categoryExpanded(locale: korean), "펼쳐짐")
        XCTAssertEqual(SDLFeedbackLocalizedStrings.categoryExpanded(locale: spanish), "Expandido")

        XCTAssertEqual(SDLFeedbackLocalizedStrings.messagePlaceholder(locale: english), "Tell us your feedback or describe the issue in detail.")
        XCTAssertEqual(SDLFeedbackLocalizedStrings.messagePlaceholder(locale: korean), "의견이나 문제 상황을 자세히 적어주세요.")
        XCTAssertEqual(SDLFeedbackLocalizedStrings.messagePlaceholder(locale: spanish), "Cuéntanos tu opinión o describe el problema con detalle.")

        XCTAssertEqual(SDLFeedbackLocalizedStrings.errorInvalidEmail(locale: english), "Enter a valid email address.")
        XCTAssertEqual(SDLFeedbackLocalizedStrings.errorInvalidEmail(locale: korean), "올바른 이메일 주소를 입력해 주세요.")
        XCTAssertEqual(SDLFeedbackLocalizedStrings.errorInvalidEmail(locale: spanish), "Introduce una dirección de correo electrónico válida.")

        XCTAssertEqual(SDLFeedbackLocalizedStrings.optional(locale: english), "Optional")
        XCTAssertEqual(SDLFeedbackLocalizedStrings.optional(locale: korean), "선택")
        XCTAssertEqual(SDLFeedbackLocalizedStrings.optional(locale: spanish), "Opcional")

        XCTAssertEqual(
            "\(SDLFeedbackLocalizedStrings.emailTitle(locale: english)) (\(SDLFeedbackLocalizedStrings.optional(locale: english)))",
            "Email (Optional)"
        )
        XCTAssertEqual(
            "\(SDLFeedbackLocalizedStrings.emailTitle(locale: korean)) (\(SDLFeedbackLocalizedStrings.optional(locale: korean)))",
            "이메일 (선택)"
        )
        XCTAssertEqual(
            "\(SDLFeedbackLocalizedStrings.emailTitle(locale: spanish)) (\(SDLFeedbackLocalizedStrings.optional(locale: spanish)))",
            "Correo electrónico (Opcional)"
        )

        XCTAssertEqual(
            "\(SDLFeedbackLocalizedStrings.attachmentTitle(locale: english)) (\(SDLFeedbackLocalizedStrings.optional(locale: english)))",
            "Attachment (Optional)"
        )
        XCTAssertEqual(
            "\(SDLFeedbackLocalizedStrings.attachmentTitle(locale: korean)) (\(SDLFeedbackLocalizedStrings.optional(locale: korean)))",
            "첨부 (선택)"
        )
        XCTAssertEqual(
            "\(SDLFeedbackLocalizedStrings.attachmentTitle(locale: spanish)) (\(SDLFeedbackLocalizedStrings.optional(locale: spanish)))",
            "Adjunto (Opcional)"
        )
    }

    func testPrivacyDisclosureUsesExplicitLocaleAndAppName() {
        let english = SDLFeedbackLocalizedStrings.privacyDisclosureBody(appName: "Example App", locale: .init(identifier: "en"))
        let korean = SDLFeedbackLocalizedStrings.privacyDisclosureBody(appName: "Example App", locale: .init(identifier: "ko"))
        let spanish = SDLFeedbackLocalizedStrings.privacyDisclosureBody(appName: "Example App", locale: .init(identifier: "es"))

        XCTAssertEqual(english, "Feedback sent to Example App may include your message, optional email address, and an attached image.")
        XCTAssertEqual(korean, "Example App에 보내는 피드백에는 입력한 내용, 선택적 이메일 및 첨부 이미지가 포함될 수 있습니다.")
        XCTAssertEqual(spanish, "Los comentarios enviados a Example App pueden incluir tu mensaje, correo electrónico opcional y una imagen adjunta.")
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
