#if canImport(SwiftUI)
import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

enum FeedbackFormPresentationMetrics {
    static func contentSpacing(isRegularWidth: Bool) -> CGFloat {
        isRegularWidth ? 20 : 24
    }

    static func contentTopPadding(isRegularWidth: Bool) -> CGFloat {
        isRegularWidth ? 20 : 24
    }

    static func contentBottomPadding(isRegularWidth: Bool) -> CGFloat {
        isRegularWidth ? 20 : 28
    }

    static func messageEditorMinimumHeight(isRegularWidth: Bool, isCompactHeight: Bool) -> CGFloat {
        if isRegularWidth, !isCompactHeight {
            return 116
        }
        return 140
    }

    static var controlCornerRadius: CGFloat {
        12
    }

    static var controlBorderWidth: CGFloat {
        1
    }

    static var controlSurfaceFill: Color {
#if os(iOS)
        Color(UIColor.secondarySystemBackground)
#elseif os(macOS)
        Color(NSColor.controlBackgroundColor)
#else
        Color(.background)
#endif
    }

    static var footerSurfaceFill: Color {
        controlSurfaceFill
    }

    static var controlBorderColor: Color {
#if os(iOS)
        Color(UIColor.separator).opacity(0.22)
#elseif os(macOS)
        Color(NSColor.separatorColor).opacity(0.22)
#else
        Color.secondary.opacity(0.22)
#endif
    }
}
#endif
