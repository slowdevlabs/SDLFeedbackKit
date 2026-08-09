# SDLFeedbackKit — Project Brief

## 1. Overview

**Project Name**
SDLFeedbackKit

**Type**
Open-source Swift Package

**Primary Platforms**

* iOS
* macOS

**Framework**

* Swift
* SwiftUI
* Swift Package Manager

**License**
MIT License

**Distribution**
GitHub public repository

**Repository Name**
`slowdevlabs/SDLFeedbackKit`

---

## 2. Project Summary

SDLFeedbackKit은 iOS 및 macOS 앱에서 공통으로 사용할 수 있는 재사용 가능한 피드백 전송 UI 및 데이터 처리 Swift Package이다.

개별 앱마다 별도의 의견 보내기 기능을 구현하지 않고, 동일한 UI 구조와 데이터 모델을 공유할 수 있도록 설계한다.

SDLFeedbackKit 자체는 특정 서버, 데이터베이스, 클라우드 서비스에 종속되지 않는다.

패키지는 사용자 피드백 입력, 첨부 이미지 처리, 앱 및 시스템 정보 수집, 피드백 Payload 생성 및 전송 인터페이스 제공까지만 담당한다.

실제 데이터 저장과 백엔드 처리는 패키지를 사용하는 개발자가 자신의 환경에 맞게 직접 구현하는 **Self-hosted 구조**를 기본 원칙으로 한다.

---

## 3. Goals

SDLFeedbackKit의 주요 목표는 다음과 같다.

### 3.1 재사용 가능한 Feedback UI 제공

iOS 및 macOS 앱에서 공통으로 사용할 수 있는 SwiftUI 기반 의견 보내기 화면을 제공한다.

개발자는 패키지를 추가한 뒤 최소한의 설정만으로 Feedback UI를 앱에 연결할 수 있어야 한다.

---

### 3.2 Backend Agnostic

SDLFeedbackKit은 특정 Backend Provider에 종속되지 않는다.

다음과 같은 다양한 환경과 연결할 수 있어야 한다.

* Cloudflare Workers
* Supabase
* Firebase
* AWS
* Vapor
* Node.js
* PHP
* Custom REST API
* 기타 사용자 정의 Backend

이를 위해 실제 전송 계층은 Protocol 기반으로 설계한다.

---

### 3.3 Self-hosted First

SDLFeedbackKit은 SlowDevLabs가 운영하는 중앙 Feedback 서비스를 제공하지 않는다.

각 개발자가 자신의 서버 및 데이터 저장소를 직접 운영하는 것을 기본 모델로 한다.

예:

```text
App
 ↓
SDLFeedbackKit
 ↓
Custom FeedbackTransport
 ↓
Developer Backend
 ↓
Database / Object Storage
```

SlowDevLabs 내부 앱 역시 동일한 구조를 사용한다.

---

### 3.4 iOS + macOS 공통 지원

동일한 Feedback API와 데이터 모델을 사용하면서 플랫폼별 UI 차이는 SDLFeedbackKit 내부에서 처리한다.

예:

```text
iOS
→ PHPickerViewController / UIImagePickerController fallback

macOS
→ NSOpenPanel
```

앱은 플랫폼별 구현 세부사항을 알 필요가 없어야 한다.

---

### 3.5 Production-ready 기반

단순한 예제 UI Package가 아니라 실제 배포 앱에서 사용할 수 있는 수준을 목표로 한다.

SlowDevLabs가 출시한 iOS/macOS 앱들에 SDLFeedbackKit을 실제 적용하여 지속적으로 검증한다.

---

## 4. Non-Goals

SDLFeedbackKit은 다음 기능을 직접 제공하지 않는다.

### Backend Hosting

SlowDevLabs가 외부 개발자의 피드백을 저장하거나 관리하는 SaaS Backend는 초기 범위에 포함하지 않는다.

---

### Feedback Dashboard

관리자용 웹 Dashboard 또는 피드백 관리 시스템은 SDLFeedbackKit의 책임이 아니다.

---

### Database

