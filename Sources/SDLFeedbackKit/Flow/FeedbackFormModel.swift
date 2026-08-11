import Combine
import Foundation

@MainActor
final class FeedbackFormModel: ObservableObject {
    @Published var selectedCategory: FeedbackCategory? {
        didSet {
            guard oldValue != selectedCategory else { return }
            handleDraftMutation()
        }
    }

    @Published var message: String {
        didSet {
            guard oldValue != message else { return }
            handleDraftMutation()
        }
    }

    @Published var email: String {
        didSet {
            guard oldValue != email else { return }
            updateEmailValidationState()
            handleDraftMutation()
        }
    }

    @Published private(set) var emailValidationError: FeedbackError?

    @Published private(set) var attachment: FeedbackAttachment?
    @Published private(set) var state: FeedbackFormState

    private let context: FeedbackContext
    private let configuration: FeedbackConfiguration
    private let transport: any FeedbackTransport
    private let payloadBuilder: FeedbackPayloadBuilder
    private let imageOptimizer: any ImageOptimizer
    private let uuidProvider: () -> UUID
    private let dateProvider: () -> Date
    private let attachmentProviderTimeoutNanoseconds: UInt64

    private var pendingSubmission: PendingSubmissionIdentity?
    private var currentAttachmentSelectionID: UUID?
    private var pendingAttachmentTimeoutTask: Task<Void, Never>?
    private var isAttachmentOptimizationInFlight = false

    init(
        context: FeedbackContext,
        configuration: FeedbackConfiguration,
        transport: any FeedbackTransport,
        payloadBuilder: FeedbackPayloadBuilder = FeedbackPayloadBuilder(),
        imageOptimizer: any ImageOptimizer = DefaultImageOptimizer(),
        uuidProvider: @escaping () -> UUID = UUID.init,
        dateProvider: @escaping () -> Date = Date.init,
        attachmentProviderTimeoutNanoseconds: UInt64 = 5_000_000_000
    ) {
        self.context = context
        self.configuration = configuration
        self.transport = transport
        self.payloadBuilder = payloadBuilder
        self.imageOptimizer = imageOptimizer
        self.uuidProvider = uuidProvider
        self.dateProvider = dateProvider
        self.attachmentProviderTimeoutNanoseconds = attachmentProviderTimeoutNanoseconds
        self.selectedCategory = configuration.categories.first
        self.message = ""
        self.email = ""
        self.emailValidationError = nil
        self.attachment = nil
        self.state = .idle
    }

    deinit {
        pendingAttachmentTimeoutTask?.cancel()
    }

    var isSubmitting: Bool {
        if case .submitting = state {
            return true
        }
        return false
    }

    var isProcessingAttachment: Bool {
        if case .processingAttachment = state {
            return true
        }
        return false
    }

    var canSubmit: Bool {
        !isSubmitting && !isProcessingAttachment && emailValidationError == nil
    }

    func beginAttachmentSelection() -> UUID {
        cancelPendingAttachmentTimeout()
        let selectionID = UUID()
        currentAttachmentSelectionID = selectionID
        AttachmentPickerDebugLog.log("attachment.selection.begin id=\(selectionID.uuidString)")
        return selectionID
    }

    func beginAttachmentAcquisition(selectionID: UUID) {
        guard isCurrentAttachmentSelection(selectionID) else {
            AttachmentPickerDebugLog.log("provider.request.timeoutScheduled.dropped.stale id=\(selectionID.uuidString) current=\(currentAttachmentSelectionID?.uuidString ?? "nil")")
            return
        }

        cancelPendingAttachmentTimeout()
        state = .processingAttachment
        AttachmentPickerDebugLog.log("provider.request.timeoutScheduled id=\(selectionID.uuidString)")
        pendingAttachmentTimeoutTask = Task { [attachmentProviderTimeoutNanoseconds, weak self] in
            do {
                try await Task.sleep(nanoseconds: attachmentProviderTimeoutNanoseconds)
            } catch {
                return
            }
            if let self {
                self.handleAttachmentTimeoutIfCurrent(selectionID: selectionID)
            }
        }
    }

    func markAttachmentProviderResponse(selectionID: UUID) {
        guard isCurrentAttachmentSelection(selectionID) else {
            AttachmentPickerDebugLog.log("provider.callback.drop.stale id=\(selectionID.uuidString) current=\(currentAttachmentSelectionID?.uuidString ?? "nil")")
            return
        }

        cancelPendingAttachmentTimeout()
    }

