SDLFeedbackKit

Lightweight, backend-agnostic SwiftUI feedback package for iOS and macOS.

SDLFeedbackKit provides the feedback form UI, payload model, attachment pipeline, localization, and a transport contract. Your app owns presentation, and your backend owns submission handling.

Status

Early release / v0.1.0

Highlights

SwiftUI feedback form

Custom feedback categories

Message and optional email fields

Single image attachment

Automatic image optimization and metadata reduction

1,000,000-byte default final attachment limit

Backend-independent FeedbackTransport

Native attachment pickers for iOS and macOS

English, Korean, and Spanish localization

No external dependencies

Requirements

Swift 5.9+

iOS 13.0+

macOS 10.15+

Swift Package Manager

Installation

Add SDLFeedbackKit in Xcode using the package repository URL:

https://github.com/slowdevlabs/SDLFeedbackKit

Select version 0.1.0 or later within the 0.1.x series.

When working inside this repository, the example apps use the local package checkout.

Quick Start

import SDLFeedbackKit
import SwiftUI

struct SettingsView: View {
    @State private var showingFeedback = false

    var body: some View {
        Button("Send Feedback") {
            showingFeedback = true
        }
        .sheet(isPresented: $showingFeedback) {
            FeedbackFormView(
                context: FeedbackContext(
                    appID: "my-app",
                    appName: "My App"
                ),
                transport: MyFeedbackTransport(),
                onSubmitted: { _ in
                    showingFeedback = false
                },
                onCancelled: {
                    showingFeedback = false
                }
            )
        }
    }
}

Custom Transport

Implement FeedbackTransport in your app or networking module:

struct MyFeedbackTransport: FeedbackTransport {
    func submit(_ payload: FeedbackPayload) async throws -> FeedbackSubmissionReceipt {
        // Send the payload to your own backend.
        return FeedbackSubmissionReceipt(
            serverID: "feedback-123",
            acceptedAt: Date()
        )
    }
}

SDLFeedbackKit does not include a hosted backend or a built-in network transport. The example apps use a mock transport and do not persist submitted feedback.

Presenting the Form

FeedbackFormView does not own presentation. Host apps can present it using a sheet, window, or another container.

The recommended pattern is to close the host presentation from onSubmitted and onCancelled.

Configuration

FeedbackConfiguration supports:

categories

email field settings

attachment settings

message settings

cancel button visibility

The default attachment policy is:

final optimized attachment limit: 1,000,000 bytes

long edge: 1,800 px

initial JPEG quality: 0.8

Attachments

SDLFeedbackKit accepts a single image attachment and normalizes it before submission.

Images are resized and re-encoded by the package

Metadata is reduced during re-encoding

The default final output format is JPEG

FeedbackAttachment is the final optimized value passed to FeedbackTransport

The default final attachment size is limited to 1,000,000 bytes

Supported input formats depend on the Apple platform decoder. JPEG and PNG are common cases; HEIC/HEIF support depends on the host OS.

Localization

SDLFeedbackKit includes .strings resources for:

English

Korean

Spanish

English is the base language, and package localization is loaded through Bundle.module.

Built-in category titles are localized by SDLFeedbackKit. Custom category titles are provided by the host app, so the host is responsible for localizing them when needed.

Privacy and Security

SDLFeedbackKit does not include a backend

Client-side feedback data is untrusted and should be validated again by your backend

Do not embed backend secrets in the app binary

The package does not collect persistent device identifiers

The package does not collect precise location

Selected images are re-encoded to reduce metadata and size

The package only processes the image selected by the user; it does not scan the photo library

Your backend is responsible for authentication, rate limiting, abuse prevention, storage, and retention policies

Examples

Example host apps are included in:

Examples/iOSExample

Examples/macOSExample

They demonstrate host-owned presentation, FeedbackTransport integration, success/failure flows, and attachment handling using a mock transport.

What SDLFeedbackKit Does Not Provide

No built-in backend

No built-in network transport implementation

No multiple attachments

No camera capture

No drag-and-drop attachment pipeline

No pasteboard attachment support

No custom theming system

License

MIT. See LICENSE.