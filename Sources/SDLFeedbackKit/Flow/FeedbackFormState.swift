import Foundation

enum FeedbackFormState {
    case idle
    case processingAttachment
    case submitting
    case success(FeedbackSubmissionResult)
    case failure(FeedbackError)
}
