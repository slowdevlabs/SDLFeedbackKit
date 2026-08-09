# SDLFeedbackKit — API Specification

## 1. Document Purpose

이 문서는 `SDLFeedbackKit`의 Public API를 정의한다.

목표는 다음과 같다.

* 외부 개발자가 사용하는 API Surface를 최소화한다.
* iOS/macOS에서 동일한 사용 패턴을 제공한다.
* Backend 구현과 Package 구현을 분리한다.
* 향후 Semantic Versioning 기준이 될 안정적인 API 계약을 만든다.
* 불필요한 Public Type 노출을 방지한다.

이 문서는 구현 세부사항보다 **외부에서 보이는 인터페이스와 동작 계약**을 우선 정의한다.

---

# 2. API Design Principles

SDLFeedbackKit의 Public API는 다음 원칙을 따른다.

## 2.1 Small Public Surface

외부 개발자가 직접 알아야 하는 Type은 최소화한다.

초기 Public API 후보:

```text
FeedbackFormView
FeedbackContext
FeedbackConfiguration
FeedbackCategory
FeedbackPayload
FeedbackAttachment
FeedbackTransport
FeedbackError
FeedbackSubmissionResult
```

나머지 ViewModel, Validator, Payload Builder, Platform Provider 등은 기본적으로 `internal`로 유지한다.

---

## 2.2 Sensible Defaults

대부분의 개발자는 기본 Configuration만으로 사용할 수 있어야 한다.

목표:

```swift
FeedbackFormView(
    context: FeedbackContext(
        appID: "my-app",
        appName: "My App"
    ),
    transport: MyFeedbackTransport()
)
```

위 코드만으로 기본 Feedback Form을 표시할 수 있어야 한다.

---

## 2.3 Backend Independence

Public API에 다음 개념은 포함하지 않는다.

```text
Cloudflare
D1
R2
Supabase
Firebase
AWS
REST Endpoint URL
API Key
```

Backend 관련 구현은 모두 `FeedbackTransport` 바깥에 둔다.

---

## 2.4 Swift Concurrency First

전송 API는 `async/await`를 기본으로 한다.

Completion Handler 기반 API는 제공하지 않는다.

---

## 2.5 Value Types First

가능한 경우 Public Model은 `struct` 기반으로 설계한다.

목표:

* 예측 가능한 State
* Sendable 지원
* Thread Safety
* 쉬운 Testing
* 간단한 Serialization

---

# 3. Module Import

사용자는 다음과 같이 Package를 import한다.

```swift
import SDLFeedbackKit
```

---

# 4. Minimum Integration

최소 사용 예:

```swift
import SwiftUI
import SDLFeedbackKit

struct SettingsView: View {

    var body: some View {
        FeedbackFormView(
            context: FeedbackContext(
                appID: "my-app",
                appName: "My App"
            ),
            transport: MyFeedbackTransport()
        )
    }
}
```

`MyFeedbackTransport`는 개발자가 직접 구현한다.

---

# 5. FeedbackFormView

## 5.1 Purpose

`FeedbackFormView`는 SDLFeedbackKit의 기본 UI Entry Point다.

사용자가 다음 작업을 수행할 수 있도록 한다.

* Feedback Category 선택
* Message 입력
* Optional Email 입력
* Optional Attachment 선택
* Feedback Submit

---

## 5.2 Proposed API

초기 권장 형태:

```swift
public struct FeedbackFormView: View {

    public init(
        context: FeedbackContext,
        transport: any FeedbackTransport,
        configuration: FeedbackConfiguration = .default,
        onSubmitted: ((FeedbackSubmissionResult) -> Void)? = nil,
        onCancelled: (() -> Void)? = nil
    )
}
```

---

## 5.3 Parameters

### context

```swift
FeedbackContext
```

Host Application의 앱 정보 및 Custom Metadata를 전달한다.

---

### transport

```swift
any FeedbackTransport
```

생성된 Feedback Payload를 실제 Backend로 전송하는 구현체다.

---

### configuration

```swift
FeedbackConfiguration
```

Feedback Form의 동작 및 옵션을 정의한다.

기본값:

```swift
.default
```

---

### onSubmitted

```swift
((FeedbackSubmissionResult) -> Void)?
```

전송 성공 후 Host Application이 추가 동작을 수행하고 싶은 경우 사용한다.

