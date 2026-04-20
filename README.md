# 담아, (Dama)

> 오늘의 색을 담는 산책 — 매일 제시되는 색상 팔레트를 카메라로 채워가는 컬러 컬렉션 앱
> <br>
> 당신만의 색으로 일상을 가득 채워보세요.

<br>

## App Store

[<img src="https://developer.apple.com/assets/elements/badges/download-on-the-app-store.svg" height="44">](https://apps.apple.com/kr/app/%EB%8B%B4%EC%95%84/id6761337499)


<br>

## Screenshots

| 홈 | 카메라 | 미션 | 지도 |
|:--:|:--:|:--:|:--:|
| <img src="https://github.com/user-attachments/assets/dd0e4f5e-5b59-4d71-a6e3-55222cd9974a" width="360"> | <img src="https://github.com/user-attachments/assets/0b243822-0ae4-4f41-a78f-4ea657d6f7b4" width="360"> | <img src="https://github.com/user-attachments/assets/cb11a44b-9dda-4bbd-bb42-07d0a9dfb6e4" width="360"> | <img src="https://github.com/user-attachments/assets/e26735c6-08f3-4bc1-bca5-3b1b12401405" width="360"> |

<br>




## Features

- **데일리 미션** — 매일 새로운 색상 팔레트(기본 9칸, 수정 가능)가 제시되며, 주변의 색을 카메라로 찾아 채웁니다.
- **컬러 매칭** — CoreImage `CILabDeltaE`를 활용한 지각적 색상 유사도 측정으로 정확한 매칭을 판별합니다.
- **갤러리 선택** — 카메라 외에 포토 라이브러리에서 색상을 불러와 슬롯을 채울 수 있습니다.
- **지도 기록** — 촬영한 모든 색상의 위치가 지도 위 핀으로 기록되고 클러스터링으로 표시됩니다.
- **컬렉션 뷰** — 날짜별 팔레트와 캡처 사진을 한눈에 확인할 수 있습니다.
- **Live Activity** — ActivityKit 기반 Dynamic Island 미션 타이머를 지원합니다.

<br>

## Tech Stack

| Category | Stack |
|---|---|
| Language | Swift 5.9 |
| UI | UIKit · SnapKit |
| Architecture | MVVM + Coordinator |
| Reactive | RxSwift · RxCocoa |
| Database | RealmSwift |
| Image | Kingfisher |
| Map | MapKit |
| Color Matching | CoreImage (CILabDeltaE)|
| Live Activity | ActivityKit · WidgetKit |
| Analytics | Firebase Analytics, Crashtics |
| Minimum Deployment | iOS 26.0 |

<br>

## Architecture

```
SceneDelegate
└── AppCoordinator
    └── MainTabBarController
        ├── HomeCoordinator    → HomeViewController
        ├── CameraCoordinator  → CameraViewController
        ├── CollectionCoordinator (WIP)
        └── MapCoordinator     → MapViewController
```

모든 ViewController는 `BaseViewController`를 상속하며 `setupViews → setupConstraints → bind` 순서로 초기화합니다.

ViewModel은 `ViewModelType` 프로토콜의 `transform(input:) → Output` 패턴을 따르며,
Output은 항상 `Driver`로 노출해 Main 스레드와 에러 핸들링을 보장합니다.

<br>

## Folder Structure
  | Layer | Description |
  |---|---|
  | **App/**| 앱 진입점. AppCoordinator가 Window에 루트 탭바를 세팅하고 각 탭 Coordinator를 생성 |
  | **Base/** | 모든 VC·ViewModel이 따르는 베이스 클래스와 프로토콜 (BaseViewController, Coordinator, ViewModelType) |
  | **Common/**| 앱 전역에서 재사용하는 UI 컴포넌트, Extension, 메모리 상태 스토어 |
  | **Domain/** | Realm Object 모델 정의 (Photo, DailyMission, ColorSlot, User) |
  | **Data/** | Realm CRUD를 담당하는 RealmManager 싱글톤 |
  | **LiveActivity/** | ActivityKit 기반 Dynamic Island 미션 타이머 관련 코드 |
  | **Presentation/** | 화면 단위로 View / ViewModel / Component / Coordinator를 묶어 관리 |

<br>

## Requirements

- Xcode 16.0+
- iOS 26.0+
- Swift 5.9+

<br>

## Installation

```bash
# 의존성 관리: Swift Package Manager
# Xcode에서 프로젝트를 열면 패키지가 자동으로 resolve됩니다.
open ColorWalk.xcodeproj
```

| Package | Version |
|---|---|
| RxSwift, RxCocoa | 6.10.2 |
| RealmSwift |  20.0.3 |
| SnapKit | 5.7.1 |
| Kingfisher | 8.8.0 |

<br>

## License

Distributed under the MIT License.
