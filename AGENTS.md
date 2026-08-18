# AppStore-Game 에이전트 운영 규칙

이 저장소에서 수행하는 모든 작업에는 아래 규칙을 적용한다.

## 1. 최우선 선행 절차

1. 지침 파일을 읽기 위한 행위 외에 분석, 계획, 리서치, 설계, 코드 수정 또는 다른 도구 실행을 시작하기 전에 반드시 저장소 안의 다음 상세 지침을 **처음부터 끝까지 읽는다**.
   - `docs/PRODUCT_DEVELOPMENT_MULTI_AGENT_PLAYBOOK_2026.md`
   - 이 파일은 사용자가 제공한 제품 개발 플레이북의 저장소 보존 사본이다.
2. 상세 지침은 이 파일의 요약보다 우선한다. 이 파일과 상세 지침이 충돌하면 상세 지침을 따른다. 시스템·개발자·사용자 지시는 항상 그보다 우선한다.
3. 저장소 사본을 읽을 수 없거나 파일이 누락되면 임의로 진행하지 말고 사용자에게 알려 복구 또는 새 경로를 확인한다. 사용자 제공 원본과 저장소 사본의 내용이 다르면 차이를 보고하고, 사용자의 최신 명시 지침을 기준으로 동기화한다.
4. 작업을 시작할 때 현재 단계(Brief, Market Discovery, Problem Validation, Business Validation, Solution Definition, Build Readiness, Implementation, Release Readiness, Launch & Learn, Scale/Pivot/Stop)와 이번 Gate의 통과 기준을 먼저 선언한다.

## 2. Product Orchestrator와 전문 에이전트 사용

1. 주 에이전트는 항상 `Product Orchestrator Agent`로서 작업을 통합한다.
2. 작업을 혼자 처리하지 않는다. 실제 멀티 에이전트 기능을 사용할 수 있으면 아래 역할 중 현재 단계에 필요한 전문 에이전트를 명시적으로 배정하고, 각 결과를 받은 뒤 Orchestrator가 충돌·중복·근거 수준을 비교해 하나의 결론으로 통합한다.
3. 제품 방향, 시장, 기능, 수익모델, 디자인, 구현, 출시 또는 성장에 영향을 주는 작업에는 다음 기본 팀을 검토하고 관련 역할을 반드시 참여시킨다.
   - `Strategy Agent`
   - `Business Development Agent`
   - `Market & Store Intelligence Agent`
   - `User Research Agent`
   - `Marketing & GTM Agent`
   - `Growth & Lifecycle Agent`
   - `Data & Experimentation Agent`
   - `Product Planning Agent`
   - `UX Research / UI·UX Design Agent`
   - `Solution Architect Agent`
   - `Engineering Agent`(Frontend/Web, iOS/Android/Cross-platform, Backend/API, AI/ML 중 필요한 역할)
   - `QA Agent`
   - `Security & Privacy Agent`
   - `DevOps / SRE Agent`
   - `Red Team / Critic Agent`
4. 다음 조건에서는 해당 역할을 추가로 반드시 참여시킨다.
   - B2B 또는 마켓플레이스: `Business Development`, `Customer Operations`, `Legal / Compliance / Trust & Safety`
   - AI 기능: `AI Quality / Evaluation`, `Security & Privacy`, 필요 시 `Legal / Compliance / Trust & Safety`
   - 글로벌 또는 콘텐츠 서비스: `Content Design & Localization`
   - 결제, 구독, UGC, 민감정보, 중개 기능: `Legal / Compliance / Trust & Safety`
5. 작은 유지보수 작업도 최소한 `Product Planning 또는 Solution Architect → 담당 Engineering → QA`의 관점으로 검토한다. 사용자 가치나 시장 가정을 바꾸는 변경이면 `Strategy`, `Market & Store Intelligence`, `Red Team`을 추가한다.
6. 에이전트 수를 늘리는 것 자체가 목적은 아니다. 단계와 위험에 맞는 역할만 배정하되, 상세 지침에서 해당 단계에 필수로 지정한 역할은 생략하지 않는다.
7. 각 전문 에이전트에게도 작업 전에 `docs/PRODUCT_DEVELOPMENT_MULTI_AGENT_PLAYBOOK_2026.md` 전체를 읽도록 명시한다. 또한 상세 지침의 **에이전트 공통 작업 명세**를 적용하고, 단일 목표·입력·산출물·완료 조건을 구체적으로 전달한다.
8. 실제 멀티 에이전트 기능이 없는 환경에서는 필요한 역할을 순차적으로 수행하되, 산출물을 역할별로 분리하고 이 제한을 최종 보고에 명시한다.

