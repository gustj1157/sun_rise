# 일출/일몰 정보 앱 MVP 개발 계획서 (수정본)

## 1. 프로젝트 개요

### 1.1 프로젝트명
**SunTime Korea** (가칭)

### 1.2 목표
전국 숨겨진 일출/일몰 명소를 위성지도 기반으로 시각화하고, 실시간 태양 위치에 따른 명암 표현과 명소 사진 썸네일을 제공하는 Flutter MVP 앱 개발

### 1.3 핵심 가치
- 인스타/블로그에서 핫한 숨겨진 포토스팟 발굴
- 실시간 해 위치 시각화로 직관적인 정보 전달
- 각 명소의 실제 일출/일몰 사진 미리보기

---

## 2. MVP 기능 범위

### 2.1 핵심 기능 (Must Have)

| 기능 | 설명 |
|------|------|
| 위성지도 | Google Maps 위성(Satellite) 모드 기본 적용 |
| 사진 마커 | 각 명소의 대표 사진을 원형 썸네일로 지도에 표시 |
| 명암 오버레이 | 해 뜬 지역은 밝게, 해 진 지역은 어둡게 표현 |
| 장소 클릭 | 마커 클릭 시 해당 장소의 일출/일몰 시간 표시 |
| 숨은 명소 | SNS 인기 기반 15~20개 포토스팟 선정 |

### 2.2 제외 기능 (MVP 이후)

- 커뮤니티/사진 공유 기능
- 날씨/구름 데이터 연동
- 푸시 알림
- 사용자 즐겨찾기

---

## 3. 기술 스택

### 3.1 프레임워크
- **Flutter 3.x** (최신 stable)
- **Dart**

### 3.2 주요 패키지

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
  google_maps_flutter: ^2.5.0
  geolocator: ^10.1.0
  intl: ^0.18.1
  provider: ^6.1.1
  cached_network_image: ^3.3.0  # 이미지 캐싱
  flutter_cache_manager: ^3.3.1