SDLFeedbackKit은 Host App의 Navigation을 직접 제어하지 않는 것을 원칙으로 한다.

예:

```swift
FeedbackFormView(
    context: context,
    transport: transport,
    onSubmitted: { result in
        dismiss()
    }
)
```

---

### onCancelled

```swift
(() -> Void)?
```

사용자가 Cancel 동작을 선택한 경우 Host Application에 알린다.

Cancel UI 자체를 표시할지 여부는 Configuration으로 제어할 수 있다.

---

# 6. FeedbackContext

## 6.1 Purpose

`FeedbackContext`는 현재 Feedback이 어떤 앱에서 발생했는지 식별하기 위한 Host-defined Context다.

---

## 6.2 Proposed API

```swift
public struct FeedbackContext: Sendable, Hashable {

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

---

## 6.3 appID

Backend에서 앱을 안정적으로 식별하기 위한 값이다.

예:

```text
doligo
timetape
cue-kpop
symbolicdrop
```

권장:

* 사람이 읽을 수 있는 안정적인 identifier
* 앱 이름이 변경되어도 가능하면 유지
* Display Name과 분리

---

## 6.4 appName

사용자 또는 관리자 화면에 표시할 수 있는 앱 이름이다.

예:

```text
돌리GO
TimeTape
SymbolicDrop
```

---

## 6.5 metadata

앱별 추가 Context를 전달한다.

예:

```swift
FeedbackContext(
    appID: "doligo",
    appName: "돌리GO",
    metadata: [
        "datasetVersion": "1.4.0",
        "screen": "destination",
        "mode": "stay"
    ]
)
```

Package는 Metadata의 의미를 해석하지 않는다.

---

# 7. FeedbackConfiguration

## 7.1 Purpose

Feedback Form의 동작을 조정한다.

---

## 7.2 Proposed API

```swift
public struct FeedbackConfiguration: Sendable {

    public var categories: [FeedbackCategory]

    public var emailField: EmailFieldConfiguration
    public var attachment: AttachmentConfiguration
    public var message: MessageConfiguration

    public var showsCancelButton: Bool

    public init(
        categories: [FeedbackCategory] = .defaultFeedbackCategories,
        emailField: EmailFieldConfiguration = .default,
        attachment: AttachmentConfiguration = .default,
        message: MessageConfiguration = .default,
        showsCancelButton: Bool = true
    )

    public static let `default`: FeedbackConfiguration
}
```

---

# 8. FeedbackCategory

## 8.1 Purpose

Feedback 종류를 표현한다.

고정 Enum 대신 확장 가능한 Value Type을 사용한다.

---

## 8.2 Proposed API

```swift
public struct FeedbackCategory:
    Identifiable,
    Hashable,
    Sendable {

    public let id: String
    public let title: String

    public init(
        id: String,
        title: String
    )
}
```

---

## 8.3 Default Categories

Convenience API로 기본 Category를 제공한다.

```swift
public extension FeedbackCategory {

    static let general = FeedbackCategory(
        id: "general",
        title: "General Feedback"
    )

    static let bug = FeedbackCategory(
        id: "bug",
        title: "Bug Report"
    )

    static let featureRequest = FeedbackCategory(
        id: "feature_request",
        title: "Feature Request"
    )

    static let other = FeedbackCategory(
        id: "other",
        title: "Other"
    )
}
```

또한:

```swift
public extension Array where Element == FeedbackCategory {

    static var defaultFeedbackCategories: [FeedbackCategory] {
        [
            .general,
            .bug,
            .featureRequest,
            .other
        ]
    }
}
```

구체 구현은 Package 내부 구조에 따라 조정 가능하다.

---

# 9. MessageConfiguration

## 9.1 Purpose

Feedback Message 입력 정책을 정의한다.

---

## 9.2 Proposed API

```swift
public struct MessageConfiguration: Sendable {

    public var minimumLength: Int
    public var maximumLength: Int
    public var isRequired: Bool

    public init(
        minimumLength: Int = 1,
        maximumLength: Int = 5_000,
        isRequired: Bool = true
    )

    public static let `default`: MessageConfiguration
}
```

---

# 10. EmailFieldConfiguration

## 10.1 Purpose

Email 입력 Field의 동작을 정의한다.

---

## 10.2 Proposed API

```swift
public struct EmailFieldConfiguration: Sendable {

