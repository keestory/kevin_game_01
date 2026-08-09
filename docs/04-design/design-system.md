# Draft Design System — 한 칸만! 만원열차

> 상태: DRAFT / 현재 구현 감사본
> 현재 단계: Stage 0/1 재검증
> 색상·폰트·모션은 사용성·접근성 테스트 전 확정 토큰이 아니다.

## 1. 디자인 원칙

1. **한눈에 규칙:** 장식보다 다음 승객, 선택 열, 보드 위험도를 먼저 보인다.
2. **한국적이되 비공식:** 지하철 안내 감성을 사용하되 실제 기관·노선·상표를 복제하지 않는다.
3. **색 이외의 의미:** 색, 도형, 텍스트를 중복 사용한다.
4. **실패는 정보:** 비난·압박 대신 실패 원인과 무료 다음 행동을 보여준다.
5. **광고는 거래:** 광고 여부, 정확한 보상, 거절 결과를 숨기지 않는다.
6. **모션은 선택:** Reduce Motion에서 지속 이동과 입자를 실질적으로 줄인다.

## 2. 현재 색상 토큰

| Token | Hex | 현재 용도 | 검증 상태 |
|---|---:|---|---|
| `trainNavy` | `#10182C` | 앱 배경, 어두운 전경 | 대비 일부 미측정 |
| `trainPanel` | `#182541` | 창·패널 | 대비 미측정 |
| `safetyYellow` | `#FFD84D` | Primary CTA, 선택기, 시간 | 밝은 배경 위 사용 주의 |
| `exitMint` | `#36D6A0` | 성공·도움 상태 | 텍스트 대비 미측정 |
| `alertCoral` | `#FF665F` | 위험·구조 | 색만으로 위험 표시 금지 |
| `warmIvory` | `#F7F3E8` | 객실·튜토리얼 카드 | 어두운 텍스트 사용 |
| `passengerCircle` | `#FF6B72` | 동그라미 목적지 | `●` 병기 |
| `passengerTriangle` | `#3FD4A2` | 세모 목적지 | `▲` 병기 |
| `passengerStar` | `#FFD84D` | 별 목적지 | `★` 및 어두운 문자 병기 |
| `passengerSquare` | `#7B9CFF` | 네모 목적지 | `■` 병기 |
| `passengerTransfer` | `#B993FF` | 환승객 | `↔` 병기 |

### 색상 수용 기준

- 일반 크기 텍스트 WCAG 2.2 AA 4.5:1, 큰 텍스트 3:1을 도구로 측정한다.
- 컨트롤 경계·상태 표현은 인접 색 대비 3:1을 목표로 한다.
- `alertCoral` 또는 `exitMint`만으로 성공·실패를 전달하지 않는다.
- 반투명 material은 실제 배경 조합별 대비를 캡처해 측정한다.

현재 대비 측정 보고서가 없으므로 `충분한 대비 지원`을 주장할 수 없다.

## 3. Typography

### 목표 체계

| 역할 | SwiftUI 목표 | 최소 | 비고 |
|---|---|---:|---|
| Display title | `.largeTitle`/custom relative | 28pt | Dynamic Type 상대 크기 |
| Screen title | `.title` | 24pt | 줄바꿈 허용 |
| Primary score | custom relative | 34pt | monospaced digits 허용 |
| Body | `.body` | 17pt | 기본 설명 |
| Supporting | `.subheadline` | 15pt | 핵심 정보 대체 금지 |
| Caption | `.caption` | 12pt | 부가 정보만 |
| Game absolute minimum | custom relative | 11pt | Apple 게임 최소; 필수 HUD는 더 크게 |

### 현재 상태와 남은 충돌

- HUD 최소 라벨은 11pt로 조정되어 코드 기준 최소선을 충족한다.
- SpriteKit 텍스트는 Dynamic Type과 자동 연결되지 않는다.
- 홈의 52pt 고정 제목은 작은 화면·Larger Text에서 재배치 검증이 필요하다.
- 숫자 애니메이션은 Reduce Motion 시 정적 갱신을 검토한다.

한국어는 `Apple SD Gothic Neo`/시스템 글꼴을 사용하고 자간을 과도하게 줄이지 않는다. 영문 브랜드용 `Avenir Next` 사용은 한국어 대체와 기준선 정렬을 확인한다.

## 4. Spacing & Layout

기본 단위는 4pt이며 주요 간격은 `4, 8, 12, 16, 20, 24, 32`를 사용한다.

- 화면 좌우 기본 여백: 20pt.
- 카드 내부 여백: 18~20pt.
- 주요 CTA 세로 패딩: 16~17pt.
- 컨트롤 기본 목표 크기: 44×44pt 이상.
- 세로 화면은 iPhone SE급과 19.5:9 대형 기기를 모두 검증한다.
- 노치·Dynamic Island·Home Indicator는 safe area를 침범하지 않는다.
- 게임 보드는 fixed 390×844 논리 크기를 사용하더라도 실제 안전 영역과 HUD 충돌을 확인한다.

