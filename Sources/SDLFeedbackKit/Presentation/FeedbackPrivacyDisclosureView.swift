#if canImport(SwiftUI)
import Foundation
import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct FeedbackPrivacyDisclosureView: View {
    let appName: String
    let privacyPolicyURL: URL
    @Environment(\.locale) private var locale

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(SDLFeedbackLocalizedStrings.privacyDisclosureBody(appName: appName, locale: locale))
                .font(.footnote)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Button(action: openPrivacyPolicy) {
                Text(SDLFeedbackLocalizedStrings.privacyPolicyLabel(locale: locale))
                    .font(.footnote.weight(.semibold))
                    .underline()
            }
            .buttonStyle(.plain)
            .foregroundColor(.accentColor)
        }
    }

    private func openPrivacyPolicy() {
#if os(iOS)
        UIApplication.shared.open(privacyPolicyURL, options: [:], completionHandler: nil)
#elseif os(macOS)
        NSWorkspace.shared.open(privacyPolicyURL)
#endif
    }
}

enum FeedbackPrivacyDisclosure {
    static func shouldDisplay(privacyPolicyURL: URL?) -> Bool {
        privacyPolicyURL != nil
    }

    static func disclosureBody(appName: String) -> String {
        SDLFeedbackStrings.privacyDisclosureBody(appName: appName)
    }
}
#endif
