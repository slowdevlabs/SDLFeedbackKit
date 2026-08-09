# SDLFeedbackKit — Integration Guide

## 1. Document Purpose

이 문서는 `SDLFeedbackKit`을 iOS 및 macOS 앱에 통합하는 방법을 설명한다.

대상 독자는 다음과 같다.

* iOS 개발자
* macOS 개발자
* SwiftUI 앱 개발자
* 자신의 Backend를 운영하는 개발자
* SDLFeedbackKit을 Self-hosted 환경에 연결하려는 개발자

이 문서에서는 다음 흐름을 다룬다.

```text
Install package
→ Create FeedbackContext
→ Implement FeedbackTransport
→ Present FeedbackFormView
→ Connect to self-hosted backend
```

SDLFeedbackKit은 Backend를 포함하지 않는다.

각 개발자는 자신의 서버 환경에 맞는 `FeedbackTransport`를 직접 구현해야 한다.

---

# 2. Requirements

SDLFeedbackKit은 다음 환경을 대상으로 한다.

```text
Swift
SwiftUI
Swift Package Manager
iOS
macOS
```

정확한 Minimum Deployment Target과 Swift Version은 `Package.swift`에서 정의한다.

---

# 3. Installation

## 3.1 Swift Package Manager

Xcode에서:

```text
File
→ Add Package Dependencies
```

를 선택한다.

SDLFeedbackKit GitHub Repository URL을 입력한다.

예:

```text
https://github.com/slowdevlabs/SDLFeedbackKit
```

원하는 Version Rule을 선택한다.

예:

```text
Up to Next Major Version
```

초기 `0.x` 단계에서는 프로젝트 정책에 맞게 정확한 버전을 고정하는 것도 권장한다.

---

# 4. Import

사용할 Swift 파일에서:

```swift
import SDLFeedbackKit
```

을 추가한다.

---

# 4.1 iOS 13 Legacy Picker Note

`SDLFeedbackKit`의 iOS 13 photo library fallback은 호스트 앱의 환경에 따라 `NSPhotoLibraryUsageDescription`이 필요할 수 있다.

`PHPickerViewController`를 사용하는 iOS 14+ 경로에서는 전체 photo library 권한을 선제적으로 요청하지 않는다.

---

# 5. Integration Overview

SDLFeedbackKit을 앱에 연결하려면 최소 두 가지가 필요하다.

```text
FeedbackContext
FeedbackTransport
```

그리고 이를 `FeedbackFormView`에 전달한다.

전체 구조:

```text
Host App
   │
   ├─ FeedbackContext
   │
   └─ FeedbackTransport
            │
            ▼
     FeedbackFormView
            │
            ▼
      FeedbackPayload
            │
            ▼
     Self-hosted Backend
```

---

# 6. Create FeedbackContext

`FeedbackContext`는 어느 앱에서 Feedback이 발생했는지 SDLFeedbackKit에 알려준다.

기본 예:

```swift
let feedbackContext = FeedbackContext(
    appID: "my-app",
    appName: "My App"
)
```

---

# 7. appID

`appID`는 Backend에서 앱을 구분하는 안정적인 Identifier다.

예:

```text
my-app
my-ios-app
com.example.myapp
```

앱 Display Name이 변경되더라도 가능하면 `appID`는 유지하는 것을 권장한다.

---

# 8. appName

`appName`은 사람이 읽을 수 있는 앱 이름이다.

예:

```swift
FeedbackContext(
    appID: "my-app",
    appName: "My App"
)
```

`appName`은 Backend Dashboard 등에 표시할 수 있다.

---

# 9. Add Custom Metadata

특정 앱에서 추가 Context가 필요한 경우 `metadata`를 사용한다.

예:

```swift
let feedbackContext = FeedbackContext(
    appID: "my-app",
    appName: "My App",
    metadata: [
        "screen": "settings",
        "datasetVersion": "2.1.0"
    ]
)
```

SDLFeedbackKit은 Metadata의 의미를 해석하지 않는다.

---

# 10. Metadata Guidelines

Metadata에는 디버깅에 필요한 앱별 Context만 넣는 것을 권장한다.

좋은 예:

```text
screen
feature
datasetVersion
documentType
mode
```

