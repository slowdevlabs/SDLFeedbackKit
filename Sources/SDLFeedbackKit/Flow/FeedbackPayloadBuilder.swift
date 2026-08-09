import Foundation

struct FeedbackPayloadBuilder: Sendable {
    let platformInfoProvider: any PlatformInfoProvider
    let validator: FeedbackValidator

    init(
        platformInfoProvider: any PlatformInfoProvider = DefaultPlatformInfoProvider(),
        validator: FeedbackValidator = FeedbackValidator()
    ) {
        self.platformInfoProvider = platformInfoProvider
        self.validator = validator
    }

    func build(
        context: FeedbackContext,
        draft: FeedbackDraft,
        configuration: FeedbackConfiguration,
        clientID: UUID = UUID(),
        createdAt: Date = Date()
    ) throws -> FeedbackPayload {
        let normalized = try validator.normalize(
            context: context,
            draft: draft,
            configuration: configuration
        )
        let platformInfo = platformInfoProvider.currentInfo()

        return FeedbackPayload(
            clientID: clientID,
            appID: context.appID.trimmingCharacters(in: .whitespacesAndNewlines),
            appName: context.appName.trimmingCharacters(in: .whitespacesAndNewlines),
            appVersion: platformInfo.appVersion,
            buildNumber: platformInfo.buildNumber,
            platform: platformInfo.platform,
            osVersion: platformInfo.osVersion,
            localeIdentifier: platformInfo.localeIdentifier,
            category: normalized.category,
            message: normalized.message,
            email: normalized.email,
            metadata: context.metadata,
            attachment: normalized.attachment,
            createdAt: createdAt
        )
    }
}
