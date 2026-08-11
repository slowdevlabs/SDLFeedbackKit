import XCTest

@testable import SDLFeedbackKit

final class AttachmentPickerImageTypeResolverTests: XCTestCase {
    func testResolvesPublicPNGBeforePrivateThumbnail() {
        let resolution = AttachmentPickerImageTypeResolver.resolvePreferredImageType(
            from: [
                "public.png",
                "com.apple.private.photos.thumbnail.standard"
            ],
            hasImageConformance: true
        )

        XCTAssertEqual(resolution?.identifier, "public.png")
        XCTAssertEqual(resolution?.usedGenericFallback, false)
    }

    func testPrefersHeicOverJpegWhenBothAreAvailable() {
        let resolution = AttachmentPickerImageTypeResolver.resolvePreferredImageType(
            from: [
                "public.jpeg",
                "public.heic",
                "com.apple.private.photos.thumbnail.low"
            ],
            hasImageConformance: true
        )

        XCTAssertEqual(resolution?.identifier, "public.heic")
        XCTAssertEqual(resolution?.usedGenericFallback, false)
    }

    func testResolvesHeicWhenItAppearsFirst() {
        let resolution = AttachmentPickerImageTypeResolver.resolvePreferredImageType(
            from: [
                "public.heic",
                "public.jpeg"
            ],
            hasImageConformance: true
        )

        XCTAssertEqual(resolution?.identifier, "public.heic")
        XCTAssertEqual(resolution?.usedGenericFallback, false)
    }

    func testPrefersHeifWhenHeicIsAbsent() {
        let resolution = AttachmentPickerImageTypeResolver.resolvePreferredImageType(
            from: [
                "public.jpeg",
                "public.heif"
            ],
            hasImageConformance: true
        )

        XCTAssertEqual(resolution?.identifier, "public.heif")
        XCTAssertEqual(resolution?.usedGenericFallback, false)
    }

    func testFallsBackToGenericImageWhenNoConcreteTypeExists() {
        let resolution = AttachmentPickerImageTypeResolver.resolvePreferredImageType(
            from: [
                "com.apple.private.photos.thumbnail.standard",
                "com.apple.private.photos.thumbnail.low"
            ],
            hasImageConformance: true
        )

        XCTAssertEqual(resolution?.identifier, "public.image")
        XCTAssertEqual(resolution?.usedGenericFallback, true)
    }

    func testReturnsNilWhenNoImageConformanceExists() {
        let resolution = AttachmentPickerImageTypeResolver.resolvePreferredImageType(
            from: [
                "com.apple.private.photos.thumbnail.standard",
                "com.apple.private.photos.thumbnail.low"
            ],
            hasImageConformance: false
        )

        XCTAssertNil(resolution)
    }

    func testJPEGOnlyAssetStillResolvesJPEG() {
        let resolution = AttachmentPickerImageTypeResolver.resolvePreferredImageType(
            from: [
                "public.jpeg"
            ],
            hasImageConformance: true
        )

        XCTAssertEqual(resolution?.identifier, "public.jpeg")
        XCTAssertEqual(resolution?.usedGenericFallback, false)
    }

    func testPrefersHeicOverPrivateThumbnailAndJPEG() {
        let resolution = AttachmentPickerImageTypeResolver.resolvePreferredImageType(
            from: [
                "com.apple.private.photos.thumbnail.standard",
                "public.jpeg",
                "public.heic"
            ],
            hasImageConformance: true
        )

        XCTAssertEqual(resolution?.identifier, "public.heic")
        XCTAssertEqual(resolution?.usedGenericFallback, false)
    }

    func testPrivateThumbnailsAndGenericImageAreNotConcreteCandidates() {
        XCTAssertFalse(AttachmentPickerImageTypeResolver.isPreferredConcreteImageTypeIdentifier("public.image"))
        XCTAssertFalse(AttachmentPickerImageTypeResolver.isPreferredConcreteImageTypeIdentifier("com.apple.private.photos.thumbnail.standard"))
        XCTAssertFalse(AttachmentPickerImageTypeResolver.isPreferredConcreteImageTypeIdentifier("com.apple.private.photos.thumbnail.low"))
    }
}