피해야 할 예:

```text
password
accessToken
refreshToken
privateAPIKey
fullAddress
paymentData
```

Metadata는 Client에서 전송되는 값이므로 Server에서 신뢰하면 안 된다.

---

# 11. Implement FeedbackTransport

SDLFeedbackKit은 Backend를 직접 호출하지 않는다.

개발자가 `FeedbackTransport`를 구현한다.

기본 Protocol:

```swift
public protocol FeedbackTransport: Sendable {
    func submit(
        _ payload: FeedbackPayload
    ) async throws -> FeedbackSubmissionReceipt
}
```

---

# 12. Minimal Transport

가장 단순한 형태:

```swift
struct MyFeedbackTransport: FeedbackTransport {

    func submit(
        _ payload: FeedbackPayload
    ) async throws -> FeedbackSubmissionReceipt {

        try await sendToBackend(payload)

        return FeedbackSubmissionReceipt()
    }
}
```

---

# 13. Transport Responsibilities

Transport는 다음을 담당한다.

```text
Serialization
HTTP request
Authentication if required
Attachment upload
Backend-specific headers
Response parsing
Error handling
```

SDLFeedbackKit은 이 부분을 강제하지 않는다.

---

# 14. JSON-only Backend Example

Attachment를 사용하지 않는 Backend라면 JSON Request로 단순하게 구현할 수 있다.

개념 예:

```swift
struct MyFeedbackTransport: FeedbackTransport {

    let endpoint: URL

    func submit(
        _ payload: FeedbackPayload
    ) async throws -> FeedbackSubmissionReceipt {

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )

        let body = FeedbackRequest(
            clientID: payload.clientID.uuidString,
            appID: payload.appID,
            appName: payload.appName,
            appVersion: payload.appVersion,
            buildNumber: payload.buildNumber,
            platform: payload.platform.rawValue,
            osVersion: payload.osVersion,
            locale: payload.localeIdentifier,
            categoryID: payload.category.id,
            categoryTitle: payload.category.title,
            message: payload.message,
            email: payload.email,
            metadata: payload.metadata,
            createdAt: payload.createdAt
        )

        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(
            for: request
        )

        try validate(response)

        return FeedbackSubmissionReceipt()
    }
}
```

이 코드는 개념 예제다.

실제 Backend Contract에 맞게 Request Model을 정의해야 한다.

---

# 15. Attachment Transport

Attachment가 활성화되어 있다면 `payload.attachment`를 확인한다.

```swift
if let attachment = payload.attachment {
    // Upload attachment
}
```

Attachment에는 이미 SDLFeedbackKit에서 최적화된 이미지 데이터가 들어 있다.

---

# 16. Attachment Properties

Transport에서 사용할 수 있는 정보:

```swift
attachment.data
attachment.filename
attachment.mimeType
attachment.byteCount
attachment.pixelWidth
attachment.pixelHeight
```

기본 Attachment는 최대 약:

```text
1 MB
```

를 목표로 최적화된다.

---

# 17. Recommended Multipart Pattern

일반적인 REST Backend에서는 다음 구조를 사용할 수 있다.

```text
POST /v1/feedback

multipart/form-data

Part 1
payload
application/json

Part 2
attachment
image/jpeg
```

단, SDLFeedbackKit은 Multipart 형식을 강제하지 않는다.

---

# 18. Alternative Upload Patterns

Backend에 따라 다음 방식도 사용할 수 있다.

```text
JSON only
Multipart
Presigned upload
Direct storage upload
Two-step upload
GraphQL
Backend SDK
```

Transport가 Backend 차이를 흡수한다.

---

# 19. Present FeedbackFormView

가장 기본적인 사용:

```swift
FeedbackFormView(
    context: feedbackContext,
    transport: MyFeedbackTransport()
)
```

---

# 20. Present as Sheet

일반적인 SwiftUI 예:

```swift
struct SettingsView: View {

    @State private var showsFeedback = false

    var body: some View {
        Button("Send Feedback") {
            showsFeedback = true
        }
        .sheet(isPresented: $showsFeedback) {
            FeedbackFormView(
                context: FeedbackContext(
                    appID: "my-app",
                    appName: "My App"
                ),
                transport: MyFeedbackTransport()
            )
        }
    }
}
```

