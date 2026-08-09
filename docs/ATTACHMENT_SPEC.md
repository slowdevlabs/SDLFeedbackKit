# SDLFeedbackKit — Attachment Specification

## 1. Document Purpose

이 문서는 `SDLFeedbackKit`의 이미지 첨부 기능에 대한 기술 규격을 정의한다.

주요 범위는 다음과 같다.

* iOS/macOS에서의 이미지 선택 방식
* Attachment 수 제한
* 이미지 Decode 및 Orientation 처리
* Resize 정책
* Re-encode 정책
* EXIF/GPS 등 Metadata 제거
* 최종 파일 크기 제한
* **1MB 초과 시 재압축 정책**
* Attachment Validation
* Memory 관리
* Transport 전달 모델
* Error 처리

이 문서는 Backend Storage나 HTTP Upload 형식을 정의하지 않는다.

---

# 2. Core Attachment Principle

SDLFeedbackKit의 Attachment 기능은 다음 원칙을 따른다.

> 사용자가 선택한 이미지를 그대로 전송하지 않고, Feedback 용도에 적합한 크기와 포맷으로 정규화한 뒤 전달한다.

목표:

```text
Privacy
+
Low bandwidth
+
Predictable payload size
+
Cross-backend compatibility
+
Low memory overhead
```

---

# 3. MVP Attachment Scope

SDLFeedbackKit v0.1에서는 다음만 지원한다.

```text
Image attachment
Maximum 1 image
Optional
```

지원 대상 예:

* Screenshot
* Photos library image
* macOS local image file

MVP에서 지원하지 않는 항목:

```text
Multiple images
Video
Audio
PDF
ZIP
Log file
Text file
Arbitrary binary file
```

---

# 4. Attachment Public Model

`FeedbackAttachment`의 개념 구조:

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

Transport는 이미 최적화가 완료된 Attachment만 전달받는다.

---

# 5. Attachment Lifecycle

전체 흐름:

```text
User chooses image
        ↓
Load source data
        ↓
Validate source
        ↓
Decode
        ↓
Normalize orientation
        ↓
Resize if required
        ↓
Strip unnecessary metadata
        ↓
    Encode
        ↓
    Check size
        ↓
≤ 1MB ?
   │
   ├─ Yes
   │    ↓
   │ FeedbackAttachment
   │
   └─ No
        ↓
   Recompression
        ↓
   Check again
        ↓
   Final validation
        ↓
   FeedbackAttachment
   or Error
```

---

# 6. Platform Picking Strategy

## 6.1 iOS

지원하는 iOS 버전에 따라 가장 안정적인 Apple native picker를 사용한다.

* iOS 14+
  * `PHPickerViewController`
  * selection limit: 1
  * image-only
* iOS 13
  * `UIImagePickerController`
  * photo library fallback
  * image-only

---

# 7. iOS Permissions

가능하면 SDLFeedbackKit은 전체 Photo Library Access를 요구하지 않는다.

즉 다음 형태를 기본으로 하지 않는다.

```text
Full Photo Library permission
```

사용자가 직접 선택한 이미지에만 접근한다.

---

# 8. macOS

macOS에서는 `NSOpenPanel`을 사용한다.

주 사용 사례:

```text
Desktop screenshot
Downloaded image
Saved app screenshot
Local image file
```

따라서 macOS 기본 방향:

```text
NSOpenPanel
```

Allowed Content Types는 이미지로 제한한다.
대표 확장자 예:

```text
jpg
jpeg
png
heic
heif
```

이 차이는 SDLFeedbackKit 내부에서 처리한다.

Host App은 플랫폼별 Picker를 구현하지 않는다.

---

# 10. Attachment Count

MVP에서는 최대:

```text
1
```

장만 허용한다.

따라서 Public Model도:

```swift
attachment: FeedbackAttachment?
```

형태를 사용한다.

배열은 사용하지 않는다.

---

# 11. Replacing Attachment

