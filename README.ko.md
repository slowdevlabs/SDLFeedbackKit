# SDLFeedbackKit

[English](README.md) · [한국어](README.ko.md) · [Español](README.es.md)


**iOS와 macOS용 가볍고 백엔드에 종속되지 않는 SwiftUI 피드백 폼 패키지입니다.**

![Swift](https://img.shields.io/badge/Swift-5.9+-F05138)
![iOS](https://img.shields.io/badge/iOS-13.0+-000000)
![macOS](https://img.shields.io/badge/macOS-10.15+-000000)
![License](https://img.shields.io/badge/License-MIT-4C8BF5)

SDLFeedbackKit은 재사용 가능한 피드백 폼 UI, payload 모델, 이미지 첨부 처리 파이프라인, 현지화, 그리고 전송 계약을 제공합니다. 화면 표시와 닫기는 호스트 앱이 담당하고, 실제 전송과 저장은 사용자의 백엔드가 담당합니다.

> [!NOTE]
> SDLFeedbackKit에는 호스팅된 백엔드나 내장 네트워크 전송 기능이 포함되어 있지 않습니다.  
> `FeedbackTransport`를 구현해 원하는 백엔드와 연결하세요.

| | |
|---|---|
| **플랫폼** | iOS 13+ · macOS 10.15+ |
| **Swift** | 5.9+ |
| **현지화** | 영어 · 한국어 · 스페인어 |
| **첨부파일** | 이미지 1개 · JPEG 출력 · 기본 최대 1,000,000 bytes |
| **외부 의존성** | 없음 |
| **백엔드** | 직접 구현한 `FeedbackTransport` 사용 |

---

## 주요 기능

- SwiftUI 피드백 폼
- 사용자 정의 피드백 카테고리
- 메시지 및 선택적 이메일 입력
- 이미지 1개 첨부
- 자동 이미지 리사이즈, JPEG 재인코딩, 메타데이터 축소
- 최종 첨부파일 기본 제한 `1,000,000` bytes
- 백엔드에 종속되지 않는 `FeedbackTransport`
- iOS / macOS 네이티브 첨부파일 선택기
- 영어, 한국어, 스페인어 현지화
- 호스트 앱이 화면 표시와 닫기를 직접 제어
- 외부 의존성 없음

---

## 요구사항

- Swift 5.9+
- iOS 13.0+
- macOS 10.15+
- Swift Package Manager

---

## 설치

Xcode에서 아래 저장소 URL을 사용해 SDLFeedbackKit을 추가합니다.

```text
https://github.com/slowdevlabs/SDLFeedbackKit
```

`0.1.0` 이상, `0.1.x` 범위의 버전을 선택하세요.

이 저장소 안에서 작업할 때 예제 앱은 로컬 package checkout을 사용합니다.

---

## 빠른 시작

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

`FeedbackFormView`는 스스로 화면을 닫지 않습니다. 화면 표시와 닫기는 호스트 앱이 담당하며, `onSubmitted`와 `onCancelled`에서 원하는 동작을 결정할 수 있습니다.

---

## 사용자 정의 Transport

앱 또는 네트워크 모듈에서 `FeedbackTransport`를 구현합니다.

```swift
struct MyFeedbackTransport: FeedbackTransport {
    func submit(
        _ payload: FeedbackPayload
    ) async throws -> FeedbackSubmissionReceipt {
        // 원하는 백엔드로 payload를 전송합니다.

        return FeedbackSubmissionReceipt(
            serverID: "feedback-123",
            acceptedAt: Date()
        )
    }
}
```

> [!IMPORTANT]
> 피드백 payload는 신뢰할 수 없는 입력으로 취급해야 합니다. 백엔드에서 요청을 다시 검증하고, rate limit과 저장/보존 정책을 적용하세요.

포함된 예제 앱은 mock transport를 사용합니다. 예제에서 제출한 피드백은 **실제 백엔드에 저장되지 않습니다.**

---

## 설정

`FeedbackConfiguration`에서 다음 항목을 설정할 수 있습니다.

- 카테고리
- 이메일 필드 설정
- 첨부파일 설정
- 메시지 설정
- 취소 버튼 표시 여부

### 기본 첨부파일 정책

| 항목 | 기본값 |
|---|---:|
| 최종 최적화 크기 | `1,000,000` bytes |
| 긴 변 기준 | `1,800` px |
| 초기 JPEG 품질 | `0.8` |

---

## 첨부파일

SDLFeedbackKit은 이미지 1개를 첨부할 수 있으며, 제출 전에 표준화된 형태로 처리합니다.

처리 흐름:

```text
선택한 이미지
    ↓
디코딩 / 다운샘플링
    ↓
방향 보정
    ↓
JPEG 재인코딩
    ↓
메타데이터 축소
    ↓
FeedbackAttachment
    ↓
FeedbackTransport
```

최종 첨부파일은:

- JPEG 형식을 사용합니다
- 기본적으로 `1,000,000` bytes 이하로 제한됩니다
- 최종 픽셀 크기와 byteCount를 제공합니다
- 파일명은 `feedback.jpg`로 표준화됩니다
- `FeedbackAttachment`를 통해 원본 파일 경로를 노출하지 않습니다

지원 가능한 입력 형식은 Apple 플랫폼의 디코더 지원에 따라 달라집니다. JPEG와 PNG는 일반적으로 사용할 수 있으며, HEIC/HEIF는 호스트 OS의 지원 여부에 따라 달라집니다.

---

## 현지화

SDLFeedbackKit에는 다음 언어의 `.strings` 리소스가 포함되어 있습니다.

- 영어
- 한국어
- 스페인어

기본 언어는 영어이며, package 현지화는 `Bundle.module`을 통해 로드됩니다.

기본 제공 카테고리 이름은 SDLFeedbackKit이 현지화합니다.

> [!TIP]
> 사용자 정의 카테고리의 이름은 호스트 앱에서 제공하므로, 필요한 경우 호스트 앱이 직접 현지화해야 합니다.

---

## 개인정보 보호 및 보안

SDLFeedbackKit은 백엔드와 개인정보 처리 정책을 호스트 앱이 직접 결정하도록 설계되어 있습니다.

- 호스팅된 백엔드는 포함하지 않습니다
- 패키지에서 영구적인 기기 식별자를 수집하지 않습니다
- 패키지에서 정밀 위치 정보를 수집하지 않습니다
- 사용자가 직접 선택한 이미지만 처리합니다
- 선택한 이미지는 메타데이터와 파일 크기를 줄이기 위해 재인코딩됩니다
- 백엔드 secret을 앱 바이너리에 포함하면 안 됩니다
- 서버 측 검증과 악용 방지는 백엔드의 책임입니다

---

## 예제

지원 플랫폼별 예제 호스트 앱이 포함되어 있습니다.

```text
Examples/
├── iOSExample/
└── macOSExample/
```

예제에서는 다음을 확인할 수 있습니다.

- `FeedbackFormView` 표시
- 호스트 앱이 화면 닫기 제어
- `FeedbackTransport` 구현
- 성공 / 실패 흐름
- 이미지 첨부 처리

예제는 의도적으로 실제 production backend 대신 mock transport를 사용합니다.

---

## SDLFeedbackKit이 제공하지 않는 것

SDLFeedbackKit은 의도적으로 범위를 작게 유지합니다.

- 내장 백엔드 없음
- 내장 네트워크 전송 구현 없음
- 다중 첨부파일 없음
- 카메라 촬영 없음
- 드래그 앤 드롭 첨부 파이프라인 없음
- Pasteboard 첨부 지원 없음
- 사용자 정의 테마 시스템 없음

---

## 상태

**Early release — 0.1.x**

현재 실제 앱에 통합할 수 있는 상태이지만, `0.x` 버전 동안 Public API는 계속 개선될 수 있습니다.

---

## 라이선스

SDLFeedbackKit은 MIT License로 제공됩니다. 자세한 내용은 [LICENSE](LICENSE)를 확인하세요.