```

### 3.3 외부 API
- **Sunrise-Sunset API** (https://sunrise-sunset.org/api) - 무료
- **Google Maps SDK** - 위성지도 모드 사용

---

## 4. 데이터 구조

### 4.1 숨겨진 명소 데이터 (SNS 인기 기반 선정)

```dart
final List<SpotData> hiddenSpots = [
  
  // ========== 일출 명소 (동해안 + 특별 스팟) ==========
  
  // 강원도
  SpotData(
    name: '주문진 방파제',
    description: '영화 "시월애" 촬영지, 방파제 끝 등대와 일출',
    lat: 37.8983,
    lng: 128.8311,
    type: SpotType.sunrise,
    imageUrl: 'assets/spots/jumunjin.jpg',
    tags: ['등대', '방파제', '고즈넉함'],
  ),
  SpotData(
    name: '하조대',
    description: '소나무 숲 사이로 보이는 일출, 인생샷 명소',
    lat: 38.0125,
    lng: 128.7083,
    type: SpotType.sunrise,
    imageUrl: 'assets/spots/hajodae.jpg',
    tags: ['소나무', '전망대', '일출맛집'],
  ),
  SpotData(
    name: '추암 촛대바위',
    description: '기암괴석과 일출의 환상 조합',
    lat: 37.4789,
    lng: 129.1456,
    type: SpotType.sunrise,
    imageUrl: 'assets/spots/chuam.jpg',
    tags: ['기암괴석', '드라마촬영지'],
  ),
  
  // 경북/울산
  SpotData(
    name: '간절곶 소망길',
    description: '한반도 가장 먼저 해 뜨는 곳 옆 숨은 산책로',
    lat: 35.3589,
    lng: 129.3645,
    type: SpotType.sunrise,
    imageUrl: 'assets/spots/ganjeolgot_trail.jpg',
    tags: ['산책로', '한적함', '첫해'],
  ),
  SpotData(
    name: '경주 문무대왕릉',
    description: '바다 위 수중릉과 일출, 역사+풍경',
    lat: 35.7442,
    lng: 129.5033,
    type: SpotType.sunrise,
    imageUrl: 'assets/spots/munmu.jpg',
    tags: ['역사', '수중릉', '장엄함'],
  ),
  
  // 부산
  SpotData(
    name: '청사포 다릿돌 전망대',
    description: '스카이워크에서 보는 일출, 인스타 핫플',
    lat: 35.1589,
    lng: 129.1875,
    type: SpotType.sunrise,
    imageUrl: 'assets/spots/cheongsapo.jpg',
    tags: ['스카이워크', '인스타핫플'],
  ),
  SpotData(
    name: '오륙도 해맞이공원',
    description: '부산 시내에서 가장 가까운 일출 명소',
    lat: 35.1008,
    lng: 129.1231,
    type: SpotType.sunrise,
    imageUrl: 'assets/spots/oryukdo.jpg',
    tags: ['접근성', '전망대'],
  ),
  
  // 제주 (일출)
  SpotData(
    name: '광치기 해변',
    description: '성산일출봉을 배경으로 한 숨은 포토스팟',
    lat: 33.4612,
    lng: 126.9278,
    type: SpotType.sunrise,
    imageUrl: 'assets/spots/gwangchigi.jpg',
    tags: ['성산일출봉뷰', '한적함', '현지인추천'],
  ),
  SpotData(
    name: '세화 해변',
    description: '제주 동쪽 감성 카페거리와 일출',
    lat: 33.5234,
    lng: 126.8567,
    type: SpotType.sunrise,
    imageUrl: 'assets/spots/sehwa.jpg',
    tags: ['카페거리', '감성', '여유'],
  ),
  
  // ========== 일몰 명소 (서해안 + 특별 스팟) ==========
  
  // 인천/경기
  SpotData(
    name: '시화호 달 전망대',
    description: '거대한 달 조형물과 서해 일몰',
    lat: 37.2856,
    lng: 126.6892,
    type: SpotType.sunset,
    imageUrl: 'assets/spots/sihwa_moon.jpg',
    tags: ['조형물', '전망대', '드라이브'],
  ),
  SpotData(
    name: '대부도 탄도 바닷길',
    description: '모세의 기적, 갈라지는 바다와 일몰',
    lat: 37.2456,
    lng: 126.5978,
    type: SpotType.sunset,
    imageUrl: 'assets/spots/tando.jpg',
    tags: ['바닷길', '물때확인필수'],
  ),
  
  // 충남
  SpotData(
    name: '왜목마을',
    description: '서해에서 일출/일몰 모두 볼 수 있는 유일한 곳',
    lat: 36.9234,
    lng: 126.3567,
    type: SpotType.both,
    imageUrl: 'assets/spots/waemok.jpg',
    tags: ['일출일몰모두', '특이지형', '희귀'],
  ),
  SpotData(
    name: '삽시도',
    description: '배타고 30분, 때묻지 않은 섬 일몰',
    lat: 36.4123,
    lng: 126.3456,
    type: SpotType.sunset,
    imageUrl: 'assets/spots/sapsido.jpg',
    tags: ['섬', '한적함', '모험'],
  ),
  
  // 전북/전남
  SpotData(
    name: '변산 채석강',
    description: '병풍처럼 펼쳐진 절벽과 일몰',
    lat: 35.6234,
    lng: 126.4567,
    type: SpotType.sunset,
    imageUrl: 'assets/spots/chaesukgang.jpg',
    tags: ['절벽', '지질명소', '장엄함'],
  ),
  SpotData(
    name: '신안 퍼플섬',
    description: '보라색 마을과 일몰의 몽환적 조합',
    lat: 34.7456,
    lng: 126.1234,
    type: SpotType.sunset,
    imageUrl: 'assets/spots/purple_island.jpg',
    tags: ['보라색', '인스타핫플', '이색'],
  ),
  SpotData(
    name: '증도 짱뚱어 다리',
    description: '갯벌 위 나무다리와 황금빛 일몰',
    lat: 34.8567,
    lng: 126.1678,
    type: SpotType.sunset,
    imageUrl: 'assets/spots/jeungdo.jpg',
    tags: ['갯벌', '나무다리', '황금빛'],
  ),
  
  // 제주 (일몰)
  SpotData(
    name: '판포포구',
    description: '현지인만 아는 제주 서쪽 숨은 일몰 스팟',
    lat: 33.3789,
    lng: 126.1678,
    type: SpotType.sunset,
    imageUrl: 'assets/spots/panpo.jpg',
    tags: ['현지인추천', '한적함', '어촌'],
  ),
  SpotData(
    name: '수월봉',
    description: '엄청난 절벽뷰와 차귀도 배경 일몰',
    lat: 33.3123,
    lng: 126.1789,
    type: SpotType.sunset,
    imageUrl: 'assets/spots/suwolbong.jpg',
    tags: ['절벽', '차귀도뷰', '웅장함'],
  ),
  SpotData(
    name: '새별오름',
    description: '오름 정상에서 보는 360도 파노라마 일몰',
    lat: 33.3634,
    lng: 126.3567,
    type: SpotType.sunset,
    imageUrl: 'assets/spots/saebyeol.jpg',
    tags: ['오름', '360도뷰', '트레킹'],
  ),
];
```

### 4.2 데이터 모델

```dart
enum SpotType { sunrise, sunset, both }