이미 Attachment가 존재하는 상태에서 사용자가 새로운 이미지를 선택하면:

```text
Existing attachment
        ↓
New image selected
        ↓
Replace
```

방식을 기본으로 한다.

두 이미지를 동시에 유지하지 않는다.

---

# 12. Removing Attachment

사용자는 Submit 전 언제든 Attachment를 제거할 수 있어야 한다.

제거 시:

```text
attachment = nil
```

원본 및 최적화 이미지에 대한 불필요한 메모리 reference도 해제한다.

---

# 13. Supported Source Formats

Apple Image APIs가 안전하게 Decode할 수 있는 일반적인 이미지 포맷을 Source로 허용한다.

대표적으로:

```text
JPEG
PNG
HEIC / HEIF
```

기타 Image Type은 OS Decode 지원 여부에 따라 처리할 수 있다.

---

# 14. Source Format vs Output Format

Source의 이미지 포맷과 최종 Attachment 포맷은 동일할 필요가 없다.

예:

```text
HEIC source
    ↓
JPEG output
```

또는:

```text
PNG screenshot
    ↓
JPEG output
```

이렇게 정규화할 수 있다.

---

# 15. Default Output Format

SDLFeedbackKit v0.1의 기본 Attachment Output은:

```text
JPEG
```

로 한다.

MIME Type:

```text
image/jpeg
```

File Extension:

```text
.jpg
```

---

# 16. Why JPEG

Feedback Attachment는 대부분 다음 유형이다.

```text
Screenshot
UI capture
Photo
```

JPEG를 기본으로 하는 이유:

* Backend 호환성이 높음
* 넓은 플랫폼 지원
* 효율적인 용량 감소
* 인코딩 구현이 단순함
* R2/S3 등의 저장소와 호환성이 좋음

---

# 17. Transparency

PNG 등 Source에 Transparency가 존재하더라도 v0.1에서는 반드시 Transparency를 보존하는 것을 요구하지 않는다.

JPEG로 변환할 경우 Alpha는 적절한 배경과 합성해야 한다.

기본 배경은 플랫폼에 무관한 안전한 색상으로 처리한다.

정확한 합성 구현은 이미지 렌더링 검증 과정에서 결정한다.

---

# 18. Future PNG Preservation

투명도 보존 요구가 실제로 확인될 경우 향후:

```text
preserveAlpha
```

또는 Output Strategy API를 검토할 수 있다.

v0.1에서는 Public API로 노출하지 않는다.

---

# 19. Maximum Image Dimension

기본 Long Edge 제한:

```text
1800 px
```

이다.

---

# 20. Resize Rule

원본 긴 변이 1800px보다 클 경우 Aspect Ratio를 유지하면서 축소한다.

예:

```text
4032 × 3024
        ↓
1800 × 1350
```

또는:

```text
1179 × 2556
        ↓
830 × 1800
```

---

# 21. No Upscaling

원본이 이미 제한보다 작은 경우 확대하지 않는다.

예:

```text
800 × 600
        ↓
800 × 600
```

다음은 하지 않는다.

```text
800 × 600
        ↓
1800 × 1350
```

---

# 22. Orientation Normalization

Source Image의 EXIF Orientation에 의존한 상태로 Attachment를 생성하지 않는다.

Decode 후 실제 Pixel Orientation을 정상화한다.

목표:

```text
Attachment를 어느 Backend/View에서 열어도
동일한 방향으로 표시
```

---

# 23. Image Processing Order

권장 순서:

```text
1. Load
2. Decode
3. Apply orientation
4. Calculate target size
5. Resize
6. Render normalized bitmap
7. Encode JPEG
8. Validate byte size
9. Recompress if necessary
```

---

# 24. Metadata Removal

최종 이미지는 원본 파일을 단순 복사하지 않고 재렌더링 및 재인코딩한다.

이 과정에서 불필요한 Metadata를 제거하는 것을 원칙으로 한다.

대상:

