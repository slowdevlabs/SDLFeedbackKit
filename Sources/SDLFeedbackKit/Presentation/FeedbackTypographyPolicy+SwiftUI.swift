#if canImport(SwiftUI)
import SwiftUI

extension FeedbackTypographyPolicy {
    func resolvedSizeCategory(from sizeCategory: ContentSizeCategory) -> ContentSizeCategory {
        switch self {
        case .system:
            return sizeCategory
        case .restrained:
            return Self.clamp(sizeCategory, toMaximum: .extraExtraExtraLarge)
        }
    }

    static func clamp(
        _ sizeCategory: ContentSizeCategory,
        toMaximum maximum: ContentSizeCategory
    ) -> ContentSizeCategory {
        let orderedCategories: [ContentSizeCategory] = [
            .extraSmall,
            .small,
            .medium,
            .large,
            .extraLarge,
            .extraExtraLarge,
            .extraExtraExtraLarge,
            .accessibilityMedium,
            .accessibilityLarge,
            .accessibilityExtraLarge,
            .accessibilityExtraExtraLarge,
            .accessibilityExtraExtraExtraLarge
        ]

        guard
            let currentIndex = orderedCategories.firstIndex(of: sizeCategory),
            let maximumIndex = orderedCategories.firstIndex(of: maximum)
        else {
            return sizeCategory
        }

        return orderedCategories[min(currentIndex, maximumIndex)]
    }
}
#endif
