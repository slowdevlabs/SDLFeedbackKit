# SDLFeedbackKit — Architecture

## 1. Document Purpose

이 문서는 `SDLFeedbackKit`의 기술 아키텍처, 모듈 경계, 데이터 흐름, Public API 설계 원칙을 정의한다.

SDLFeedbackKit은 iOS 및 macOS 앱에서 재사용 가능한 Feedback 기능을 제공하는 공개 Swift Package이며, 특정 Backend Provider나 SlowDevLabs 내부 시스템에 종속되지 않는 것을 핵심 원칙으로 한다.

이 문서의 목적은 다음과 같다.

* Package 책임 범위 정의
* Public API와 Internal 구현 경계 정의
* Feedback 데이터 흐름 정의
* Attachment 처리 방식 정의
* Platform-specific 구현 분리
* Transport abstraction 정의
* Security boundary 정의
* 향후 확장 시 아키텍처 일관성 유지

---

# 2. Architecture Goals

SDLFeedbackKit 아키텍처는 다음 목표를 우선한다.

## 2.1 Backend Agnostic

SDLFeedbackKit은 특정 서버 구현을 알지 않는다.

Package는 다음을 알지 않아야 한다.

* Cloudflare Worker URL
* D1 Schema
* R2 Bucket
* Supabase Project
* Firebase Project
* AWS Resource
* SlowDevLabs 내부 API

Package가 알아야 하는 것은 오직:

> 생성된 Feedback을 어떤 Transport에게 전달할 것인가

뿐이다.

---

## 2.2 Simple Public API

일반적인 사용자는 복잡한 내부 구조를 이해하지 않고도 Feedback 기능을 추가할 수 있어야 한다.

목표 사용 형태:

```swift
FeedbackFormView(
    context: FeedbackContext(
        appID: "my-app",
        appName: "My App"
    ),
    transport: MyFeedbackTransport()
)
```

고급 설정이 필요한 경우에만 Configuration을 사용한다.

---

## 2.3 Platform Abstraction

iOS와 macOS의 차이는 가능한 한 Package 내부에서 처리한다.

앱에서는 다음과 같은 분기 코드가 필요하지 않아야 한다.

```swift
#if os(iOS)
...
#elseif os(macOS)
...
#endif
```

Platform-specific 구현은 Internal Layer에서 캡슐화한다.

---

## 2.4 Minimal Dependencies

가능하면 외부 Dependency를 사용하지 않는다.

기본 사용 대상:

* Swift
* SwiftUI
* Foundation
* PhotosUI
* UniformTypeIdentifiers
* AppKit
* UIKit

필요하지 않은 Network Library, Image Library, Analytics SDK 등을 추가하지 않는다.

---

## 2.5 Explicit Trust Boundary

Client Package는 보안 경계가 아니다.

SDLFeedbackKit에서 생성된 모든 데이터는 서버 입장에서 신뢰할 수 없는 입력으로 간주해야 한다.

Package는 Client-side Validation을 제공할 수 있지만, Backend Validation을 대체하지 않는다.

---

# 3. High-Level Architecture

전체 구조:

```text
┌──────────────────────────────┐
│        Host Application      │
│                              │
│ FeedbackContext              │
│ FeedbackConfiguration        │
│ FeedbackTransport            │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│       SDLFeedbackKit         │
│                              │
│ ┌──────────────────────────┐ │
│ │ Presentation Layer       │ │
│ │ FeedbackFormView         │ │
│ │ Attachment UI            │ │
│ │ Submission State UI      │ │
│ └─────────────┬────────────┘ │
│               │              │
│ ┌─────────────▼────────────┐ │
│ │ Feedback Flow Layer      │ │
│ │ Form State               │ │
│ │ Validation               │ │
│ │ Payload Builder          │ │
│ └─────────────┬────────────┘ │
│               │              │
│ ┌─────────────▼────────────┐ │
│ │ Services                 │ │
│ │ PlatformInfoProvider     │ │
│ │ ImageOptimizer           │ │
│ │ AttachmentProvider       │ │
│ └─────────────┬────────────┘ │
│               │              │
│ ┌─────────────▼────────────┐ │
│ │ Transport Abstraction    │ │
│ │ FeedbackTransport        │ │
│ └─────────────┬────────────┘ │
└───────────────┼──────────────┘
                │
                ▼
┌──────────────────────────────┐
│      Developer Backend       │
│                              │
│ Cloudflare / Firebase / AWS  │
│ Supabase / Vapor / Custom    │
└──────────────────────────────┘
```

---

# 4. Package Boundary

