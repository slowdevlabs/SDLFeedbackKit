# SDLFeedbackKit — Security Guide

## 1. Document Purpose

이 문서는 `SDLFeedbackKit`을 안전하게 사용하기 위한 보안 원칙과 권장사항을 정의한다.

SDLFeedbackKit은 공개 GitHub Repository로 배포되는 Open Source Swift Package이며, 실제 Feedback Backend는 각 개발자가 직접 운영하는 **Self-hosted 구조**를 전제로 한다.

이 문서의 핵심 원칙은 다음과 같다.

> SDLFeedbackKit과 Host App의 Client Code는 신뢰 경계가 아니다.

즉, 앱에 포함된 값과 Feedback 요청은 모두 외부에서 분석·변조·재현될 수 있다고 가정해야 한다.

---

# 2. Security Model

SDLFeedbackKit의 기본 구조:

```text
Host App
   ↓
SDLFeedbackKit
   ↓
FeedbackTransport
   ↓
Developer Backend
   ↓
Database / Object Storage
```

보안 경계는 다음과 같이 본다.

```text
Untrusted
────────────────────────
SDLFeedbackKit
Host App Binary
FeedbackPayload
Metadata
Attachment
Client Headers
Client-generated ID
App-provided API values

Trusted Boundary
────────────────────────
Developer Backend
Server-side Secrets
Database Credentials
Storage Credentials
Admin Authentication
Server-side Validation
```

---

# 3. Public Source Code Is Not a Security Risk by Itself

SDLFeedbackKit의 Source Code가 공개된다는 사실 자체는 보안 문제가 아니다.

외부 사용자는 다음 내용을 알 수 있다.

* Feedback Form 구조
* Payload 필드
* Attachment 처리 방식
* 이미지 압축 정책
* Client-side Validation 규칙
* Transport Protocol 구조

이러한 정보는 Secret으로 취급하지 않는다.

모바일 및 데스크탑 앱 Binary 역시 분석될 수 있으므로 Client 구현 자체를 숨기는 것으로 보안을 확보하려 해서는 안 된다.

---

# 4. Never Store Secrets in SDLFeedbackKit

SDLFeedbackKit Source Code에는 Secret을 포함하지 않는다.

금지 예:

```text
Cloudflare API Token
AWS Access Key
Supabase Service Role Key
Firebase Admin Credential
Database Password
R2 Secret
Private Signing Key
Admin Token
Private API Secret
```

다음과 같은 형태도 금지한다.

```swift
let apiSecret = "super-secret-key"
```

또는:

```swift
headers["X-Private-Key"] = "..."
```

---

# 5. Host App Secrets Are Also Not Safe

Secret을 SDLFeedbackKit이 아니라 Host Application에 넣는다고 해서 안전해지는 것은 아니다.

예:

```swift
let feedbackAPIKey = "my-secret"
```

앱 Binary에 포함된 고정 Secret은 추출될 수 있다.

따라서:

> Client-side fixed API keys must not be treated as secrets.

를 기본 원칙으로 한다.

---

# 6. Endpoint URLs Are Not Secrets

Feedback Endpoint URL은 Secret이 아니다.

예:

```text
https://feedback.example.com/v1/feedback
```

이 URL이 알려져도 Backend가 안전해야 한다.

URL을 숨기는 것으로 Abuse를 방지하려 하지 않는다.

---

# 7. Public Submission Endpoint Assumption

Feedback Submission Endpoint는 사실상 Public Endpoint로 간주한다.

예:

```text
POST /v1/feedback
```

누구나 Request를 재현할 수 있다는 가정 아래 설계해야 한다.

따라서 Backend는 반드시 다음을 구현해야 한다.

```text
Rate limiting
Payload validation
Request size limit
Attachment validation
Spam mitigation
Safe error handling
Abuse monitoring
```

---

# 8. Client Validation Is UX Only

SDLFeedbackKit은 다음과 같은 Client-side Validation을 제공할 수 있다.

```text
Required message
Email format
Message length
Metadata limits
Attachment size
Supported image type
```

하지만 이는 사용자 경험을 위한 것이다.

