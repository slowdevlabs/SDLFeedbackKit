#if canImport(SwiftUI)
import SwiftUI

struct FeedbackCategoryPicker: View {
    @Binding var selection: FeedbackCategory?
    let categories: [FeedbackCategory]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(SDLFeedbackStrings.categoryTitle)
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(categories) { category in
                    Button(action: {
                        selection = category
                    }) {
                        HStack(spacing: 12) {
                            Text(category.title)
                                .foregroundColor(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 0)
                            if selection?.id == category.id {
                                Text("✓")
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(selection?.id == category.id ? Color.accentColor.opacity(0.12) : Color.clear)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}
#endif