SDLFeedbackKit은 다음 책임을 가진다.

## Package Responsibilities

* Feedback Form UI
* Form State 관리
* Feedback Category
* Message 입력
* Optional Email 입력
* Attachment 선택
* Image Resize
* Image Compression
* Attachment Preview
* Attachment 제거
* App Context 구성
* Platform Context 수집
* Custom Metadata 병합
* Client-side Validation
* FeedbackPayload 생성
* FeedbackTransport 호출
* Submission Loading State
* Submission Success State
* Submission Failure State

---

## Outside Package Responsibilities

다음은 Host Application 또는 Backend 책임이다.

* API Endpoint 제공
* Feedback DB 저장
* Attachment Storage
* Authentication 정책
* Rate Limiting
* Spam Prevention
* Server-side Validation
* Admin Dashboard
* Feedback Status 관리
* Email Reply System
* Push Notification
* Ticketing System
* Backend Logging
* Server Monitoring

---

# 5. Proposed Package Structure

초기 권장 구조:

```text
SDLFeedbackKit/
│
├─ Package.swift
│
├─ Sources/
│  └─ SDLFeedbackKit/
│
│     ├─ Public/
│     │  ├─ FeedbackFormView.swift
│     │  ├─ FeedbackContext.swift
│     │  ├─ FeedbackConfiguration.swift
│     │  ├─ FeedbackCategory.swift
│     │  ├─ FeedbackPayload.swift
│     │  ├─ FeedbackAttachment.swift
│     │  ├─ FeedbackTransport.swift
│     │  └─ FeedbackError.swift
│     │
│     ├─ Presentation/
│     │  ├─ FeedbackFormContent.swift
│     │  ├─ FeedbackCategoryPicker.swift
│     │  ├─ FeedbackMessageEditor.swift
│     │  ├─ FeedbackEmailField.swift
│     │  ├─ FeedbackAttachmentView.swift
│     │  └─ FeedbackSubmissionStateView.swift
│     │
│     ├─ Flow/
│     │  ├─ FeedbackFormModel.swift
│     │  ├─ FeedbackFormState.swift
│     │  ├─ FeedbackValidator.swift
│     │  └─ FeedbackPayloadBuilder.swift
│     │
│     ├─ Services/
│     │  ├─ PlatformInfoProvider.swift
│     │  ├─ DefaultPlatformInfoProvider.swift
│     │  ├─ ImageOptimizer.swift
│     │  ├─ DefaultImageOptimizer.swift
│     │  └─ AttachmentLoader.swift
│     │
│     ├─ Platform/
│     │  ├─ iOS/
│     │  │  └─ iOSAttachmentPicker.swift
│     │  │
│     │  └─ macOS/
│     │     └─ macOSAttachmentPicker.swift
│     │
│     ├─ Localization/
│     │  └─ Resources/
│     │
│     └─ Internal/
│        └─ Utilities/
│
└─ Tests/
   └─ SDLFeedbackKitTests/
```

이 구조는 구현 과정에서 단순화할 수 있다.

핵심은 Public API와 Internal Implementation을 명확히 분리하는 것이다.

---

# 6. Core Public Types

SDLFeedbackKit의 Public Surface는 가능한 한 작게 유지한다.

초기 핵심 Public Type:

```text
FeedbackFormView
FeedbackContext
FeedbackConfiguration
FeedbackCategory
FeedbackPayload
FeedbackAttachment
FeedbackTransport
FeedbackError
```

그 외 대부분의 구현체는 `internal`로 유지한다.

Public API 확대는 신중하게 결정한다.

한 번 공개된 API는 Semantic Versioning상 호환성 부담이 생기기 때문이다.

---

# 7. FeedbackContext

`FeedbackContext`는 Host Application이 SDLFeedbackKit에 전달하는 앱 단위 정보이다.

개념 구조:

```swift
public struct FeedbackContext: Sendable {
    public let appID: String
    public let appName: String
    public let metadata: [String: String]

    public init(
        appID: String,
        appName: String,
        metadata: [String: String] = [:]
    )
}
```

자동으로 얻을 수 있는 앱 버전과 Build Number는 Host Application이 직접 전달하지 않고 내부 Provider가 Bundle에서 읽는 방식을 기본으로 한다.

필요할 경우 향후 override를 지원할 수 있다.

---

# 8. FeedbackConfiguration

`FeedbackConfiguration`은 SDLFeedbackKit의 동작과 UI 옵션을 정의한다.

예시:

```swift
public struct FeedbackConfiguration {
    public var categories: [FeedbackCategory]
    public var emailEnabled: Bool
    public var attachmentEnabled: Bool
    public var maximumAttachmentBytes: Int
    public var maximumImageDimension: CGFloat
    public var compressionQuality: CGFloat
}
```

기본값을 제공한다.

예:

```text
categories
→ General / Bug / Feature Request / Other

emailEnabled
→ true

attachmentEnabled
→ true

maximum attachments
→ 1

maximumImageDimension
→ 1800px

compressionQuality
→ reasonable default
```

일반 사용자는 Configuration을 생성하지 않아도 동작할 수 있어야 한다.

---

# 9. FeedbackCategory

기본 Category는 범용적으로 유지한다.

개념 예:

```swift
public struct FeedbackCategory:
    Identifiable,
    Hashable,
    Sendable
{
    public let id: String
    public let title: String
}
```

Enum으로 고정하지 않고 Value Type으로 설계하는 것을 우선 검토한다.

이유:

외부 개발자가 다음과 같은 Category를 자유롭게 정의할 수 있어야 하기 때문이다.

```text
Bug
Feature Request
Translation Issue
Billing
Content Issue
Other
```

기본 Category는 Package에서 Convenience API로 제공한다.

---

# 10. FeedbackFormView

`FeedbackFormView`는 Package의 주요 UI Entry Point다.

초기 API 방향:

```swift
public struct FeedbackFormView<Transport>: View
where Transport: FeedbackTransport {

    public init(
        context: FeedbackContext,
        transport: Transport,
        configuration: FeedbackConfiguration = .default
    )
}
```

다만 Generic Transport가 SwiftUI View Type을 복잡하게 만든다면 Type Erasure 또는 existential 사용을 검토할 수 있다.

예:

```swift
public init(
    context: FeedbackContext,
    transport: any FeedbackTransport,
    configuration: FeedbackConfiguration = .default
)
```

최종 형태는 Swift concurrency 및 SwiftUI 호환성을 검증한 뒤 결정한다.

---

# 11. Form State Architecture

사용자 입력 상태는 `FeedbackFormModel`에서 관리한다.

개념 상태:

```text
category
message
email
attachment
submissionState
validationErrors
```

Submission State:

```swift
enum SubmissionState {
    case idle
    case submitting
    case success
    case failure(FeedbackError)
}
```

Public으로 노출할 필요가 없는 경우 `internal`로 유지한다.

---

# 12. Data Flow

기본 전송 데이터 흐름:

```text
1. FeedbackFormView 표시

2. FeedbackFormModel 생성

3. 사용자 입력
   - Category
   - Message
   - Email
   - Attachment

4. Attachment 선택 시
   AttachmentLoader
        ↓
   ImageOptimizer
        ↓
   FeedbackAttachment

5. 사용자가 Submit 선택

6. FeedbackValidator 실행

7. PlatformInfoProvider 호출

8. FeedbackPayloadBuilder 실행

9. FeedbackPayload 생성

10. FeedbackTransport.submit()

11. Transport 결과 반환

12-A. Success
     → UI Success State

12-B. Failure
     → UI Error State
     → Retry 가능
```

---

# 13. FeedbackPayload

Payload는 Backend에 전달되는 논리적 Feedback 데이터 모델이다.

초기 개념:

```swift
public struct FeedbackPayload: Sendable {

    public let id: UUID

    public let appID: String
    public let appName: String

    public let appVersion: String?
    public let buildNumber: String?

    public let platform: String
    public let osVersion: String

    public let categoryID: String
    public let categoryTitle: String

    public let message: String
    public let email: String?

    public let locale: String?

    public let metadata: [String: String]

    public let attachment: FeedbackAttachment?

    public let createdAt: Date
}
```

정확한 API는 구현 및 Codable 요구 여부를 검토하며 조정한다.

---

# 14. Payload Serialization

중요한 원칙:

> SDLFeedbackKit은 특정 HTTP Payload Format을 강제하지 않는다.

즉 Package가 다음을 직접 결정하지 않는다.

```text
multipart/form-data
JSON + Base64
presigned upload
two-step upload
GraphQL mutation
Firebase SDK
```

`FeedbackTransport` 구현체가 Payload를 자신의 Backend 방식으로 변환한다.

예:

```text
FeedbackPayload
      ↓
MyCloudflareTransport
      ↓
multipart/form-data
```

또는:

```text
FeedbackPayload
      ↓
MySupabaseTransport
      ↓
Storage Upload
      +
Database Insert
```

이 구조가 Backend independence의 핵심이다.

---

# 15. FeedbackAttachment