보안 목적으로 신뢰해서는 안 된다.

Backend는 동일하거나 더 강한 Validation을 다시 수행해야 한다.

---

# 9. Server-side Validation Requirements

Backend는 최소한 다음 항목을 검증해야 한다.

```text
Required fields
String length
Allowed field types
Metadata entry count
Metadata key/value length
Total metadata size
Attachment byte size
Attachment content type
Attachment binary signature
Image decode validity
Image dimensions
Request body size
```

---

# 10. Treat All Payload Fields as Untrusted

다음 모든 값은 신뢰하지 않는다.

```text
clientID
appID
appName
appVersion
buildNumber
platform
osVersion
localeIdentifier
category
message
email
metadata
attachment
filename
mimeType
pixelWidth
pixelHeight
createdAt
```

SDLFeedbackKit이 자동으로 생성한 값도 Server에서는 Untrusted Input이다.

Client Binary를 수정하거나 요청을 직접 재생성할 수 있기 때문이다.

---

# 11. appID Is Not Authentication

`appID`는 앱 구분용 Identifier일 뿐이다.

예:

```text
doligo
timetape
symbolicdrop
```

Backend에서:

```text
appID == "paid-app"
```

라는 이유로 권한을 부여해서는 안 된다.

`appID`는 Routing, Filtering, Reporting 용도로만 사용한다.

---

# 12. clientID Is Not Authentication

`clientID`는 중복 감지와 Log Correlation을 위한 Client-generated Identifier다.

다음 용도로 사용할 수 있다.

```text
Idempotency
Retry correlation
Duplicate detection
Attachment correlation
```

하지만 인증 수단으로 사용하지 않는다.

---

# 13. Recommended Idempotency Strategy

중복 전송 방지를 원한다면 Backend에서:

```text
appID + clientID
```

조합을 Unique Key 후보로 사용할 수 있다.

예:

```text
UNIQUE(app_id, client_id)
```

단, 동일 Client ID를 악의적으로 재사용할 수 있으므로 이는 Security Identity가 아니라 Submission Correlation 수단이다.

---

# 14. Request Size Limits

Backend는 전체 Request 크기에 명시적인 제한을 둔다.

SDLFeedbackKit v0.1의 기본 Attachment 정책:

```text
Maximum optimized attachment
1,000,000 bytes
```

Reference Backend에서는 Text, Metadata, multipart overhead 등을 고려해 전체 Request 상한을 별도로 설정한다.

권장 초기 범위:

```text
2 MB ~ 3 MB
```

실제 Backend 환경에 맞게 조정한다.

---

# 15. Attachment Size Validation

Client에서 Attachment를 1MB 이하로 최적화했더라도 Backend가 다시 검사한다.

기본 제한 예:

```text
Attachment binary
≤ 1,000,000 bytes
```

Client에서 전달한 `byteCount` 값은 신뢰하지 않고 실제 Binary Size를 검사한다.

---

# 16. MIME Type Validation

Client가 제공하는:

```text
image/jpeg
image/png
```

등의 MIME Type만 신뢰해서는 안 된다.

Backend는 가능한 경우 실제 Binary Signature 또는 안전한 Image Decoder를 사용해 파일 형식을 검증한다.

---

# 17. Filename Safety

Client filename을 Storage Object Key 또는 Local File Path로 직접 사용하지 않는다.

위험한 예:

```text
../../../admin/config
```

또는 충돌 가능한:

```text
feedback.jpg
```

를 그대로 Storage Key로 사용하면 안 된다.

Server에서 자체 Key를 생성한다.

권장:

```text
attachments/<server-feedback-id>/image.jpg
```

---

# 18. Path Traversal Protection

Backend에서 사용자 입력 filename 또는 Metadata를 File Path 구성에 직접 연결하지 않는다.

금지 예:

```text
/storage/{clientFilename}
```

항상 Server-generated Identifier를 사용한다.

---

# 19. Image Decode Validation

파일 Extension과 MIME Type이 올바르더라도 실제 Binary가 이미지가 아닐 수 있다.

