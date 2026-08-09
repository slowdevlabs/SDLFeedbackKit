import Foundation

struct FeedbackDraft: Sendable {
    var category: FeedbackCategory
    var message: String
    var email: String?
    var attachment: FeedbackAttachment?

    init(
        category: FeedbackCategory,
        message: String,
        email: String? = nil,
        attachment: FeedbackAttachment? = nil
    ) {
        self.category = category
        self.message = message
        self.email = email
        self.attachment = attachment
    }
}
