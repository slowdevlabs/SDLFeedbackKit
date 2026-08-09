# SDLFeedbackKit

**A lightweight, backend-agnostic feedback form for SwiftUI on iOS and macOS.**

![Swift](https://img.shields.io/badge/Swift-5.9+-F05138)
![iOS](https://img.shields.io/badge/iOS-13.0+-000000)
![macOS](https://img.shields.io/badge/macOS-10.15+-000000)
![License](https://img.shields.io/badge/License-MIT-4C8BF5)

SDLFeedbackKit provides a reusable feedback form, payload model, image attachment pipeline, localization, and a transport contract. Your app owns presentation, while your backend owns submission and storage.

> [!NOTE]
> SDLFeedbackKit does **not** include a hosted backend or built-in network transport.  
> Connect it to your own backend by implementing `FeedbackTransport`.

| | |
|---|---|
| **Platforms** | iOS 13+ · macOS 10.15+ |
| **Swift** | 5.9+ |
| **Localization** | English · Korean · Spanish |
| **Attachments** | 1 image · JPEG output · max 1,000,000 bytes by default |
| **Dependencies** | None |
| **Backend** | Bring your own `FeedbackTransport` |

---

## Features

- SwiftUI feedback form
- Custom feedback categories
- Message and optional email fields
- Single image attachment
- Automatic image resizing, JPEG re-encoding, and metadata reduction
- Default final attachment limit of `1,000,000` bytes
- Backend-independent `FeedbackTransport`
- Native attachment pickers for iOS and macOS
- English, Korean, and Spanish localization
- Host-owned presentation and dismissal
- No external dependencies

---

## Requirements

- Swift 5.9+
- iOS 13.0+
- macOS 10.15+
- Swift Package Manager

---

## Installation

Add SDLFeedbackKit in Xcode using:

```text
https://github.com/slowdevlabs/SDLFeedbackKit
```

Choose version `0.1.0` or later within the `0.1.x` series.

When working inside this repository, the example apps use the local package checkout.

---

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

`FeedbackFormView` does not dismiss itself. The host app owns presentation and decides what to do in `onSubmitted` and `onCancelled`.

---

## Custom Transport

Implement `FeedbackTransport` in your app or networking module:

```swift
struct MyFeedbackTransport: FeedbackTransport {
    func submit(
        _ payload: FeedbackPayload
    ) async throws -> FeedbackSubmissionReceipt {
        // Send the payload to your own backend.

        return FeedbackSubmissionReceipt(
            serverID: "feedback-123",
            acceptedAt: Date()
        )
    }
}
```

> [!IMPORTANT]
> Treat feedback payloads as untrusted input. Your backend should validate requests, apply rate limits, and enforce its own storage and retention policies.

The included example apps use a mock transport. Submitted feedback from the examples is **not persisted to a real backend**.

---

## Configuration

`FeedbackConfiguration` supports:

- categories
- email field settings
- attachment settings
- message settings
- cancel button visibility

### Default attachment policy

| Setting | Default |
|---|---:|
| Final optimized size | `1,000,000` bytes |
| Long edge | `1,800` px |
| Initial JPEG quality | `0.8` |

---

## Attachments

SDLFeedbackKit accepts a single image attachment and normalizes it before submission.

The attachment pipeline:

```text
Selected image
    ↓
Decode / downsample
    ↓
Orientation handling
    ↓
JPEG re-encoding
    ↓
Metadata reduction
    ↓
FeedbackAttachment
    ↓
FeedbackTransport
```

The final attachment:

- uses JPEG output
- is limited to `1,000,000` bytes by default
- reports its final pixel dimensions and byte count
- uses the normalized filename `feedback.jpg`
- does not expose the original source path through `FeedbackAttachment`

Supported input formats depend on Apple platform decoding support. JPEG and PNG are common cases; HEIC/HEIF support depends on the host OS.

---

## Localization

SDLFeedbackKit includes `.strings` resources for:

- English
- Korean
- Spanish

English is the base language, and package localization is loaded through `Bundle.module`.

Built-in category titles are localized by SDLFeedbackKit.

> [!TIP]
> Custom category titles are provided by the host app, so the host is responsible for localizing them when needed.

---

## Privacy & Security

SDLFeedbackKit is designed to keep backend and privacy policy decisions in the host application.

- No hosted backend is included
- No persistent device identifier is collected by the package
- No precise location is collected by the package
- The package processes only the image selected by the user
- Selected images are re-encoded to reduce metadata and file size
- Backend secrets should never be embedded in the app binary
- Server-side validation and abuse prevention remain the backend's responsibility

---

## Examples

Example host apps are included for both supported platforms:

```text
Examples/
├── iOSExample/
└── macOSExample/
```

They demonstrate:

- presenting `FeedbackFormView`
- host-owned dismissal
- implementing `FeedbackTransport`
- success and failure flows
- image attachment handling

The examples intentionally use a mock transport rather than a production backend.

---

## What SDLFeedbackKit Does Not Provide

SDLFeedbackKit intentionally keeps its scope small.

- No built-in backend
- No built-in network transport implementation
- No multiple attachments
- No camera capture
- No drag-and-drop attachment pipeline
- No pasteboard attachment support
- No custom theming system

---

## Status

**Early release — 0.1.x**

The package is ready for integration, but the public API may continue to evolve during the `0.x` series.

---

## License

SDLFeedbackKit is available under the MIT License. See [LICENSE](LICENSE).