    public var isEnabled: Bool
    public var isRequired: Bool
    public var maximumLength: Int

    public init(
        isEnabled: Bool = true,
        isRequired: Bool = false,
        maximumLength: Int = 320
    )

    public static let `default`: EmailFieldConfiguration
}
```

---

## 10.3 Behavior

`isEnabled == false`이면:

* Email Field를 표시하지 않는다.
* Payload의 email은 `nil`이다.

`isRequired == true`이면:

* Empty Email을 Submit할 수 없다.
* 기본 Email Format Validation을 수행한다.

---

# 11. AttachmentConfiguration

## 11.1 Purpose

이미지 첨부 정책을 정의한다.

---

## 11.2 Proposed API

```swift
public struct AttachmentConfiguration: Sendable {

    public var isEnabled: Bool
    public var maximumAttachmentBytes: Int
    public var maximumImageDimension: Int
    public var compressionQuality: Double

    public init(
        isEnabled: Bool = true,
        maximumAttachmentBytes: Int = 1_000_000,
        maximumImageDimension: Int = 1_800,
        compressionQuality: Double = 0.8
    )

    public static let `default`: AttachmentConfiguration
}
```

---

## 11.3 Constraints

MVP에서는:

```text
Maximum Attachment Count
1
```

고정이다.

Multiple Attachment는 v0.1 Public API에 포함하지 않는다.

---

# 12. FeedbackPayload

## 12.1 Purpose

사용자가 작성한 Feedback과 자동 수집 Context를 결합한 최종 전송 모델이다.

Transport는 이 Type을 입력으로 받는다.

---

## 12.2 Proposed API

```swift
public struct FeedbackPayload: Sendable {

    public let clientID: UUID

    public let appID: String
    public let appName: String

    public let appVersion: String?
    public let buildNumber: String?

    public let platform: FeedbackPlatform
    public let osVersion: String
    public let localeIdentifier: String?

    public let category: FeedbackCategory

    public let message: String
    public let email: String?

    public let metadata: [String: String]

    public let attachment: FeedbackAttachment?

    public let createdAt: Date
}
```

---

# 13. Payload Immutability

`FeedbackPayload`는 생성된 이후 변경되지 않는 것을 원칙으로 한다.

모든 Property는:

```swift
let
```

로 유지한다.

Payload 생성은 Package 내부 `FeedbackPayloadBuilder`가 담당한다.

외부 개발자가 직접 Payload를 생성할 필요는 없다.

필요하지 않다면 Public Initializer를 제공하지 않는 것도 허용한다.

즉:

```swift
public struct FeedbackPayload
```

이지만 initializer는 `internal`일 수 있다.

Transport 구현자는 읽기만 하면 된다.

---

# 14. FeedbackPlatform

## 14.1 Purpose

현재 실행 Platform을 명시적으로 전달한다.

---

## 14.2 Proposed API

```swift
public enum FeedbackPlatform:
    String,
    Sendable,
    Codable {

    case iOS
    case macOS
}
```

향후 필요 시:

```text
visionOS
```

등을 추가할 수 있다.

단, `1.0` 이후 Enum Case 추가가 외부 exhaustive switch에 영향을 줄 수 있으므로 향후 Non-frozen 전략을 검토한다.

---

# 15. FeedbackAttachment

## 15.1 Purpose

전송 가능한 최종 이미지 Attachment를 표현한다.

---

## 15.2 Proposed API

```swift
public struct FeedbackAttachment: Sendable {

    public let data: Data
    public let filename: String
    public let mimeType: String

    public let pixelWidth: Int?
    public let pixelHeight: Int?

    public let byteCount: Int
}
```

---

## 15.3 Attachment Content

Attachment는 최적화된 데이터만 포함한다.

Package 내부에서:

```text
Original Image
→ Decode
→ Normalize
→ Resize
→ Re-encode
→ Metadata removal
→ FeedbackAttachment
```

과정을 거친 이후 Transport에 전달된다.

---

# 16. Attachment Format

MVP에서는 Package가 생성하는 기본 출력 이미지 포맷을 하나로 통일하는 것을 우선 검토한다.

권장 후보:

```text
JPEG
```

이유:

* 넓은 Backend 호환성
* Screenshot 압축 효과
* 구현 단순성

단, 투명도가 필요한 경우를 고려해 실제 구현 단계에서 HEIC/PNG 정책을 재검토할 수 있다.

Transport는 `mimeType`에 따라 처리한다.

---

# 17. FeedbackTransport

## 17.1 Purpose

Backend와 SDLFeedbackKit의 공식 경계다.

---

## 17.2 Proposed API

```swift
public protocol FeedbackTransport: Sendable {

