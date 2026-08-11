import Foundation
import XCTest

@testable import SDLFeedbackKit

final class FeedbackEmailValidationTests: XCTestCase {
    func testEmptyOptionalEmailIsValid() {
        let configuration = EmailFieldConfiguration(isEnabled: true, isRequired: false, maximumLength: 320)

        XCTAssertNil(FeedbackEmailValidation.validationError(for: nil, configuration: configuration))
        XCTAssertNil(FeedbackEmailValidation.validationError(for: "", configuration: configuration))
    }

    func testValidEmailAddressesPass() {
        let configuration = EmailFieldConfiguration(isEnabled: true, isRequired: false, maximumLength: 320)

        XCTAssertNil(FeedbackEmailValidation.validationError(for: "name@example.com", configuration: configuration))
        XCTAssertNil(FeedbackEmailValidation.validationError(for: "user.name+feedback@example.co.kr", configuration: configuration))
    }

    func testInvalidEmailAddressesFail() {
        let configuration = EmailFieldConfiguration(isEnabled: true, isRequired: false, maximumLength: 320)

        XCTAssertEqual(FeedbackEmailValidation.validationError(for: "@example.com", configuration: configuration), .invalidEmail)
        XCTAssertEqual(FeedbackEmailValidation.validationError(for: "user@", configuration: configuration), .invalidEmail)
        XCTAssertEqual(FeedbackEmailValidation.validationError(for: "user example@example.com", configuration: configuration), .invalidEmail)
        XCTAssertEqual(FeedbackEmailValidation.validationError(for: "user@@example.com", configuration: configuration), .invalidEmail)
    }

    func testMaximumLengthIsRespected() {
        let configuration = EmailFieldConfiguration(isEnabled: true, isRequired: false, maximumLength: 5)

        XCTAssertEqual(FeedbackEmailValidation.validationError(for: "abcde@f.com", configuration: configuration), .invalidEmail)
    }

    func testDisabledEmailFieldBypassesValidation() {
        let configuration = EmailFieldConfiguration(isEnabled: false, isRequired: false, maximumLength: 5)

        XCTAssertNil(FeedbackEmailValidation.validationError(for: "not-an-email", configuration: configuration))
    }
}
