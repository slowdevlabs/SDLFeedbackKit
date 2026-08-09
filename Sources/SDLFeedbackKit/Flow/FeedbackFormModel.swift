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
            handleDraftMutation()
        }
    }

    @Published private(set) var attachment: FeedbackAttachment?
    @Published private(set) var state: FeedbackFormState

    private let context: FeedbackContext
    private let configuration: FeedbackConfiguration
    private let transport: any FeedbackTransport
    private let payloadBuilder: FeedbackPayloadBuilder
    private let imageOptimizer: any ImageOptimizer
    private let uuidProvider: () -> UUID
    private let dateProvider: () -> Date

    private var pendingSubmission: PendingSubmissionIdentity?

    init(
        context: FeedbackContext,
        configuration: FeedbackConfiguration,
        transport: any FeedbackTransport,
        payloadBuilder: FeedbackPayloadBuilder = FeedbackPayloadBuilder(),
        imageOptimizer: any ImageOptimizer = DefaultImageOptimizer(),
        uuidProvider: @escaping () -> UUID = UUID.init,
        dateProvider: @escaping () -> Date = Date.init
    ) {
        self.context = context
        self.configuration = configuration
        self.transport = transport
        self.payloadBuilder = payloadBuilder
        self.imageOptimizer = imageOptimizer
        self.uuidProvider = uuidProvider
        self.dateProvider = dateProvider
        self.selectedCategory = configuration.categories.first
        self.message = ""
        self.email = ""
        self.attachment = nil
        self.state = .idle
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
        !isSubmitting && !isProcessingAttachment
    }

    func submit() async {
        guard !isProcessingAttachment else { return }
        guard !isSubmitting else { return }
        if case .success = state {
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
        guard !isProcessingAttachment, !isSubmitting else {
            return
        }

        state = .processingAttachment

        do {
            let optimizedAttachment = try await imageOptimizer.optimize(
                data: data,
                configuration: configuration.attachment
            )
            attachment = optimizedAttachment
            pendingSubmission = nil
            state = .idle
        } catch is CancellationError {
            state = .idle
        } catch let error as FeedbackError {
            state = .failure(error)
        } catch {
            state = .failure(.attachmentProcessingFailed)
        }
    }

    func reportAttachmentFailure(_ error: FeedbackError) {
        guard !isSubmitting, !isProcessingAttachment else {
            return
        }
        state = .failure(error)
    }

    func removeAttachment() {
        guard attachment != nil else { return }
        guard !isProcessingAttachment, !isSubmitting else {
            return
        }
        attachment = nil
        pendingSubmission = nil
        state = .idle
    }

    func reset() {
        guard !isSubmitting, !isProcessingAttachment else {
            return
        }
        selectedCategory = configuration.categories.first
        message = ""
        email = ""
        attachment = nil
        pendingSubmission = nil
        state = .idle
    }

    private func handleDraftMutation() {
        pendingSubmission = nil
        if case .success = state {
            state = .idle
        } else if case .failure = state {
            state = .idle
        }
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