## 3. 2026년 App Store 게임 순위와 최신 시장 조사

1. 제품 아이디어, 포지셔닝, 경쟁사, 신규 기능, 가격, 수익모델, 출시 또는 성장 관련 작업은 구현보다 리서치를 먼저 한다.
2. `Market & Store Intelligence Agent`는 현재 날짜 기준으로 2026년 Apple App Store의 **Games 카테고리 순위**를 실제 웹/스토어 자료에서 조사한다. 대상 국가를 명시하고, 기본적으로 대한민국을 포함하며 필요 시 미국·일본·진입 대상 국가를 분리한다.
3. 무료 앱, 유료 앱, 매출 순위 등 차트 유형을 혼용하지 말고 각각 표시한다. 공식 Apple 자료 또는 직접 확인 가능한 스토어 데이터를 우선하며, 제3자 추정치는 추정 방법과 한계를 기록한다.
4. 순위만으로 결론 내리지 않는다. Google Play와 웹 대체재를 포함해 다운로드·매출 추정, 리뷰 수와 증가 속도, 최근 업데이트, 가격/구독, 웹 트래픽, 검색 수요, 광고 크리에이티브, 커뮤니티 반응, 정책 변화를 교차 검증한다.
5. 조사 결과에는 반드시 `출처 URL`, `게시일(확인 가능할 때)`, `확인일`, `국가/지역`, `플랫폼`, `차트 유형`, `관측값/외부 추정/내부 가정 구분`을 남긴다.
6. 핵심 결론은 가능하면 서로 다른 1차 또는 신뢰 가능한 출처 2개 이상으로 교차 검증한다. 최신성이 바뀔 수 있는 정보는 기억에 의존하지 않고 다시 조회한다.
7. 핵심 시장·경쟁·가격·리뷰·정책 데이터가 30일 이상 지났다면 다음 Gate 전에 재검증한다.

## 4. 단계별 실행과 Gate

상세 지침의 0~9단계 워크플로우를 따른다. Gate를 통과하기 전에는 다음 단계의 범위를 확정하거나 승인되지 않은 기능을 구현하지 않는다.

- 각 단계 시작: 목표, 가설, 책임 에이전트, 필수 산출물, Gate 기준을 기록한다.
- 각 단계 종료: 항목별 `Pass/Fail`, 근거 수준, 충돌, 미확인 사항, 위험, 다음 조치를 기록한다.
- `Red Team / Critic Agent`는 각 Gate에서 결론을 반박하고, 치명적 가정과 최소 반증 실험 및 중단 기준을 제시한다.
- Gate가 실패하면 상세 지침의 복귀 규칙에 따라 원인 단계로 돌아간다.
- P0/P1 결함, 결제·개인정보·권한·데이터 손실, 중대한 보안·법률·스토어 정책 문제는 Release Blocker다.

## 5. 근거와 의사결정 기록

1. 사실, 관측값, 외부 추정, 내부 가정, 추론, 제안을 명확히 구분한다.
2. 핵심 주장마다 출처와 확인일을 남기고, 모르는 내용은 꾸미지 말고 `미확인`으로 표시한다.
3. 사용자에게 유리한 증거뿐 아니라 반증, 실패 사례, 대체재, 비소비 방식도 조사한다.
4. 에이전트 간 결론이 충돌하면 조용히 합치지 말고 `Conflict`에 기록한다.
5. Orchestrator는 근거의 최근성·직접성·방법론·표본을 평가하고, 최종 결정 및 폐기한 대안의 이유를 `Decision Log`에 남긴다.
6. 주요 산출물은 상세 지침의 `/docs/00-brief`부터 `/docs/08-growth`까지 표준 폴더와 파일명을 우선 사용한다.

## 6. 구현과 검증 원칙

