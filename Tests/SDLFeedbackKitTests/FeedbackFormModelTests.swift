import Combine
import Foundation
import ImageIO
import XCTest

@testable import SDLFeedbackKit

@MainActor
final class FeedbackFormModelTests: XCTestCase {
    func testInitialStateUsesFirstConfiguredCategory() {
        let transport = SequenceTransport(outcomes: [])
        let model = makeModel(transport: transport)

        XCTAssertEqual(model.selectedCategory?.id, FeedbackCategory.general.id)
        XCTAssertEqual(model.message, "")
        XCTAssertEqual(model.email, "")
        XCTAssertNil(model.attachment)
        assertIdle(model.state)
    }

    func testPublishedChangesEmitObjectWillChange() {
        let transport = SequenceTransport(outcomes: [])
        let model = makeModel(transport: transport)

        var changeCount = 0
        let cancellable = model.objectWillChange.sink { _ in
            changeCount += 1
        }

        model.message = "Updated message"
        model.email = "user@example.com"
        model.selectedCategory = .bug
        model.reportAttachmentFailure(.invalidInput)

        XCTAssertGreaterThanOrEqual(changeCount, 4)
        _ = cancellable

        XCTAssertEqual(model.message, "Updated message")
        XCTAssertEqual(model.email, "user@example.com")
        XCTAssertEqual(model.selectedCategory?.id, FeedbackCategory.bug.id)
        assertFailure(model.state, .invalidInput)
    }

    func testEmptyCategoriesAreSafe() async {
        let configuration = FeedbackConfiguration(categories: [])
        let transport = SequenceTransport(outcomes: [])
        let model = makeModel(configuration: configuration, transport: transport)

        XCTAssertNil(model.selectedCategory)

        await model.submit()

        assertFailure(model.state, .invalidInput)
        let callCount = await transport.callCount()
        XCTAssertEqual(callCount, 0)
    }

    func testValidSubmissionBuildsPayloadAndSucceeds() async {
        let receipt = FeedbackSubmissionReceipt(serverID: "server-123")
        let transport = SequenceTransport(outcomes: [.success(receipt)])
        let model = makeModel(
            transport: transport,
            uuidProvider: { UUID(uuidString: "11111111-1111-1111-1111-111111111111")! },
            dateProvider: { Date(timeIntervalSince1970: 1_000) }
        )

        model.message = "Need help with the app"
        model.email = "user@example.com"

        await model.submit()

        let callCount = await transport.callCount()
        XCTAssertEqual(callCount, 1)
        let payloads = await transport.payloads()
        XCTAssertEqual(payloads.count, 1)

        guard let payload = payloads.first else {
            return XCTFail("Missing payload")
        }

        XCTAssertEqual(payload.clientID.uuidString, "11111111-1111-1111-1111-111111111111")
        XCTAssertEqual(payload.appID, "my-app")
        XCTAssertEqual(payload.appName, "My App")
        XCTAssertEqual(payload.category.id, FeedbackCategory.general.id)
        XCTAssertEqual(payload.message, "Need help with the app")
        XCTAssertEqual(payload.email, "user@example.com")
        XCTAssertEqual(payload.metadata, ["channel": "stable"])
        XCTAssertEqual(payload.createdAt, Date(timeIntervalSince1970: 1_000))
        assertSuccess(model.state)
        if case let .success(result) = model.state {
            XCTAssertEqual(result.clientID, payload.clientID)
            XCTAssertEqual(result.receipt.serverID, "server-123")
        }
    }

    func testValidationFailurePreventsTransportCall() async {
        let transport = SequenceTransport(outcomes: [.success(FeedbackSubmissionReceipt())])
        let model = makeModel(transport: transport)
        model.message = ""

        await model.submit()

        assertFailure(model.state, .invalidInput)
        let callCount = await transport.callCount()
        XCTAssertEqual(callCount, 0)
    }

