import Foundation

struct ImageProcessingResult: Sendable {
    let attachment: FeedbackAttachment
    let usedDimensionLimit: Int
    let usedQuality: Double
    let finalPixelWidth: Int
    let finalPixelHeight: Int
}