class SpotData {
  final String name;
  final String description;
  final double lat;
  final double lng;
  final SpotType type;
  final String imageUrl;
  final List<String> tags;
  
  // API에서 가져올 데이터
  DateTime? sunriseTime;
  DateTime? sunsetTime;
  bool? isDaytime;  // 현재 해가 떠있는지
}
```

### 4.3 명암 상태 계산

```dart
enum SunStatus {
  beforeSunrise,  // 일출 전 (어두움)
  sunrise,        // 일출 중 (주황빛)
  daytime,        // 낮 (밝음)
  sunset,         // 일몰 중 (주황빛)
  afterSunset,    // 일몰 후 (어두움)
}
```

---

## 5. 화면 구성

### 5.1 메인 화면 구조

```
┌─────────────────────────────────────┐
│  SunTime          📍현위치    ⚙️   │
├─────────────────────────────────────┤
│                                     │
│   ┌─────────────────────────────┐   │
│   │                             │   │
│   │    [위성지도 - Satellite]    │   │
│   │                             │   │
│   │  🌅        ┌───┐            │   │
│   │ (어두운    │ 📷 │   밝은     │   │
│   │  오버레이) └───┘   영역)    │   │
│   │     ┌───┐                   │   │
│   │     │ 📷 │ ← 원형 사진 마커  │   │
│   │     └───┘                   │   │
│   │              ┌───┐          │   │
│   │              │ 📷 │          │   │
│   │              └───┘          │   │
│   └─────────────────────────────┘   │
│                                     │
├─────────────────────────────────────┤
│  ≡  20개 명소 발견                  │
└─────────────────────────────────────┘
```

### 5.2 마커 클릭 시 상세 카드

```
┌─────────────────────────────────────┐
│                                     │
│   [위성지도 - 선택된 마커 확대]      │
│                                     │
├─────────────────────────────────────┤
│ ┌─────────────────────────────────┐ │
│ │  ┌──────┐                       │ │
│ │  │ 📷   │  주문진 방파제         │ │
│ │  │ 사진  │  "시월애" 촬영지       │ │
│ │  └──────┘                       │ │
│ │                                 │ │
│ │  ☀️ 일출  06:42                 │ │
│ │  🌙 일몰  18:23                 │ │
│ │                                 │ │
│ │  🏷️ #등대 #방파제 #고즈넉함      │ │
│ │                                 │ │
│ │  [ 🧭 길찾기 ]  [ 📸 사진보기 ]  │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

### 5.3 명암 오버레이 시각화

```dart
// 해가 진 지역: 반투명 어두운 오버레이
Color darkOverlay = Colors.black.withOpacity(0.4);

// 해가 뜬 지역: 투명 (원본 위성사진)
Color lightArea = Colors.transparent;

// 일출/일몰 중: 주황빛 그라데이션
Color goldenHour = Colors.orange.withOpacity(0.2);
```

---

## 6. 핵심 구현 상세

### 6.1 위성지도 설정

```dart
GoogleMap(
  mapType: MapType.satellite,  // 위성지도 모드
  initialCameraPosition: CameraPosition(
    target: LatLng(36.5, 127.5),  // 한국 중심
    zoom: 7,
  ),
  // ...
)
```

### 6.2 원형 사진 마커 생성

```dart
Future<BitmapDescriptor> createPhotoMarker(String imageUrl) async {
  // 1. 이미지 로드
  // 2. 원형으로 크롭
  // 3. 테두리 추가 (일출: 주황, 일몰: 보라)
  // 4. BitmapDescriptor로 변환
  
  final size = 80.0;  // 마커 크기
  final borderWidth = 4.0;
  
  // Canvas로 원형 마커 생성
  final pictureRecorder = ui.PictureRecorder();
  final canvas = Canvas(pictureRecorder);
  
  // 테두리 색상 (시간대에 따라)
  final borderColor = isDaytime ? Colors.orange : Colors.purple;
  
  // 원형 클리핑 + 이미지 그리기
  // ...
  
  return BitmapDescriptor.fromBytes(markerBytes);
}
```

### 6.3 명암 오버레이 구현

