import CoreGraphics
import Foundation
import ImageIO
import XCTest
@testable import SDLFeedbackKit

final class DefaultImageOptimizerTests: XCTestCase {
    private let optimizer = DefaultImageOptimizer()

    func testDimensionScheduleHelper() {
        XCTAssertEqual(DefaultImageOptimizer.makeDimensionSchedule(maxDimension: 1800), [1800, 1440, 1200, 1000])
        XCTAssertEqual(DefaultImageOptimizer.makeDimensionSchedule(maxDimension: 1600), [1600, 1440, 1200, 1000])
        XCTAssertEqual(DefaultImageOptimizer.makeDimensionSchedule(maxDimension: 1200), [1200, 1000])
        XCTAssertEqual(DefaultImageOptimizer.makeDimensionSchedule(maxDimension: 900), [900])
    }

    func testQualityScheduleHelper() {
        XCTAssertEqual(
            DefaultImageOptimizer.makeQualitySchedule(
                isInitialStage: true,
                configuredQuality: 0.9,
                configuredDimension: 1800
            ),
            [0.9, 0.8, 0.7, 0.6, 0.5]
        )

        XCTAssertEqual(
            DefaultImageOptimizer.makeQualitySchedule(
                isInitialStage: true,
                configuredQuality: 0.65,
                configuredDimension: 1800
            ),
            [0.65, 0.6, 0.5]
        )

        XCTAssertEqual(
            DefaultImageOptimizer.makeQualitySchedule(
                isInitialStage: false,
                configuredQuality: 0.8,
                configuredDimension: 1440
            ),
            [0.7, 0.6, 0.5]
        )

        XCTAssertEqual(
            DefaultImageOptimizer.makeQualitySchedule(
                isInitialStage: false,
                configuredQuality: 0.8,
                configuredDimension: 1200
            ),
            [0.6, 0.5]
        )

        XCTAssertEqual(
            DefaultImageOptimizer.makeQualitySchedule(
                isInitialStage: false,
                configuredQuality: 0.8,
                configuredDimension: 1000
            ),
            [0.55, 0.5]
        )
    }

    func testEmptyDataFailsSafely() async {
        await XCTAssertThrowsErrorAsync {
            try await self.optimizer.optimize(data: Data(), configuration: .default)
        } errorHandler: { error in
            XCTAssertEqual(error as? FeedbackError, .unsupportedAttachment)
        }
    }

    func testInvalidDataFailsSafely() async {
        await XCTAssertThrowsErrorAsync {
            try await self.optimizer.optimize(data: Data("not-an-image".utf8), configuration: .default)
        } errorHandler: { error in
            XCTAssertEqual(error as? FeedbackError, .unsupportedAttachment)
        }
    }

    func testJPEGInputProducesJPEGOutput() async throws {
        let source = try ImageTestFactory.solidJPEGData(width: 640, height: 480)
        let attachment = try await optimizer.optimize(data: source, configuration: .default)

        XCTAssertEqual(attachment.filename, "feedback.jpg")
        XCTAssertEqual(attachment.mimeType, "image/jpeg")
        XCTAssertEqual(attachment.byteCount, attachment.data.count)
        XCTAssertNotNil(makeImageSource(from: attachment.data))
    }

    func testPNGInputProducesJPEGOutputAndDoesNotUpscale() async throws {
        let source = try ImageTestFactory.transparentPNGData(width: 500, height: 500)
        let attachment = try await optimizer.optimize(data: source, configuration: .default)

        XCTAssertEqual(attachment.mimeType, "image/jpeg")
        XCTAssertEqual(attachment.filename, "feedback.jpg")
        XCTAssertLessThanOrEqual(attachment.pixelWidth ?? .max, 500)
        XCTAssertLessThanOrEqual(attachment.pixelHeight ?? .max, 500)
        XCTAssertNotNil(makeImageSource(from: attachment.data))
    }

