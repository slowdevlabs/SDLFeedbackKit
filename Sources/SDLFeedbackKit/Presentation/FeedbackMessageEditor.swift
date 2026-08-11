#if canImport(SwiftUI)
import SwiftUI

struct FeedbackMessageEditor: View {
    @Binding var text: String
    let placeholder: String
    @Environment(\.locale) private var locale
    @Environment(\.sizeCategory) private var sizeCategory

    private let minimumHeight: CGFloat = 140

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(SDLFeedbackLocalizedStrings.messageTitle(locale: locale))
                .font(.headline)

            ZStack(alignment: .topLeading) {
                MultilineTextView(text: $text, sizeCategory: sizeCategory)
                    .frame(minHeight: minimumHeight)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.clear)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.secondary.opacity(0.25))
                    )

                if text.isEmpty {
                    Text(placeholder)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 18)
                        .allowsHitTesting(false)
                }
            }
        }
    }
}

private struct MultilineTextView: View {
    @Binding var text: String
    let sizeCategory: ContentSizeCategory

    var body: some View {
        PlatformMultilineTextView(text: $text, sizeCategory: sizeCategory)
    }
}

#if os(iOS)
import UIKit

private struct PlatformMultilineTextView: UIViewRepresentable {
    @Binding var text: String
    let sizeCategory: ContentSizeCategory

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.backgroundColor = .clear
        textView.font = bodyFont(for: sizeCategory)
        textView.adjustsFontForContentSizeCategory = true
        textView.textColor = UIColor.label
        textView.delegate = context.coordinator
        textView.isScrollEnabled = true
        textView.alwaysBounceVertical = true
        textView.textContainerInset = UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 8)
        textView.text = text
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.font = bodyFont(for: sizeCategory)
        if uiView.text != text {
            uiView.text = text
        }
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        private var text: Binding<String>

        init(text: Binding<String>) {
            self.text = text
        }

        func textViewDidChange(_ textView: UITextView) {
            text.wrappedValue = textView.text
        }
    }

    private func bodyFont(for sizeCategory: ContentSizeCategory) -> UIFont {
        let traitCollection = UITraitCollection(preferredContentSizeCategory: sizeCategory.uiContentSizeCategory)
        return UIFont.preferredFont(forTextStyle: .body, compatibleWith: traitCollection)
    }
}
#elseif os(macOS)
import AppKit

private struct PlatformMultilineTextView: NSViewRepresentable {
    @Binding var text: String
    let sizeCategory: ContentSizeCategory

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false

        let textView = NSTextView()
        textView.delegate = context.coordinator
        textView.isRichText = false
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.backgroundColor = .clear
        textView.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        textView.setAccessibilityElement(true)
        textView.string = text
        textView.textContainerInset = NSSize(width: 6, height: 10)
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )

        scrollView.documentView = textView
        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else {
            return
        }

        if textView.string != text {
            textView.string = text
        }
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        private var text: Binding<String>

        init(text: Binding<String>) {
            self.text = text
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            text.wrappedValue = textView.string
        }
    }
}
#endif

#if os(iOS)
private extension ContentSizeCategory {
    var uiContentSizeCategory: UIContentSizeCategory {
        switch self {
        case .extraSmall:
            return .extraSmall
        case .small:
            return .small
        case .medium:
            return .medium
        case .large:
            return .large
        case .extraLarge:
            return .extraLarge
        case .extraExtraLarge:
            return .extraExtraLarge
        case .extraExtraExtraLarge:
            return .extraExtraExtraLarge
        case .accessibilityMedium:
            return .accessibilityMedium
        case .accessibilityLarge:
            return .accessibilityLarge
        case .accessibilityExtraLarge:
            return .accessibilityExtraLarge
        case .accessibilityExtraExtraLarge:
            return .accessibilityExtraExtraLarge
        case .accessibilityExtraExtraExtraLarge:
            return .accessibilityExtraExtraExtraLarge
        @unknown default:
            return .large
        }
    }
}
#endif

#endif