```text
GPS
EXIF
Camera manufacturer
Camera model
Lens data
Capture location
Original filename path
Original creation metadata
Thumbnail metadata
```

---

# 25. Privacy Goal

최종 Attachment에는 Feedback 조사에 필요한 실제 이미지 Pixel 정보만 유지하는 것을 목표로 한다.

특히:

```text
GPS metadata
```

가 남지 않도록 구현 및 테스트해야 한다.

---

# 26. Original Filename Policy

사용자가 선택한 실제 파일 이름을 그대로 유지할 필요는 없다.

이유:

실제 파일명에 민감한 정보가 들어갈 가능성이 있기 때문이다.

예:

```text
john-work-client-secret-screen.png
```

---

# 27. Generated Filename

SDLFeedbackKit이 안전한 이름을 생성하는 것을 기본으로 한다.

권장:

```text
feedback.jpg
```

또는 Client ID 일부를 이용:

```text
feedback-2E4199E2.jpg
```

---

# 28. Local File Path

Payload 또는 Filename에 절대 다음을 포함하지 않는다.

```text
/Users/username/Desktop/...
/private/var/mobile/...
```

로컬 경로는 Backend로 전달하지 않는다.

---

# 29. Default Compression Quality

첫 번째 JPEG Encode의 기본 Compression Quality:

```text
0.8
```

이다.

---

# 30. Target Attachment Size

SDLFeedbackKit v0.1에서 최종 Attachment의 목표 최대 크기는:

```text
1,000,000 bytes
```

즉 약:

```text
1 MB
```

로 정의한다.

---

# 31. 1MB Rule

첫 번째 Resize + JPEG Encode 결과가:

```text
≤ 1 MB
```

이면 그대로 사용한다.

결과가:

```text
> 1 MB
```

이면 즉시 실패하지 않고 **재압축을 수행한다.**

이 정책은 v0.1의 기본 Attachment Processing Rule이다.

---

# 32. Recompression Strategy

1MB를 초과할 경우 JPEG Quality를 단계적으로 낮춘다.

초기 권장 단계:

```text
0.80
 ↓
0.70
 ↓
0.60
 ↓
0.50
```

각 단계마다:

```text
Encode
 ↓
data.count 확인
```

을 반복한다.

---

# 33. First Compression Attempt

기본 Resize 후:

```text
quality = 0.80
```

로 Encode한다.

결과:

```text
≤ 1MB
→ Accept
```

```text
> 1MB
→ quality 0.70
```

---

# 34. Second Compression Attempt

```text
quality = 0.70
```

결과:

```text
≤ 1MB
→ Accept
```

```text
> 1MB
→ quality 0.60
```

---

# 35. Third Compression Attempt

```text
quality = 0.60
```

결과:

```text
≤ 1MB
→ Accept
```

```text
> 1MB
→ quality 0.50
```

---

# 36. Minimum Quality

v0.1의 기본 최소 JPEG Quality:

```text
0.50
```

로 한다.

지나치게 낮은 품질로 계속 압축하는 것은 Feedback Screenshot의 가독성을 해칠 수 있기 때문이다.

---

# 37. If Still Over 1MB

Quality `0.50`에서도 1MB를 초과할 경우 Image Dimension을 추가로 축소한다.

즉:

```text
Quality compression first
        ↓
Still > 1MB
        ↓
Dimension reduction
```

순서를 따른다.

---

# 38. Secondary Resize

두 번째 Resize 단계의 권장 Long Edge:

```text
1440 px
```

이다.

즉:

```text
1800 px
 ↓
1440 px
```

로 축소하고 JPEG Quality를 다시 적용한다.

---

# 39. Secondary Compression

1440px 이미지에서 다시:

```text
0.70
 ↓
0.60
 ↓
0.50
```

순으로 시도한다.

`0.80`부터 다시 시작하지 않는 이유는 이미 첫 단계에서 1MB를 크게 초과한 데이터일 가능성이 높기 때문이다.

---

# 40. Final Resize Fallback