    func testTransportFailureMapsToSubmissionFailed() async {
        enum MockError: Error {
            case failed
        }

        let transport = SequenceTransport(outcomes: [.failure(MockError.failed)])
        let model = makeModel(transport: transport)
        model.message = "This should fail"
        model.email = "user@example.com"

        await model.submit()

        assertFailure(model.state, .submissionFailed)
        let callCount = await transport.callCount()
        XCTAssertEqual(callCount, 1)
        let payload = try? await transport.payload(at: 0)
        XCTAssertEqual(payload?.message, "This should fail")
        XCTAssertEqual(payload?.email, "user@example.com")
    }

    func testDuplicateSubmitIsBlockedWhileSubmitting() async {
        let transport = BlockingTransport()
        let model = makeModel(transport: transport)
        model.message = "Please wait"

        let firstSubmit = Task { await model.submit() }

        await waitUntil {
            if case .submitting = model.state {
                return true
            }
            return false
        }

        let firstCallCount = await transport.callCount()
        XCTAssertEqual(firstCallCount, 1)

        await model.submit()

        let secondCallCount = await transport.callCount()
        XCTAssertEqual(secondCallCount, 1)

        await transport.resume(with: FeedbackSubmissionReceipt(serverID: "done"))
        await firstSubmit.value

        assertSuccess(model.state)
    }

    func testAttachmentProcessingSuccessAndReplacementFailurePreservesExistingAttachment() async {
        let firstAttachment = makeAttachment(
            data: Data([0x01, 0x02, 0x03]),
            filename: "feedback.jpg",
            mimeType: "image/jpeg",
            pixelWidth: 10,
            pixelHeight: 20
        )
        let transport = SequenceTransport(outcomes: [])
        let optimizer = SequenceImageOptimizer(outcomes: [.success(firstAttachment), .failure(FeedbackError.attachmentProcessingFailed)])
        let model = makeModel(transport: transport, imageOptimizer: optimizer)

        await model.processAttachment(data: Data([0x10, 0x20]))
        assertIdle(model.state)
        XCTAssertNotNil(model.attachment)
        XCTAssertEqual(model.attachment?.byteCount, 3)
        XCTAssertEqual(model.attachment?.pixelWidth, 10)
        XCTAssertEqual(model.attachment?.pixelHeight, 20)

        await model.processAttachment(data: Data([0x30, 0x40]))
        assertFailure(model.state, .attachmentProcessingFailed)
        XCTAssertEqual(model.attachment?.byteCount, 3)
        XCTAssertEqual(model.attachment?.pixelWidth, 10)
        XCTAssertEqual(model.attachment?.pixelHeight, 20)
    }

    func testRemoveAttachmentClearsAttachmentAndIdentity() async {
        let receipt = FeedbackSubmissionReceipt(serverID: "ok")
        let transport = SequenceTransport(outcomes: [.success(receipt)])
        let model = makeModel(transport: transport)
        model.message = "With attachment"

        let attachment = makeAttachment(
            data: Data([0xAA, 0xBB, 0xCC]),
            filename: "feedback.jpg",
            mimeType: "image/jpeg",
            pixelWidth: 12,
            pixelHeight: 12
        )
        let optimizer = SequenceImageOptimizer(outcomes: [.success(attachment)])
        let attachmentModel = makeModel(transport: transport, imageOptimizer: optimizer)
        attachmentModel.message = "With attachment"

        await attachmentModel.processAttachment(data: Data([0x99]))
        XCTAssertNotNil(attachmentModel.attachment)

        attachmentModel.removeAttachment()

        XCTAssertNil(attachmentModel.attachment)
        assertIdle(attachmentModel.state)
    }

    func testSubmitIsBlockedWhileAttachmentIsProcessing() async {
        let optimizer = BlockingImageOptimizer()
        let transport = SequenceTransport(outcomes: [.success(FeedbackSubmissionReceipt())])
        let model = makeModel(transport: transport, imageOptimizer: optimizer)
        model.message = "Wait for attachment"

        let attachmentTask = Task { await model.processAttachment(data: Data([0x01, 0x02])) }

        await waitUntil {
            if case .processingAttachment = model.state {
                return true
            }
            return false
        }

        await model.submit()

        let callCount = await transport.callCount()
        XCTAssertEqual(callCount, 0)

        let attachment = makeAttachment(
            data: Data([0x01, 0x02, 0x03, 0x04]),
            filename: "feedback.jpg",
            mimeType: "image/jpeg",
            pixelWidth: 4,
            pixelHeight: 1
        )
        await optimizer.resume(with: attachment)
        await attachmentTask.value

        assertIdle(model.state)
        XCTAssertEqual(model.attachment?.byteCount, 4)
    }