    func submit() async {
        guard !isProcessingAttachment else { return }
        guard !isSubmitting else { return }
        if case .success = state {
            return
        }

        if let validationError = FeedbackEmailValidation.validationError(
            for: email,
            configuration: configuration.emailField
        ) {
            emailValidationError = validationError
            return
        }

        guard let selectedCategory else {
            state = .failure(.invalidInput)
            return
        }

        let draft = FeedbackDraft(
            category: selectedCategory,
            message: message,
            email: email,
            attachment: attachment
        )

        let submissionIdentity: PendingSubmissionIdentity
        if pendingSubmission?.matches(
            category: selectedCategory,
            message: message,
            email: email,
            attachment: attachment
        ) == true, let pendingSubmission {
            submissionIdentity = pendingSubmission
        } else {
            submissionIdentity = makePendingSubmissionIdentity()
        }

        let clientID = submissionIdentity.clientID
        let createdAt = submissionIdentity.createdAt

        let payload: FeedbackPayload
        do {
            payload = try payloadBuilder.build(
                context: context,
                draft: draft,
                configuration: configuration,
                clientID: clientID,
                createdAt: createdAt
            )
        } catch let error as FeedbackError {
            state = .failure(error)
            return
        } catch is CancellationError {
            return
        } catch {
            state = .failure(.invalidInput)
            return
        }

        pendingSubmission = submissionIdentity
        state = .submitting

        do {
            let receipt = try await transport.submit(payload)
            let result = FeedbackSubmissionResult(
                clientID: payload.clientID,
                receipt: receipt
            )
            state = .success(result)
        } catch {
            if error is CancellationError {
                state = .idle
            } else {
                state = .failure(.submissionFailed)
            }
        }
    }

    func processAttachment(data: Data) async {
        await processAttachment(data: data, selectionID: nil)
    }

    func processAttachment(data: Data, selectionID: UUID) async {
        await processAttachment(data: data, selectionID: Optional(selectionID))
    }

    func processAttachment(fileURL: URL) async {
        await processAttachment(fileURL: fileURL, selectionID: nil)
    }

    func processAttachment(fileURL: URL, selectionID: UUID) async {
        await processAttachment(fileURL: fileURL, selectionID: Optional(selectionID))
    }

    func reportAttachmentFailure(_ error: FeedbackError) {
        reportAttachmentFailure(error, selectionID: nil)
    }

    func reportAttachmentFailure(_ error: FeedbackError, selectionID: UUID) {
        reportAttachmentFailure(error, selectionID: Optional(selectionID))
    }

    func removeAttachment() {
        guard attachment != nil else { return }
        guard !isProcessingAttachment, !isSubmitting else {
            return
        }
        cancelPendingAttachmentTimeout()
        attachment = nil
        pendingSubmission = nil
        currentAttachmentSelectionID = nil
        state = .idle
    }

    func reset() {
        guard !isSubmitting, !isProcessingAttachment else {
            return
        }
        cancelPendingAttachmentTimeout()
        selectedCategory = configuration.categories.first
        message = ""
        email = ""
        emailValidationError = nil
        attachment = nil
        pendingSubmission = nil
        currentAttachmentSelectionID = nil
        state = .idle
    }