가능하면 Backend에서 안전한 Decoder 또는 파일 검증 로직을 사용한다.

손상되거나 의심스러운 파일은 저장을 거부할 수 있다.

---

# 20. Image Dimensions

비정상적으로 큰 Pixel Dimension을 가진 이미지는 Memory 및 Processing 공격에 사용될 수 있다.

예:

```text
100000 × 100000
```

따라서 Backend에서도 합리적인 Pixel Dimension 제한을 둘 수 있다.

Client가 전달한 `pixelWidth`와 `pixelHeight`는 검증 정보가 아니라 참고 정보다.

---

# 21. Metadata Limits

기본 SDLFeedbackKit Metadata 권장값:

```text
Maximum entries
32

Maximum key length
64 characters

Maximum value length
1,000 characters

Recommended total size
~32 KB
```

Backend에서도 동일하거나 더 작은 제한을 적용한다.

---

# 22. Metadata Must Not Control Authorization

다음 같은 Metadata는 신뢰하지 않는다.

```swift
[
    "isAdmin": "true",
    "isPremium": "true",
    "userRole": "owner"
]
```

Custom Metadata는 Debugging Context일 뿐이다.

권한, 결제 상태, 사용자 Identity 판단에 사용하지 않는다.

---

# 23. Sensitive Metadata

Host App 개발자는 Metadata에 Secret 또는 민감정보를 넣지 않아야 한다.

금지 예:

```text
Password
Authentication token
Refresh token
Session cookie
Private API key
Full payment information
Private encryption key
```

---

# 24. Personal Data Minimization

SDLFeedbackKit은 자동으로 다음 데이터를 수집하지 않는다.

```text
Exact location
Contacts
Apple ID
Advertising Identifier
Device serial number
Installed apps
Photo library inventory
User account credentials
```

Feedback 조사에 필요한 최소한의 기술 정보만 수집한다.

---

# 25. Email Privacy

Email은 사용자가 직접 입력한 경우에만 전송한다.

Host App은 Privacy Policy에서 Feedback을 통해 Email을 수집할 수 있음을 적절히 설명해야 한다.

Backend는 Email을 일반 로그에 불필요하게 출력하지 않는 것을 권장한다.

---

# 26. Attachment Privacy

Attachment는 사용자가 명시적으로 선택한 이미지만 허용한다.

SDLFeedbackKit v0.1은 자동 Screenshot 캡처를 하지 않는다.

패키지는 이미지 재인코딩을 통해 가능하면 다음 Metadata를 제거한다.

```text
GPS
EXIF camera data
Original local path
Camera model
Original filename-related metadata
```

---

# 27. Re-encoding Does Not Replace Server Validation

Client가 EXIF 제거 및 JPEG 재인코딩을 수행하더라도 Server는 항상 Client Binary를 신뢰하지 않는다.

공격자는 SDLFeedbackKit을 사용하지 않고 직접 Request를 만들 수 있기 때문이다.

---

# 28. Rate Limiting

Public Feedback Endpoint에는 Rate Limit을 적용한다.

정확한 수치는 서비스 특성에 맞게 결정한다.

예를 들어 다음 요소를 조합할 수 있다.

```text
IP
appID
User agent
Time window
Client ID
Server-generated abuse signals
```

단일 Client 값에만 의존하지 않는다.

---

# 29. IP-based Rate Limiting Limitations

IP Rate Limit만 사용하면 다음 환경에서 정상 사용자가 영향을 받을 수 있다.

```text
Corporate NAT
Mobile carrier NAT
Public Wi-Fi
Shared network
```

따라서 Rate Limiting은 과도하게 공격적으로 설정하지 않는다.

---

# 30. Spam and Abuse Prevention

Feedback Endpoint는 다음 Abuse에 노출될 수 있다.

```text
Automated spam
Repeated submissions
Large payload attempts
Invalid image uploads
Offensive content
Storage abuse
Database flooding
```

초기 Backend에서는 최소한 다음을 권장한다.

```text
Rate limit
Body size limit
Field validation
Attachment size/type validation
Duplicate detection
Basic abuse logging
```

---

# 31. CAPTCHA