Attachment는 Backend-specific URL이 아니라 전송 가능한 Local Data를 표현한다.

개념 구조:

```swift
public struct FeedbackAttachment: Sendable {

    public let data: Data
    public let filename: String
    public let mimeType: String

    public let pixelWidth: Int?
    public let pixelHeight: Int?
}
```

Attachment에 다음 정보는 포함하지 않는다.

```text
R2 Key
S3 URL
Firebase URL
Cloudflare Object ID
```

이는 Backend Transport의 책임이다.

---

# 16. Attachment Processing Pipeline

이미지 선택 후 다음 단계를 따른다.

```text
Selected Image
     ↓
Load Data
     ↓
Decode
     ↓
Orientation Normalize
     ↓
Resize
     ↓
Compress
     ↓
Validate Size
     ↓
FeedbackAttachment
```

기본 정책:

```text
Maximum Attachments
1

Maximum Dimension
약 1800px 기본값

Compression
Configuration 기반

Metadata
가능하면 불필요한 이미지 metadata 제거
```

---

# 17. Image Metadata Policy

Feedback Screenshot에는 불필요한 metadata가 포함될 수 있다.

가능하면 재인코딩 과정에서 다음과 같은 metadata를 제거하는 방향으로 설계한다.

* GPS
* EXIF
* Camera Model
* Original Creation Metadata

목적은 Privacy 최소화다.

ImageOptimizer가 새로운 이미지 데이터를 생성하면 대부분 자연스럽게 제거 가능하다.

다만 구현 단계에서 실제 Platform API 동작을 검증한다.

---

# 18. Attachment Picking

Attachment 선택 API는 플랫폼별로 다를 수 있다.

## iOS

우선 후보:

```text
PHPickerViewController / UIImagePickerController fallback
```

장점:

* Native
* Privacy-friendly
* Photos permission 전체 요청 불필요
* SwiftUI integration via representable bridge

---

## macOS

상황에 따라:

```text
NSOpenPanel
```

를 사용할 수 있다.

사용자는 Screenshot 파일을 직접 첨부하는 경우가 많기 때문에 macOS에서는 File Importer가 더 자연스러울 수 있다.
현재 v0.1 구현은 `NSOpenPanel`을 사용한다.

최종 UX는 구현 단계에서 검증한다.

---

# 19. PlatformInfoProvider

자동 Context 수집은 `PlatformInfoProvider`를 통해 분리한다.

개념:

```swift
protocol PlatformInfoProvider {
    func collect() -> PlatformInfo
}
```

기본 수집 후보:

```text
App Version
Build Number
Platform
OS Version
Locale
Device / Hardware Information
```

Provider로 분리하는 이유:

* Unit Test 가능
* Preview 가능
* 미래 플랫폼 대응
* 실제 Device API 변경 격리

---

# 20. Platform Information Privacy

자동 수집은 최소한으로 유지한다.

기본적으로 수집하지 않는 정보:

```text
User Name
Apple ID
Advertising Identifier
Exact Location
Contacts
Photos Library
IP Address
Installed Applications
Device Serial Number
Persistent User Tracking Identifier
```

Device Model 역시 필요성 및 Apple 정책을 검토하여 적절한 수준으로만 제공한다.

목표는:

> 문제 재현에 필요한 기술 정보만 제공

이다.

---

# 21. FeedbackTransport

Transport는 SDLFeedbackKit과 Backend 사이의 유일한 공식 경계다.

기본 설계:

```swift
public protocol FeedbackTransport: Sendable {

    func submit(
        _ payload: FeedbackPayload
    ) async throws
}
```

Transport는 다음 책임을 가진다.

* Network Request
* Authentication if required
* Serialization
* Attachment Upload
* Backend Response Parsing
* Backend-specific Error Mapping

SDLFeedbackKit은 Transport 내부 구현을 알지 않는다.

---

# 22. Example Custom Transport

예:

```swift
struct MyFeedbackTransport: FeedbackTransport {

    func submit(
        _ payload: FeedbackPayload
    ) async throws {

        // Serialize payload
        // Upload attachment
        // POST to backend
        // Validate response
    }
}
```

앱에서는:

```swift
FeedbackFormView(
    context: context,
    transport: MyFeedbackTransport()
)
```

형태로 사용한다.

---

# 23. No Built-in Production Endpoint

SDLFeedbackKit에는 기본 Production Endpoint를 포함하지 않는다.

다음과 같은 코드는 Package에 존재해서는 안 된다.

```swift
let defaultEndpoint =
    URL(string: "https://feedback.slowdevlabs.com")!
```