---

# 21. Handle Submission

전송 성공 후 Host App에서 Sheet를 닫고 싶다면:

```swift
.sheet(isPresented: $showsFeedback) {

    FeedbackFormView(
        context: feedbackContext,
        transport: transport,
        onSubmitted: { result in
            showsFeedback = false
        }
    )
}
```

---

# 22. Handle Cancellation

```swift
FeedbackFormView(
    context: feedbackContext,
    transport: transport,
    onCancelled: {
        showsFeedback = false
    }
)
```

Presentation lifecycle은 Host App이 소유한다.

---

# 23. NavigationStack

`FeedbackFormView`는 Sheet에 종속되지 않는다.

예:

```swift
NavigationLink("Send Feedback") {
    FeedbackFormView(
        context: feedbackContext,
        transport: transport
    )
}
```

---

# 24. macOS Integration

macOS에서도 동일한 Public API를 사용한다.

예:

```swift
.sheet(isPresented: $showsFeedback) {
    FeedbackFormView(
        context: feedbackContext,
        transport: transport
    )
}
```

Attachment Picker 차이는 SDLFeedbackKit 내부에서 처리한다.

기본 방향:

```text
iOS
→ PHPickerViewController / UIImagePickerController fallback

macOS
→ NSOpenPanel
```

Host App은 별도의 플랫폼 분기 코드를 작성할 필요가 없다.

---

# 25. Default Feedback Categories

기본 Configuration에서는 다음 Category를 제공한다.

```text
General Feedback
Bug Report
Feature Request
Other
```

---

# 26. Custom Categories

앱에 맞는 Category를 정의할 수 있다.

```swift
let categories = [
    FeedbackCategory(
        id: "bug",
        title: "Bug"
    ),
    FeedbackCategory(
        id: "content",
        title: "Content Issue"
    ),
    FeedbackCategory(
        id: "translation",
        title: "Translation Issue"
    )
]
```

Configuration:

```swift
let configuration = FeedbackConfiguration(
    categories: categories
)
```

그리고:

```swift
FeedbackFormView(
    context: feedbackContext,
    transport: transport,
    configuration: configuration
)
```

---

# 27. Disable Email

Email이 필요하지 않은 앱에서는 비활성화할 수 있다.

```swift
let configuration = FeedbackConfiguration(
    emailField: EmailFieldConfiguration(
        isEnabled: false
    )
)
```

---

# 28. Require Email

필요한 경우:

```swift
let configuration = FeedbackConfiguration(
    emailField: EmailFieldConfiguration(
        isEnabled: true,
        isRequired: true
    )
)
```

다만 일반적인 Feedback Flow에서는 Email을 Optional로 유지하는 것을 권장한다.

---

# 29. Disable Attachment

이미지 첨부가 필요하지 않다면:

```swift
let configuration = FeedbackConfiguration(
    attachment: AttachmentConfiguration(
        isEnabled: false
    )
)
```

---

# 30. Default Attachment Policy

SDLFeedbackKit v0.1의 기본 Attachment 정책:

```text
Maximum images
1

Initial long edge
1800 px

Output format
JPEG

Initial JPEG quality
0.80

Maximum final attachment size
1,000,000 bytes
```

---

# 31. Oversized Attachment

이미지 처리 후 1MB를 초과하면 SDLFeedbackKit이 자동으로 재압축한다.

기본 흐름:

```text
1800px
↓
JPEG 0.80
↓
0.70
↓
0.60
↓
0.50
```

그래도 1MB를 초과하면:

```text
1440px
↓
1200px
↓
1000px
```

순으로 필요한 경우에만 추가 축소한다.

최종적으로도 제한을 만족하지 못하면 Attachment만 실패 처리한다.

사용자는 이미지를 제거하고 Text Feedback만 전송할 수 있다.

---

# 32. Custom Attachment Limit

개발자가 더 작은 제한을 원한다면:

```swift
let configuration = FeedbackConfiguration(
    attachment: AttachmentConfiguration(
        isEnabled: true,
        maximumAttachmentBytes: 750_000,
        maximumImageDimension: 1_600,
        compressionQuality: 0.75
    )
)
```

