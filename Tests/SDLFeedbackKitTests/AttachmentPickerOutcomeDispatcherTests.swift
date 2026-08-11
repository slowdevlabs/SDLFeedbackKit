import Foundation
import XCTest

@testable import SDLFeedbackKit

final class AttachmentPickerOutcomeDispatcherTests: XCTestCase {
    func testSelectionForwardsDataWithoutParentDismissal() async {
        let dismissExpectation = expectation(description: "dismiss")
        dismissExpectation.isInverted = true
        let dataExpectation = expectation(description: "data")

        let dispatcher = AttachmentPickerOutcomeDispatcher(
            selectionID: UUID(),
            dismissPicker: {
                dismissExpectation.fulfill()
            },
            processData: { _, _ in
                dataExpectation.fulfill()
            },
            processFile: { _, _ in
                XCTFail("Expected data path")
            },
            reportFailure: { _, _ in
                XCTFail("Expected data path")
            }
        )

        await dispatcher.dispatch(.selected(Data([0x01, 0x02])))

        await fulfillment(of: [dismissExpectation, dataExpectation], timeout: 1.0)
    }

    func testSelectedFileForwardsFileWithoutParentDismissal() async {
        let dismissExpectation = expectation(description: "dismiss")
        dismissExpectation.isInverted = true
        let fileExpectation = expectation(description: "file")

        let dispatcher = AttachmentPickerOutcomeDispatcher(
            selectionID: UUID(),
            dismissPicker: {
                dismissExpectation.fulfill()
            },
            processData: { _, _ in
                XCTFail("Expected file path")
            },
            processFile: { _, _ in
                fileExpectation.fulfill()
            },
            reportFailure: { _, _ in
                XCTFail("Expected file path")
            }
        )

        await dispatcher.dispatch(.selectedFile(URL(fileURLWithPath: "/tmp/test.jpg")))

        await fulfillment(of: [dismissExpectation, fileExpectation], timeout: 1.0)
    }

    func testCancelDismissesPickerOnly() async {
        let dismissExpectation = expectation(description: "dismiss")
        let dataExpectation = expectation(description: "data")
        let fileExpectation = expectation(description: "file")
        let failureExpectation = expectation(description: "failure")
        dataExpectation.isInverted = true
        fileExpectation.isInverted = true
        failureExpectation.isInverted = true

        let dispatcher = AttachmentPickerOutcomeDispatcher(
            selectionID: UUID(),
            dismissPicker: {
                dismissExpectation.fulfill()
            },
            processData: { _, _ in
                dataExpectation.fulfill()
            },
            processFile: { _, _ in
                fileExpectation.fulfill()
            },
            reportFailure: { _, _ in
                failureExpectation.fulfill()
            }
        )

        await dispatcher.dispatch(.cancelled)

        await fulfillment(
            of: [dismissExpectation, dataExpectation, fileExpectation, failureExpectation],
            timeout: 1.0
        )
    }

    func testFailureDoesNotTriggerParentDismissalFromDispatcher() async {
        let dismissExpectation = expectation(description: "dismiss")
        dismissExpectation.isInverted = true
        let failureExpectation = expectation(description: "failure")

        let dispatcher = AttachmentPickerOutcomeDispatcher(
            selectionID: UUID(),
            dismissPicker: {
                dismissExpectation.fulfill()
            },
            processData: { _, _ in
                XCTFail("Expected failure path")
            },
            processFile: { _, _ in
                XCTFail("Expected failure path")
            },
            reportFailure: { _, _ in
                failureExpectation.fulfill()
            }
        )

        await dispatcher.dispatch(.failed(.attachmentProcessingFailed))

        await fulfillment(of: [dismissExpectation, failureExpectation], timeout: 1.0)
    }
}