Native App Feedback Flow에 CAPTCHA를 기본으로 요구하지 않는다.

사용자 경험을 크게 해칠 수 있기 때문이다.

실제 Abuse가 발생할 경우 Backend 수준에서 추가 방어를 검토한다.

---

# 32. CORS Is Not a Security Boundary

CORS는 Browser 보안 정책이다.

Native iOS/macOS App이나 직접 작성한 HTTP Client는 CORS 제약을 받지 않는다.

따라서:

```text
Access-Control-Allow-Origin
```

설정만으로 Feedback Endpoint를 보호할 수 있다고 생각해서는 안 된다.

---

# 33. User-Agent Is Not Authentication

Client가 전송하는 User-Agent 또는 Custom Header 역시 위조 가능하다.

예:

```text
X-App-ID
X-App-Version
User-Agent
```

이러한 Header는 Routing 또는 Debugging에는 사용할 수 있지만 인증 수단으로 사용하지 않는다.

---

# 34. TLS

Feedback Backend는 HTTPS만 사용한다.

권장:

```text
TLS via HTTPS
```

HTTP Endpoint는 Production에서 사용하지 않는다.

---

# 35. Certificate Validation

SDLFeedbackKit Core는 Network 구현을 직접 제공하지 않는다.

Transport 개발자는 일반적인 `URLSession`의 정상적인 TLS Certificate Validation을 유지한다.

Production에서 임의로 Certificate Validation을 우회하지 않는다.

---

# 36. Authentication

SDLFeedbackKit은 Backend Authentication 방식을 강제하지 않는다.

Feedback 제출 Endpoint는 Public Submission을 전제로 할 수 있다.

인증이 필요한 앱이라면 Transport에서 해당 App의 기존 User Authentication Context를 사용할 수 있다.

단, SDLFeedbackKit 자체가 인증 시스템을 제공하지 않는다.

---

# 37. Anonymous Feedback

SDLFeedbackKit은 Anonymous Feedback을 지원하는 구조를 기본으로 한다.

즉 사용자 계정이 없어도 Feedback을 전송할 수 있다.

이는 제품 정책에 따라 Host App이 결정한다.

---

# 38. Admin APIs Must Be Separate

Submission API와 관리자 API를 명확히 분리한다.

예:

```text
POST /v1/feedback
```

은 Public Submission Endpoint일 수 있다.

하지만:

```text
GET /v1/admin/feedback
DELETE /v1/admin/feedback/:id
PATCH /v1/admin/feedback/:id
```

같은 API는 반드시 별도의 강한 인증을 사용한다.

---

# 39. Never Expose Admin Credentials to App

Admin API Token을 iOS/macOS App에 넣지 않는다.

App은 Feedback 제출만 수행한다.

관리자 조회, 삭제, 상태 변경 기능은 별도의 안전한 관리 환경에서 수행한다.

---

# 40. Database Safety

SQL 기반 Backend에서는 Parameter Binding을 사용한다.

금지:

```text
"INSERT INTO feedback VALUES ('" + message + "')"
```

권장:

```text
Prepared statement
Parameterized query
```

---

# 41. HTML / Dashboard Rendering

Feedback Message와 Metadata는 사용자 입력이다.

관리자 Dashboard에서 HTML로 렌더링할 경우 XSS 방지를 위해 Escape해야 한다.

예:

```text
<script>alert(1)</script>
```

같은 입력을 코드로 실행해서는 안 된다.

---

# 42. Markdown Rendering

향후 Dashboard가 Markdown을 지원하더라도 Raw HTML 또는 Unsafe Link Rendering을 신뢰하지 않는다.

필요하면 Sanitization 정책을 별도로 적용한다.

---

# 43. Error Responses

Backend는 내부 구현 정보를 Client에 노출하지 않는다.

피해야 할 응답:

```text
SQL error
Database path
Stack trace
R2 credential detail
Worker internal exception
```

Client에는 일반화된 오류만 반환한다.

예:

```json
{
  "error": "submission_failed"
}
```

---

# 44. Client Error Display

SDLFeedbackKit 역시 Backend Raw Error를 사용자에게 그대로 보여주지 않는다.