D1, PostgreSQL, Firestore 등 특정 Database 구현을 패키지 내부에 포함하지 않는다.

---

### Object Storage

R2, S3 등 첨부 이미지 저장소도 SDLFeedbackKit의 책임이 아니다.

---

### Authentication Service

사용자 계정, 관리자 인증, API 인증 시스템을 SDLFeedbackKit에서 직접 제공하지 않는다.

---

### Analytics SDK

SDLFeedbackKit은 Analytics 또는 Crash Reporting SDK를 대체하지 않는다.

---

## 5. Core User Flow

기본적인 사용 흐름은 다음과 같다.

```text
사용자
 ↓
의견 보내기 선택
 ↓
FeedbackFormView
 ↓
유형 선택
 ↓
내용 입력
 ↓
선택적으로 이메일 입력
 ↓
선택적으로 이미지 첨부
 ↓
보내기
 ↓
Payload 생성
 ↓
FeedbackTransport
 ↓
Developer Backend
```

전송 성공 시 완료 상태를 표시하고 Feedback 화면을 종료할 수 있다.

전송 실패 시 오류 상태와 재시도 옵션을 제공한다.

---

## 6. Core Feedback Form

기본 Feedback Form은 다음 요소를 지원한다.

### Feedback Category

기본 Category 예:

* General Feedback
* Bug Report
* Feature Request
* Other

Category는 개발자가 변경하거나 확장할 수 있어야 한다.

---

### Message

사용자가 자유롭게 의견을 입력한다.

Message는 필수 입력값을 기본으로 한다.

---

### Email

사용자가 회신을 원하는 경우 선택적으로 이메일을 입력할 수 있다.

Email 입력 자체를 앱에서 비활성화할 수도 있어야 한다.

---

### Attachment

사용자는 선택적으로 이미지 1장을 첨부할 수 있다.

초기 버전에서는 Multiple Attachment를 지원하지 않는다.

---

## 7. Attachment Policy

기본 정책:

* 최대 이미지 1장
* 이미지 첨부는 선택 사항
* 긴 변 기준 이미지 축소
* 기본 최대 크기 약 1600~2000px
* JPEG 또는 지원되는 효율적 이미지 포맷 사용
* 압축 처리
* 전송 전 예상/최종 파일 크기 확인 가능
* 첨부 이미지 제거 가능

정확한 Compression Quality 및 Resolution Limit은 Configuration으로 조정할 수 있도록 설계한다.

---

## 8. Automatic Context Collection

SDLFeedbackKit은 개발자가 별도로 구현하지 않아도 기본적인 앱 및 시스템 정보를 수집할 수 있다.

예:

```text
App ID
App Name
App Version
Build Number
Platform
OS Version
Device Model / Hardware Information
Locale
```

수집 가능한 정보는 Apple Privacy 정책과 플랫폼 제한을 준수해야 한다.

불필요하거나 민감한 개인정보는 자동 수집하지 않는다.

---

## 9. FeedbackContext

각 앱은 SDLFeedbackKit에 자신의 앱 정보를 전달한다.

예:

```swift
FeedbackContext(
    appID: "doligo",
    appName: "돌리GO"
)
```

필요한 경우 추가 Metadata를 전달할 수 있다.

```swift
FeedbackContext(
    appID: "doligo",
    appName: "돌리GO",
    metadata: [
        "datasetVersion": "1.4.0",
        "mode": "stay"
    ]
)
```

---

## 10. Custom Metadata

SDLFeedbackKit은 앱별 비즈니스 정보를 직접 정의하지 않는다.

예를 들어 다음과 같은 특정 앱 필드는 SDLFeedbackKit 모델에 추가하지 않는다.

```text
destination
rouletteType
cityID
birthdayID
quizSessionID
```

대신 범용 Metadata 구조를 사용한다.

예:

```swift
metadata: [
    "destination": "Gangneung",
    "rouletteType": "stay"
]
```

이 원칙을 통해 SDLFeedbackKit이 특정 앱에 종속되는 것을 방지한다.

---

## 11. Feedback Payload

기본 Payload는 다음과 같은 개념 구조를 가진다.

