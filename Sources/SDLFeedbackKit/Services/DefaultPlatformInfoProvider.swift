import Foundation

struct DefaultPlatformInfoProvider: PlatformInfoProvider {
    let bundle: Bundle

    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    func currentInfo() -> PlatformInfo {
        PlatformInfo(
            appVersion: value(forInfoDictionaryKey: "CFBundleShortVersionString"),
            buildNumber: value(forInfoDictionaryKey: "CFBundleVersion"),
            platform: currentPlatform(),
            osVersion: currentOSVersion(),
            localeIdentifier: Locale.current.identifier
        )
    }

    private func value(forInfoDictionaryKey key: String) -> String? {
        guard let value = bundle.object(forInfoDictionaryKey: key) as? String else {
            return nil
        }

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func currentPlatform() -> FeedbackPlatform {
#if os(iOS)
        return .iOS
#elseif os(macOS)
        return .macOS
#endif
    }

    private func currentOSVersion() -> String {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        let components = [version.majorVersion, version.minorVersion, version.patchVersion]
        return components
            .map(String.init)
            .joined(separator: ".")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
