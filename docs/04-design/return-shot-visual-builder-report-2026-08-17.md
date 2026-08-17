# Return Shot Visual Builder Report

- 확인일: 2026-08-17 KST
- 단계: Stage 6 Implementation
- Gate: `Revise-Go` — 시각 MVP와 자동 상호작용 검증은 통과, 실제 사용자 재미·유지 검증은 미통과
- 기본 변형: A `Precision Neon`
- 비교 변형: B `Impact Pop` (`-visualB` launch argument)

## 목표와 검증 범위

열차 prototype을 대체한 `연쇄파괴: 리턴 샷`의 최소 기능 버전을 실제 iOS 앱으로 구현하고, ImageGen 배경과 코드 기반 플레이 오브젝트를 합성한 뒤 iPhone 화면을 반복 캡처·검사했다. 이번 Gate는 시각 위계, 조작 명료성, 모바일 레이아웃, 핵심 사용자 흐름 및 deterministic core의 기술적 성립까지만 판정한다. 한국 App Store 1위, 재미, D1/D7, CPI/LTV는 이번 증거로 주장하지 않는다.

## 구현된 최소 기능

- 한 엄지 패들 드래그와 접촉 위치·패들 속도 기반 반사각
- 점수, endless 높이, 파괴 콤보, 개인 최고 기록선과 동일 seed 재도전
- 색·무늬·마크 LINK 5연속과 6초 공명 폭주
- 3회 타격 프리즘 보너스 벽돌
- 직접 적중 시 `-250`, 지지 붕괴로 간접 제거 시 `+120`인 마이너스 벽돌
- 120Hz 고정 tick, swept collision, support graph collapse
- 홈, 설정, 게임 HUD, 튜토리얼, 일시정지, 결과, 공유
- 광고·친구 설치·계정·서버·유료 부스터 없음

## ImageGen + Vision 반복

ImageGen은 중앙 70%가 저대비인 어두운 kinetic laboratory shaft 배경만 생성했다. 공, 패들, 벽돌, 지지선, HUD, 판정은 모두 SwiftUI/SpriteKit 코드로 그려 실제 상태와 일치하게 유지했다. 대포, 유리 복도, 기차, 캐릭터, 로고, 글자와 벽돌은 프롬프트에서 제외했다. 생성·사용 기록은 `docs/ASSET_PROVENANCE.md`에 남겼다.

### 첫 캡처에서 발견한 문제

| 심각도 | 문제 | 수정 |
|---|---|---|
| P0 | 상단 HUD와 첫 벽돌 행이 겹쳐 점수와 목표를 동시에 읽기 어려움 | 구조 시작 높이를 낮추고 행 간격을 조정해 HUD 아래에 독립 플레이 영역 확보 |
| P1 | HUD와 SpriteKit 피드백이 같은 정보를 중복 표시 | SwiftUI 단일 HUD·상태 pill로 통합하고 SpriteKit 중복 레이블 제거 |
| P1 | 색만으로 LINK와 벽돌을 구분하기 쉬움 | 큰 마크, 실제 stripe/dot/grid 무늬, 형태, 내구도 pip를 함께 표시 |
| P1 | 지지 관계와 마이너스 제거 전략이 약함 | 지지선을 굵게 하고 마이너스 경고선·`직접 -250` 표기 추가 |
| P1 | 홈 통계 제목이 8pt이고 저대비 | 10pt, 대비 상승, 숫자는 16pt monospaced 유지 |
| P1 | 장식 배경이 VoiceOver 요소로 노출 | 장식 Image를 accessibility tree에서 제외 |
| P1 | UI fast-fail이 드래그 전에 종료돼 테스트가 경합 | 재개 동작 이후에만 fast-fail을 arm하도록 변경 |
| P1 | 작은 기기 검증 부재 | iPhone 17e에서 별도 실행·캡처, 핵심 요소 clipping 없음 확인 |
| P0 | 중앙 튜토리얼 뒤로 공이 지나갈 수 있음 | 튜토리얼을 HUD 아래 예약 band로 이동하고 top wall을 540pt로 제한; 권위 공이 band에 진입하지 않는 회귀 테스트 추가 |
| P0 | 벽돌에 실제 지지점이 2개인데 첫 번째 선만 표시 | 모든 `supportIDs` 연결을 그리고 지지점 제거 시 연결선도 즉시 제거 |
| P0 | 17e는 390×844급이라 SE 검증을 대체하지 못함 | iPhone SE 3세대 375×667 시뮬레이터를 생성해 별도 실캡처, 무겹침 확인 |
| P1 | 앱 아이콘과 미사용 번들이 과거 열차 prototype | ImageGen Return Shot 아이콘으로 교체하고 열차 자산 3종은 문서 archive로 이동 |
| P1 | SE 결과 첫 화면에 핵심 재도전 CTA가 보이지 않음 | 상세 통계보다 `같은 구조 다시`를 위로 이동하고 SE 전체 흐름을 재실행해 첫 화면 노출 확인 |
| P1 | 홈 공유 hit target·결과 통계 보조 텍스트가 약함 | 공유 영역 최소 44pt, 보조 텍스트 opacity 68%로 상향 |