```json
{
  "appId": "doligo",
  "appName": "돌리GO",
  "appVersion": "1.3.0",
  "buildNumber": "42",

  "platform": "iOS",
  "osVersion": "26.0",

  "category": "bug",
  "message": "Feedback message",

  "email": "optional@example.com",

  "metadata": {
    "datasetVersion": "1.4.0"
  }
}
```

Attachment는 Backend 구현 방식에 따라 Multipart Upload 또는 별도 Binary Data 전달 방식을 사용할 수 있다.

최종 Payload Schema는 구현 단계에서 별도 Specification으로 정의한다.

---

## 12. Transport Architecture

SDLFeedbackKit은 전송 서버를 직접 알지 않는다.

전송 인터페이스만 정의한다.

개념 예:

```swift
public protocol FeedbackTransport {
    func submit(
        _ feedback: FeedbackPayload
    ) async throws
}
```

개발자는 자신의 Backend에 맞는 Transport를 구현한다.

예:

```text
CloudflareFeedbackTransport
SupabaseFeedbackTransport
FirebaseFeedbackTransport
MyCustomFeedbackTransport
```

---

## 13. SlowDevLabs Production Architecture

SlowDevLabs 자체 앱에서는 다음 구조를 사용할 예정이다.

```text
SlowDevLabs App
 ↓
SDLFeedbackKit
 ↓
SlowDevFeedbackTransport
 ↓
Cloudflare Worker
 ↓
D1
 +
R2
```

### D1

Feedback 본문 및 Metadata 저장.

예:

```text
id
app_id
app_version
platform
os_version
category
message
email
attachment_key
metadata
created_at
```

---

### R2

첨부 이미지를 저장한다.

D1에는 Binary 데이터를 직접 저장하지 않고 R2 Object Key 또는 이에 대응하는 식별 정보만 기록한다.

---

## 14. Security Principles

SDLFeedbackKit은 공개 Source Code이므로 Client Code 자체를 보안 경계로 사용하지 않는다.

기본 원칙:

> Client code must always be considered public.

다음 정보는 SDLFeedbackKit Source Code 또는 앱 내부에 Secret 형태로 포함하지 않는다.

* Cloudflare API Token
* Database credentials
* R2 credentials
* Private API Key
* Signing secrets
* Administrator credentials

---

### Public Submit Endpoint

Feedback Submission Endpoint는 외부에서 발견될 수 있다는 것을 전제로 설계해야 한다.

Server Side에서 다음 방어를 담당한다.

* Rate Limiting
* Payload Validation
* Message Length Limit
* Metadata Size Limit
* Attachment Size Limit
* File Type Validation
* Spam / Abuse Prevention
* Parameterized Database Query
* Server-generated Attachment ID
* Error Sanitization

---

### Client API Keys

앱 Binary 내부에 저장하는 고정 API Key는 Secret으로 간주하지 않는다.

앱에 포함된 Key는 추출될 수 있다는 것을 전제로 한다.

Feedback 제출 API의 보안은 Client Secret이 아니라 Server-side Validation과 Abuse Protection을 중심으로 설계한다.

---

## 15. Privacy Principles

SDLFeedbackKit은 최소 정보 수집을 기본 원칙으로 한다.

자동 수집 대상에 다음과 같은 개인정보를 포함하지 않는다.

* 사용자 이름
* 연락처
* 위치 정보
* 광고 식별자
* 사진 라이브러리 전체 정보
* 사용자 계정 정보

Email과 Attachment는 사용자가 명시적으로 입력하거나 선택한 경우에만 전달한다.

개발자는 SDLFeedbackKit을 사용하는 앱의 Privacy Policy에서 Feedback을 통해 수집되는 정보를 적절히 설명해야 한다.

---

## 16. Accessibility

SDLFeedbackKit은 SwiftUI 기본 접근성 기능을 최대한 활용한다.

지원 대상:

* VoiceOver
* Dynamic Type
* Reduce Motion
* Light Mode
* Dark Mode
* Keyboard Navigation where applicable
* macOS Accessibility