사용자에게는:

```text
Couldn't send feedback.
Please try again.
```

처럼 안전한 메시지를 표시한다.

---

# 45. Logging Policy

Server 로그에 다음 정보를 무조건 기록하지 않는다.

```text
Full feedback message
Email
Attachment data
Sensitive metadata
Auth tokens
Cookies
```

필요한 Debugging 정보만 기록한다.

---

# 46. Safe Logging Example

권장:

```text
feedback request rejected
appID=doligo
reason=attachment_too_large
size=1452843
```

주의:

```text
message=<full user message>
email=<full email>
```

등을 기본 로그에 남기지 않는다.

---

# 47. Client Logging

SDLFeedbackKit 및 Transport에서도 Production 기본 로그로 다음 데이터를 출력하지 않는다.

```text
Full message
Email address
Image binary
Potentially sensitive metadata
```

---

# 48. Redacted Debug Description

Payload Debug 출력이 필요하다면:

```text
clientID
appID
categoryID
messageLength
emailPresent
attachmentBytes
metadataCount
```

정도의 Non-sensitive summary를 권장한다.

---

# 49. Data Retention

SDLFeedbackKit은 Server-side Data Retention을 결정하지 않는다.

Self-hosted Backend 운영자가 직접 정책을 결정한다.

권장:

* 필요한 기간만 저장
* 오래된 Attachment 정리
* 불필요한 Email 장기 보관 지양
* 삭제 정책 문서화

---

# 50. User Data Deletion

Feedback에 개인 식별 가능한 정보가 포함될 수 있는 경우 운영자는 해당 지역의 Privacy 법규 및 자신의 Privacy Policy에 따라 삭제 요청 처리 방식을 준비해야 한다.

SDLFeedbackKit 자체는 삭제 API를 제공하지 않는다.

---

# 51. Temporary Client Data

SDLFeedbackKit v0.1에서는 Attachment를 Persistent Cache에 저장하지 않는 것을 기본으로 한다.

Processing 및 Submission에 필요한 기간 동안만 메모리에 유지한다.

---

# 52. Offline Storage

MVP에서는 Offline Submission Queue를 제공하지 않는다.

이는 민감한 Feedback 내용과 Attachment가 기기에 장기간 남는 것을 방지하는 효과도 있다.

---

# 53. Retry Security

Network Retry 시 이미 생성한 동일 Payload를 재사용할 수 있다.

자동 무한 Retry는 하지 않는다.

기본적으로 사용자가 명시적으로 Retry하도록 한다.

---

# 54. Dependency Security

SDLFeedbackKit은 외부 Dependency를 최소화한다.

가능하면 Apple Native Framework만 사용한다.

이유:

```text
Smaller attack surface
Lower supply-chain risk
Simpler maintenance
```

---

# 55. Third-party Dependencies

향후 외부 Dependency를 추가할 경우 다음을 검토한다.

```text
License
Maintenance status
Security history
Transitive dependencies
Necessity
Binary inclusion
```

단순 편의를 위해 대형 Networking/Image Library를 추가하지 않는다.

---

# 56. Package Integrity

사용자는 Swift Package Manager를 통해 정식 SDLFeedbackKit Repository와 Version Tag를 사용하는 것을 권장한다.

Release는 Semantic Versioning을 따른다.

예:

```text
0.1.0
0.2.0
1.0.0
```

---

# 57. GitHub Repository Security

Public Repository에는 다음을 Commit하지 않는다.

```text
.env
Cloudflare credentials
API tokens
Private certificates
Provisioning secrets
Database dumps containing user data
Production attachment samples
Real user feedback
```

---

# 58. .gitignore

Repository의 `.gitignore`는 개발 환경의 Secret 및 Build Artifacts가 실수로 Commit되지 않도록 구성한다.

---

# 59. Example Backend Security

Reference Backend Example을 제공하더라도 실제 Credential을 포함하지 않는다.

예:

```text
wrangler.example.jsonc
```

또는 환경변수 이름만 제공한다.

실제 값은 개발자가 자신의 환경에서 설정하도록 한다.

