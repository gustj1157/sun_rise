# SUNRISE

전국 30개 일출/일몰 명소를 위성지도 위에 시각화하고, 실시간 태양 위치·날씨 기반의 시각 효과를 제공하는 Flutter 앱.

## 주요 기능

- 위성지도 + 커스텀 티어드롭 마커 (글로우/아이콘/라벨)
- 시간대별 하늘 그라데이션 오버레이 (일출/낮/일몰/밤)
- 해·달 애니메이션, 별 파티클, edge glow 효과
- 글래스모피즘 상단 정보바, shimmer 로딩, 스플래시
- 실시간 카운트다운, 거리/소요시간 계산, 태양 나침반
- 날씨 기반 구름 시각화, 주간 일출/일몰 추천
- 명소별 사진 갤러리 (Unsplash)

## 기술 스택

- **Flutter** 3.x · **Dart** SDK `^3.10.7`
- 상태관리: `provider`
- 지도/위치: `google_maps_flutter`, `geolocator`
- 네트워크/이미지: `http`, `cached_network_image`, `flutter_cache_manager`
- 기타: `intl`, `url_launcher`

## 외부 API

| 용도 | 서비스 |
|------|--------|
| 일출/일몰 시각 | sunrise-sunset.org |
| 날씨/구름 | OpenWeatherMap |
| 명소 사진 | Unsplash |
| 지도 | Google Maps SDK |

## 폴더 구조

```
lib/
├── main.dart
├── constants/        # 테마, 30개 명소 데이터
├── models/           # SpotData, SunData, SunStatus
├── providers/        # SpotsProvider, SunStatusProvider
├── services/         # sunrise / weather / unsplash / location / marker
├── screens/          # splash, map, photo_gallery
├── widgets/          # top_info_bar, spot_detail_sheet, sun_moon_animation 등
├── painters/         # DayNightPainter
└── utils/            # sun_calculator, kst_time_helper, distance_calculator
```

## 시작하기

### 1. 사전 요구사항

- Flutter SDK 3.x (`flutter --version`)
- Dart SDK `^3.10.7`
- Android Studio / Xcode (모바일 빌드 시)
- Chrome (웹 빌드 시)

### 2. 클론 & 의존성 설치

```bash
git clone https://github.com/gustj1157/sun_rise.git
cd sun_rise
flutter pub get
```

### 3. API 키 설정

이 프로젝트는 외부 API 키 4종을 필요로 합니다. **각자 발급받아 아래 위치에 채워야 합니다.**

#### Google Maps API 키

- 발급: https://console.cloud.google.com/google/maps-apis
- Maps SDK for Android / iOS / JavaScript 활성화

**Web** — `web/index.html`
```html
<script src="https://maps.googleapis.com/maps/api/js?key=YOUR_API_KEY"></script>
```

**Android** — `android/app/src/main/AndroidManifest.xml`
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_API_KEY"/>
```

**iOS** — `ios/Runner/AppDelegate.swift`
```swift
GMSServices.provideAPIKey("YOUR_API_KEY")
```

#### OpenWeatherMap API 키

- 발급: https://openweathermap.org/api
- `lib/services/weather_service.dart`의 `_apiKey` 값 교체

#### Unsplash API 키 (선택)

- 발급: https://unsplash.com/developers
- `lib/services/unsplash_service.dart`에 키 등록 (미설정 시 picsum.photos 폴백)

### 4. 실행

```bash
# Web
flutter run -d chrome

# Android
flutter run -d <device-id>

# iOS
flutter run -d <device-id>
```

### 5. 빌드

```bash
flutter build web
flutter build apk --release
flutter build ios --release
```

## 개발 환경

| 항목 | 버전 |
|------|------|
| OS | Windows 11 / macOS / Linux |
| Flutter | 3.x stable |
| Dart | ^3.10.7 |
| Android minSdk | Flutter 기본값 |
| iOS deployment target | 12.0+ |

## 알려진 이슈

- 단위/위젯 테스트 미작성
- 데이터 영속화 레이어 없음 (메모리 기반)
- Unsplash 키 미설정 시 임시 이미지 사용

## 라이선스

비공개 프로젝트 (`publish_to: none`).