### 최종 캡처

- A 홈: `docs/screenshots/return-shot-precision-home.png`
- A 게임: `docs/screenshots/return-shot-precision-game.png` (1206×2622)
- A 결과: `docs/screenshots/return-shot-precision-result.png`
- B 홈: `docs/screenshots/return-shot-impact-home.png`
- B 게임: `docs/screenshots/return-shot-impact-game.png` (1206×2622)
- B 결과: `docs/screenshots/return-shot-impact-result.png`
- 작은 화면 A 게임: `docs/screenshots/return-shot-17e-game.png` (1170×2532)
- SE A 게임: `docs/screenshots/return-shot-se-game.png` (750×1334, 375×667pt)
- SE A 홈: `docs/screenshots/return-shot-se-home.png` (750×1334)
- SE A 결과: `docs/screenshots/return-shot-se-result.png` (750×1334, 재도전 CTA 첫 화면 노출)
- 이전 상태 비교: `docs/screenshots/return-shot-a-*.png`

## 최종 시각 QA

| 검사 기준 | 판정 | 근거 |
|---|---|---|
| 시각적 위계 | Pass | HUD → 벽돌 구조 → 튜토리얼 → 공·패들 순으로 분리 |
| 간격 | Pass | iPhone 17 Pro/17e/SE에서 HUD·벽돌·안내·패들 clipping 없음 |
| 대비 | Pass | 중앙 저대비 배경 위 white/mint/coral/blue 대상 대비 유지 |
| 텍스트 가독성 | Pass with debt | 핵심 HUD·CTA는 충분함. 작은 보조 수치의 Dynamic Type 확대 검증은 후속 |
| 반응형 레이아웃 | Pass for tested phones | 17 Pro 1206×2622, 17e 1170×2532, SE home/game/result 750×1334 실캡처 통과 |
| hover | N/A | touch-only iPhone 앱. 44pt 이상 hit target과 pressed feedback으로 대체 |
| 모바일 사용성 | Pass for MVP | 세로 한 엄지 조작, HUD가 플레이 영역을 가리지 않음 |
| 클릭 명확성 | Pass | 노란 primary CTA, 44pt 일시정지, 결과의 우선 재도전 CTA |
| 흐름 자연스러움 | Pass automated | 홈→시작→드래그→일시정지→재개→결과→같은 seed 재도전 성공 |
| 접근성 | Revise | 색 외 마크·무늬·형태와 장식 숨김 반영. VoiceOver 실사용·Dynamic Type 전체 검증은 남음 |

## A/B 변형 판정

### A — Precision Neon, 기본안

- 차가운 navy panel, mint edge, 중립 회색 지지선
- 판단 대상의 색·무늬·마크가 구조선보다 먼저 읽힘
- PB 추격과 정밀 반사 숙련을 강조

