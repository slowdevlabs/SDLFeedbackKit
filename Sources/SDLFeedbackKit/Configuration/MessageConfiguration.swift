import Foundation

public struct MessageConfiguration: Sendable {
    public var minimumLength: Int
    public var maximumLength: Int
    public var isRequired: Bool

    public init(
        minimumLength: Int = 1,
        maximumLength: Int = 5_000,
        isRequired: Bool = true
    ) {
        self.minimumLength = minimumLength
        self.maximumLength = maximumLength
        self.isRequired = isRequired
    }

    public static var `default`: MessageConfiguration {
        MessageConfiguration()
    }
}