    func testSuccessBlocksDuplicateSubmitUntilEditOrReset() async {
        let receipt = FeedbackSubmissionReceipt(serverID: "ok")
        let transport = SequenceTransport(outcomes: [.success(receipt)])
        let model = makeModel(transport: transport)
        model.message = "First submit"

        await model.submit()
        assertSuccess(model.state)

        await model.submit()

        let callCount = await transport.callCount()
        XCTAssertEqual(callCount, 1)
    }

    func testRetryAfterTransportFailureReusesClientIDAndCreatedAt() async {
        let receipt = FeedbackSubmissionReceipt(serverID: "ok")
        let transport = SequenceTransport(outcomes: [
            .failure(MockTransportError.failed),
            .success(receipt)
        ])
        var uuidValues = [
            UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
        ]
        var dateValues = [
            Date(timeIntervalSince1970: 2_000),
            Date(timeIntervalSince1970: 3_000)
        ]
        let model = makeModel(
            transport: transport,
            uuidProvider: { uuidValues.removeFirst() },
            dateProvider: { dateValues.removeFirst() }
        )
        model.message = "Retry me"

        await model.submit()
        assertFailure(model.state, .submissionFailed)

        await model.submit()
        assertSuccess(model.state)

        let payloads = await transport.payloads()
        XCTAssertEqual(payloads.count, 2)
        XCTAssertEqual(payloads[0].clientID, payloads[1].clientID)
        XCTAssertEqual(payloads[0].createdAt, payloads[1].createdAt)
        XCTAssertEqual(uuidValues.count, 1)
        XCTAssertEqual(dateValues.count, 1)
    }

    func testEditingAfterFailureCreatesNewIdentity() async {
        let receipt = FeedbackSubmissionReceipt(serverID: "ok")
        let transport = SequenceTransport(outcomes: [
            .failure(MockTransportError.failed),
            .success(receipt)
        ])
        var uuidValues = [
            UUID(uuidString: "44444444-4444-4444-4444-444444444444")!,
            UUID(uuidString: "55555555-5555-5555-5555-555555555555")!
        ]
        var dateValues = [
            Date(timeIntervalSince1970: 4_000),
            Date(timeIntervalSince1970: 5_000)
        ]
        let model = makeModel(
            transport: transport,
            uuidProvider: { uuidValues.removeFirst() },
            dateProvider: { dateValues.removeFirst() }
        )
        model.message = "Original"

        await model.submit()
        assertFailure(model.state, .submissionFailed)

        model.message = "Edited"
        assertIdle(model.state)

        await model.submit()

        let payloads = await transport.payloads()
        XCTAssertEqual(payloads.count, 2)
        XCTAssertNotEqual(payloads[0].clientID, payloads[1].clientID)
        XCTAssertNotEqual(payloads[0].createdAt, payloads[1].createdAt)
    }

    func testResetClearsFormValuesAndIdentity() async {
        let receipt = FeedbackSubmissionReceipt(serverID: "ok")
        let transport = SequenceTransport(outcomes: [
            .failure(MockTransportError.failed),
            .success(receipt)
        ])
        var uuidValues = [
            UUID(uuidString: "66666666-6666-6666-6666-666666666666")!,
            UUID(uuidString: "77777777-7777-7777-7777-777777777777")!
        ]
        var dateValues = [
            Date(timeIntervalSince1970: 6_000),
            Date(timeIntervalSince1970: 7_000)
        ]
        let model = makeModel(
            transport: transport,
            uuidProvider: { uuidValues.removeFirst() },
            dateProvider: { dateValues.removeFirst() }
        )
        model.message = "Before reset"

        await model.submit()
        assertFailure(model.state, .submissionFailed)

        model.reset()

        XCTAssertEqual(model.selectedCategory?.id, FeedbackCategory.general.id)
        XCTAssertEqual(model.message, "")
        XCTAssertEqual(model.email, "")
        XCTAssertNil(model.attachment)
        assertIdle(model.state)

        model.message = "After reset"

        await model.submit()

        let payloads = await transport.payloads()
        XCTAssertEqual(payloads.count, 2)
        XCTAssertNotEqual(payloads[0].clientID, payloads[1].clientID)
    }