1440px + 0.50에서도 여전히 1MB를 초과하면 최종적으로:

```text
1200 px
```

Long Edge까지 축소한다.

---

# 41. Final Encoding

1200px 단계에서는:

```text
quality = 0.60
```

부터 시도한다.

필요 시:

```text
0.50
```

까지 낮춘다.

그래도 1MB를 초과하면 최종 fallback으로 1000px 단계로 내려간다.

---

# 42. Final Fallback Resize

최종 fallback의 권장 Long Edge:

```text
1000 px
```

이다.

즉:

```text
1200 px
 ↓
1000 px
```

---

# 43. Final Encoding and Failure Rule

1000px 단계에서는:

```text
quality = 0.55
```

필요 시:

```text
0.50
```

까지 낮춘다.

```text
Long edge ≤ 1000px
quality = 0.50
```

에서 최종 Data가 1MB를 초과하면:

```text
attachmentTooLarge
```

Error로 처리한다.

무한 재압축하지 않는다.

---

# 44. Recompression Algorithm Summary

기본 정책:

```text
Resize max 1800
    ↓
JPEG 0.80
    ↓
>1MB ?
 ├─ No → Done
 └─ Yes
      ↓
    0.70
      ↓
    0.60
      ↓
    0.50
      ↓
    Still >1MB ?
       ├─ No → Done
       └─ Yes
            ↓
         Resize max 1440
            ↓
           0.70
            ↓
           0.60
            ↓
           0.50
            ↓
         Still >1MB ?
            ├─ No → Done
            └─ Yes
                 ↓
              Resize max 1200
                 ↓
                0.60
                 ↓
                0.50
                 ↓
              Still >1MB ?
                 ├─ No → Done
                 └─ Yes
                      ↓
                   Resize max 1000
                      ↓
                     0.55
                      ↓
                     0.50
                      ↓
                   Still >1MB ?
                      ├─ No → Done
                      └─ Yes → Reject
```

---

# 44. Why Not Binary Search Quality

JPEG Quality를 0.79, 0.78 등의 방식으로 Binary Search하는 복잡한 알고리즘은 v0.1에서 사용하지 않는다.

이유:

* 구현 복잡도 증가
* 재인코딩 횟수 증가
* CPU 비용 증가
* 결과 차이가 실질적으로 크지 않음

단순한 단계식 압축을 우선한다.

---

# 45. Why Resize After Quality Reduction

Screenshot 가독성 측면에서는 우선 Resolution을 유지하는 편이 유리하다.

따라서:

```text
1800px 유지
+
JPEG quality 감소
```

를 먼저 시도한다.

그래도 충분하지 않을 때 Resolution을 줄인다.

---

# 46. Configuration

`AttachmentConfiguration` 기본값은 앞선 API 문서에서 다음과 같이 조정한다.

```swift
public struct AttachmentConfiguration: Sendable {

    public var isEnabled: Bool
    public var maximumAttachmentBytes: Int
    public var maximumImageDimension: Int
    public var compressionQuality: Double
}
```

권장 기본값:

```text
isEnabled
true

maximumAttachmentBytes
1_000_000

maximumImageDimension
1800

compressionQuality
0.8
```

---

# 47. Configuration vs Recompression

사용자가 `compressionQuality`를 변경하더라도 Package는 최종 최대 크기를 만족시키기 위해 추가 Recompression을 수행할 수 있다.

예:

```text
configured quality = 0.9
```

이라면:

```text
0.90
→ 0.80
→ 0.70
...
```

같은 내부 정책을 사용할 수 있다.

v0.1에서는 기본 `0.8`을 기준으로 먼저 구현한다.

---

# 48. Custom Maximum Bytes

개발자가:

```swift
maximumAttachmentBytes: 2_000_000
```

을 설정하면 동일한 재압축 알고리즘의 목표 크기도 2MB가 된다.

즉 `1MB`는 기본값이며 알고리즘 자체는 Configuration 값을 기준으로 동작하도록 한다.

---