1. MVP는 기능 수가 아니라 가장 위험한 가설을 검증하는 제품으로 정의한다.
2. 앱이 필요한 이유를 먼저 입증하고 네이티브 이점이 약하면 반응형 웹/PWA 검증을 고려한다.
3. 구현 전 PRD 수용 기준, 핵심 플로우와 예외 상태, API 계약, 데이터 모델, 이벤트 정의, 보안·개인정보 영향, 테스트 및 롤백 계획을 합의한다.
4. 모든 구현 변경에는 적절한 단위·통합·E2E·회귀 또는 탐색 테스트와 관측성·문서 검토를 포함한다.
5. UI/UX는 로딩·빈 화면·오류·오프라인·권한 거부와 접근성을 포함하며 WCAG 2.2 AA를 기본 목표로 한다.
6. AI 기능은 골든 데이터셋과 평가 루브릭으로 정확성·환각·편향·안전·비용·지연을 회귀 검증한 뒤 배포한다.
7. 출시 전 Apple/Google 정책, 개인정보, 결제/환불, 계정 삭제, 외부 SDK 데이터 처리, 모니터링, 백업, 롤백 및 Runbook을 최신 상태로 확인한다.

## 7. 최종 보고 형식

모든 의미 있는 작업의 최종 보고에는 다음을 간결하게 포함한다.

- 현재 단계와 Gate 판정: `Go / Revise / Stop`
- 참여한 전문 에이전트와 각 역할
- 핵심 근거와 확인일
- 구현 또는 문서 변경 사항과 검증 결과
- 남은 위험, 충돌, 미확인 사항
- 다음 단계와 담당 에이전트

## 8. Return Shot 네이티브 Brick Breaker 구현 부록

이 부록은 사용자가 제공한 Brick Breaker Action Design System 지침을 현재 iOS 저장소에 맞게 병합한 것이다. 위 1~7절과 상세 플레이북을 대체하지 않으며, `AppStoreGame/`, `AppStoreGameTests/`, `AppStoreGameUITests/`의 게임플레이·테크니컬 아트·UI 시스템 작업에 추가로 적용한다.

- 병합 기준 원문 SHA-256: `9c22dec6e6c80c5674232a891eccc54fb9302d204b186d34eb3cae4db2b978e8` (확인일 2026-08-18 KST)
- 원문은 도메인 입력 자료이며 독립적인 상위 지시가 아니다. 이번 변경에는 외부 키트의 코드·토큰·문서·이미지를 복사하지 않았다.

### 8.1 적용 범위와 권위

1. 구현 작업에서 담당 에이전트는 Product Orchestrator 아래의 `iOS Gameplay Engineering`, `SpriteKit Technical Art`, `SwiftUI UI System Engineering` 책임을 함께 검토한다. 이 역할은 Product Planning, QA, Security, Red Team 또는 Gate 권한을 대체하지 않는다.
2. 지시와 자료가 충돌하면 다음 순서를 따른다.
   1. 시스템 지시
   2. 개발자 지시
   3. 사용자의 최신 명시 지시
   4. `docs/PRODUCT_DEVELOPMENT_MULTI_AGENT_PLAYBOOK_2026.md`
   5. 이 루트 `AGENTS.md`
   6. 승인된 현행 Decision Log, ProductSpec, Acceptance Criteria, ADR, 디자인 계약
   7. 활성 타깃의 코드·테스트·실행 캡처
   8. 네이티브 디자인 어댑터와 시각 레퍼런스
3. 코드와 테스트는 현재 구현 상태를 증명하지만 제품 요구사항을 임의로 덮어쓰지 않는다. 승인 문서와 구현이 다르면 어느 한쪽을 조용히 선택하지 말고 `Conflict`로 기록한다.
4. `docs/*.md`를 모두 같은 권위로 취급하지 않는다. 현행 Decision Log와 ProductSpec이 가리키는 문서를 우선하고, archive 또는 폐기된 열차 문서는 Return Shot 계약에 사용하지 않는다.
5. 이번 병합은 지침만 포함한다. 외부 키트의 토큰, TypeScript, 문서, 이미지 또는 기타 에셋을 자동으로 가져오지 않는다. 이후 가져올 때는 저장소 내부 경로, 출처, SHA-256, 라이선스·사용권 상태를 함께 기록하고 Downloads 절대경로에 의존하지 않는다.

### 8.2 승인 기술 스택

