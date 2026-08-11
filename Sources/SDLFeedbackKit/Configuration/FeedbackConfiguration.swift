import Foundation

public struct FeedbackConfiguration: Sendable {
    public var categories: [FeedbackCategory]
    public var emailField: EmailFieldConfiguration
    public var attachment: AttachmentConfiguration
    public var message: MessageConfiguration
    public var showsCancelButton: Bool
    public var privacyPolicyURL: URL?
    public var typographyPolicy: FeedbackTypographyPolicy

    public init(
        categories: [FeedbackCategory] = .defaultFeedbackCategories,
        emailField: EmailFieldConfiguration = .default,
        attachment: AttachmentConfiguration = .default,
        message: MessageConfiguration = .default,
        showsCancelButton: Bool = true,
        privacyPolicyURL: URL? = nil,
        typographyPolicy: FeedbackTypographyPolicy = .system
    ) {
        self.categories = categories
        self.emailField = emailField
        self.attachment = attachment
        self.message = message
        self.showsCancelButton = showsCancelButton
        self.privacyPolicyURL = privacyPolicyURL
        self.typographyPolicy = typographyPolicy
    }

    public static var `default`: FeedbackConfiguration {
        FeedbackConfiguration()
    }
}