    func submit(
        _ payload: FeedbackPayload
    ) async throws -> FeedbackSubmissionReceipt
}
```

초기 Architecture 문서의 `Void` 반환보다 Receipt 반환 구조를 권장한다.

이유:

* Backend Feedback ID 전달 가능
* Server timestamp 전달 가능
* Host callback에 결과 제공 가능
* 향후 Dashboard correlation 가능

---

# 18. FeedbackSubmissionReceipt

## 18.1 Purpose

Backend가 Feedback을 성공적으로 수신했음을 나타내는 값이다.

---

## 18.2 Proposed API

```swift
public struct FeedbackSubmissionReceipt:
    Sendable,
    Hashable {

    public let serverID: String?
    public let acceptedAt: Date?

    public init(
        serverID: String? = nil,
        acceptedAt: Date? = nil
    )
}
```

Backend가 별도 정보를 제공하지 않으면:

```swift
FeedbackSubmissionReceipt()
```

를 반환할 수 있다.

---

# 19. FeedbackSubmissionResult

## 19.1 Purpose

Host App의 `onSubmitted` callback에 전달하는 성공 결과다.

---

## 19.2 Proposed API

```swift
public struct FeedbackSubmissionResult: Sendable {

    public let clientID: UUID
    public let receipt: FeedbackSubmissionReceipt

    public init(
        clientID: UUID,
        receipt: FeedbackSubmissionReceipt
    )
}
```

이 Type은 Package 내부에서 생성한다.

---

# 20. Custom Transport Example

```swift
import Foundation
import SDLFeedbackKit

struct MyFeedbackTransport: FeedbackTransport {

    func submit(
        _ payload: FeedbackPayload
    ) async throws -> FeedbackSubmissionReceipt {

        let request = try makeRequest(from: payload)

        let (data, response) = try await URLSession.shared.data(
            for: request
        )

        try validate(response)

        let result = try JSONDecoder().decode(
            ServerResponse.self,
            from: data
        )

        return FeedbackSubmissionReceipt(
            serverID: result.id,
            acceptedAt: result.createdAt
        )
    }
}
```

SDLFeedbackKit은 `makeRequest`, JSON Schema, Endpoint 형태를 강제하지 않는다.

---

# 21. Transport Responsibilities

`FeedbackTransport` 구현체의 책임:

```text
Serialization
Network Request
Authentication
Backend-specific headers
Attachment Upload
Response validation
Response parsing
Backend error mapping
```

SDLFeedbackKit의 책임이 아니다.

---

# 22. Transport Threading Contract

`submit(_:)`은 어느 Actor에서도 호출될 수 있다고 가정한다.

Transport는 Main Thread 의존성을 가지면 안 된다.

UI 상태 변경은 SDLFeedbackKit 내부에서 `MainActor`로 처리한다.

---

# 23. FeedbackError

## 23.1 Purpose

Package 자체에서 발생하는 범용 오류를 표현한다.

---

## 23.2 Proposed API

```swift
public enum FeedbackError: Error, Sendable {