또한:

```text
Default SlowDevLabs API Key
Default Cloudflare Account
Default D1 Database
```

등도 포함하지 않는다.

---

# 24. Reference Transport

향후 README 또는 Examples에 단순 HTTP Transport 예제를 제공할 수 있다.

예:

```text
Examples/
└─ BasicHTTPFeedbackTransport.swift
```

이 구현은 참고용이며 SDLFeedbackKit Public API의 필수 구성 요소가 아니다.

Cloudflare 전용 구현 역시 Core Package에 넣지 않는 것을 기본 방향으로 한다.

---

# 25. SlowDevLabs Internal Integration

SlowDevLabs 앱은 공개 SDLFeedbackKit 위에 내부 Transport를 구현한다.

```text
Doligo
TimeTape
CUE
SymbolicDrop
...
    │
    ▼
SDLFeedbackKit
    │
    ▼
SlowDevFeedbackTransport
    │
    ▼
SlowDev Feedback Worker
    │
    ├─ D1
    └─ R2
```

`SlowDevFeedbackTransport`는 각 앱 또는 별도 private package에서 관리할 수 있다.

SDLFeedbackKit repository에는 포함하지 않는다.

---

# 26. Recommended SlowDevLabs Backend Boundary

내부 Backend 예:

```text
POST /v1/feedback
```

Worker Responsibilities:

```text
Request validation
Rate limiting
Payload normalization
Feedback ID generation
Attachment validation
R2 storage
D1 insert
Response
```

하지만 이는 SDLFeedbackKit Core Architecture 밖의 구현이다.

---

# 27. Client Validation

SDLFeedbackKit은 사용자 경험 개선을 위해 기본 Validation을 수행한다.

예:

```text
Message
→ Empty 불가

Message length
→ Configured limit

Email
→ 입력된 경우 기본 형식 검사

Attachment
→ Supported image only

Attachment size
→ Configuration limit
```

이 Validation은 UX 목적이다.

보안 목적으로 신뢰해서는 안 된다.

Backend에서는 동일하거나 더 강한 검증을 별도로 수행해야 한다.

---

# 28. Message Length Policy

Client와 Backend 모두 명시적인 길이 제한을 가져야 한다.

예시 초기값:

```text
Message
Maximum 5,000 characters

Email
Maximum 320 characters

Metadata Key
Maximum 64 characters

Metadata Value
Maximum 1,000 characters

Metadata Entry Count
Maximum configurable value
```

정확한 값은 API Specification에서 최종 확정한다.

---

# 29. Metadata Architecture

Metadata는 자유도를 제공하지만 무제한 데이터 전달 수단으로 사용하지 않는다.

권장 모델:

```swift
[String: String]
```

이유:

* 단순함
* Codable 용이
* Backend 호환성
* 예측 가능한 Payload
* Arbitrary nested object 방지

초기 버전에서는:

```text
[String: Any]
```

또는 임의 JSON Tree는 지원하지 않는 것을 권장한다.

---

# 30. Metadata Collision Policy

Automatic Context와 Custom Metadata의 이름 충돌을 방지한다.

예:

```text
System fields

appID
appVersion
platform
osVersion

Custom metadata

metadata["datasetVersion"]
metadata["screen"]
```

Custom Metadata가 System Field를 override하지 못하도록 구조적으로 분리한다.

---

# 31. Error Architecture

SDLFeedbackKit의 Error는 Backend-specific detail을 사용자에게 그대로 노출하지 않는다.

Public error model 예:

```swift
public enum FeedbackError: Error {
    case invalidInput
    case attachmentProcessingFailed
    case submissionFailed
    case cancelled
}
```

개발자 디버깅을 위한 underlying error는 내부에서 유지하거나 적절히 전달할 수 있다.

사용자에게는 다음처럼 간단하게 표시한다.

```text
Couldn't send feedback.
Please try again.
```

Backend response body나 Server Stack Trace는 UI에 표시하지 않는다.

---

# 32. Submission Concurrency

Feedback Submit은 Swift Concurrency 기반으로 처리한다.

```text
async / await
```

기본 원칙:

* MainActor에서 UI 상태 변경
* Network는 Transport 내부 async operation
* 중복 Submit 방지
* Submit 중 Button Disable
* Task cancellation 고려
* View 종료 시 불필요한 작업 처리 정책 명확화

---

# 33. Duplicate Submission

사용자가 Submit 버튼을 여러 번 누르는 것을 방지한다.

Client:

```text
submitting state
→ Submit disabled
```