---

# 60. Environment Variables

Server-side Secret은 Backend Environment Variable 또는 Secret Store에 저장한다.

예:

```text
Cloudflare Worker Secrets
AWS Secret Manager
Hosting platform environment secrets
```

---

# 61. Default Backend Must Not Exist

SDLFeedbackKit에는 SlowDevLabs가 운영하는 기본 Submission Endpoint를 포함하지 않는다.

즉 설치만으로 외부 개발자의 Feedback이 SlowDevLabs 서버로 전송되는 구조를 만들지 않는다.

---

# 62. Self-hosted Responsibility

SDLFeedbackKit 사용자는 자신의 Backend에 대해 다음 책임을 가진다.

```text
Security
Availability
Privacy
Data retention
Abuse prevention
Database protection
Storage protection
Legal compliance
```

SDLFeedbackKit은 Client-side Feedback SDK일 뿐이다.

---

# 63. SlowDevLabs Internal Backend

SlowDevLabs 자체 앱에서 사용하는 Backend 구현은 Public SDLFeedbackKit Repository와 분리한다.

예:

```text
Public
slowdevlabs/SDLFeedbackKit

Private
SlowDev Feedback Worker
D1
R2
Admin tooling
```

이 구조를 통해 Open Source SDK와 Production Infrastructure를 명확히 분리한다.

---

# 64. Cloudflare Reference Guidance

Cloudflare Workers + D1 + R2를 사용할 경우 권장:

```text
Worker
→ Request validation
→ Rate limiting
→ Generate canonical ID
→ Validate attachment
→ Store attachment in R2
→ Store metadata in D1
```

R2 Credential과 D1 binding은 Server runtime 내부에서만 접근한다.

---

# 65. Storage Access

Attachment R2 Bucket 또는 S3 Bucket을 불필요하게 Public Read로 설정하지 않는 것을 권장한다.

Feedback Screenshot에는 민감한 UI 정보가 포함될 수 있다.

---

# 66. Attachment URLs

Admin Dashboard에서 Attachment를 보여주기 위해 Public Permanent URL을 만드는 것은 신중히 결정한다.

권장 후보:

```text
Authenticated proxy
Signed temporary URL
Private storage access
```

---

# 67. Privacy-sensitive Screenshots

사용자는 의도치 않게 Screenshot에 다음 정보를 포함할 수 있다.

```text
Names
Messages
Addresses
Email
Account details
Private app content
```

따라서 Attachment는 일반 공개 이미지로 취급하지 않는다.

---

# 68. Abuse Storage Protection

공격자가 Attachment Upload를 Storage Abuse 용도로 사용할 수 있다.

따라서:

```text
Maximum attachment size
Maximum request size
Rate limit
Image validation
```

을 반드시 적용한다.

---

# 69. Database Flood Protection

Attachment가 없어도 많은 Text Feedback 요청으로 D1/PostgreSQL을 Flood할 수 있다.

Rate Limit과 Request Validation을 Attachment가 없는 요청에도 동일하게 적용한다.

---

# 70. Category Values

Backend가 특정 Category 목록만 허용할 필요는 없다.

SDLFeedbackKit은 Custom Category를 지원하기 때문이다.

단, 길이 및 형식 제한은 적용해야 한다.

---

# 71. Email Validation

Client와 Server에서 기본적인 Email 형식 검사를 할 수 있으나 완벽한 Email 존재 여부 검증을 목표로 하지 않는다.

Email 입력은 사용자의 회신 요청 정보일 뿐 인증 수단이 아니다.

---

# 72. Timestamps

`createdAt`은 Client Clock 기반이므로 신뢰하지 않는다.

Backend는 별도의 Server Timestamp를 기록한다.

정렬, 보존 정책, Abuse 분석에는 Server Timestamp를 우선 사용한다.

---

# 73. Locale and Device Context

Locale, OS Version, App Version 등은 Debugging Context다.

권한 또는 Security Policy 판단에 사용하지 않는다.

---

# 74. Device Fingerprinting

SDLFeedbackKit은 장기적인 사용자 추적이 가능한 Persistent Device Identifier를 생성하지 않는다.