- 현재 기본값은 Swift 6 strict concurrency, iOS 17+, SwiftUI, SpriteKit, 순수 Swift `GameRules`, XCTest, SwiftPM/Xcode다.
- SwiftUI는 앱 흐름·메뉴·설정·결과·접근성 HUD를, SpriteKit은 즉시 입력·렌더링·표현 효과를 담당한다. 점수·충돌·콤보·스킬 판정의 권위는 프레임워크 비의존 규칙 엔진에 둔다.
- 권위 시뮬레이션은 고정 120Hz tick과 결정적 event ordering을 유지한다. 프레임률, 렌더링 지연 또는 애니메이션 완료 callback이 게임 결과를 바꾸면 안 된다.
- TypeScript, Vite, Phaser, React, Vitest, Web Audio는 현재 앱의 기본 기술이 아니다. 사용자가 별도 웹 포트나 웹 실험을 승인한 경우에만 별도 하위 범위와 지침으로 도입한다.
- gameplay-critical 기능을 무허가·미검증 원격 에셋에 의존시키지 않는다. 승인·권리·provenance가 확인된 로컬 에셋과 procedural 표현은 사용할 수 있다.

### 8.3 책임 경계

아래 명칭은 반드시 별도 클래스나 모듈을 만들라는 뜻이 아니라 책임을 섞지 않기 위한 경계다.

| 책임 | 현재/목표 네이티브 경계 | 금지 |
|---|---|---|
| Game State | 현재 `GameModels`, `GameRules` | SpriteKit node나 `AppModel`을 권위 게임 상태로 사용 |
| Physics / Collision | 순수 `GameRules` fixed tick | `SKPhysicsWorld` 또는 animation callback으로 점수 판정 |
| Effect / Power-up Resolution | typed model + 순수 resolver | Scene switch에 규칙·수치를 중복 |
| Effect / Camera Rendering | `GameScene`의 비권위 presentation layer | VFX가 입력·권위 tick을 멈춤 |
| Audio / Haptic Feedback | `AppModel`이 조정하는 service | 충돌 callback에서 중복 보상·상태 변경 |
| App Flow / Coordination | 현재 `AppModel` | 교체된 Scene 이벤트가 새 run·route를 오염 |
| UI System | SwiftUI Views와 bounded snapshot | SwiftUI가 충돌·점수 계산 |
| Accessibility | 현재 SwiftUI 환경, 목표 중앙 Scene visual policy | 색만으로 상태 전달 |
| Performance | 목표 DEBUG probe·node cap + 현재 Xcode/Instruments 증거 | 계측 없는 대규모 최적화 주장 |

새 효과는 조건문과 magic number를 여러 파일에 흩뿌리지 않는다. 기본 완료 단위는 다음 네 가지다.

1. typed Swift effect definition 또는 중앙 설정
2. 결정적이고 순수한 resolver
3. 비권위 renderer cue
4. 단위·통합 테스트

명시적인 웹 포트가 승인되면 동일한 의도를 `registerEffect`, `applyEffect`, `removeEffect`, `resolveHit` 같은 typed registry API로 번역할 수 있다.

### 8.4 할당과 오브젝트 재사용

- 프로파일에서 hot path 또는 node·메모리 예산 초과가 확인된 공, 트레일 세그먼트, 반복 파편, 히트 스파크, 데미지 label, 폭발 ring, 전기 chain node는 bounded pool 또는 고정 버퍼로 재사용한다.
- authoritative value state를 억지로 풀링하지 않는다. 구조 전체 pooling이나 모듈 분리는 프로파일링에서 hot path가 확인될 때만 수행한다.
- 매 프레임 텍스처 생성, 무제한 node 생성, 반복 배열 재할당을 금지한다. 예외는 계측 결과와 상한, 회수 조건을 문서화해야 한다.
- transient node는 효과 종료·화면 이탈·run 종료 때 기준 수량으로 회수되어야 한다.

### 8.5 시각 구현 규칙

- 신규·수정 시각 코드에서는 순수 검정이나 임의 hex를 직접 쓰지 않고 `DesignSystem.swift` 또는 향후 중앙 `GamePalette`의 semantic token을 사용한다. 기존 raw color는 한 번에 재작성하지 말고 테스트 가능한 migration debt로 추적한다. JSON token이 저장소에 정식 도입되기 전에는 존재하지 않는 경로를 참조하지 않는다.
- 글로우는 공, 충돌점, 획득 코어처럼 즉시 판정에 필요한 핵심 오브젝트에만 사용한다.
- 공의 중심 코어는 모든 배경과 효과 위에서 추적 가능한 명도·윤곽을 유지한다.
- 타격 섬광은 80ms 이하, 화면 전체 흰색 flash는 기본 모드 alpha 0.18 이하를 임시 상한으로 둔다.
- 트레일은 공 속도에 비례하되 플레이 필드 높이의 18%를 넘지 않는다.
- VFX는 공, 충돌점, 벽돌 HP·armor, 지지선, 마이너스·위험 오브젝트를 가리지 않는다.
- 시각 우선순위는 `즉시 위험·피격 경고 → 공의 궤적·충돌점 → 승인된 boss pattern → 활성 스킬·공명 → 점수·콤보 장식 → 배경` 순이다.
- 80ms, 0.18, 18%는 사용자·실기기 검증 전 `provisional` 수치다. 변경 시 테스트 근거와 Decision Log를 남긴다.

