#if canImport(SwiftUI)
import SwiftUI

struct FeedbackCategoryPicker: View {
    @Binding var selection: FeedbackCategory?
    let categories: [FeedbackCategory]
    @Environment(\.locale) private var locale
    @State private var disclosureState = FeedbackCategoryDisclosureState()

    private var selectedCategory: FeedbackCategory? {
        selection ?? categories.first
    }

    private var selectedTitle: String {
        guard let selectedCategory else {
            return SDLFeedbackLocalizedStrings.categoryTitle(locale: locale)
        }

        if let localizedTitle = SDLFeedbackLocalizedStrings.categoryTitle(for: selectedCategory, locale: locale) {
            return localizedTitle
        }

        return selectedCategory.title
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(SDLFeedbackLocalizedStrings.categoryTitle(locale: locale))
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                Button(action: toggleExpansion) {
                    HStack(spacing: 12) {
                        Text(selectedTitle)
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                        Text(disclosureState.isExpanded ? "⌃" : "⌄")
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.secondary.opacity(0.08))
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())

                if disclosureState.isExpanded {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(categories) { category in
                            categoryRow(for: category)
                        }
                    }
                    .transition(.opacity)
                }
            }
        }
    }

    private func toggleExpansion() {
        withAnimation(.easeInOut(duration: 0.16)) {
            disclosureState.toggle()
        }
    }

    private func categoryRow(for category: FeedbackCategory) -> some View {
        let isSelected = selection?.id == category.id
        let title = SDLFeedbackLocalizedStrings.categoryTitle(for: category, locale: locale) ?? category.title

        return Button(action: {
            withAnimation(.easeInOut(duration: 0.16)) {
                selection = category
                disclosureState.collapse()
            }
        }) {
            HStack(spacing: 12) {
                Text(title)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                if isSelected {
                    Text("✓")
                        .foregroundColor(.accentColor)
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.secondary.opacity(0.08) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        #if os(iOS)
        .accessibility(addTraits: isSelected ? .isSelected : [])
        #endif
    }
}
#endif