Feedback Submission 간 사용자를 추적하는 것이 SDK 목적이 아니다.

---

# 75. Analytics Separation

SDLFeedbackKit은 Feedback SDK이지 Analytics SDK가 아니다.

사용자 행동 추적을 위해 Feedback Metadata를 남용하지 않는다.

---

# 76. Principle of Least Data

새로운 자동 Context 필드를 추가할 때 다음 질문을 검토한다.

> 이 정보가 실제 Feedback 조사에 필요한가?

필요성이 명확하지 않다면 수집하지 않는다.

---

# 77. Security Review Checklist

새로운 기능 추가 전 다음을 확인한다.

```text
새로운 Secret이 Client에 필요한가?
→ 필요하다면 설계 재검토

새로운 사용자 데이터가 자동 수집되는가?
→ 최소화 가능한가?

새로운 파일 형식을 허용하는가?
→ Validation 정책이 있는가?

Payload 크기가 증가하는가?
→ Server Limit과 일치하는가?

새로운 Public API가 인증을 암시하는가?
→ Client 신뢰 문제 없는가?

Backend가 새로운 입력을 처리해야 하는가?
→ Server-side Validation 정의되었는가?
```

---

# 78. Security Incident Reporting

공개 프로젝트 운영 시 Security Issue는 일반 GitHub Issue보다 비공개 신고 경로를 제공하는 것을 권장한다.

예:

```text
GitHub Private Vulnerability Reporting
```

Repository 공개 시 활성화를 검토한다.

---

# 79. Vulnerability Disclosure

README 또는 GitHub Security Policy에서 다음을 안내할 수 있다.

```text
Do not publish exploitable security vulnerabilities
as public issues before maintainers have had
a reasonable opportunity to investigate.
```

정확한 신고 절차는 Repository 공개 단계에서 추가한다.

---

# 80. Security Non-Goals

SDLFeedbackKit은 다음을 제공하지 않는다.

```text
End-user authentication
Server authentication system
Encryption key management
Certificate pinning framework
Anti-bot SaaS
CAPTCHA
Admin authorization
Database encryption
Backend firewall
WAF configuration
```

이는 Host App 또는 Self-hosted Backend의 책임이다.

---

# 81. Recommended Minimum Backend Security

SDLFeedbackKit을 Production 앱에서 사용하려면 Backend는 최소 다음 조건을 만족해야 한다.

```text
HTTPS
Request size limit
Server-side field validation
Attachment size validation
Attachment file validation
Rate limiting
Safe database queries
Server-generated storage keys
Sanitized error responses
Private admin access
No client-side secrets
```

---

# 82. Recommended Enhanced Security

사용량이 늘어난 이후 추가 검토:

```text
Abuse scoring
IP reputation
WAF rules
Temporary block lists
Feedback frequency analysis
Signed attachment URLs
Automated retention cleanup
Admin audit logs
Alerting
```

MVP에서는 필요 이상 복잡하게 구현하지 않는다.

---

# 83. Final Security Definition

SDLFeedbackKit의 Security Model은 다음 한 문장으로 정의한다.

> **The client is public and untrusted; security is enforced by the self-hosted backend.**

SDLFeedbackKit의 역할:

```text
Safe UI
Reasonable client validation
Privacy-conscious attachment processing
Bounded payload generation
```

Backend의 역할:

```text
Trust enforcement
Validation
Rate limiting
Abuse protection
Authentication
Storage security
Data protection
```

---

# 84. Core Rule

SDLFeedbackKit 관련 보안 판단에서 항상 다음 원칙을 우선한다.

> **If a security control depends on hiding something inside the app, it is not a reliable security control.**

Client에서 숨기는 대신 Server가 안전하도록 설계한다.

---

**Project:** SDLFeedbackKit
**Document:** SECURITY.md
**Owner:** SlowDevLabs
**Distribution:** Public GitHub / Swift Package Manager
**Backend Model:** Self-hosted
**Security Model:** Untrusted Client / Trusted Server Boundary
**Status:** Draft
**Target Version:** v0.1
