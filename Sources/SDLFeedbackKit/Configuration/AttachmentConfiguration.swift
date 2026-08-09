import Foundation

public struct AttachmentConfiguration: Sendable {
    public var isEnabled: Bool
    public var maximumAttachmentBytes: Int
    public var maximumImageDimension: Int
    public var compressionQuality: Double

    public init(
        isEnabled: Bool = true,
        maximumAttachmentBytes: Int = 1_000_000,
        maximumImageDimension: Int = 1_800,
        compressionQuality: Double = 0.8
    ) {
        self.isEnabled = isEnabled
        self.maximumAttachmentBytes = maximumAttachmentBytes
        self.maximumImageDimension = maximumImageDimension
        self.compressionQuality = compressionQuality
    }

    public static var `default`: AttachmentConfiguration {
        AttachmentConfiguration()
    }
}
