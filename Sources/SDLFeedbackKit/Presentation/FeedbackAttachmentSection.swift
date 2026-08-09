#if canImport(SwiftUI)
import SwiftUI

struct FeedbackAttachmentSection: View {
    let attachment: FeedbackAttachment?
    let state: FeedbackFormState
    let isInteractionDisabled: Bool
    let onPrimaryAction: () -> Void
    let onRemove: () -> Void

    private var byteCountFormatter: ByteCountFormatter {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(SDLFeedbackStrings.attachmentTitle)
                .font(.headline)

            switch state {
            case .processingAttachment:
                HStack(spacing: 10) {
                    FeedbackActivityIndicator()
                    Text(SDLFeedbackStrings.attachmentPreparing)
                        .foregroundColor(.secondary)
                }
            default:
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
                            Button(SDLFeedbackStrings.attachmentReplace) {
                                onPrimaryAction()
                            }
                            .disabled(isInteractionDisabled)

                            Button(SDLFeedbackStrings.attachmentRemove) {
                                onRemove()
                            }
                            .disabled(isInteractionDisabled)
                        }
                    }
                } else {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(SDLFeedbackStrings.attachmentNone)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        Button(SDLFeedbackStrings.attachmentAdd) {
                            onPrimaryAction()
                        }
                        .disabled(isInteractionDisabled)
                    }
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