Backend 역시 완벽한 중복 방지는 별도로 고려할 수 있다.

향후 Payload에 Client-generated UUID를 포함하는 이유 중 하나도 중복 추적이다.

예:

```swift
id: UUID
```

Backend는 필요하다면 idempotency 처리에 사용할 수 있다.

---

# 34. Feedback ID

Client에서 UUID를 생성하는 구조를 우선 검토한다.

```swift
UUID()
```

장점:

* Submit retry 식별
* Backend log correlation
* Attachment correlation
* Duplicate detection 가능

다만 Server가 별도 canonical ID를 생성해도 된다.

Client ID와 Server ID는 서로 다른 개념으로 사용할 수 있다.

---

# 35. Success Behavior

기본 성공 흐름:

```text
Submit
 ↓
Loading
 ↓
Success
 ↓
Short confirmation
 ↓
Dismiss 가능
```

Dismiss 방식은 Host Application 구조와 충돌하지 않아야 한다.

Package가 무조건 `dismiss()`를 수행하기보다 Configuration 또는 callback을 제공하는 방식을 검토한다.

예:

```swift
onSubmitted: (() -> Void)?
```

초기 구현에서 가장 단순한 UX를 우선하되 Host의 Navigation control을 침범하지 않는다.

---

# 36. Presentation Ownership

SDLFeedbackKit은 다음 형태 모두에서 사용 가능해야 한다.

```text
sheet
fullScreenCover
NavigationStack destination
macOS window / sheet
```

Package가 Presentation 방식 자체를 강제하지 않는다.

Host App이 FeedbackFormView를 어떻게 표시할지 결정한다.

---

# 37. Navigation Independence

SDLFeedbackKit 내부에서 Host App NavigationPath를 직접 수정하지 않는다.

또한 다음에 의존하지 않는다.

```text
NavigationCoordinator
AppRouter
Environment Router
Custom Navigation Framework
```

Feedback Form 자체 내부 navigation이 필요하다면 독립적으로 처리한다.

---

# 38. Dependency Injection

테스트 가능성을 위해 다음 요소는 교체 가능해야 한다.

```text
FeedbackTransport
PlatformInfoProvider
ImageOptimizer
```

Public 사용자는 대부분 기본 구현을 사용한다.

Tests에서는 Mock으로 교체할 수 있다.

---

# 39. Test Architecture

초기 Unit Test 대상:

## Payload Builder

* Context 병합
* App/System 정보 반영
* Metadata 유지
* Optional Email
* Attachment 포함/미포함

## Validation

* Empty Message
* Message Length
* Email
* Attachment Size

## Image Optimizer

* Resize 결과
* Maximum Dimension
* Compression
* Invalid Data Handling

## Form Model

* Initial State
* Submit State
* Success
* Error
* Duplicate Submit 방지

## Transport

Package에서는 Mock Transport를 사용한다.

실제 Network Test는 Core Test 범위에 포함하지 않는다.

---

# 40. UI Test Scope

Example Apps 또는 별도 Integration Tests에서 다음을 검증할 수 있다.

```text
Form presentation
Category selection
Message input
Email optional behavior
Attachment add/remove
Loading
Success
Failure
Dark Mode
Dynamic Type
VoiceOver Labels
```

---

# 41. Accessibility Architecture

Custom UI를 만들 경우 기본 SwiftUI semantics를 유지한다.

다음에 주의한다.

```text
Button labels
Image accessibility
Attachment remove action
Error announcement
Submission progress
Dynamic Type
Keyboard focus
macOS keyboard navigation
```

장식용 이미지나 아이콘은 필요 시 accessibilityHidden 처리한다.

---

# 42. Localization Architecture

Package UI 문자열은 Resource 기반으로 관리한다.

Hardcoded UI text를 피한다.

예:

```text
Feedback
Category
Message
Email
Add Screenshot
Send
Sending...
Thank you
Try Again
```

향후 외부 개발자가 커스텀 문구를 전달할 필요가 있다면 Configuration 기반 override를 고려한다.

초기에는 지나치게 많은 String Configuration을 Public API로 노출하지 않는다.

---

# 43. Styling Architecture

SDLFeedbackKit은 기본적으로 Native SwiftUI styling을 사용한다.

초기 버전에서는 완전한 Theme Engine을 제공하지 않는다.

이유:

* Public API 복잡도 증가
* 유지보수 부담
* macOS/iOS UI divergence 증가
* 앱별 Custom Style 요구 무한 확장

초기 우선순위:

```text
Native
Clean
Adaptive
Accessible
```