    func testOrientationIsNormalized() async throws {
        let source = try ImageTestFactory.solidJPEGData(
            width: 1200,
            height: 800,
            orientation: .right,
            includeMetadata: true
        )
        let result = try await optimizer.process(data: source, configuration: .default)

        XCTAssertEqual(result.attachment.mimeType, "image/jpeg")
        XCTAssertEqual(result.finalPixelWidth, 800)
        XCTAssertEqual(result.finalPixelHeight, 1200)
        XCTAssertGreaterThan(result.finalPixelHeight, result.finalPixelWidth)
    }

    func testMetadataIsStripped() async throws {
        let source = try ImageTestFactory.solidJPEGData(
            width: 900,
            height: 600,
            includeMetadata: true
        )
        let attachment = try await optimizer.optimize(data: source, configuration: .default)
        let properties = imageProperties(from: attachment.data)
        let exif = properties?[kCGImagePropertyExifDictionary as String] as? [String: Any]

        XCTAssertNil(properties?[kCGImagePropertyGPSDictionary as String])
        XCTAssertNil(exif?[kCGImagePropertyExifUserComment as String])
        XCTAssertNil(exif?[kCGImagePropertyExifLensModel as String])
        XCTAssertNil(exif?[kCGImagePropertyExifCameraOwnerName as String])
    }

    func testCustomMaximumDimensionRespected() async throws {
        let source = try ImageTestFactory.noisyJPEGData(width: 2400, height: 1800)
        let configuration = AttachmentConfiguration(maximumImageDimension: 1200)
        let result = try await optimizer.process(data: source, configuration: configuration)

        XCTAssertLessThanOrEqual(result.usedDimensionLimit, 1200)
        XCTAssertLessThanOrEqual(result.finalPixelWidth, 1200)
        XCTAssertLessThanOrEqual(result.finalPixelHeight, 1200)
    }

    func testAdaptiveRecompressionUsesSmallerQualityOrDimension() async throws {
        let source = try ImageTestFactory.noisyJPEGData(width: 2400, height: 2400)
        let configuration = AttachmentConfiguration(
            maximumAttachmentBytes: 1_000_000,
            maximumImageDimension: 1800,
            compressionQuality: 0.8
        )
        let result = try await optimizer.process(data: source, configuration: configuration)

        XCTAssertLessThanOrEqual(result.attachment.byteCount, 1_000_000)
        XCTAssertTrue(result.usedDimensionLimit < 1800 || result.usedQuality < 0.8)
    }

    func testFinalAttachmentTooLargeFails() async {
        let source = try? ImageTestFactory.solidJPEGData(width: 500, height: 500)
        XCTAssertNotNil(source)

        await XCTAssertThrowsErrorAsync {
            try await self.optimizer.optimize(
                data: source!,
                configuration: AttachmentConfiguration(
                    maximumAttachmentBytes: 1,
                    maximumImageDimension: 1800,
                    compressionQuality: 0.8
                )
            )
        } errorHandler: { error in
            XCTAssertEqual(error as? FeedbackError, .attachmentTooLarge)
        }
    }

    func testCustomMaximumBytesRespected() async throws {
        let source = try ImageTestFactory.solidJPEGData(width: 800, height: 600)
        let configuration = AttachmentConfiguration(maximumAttachmentBytes: 50_000)
        let attachment = try await optimizer.optimize(data: source, configuration: configuration)

        XCTAssertLessThanOrEqual(attachment.byteCount, 50_000)
    }

    private func makeImageSource(from data: Data) -> CGImageSource? {
        CGImageSourceCreateWithData(data as CFData, nil)
    }

    private func imageProperties(from data: Data) -> [String: Any]? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }
        return CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any]
    }
}

    private extension XCTestCase {
    func XCTAssertThrowsErrorAsync<T>(
        _ expression: @escaping () async throws -> T,
        errorHandler: @escaping (Error) -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        do {
            _ = try await expression()
            XCTFail("Expected error to be thrown", file: file, line: line)
        } catch {
            errorHandler(error)
        }
    }
}