    private func processAttachment(data: Data, selectionID: UUID?) async {
        guard !isAttachmentOptimizationInFlight, !isSubmitting else {
            AttachmentPickerDebugLog.log("attachment.processing.data.dropped.busy id=\(selectionID?.uuidString ?? "nil")")
            return
        }
        guard isCurrentAttachmentSelection(selectionID) else {
            AttachmentPickerDebugLog.log("attachment.processing.data.dropped.stale id=\(selectionID?.uuidString ?? "nil") current=\(currentAttachmentSelectionID?.uuidString ?? "nil")")
            return
        }

        AttachmentPickerDebugLog.log("attachment.processing.data.started id=\(selectionID?.uuidString ?? "nil") bytes=\(data.count)")
        isAttachmentOptimizationInFlight = true
        state = .processingAttachment
        cancelPendingAttachmentTimeout(selectionID: selectionID)
        defer {
            isAttachmentOptimizationInFlight = false
        }

        do {
            let optimizedAttachment = try await imageOptimizer.optimize(
                data: data,
                configuration: configuration.attachment
            )
            guard isCurrentAttachmentSelection(selectionID) else {
                AttachmentPickerDebugLog.log("attachment.processing.data.dropped.afterOptimize id=\(selectionID?.uuidString ?? "nil") current=\(currentAttachmentSelectionID?.uuidString ?? "nil")")
                return
            }
            AttachmentPickerDebugLog.log("attachment.assign.willSet id=\(selectionID?.uuidString ?? "nil") filename=\(optimizedAttachment.filename) bytes=\(optimizedAttachment.byteCount)")
            attachment = optimizedAttachment
            AttachmentPickerDebugLog.log("attachment.assign.didSet id=\(selectionID?.uuidString ?? "nil") filename=\(attachment?.filename ?? "nil") bytes=\(attachment?.byteCount ?? 0)")
            pendingSubmission = nil
            currentAttachmentSelectionID = nil
            state = .idle
            AttachmentPickerDebugLog.log("attachment.processing.data.completed id=\(selectionID?.uuidString ?? "nil")")
        } catch is CancellationError {
            if isCurrentAttachmentSelection(selectionID) {
                state = .idle
            }
        } catch let error as FeedbackError {
            if isCurrentAttachmentSelection(selectionID) {
                currentAttachmentSelectionID = nil
                state = .failure(error)
                AttachmentPickerDebugLog.log("attachment.processing.failed")
            }
        } catch {
            if isCurrentAttachmentSelection(selectionID) {
                currentAttachmentSelectionID = nil
                state = .failure(.attachmentProcessingFailed)
                AttachmentPickerDebugLog.log("attachment.processing.failed")
            }
        }
    }

    private func processAttachment(fileURL: URL, selectionID: UUID?) async {
        defer {
            isAttachmentOptimizationInFlight = false
            try? FileManager.default.removeItem(at: fileURL)
        }

        guard !isAttachmentOptimizationInFlight, !isSubmitting else {
            AttachmentPickerDebugLog.log("attachment.processing.file.dropped.busy id=\(selectionID?.uuidString ?? "nil")")
            return
        }
        guard isCurrentAttachmentSelection(selectionID) else {
            AttachmentPickerDebugLog.log("attachment.processing.file.dropped.stale id=\(selectionID?.uuidString ?? "nil") current=\(currentAttachmentSelectionID?.uuidString ?? "nil")")
            return
        }

        AttachmentPickerDebugLog.log("attachment.processing.file.started id=\(selectionID?.uuidString ?? "nil") file=\(fileURL.lastPathComponent)")
        isAttachmentOptimizationInFlight = true
        state = .processingAttachment
        cancelPendingAttachmentTimeout(selectionID: selectionID)

        do {
            let optimizedAttachment = try await imageOptimizer.optimize(
                fileURL: fileURL,
                configuration: configuration.attachment
            )
            guard isCurrentAttachmentSelection(selectionID) else {
                AttachmentPickerDebugLog.log("attachment.processing.file.dropped.afterOptimize id=\(selectionID?.uuidString ?? "nil") current=\(currentAttachmentSelectionID?.uuidString ?? "nil")")
                return
            }
            AttachmentPickerDebugLog.log("attachment.assign.willSet id=\(selectionID?.uuidString ?? "nil") filename=\(optimizedAttachment.filename) bytes=\(optimizedAttachment.byteCount)")
            attachment = optimizedAttachment
            AttachmentPickerDebugLog.log("attachment.assign.didSet id=\(selectionID?.uuidString ?? "nil") filename=\(attachment?.filename ?? "nil") bytes=\(attachment?.byteCount ?? 0)")
            pendingSubmission = nil
            currentAttachmentSelectionID = nil
            state = .idle
            AttachmentPickerDebugLog.log("attachment.processing.file.completed id=\(selectionID?.uuidString ?? "nil")")
        } catch is CancellationError {
            if isCurrentAttachmentSelection(selectionID) {
                state = .idle
            }
        } catch let error as FeedbackError {
            if isCurrentAttachmentSelection(selectionID) {
                currentAttachmentSelectionID = nil
                state = .failure(error)
                AttachmentPickerDebugLog.log("attachment.processing.failed")
            }
        } catch {
            if isCurrentAttachmentSelection(selectionID) {
                currentAttachmentSelectionID = nil
                state = .failure(.attachmentProcessingFailed)
                AttachmentPickerDebugLog.log("attachment.processing.failed")
            }
        }
    }

