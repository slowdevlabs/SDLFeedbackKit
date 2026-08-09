#if canImport(SwiftUI)
import SwiftUI

struct FeedbackEmailField: View {
    @Binding var text: String
    let isRequired: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Text(SDLFeedbackStrings.emailTitle)
                    .font(.headline)
                    .fixedSize(horizontal: false, vertical: true)
                if !isRequired {
                    Text(SDLFeedbackStrings.emailOptional)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            TextField("", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .modifier(FeedbackEmailInputTraits())
        }
    }
}

private struct FeedbackEmailInputTraits: ViewModifier {
    func body(content: Content) -> some View {
        #if os(iOS)
        return content
            .keyboardType(.emailAddress)
            .textContentType(.emailAddress)
            .autocapitalization(.none)
            .disableAutocorrection(true)
        #elseif os(macOS)
        return content
        #else
        return content
        #endif
    }
}
#endif
