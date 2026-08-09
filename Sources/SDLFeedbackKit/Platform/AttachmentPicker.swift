import Foundation

enum AttachmentPickerOutcome: Sendable {
    case selected(Data)
    case cancelled
    case failed(FeedbackError)
}