Feedback 기능이 앱의 핵심 기능은 아니더라도 접근성 품질을 낮추지 않는 것을 원칙으로 한다.

---

## 17. Initial Package Structure

초기 구조 예:

```text
SDLFeedbackKit/
│
├─ Package.swift
├─ README.md
├─ LICENSE
├─ CHANGELOG.md
│
├─ Sources/
│  └─ SDLFeedbackKit/
│
│     ├─ UI/
│     │  ├─ FeedbackFormView.swift
│     │  ├─ FeedbackCategoryView.swift
│     │  ├─ FeedbackAttachmentView.swift
│     │  └─ FeedbackSubmissionView.swift
│     │
│     ├─ Models/
│     │  ├─ FeedbackCategory.swift
│     │  ├─ FeedbackContext.swift
│     │  ├─ FeedbackPayload.swift
│     │  └─ FeedbackAttachment.swift
│     │
│     ├─ Services/
│     │  ├─ FeedbackTransport.swift
│     │  ├─ PlatformInfoProvider.swift
│     │  └─ ImageOptimizer.swift
│     │
│     └─ Configuration/
│        └─ FeedbackConfiguration.swift
│
├─ Tests/
│  └─ SDLFeedbackKitTests/
│
├─ Examples/
│  ├─ iOSExample/
│  └─ macOSExample/
│
└─ Docs/
```

구현 과정에서 파일 구조는 변경될 수 있다.

---

## 18. Public API Direction

SDLFeedbackKit의 최종 목표는 앱에서 복잡한 설정 없이 사용할 수 있는 API를 제공하는 것이다.

개념 예:

```swift
FeedbackFormView(
    context: FeedbackContext(
        appID: "my-app",
        appName: "My App"
    ),
    transport: MyFeedbackTransport()
)
```

또는 Configuration을 사용하는 경우:

```swift
FeedbackFormView(
    configuration: FeedbackConfiguration(
        context: context,
        transport: transport
    )
)
```

구체적인 Public API는 Implementation 단계에서 사용성을 검증하며 확정한다.

---

## 19. Configuration

개발자는 필요에 따라 다음 항목을 설정할 수 있어야 한다.

* Feedback Categories
* Email Field Enabled / Disabled
* Attachment Enabled / Disabled
* Maximum Attachment Size
* Maximum Image Dimension
* Compression Quality
* Custom Metadata
* Form Title
* Submit Button Label
* Completion Behavior

가능한 한 기본값을 제공하여 최소 설정으로 사용할 수 있게 한다.

---

## 20. Localization

초기 SDLFeedbackKit은 Localization 가능한 구조로 설계한다.

패키지 내부 UI 문자열을 하드코딩하지 않는다.

기본 제공 언어 범위는 구현 단계에서 결정하며, 최소한 영어를 기본 언어로 지원한다.

외부 개발자가 자신의 Localization을 적용할 수 있는 확장 구조도 고려한다.

---

## 21. GitHub Distribution

SDLFeedbackKit은 GitHub Public Repository로 배포한다.

예:

```text
github.com/slowdevlabs/SDLFeedbackKit
```

사용자는 Swift Package Manager를 통해 프로젝트에 추가할 수 있다.

```text
File
→ Add Package Dependencies
→ SDLFeedbackKit GitHub URL
```

Semantic Versioning을 사용한다.

예:

```text
0.1.0
0.2.0
0.3.0
1.0.0
```

초기 Public API가 안정화되기 전까지는 `0.x` 버전을 유지한다.

---

## 22. Open Source Policy

SDLFeedbackKit은 MIT License 기반 Open Source 프로젝트로 운영한다.

허용 범위:

* 개인 프로젝트
* 상업 앱
* 무료 앱
* 수정
* 재배포

License 조건에 따른 Copyright 및 License 고지는 유지해야 한다.

---

## 23. Example Backend

SDLFeedbackKit 자체는 Backend를 제공하지 않지만, 사용자가 쉽게 시작할 수 있도록 Backend Example 또는 Reference Implementation을 제공하는 것을 고려한다.

첫 번째 Reference Backend 후보:

