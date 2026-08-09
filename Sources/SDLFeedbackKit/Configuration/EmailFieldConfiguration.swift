import Foundation

public struct EmailFieldConfiguration: Sendable {
    public var isEnabled: Bool
    public var isRequired: Bool
    public var maximumLength: Int

    public init(
        isEnabled: Bool = true,
        isRequired: Bool = false,
        maximumLength: Int = 320
    ) {
        self.isEnabled = isEnabled
        self.isRequired = isRequired
        self.maximumLength = maximumLength
    }

    public static var `default`: EmailFieldConfiguration {
        EmailFieldConfiguration()
    }
}
