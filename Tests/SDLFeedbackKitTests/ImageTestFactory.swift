import CoreGraphics
import Foundation
import ImageIO

enum ImageTestFactory {
    static func solidJPEGData(
        width: Int,
        height: Int,
        quality: Double = 0.95,
        orientation: CGImagePropertyOrientation? = nil,
        includeMetadata: Bool = false
    ) throws -> Data {
        let image = try makeImage(width: width, height: height) { _, _ in
            (220, 180, 140, 255)
        }

        return try encode(
            image: image,
            uti: "public.jpeg",
            quality: quality,
            properties: makeSourceProperties(
                width: width,
                height: height,
                orientation: orientation,
                includeMetadata: includeMetadata
            )
        )
    }

    static func noisyJPEGData(
        width: Int,
        height: Int,
        quality: Double = 0.95,
        orientation: CGImagePropertyOrientation? = nil,
        includeMetadata: Bool = false
    ) throws -> Data {
        let image = try makeImage(width: width, height: height) { x, y in
            var seed = UInt32(truncatingIfNeeded: x &* 73856093 ^ y &* 19349663 ^ 0x9E3779B9)
            seed ^= seed << 13
            seed ^= seed >> 17
            seed ^= seed << 5

            let r = UInt8(truncatingIfNeeded: seed & 0xFF)
            let g = UInt8(truncatingIfNeeded: (seed >> 8) & 0xFF)
            let b = UInt8(truncatingIfNeeded: (seed >> 16) & 0xFF)
            return (r, g, b, 255)
        }

        return try encode(
            image: image,
            uti: "public.jpeg",
            quality: quality,
            properties: makeSourceProperties(
                width: width,
                height: height,
                orientation: orientation,
                includeMetadata: includeMetadata
            )
        )
    }

    static func transparentPNGData(width: Int, height: Int) throws -> Data {
        let image = try makeImage(width: width, height: height) { x, y in
            let isTransparent = (x + y).isMultiple(of: 2)
            if isTransparent {
                return (0, 140, 255, 0)
            } else {
                return (0, 140, 255, 180)
            }
        }

        return try encode(image: image, uti: "public.png", quality: nil, properties: [:])
    }

    private static func makeImage(
        width: Int,
        height: Int,
        pixelProvider: (Int, Int) -> (UInt8, UInt8, UInt8, UInt8)
    ) throws -> CGImage {
        var pixels = [UInt8](repeating: 0, count: width * height * 4)

        for y in 0..<height {
            for x in 0..<width {
                let (r, g, b, a) = pixelProvider(x, y)
                let index = ((y * width) + x) * 4
                pixels[index] = r
                pixels[index + 1] = g
                pixels[index + 2] = b
                pixels[index + 3] = a
            }
        }

        return try pixels.withUnsafeMutableBytes { buffer in
            guard let context = CGContext(
                data: buffer.baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGBitmapInfo.byteOrder32Big.rawValue
                    | CGImageAlphaInfo.premultipliedLast.rawValue
            ) else {
                throw NSError(domain: "ImageTestFactory", code: 1, userInfo: nil)
            }

            guard let image = context.makeImage() else {
                throw NSError(domain: "ImageTestFactory", code: 2, userInfo: nil)
            }

            return image
        }
    }

    private static func encode(
        image: CGImage,
        uti: String,
        quality: Double?,
        properties: [CFString: Any]
    ) throws -> Data {
        let outputData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            outputData,
            uti as CFString,
            1,
            nil
        ) else {
            throw NSError(domain: "ImageTestFactory", code: 3, userInfo: nil)
        }

        var finalProperties = properties
        if let quality {
            finalProperties[kCGImageDestinationLossyCompressionQuality] = quality
        }

        CGImageDestinationAddImage(destination, image, finalProperties as CFDictionary)
        guard CGImageDestinationFinalize(destination) else {
            throw NSError(domain: "ImageTestFactory", code: 4, userInfo: nil)
        }

        return outputData as Data
    }

    private static func makeSourceProperties(
        width: Int,
        height: Int,
        orientation: CGImagePropertyOrientation?,
        includeMetadata: Bool
    ) -> [CFString: Any] {
        var properties: [CFString: Any] = [:]

        if let orientation {
            properties[kCGImagePropertyOrientation] = NSNumber(value: orientation.rawValue)
        }

        guard includeMetadata else {
            return properties
        }

        properties[kCGImagePropertyGPSDictionary] = [
            kCGImagePropertyGPSLatitude: 37.7749,
            kCGImagePropertyGPSLatitudeRef: "N",
            kCGImagePropertyGPSLongitude: 122.4194,
            kCGImagePropertyGPSLongitudeRef: "W"
        ]
        properties[kCGImagePropertyExifDictionary] = [
            kCGImagePropertyExifUserComment: "synthetic-fixture",
            kCGImagePropertyExifPixelXDimension: NSNumber(value: width),
            kCGImagePropertyExifPixelYDimension: NSNumber(value: height)
        ]

        return properties
    }
}