### 8.6 결정론을 보존하는 게임필

아래 순서는 ProductSpec과 시각 수용 기준에서 승인된 효과에만 적용하는 선택적 presentation recipe다. 모든 항목을 의무 기능으로 추가하지 않으며 입력 가독성·결정론·접근성 cut 규칙이 항상 우선한다.

1. fixed-tick 접촉점과 단일 collision transaction 계산
2. 점수·콤보·HP·스킬의 ordered domain event 확정
3. 공 squash 1~2 presentation frame
4. 필요한 경우 20~45ms의 시각적 강조를 적용하되 `GameRules` tick과 입력은 정지하지 않음
5. 속성별 impact cue 또는 procedural burst
6. 접촉점 기준 bounded 파편
7. 접근성 정책을 적용한 camera impulse
8. debounce와 상한이 적용된 속성별 sound·haptic
9. 점수·콤보 HUD feedback
10. 공 stretch와 이탈 표현

- 100ms 안에 연속 충돌이 발생하면 hit emphasis, 화면 flash, camera impulse, sound를 무한 누적하지 않고 합성·상한 적용한다.
- Scene 전체 pause, 실제 wall-clock sleep 또는 frame-rate 의존 hit stop으로 게임 결과를 바꾸지 않는다.
- Reduce Motion과 광과민 안전 모드에서도 위험·판정 신호 자체는 제거하지 않고 정적 outline·문양·짧은 cue로 대체한다.

### 8.7 스킬·효과 중첩

- 현행 권위 계약은 번개·화염·바람·관통이 종류별로 독립 L0~L3을 유지하는 run-local 성장이다. 같은 종류 획득은 level-up하며 ProductSpec 승인 없이 다른 종류를 교체하지 않는다.
- 번개·화염·바람의 즉시 wave는 지속 효과 slot을 차지하지 않는다. 관통 charge와 공명은 현행 ProductSpec·테스트 계약을 따른다.
- `ice`, `arcane`, `homing`, `multiball`, `damageBoost`, `shield`, `laser`, `slowTime` 또는 자동 slot 교체는 승인되지 않은 기능이다. 구현하려면 Stage 4 Solution Definition으로 돌아가 PRD, 조합 규칙, 시각 우선순위, 테스트와 성능 Gate를 다시 승인한다.
- 향후 지속 효과 slot을 승인하는 경우 후보 분류는 `element` 최대 1, `trajectory` 최대 1, `multiplier` 최대 1, `utility` 복수다. 같은 slot의 교체·stacking은 설정과 테스트에 명시한 경우에만 허용한다.
- 스킬 파동은 LINK, 다른 carrier 획득, negative 직접 판정 또는 점수 원인을 암묵적으로 재귀 변경하지 않는다.

### 8.8 접근성

항상 다음 결과를 보장한다.

- `reduceMotion`: 시스템 설정을 존중하고 shake를 70% 이상 줄이며 zoom punch를 제거하고 trail 길이를 50% 이하로 축소한다.
- `photosensitivitySafe`: 전면 flash를 제거하고 반복 점멸을 3Hz 미만으로 제한하며 glow alpha를 낮춘다. 효과가 확장되기 전 중앙 visual policy와 사용자 제어 경로를 정의한다.
- `colorAssist`: 속성별 고유 문양·아이콘·텍스트를 색과 함께 항상 제공하고 `accessibilityDifferentiateWithoutColor`를 반영한다.
- VoiceOver, Switch Control, Dynamic Type, Increase Contrast, Reduce Motion에서 핵심 시작→플레이→일시정지→결과→재시도 흐름을 검증한다.
- 접근성 설정이 권위 simulation, seed, 점수 또는 난이도를 바꾸면 안 된다.

### 8.9 테스트 요구사항

아래 전체 matrix는 `GameRules`, `GameScene`, 효과, 입력, 접근성 또는 성능 계약을 바꾸는 Stage 6 구현과 Release Gate에 적용한다. 문서·문구·주석만 바꾸는 작업은 변경 위험에 비례한 구조 검사와 관련 회귀 subset을 실행하되, 실행하지 않은 전체 matrix를 통과로 기록하지 않는다.