    case invalidInput
    case invalidEmail
    case attachmentTooLarge
    case unsupportedAttachment
    case attachmentProcessingFailed
    case submissionFailed
    case cancelled
}
```

---

# 24. Transport Errors

Transport가 던지는 Error를 SDLFeedbackKit이 모두 `FeedbackError`로 변환할 필요는 없다.

기본 정책:

```text
Transport Error
→ Package 내부에서 submission failure state로 처리
→ 사용자에게 안전한 일반 메시지 표시
```

필요하면 underlying error를 Logging 또는 callback으로 전달하는 별도 API를 향후 검토할 수 있다.

MVP에서는 사용자 UI에 Raw Error를 직접 표시하지 않는다.

---

# 25. Validation Contract

Submit 전에 SDLFeedbackKit은 다음을 검증한다.

## Message

```text
Required 여부
Minimum Length
Maximum Length
```

---

## Email

Email Field가 활성화되고 입력된 경우:

```text
Maximum Length
Basic Email Format
```

`isRequired == true`인 경우 Empty를 허용하지 않는다.

---

## Metadata

권장 기본 제한:

```text
Maximum Entry Count: 32
Maximum Key Length: 64
Maximum Value Length: 1,000
```

이 값은 내부 상수 또는 향후 Configuration으로 관리할 수 있다.

MVP에서는 Public Configuration Surface를 과도하게 늘리지 않기 위해 고정값으로 둘 수 있다.

---

## Attachment

```text
Supported image
Configured maximum dimensions
Configured maximum byte size
```

---

# 26. Server Validation Requirement

Client Validation은 보안 기능이 아니다.

README 및 Security 문서에서 다음을 명시한다.

> Every field in FeedbackPayload must be treated as untrusted input by the backend.

Backend는 반드시 자체 Validation을 수행한다.

---

# 27. Metadata API

## 27.1 Type

MVP에서는:

```swift
[String: String]
```

만 지원한다.

---

## 27.2 Rationale

지원하지 않는 형태:

```swift
[String: Any]
[AnyHashable: Any]
Arbitrary JSON tree
```

이유:

* Sendable 어려움
* Serialization 불명확
* Backend interoperability 감소
* Payload size 제어 어려움

---

# 28. Automatic Context API

자동 수집 Context는 Public API에서 별도 입력을 요구하지 않는 것이 기본이다.

Package 내부에서 자동 수집:

```text
App Version
Build Number
OS Version
Platform
Locale
```

---

# 29. Context Override Policy

MVP에서는 자동 수집값 Override API를 제공하지 않는 것을 권장한다.

이유:

* Public API 단순화
* 잘못된 Context 방지
* 일반 앱에서는 필요 없음

향후 Test Host나 특수 Environment 요구가 생기면 Advanced Configuration으로 추가할 수 있다.

---

# 30. Device Information

Device Model 제공 여부는 구현 단계에서 확정한다.

Public Payload에 포함할 경우 예:

```swift
public let deviceModel: String?
```

다만 초기 API에서는 생략하는 것을 우선 권장한다.

이유:

* Platform별 의미 차이
* Simulator 처리
* Privacy 설명 복잡성
* Bug report에 항상 필수는 아님

필요성이 확인된 후 추가하는 편이 안전하다.

---

# 31. Public Initialization Policy

Public Model별 생성 권한을 구분한다.

## 외부 개발자가 직접 생성

```text
FeedbackContext
FeedbackConfiguration
FeedbackCategory
MessageConfiguration
EmailFieldConfiguration
AttachmentConfiguration
FeedbackSubmissionReceipt
```

---

## Package가 생성

```text
FeedbackPayload
FeedbackAttachment
FeedbackSubmissionResult
```

필요하지 않은 Public Initializer는 제공하지 않는다.

---

# 32. Sendable Policy

Concurrency 경계를 넘을 가능성이 있는 Public Model은 가능한 한 `Sendable`을 채택한다.

대상:

```text
FeedbackContext
FeedbackConfiguration
FeedbackCategory
FeedbackPayload
FeedbackAttachment
FeedbackSubmissionReceipt
FeedbackSubmissionResult
FeedbackError
FeedbackPlatform
```

Swift Compiler의 Strict Concurrency 경고를 최대한 피하는 구조를 목표로 한다.

---

# 33. Codable Policy

모든 Public Model에 무조건 `Codable`을 붙이지 않는다.

특히 `FeedbackPayload`는 Attachment의 `Data` 때문에 Transport별 Serialization 전략이 다를 수 있다.

초기 권장:

```text
FeedbackCategory
FeedbackPlatform
```

정도만 필요 시 Codable.

`FeedbackPayload` 전체 Codable 지원은 실제 Integration 요구가 확인된 후 결정한다.

---

# 34. Hashable Policy

UI State나 Collection 식별에 실질적으로 필요한 Type만 `Hashable`을 채택한다.

예:

```text
FeedbackCategory
FeedbackContext
FeedbackSubmissionReceipt
```

Data를 포함하는 `FeedbackAttachment`와 전체 `FeedbackPayload`에 불필요하게 `Hashable`을 요구하지 않는다.

---

# 35. Default Configuration

기본값은 최소한의 설정으로 Production에서 사용할 수 있는 합리적인 수준이어야 한다.

권장 초기값:

```text
Categories
General Feedback
Bug Report
Feature Request
Other

