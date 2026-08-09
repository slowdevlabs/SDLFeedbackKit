import Foundation

public struct FeedbackAttachment: Sendable {
    public let data: Data
    public let filename: String
    public let mimeType: String
    public let pixelWidth: Int?
    public let pixelHeight: Int?
    public let byteCount: Int

    internal init(
        data: Data,
        filename: String,
        mimeType: String,
        pixelWidth: Int? = nil,
        pixelHeight: Int? = nil
    ) {
        self.data = data
        self.filename = filename
        self.mimeType = mimeType
        self.pixelWidth = pixelWidth
        self.pixelHeight = pixelHeight
        self.byteCount = data.count
    }
}