처럼 설정할 수 있다.

재압축 알고리즘은 설정된 최대 Byte Size를 목표로 동작한다.

---

# 33. Message Configuration

Message 기본 정책:

```text
Required
Maximum 5,000 characters
```

필요한 경우:

```swift
let configuration = FeedbackConfiguration(
    message: MessageConfiguration(
        minimumLength: 10,
        maximumLength: 2_000,
        isRequired: true
    )
)
```

처럼 조정할 수 있다.

---

# 34. Full Configuration Example

```swift
let configuration = FeedbackConfiguration(
    categories: [
        .general,
        .bug,
        .featureRequest,
        .other
    ],
    emailField: EmailFieldConfiguration(
        isEnabled: true,
        isRequired: false
    ),
    attachment: AttachmentConfiguration(
        isEnabled: true,
        maximumAttachmentBytes: 1_000_000,
        maximumImageDimension: 1_800,
        compressionQuality: 0.8
    ),
    message: MessageConfiguration(
        minimumLength: 1,
        maximumLength: 5_000,
        isRequired: true
    ),
    showsCancelButton: true
)
```

---

# 35. Recommended Basic Integration

대부분의 앱에서는 Configuration을 따로 만들 필요가 없다.

권장:

```swift
FeedbackFormView(
    context: FeedbackContext(
        appID: "my-app",
        appName: "My App"
    ),
    transport: MyFeedbackTransport()
)
```

Default를 우선 사용하고 실제 요구가 있는 경우에만 Configuration을 변경한다.

---

# 36. Self-hosted Backend

SDLFeedbackKit은 Feedback Backend를 제공하지 않는다.

개발자는 자신의 환경을 준비한다.

예:

```text
Cloudflare Workers
Supabase
Firebase
AWS
Vapor
Node.js
PHP
Custom Server
```

---

# 37. Example Architecture — Cloudflare

예:

```text
App
 ↓
SDLFeedbackKit
 ↓
CloudflareFeedbackTransport
 ↓
Cloudflare Worker
 ↓
D1
 +
R2
```

권장 역할:

```text
D1
→ Feedback metadata

R2
→ Attachment binary
```

---

# 38. Example Backend Flow

개념:

```text
POST /v1/feedback
       ↓
Validate request
       ↓
Generate server feedback ID
       ↓
Attachment exists?
       │
       ├─ Yes
       │   ↓
       │ Validate image
       │   ↓
       │ Store in object storage
       │
       └─ No
       ↓
Store feedback metadata
       ↓
Return success receipt
```

---

# 39. Suggested Backend Response

Backend는 필요하면 다음 정보를 반환할 수 있다.

```json
{
  "id": "fb_01ABCXYZ",
  "acceptedAt": "2026-08-08T03:00:00Z"
}
```

Transport는 이를:

```swift
FeedbackSubmissionReceipt(
    serverID: response.id,
    acceptedAt: response.acceptedAt
)
```

로 변환한다.

---

# 40. Empty Receipt

Backend에서 별도 정보를 반환하지 않아도 된다.

```swift
return FeedbackSubmissionReceipt()
```

이면 충분하다.

---

# 41. Backend Validation

SDLFeedbackKit에서 Validation이 이미 수행되더라도 Server가 다시 검증해야 한다.

반드시 다음을 신뢰하지 않는다.

```text
appID
appVersion
platform
message
email
metadata
attachment size
mime type
filename
clientID
createdAt
```

---

# 42. Recommended Backend Limits

SDLFeedbackKit 기본값 기준 권장:

```text
Message
≤ 5,000 characters

Email
≤ 320 characters

Metadata entries
≤ 32

Metadata key
≤ 64 characters

Metadata value
≤ 1,000 characters

Attachment
≤ 1,000,000 bytes
```

전체 Request는 multipart overhead 등을 고려하여 별도 상한을 설정한다.

---

# 43. Server Request Size

1MB Attachment 기준으로 초기 Backend Request limit은 대략:

```text
2 MB ~ 3 MB
```

범위를 검토할 수 있다.

실제 환경에 따라 더 작거나 크게 설정할 수 있다.

---

# 44. Rate Limiting