    private func reportAttachmentFailure(_ error: FeedbackError, selectionID: UUID?) {
        guard !isSubmitting else {
            return
        }
        guard isCurrentAttachmentSelection(selectionID) else {
            AttachmentPickerDebugLog.log("provider.callback.drop.stale id=\(selectionID?.uuidString ?? "nil") current=\(currentAttachmentSelectionID?.uuidString ?? "nil")")
            return
        }
        cancelPendingAttachmentTimeout(selectionID: selectionID)
        currentAttachmentSelectionID = nil
        state = .failure(error)
        AttachmentPickerDebugLog.log("attachment.processing.failed")
    }

    private func handleAttachmentTimeoutIfCurrent(selectionID: UUID) {
        guard isCurrentAttachmentSelection(selectionID) else {
            AttachmentPickerDebugLog.log("provider.request.timedOut.dropped.stale id=\(selectionID.uuidString) current=\(currentAttachmentSelectionID?.uuidString ?? "nil")")
            return
        }

        AttachmentPickerDebugLog.log("provider.request.timedOut id=\(selectionID.uuidString)")
        pendingAttachmentTimeoutTask = nil
        currentAttachmentSelectionID = nil
        state = .failure(.attachmentProcessingFailed)
        AttachmentPickerDebugLog.log("attachment.processing.failed")
    }

    private func cancelPendingAttachmentTimeout(selectionID: UUID? = nil) {
        guard let pendingAttachmentTimeoutTask else {
            return
        }
        pendingAttachmentTimeoutTask.cancel()
        self.pendingAttachmentTimeoutTask = nil
        AttachmentPickerDebugLog.log("provider.request.timeoutCancelled id=\(selectionID?.uuidString ?? "nil")")
    }

    private func handleDraftMutation() {
        pendingSubmission = nil
        if case .success = state {
            state = .idle
        } else if case .failure = state {
            state = .idle
        }
    }

    private func updateEmailValidationState() {
        emailValidationError = FeedbackEmailValidation.validationError(
            for: email,
            configuration: configuration.emailField
        )
    }

    private func makePendingSubmissionIdentity() -> PendingSubmissionIdentity {
        PendingSubmissionIdentity(
            clientID: uuidProvider(),
            createdAt: dateProvider(),
            draft: FeedbackDraft(
                category: selectedCategory ?? .general,
                message: message,
                email: email,
                attachment: attachment
            )
        )
    }

    private func isCurrentAttachmentSelection(_ selectionID: UUID?) -> Bool {
        guard let selectionID else {
            return true
        }
        return currentAttachmentSelectionID == selectionID
    }
}

private struct PendingSubmissionIdentity {
    let clientID: UUID
    let createdAt: Date
    let draft: FeedbackDraftSnapshot

    init(
        clientID: UUID,
        createdAt: Date,
        draft: FeedbackDraft
    ) {
        self.clientID = clientID
        self.createdAt = createdAt
        self.draft = FeedbackDraftSnapshot(draft)
    }

    func matches(
        category: FeedbackCategory,
        message: String,
        email: String,
        attachment: FeedbackAttachment?
    ) -> Bool {
        draft == FeedbackDraftSnapshot(
            category: category,
            message: message,
            email: email,
            attachment: attachment
        )
    }
}

private struct FeedbackDraftSnapshot: Equatable {
    let category: FeedbackCategory
    let message: String
    let email: String
    let attachment: AttachmentSnapshot?

    init(
        category: FeedbackCategory,
        message: String,
        email: String,
        attachment: FeedbackAttachment?
    ) {
        self.category = category
        self.message = message
        self.email = email
        self.attachment = attachment.map(AttachmentSnapshot.init)
    }

    init(_ draft: FeedbackDraft) {
        self.init(
            category: draft.category,
            message: draft.message,
            email: draft.email ?? "",
            attachment: draft.attachment
        )
    }
}

private struct AttachmentSnapshot: Equatable {
    let data: Data
    let filename: String
    let mimeType: String
    let pixelWidth: Int?
    let pixelHeight: Int?

    init(_ attachment: FeedbackAttachment) {
        self.data = attachment.data
        self.filename = attachment.filename
        self.mimeType = attachment.mimeType
        self.pixelWidth = attachment.pixelWidth
        self.pixelHeight = attachment.pixelHeight
    }
}
