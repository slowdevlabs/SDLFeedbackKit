#if canImport(SwiftUI)
import SwiftUI

struct FeedbackAttachmentSection: View {
    let attachment: FeedbackAttachment?
    let state: FeedbackFormState
    let isInteractionDisabled: Bool
    let onPrimaryAction: () -> Void
    let onRemove: () -> Void
    @Environment(\.locale) private var locale

    private var byteCountFormatter: ByteCountFormatter {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 0) {
                Text(SDLFeedbackLocalizedStrings.attachmentTitle(locale: locale))
                    .fixedSize(horizontal: false, vertical: true)
                Text(" (")
                    .font(.headline)
                    .fontWeight(.regular)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(SDLFeedbackLocalizedStrings.optional(locale: locale))
                    .font(.headline)
                    .fontWeight(.regular)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(")")
                    .font(.headline)
                    .fontWeight(.regular)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .font(.headline)
            .accessibilityElement(children: .combine)

            if let processingMessage = FeedbackAttachmentPresentation.processingMessage(for: state, locale: locale) {
                HStack(spacing: 10) {
                    FeedbackActivityIndicator()
                    Text(processingMessage)
                        .foregroundColor(.secondary)
                }
            }

            if let errorMessage = FeedbackAttachmentPresentation.attachmentErrorMessage(for: state, locale: locale) {
                Text(errorMessage)
                    .font(.subheadline)
                    .foregroundColor(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let attachment {
                VStack(alignment: .leading, spacing: 10) {
                    Text(attachment.filename)
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(byteCountFormatter.string(fromByteCount: Int64(attachment.byteCount)))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 12) {
                        Button(SDLFeedbackLocalizedStrings.attachmentReplace(locale: locale)) {
                            onPrimaryAction()
                        }
                        .disabled(isInteractionDisabled)

                        Button(SDLFeedbackLocalizedStrings.attachmentRemove(locale: locale)) {
                            onRemove()
                        }
                        .disabled(isInteractionDisabled)
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text(SDLFeedbackLocalizedStrings.attachmentNone(locale: locale))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Button(SDLFeedbackLocalizedStrings.attachmentAdd(locale: locale)) {
                        onPrimaryAction()
                    }
                    .disabled(isInteractionDisabled)
                }
            }
        }
    }
}

struct FeedbackActivityIndicator: View {
    var body: some View {
        PlatformActivityIndicator()
    }
}

#if os(iOS)
import UIKit

struct PlatformActivityIndicator: UIViewRepresentable {
    func makeUIView(context: Context) -> UIActivityIndicatorView {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.startAnimating()
        return indicator
    }

    func updateUIView(_ uiView: UIActivityIndicatorView, context: Context) {
        uiView.startAnimating()
    }
}
#elseif os(macOS)
import AppKit

struct PlatformActivityIndicator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSProgressIndicator {
        let indicator = NSProgressIndicator()
        indicator.style = .spinning
        indicator.controlSize = .regular
        indicator.isDisplayedWhenStopped = false
        indicator.startAnimation(nil)
        return indicator
    }

    func updateNSView(_ nsView: NSProgressIndicator, context: Context) {
        nsView.startAnimation(nil)
    }
}
#endif
#endif
