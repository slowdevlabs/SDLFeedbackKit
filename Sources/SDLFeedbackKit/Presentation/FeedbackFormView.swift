#if canImport(SwiftUI)
import SwiftUI

/// A lightweight SwiftUI feedback form that owns its internal model lifecycle.
public struct FeedbackFormView: View {
    @State private var model: FeedbackFormModel

    private let context: FeedbackContext
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
        self.context = context
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
            context: context,
            configuration: configuration,
            onSubmitted: onSubmitted,
            onCancelled: onCancelled
        )
    }
}

private struct FeedbackFormContentView: View {
    @ObservedObject var model: FeedbackFormModel
    let context: FeedbackContext
    @State private var handledSuccessClientID: UUID?
    @State private var isAttachmentPickerPresented = false
    @State private var activeAttachmentSelectionID: UUID?
    @Environment(\.locale) private var locale
    @Environment(\.sizeCategory) private var sizeCategory
#if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
#endif

    let configuration: FeedbackConfiguration
    let onSubmitted: ((FeedbackSubmissionResult) -> Void)?
    let onCancelled: (() -> Void)?

    private var isSuccess: Bool {
        if case .success = model.state {
            return true
        }
        return false
    }

    var body: some View {
        let appliedSizeCategory = configuration.typographyPolicy.resolvedSizeCategory(from: sizeCategory)
#if os(iOS)
        let isRegularWidth = horizontalSizeClass == .regular
#else
        let isRegularWidth = false
#endif
        VStack(spacing: 0) {
            ScrollView {
                VStack(
                    alignment: .leading,
                    spacing: FeedbackFormPresentationMetrics.contentSpacing(isRegularWidth: isRegularWidth)
                ) {
                    Text(SDLFeedbackLocalizedStrings.title(locale: locale))
                        .font(.title.weight(.semibold))

                    FeedbackCategoryPicker(
                        selection: $model.selectedCategory,
                        categories: configuration.categories
                    )

                    FeedbackMessageEditor(
                        text: $model.message,
                        placeholder: SDLFeedbackLocalizedStrings.messagePlaceholder(locale: locale)
                    )

                    if configuration.emailField.isEnabled {
                        FeedbackEmailField(
                            text: $model.email,
                            isRequired: configuration.emailField.isRequired,
                            validationError: model.emailValidationError
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

                    if let privacyPolicyURL = configuration.privacyPolicyURL,
                       FeedbackPrivacyDisclosure.shouldDisplay(privacyPolicyURL: privacyPolicyURL) {
                        FeedbackPrivacyDisclosureView(
                            appName: context.appName,
                            privacyPolicyURL: privacyPolicyURL
                        )
                        .padding(.top, 4)
                    }
                }
                .frame(maxWidth: 640, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, 20)
                .padding(.top, FeedbackFormPresentationMetrics.contentTopPadding(isRegularWidth: isRegularWidth))
                .padding(.bottom, FeedbackFormPresentationMetrics.contentBottomPadding(isRegularWidth: isRegularWidth))
            }

            Divider()

            FeedbackFormActionBar(
                configuration: configuration,
                model: model,
                isAttachmentPickerPresented: isAttachmentPickerPresented,
                isSuccess: isSuccess,
                locale: locale,
                onCancel: {
                    AttachmentPickerDebugLog.log("feedbackForm.onCancelled.invoked")
                    onCancelled?()
                },
                onSubmit: submit
            )
        }
        .background(FeedbackFormBackground())
        .onAppear {
            AttachmentPickerDebugLog.log("feedbackForm.appear")
        }
        .onDisappear {
            AttachmentPickerDebugLog.log("feedbackForm.disappear")
        }
        .environment(\.sizeCategory, appliedSizeCategory)
        .sheet(isPresented: $isAttachmentPickerPresented) {
            AttachmentPickerHost(
                onSelectionAccepted: {
                    let selectionID = activeAttachmentSelectionID
                    Task { @MainActor in
                        AttachmentPickerDebugLog.log("picker.selectionAccepted.received id=\(selectionID?.uuidString ?? "nil")")
                        if let selectionID {
                            model.beginAttachmentAcquisition(selectionID: selectionID)
                        }
                        AttachmentPickerDebugLog.log("nestedPicker.isPresented = false id=\(selectionID?.uuidString ?? "nil")")
                        isAttachmentPickerPresented = false
                    }
                },
                onOutcome: { outcome in
                    Task { @MainActor in
                        AttachmentPickerDebugLog.log("picker.outcome.dispatch.requested id=\(activeAttachmentSelectionID?.uuidString ?? "nil")")
                        if let selectionID = activeAttachmentSelectionID {
                            model.markAttachmentProviderResponse(selectionID: selectionID)
                        }
                        await AttachmentPickerOutcomeDispatcher(
                            selectionID: activeAttachmentSelectionID,
                            dismissPicker: {
                                isAttachmentPickerPresented = false
                            },
                            processData: { data, selectionID in
                                await model.processAttachment(data: data, selectionID: selectionID)
                            },
                            processFile: { fileURL, selectionID in
                                await model.processAttachment(fileURL: fileURL, selectionID: selectionID)
                            },
                            reportFailure: { error, selectionID in
                                model.reportAttachmentFailure(error, selectionID: selectionID)
                            }
                        ).dispatch(outcome)
                    }
                }
            )
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
        AttachmentPickerDebugLog.log("feedbackForm.onSubmitted.invoked")
        onSubmitted?(result)
    }

    private func presentAttachmentPicker() {
        guard !isAttachmentPickerPresented,
              !model.isSubmitting,
              !model.isProcessingAttachment,
              !isSuccess else {
            return
        }
        activeAttachmentSelectionID = model.beginAttachmentSelection()
        AttachmentPickerDebugLog.log("feedbackForm.presentAttachmentPicker id=\(activeAttachmentSelectionID?.uuidString ?? "nil")")
        isAttachmentPickerPresented = true
    }
}

private struct FeedbackFormActionBar: View {
    let configuration: FeedbackConfiguration
    @ObservedObject var model: FeedbackFormModel
    let isAttachmentPickerPresented: Bool
    let isSuccess: Bool
    let locale: Locale
    let onCancel: () -> Void
    let onSubmit: () -> Void

    private var submitDisabled: Bool {
        !model.canSubmit || model.selectedCategory == nil || isSuccess || isAttachmentPickerPresented
    }

    var body: some View {
        HStack(spacing: 12) {
            if configuration.showsCancelButton {
                Button(SDLFeedbackLocalizedStrings.cancel(locale: locale)) {
                    onCancel()
                }
                .disabled(model.isSubmitting || model.isProcessingAttachment || isAttachmentPickerPresented)
            }

            Spacer(minLength: 0)

            Button(action: onSubmit) {
                Text(
                    model.isSubmitting
                        ? SDLFeedbackLocalizedStrings.submitting(locale: locale)
                        : SDLFeedbackLocalizedStrings.submit(locale: locale)
                )
            }
            .disabled(submitDisabled)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(FeedbackFormPresentationMetrics.footerSurfaceFill)
    }
}

private struct FeedbackFormBackground: View {
    var body: some View {
#if os(iOS)
        Color(UIColor.systemBackground)
            .edgesIgnoringSafeArea(.all)
#elseif os(macOS)
        Color(NSColor.windowBackgroundColor)
            .edgesIgnoringSafeArea(.all)
#else
        Color(.background)
#endif
    }
}
#endif