# 49. Hard Safety Limit

Configuration에서 지나치게 큰 크기를 지정하더라도 Package 내부에 별도 Hard Safety Limit을 둘 수 있다.

예:

```text
10 MB
```

이는 메모리 및 Network Abuse를 방지하기 위한 내부 보호 장치다.

정확한 값은 구현 검증 후 확정한다.

---

# 50. Source File Size

원본 Source File이 1MB를 초과한다고 해서 즉시 거부하지 않는다.

예:

```text
Original HEIC
12 MB
```

라도:

```text
Resize
+
Re-encode
```

후 1MB 이하로 만들 수 있다면 허용한다.

---

# 51. Extremely Large Source Images

매우 큰 이미지를 Decode할 경우 Memory Spike가 발생할 수 있다.

따라서 구현 시 가능한 경우:

```text
Downsampling
```

을 사용해 전체 원본 Bitmap을 메모리에 로드하지 않는 방식을 우선한다.

---

# 52. ImageIO Preference

대형 이미지 처리를 위해 Apple의 ImageIO 기반 Downsampling을 우선 검토한다.

목표:

```text
Original 48MP image
```

전체를 UIImage/NSImage로 먼저 Decode하는 것보다 Target Size에 맞춰 Decode한다.

---

# 53. Memory Goal

이미지 Processing 과정에서:

```text
Original
+
Resized
+
Encoded
```

Data를 필요 이상 동시에 오래 유지하지 않는다.

권장 흐름:

```text
Load
↓
Downsample
↓
Encode
↓
Release source
```

---

# 54. Main Thread Policy

Image Decode, Resize, Compression은 UI Main Thread를 장시간 차단해서는 안 된다.

Processing은 async background 작업으로 수행한다.

UI 업데이트만 MainActor에서 처리한다.

---

# 55. User Feedback During Processing

이미지 선택 이후 Processing이 즉시 끝나지 않을 수 있으므로 UI에서 상태를 표시할 수 있다.

예:

```text
Preparing image…
```

짧은 작업인 경우 불필요한 Progress UI를 표시하지 않아도 된다.

---

# 56. Submit During Processing

Attachment가 아직 Processing 중이라면 Submit을 허용하지 않는 것을 기본으로 한다.

예:

```text
attachmentState = processing
→ Submit disabled
```

---

# 57. Attachment State

내부 상태 예:

```text
none
loading
processing
ready
failed
```

Public API로 노출하지 않는다.

---

# 58. Preview

최적화 완료 후 사용자가 첨부된 이미지를 확인할 수 있어야 한다.

Preview에서는:

* Thumbnail
* Remove action
* File size

정도를 표시할 수 있다.

---

# 59. File Size Display

권장:

```text
1.2 MB
742 KB
```

처럼 사람이 읽기 쉬운 형태로 표시한다.

정확한 Binary/Decimal 단위 표기는 Foundation formatter를 사용해 플랫폼 conventions를 따른다.

---

# 60. Do Not Show Compression Complexity

사용자에게:

```text
JPEG 0.6
1800px
Recompression stage 3
```

같은 내부 기술 정보를 보여주지 않는다.

사용자가 알아야 할 것은:

```text
Attachment ready
1.8 MB
```

정도다.

---

# 61. Image Quality Goal

Feedback Attachment의 목표는 원본 보존이 아니라:

```text
UI text readable
Bug visually identifiable
Reasonable color/detail preservation
```

이다.

사진 백업 서비스 수준의 무손실 품질은 목표가 아니다.

---

# 62. Screenshot Readability

특히 앱 Screenshot의 작은 글씨가 심하게 뭉개지지 않는지 테스트해야 한다.

테스트 대상:

```text
Small iPhone
Large iPhone
iPad screenshot if later supported
Retina macOS screenshot
Dark Mode UI
Light Mode UI
Text-heavy screen
```

---

# 63. PNG to JPEG Concern

Text-heavy Screenshot에서는 PNG가 JPEG보다 더 효율적이거나 선명할 수 있다.