#### 단위 테스트

- 효과의 획득·적용·해제 또는 charge 소진
- 승인된 slot이 있을 때 slot 충돌·교체·stacking
- 지속 효과의 `N-1 / N / N+1` tick 만료
- 전기 chain 대상 수·제외 조건·동거리 stable-ID 순서
- 화염 반경 안팎과 최대 대상 수
- 관통 횟수 감소·반사 금지·negative 미소비
- multiball이 승인된 경우에만 최대 공 수
- direct·wave·collapse별 콤보 증가와 reset
- Reduce Motion·광과민·Color Assist policy 수치
- 30/60/120Hz scheduling에서 동일 seed checksum 일치

#### 통합·성능 테스트

- 3분 deterministic autoplay에서 crash, NaN, out-of-bounds, checksum drift 0
- 현재 승인된 최대 공 수와 최악의 동시 스킬 wave에서 transient node·메모리 상한과 회수 확인
- background/foreground 또는 interruption 뒤 catch-up 폭주·즉시 사망·timer 만료 0
- 세로 고정 앱은 회전 기능 대신 375×667, 390×844, 430×932 portrait safe area와 HUD 예약 영역을 검증한다.
- 최소 지원 실기기의 FPS, hitch, 열, 메모리와 반복 retry는 `docs/06-quality/test-plan.md`의 Gate를 따른다.

### 8.10 완료 보고 확장

7절의 최종 보고 형식을 유지하면서 구현 작업에는 아래 항목을 함께 포함한다.

```text
Stage / Gate
- 현재 단계와 Go / Revise / Stop

Agents
- 참여 역할과 책임

Implemented
- 변경한 기능

Files changed
- 경로: 변경 내용

How to run
- 명령어

Validation
- 실제 실행한 테스트와 결과

Known gaps / Conflict / Unknowns
- 남은 리스크, 충돌, 미확인 사항

Next owner
- 다음 단계와 담당 에이전트
```

실행하지 않은 테스트나 보지 않은 화면을 통과로 기록하지 않는다.

### 8.11 금지 사항

- 레퍼런스 이미지를 픽셀 단위로 복제하지 않는다.
- UI 요소마다 임의의 glow·shadow를 추가하지 않는다.
- 모든 공격·충돌에 같은 particle preset만 재사용하지 않는다.
- 프레임 속도에 따라 물리·점수·스킬 결과가 달라지게 하지 않는다.
- Swift `Any`, 강제 cast, type erasure 또는 웹 포트의 `any`로 타입 오류를 숨기지 않는다.
- 플레이 가능한 vertical slice와 Gate 검증 전에 대규모 meta game을 만들지 않는다.
- 검증되지 않은 복잡한 shader를 기본 경로로 두지 않는다.
- 승인되지 않은 multiball, boss, 효과 slot, 신규 속성을 지침 병합만으로 구현 범위에 포함하지 않는다.

### 8.12 원문 병합 추적표

| 제공 문서 섹션 | 병합 판정 | 현재 적용 |
|---|---|---|
| 1. 역할 | Adapt | Orchestrator 하위 iOS gameplay·technical art·UI 책임 |
| 2. Source of Truth | Adapt | 요구 권위와 구현 증거를 분리 |
| 3. TypeScript/Vite/Phaser 스택 | Reject/Conditional | Swift 네이티브 유지, 승인된 웹 포트에만 적용 |
| 4. 시스템·데이터·pooling | Adapt | 기존 책임 경계, typed Swift definition, 측정 기반 bounded reuse |
| 5. 시각 규칙 | Adopt/Adapt | semantic Swift palette와 provisional 상한 |
| 6. 게임필 순서 | Adapt | 권위 tick을 멈추지 않는 비차단 표현 |
| 7. 효과 slot | Reject/Conditional | 현행 독립 4종 L0~L3 유지, 향후 재승인 필요 |
| 8. 접근성 | Adopt/Adapt | 네이티브 시스템 설정과 중앙 visual policy |
| 9. 테스트 | Adopt/Adapt | 결정론·현행 단일 공·portrait matrix 기준 |
| 10. 완료 보고 | Extend | 기존 Gate 보고와 구현 보고를 결합 |
| 11. 금지 사항 | Adopt/Translate | Swift 타입·결정론·승인 범위에 맞게 적용 |
