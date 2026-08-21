# 06. Accessibility & Performance

## 1. 접근성 모드

### Reduce Motion

- camera shake multiplier: 0.30
- zoom punch: off
- UI overshoot: off
- trail length: 0.50
- parallax: 0.25
- background drift: 0.40

### Photosensitivity Safe Mode

- full-screen flash: off
- 반복적인 밝기 점멸: 3Hz 미만
- electric luminance pulse: 40% 이하
- explosion core alpha: 0.55 이하
- chromatic aberration: off
- strobing boss warnings: shape pulse로 대체

### Color Assist

- 모든 속성에 고유 아이콘
- 공 shell에 패턴 추가
- 상태 벽돌에 테두리 패턴 추가
- HUD tooltip에 속성명 표시

### High Contrast Ball

- 공 주변 2px 밝은 ring
- 배경과 반대 명도 outline
- trail opacity 최소 0.65

## 2. 광과민성 기준

- 큰 면적의 흰색/적색 점멸을 연속 사용하지 않는다.
- 폭발이 연쇄될 때 전체 화면 플래시는 첫 번째 큰 폭발에만 허용한다.
- 보스 경고는 점멸 대신 크기 변화, 테두리 이동, 패턴 진행을 사용한다.

## 3. 성능 목표

### Desktop mid-tier

- 1440×900, 60 FPS
- frame time p95 < 16.7ms

### Mobile target

- 390×844 CSS px, devicePixelRatio 2 기준
- mid-tier Android/iPhone에서 60 FPS 목표
- frame time p95 < 18ms
- Low FX에서 30 FPS 이하로 장시간 하락하지 않음

## 4. 예산

| 항목 | High | Medium | Low |
|---|---:|---:|---:|
| 활성 파티클 | 420 | 280 | 180 |
| 트레일 샘플/공 | 16 | 10 | 6 |
| 동시 point light 유사 효과 | 8 | 5 | 3 |
| 큰 shockwave | 6 | 4 | 3 |
| 활성 공 | 8 | 8 | 5 |
| 배경 레이어 | 4 | 3 | 2 |

## 5. 자동 품질 조정

다음 조건이 2초 이상 지속되면 한 단계 낮춘다.

- moving average FPS < 48
- frame time p95 > 24ms
- particle pool overflow가 초당 5회 이상

10초 안정 상태 후에만 한 단계 복귀할 수 있다. 보스 연출 중에는 품질 단계를 올리지 않는다.

## 6. 메모리

- 텍스처 atlas 재사용
- 파티클 풀 고정 상한
- 오디오 variation은 압축 포맷과 preload 정책 분리
- 스테이지 전환 시 사용하지 않는 테마 리소스 해제
- 개발자 오버레이에 pool allocated/active 표시

## 7. 물리 안정성

- 최대 delta clamp
- fast ball에 swept collision 또는 substep
- 공이 벽 내부에 갇히면 collision normal 방향으로 depenetration
- 5초 동안 벽돌 충돌이 없으면 soft nudge 또는 angle correction

## 8. QA 기기/뷰포트

필수 확인:

- 390×844 portrait
- 430×932 portrait
- 768×1024 tablet
- 1440×900 desktop
- low-end simulation: 4× CPU throttle 또는 저품질 옵션