    func testDisabledEmailIsOmitted() async {
        var configuration = FeedbackConfiguration.default
        configuration.emailField.isEnabled = false
        let transport = SequenceTransport(outcomes: [.success(FeedbackSubmissionReceipt())])
        let model = makeModel(configuration: configuration, transport: transport)
        model.message = "Email disabled"
        model.email = "should-not-leak@example.com"

        await model.submit()

        let payload = try? await transport.payload(at: 0)
        XCTAssertNil(payload?.email)
    }

    func testDisabledAttachmentIsOmitted() async {
        var configuration = FeedbackConfiguration.default
        configuration.attachment.isEnabled = false
        let transport = SequenceTransport(outcomes: [.success(FeedbackSubmissionReceipt())])
        let optimizer = SequenceImageOptimizer(outcomes: [
            .success(makeAttachment(
                data: Data([0xDE, 0xAD]),
                filename: "feedback.jpg",
                mimeType: "image/jpeg",
                pixelWidth: 1,
                pixelHeight: 2
            ))
        ])
        let model = makeModel(
            configuration: configuration,
            transport: transport,
            imageOptimizer: optimizer
        )
        model.message = "Attachment disabled"

        await model.processAttachment(data: Data([0xAA]))
        XCTAssertNotNil(model.attachment)

        await model.submit()

        let payload = try? await transport.payload(at: 0)
        XCTAssertNil(payload?.attachment)
    }