현재 일시정지 버튼은 44×44pt로 코드 기준 목표를 충족한다. 나머지 화면은 기기·Larger Text 조합에서 계속 검증한다.

## 5. Components

### Primary Button

- 용도: 운행 시작, 다음 역, 재도전.
- 배경 `safetyYellow`, 전경 `trainNavy`.
- 한 화면에 원칙적으로 1개.
- 눌림 상태는 색·크기 변화와 필요 시 햅틱 병행.
- Reduce Motion에서는 spring scale을 제거한다.

### Secondary Button

- 용도: 공유, 보조 행동.
- Primary보다 위계가 낮지만 읽을 수 있는 대비를 유지한다.
- 광고 CTA를 무조건 Primary로 두지 않는다. 실패 화면의 무료 재도전이 최소 동등하게 접근 가능해야 한다.

### Destructive/Tertiary

- `홈으로`, `결과 보기` 등.
- 낮은 위계가 낮은 가독성을 의미하지 않는다.
- 죄책감 유발 문구를 사용하지 않는다.

### Glass Card

- 정보 그룹화 전용.
- 반투명 배경 위 텍스트 대비를 각 화면에서 측정한다.
- 장식성 glass가 로딩·오류·선택 상태를 대신하지 않는다.

### Passenger Token

- 색 + 도형 + 선택적으로 이름.
- 최소 시각 크기와 외곽선은 작은 화면에서 도형이 뭉개지지 않게 한다.
- 환승객 `↔`는 양방향 화살표가 이동 제스처로 오해되는지 테스트한다.

### HUD

우선순위는 `점수/목표`, `시간`, `안전 손잡이`, `일시정지`다.

- 필수 정보는 화면 상단 3개 그룹을 넘지 않게 한다.
- 타이머는 숫자와 원형 진행을 함께 사용한다.
- 손잡이는 개수와 이름을 함께 표시한다.
- VoiceOver에서는 변화가 잦은 점수를 매 프레임 읽지 않고 의미 있는 시점만 알린다.

### Overlays

튜토리얼, 일시정지, 구조 제안은 배경 상호작용을 차단하되 현재 맥락을 설명한다. Focus order는 제목 → 설명 → Primary → Secondary → 종료 순서다.

## 6. Motion & Haptics

| 사건 | 기본 피드백 | Reduce Motion 목표 |
|---|---|---|
| 선택기 이동 | 좌우 지속 이동 | 접근성 대체 입력/감속 검증 필요 |
| 승객 배치 | 0.15초 낙하 | 짧은 crossfade 또는 즉시 배치 |
| 매치 | 확대·입자·성공 햅틱 | 입자 제거, 정적 강조+햅틱 |
| 역 보너스 | 확대+fade | fade만 또는 즉시 텍스트 |
| 위험 | 경고 햅틱+coral | 흔들림 없이 열 외곽선+문구 |
| 화면 전환 | opacity/move | crossfade 또는 즉시 전환 |

현재 `accessibilityReduceMotion`은 SwiftUI 전환 일부에만 적용되고 SpriteKit 지속 이동·입자를 제어하지 않는다. 지원 완료가 아니다.

햅틱:

- Perfect: 가벼운 impact, 60ms 이하 중복 제한.
- Match: success notification.
- Overflow: warning notification.
- 햅틱은 끌 수 있어야 하며 정보의 유일한 채널이 될 수 없다.

## 7. Content Style

- 짧고 구체적인 한국어, 한 CTA에는 한 행동.
- `다시 운행`, `결과 보기`, `광고 1회 보고 구조`처럼 결과를 예상 가능하게 한다.
- 실패: `한 칸만 비웠다면 출발!`처럼 회복 가능성을 전달하되 실제 원인 정보를 함께 제공한다.
- 금지: `포기할 건가요?`, `무료 기회를 버리시겠어요?`, 가짜 희소성.
- 현재 텍스트 공유는 `친구에게 기록 공유하기`로 기능과 일치한다.
- 실제 역 번호는 문자열 보간으로 표시한다. 현재 코드와 회귀 테스트에서 이를 확인했다.

## 8. Localization

- 모든 사용자 문구를 Strings Catalog 키로 관리하는 것이 목표다.
- 키는 화면이 아니라 의미 기반으로 작성한다. 예: `rescue.offer.reward_summary`.
- 한국어 조사 결합을 피하려면 숫자+단위 전체를 지역화한다.
- 날짜 기반 시드는 사용자-facing 날짜와 분리한다.
- `만원열차`, `막차`, `환승`은 글로벌 출시 시 문화적 대응어를 현지 검증한다.
- 실제 기관 상표·고유 노선 색 조합을 의도적으로 모사하지 않는다.

## 9. Design Gate

현재 **Fail**이다. 대비 측정, 최대 Larger Text, VoiceOver 핵심 과업, Reduce Motion, 5명 사용성 테스트가 완료되지 않았다.