Message
Required
1...5000 characters

Email
Enabled
Optional
Max 320

Attachment
Enabled
1 image
Max dimension 1800px
Max optimized size 1,000,000 bytes
≈ 1 MB
Compression 0.8

Cancel Button
Enabled

Auto Dismiss
Disabled
```

---

# 36. Why Auto Dismiss Defaults to False

Host Application이 Presentation ownership을 가진다.

Package 내부에서 무조건:

```swift
dismiss()
```

를 수행하면 다음 문제가 생길 수 있다.

```text
Custom Sheet flow
NavigationStack
macOS Window
Confirmation UI
Analytics callback
```

따라서 기본값은:

```text
FeedbackFormView는 host-owned presentation을 전제로 하며, 성공 시 dismissal은 `onSubmitted` callback에서 Host가 결정한다.
```

로 하고 Host가 callback에서 결정하는 방식을 우선한다.

자동 Dismiss 기능 자체가 실제로 필요하지 않다면 Public API에서 제거하는 것도 구현 전에 검토한다.

---

# 37. Cancellation API

FeedbackFormView는 Host Navigation을 직접 소유하지 않는다.

Cancel 발생 시:

```swift
onCancelled?()
```

를 호출한다.

Host는 필요하면:

```swift
dismiss()
```

를 수행한다.

---

# 38. Submission State

Submission State는 초기 버전에서 Public API로 직접 노출하지 않는다.

Package 내부 상태:

```text
idle
submitting
success
failure
```

Host가 상태를 직접 관찰해야 하는 실제 요구가 생길 경우 별도 callback 또는 state binding을 검토한다.

---

# 39. Presentation Examples

## Sheet

```swift
.sheet(isPresented: $showsFeedback) {
    FeedbackFormView(
        context: context,
        transport: transport,
        onSubmitted: { _ in
            showsFeedback = false
        },
        onCancelled: {
            showsFeedback = false
        }
    )
}
```

---

## NavigationStack

```swift
NavigationLink("Send Feedback") {
    FeedbackFormView(
        context: context,
        transport: transport
    )
}
```

---

## macOS Sheet

동일한 `FeedbackFormView` API를 사용한다.

Host App이 `.sheet` 또는 Window 구조를 결정한다.

---

# 40. Localization API

기본 UI 문구는 Package Resource에서 제공한다.

MVP에서는 모든 문구를 Configuration으로 Override하는 API는 제공하지 않는다.

과도한 API 예:

```swift
submitButtonTitle
messagePlaceholder
emailPlaceholder
successTitle
successMessage
attachmentTitle
```

이런 값을 초기부터 모두 노출하면 API Surface가 지나치게 커진다.

실제 수요가 생긴 후 `FeedbackStrings` 같은 별도 구조를 검토한다.

---

# 41. Category Localization

Custom Category는 개발자가 `title`을 직접 제공하므로 Localized String을 전달할 수 있다.

예:

```swift
FeedbackCategory(
    id: "bug",
    title: String(localized: "feedback.category.bug")
)
```

Default Category의 Package 내 Localization은 SDLFeedbackKit Resource가 담당한다.

---

# 42. Styling API

MVP에서는 Custom Theme API를 제공하지 않는다.

지원하지 않는 초기 API:

```text
Accent color override
Custom font
Custom background
Custom button style
Custom card style
Custom icon set
```

SwiftUI Environment와 Host App Theme를 자연스럽게 따르는 것을 우선한다.

---

# 43. Environment Behavior

가능한 한 다음 Host Environment를 따른다.

```text
Color Scheme
Dynamic Type
Locale
Accessibility settings
Tint
```

다만 Package UI 가독성을 보장하기 위해 필요한 최소 Layout 제어는 내부에서 수행한다.

---

# 44. Dependency Injection API

외부 개발자에게 노출되는 주요 DI 경계는:

```text
FeedbackTransport
```

하나로 제한한다.

`PlatformInfoProvider`, `ImageOptimizer`, Validator는 일반 Public API로 노출하지 않는다.

테스트를 위해 `@testable import` 또는 내부 Test Hook을 사용한다.

---

# 45. Advanced Injection

향후 외부 개발자가 Custom Image Processing을 요구하는 사례가 충분히 생길 경우:

```swift
FeedbackAttachmentProcessor
```

같은 Public Protocol을 추가할 수 있다.

하지만 MVP에서는 포함하지 않는다.

---

# 46. API Versioning

SDLFeedbackKit은 Semantic Versioning을 따른다.

## 0.x

Public API 변경 가능.

다만 실제 사용자 Migration 부담을 줄이기 위해 Breaking Change는 필요한 경우에만 수행한다.

---

## 1.0+

다음 변경은 Major Version 대상이다.

```text
Public Type 삭제
Public Method 삭제
Initializer Breaking Change
Protocol Requirement 추가
Public Property Type 변경
Behavior contract의 중대한 변경
```

---

# 47. Protocol Evolution Warning

`FeedbackTransport`는 가장 신중하게 관리해야 하는 Public API다.

예를 들어 v1.0 이후 다음 변경:

```swift
func submit(_ payload: FeedbackPayload) async throws
```

에서

```swift
func submit(
    _ payload: FeedbackPayload,
    options: SubmissionOptions
) async throws
```

로 바꾸면 모든 Transport 구현체가 깨진다.

따라서 Transport Protocol은 초기 설계에서 최대한 작게 유지한다.

---

# 48. Extension Strategy

새 기능이 필요한 경우 기존 Protocol Requirement를 추가하기보다 별도 Protocol 또는 Optional Capability로 확장하는 것을 우선 검토한다.

예:

```swift
protocol FeedbackTransport
```

를 유지하고 향후:

```swift
protocol FeedbackCancelableTransport
```

같은 별도 Capability를 고려할 수 있다.

필요하지 않으면 만들지 않는다.

---

# 49. API Naming Rules

Naming은 Swift API Design Guidelines를 따른다.

원칙:

```text
명확성 우선
불필요한 SDL prefix 반복 금지
Feedback domain 단어 사용
Backend provider 이름 금지
```

좋은 예:

```text
FeedbackContext
FeedbackTransport
FeedbackAttachment
FeedbackConfiguration
```

피할 예:

```text
SDLFeedbackKitContextObject
FeedbackManagerServiceImpl
CloudflarePayload
ServerFeedbackModel
```

---

# 50. Access Control Rules

Public으로 노출해야 하는 이유가 명확하지 않으면 `internal`이다.

원칙:

> Internal by default. Public by necessity.

특히 다음은 `internal` 유지:

```text
FeedbackFormModel
FeedbackPayloadBuilder
FeedbackValidator
DefaultImageOptimizer
AttachmentLoader
DefaultPlatformInfoProvider
SubmissionState
```

---

# 51. API Usage — Default

```swift
import SDLFeedbackKit