Feedback Endpoint는 Public Endpoint라고 가정한다.

Backend에서 Rate Limit을 적용한다.

예:

```text
IP
Time window
appID
other abuse signals
```

Client의 appID나 clientID 하나만으로 Rate Limit을 신뢰하지 않는다.

---

# 45. API Keys

앱 안에 Secret API Key를 넣어 Feedback Endpoint를 보호하지 않는다.

다음 방식은 보안 수단이 아니다.

```swift
let secret = "hard-coded-secret"
```

앱 Binary에서 추출될 수 있기 때문이다.

---

# 46. Endpoint URL

Endpoint URL은 공개되어도 안전한 구조로 Backend를 설계한다.

예:

```text
https://feedback.example.com/v1/feedback
```

URL을 숨기는 것으로 보안을 확보하지 않는다.

---

# 47. HTTPS

Production Backend는 HTTPS만 사용한다.

Transport에서 일반 `URLSession`의 정상적인 TLS 검증을 유지한다.

---

# 48. Admin APIs

Feedback Submission API와 관리자 API를 분리한다.

예:

```text
Public:
POST /v1/feedback

Protected:
GET /v1/admin/feedback
DELETE /v1/admin/feedback/:id
```

Admin Credential을 앱에 포함하지 않는다.

---

# 49. Attachment Storage

Feedback Screenshot에는 민감한 정보가 포함될 수 있다.

따라서 Object Storage는 가능하면 Private으로 운영한다.

권장:

```text
Private bucket
Authenticated access
Temporary signed URL
Authenticated proxy
```

Public permanent URL은 기본으로 권장하지 않는다.

---

# 50. Error Handling

Transport에서 Network 또는 Backend Error가 발생하면 `throw`한다.

예:

```swift
struct MyFeedbackTransport: FeedbackTransport {

    func submit(
        _ payload: FeedbackPayload
    ) async throws -> FeedbackSubmissionReceipt {

        let response = try await send(payload)

        guard response.isSuccessful else {
            throw MyFeedbackError.serverRejected
        }

        return FeedbackSubmissionReceipt()
    }
}
```

SDLFeedbackKit은 이를 Submission Failure State로 처리한다.

---

# 51. Do Not Expose Raw Server Errors

Backend의 다음 정보를 사용자에게 그대로 보여주지 않는다.

```text
Stack trace
SQL error
Database path
Internal server exception
Storage credential error
```

사용자에게는 일반화된 Error UI를 표시한다.

---

# 52. Retry

전송 실패 시 사용자는 Retry할 수 있다.

동일 Feedback Retry에서는 가능하면 동일한:

```text
clientID
createdAt
attachment
```

를 유지한다.

---

# 53. Backend Idempotency

중복 요청을 방지하고 싶다면 Backend에서:

```text
appID + clientID
```

조합을 Idempotency Key로 사용할 수 있다.

예:

```text
UNIQUE(app_id, client_id)
```

이는 인증 수단은 아니다.

---

# 54. Localization

SDLFeedbackKit 기본 UI 문자열은 Package Resource를 사용한다.

Custom Category는 Host App에서 Localized Title을 전달할 수 있다.

예:

```swift
FeedbackCategory(
    id: "bug",
    title: String(
        localized: "feedback.category.bug"
    )
)
```

---

# 55. App-specific Metadata Example

예를 들어 퀴즈 앱:

```swift
let context = FeedbackContext(
    appID: "quiz-app",
    appName: "Quiz App",
    metadata: [
        "screen": "question",
        "questionID": "KR-042",
        "datasetVersion": "1.2.0"
    ]
)
```

SDLFeedbackKit에 `questionID` 같은 전용 Field를 추가하지 않는다.

---

# 56. macOS-specific Metadata Example

```swift
let context = FeedbackContext(
    appID: "my-mac-app",
    appName: "My Mac App",
    metadata: [
        "source": "menuBar",
        "windowMode": "popover"
    ]
)
```

---

# 57. Privacy Policy

SDLFeedbackKit을 사용하는 앱은 자신의 Privacy Policy에 실제 Feedback 수집 내용을 반영해야 한다.

특히 사용하는 경우:

```text
User-entered email
User-selected screenshot
Feedback message
Technical app/environment information
```

을 고려한다.

---

# 58. Data SDLFeedbackKit Does Not Automatically Collect

기본적으로 자동 수집하지 않는다.

```text
Exact location
Contacts
Apple ID
Advertising identifier
Installed app list
User password
Device serial number
Persistent tracking identifier
```

---

# 59. Debug Logging

Transport를 개발할 때 전체 Payload를 그대로 `print`하지 않는 것을 권장한다.

피해야 할 예:

```swift
print(payload.message)
print(payload.email)
```

권장:

```text
clientID
appID
category
messageLength
emailPresent
attachmentBytes
metadataCount
```

---

# 60. Testing Without Backend

초기 UI 개발에서는 Mock Transport를 사용할 수 있다.

예:

```swift
struct MockFeedbackTransport: FeedbackTransport {

    func submit(
        _ payload: FeedbackPayload
    ) async throws -> FeedbackSubmissionReceipt {

        try await Task.sleep(
            for: .milliseconds(500)
        )

        return FeedbackSubmissionReceipt(
            serverID: "mock-feedback"
        )
    }
}
```

---

# 61. Failure Mock

Error UI를 테스트하려면:

```swift
struct FailingFeedbackTransport: FeedbackTransport {

    func submit(
        _ payload: FeedbackPayload
    ) async throws -> FeedbackSubmissionReceipt {

        throw TestError.failed
    }
}
```

---

# 62. Console Transport

개발 중 Payload 구조 확인용:

```swift
struct ConsoleFeedbackTransport: FeedbackTransport {

    func submit(
        _ payload: FeedbackPayload
    ) async throws -> FeedbackSubmissionReceipt {

        print(
            "Feedback:",
            payload.clientID,
            payload.appID,
            payload.category.id,
            payload.message.count
        )

        return FeedbackSubmissionReceipt()
    }
}
```

실제 Message, Email, Attachment Binary를 기본 로그에 출력하지 않는 것을 권장한다.

---

# 63. Example App Integration Structure

Host App 내부 예:

```text
MyApp/
├─ App/
├─ Features/
│
├─ Feedback/
│  ├─ MyFeedbackTransport.swift
│  └─ FeedbackIntegration.swift
│
└─ ...
```

SDLFeedbackKit 자체 코드를 복사하지 않는다.

SPM Dependency로 사용한다.

---

# 64. Recommended Feedback Integration Wrapper

여러 화면에서 사용할 경우 Host App 쪽에 작은 Wrapper를 둘 수 있다.

예:

```swift
enum AppFeedback {

    static let context = FeedbackContext(
        appID: "my-app",
        appName: "My App"
    )

    static let transport = MyFeedbackTransport()
}
```

사용:

```swift
FeedbackFormView(
    context: AppFeedback.context,
    transport: AppFeedback.transport
)
```

---

# 65. Dynamic Metadata

Metadata가 현재 화면 상태에 따라 달라지는 경우 Feedback 화면을 표시하는 시점에 Context를 만든다.

예:

```swift
let context = FeedbackContext(
    appID: "my-app",
    appName: "My App",
    metadata: [
        "screen": currentScreen,
        "documentID": currentDocumentID
    ]
)
```

단, 민감정보는 넣지 않는다.

---

# 66. Package Update

Remote Swift Package를 사용할 경우 새 버전이 배포되면 Xcode에서 Package Version을 업데이트한다.

Breaking Change 가능성이 있는 `0.x` 단계에서는 CHANGELOG를 확인하는 것을 권장한다.

---

# 67. Semantic Versioning

SDLFeedbackKit은 다음 형태를 따른다.

```text
0.1.0
0.2.0
0.3.0
1.0.0
```

`1.0.0` 이후 Public API 변경은 Semantic Versioning 규칙을 따른다.

---

# 68. Common Integration Mistakes

## Mistake 1

앱에 Backend Secret 저장:

```text
Don't.
```

---

## Mistake 2

Client Validation만 믿음:

```text
Backend must validate again.
```

---

## Mistake 3

Client filename을 Storage Key로 사용:

```text
Generate server-side key instead.
```

---

## Mistake 4

Metadata에 민감정보 저장:

```text
Keep metadata diagnostic only.
```

---

## Mistake 5

FeedbackFormView가 자동으로 Navigation을 닫아줄 것으로 가정:

```text
Host owns presentation.
```

---

# 69. Recommended Minimal Production Setup

가장 단순한 Production 구성:

```text
iOS/macOS App
       ↓
SDLFeedbackKit
       ↓
Custom HTTP FeedbackTransport
       ↓
HTTPS Feedback Endpoint
       ↓
Server Validation
       ↓
Database
```

Attachment를 사용할 경우:

```text
Database
+
Private Object Storage
```

를 권장한다.

---

# 70. Recommended Cloudflare Setup

Cloudflare를 사용하는 경우:

```text
App
 ↓
SDLFeedbackKit
 ↓
Custom FeedbackTransport
 ↓
Cloudflare Worker
 ├─ D1
 └─ R2
```

Worker에서:

```text
Request size validation
Rate limiting
Field validation
Attachment validation
Canonical ID generation
R2 write
D1 write
```

를 담당한다.

---

# 71. SDLFeedbackKit Does Not Require Cloudflare

Cloudflare는 예시일 뿐이다.

다음 Backend도 동일하게 사용할 수 있다.

```text
Supabase
Firebase
AWS
Vapor
Node.js
Rails
Laravel
Go
.NET
```

필요한 것은 `FeedbackTransport` 구현뿐이다.

---

# 72. Integration Checklist

Package 적용 후 다음을 확인한다.

```text
[ ] SDLFeedbackKit added via SPM
[ ] import SDLFeedbackKit
[ ] Stable appID selected
[ ] FeedbackContext created
[ ] FeedbackTransport implemented
[ ] FeedbackFormView presented
[ ] Submission success tested
[ ] Submission failure tested
[ ] Attachment tested
[ ] 1MB attachment policy verified
[ ] Server validates all fields
[ ] Request size limit configured
[ ] Rate limiting configured
[ ] HTTPS enabled
[ ] No client secrets
[ ] Attachment storage is private
[ ] Privacy Policy reviewed
```

---

# 73. Minimum Example

가장 작은 실제 통합 예:

```swift
import SwiftUI
import SDLFeedbackKit

struct SettingsView: View {

    @State private var showsFeedback = false

    private let transport = MyFeedbackTransport()

    var body: some View {

        Button("Send Feedback") {
            showsFeedback = true
        }
        .sheet(isPresented: $showsFeedback) {

            FeedbackFormView(
                context: FeedbackContext(
                    appID: "my-app",
                    appName: "My App"
                ),
                transport: transport,
                onSubmitted: { _ in
                    showsFeedback = false
                },
                onCancelled: {
                    showsFeedback = false
                }
            )
        }
    }
}
```

---

# 74. Integration Principle

SDLFeedbackKit의 통합 모델은 다음 한 문장으로 설명할 수 있다.

> **Your app provides context and transport; SDLFeedbackKit handles the feedback experience.**

즉 개발자가 담당하는 부분:

```text
App identity
App-specific metadata
Backend
Transport
Presentation ownership
```

SDLFeedbackKit이 담당하는 부분:

```text
Feedback form
Validation
Attachment selection
Attachment optimization
Technical context
Payload creation
Submission state
```

---

# 75. Final Integration Flow

```text
1. Add SDLFeedbackKit

2. Define app context

3. Implement FeedbackTransport

4. Present FeedbackFormView

5. SDLFeedbackKit collects:
   - category
   - message
   - optional email
   - optional screenshot
   - app/environment context

6. SDLFeedbackKit builds FeedbackPayload

7. Transport sends payload

8. Self-hosted backend validates and stores it

9. Host app handles completion
```

이 경계를 유지하면 SDLFeedbackKit은 특정 Backend에 종속되지 않으면서 여러 iOS/macOS 앱에서 동일하게 재사용할 수 있다.

---

**Project:** SDLFeedbackKit
**Document:** INTEGRATION_GUIDE.md
**Owner:** SlowDevLabs
**Distribution:** Public GitHub / Swift Package Manager
**Backend Model:** Self-hosted
**Status:** Draft
**Target Version:** v0.1