    func testSubmissionDeliversUserInputMetadataAndOptimizedAttachmentToTransport() async throws {
        let receipt = FeedbackSubmissionReceipt(
            serverID: "server-123",
            acceptedAt: Date(timeIntervalSince1970: 4_200)
        )
        let transport = SequenceTransport(outcomes: [.success(receipt)])
        let payloadBuilder = FeedbackPayloadBuilder(
            platformInfoProvider: StubPlatformInfoProvider(
                info: PlatformInfo(
                    appVersion: "2.3.4",
                    buildNumber: "987",
                    platform: .macOS,
                    osVersion: "15.7.2",
                    localeIdentifier: "es_ES"
                )
            )
        )
        let model = makeModel(
            context: FeedbackContext(
                appID: "com.example.feedback-integration",
                appName: "Feedback Integration Test",
                metadata: [
                    "screen": "settings",
                    "source": "integration-test"
                ]
            ),
            transport: transport,
            payloadBuilder: payloadBuilder,
            imageOptimizer: DefaultImageOptimizer(),
            uuidProvider: { UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")! },
            dateProvider: { Date(timeIntervalSince1970: 1_700) }
        )

        model.selectedCategory = .bug
        model.message = "Example feedback message.\nSecond line."
        model.email = "tester@example.com"

        let sourceImage = try ImageTestFactory.noisyJPEGData(
            width: 2400,
            height: 2400,
            quality: 0.98,
            includeMetadata: true
        )

        await model.processAttachment(data: sourceImage)
        assertIdle(model.state)

        guard let attachment = model.attachment else {
            return XCTFail("Expected optimized attachment")
        }

        XCTAssertEqual(attachment.filename, "feedback.jpg")
        XCTAssertEqual(attachment.mimeType, "image/jpeg")
        XCTAssertEqual(attachment.byteCount, attachment.data.count)
        XCTAssertLessThanOrEqual(attachment.byteCount, 1_000_000)
        XCTAssertGreaterThan(attachment.byteCount, 0)
        XCTAssertGreaterThan(attachment.pixelWidth ?? 0, 0)
        XCTAssertGreaterThan(attachment.pixelHeight ?? 0, 0)
        XCTAssertNotNil(CGImageSourceCreateWithData(attachment.data as CFData, nil))

        await model.submit()

        let callCount = await transport.callCount()
        XCTAssertEqual(callCount, 1)

        let payloads = await transport.payloads()
        XCTAssertEqual(payloads.count, 1)

        guard let payload = payloads.first else {
            return XCTFail("Missing submitted payload")
        }

        XCTAssertEqual(payload.appID, "com.example.feedback-integration")
        XCTAssertEqual(payload.appName, "Feedback Integration Test")
        XCTAssertEqual(payload.appVersion, "2.3.4")
        XCTAssertEqual(payload.buildNumber, "987")
        XCTAssertEqual(payload.platform, .macOS)
        XCTAssertEqual(payload.osVersion, "15.7.2")
        XCTAssertEqual(payload.localeIdentifier, "es_ES")
        XCTAssertEqual(payload.category.id, FeedbackCategory.bug.id)
        XCTAssertEqual(payload.message, "Example feedback message.\nSecond line.")
        XCTAssertEqual(payload.email, "tester@example.com")
        XCTAssertEqual(payload.metadata["screen"], "settings")
        XCTAssertEqual(payload.metadata["source"], "integration-test")
        XCTAssertEqual(payload.clientID, UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!)
        XCTAssertEqual(payload.createdAt, Date(timeIntervalSince1970: 1_700))

        guard let payloadAttachment = payload.attachment else {
            return XCTFail("Expected payload attachment")
        }

        XCTAssertEqual(payloadAttachment.filename, "feedback.jpg")
        XCTAssertEqual(payloadAttachment.mimeType, "image/jpeg")
        XCTAssertEqual(payloadAttachment.byteCount, payloadAttachment.data.count)
        XCTAssertLessThanOrEqual(payloadAttachment.byteCount, 1_000_000)
        XCTAssertGreaterThan(payloadAttachment.pixelWidth ?? 0, 0)
        XCTAssertGreaterThan(payloadAttachment.pixelHeight ?? 0, 0)
        XCTAssertNotNil(CGImageSourceCreateWithData(payloadAttachment.data as CFData, nil))

        assertSuccess(model.state)
        if case let .success(result) = model.state {
            XCTAssertEqual(result.clientID, payload.clientID)
            XCTAssertEqual(result.receipt.serverID, "server-123")
            XCTAssertEqual(result.receipt.acceptedAt, Date(timeIntervalSince1970: 4_200))
        }
    }

    private func makeModel(
        context: FeedbackContext = FeedbackContext(
            appID: "my-app",
            appName: "My App",
            metadata: ["channel": "stable"]
        ),
        configuration: FeedbackConfiguration = .default,
        transport: any FeedbackTransport,
        payloadBuilder: FeedbackPayloadBuilder? = nil,
        imageOptimizer: any ImageOptimizer = SequenceImageOptimizer(outcomes: []),
        uuidProvider: @escaping () -> UUID = { UUID(uuidString: "99999999-9999-9999-9999-999999999999")! },
        dateProvider: @escaping () -> Date = { Date(timeIntervalSince1970: 9_999) }
    ) -> FeedbackFormModel {
        let builder = payloadBuilder ?? FeedbackPayloadBuilder(
            platformInfoProvider: StubPlatformInfoProvider(
                info: PlatformInfo(
                    appVersion: "1.2.3",
                    buildNumber: "42",
                    platform: .iOS,
                    osVersion: "test-os",
                    localeIdentifier: "ko_KR"
                )
            )
        )
        return FeedbackFormModel(
            context: context,
            configuration: configuration,
            transport: transport,
            payloadBuilder: builder,
            imageOptimizer: imageOptimizer,
            uuidProvider: uuidProvider,
            dateProvider: dateProvider
        )
    }

    private func assertIdle(_ state: FeedbackFormState, file: StaticString = #filePath, line: UInt = #line) {
        if case .idle = state {
            return
        }
        XCTFail("Expected idle state", file: file, line: line)
    }

    private func assertSuccess(_ state: FeedbackFormState, file: StaticString = #filePath, line: UInt = #line) {
        if case .success = state {
            return
        }
        XCTFail("Expected success state", file: file, line: line)
    }

    private func assertFailure(
        _ state: FeedbackFormState,
        _ expectedError: FeedbackError,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        if case let .failure(error) = state, error == expectedError {
            return
        }
        XCTFail("Expected failure state \(expectedError)", file: file, line: line)
    }

    private func waitUntil(
        _ condition: @escaping () -> Bool,
        iterations: Int = 1_000
    ) async {
        for _ in 0..<iterations {
            if condition() {
                return
            }
            await Task.yield()
        }
        XCTFail("Timed out waiting for condition")
    }
}

private struct StubPlatformInfoProvider: PlatformInfoProvider {
    let info: PlatformInfo