하지만 v0.1에서는 단순성과 일관성을 위해 JPEG를 기본으로 한다.

실제 테스트 결과 JPEG에서 Text Quality 문제가 확인되면 다음 정책을 추후 검토한다.

```text
Screenshot heuristic
→ PNG or JPEG adaptive encoding
```

---

# 64. Image Type Detection

Source File Extension만으로 Image Type을 판단하지 않는다.

OS Image Decoder가 실제로 Decode 가능한지 확인한다.

---

# 65. MIME Security

Client는 MIME Type을 제공하지만 Backend는 신뢰하지 않는다.

Server에서:

```text
Magic bytes
Actual decoder
```

등으로 검증해야 한다.

---

# 66. Unsupported Source

이미지로 Decode할 수 없는 경우:

```text
unsupportedAttachment
```

또는:

```text
attachmentProcessingFailed
```

로 처리한다.

가능하면 사용자에게는 단순한 메시지를 표시한다.

예:

```text
This image couldn't be attached.
Please choose another image.
```

---

# 67. Corrupt Image

손상된 이미지 역시 Submission 전체를 Crash시키면 안 된다.

처리:

```text
Decode failure
→ attachment error
→ user may retry or remove attachment
```

---

# 68. Attachment Failure and Message

Attachment 처리 실패가 발생해도 작성한 Feedback Message를 유지한다.

사용자는:

```text
Choose another image
Remove attachment
Submit without image
```

중 선택할 수 있어야 한다.

---

# 69. Attachment Optionality

Attachment 실패 때문에 Feedback 전체를 반드시 포기하게 만들지 않는다.

이미지가 필수가 아니므로 제거 후 Text만 Submit할 수 있다.

---

# 70. Cancellation

사용자가 Picker를 취소한 경우 Error로 취급하지 않는다.

```text
Picker cancelled
→ existing state retained
```

기존 Attachment가 있다면 그대로 유지한다.

---

# 71. Security-scoped Resources on macOS

macOS File Importer에서 Security-scoped URL 접근이 필요한 경우 Platform Layer에서 적절히 처리한다.

Access는 필요한 시간 동안만 유지한다.

원본 파일 경로나 Bookmark를 Feedback Payload에 저장하지 않는다.

---

# 72. Sandbox Compatibility

SDLFeedbackKit은 App Sandbox 환경에서 정상 동작해야 한다.

Host App이 불필요한 File Access Entitlement를 추가하도록 요구하지 않는다.

---

# 73. Temporary Files

가능하면 Processing을 메모리 기반으로 수행한다.

Temporary File이 필요하다면:

```text
temporaryDirectory
```

를 사용하고 Processing 완료 후 제거한다.

---

# 74. Persistent Cache

MVP에서는 Attachment를 Persistent Cache에 저장하지 않는다.

이유:

* 개인정보 보존 최소화
* Storage lifecycle 단순화
* Failed Feedback 이미지가 기기에 계속 남는 문제 방지

---

# 75. Retry

Network Submission Retry에는 이미 생성된 `FeedbackAttachment.data`를 재사용한다.

Retry마다 원본 이미지를 다시 Decode/Compress하지 않는다.

---

# 76. User Edits Attachment

전송 실패 후 사용자가 새 Attachment를 선택하면 기존 Attachment를 폐기하고 새 이미지를 Processing한다.

새로운 Payload 생성 정책은 `FEEDBACK_PAYLOAD_SPEC.md`를 따른다.

---

# 77. Attachment and clientID

Attachment filename이나 Local State를 `clientID`와 연결할 수 있다.

하지만 Storage Canonical ID는 Backend에서 생성하는 것을 권장한다.

---

# 78. Backend Filename Rule

Backend는 Client filename을 Storage Path로 신뢰하지 않는다.

권장:

```text
Generate server key
```

예:

```text
attachments/<server-feedback-id>/image.jpg
```

---

# 79. Backend Size Validation

