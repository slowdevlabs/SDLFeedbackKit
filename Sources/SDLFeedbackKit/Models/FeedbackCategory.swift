import Foundation

public struct FeedbackCategory: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String

    public init(
        id: String,
        title: String
    ) {
        self.id = id
        self.title = title
    }
}

public extension FeedbackCategory {
    static var general: FeedbackCategory {
        FeedbackCategory(id: "general", title: SDLFeedbackStrings.categoryGeneral)
    }

    static var bug: FeedbackCategory {
        FeedbackCategory(id: "bug", title: SDLFeedbackStrings.categoryBug)
    }

    static var featureRequest: FeedbackCategory {
        FeedbackCategory(
            id: "feature_request",
            title: SDLFeedbackStrings.categoryFeatureRequest
        )
    }

    static var other: FeedbackCategory {
        FeedbackCategory(id: "other", title: SDLFeedbackStrings.categoryOther)
    }
}

public extension Array where Element == FeedbackCategory {
    static var defaultFeedbackCategories: [FeedbackCategory] {
        [
            .general,
            .bug,
            .featureRequest,
            .other
        ]
    }
}
