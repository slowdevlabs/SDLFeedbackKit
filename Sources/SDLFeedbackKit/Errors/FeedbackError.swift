import Foundation

public enum FeedbackError: Error, Sendable, Equatable {
    case invalidInput
    case invalidEmail
    case attachmentTooLarge
    case unsupportedAttachment
    case attachmentProcessingFailed
    case submissionFailed
    case cancelled
}
