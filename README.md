# SDLFeedbackKit

Lightweight backend-agnostic SwiftUI feedback package for iOS and macOS.

SDLFeedbackKit is designed for self-hosted feedback backends. It provides the form UI, payload model, attachment pipeline, localization, and a transport contract. Your app owns presentation and your backend owns submission handling.

## Status

Early release / v0.1

## Highlights

- SwiftUI feedback form
- Custom feedback categories
- Message and optional email fields
- Single image attachment
- Automatic image optimization and metadata reduction
- 1,000,000 byte default final attachment limit
- Backend-independent `FeedbackTransport`
- Native attachment pickers for iOS and macOS
- EN / KO / ES localization

## Requirements

- Swift 5.9+
- iOS 13.0+
- macOS 10.15+
- Swift Package Manager
- No external dependencies

## Installation

Add the package in Xcode with the local repository URL:

```text
https://github.com/slowdevlabs/SDLFeedbackKit
```

Or add the local checkout as a Swift Package dependency when working inside this repository.

## Quick Start

```swift
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
```

## Custom Transport

Implement `FeedbackTransport` in your app or backend module:

```swift
struct MyFeedbackTransport: FeedbackTransport {
    func submit(_ payload: FeedbackPayload) async throws -> FeedbackSubmissionReceipt {
        // Send payload to your own backend.
        return FeedbackSubmissionReceipt(
            serverID: "feedback-123",
            acceptedAt: Date()
        )
    }
}
```

## Presenting the Form

`FeedbackFormView` does not own presentation. Host apps present it via sheet, window, or any other container they choose.

The recommended pattern is to close the host presentation from `onSubmitted` and `onCancelled`.

## Configuration

`FeedbackConfiguration` currently supports:

- categories
- email field
- attachment settings
- message settings
- cancel button visibility

The default attachment policy is:

- final optimized attachment limit: `1,000,000` bytes
- long edge: `1,800` px
- initial JPEG quality: `0.8`

## Attachments

SDLFeedbackKit accepts a single image attachment and normalizes it before submission.

- Images are resized and re-encoded by the package
- Metadata is reduced during re-encoding
- The default final output format is JPEG
- `FeedbackAttachment` is the final optimized value passed through the transport boundary

Supported input formats depend on the Apple platform decoder. JPEG and PNG are the common cases; HEIC/HEIF support depends on the host OS.

## Localization

The package ships `.strings` resources in:

- English
- Korean
- Spanish

Base language is English and the package uses `Bundle.module` for lookup.

## Privacy and Security

- The package does not include a backend
- Client-side data is untrusted and must be revalidated on the server
- Do not embed secrets in the app binary
- Selected images are re-encoded to reduce metadata and size
- The package does not scan the photo library

See [docs/SECURITY.md](docs/SECURITY.md) for the full security model.

## Examples

Example host apps are included in:

- `Examples/iOSExample`
- `Examples/macOSExample`

They use a mock transport and demonstrate how to present `FeedbackFormView` from a host-owned sheet or window.

## What SDLFeedbackKit Does Not Provide

- No built-in backend
- No network transport implementation
- No multiple attachments
- No camera capture
- No drag and drop pipeline
- No pasteboard attachment support
- No custom theming system

## Documentation

- [docs/PROJECT_BRIEF.md](docs/PROJECT_BRIEF.md)
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- [docs/API_SPEC.md](docs/API_SPEC.md)
- [docs/INTEGRATION_GUIDE.md](docs/INTEGRATION_GUIDE.md)
- [docs/ATTACHMENT_SPEC.md](docs/ATTACHMENT_SPEC.md)
- [docs/SECURITY.md](docs/SECURITY.md)

## License

MIT. See [LICENSE](LICENSE).