```dart
class DayNightOverlay extends StatelessWidget {
  final List<SpotData> spots;
  
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: DayNightPainter(spots),
    );
  }
}

class DayNightPainter extends CustomPainter {
  // 태양 위치 기반으로 동쪽→서쪽 그라데이션
  // 해가 진 영역은 어둡게, 해가 뜬 영역은 밝게
  
  @override
  void paint(Canvas canvas, Size size) {
    // 현재 시간 기준 태양 경도 계산
    final sunLongitude = calculateSunLongitude(DateTime.now());
    
    // 어두운 영역 그리기 (태양 서쪽)
    final darkPaint = Paint()
      ..color = Colors.black.withOpacity(0.4)
      ..style = PaintingStyle.fill;
    
    // 그라데이션으로 자연스럽게 전환
    // ...
  }
}
```

### 6.4 장소 클릭 시 일출/일몰 정보

```dart
void onMarkerTapped(SpotData spot) async {
  // API 호출하여 해당 좌표의 일출/일몰 시간 가져오기
  final sunData = await fetchSunData(spot.lat, spot.lng);
  
  // 바텀시트로 상세 정보 표시
  showModalBottomSheet(
    context: context,
    builder: (context) => SpotDetailSheet(
      spot: spot,
      sunriseTime: sunData.sunrise,
      sunsetTime: sunData.sunset,
      currentStatus: calculateSunStatus(sunData),
    ),
  );
}
```

---

## 7. 폴더 구조

```
lib/
├── main.dart
├── models/
│   ├── spot_data.dart
│   ├── sun_data.dart
│   └── sun_status.dart
├── services/
│   ├── sunrise_api_service.dart
│   ├── location_service.dart
│   └── marker_generator_service.dart
├── providers/
│   ├── spots_provider.dart
│   └── sun_status_provider.dart
├── screens/
│   ├── splash_screen.dart
│   └── map_screen.dart
├── widgets/
│   ├── photo_marker.dart
│   ├── day_night_overlay.dart
│   ├── spot_detail_sheet.dart
│   └── spot_info_card.dart
├── painters/
│   └── day_night_painter.dart
├── constants/
│   ├── spots_data.dart       # 20개 명소 데이터
│   └── app_theme.dart
└── utils/
    ├── sun_calculator.dart   # 태양 위치 계산
    └── image_utils.dart      # 마커 이미지 처리

assets/
├── spots/                    # 명소 사진들
│   ├── jumunjin.jpg
│   ├── hajodae.jpg
│   └── ... (20개)
└── icons/
    ├── sunrise_icon.png
    └── sunset_icon.png
```

---

## 8. 개발 일정

### 8.1 전체 일정: 3주 (15일)

| 단계 | 기간 | 작업 내용 |
|------|------|----------|
| **1단계** | 1~2일 | 프로젝트 세팅, 명소 데이터 수집 |
| **2단계** | 3~4일 | API 연동, 데이터 모델 구현 |
| **3단계** | 5~7일 | 위성지도 + 원형 사진 마커 구현 |
| **4단계** | 8~10일 | 명암 오버레이 시각화 구현 |
| **5단계** | 11~13일 | 상세 카드 UI, 인터랙션 구현 |
| **6단계** | 14~15일 | 테스트 및 최적화 |

---

## 9. 리스크 및 대응

| 리스크 | 영향 | 대응 방안 |
|--------|------|----------|
| 원형 마커 성능 | 고 | 마커 이미지 사전 캐싱, 화면 내 마커만 렌더링 |
| 명소 사진 저작권 | 중 | 직접 촬영 or 무료 이미지 사용, 출처 표기 |
| 명암 오버레이 복잡도 | 중 | 단순 동서 분할로 시작, 점진적 개선 |
| 위성지도 로딩 속도 | 하 | 로딩 인디케이터, 지도 타일 캐싱 |

---

## 10. 성공 지표

### MVP 완료 기준
- [ ] 위성지도 모드 정상 작동
- [ ] 20개 명소 원형 사진 마커 표시
- [ ] 마커 클릭 시 일출/일몰 시간 정확히 표시
- [ ] 해 뜬/진 영역 명암 구분 시각화
- [ ] 3초 이내 초기 로딩 완료

---

## 11. 다음 단계 (MVP 이후)

1. **2차**: 실시간 구름/날씨 오버레이
2. **3차**: 사용자 사진 업로드 기능
3. **4차**: 커뮤니티 (포토스팟 추천/리뷰)
4. **5차**: AR 모드 (카메라로 일출/일몰 위치 미리보기)

---

*작성일: 2025년 1월 31일*
*수정일: 2025년 1월 31일 (v2 - 위성지도, 숨은 명소, 명암 시각화, 사진 마커 추가)*