import XCTest

@testable import SDLFeedbackKit

final class AttachmentPickerDiagnosticConfigurationTests: XCTestCase {
    func testDefaultsUseProductionAndUnsetRepresentationMode() {
        let configuration = AttachmentPickerDiagnosticConfiguration.current(environment: [:])

        XCTAssertEqual(configuration.representationMode, .defaultUnset)
        XCTAssertEqual(configuration.requestKind, .production)
        XCTAssertNil(configuration.requestedTypeOverride)
    }

    func testParsesAutomaticCurrentCompatibleAndRequestKinds() {
        let automatic = AttachmentPickerDiagnosticConfiguration.current(
            environment: [
                "SDLFeedbackKitAttachmentRepresentationMode": "automatic",
                "SDLFeedbackKitAttachmentRequestKind": "file",
                "SDLFeedbackKitAttachmentRequestedType": "public.heic"
            ]
        )

        XCTAssertEqual(automatic.representationMode, .automatic)
        XCTAssertEqual(automatic.requestKind, .file)
        XCTAssertEqual(automatic.requestedTypeOverride, "public.heic")

        let current = AttachmentPickerDiagnosticConfiguration.current(
            environment: [
                "SDLFeedbackKitAttachmentRepresentationMode": "current",
                "SDLFeedbackKitAttachmentRequestKind": "data"
            ]
        )

        XCTAssertEqual(current.representationMode, .current)
        XCTAssertEqual(current.requestKind, .data)
        XCTAssertNil(current.requestedTypeOverride)

        let compatible = AttachmentPickerDiagnosticConfiguration.current(
            environment: [
                "SDLFeedbackKitAttachmentRepresentationMode": "compatible",
                "SDLFeedbackKitAttachmentRequestKind": "production"
            ]
        )

        XCTAssertEqual(compatible.representationMode, .compatible)
        XCTAssertEqual(compatible.requestKind, .production)
        XCTAssertNil(compatible.requestedTypeOverride)
    }

    func testBlankRequestedTypeOverrideIsIgnored() {
        let configuration = AttachmentPickerDiagnosticConfiguration.current(
            environment: [
                "SDLFeedbackKitAttachmentRequestedType": "   "
            ]
        )

        XCTAssertNil(configuration.requestedTypeOverride)
    }
}