향후 실제 수요가 확인되면 제한적인 Appearance Configuration을 추가한다.

---

# 44. Platform Compilation

Swift Package는 Conditional Compilation을 사용해 필요한 부분만 빌드한다.

예:

```swift
#if os(iOS)
import UIKit
#endif

#if os(macOS)
import AppKit
#endif
```

단, 조건부 코드는 Platform Layer에 최대한 집중시킨다.

Core Model과 Flow Layer는 플랫폼 중립적으로 유지한다.

---

# 45. Minimum OS Versions

정확한 Deployment Target은 구현 시 사용하는 Apple API를 확인한 후 확정한다.

선정 원칙:

* supported native picker APIs
* 지나치게 오래된 OS 지원으로 복잡도를 높이지 않음
* 현재 SwiftUI 기반 앱 개발 환경에 합리적인 범위

`Package.swift`에 명시한다.

예시 형태:

```swift
platforms: [
    .iOS(...),
    .macOS(...)
]
```

구체 버전은 별도 Engineering Decision으로 기록한다.

---

# 46. Swift Version Policy

가능하면 현재 안정적인 Swift Toolchain을 기준으로 개발한다.

공개 Package이므로 너무 최신 Compiler만 강제하여 사용 범위를 좁히지 않도록 주의한다.

Swift Version 변경 시 CHANGELOG에 기록한다.

---

# 47. Semantic Versioning

SDLFeedbackKit은 Semantic Versioning을 따른다.

```text
0.1.0
0.2.0
...
1.0.0
```

`0.x` 단계에서는 Public API 변경이 상대적으로 자유롭지만, 불필요한 Breaking Change는 피한다.

`1.0.0` 이후에는 Public API 안정성을 강하게 유지한다.

---

# 48. Source Compatibility

Public Type을 추가하는 것은 비교적 안전하지만 다음은 Breaking Change가 될 수 있다.

```text
Public Property 삭제
Protocol requirement 추가
Initializer parameter 변경
Enum case 변경
Generic constraint 변경
```

특히 `FeedbackTransport`는 외부 개발자가 직접 구현하므로 매우 신중하게 변경한다.

---

# 49. Security Boundary

Architecture상 Trust Boundary:

```text
Trusted
────────────────────

Developer Backend
Secrets
Database
Storage Credentials
Admin Authentication


Untrusted
────────────────────

SDLFeedbackKit
Host App Binary
FeedbackPayload
Custom Metadata
Attachment
Client Header
Client-generated ID
```

Host App 자체도 Server 관점에서는 신뢰하지 않는다.

---

# 50. Secret Management

SDLFeedbackKit에는 Secret을 저장하지 않는다.

사용자에게도 README에서 다음을 명확히 안내해야 한다.

> Never embed server secrets in your app or SDLFeedbackKit configuration.

공개 Endpoint URL은 Secret이 아니다.

Backend는 Endpoint가 알려져도 안전하도록 설계해야 한다.

---

# 51. Network Security

SDLFeedbackKit Core는 HTTP Client를 직접 구현하지 않으므로 Transport 작성자가 Network 정책을 결정한다.

권장:

```text
HTTPS only
Server-side rate limiting
Short request timeout
Payload size limits
Safe error responses
```

실제 Transport Example을 제공한다면 안전한 기본값을 사용한다.

---

# 52. Offline Behavior

MVP에서는 Offline Queue를 제공하지 않는다.

Network Failure 시:

```text
submissionFailed
```

상태를 보여주고 사용자에게 Retry를 제공한다.

Feedback을 앱 내부에 장기 저장하는 것은 Privacy와 데이터 lifecycle을 복잡하게 만들기 때문에 초기 범위에서 제외한다.

---

# 53. Retry Policy

MVP에서는 자동 무한 Retry를 하지 않는다.

권장:

```text
User initiated retry
```

필요하면 Transport가 단기 transient retry를 자체 구현할 수 있다.

향후 SDLFeedbackKit에 Retry Policy를 추가할 경우 별도 Specification을 만든다.

---

# 54. Data Retention

SDLFeedbackKit은 Feedback 데이터를 서버에 저장하지 않으므로 Retention Policy를 결정하지 않는다.

Backend 운영자가 결정한다.

Package는 Submit 완료 후 Form State에서 불필요한 Attachment Data를 가능한 빠르게 해제하는 방향으로 구현한다.

---

# 55. Memory Considerations

고해상도 Screenshot을 그대로 메모리에 장시간 보관하지 않는다.

Attachment Pipeline에서:

```text
Load
→ Resize
→ Compress
→ Release original
```

방식을 사용한다.

