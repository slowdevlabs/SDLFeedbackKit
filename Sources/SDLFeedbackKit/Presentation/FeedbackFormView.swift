#if canImport(SwiftUI)
import SwiftUI

/// A lightweight SwiftUI feedback form that owns its internal model lifecycle.
public struct FeedbackFormView: View {
    @State private var model: FeedbackFormModel

    private let configuration: FeedbackConfiguration
    private let onSubmitted: ((FeedbackSubmissionResult) -> Void)?
    private let onCancelled: (() -> Void)?

    /// Creates a feedback form view backed by the package's internal form model.
    /// - Parameters:
    ///   - context: Stable host app context.
    ///   - transport: The backend-independent submission transport.
    ///   - configuration: Form configuration, defaulting to `.default`.
    ///   - onSubmitted: Called once when a submission succeeds.
    ///   - onCancelled: Called when the user taps Cancel.
    public init(
        context: FeedbackContext,
        transport: any FeedbackTransport,
        configuration: FeedbackConfiguration = .default,
        onSubmitted: ((FeedbackSubmissionResult) -> Void)? = nil,
        onCancelled: (() -> Void)? = nil
    ) {
        _model = State(
            wrappedValue: FeedbackFormModel(
                context: context,
                configuration: configuration,
                transport: transport
            )
        )
        self.configuration = configuration
        self.onSubmitted = onSubmitted
        self.onCancelled = onCancelled
    }

    public var body: some View {
        FeedbackFormContentView(
            model: model,
            configuration: configuration,
            onSubmitted: onSubmitted,
            onCancelled: onCancelled
        )
    }
}

private struct FeedbackFormContentView: View {
    @ObservedObject var model: FeedbackFormModel
    @State private var handledSuccessClientID: UUID?
    @State private var isAttachmentPickerPresented = false

    let configuration: FeedbackConfiguration
    let onSubmitted: ((FeedbackSubmissionResult) -> Void)?
    let onCancelled: (() -> Void)?

    private var submitDisabled: Bool {
        !model.canSubmit || model.selectedCategory == nil || isSuccess || isAttachmentPickerPresented
    }

    private var isSuccess: Bool {
        if case .success = model.state {
            return true
        }
        return false
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(SDLFeedbackStrings.title)
                    .font(.title.weight(.semibold))

                FeedbackCategoryPicker(
                    selection: $model.selectedCategory,
                    categories: configuration.categories
                )

                FeedbackMessageEditor(
                    text: $model.message,
                    placeholder: SDLFeedbackStrings.messagePlaceholder
                )

                if configuration.emailField.isEnabled {
                    FeedbackEmailField(
                        text: $model.email,
                        isRequired: configuration.emailField.isRequired
                    )
                }

                if configuration.attachment.isEnabled {
                    FeedbackAttachmentSection(
                        attachment: model.attachment,
                        state: model.state,
                        isInteractionDisabled: model.isSubmitting || model.isProcessingAttachment || isAttachmentPickerPresented || isSuccess,
                        onPrimaryAction: {
                            presentAttachmentPicker()
                        },
                        onRemove: {
                            model.removeAttachment()
                        }
                    )
                }

                FeedbackSubmissionStatusView(
                    state: model.state,
                    onRetry: {
                        guard case .failure(.submissionFailed) = model.state else {
                            return
                        }

                        Task { @MainActor in
                            await model.submit()
                            deliverSuccessCallbackIfNeeded()
                        }
                    }
                )

                HStack(spacing: 12) {
                    if configuration.showsCancelButton {
                        Button(SDLFeedbackStrings.cancel) {
                            onCancelled?()
                        }
                        .disabled(model.isSubmitting || model.isProcessingAttachment || isAttachmentPickerPresented)
                    }

                    Spacer(minLength: 0)

                    Button(action: submit) {
                        Text(model.isSubmitting ? SDLFeedbackStrings.submitting : SDLFeedbackStrings.submit)
                    }
                    .disabled(submitDisabled)
                }
            }
            .frame(maxWidth: 640, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .sheet(isPresented: $isAttachmentPickerPresented) {
            AttachmentPickerHost { outcome in
                Task { @MainActor in
                    isAttachmentPickerPresented = false

                    switch outcome {
                    case let .selected(data):
                        await model.processAttachment(data: data)
                    case let .failed(error):
                        model.reportAttachmentFailure(error)
                    case .cancelled:
                        break
                    }
                }
            }
        }
    }

    private func submit() {
        Task { @MainActor in
            await model.submit()
            deliverSuccessCallbackIfNeeded()
        }
    }

    private func deliverSuccessCallbackIfNeeded() {
        guard case let .success(result) = model.state else {
            return
        }
        guard handledSuccessClientID != result.clientID else {
            return
        }

        handledSuccessClientID = result.clientID
        onSubmitted?(result)
    }

    private func presentAttachmentPicker() {
        guard !isAttachmentPickerPresented,
              !model.isSubmitting,
              !model.isProcessingAttachment,
              !isSuccess else {
            return
        }
        isAttachmentPickerPresented = true
    }
}
#endif