FeedbackFormView(
    context: FeedbackContext(
        appID: "my-app",
        appName: "My App"
    ),
    transport: MyFeedbackTransport()
)
```

---

# 52. API Usage — Custom Categories

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
        title: "Translation"
    )
]

let configuration = FeedbackConfiguration(
    categories: categories
)
```

---

# 53. API Usage — Disable Email

```swift
let configuration = FeedbackConfiguration(
    emailField: EmailFieldConfiguration(
        isEnabled: false
    )
)
```

---

# 54. API Usage — Disable Attachment

```swift
let configuration = FeedbackConfiguration(
    attachment: AttachmentConfiguration(
        isEnabled: false
    )
)
```

---

# 55. API Usage — App Metadata

```swift
let context = FeedbackContext(
    appID: "my-app",
    appName: "My App",
    metadata: [
        "screen": "editor",
        "documentType": "project",
        "datasetVersion": "2.1.0"
    ]
)
```

---

# 56. API Usage — Custom Attachment Policy

```swift
let configuration = FeedbackConfiguration(
    attachment: AttachmentConfiguration(
        isEnabled: true,
        maximumAttachmentBytes: 1_000_000,
        maximumImageDimension: 1_600,
        compressionQuality: 0.75
    )
)
```

---

# 57. API Usage — Submission Callback