    func currentInfo() -> PlatformInfo {
        info
    }
}

private actor SequenceImageOptimizer: ImageOptimizer {
    enum Outcome {
        case success(FeedbackAttachment)
        case failure(FeedbackError)
    }

    private var outcomes: [Outcome]

    init(outcomes: [Outcome]) {
        self.outcomes = outcomes
    }

    func optimize(
        data: Data,
        configuration: AttachmentConfiguration
    ) async throws -> FeedbackAttachment {
        guard !outcomes.isEmpty else {
            return makeAttachment(
                data: Data([0x01]),
                filename: "feedback.jpg",
                mimeType: "image/jpeg",
                pixelWidth: 1,
                pixelHeight: 1
            )
        }

        let outcome = outcomes.removeFirst()
        switch outcome {
        case let .success(attachment):
            return attachment
        case let .failure(error):
            throw error
        }
    }
}

private actor BlockingImageOptimizer: ImageOptimizer {
    private var continuation: CheckedContinuation<FeedbackAttachment, Error>?
    private(set) var callCount = 0

    func optimize(
        data: Data,
        configuration: AttachmentConfiguration
    ) async throws -> FeedbackAttachment {
        callCount += 1
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
        }
    }

    func resume(with attachment: FeedbackAttachment) {
        continuation?.resume(returning: attachment)
        continuation = nil
    }
}

private actor SequenceTransport: FeedbackTransport {
    enum Outcome {
        case success(FeedbackSubmissionReceipt)
        case failure(Error)
    }

    private var outcomes: [Outcome]
    private var capturedPayloads: [FeedbackPayload] = []
    private var submitCallCount = 0

    init(outcomes: [Outcome]) {
        self.outcomes = outcomes
    }

    func submit(_ payload: FeedbackPayload) async throws -> FeedbackSubmissionReceipt {
        submitCallCount += 1
        capturedPayloads.append(payload)

        guard !outcomes.isEmpty else {
            return FeedbackSubmissionReceipt()
        }

        let outcome = outcomes.removeFirst()
        switch outcome {
        case let .success(receipt):
            return receipt
        case let .failure(error):
            throw error
        }
    }

    func callCount() -> Int {
        submitCallCount
    }

    func payloads() -> [FeedbackPayload] {
        capturedPayloads
    }

    func payload(at index: Int) throws -> FeedbackPayload {
        guard capturedPayloads.indices.contains(index) else {
            throw MockTransportError.failed
        }
        return capturedPayloads[index]
    }
}

private actor BlockingTransport: FeedbackTransport {
    private var continuation: CheckedContinuation<FeedbackSubmissionReceipt, Error>?
    private var capturedPayloads: [FeedbackPayload] = []
    private(set) var submitCallCount = 0

    func submit(_ payload: FeedbackPayload) async throws -> FeedbackSubmissionReceipt {
        submitCallCount += 1
        capturedPayloads.append(payload)
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
        }
    }

    func resume(with receipt: FeedbackSubmissionReceipt) {
        continuation?.resume(returning: receipt)
        continuation = nil
    }

    func callCount() -> Int {
        submitCallCount
    }
}

private enum MockTransportError: Error {
    case failed
}

private func makeAttachment(
    data: Data,
    filename: String,
    mimeType: String,
    pixelWidth: Int?,
    pixelHeight: Int?
) -> FeedbackAttachment {
    FeedbackAttachment(
        data: data,
        filename: filename,
        mimeType: mimeType,
        pixelWidth: pixelWidth,
        pixelHeight: pixelHeight
    )
}