특히 iOS에서 대형 이미지 선택 시 Memory Spike를 방지해야 한다.

---

# 56. Image Processing Boundary

`ImageOptimizer`는 다음 입력/출력 책임을 가진다.

```text
Input
Raw selected image

Output
Optimized FeedbackAttachment
```

Network Upload는 담당하지 않는다.

이 경계를 분리해:

```text
Image Processing
≠
Transport
```

를 유지한다.

---

# 57. Example Application Architecture

Repository에 Example App을 포함한다면 Package와 독립된 작은 Host 형태로 구성한다.

```text
Examples/
├─ SDLFeedbackKitExample-iOS/
└─ SDLFeedbackKitExample-macOS/
```

Example App에서는:

```text
MockTransport
또는
LocalDebugTransport
```

를 기본 사용한다.

실제 SlowDevLabs Backend credential은 포함하지 않는다.

---

# 58. Debug Transport

개발 편의를 위해 Example용 Transport를 만들 수 있다.

예:

```swift
struct ConsoleFeedbackTransport: FeedbackTransport {

    func submit(
        _ payload: FeedbackPayload
    ) async throws {
        print(payload)
    }
}
```

이는 Production 기능이 아니라 Example 또는 Test Utility다.

---

# 59. Documentation Architecture

Repository 문서는 최소 다음 구조를 권장한다.

```text
README.md
LICENSE
CHANGELOG.md

Docs/
├─ PROJECT_BRIEF.md
├─ ARCHITECTURE.md
├─ API_SPEC.md
├─ ATTACHMENT_SPEC.md
├─ SECURITY.md
└─ INTEGRATION_GUIDE.md
```

초기에는 모든 문서를 한 번에 만들 필요는 없다.

구현과 함께 필요한 문서부터 추가한다.

---

# 60. Recommended Next Specifications

이 Architecture 이후 구현 전에 우선 작성할 문서는 다음 순서를 권장한다.

```text
1. API_SPEC.md
   Public API와 Model 확정

2. FEEDBACK_PAYLOAD_SPEC.md
   Payload field와 validation 정의

3. ATTACHMENT_SPEC.md
   이미지 선택 / 압축 / 크기 정책

4. INTEGRATION_GUIDE.md
   외부 개발자 사용 흐름

5. SECURITY.md
   Client / Backend 보안 가이드
```

---

# 61. Architectural Decisions Summary

현재 결정:

```text
Package
SDLFeedbackKit

Distribution
Public GitHub / Swift Package Manager

UI
SwiftUI

Platforms
iOS + macOS

Backend
Not included

Backend Model
Self-hosted

Transport
Protocol-based

Attachment
Image 1

Attachment Storage
Transport / Backend responsibility

Automatic Context
Package responsibility

Custom App Data
metadata

Database
Not Package responsibility

SlowDevLabs Backend
Private implementation

Cloudflare
Reference / Internal implementation only

Security Boundary
Server

Secrets
Never stored in Package

License
MIT
```

---

# 62. Architecture Principle

SDLFeedbackKit의 모든 향후 기능은 다음 질문으로 판단한다.

> 이 기능은 iOS/macOS 앱에서 Feedback을 수집하기 위해 모든 개발자가 공통으로 필요로 하는 Client-side 기능인가?

Yes라면 SDLFeedbackKit에 포함할 수 있다.

No라면:

* Host Application
* Custom Transport
* Backend
* 별도 Package

중 하나의 책임으로 남겨야 한다.

---

# 63. Final Architecture Definition

SDLFeedbackKit은 다음 구조를 가진다.

> **A lightweight SwiftUI presentation and feedback payload layer with a protocol-based transport boundary.**

즉 SDLFeedbackKit은:

```text
Feedback UI
+
Input State
+
Attachment Processing
+
Environment Context
+
Payload Construction
+
Transport Interface
```

까지 담당한다.

그리고 다음 경계에서 멈춘다.

```text
SDLFeedbackKit
        │
        │ FeedbackPayload
        ▼
FeedbackTransport
        │
────────┼──────── Trust / Infrastructure Boundary
        ▼
Developer Backend
```

이 경계를 유지하는 것이 SDLFeedbackKit의 재사용성, 공개 배포 가능성, 보안성, 장기 유지보수성을 결정하는 핵심 원칙이다.

---

**Project:** SDLFeedbackKit
**Document:** ARCHITECTURE.md
**Owner:** SlowDevLabs
**Distribution:** Public GitHub / Swift Package Manager
**Backend Model:** Self-hosted
**Architecture Status:** Draft