Client에서 1MB 이하로 만들었더라도 Backend는 다시 크기를 검사한다.

예:

```text
maximum attachment
1 MB
```

또는 서버 정책에 따라 약간의 허용 범위를 둘 수 있다.

---

# 80. Client vs Server Limit

Transport Encoding overhead와 별개로 Binary Attachment 자체의 제한은:

```text
1,000,000 bytes
```

기준으로 한다.

Multipart 전체 Request Size는 Backend에서 더 크게 설정한다.

---

# 81. Recommended Request Limit

1MB Attachment 기준 Reference Backend Request 제한은 대략:

```text
2 MB ~ 3 MB
```

범위를 우선 검토한다.

Text/Metadata 및 multipart overhead를 포함해야 한다.

---

# 82. Attachment Validation Invariants

최종 `FeedbackAttachment`는 다음 조건을 만족해야 한다.

```text
data is not empty

data.count == byteCount

byteCount <= configured maximum

pixel width > 0 when provided

pixel height > 0 when provided

mimeType is supported

filename contains no local path

image can be decoded
```

---

# 83. Error Types

Attachment 관련 주요 Error:

```swift
case unsupportedAttachment
case attachmentTooLarge
case attachmentProcessingFailed
```

추가 세부 오류는 internal로 유지한다.

---

# 84. Public Error Simplicity

다음처럼 지나치게 세부적인 Public Error는 v0.1에서 만들지 않는다.

```text
jpegEncoderFailed
cgImageSourceFailed
securityScopedURLFailed
exifRemovalFailed
```

이는 구현 세부사항이다.

---

# 85. Logging

Attachment 처리 로그에는 다음을 출력할 수 있다.

```text
Source byte count
Source dimensions
Final dimensions
Final byte count
Compression attempts
```

하지만 다음은 기본 로그에 포함하지 않는다.

```text
Original filename
Full local path
Image binary
Sensitive image metadata
```

---

# 86. Debug Example

안전한 Debug 로그 예:

```text
Attachment processed:
sourceDimensions=4032x3024
finalDimensions=1800x1350
attempts=2
finalBytes=1843021
```

---

# 87. Test Matrix — Source Formats

최소 테스트:

```text
JPEG
PNG
HEIC
Invalid data
Corrupted JPEG
Very small image
Very large image
```

---

# 88. Test Matrix — Dimensions

테스트:

```text
500 × 500
1800 × 1200
1200 × 1800
4032 × 3024
3024 × 4032
Very wide image
Very tall image
```

---

# 89. Test Matrix — Compression

다음 Case를 반드시 테스트한다.

```text
Initial encode < 1MB

Initial encode > 1MB
→ 0.70 succeeds

0.70 > 1MB
→ 0.60 succeeds

Quality reduction insufficient
→ 1440 resize succeeds

1440 insufficient
→ 1200 resize succeeds

Final still > 1MB
→ 1000 resize succeeds

1000 insufficient
→ attachmentTooLarge
```

---

# 90. Test Matrix — Privacy

재인코딩 후 다음이 제거되었는지 확인한다.

```text
GPS
EXIF camera metadata
Original filename path
Orientation dependency
```

---

# 91. Test Matrix — Orientation

최소:

```text
Landscape
Portrait
90° rotated EXIF
180° rotated EXIF
Mirrored orientation if supported
```

최종 이미지가 정상 방향이어야 한다.

---

# 92. Test Matrix — UI

iOS:

```text
Pick image
Cancel picker
Replace image
Remove image
Processing state
Failure
Submit with attachment
Submit without attachment
```

macOS:

```text
File importer
Cancel
Unsupported file
Replace
Remove
Sandbox access
```

---

# 93. Performance Goal

일반적인 Screenshot 첨부는 사용자가 불편함을 느끼지 않을 정도로 빠르게 처리되어야 한다.

단, 구체적인 시간 SLA는 v0.1에서 Public Contract로 정의하지 않는다.

---

# 94. Quality Regression Assets