```text
Cloudflare Workers
+
D1
+
R2
```

단, Example Backend는 SDLFeedbackKit의 필수 의존성이 아니다.

사용자는 이를 사용하지 않고 자신만의 Backend를 구현할 수 있다.

---

## 24. Design Principles

SDLFeedbackKit 개발 과정에서 다음 원칙을 우선한다.

### Lightweight

불필요한 Dependency를 추가하지 않는다.

가능하면 Apple Native Framework만 사용한다.

---

### Native

iOS와 macOS의 기본 Interaction과 UI Convention을 따른다.

---

### Extensible

앱별 요구사항을 Metadata와 Configuration으로 확장할 수 있도록 한다.

---

### Backend Independent

특정 Cloud Provider 또는 API 구조를 강제하지 않는다.

---

### Secure by Design

Client Secret에 의존하지 않는다.

Server가 신뢰 경계를 담당한다.

---

### Privacy-conscious

필요 이상의 사용자 정보를 자동 수집하지 않는다.

---

### Simple Integration

패키지 추가 후 최소한의 코드로 Feedback 기능을 사용할 수 있어야 한다.

---

## 25. MVP Scope

SDLFeedbackKit v0.1의 목표 범위:

* Swift Package 구성
* iOS 지원
* macOS 지원
* SwiftUI Feedback Form
* 기본 Category
* Message 입력
* 선택적 Email
* 이미지 1장 첨부
* 이미지 Resize 및 Compression
* FeedbackContext
* Automatic App/System Context
* Custom Metadata
* FeedbackPayload
* FeedbackTransport Protocol
* Async/Await Submission
* Loading / Success / Error State
* Light / Dark Mode
* 기본 Accessibility
* Unit Tests
* iOS Example App
* macOS Example App
* README
* MIT License

---

## 26. Post-MVP Candidates

초기 버전에는 포함하지 않지만 향후 검토할 수 있는 기능:

* Multiple Attachments
* Log File Attachment
* Screenshot Annotation
* Automatic Current Screen Capture
* Custom Form Fields
* Custom Feedback Categories with Icons
* Retry Queue
* Offline Submission Queue
* Backend Adapter Packages
* Cloudflare Reference Backend
* Feedback Dashboard Reference Project
* SwiftUI Theme Customization
* UIKit / AppKit Wrapper
* visionOS 지원

이 기능들은 실제 사용 요구가 확인된 후 추가한다.

---

## 27. Success Criteria

SDLFeedbackKit의 초기 성공 기준은 다운로드 수나 GitHub Star가 아니다.

우선 다음 조건을 만족하는 것을 목표로 한다.

1. SlowDevLabs의 서로 다른 iOS/macOS 앱에서 동일 Package 사용
2. 앱별 Feedback UI 중복 코드 제거
3. 앱별 Custom Metadata 전달 가능
4. Backend 교체 없이 Package 수정이 필요하지 않는 구조 확보
5. 외부 개발자가 README만 보고 자신의 Backend와 연결 가능
6. Public API가 단순하고 이해하기 쉬움
7. 특정 SlowDevLabs 앱에 종속된 코드가 Package에 존재하지 않음

---

## 28. Long-Term Direction

SDLFeedbackKit의 장기 목표는 대규모 고객지원 플랫폼이 되는 것이 아니다.

목표는 다음과 같다.

> iOS와 macOS 개발자가 자신의 앱에 작고 안전하며 네이티브한 Feedback 기능을 빠르게 추가할 수 있도록 하는 경량 Swift Package.

SlowDevLabs의 실제 앱 개발 과정에서 필요한 기능을 우선적으로 개선하면서, 다른 Swift 개발자도 자유롭게 사용할 수 있는 범용 Open Source Package로 유지한다.

---

## 29. One-line Definition

> **SDLFeedbackKit is a lightweight, backend-agnostic SwiftUI feedback package for iOS and macOS.**

---

**Project:** SDLFeedbackKit
**Owner:** SlowDevLabs
**Distribution:** GitHub / Swift Package Manager
**License:** MIT
**Backend Model:** Self-hosted
**Status:** Planning