### B — Impact Pop, challenger

- 따뜻한 purple panel, amber outline, 노란 지지선
- 붕괴와 보너스 구조의 에너지는 강하지만 선이 벽돌보다 앞서 보여 시각 부하가 큼
- 현재는 코드 경로를 유지하되 기본 출시 후보로 선택하지 않음

이 비교는 화면 품질에 대한 전문가 휴리스틱 판정이지 사용자 A/B 결과가 아니다. 8~15명 사용성 관찰 및 동일 creative 노출 실험 전에는 A의 재미·전환 우위를 주장하지 않는다.

## 추출된 디자인 규칙

1. 게임 HUD의 최대 높이는 safe area 아래 약 96pt로 제한하고 첫 playable object와 최소 12pt의 명확한 간격을 둔다. 안내 band는 권위 공의 top wall 밖이어야 한다.
2. 기록 추격 정보는 현재 점수·높이·콤보, LINK, PB 차이만 한 panel에 둔다. 같은 피드백을 SpriteKit과 SwiftUI에서 중복하지 않는다.
3. 상호작용 대상은 배경보다 밝고, 지지 관계는 대상보다 한 단계 약하게 그린다. 판정에 존재하는 모든 지지 관계는 보여 주고 위험선만 coral로 승격한다.
4. 색은 의미의 유일한 전달자가 될 수 없다. 모든 eligible 벽돌은 마크, 실제 무늬, 형태를 같이 가진다.
5. 프리즘은 금색 외곽과 3개의 내구도 pip, 마이너스는 큰 `−`와 경고선으로 0.5초 안에 식별 가능해야 한다.
6. 튜토리얼은 첫 리턴 전 한 문장과 한 보조 문장만 보이고 플레이 영역 중앙을 장시간 가리지 않는다.
7. 주요 버튼은 44×44pt 이상, primary action은 노란 full-width CTA 하나만 둔다. native iPhone에는 hover 요구 대신 pressed 상태를 제공한다.
8. ImageGen 자산은 저대비 환경층으로만 사용하고 gameplay truth와 판정은 코드 레이어에서 렌더한다.
9. 새 시각 효과는 공, 낙하지점, 위험 벽돌을 가리지 않아야 하며 Reduce Motion에서 흔들림·파티클을 먼저 줄인다.
10. A/B는 한 번에 표현 계열만 바꾸고 seed·규칙·난이도·문구를 동일하게 유지한다.

## 검증 결과

- generic iOS Simulator app build: 성공
- SwiftPM: 12/12 성공
- Xcode iPhone 17 Pro: app unit 12/12 성공
- XCUITest: 1/1 성공, 22.667초
- 전체 Xcode test: 13/13 성공(규칙 12 + UI 1), 총 114.094초, artifact `/private/tmp/ReturnShotFinalDerived/Logs/Test/Test-AppStoreGame-2026.08.18_00-20-57-+0900.xcresult`
- 실캡처: iPhone 17 Pro A/B, iPhone 17e A, iPhone SE 3세대 375×667 A 통과
- SE UI 전체 흐름: 1/1 성공, 27.898초, artifact `/private/tmp/ReturnShotSEDerived/Logs/Test/Test-AppStoreGame-2026.08.18_00-26-45-+0900.xcresult`

## 남은 Gate

- 타깃 사용자 5명 중 4명의 무설명 첫 리턴 5초 이내
- 5명 중 3명 이상 자발적 3회차, Run 3 기록 중앙값 Run 1 대비 +20%
- active-touch 중앙값 60% 이상, 불공정 죽음·공 관통 0건
- VoiceOver·Dynamic Type·Reduce Motion 실기기 탐색 QA
- 최소 지원 실기기 10분 soak, 60fps 목표·30fps hard floor, 열·메모리 확인
- 한국 no-ad TestFlight D1/D7와 CPI/LTV; 완료 전 한국 무료 1위 가능성은 `Unknown`
