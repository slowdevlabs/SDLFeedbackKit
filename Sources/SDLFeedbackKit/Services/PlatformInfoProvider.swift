import Foundation

protocol PlatformInfoProvider: Sendable {
    func currentInfo() -> PlatformInfo
}