```swift
FeedbackFormView(
    context: context,
    transport: transport,
    onSubmitted: { result in

        print(
            "Feedback submitted:",
            result.clientID
        )

        if let serverID = result.receipt.serverID {
            print("Server ID:", serverID)
        }

        dismiss()
    }
)
```

---

# 58. API Usage — Cancel Callback

```swift
FeedbackFormView(
    context: context,
    transport: transport,
    onCancelled: {
        dismiss()
    }
)
```

---

# 59. API Usage — Simple Transport Without Receipt Data

```swift
struct MyTransport: FeedbackTransport {

    func submit(
        _ payload: FeedbackPayload
    ) async throws -> FeedbackSubmissionReceipt {

        try await upload(payload)

        return FeedbackSubmissionReceipt()
    }
}
```

---

# 60. API Usage — Self-hosted Backend

SDLFeedbackKit에서 요구하는 것은 오직 `FeedbackTransport` 구현뿐이다.

예:

```text
SDLFeedbackKit
       ↓
MyFeedbackTransport
       ↓
https://feedback.example.com
       ↓
Developer Server
```

Backend technology는 API 계약에 영향을 주지 않는다.

---

# 61. API Non-Goals

MVP Public API에는 다음을 넣지 않는다.

```text
Backend URL
API key storage
Cloudflare adapter
D1 models
R2 models
Admin state
Ticket status
Feedback history
User account
Chat support
Push reply
Multiple images
Video attachment
Audio attachment
Log collection
Automatic screenshot capture
Offline queue
Theme engine
Custom image processor
```

---

# 62. Potential Future APIs

실제 수요가 확인된 이후 검토:

```text
FeedbackStrings
FeedbackAppearance
FeedbackAttachmentProcessor
Multiple Attachment Configuration
Additional Form Fields
Diagnostic Log Attachment
Screenshot Annotation
Submission Retry Policy
Offline Queue
visionOS
```

이 목록은 Roadmap이며 API 약속이 아니다.

---

# 63. Proposed Public API Surface v0.1

최종적으로 v0.1에서 외부에 노출하는 핵심 API는 다음 범위로 제한하는 것을 권장한다.

```text
FeedbackFormView

FeedbackContext

FeedbackConfiguration
MessageConfiguration
EmailFieldConfiguration
AttachmentConfiguration

FeedbackCategory

FeedbackTransport

FeedbackPayload
FeedbackAttachment
FeedbackPlatform

FeedbackSubmissionReceipt
FeedbackSubmissionResult

FeedbackError
```

---

# 64. Recommended API Freeze Order

구현 전 다음 순서로 확정한다.

```text
1. FeedbackTransport
2. FeedbackPayload
3. FeedbackAttachment
4. FeedbackContext
5. FeedbackConfiguration
6. FeedbackFormView initializer
7. Submission callbacks
```

특히 1~3은 Backend Adapter와 직접 연결되므로 먼저 안정화해야 한다.

---

# 65. API Review Checklist

Public API 추가 전 다음을 확인한다.

```text
이 기능이 모든 앱에 공통적으로 필요한가?

Host App에서 구현할 수 없는가?

Transport에서 처리하는 것이 더 자연스럽지 않은가?

Backend 책임은 아닌가?

Public이 아니라 internal이어도 되는가?

기본값으로 해결할 수 없는가?

이 API를 1.0 이후에도 유지할 자신이 있는가?
```

하나라도 명확하지 않다면 Public API 추가를 보류한다.

---

# 66. Final API Definition

SDLFeedbackKit의 핵심 사용 모델은 다음 한 문장으로 정의한다.

> The host app provides context and a transport; SDLFeedbackKit collects feedback, builds a payload, and submits it through that transport.

구조:

```text
Host App
   │
   ├─ FeedbackContext
   ├─ FeedbackConfiguration
   └─ FeedbackTransport
            │
            ▼
     FeedbackFormView
            │
            ▼
      FeedbackPayload
            │
            ▼
     FeedbackTransport
            │
            ▼
      Self-hosted Backend
```

SDLFeedbackKit의 Public API는 이 흐름을 지원하는 데 필요한 최소한의 타입만 노출한다.

---

**Project:** SDLFeedbackKit
**Document:** API_SPEC.md
**Owner:** SlowDevLabs
**Distribution:** Public GitHub / Swift Package Manager
**Backend Model:** Self-hosted
**API Status:** Draft
**Target Version:** v0.1
