import CoreGraphics
import Foundation
import ImageIO

struct DefaultImageOptimizer: ImageOptimizer {
    func optimize(
        data: Data,
        configuration: AttachmentConfiguration
    ) async throws -> FeedbackAttachment {
        let result = try await process(data: data, configuration: configuration)
        return result.attachment
    }

    func optimize(
        fileURL: URL,
        configuration: AttachmentConfiguration
    ) async throws -> FeedbackAttachment {
        let result = try await process(fileURL: fileURL, configuration: configuration)
        return result.attachment
    }

    func process(
        data: Data,
        configuration: AttachmentConfiguration
    ) async throws -> ImageProcessingResult {
        try await Task.detached(priority: .userInitiated) {
            try Self.processSynchronously(data: data, configuration: configuration)
        }.value
    }

    func process(
        fileURL: URL,
        configuration: AttachmentConfiguration
    ) async throws -> ImageProcessingResult {
        try await Task.detached(priority: .userInitiated) {
            try Self.processSynchronously(fileURL: fileURL, configuration: configuration)
        }.value
    }

    private static func processSynchronously(
        data: Data,
        configuration: AttachmentConfiguration
    ) throws -> ImageProcessingResult {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            throw FeedbackError.unsupportedAttachment
        }
        return try processSynchronously(source: source, configuration: configuration)
    }

    private static func processSynchronously(
        fileURL: URL,
        configuration: AttachmentConfiguration
    ) throws -> ImageProcessingResult {
        guard let source = CGImageSourceCreateWithURL(fileURL as CFURL, nil) else {
            throw FeedbackError.unsupportedAttachment
        }
        return try processSynchronously(source: source, configuration: configuration)
    }

    private static func processSynchronously(
        source: CGImageSource,
        configuration: AttachmentConfiguration
    ) throws -> ImageProcessingResult {
        try Task.checkCancellation()
        try validate(configuration: configuration)

        guard CGImageSourceGetCount(source) > 0 else {
            throw FeedbackError.unsupportedAttachment
        }

        let dimensionSchedule = makeDimensionSchedule(maxDimension: configuration.maximumImageDimension)

        for (stageIndex, dimensionLimit) in dimensionSchedule.enumerated() {
            try Task.checkCancellation()

            guard let cgImage = makeDownsampledImage(
                from: source,
                maxPixelSize: dimensionLimit
            ) else {
                throw FeedbackError.attachmentProcessingFailed
            }

            let resizedImage = try flattenIfNeeded(cgImage)
            let qualities = makeQualitySchedule(
                isInitialStage: stageIndex == 0,
                configuredQuality: configuration.compressionQuality,
                configuredDimension: dimensionLimit
            )

            for quality in qualities {
                try Task.checkCancellation()

                guard let encoded = encodeJPEG(image: resizedImage, quality: quality) else {
                    throw FeedbackError.attachmentProcessingFailed
                }

                if encoded.count <= configuration.maximumAttachmentBytes {
                    let attachment = FeedbackAttachment(
                        data: encoded,
                        filename: Self.outputFilename,
                        mimeType: Self.outputMimeType,
                        pixelWidth: resizedImage.width,
                        pixelHeight: resizedImage.height
                    )
                    return ImageProcessingResult(
                        attachment: attachment,
                        usedDimensionLimit: dimensionLimit,
                        usedQuality: quality,
                        finalPixelWidth: resizedImage.width,
                        finalPixelHeight: resizedImage.height
                    )
                }
            }
        }

        throw FeedbackError.attachmentTooLarge
    }

    private static func validate(configuration: AttachmentConfiguration) throws {
        guard configuration.maximumAttachmentBytes > 0,
              configuration.maximumImageDimension > 0,
              configuration.compressionQuality >= 0.5,
              configuration.compressionQuality <= 1 else {
            throw FeedbackError.invalidInput
        }
    }

    private static func makeDownsampledImage(
        from source: CGImageSource,
        maxPixelSize: Int
    ) -> CGImage? {
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ]

        return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
    }

    private static func flattenIfNeeded(_ image: CGImage) throws -> CGImage {
        let width = image.width
        let height = image.height
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo.byteOrder32Big.rawValue
            | CGImageAlphaInfo.premultipliedLast.rawValue

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            throw FeedbackError.attachmentProcessingFailed
        }

        context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

        guard let flattened = context.makeImage() else {
            throw FeedbackError.attachmentProcessingFailed
        }

        return flattened
    }

    private static func encodeJPEG(image: CGImage, quality: Double) -> Data? {
        let outputData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            outputData,
            "public.jpeg" as CFString,
            1,
            nil
        ) else {
            return nil
        }

        let properties: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: quality
        ]

        CGImageDestinationAddImage(destination, image, properties as CFDictionary)
        guard CGImageDestinationFinalize(destination) else {
            return nil
        }

        return outputData as Data
    }

    static func makeDimensionSchedule(maxDimension: Int) -> [Int] {
        var schedule: [Int] = []
        appendUnique(maxDimension, to: &schedule)
        for fallback in [1440, 1200, 1000] where fallback < maxDimension {
            appendUnique(fallback, to: &schedule)
        }
        return schedule
    }

    static func makeQualitySchedule(
        isInitialStage: Bool,
        configuredQuality: Double,
        configuredDimension: Int
    ) -> [Double] {
        let base: [Double]
        if isInitialStage {
            base = [configuredQuality, 0.8, 0.7, 0.6, 0.5]
        } else if configuredDimension > 1200 {
            base = [0.7, 0.6, 0.5]
        } else if configuredDimension > 1000 {
            base = [0.6, 0.5]
        } else {
            base = [0.55, 0.5]
        }

        var schedule: [Double] = []
        for quality in base where quality <= configuredQuality && quality >= 0.5 {
            appendUnique(quality, to: &schedule)
        }

        if schedule.isEmpty {
            appendUnique(0.5, to: &schedule)
        }

        return schedule
    }

    private static func appendUnique(_ value: Int, to schedule: inout [Int]) {
        guard !schedule.contains(value) else { return }
        schedule.append(value)
    }

    private static func appendUnique(_ value: Double, to schedule: inout [Double]) {
        guard !schedule.contains(where: { abs($0 - value) < 0.000001 }) else { return }
        schedule.append(value)
    }

    private static let outputFilename = "feedback.jpg"
    private static let outputMimeType = "image/jpeg"
}