Repository Tests에 직접 민감한 실제 사용자 Screenshot을 넣지 않는다.

Synthetic 또는 공개 테스트 이미지를 사용한다.

가능하면:

```text
generated test pattern
sample UI-like image
```

를 사용한다.

---

# 95. Accessibility

Attachment UI에는 VoiceOver Label을 제공한다.

예:

```text
Add image
Attached image
Remove attached image
Image processing
Attachment failed
```

Thumbnail 자체가 의미 없는 경우 별도의 accessible label을 제공한다.

---

# 96. Reduce Motion

Attachment Processing 및 Success UI에서 불필요한 애니메이션을 강제하지 않는다.

Reduce Motion 설정을 존중한다.

---

# 97. Localization

다음 UI 문구는 Package Localization Resource를 사용한다.

```text
Add Image
Replace Image
Remove Image
Preparing Image…
Couldn't Attach Image
Image Too Large
```

---

# 98. API Boundary

`AttachmentConfiguration` 외에 이미지 처리의 세부 알고리즘을 Public API로 노출하지 않는다.

즉 외부 개발자는 기본적으로 다음 정도만 조절한다.

```text
enabled
max bytes
max dimension
initial quality
```

다음은 internal:

```text
Recompression quality sequence
Fallback dimensions
ImageIO settings
EXIF stripping
Decode strategy
```

---

# 99. Why Recompression Is Internal

재압축 알고리즘까지 Public Configuration으로 만들면 API가 지나치게 복잡해진다.

예를 들어 다음은 v0.1에서 제공하지 않는다.

```swift
qualitySteps: [0.8, 0.73, 0.61]
resizeSteps: [1800, 1540, 1230]
```

이러한 값은 Package가 안전한 기본값으로 관리한다.

---

# 100. Default Attachment Policy Summary

SDLFeedbackKit v0.1의 기본 정책은 다음과 같다.

```text
Attachment Type
Image

Maximum Count
1

iOS Picker
PHPickerViewController / UIImagePickerController fallback

macOS Picker
NSOpenPanel

Default Output
JPEG

Initial Long Edge
1800 px

Initial Quality
0.80

Maximum Final Size
1 MB

If > 1MB
Recompress

Quality Steps
0.80
0.70
0.60
0.50

If still > 1MB
Resize to 1440 px

If still > 1MB
Resize to 1200 px

If still > 1MB
Resize to 1000 px

Final Minimum Quality
0.50

If still > 1MB
Reject attachment
```

---

# 101. Final Processing Definition

Attachment Processing은 다음 한 문장으로 정의한다.

> SDLFeedbackKit converts a user-selected image into a privacy-reduced, orientation-normalized, size-bounded JPEG suitable for feedback submission.

즉:

```text
Selected image
    ↓
Safe loading
    ↓
Downsample / Resize
    ↓
Orientation normalization
    ↓
Metadata stripping
    ↓
JPEG encoding
    ↓
1MB check
    ↓
Adaptive recompression
    ↓
FeedbackAttachment
```

---

# 102. Architectural Rule

향후 Attachment 기능을 확장하기 전에 다음 질문을 확인한다.

> 이 기능이 일반적인 앱 Feedback에 필요한가, 아니면 파일 전송 시스템의 영역으로 확장되고 있는가?

SDLFeedbackKit은 범용 파일 업로더가 아니다.

따라서:

```text
Screenshot / image attachment
```

라는 명확한 범위를 유지한다.

Multiple files, logs, videos 등은 실제 수요가 충분히 확인된 이후 별도 설계로 추가한다.

---

**Project:** SDLFeedbackKit
**Document:** ATTACHMENT_SPEC.md
**Owner:** SlowDevLabs
**Distribution:** Public GitHub / Swift Package Manager
**Backend Model:** Self-hosted
**Attachment Status:** Draft
**Target Version:** v0.1
**Default Maximum Attachment Size:** 1 MB
**Oversize Policy:** Adaptive recompression
