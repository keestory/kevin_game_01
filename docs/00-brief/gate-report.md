# Gate Report

확인일: 2026-08-09
판정자: Product Orchestrator

## Stage 0 — Brief

판정: **Go**

| 기준 | 판정 | 근거 |
|---|---|---|
| 문제 | Pass | 통근·짧은 대기 시간에 즉시 이해하고 반복할 수 있는 60초 퍼즐이라는 검증 대상이 명시됨. 문제의 실제 강도는 Stage 2에서 검증해야 함. |
| 대상 | Pass | 첫 세그먼트는 한국 iPhone의 짧은 세션 캐주얼 퍼즐 사용자로 제한. 연령·통근 맥락은 내부 가정. |
| 지역·플랫폼 | Pass | 대한민국, iPhone, App Store Games 무료 차트. |
| 성공 정의 | Pass | 1위 결과 목표와 제품 Gate 지표를 분리함. |
| 기한 | Pass | Sprint 0은 3~5일, Problem Validation은 1~2주 time-box. 출시일은 시장·사용자 Gate 전 확정하지 않음. |

## Stage 1 — Market Discovery

판정: **Go — Stage 2 진입에 한정**

| 기준 | 판정 | 근거 수준 | 근거 |
|---|---|---:|---|
| 최신 한국 iPhone Games 관측 | Pass | A | 2026-08-09 19:58 KST Apple Top Free 25개 스냅샷과 앱 메타데이터 |
| 문제·공백 다중 근거 | Pass | A/B | Apple·Google Play 경쟁 리뷰, KOCCA 퍼즐/인디 이용 조사, Sensor Tower 광고 경쟁 추정 |
| 경쟁·대체재 | Pass | A/C | 직접 경쟁 10개, Google Play, 무설치 웹게임과 숏폼 대체재 구분 |
| 관측/추정/가정 분리 | Pass | A | Evidence Register에서 출처·시점·지역·플랫폼·등급 기록 |
| 제품 자체 수요 | Fail | 없음 | 실제 인터뷰·관찰·퍼널 데이터 0건 |

퍼즐·짧은 조작 수요와 광고·공정성 불만은 복수 근거로 확인됐다. 그러나 `만원열차` 소재, 현재 5×7 루프, 공유와 광고 구조가 실제 선택을 만든다는 근거는 없다. 따라서 제품 출시·대규모 UA·수익화 범위 승인이 아니라 Problem Validation 진입만 허용한다.

## Stage 2 — Problem Validation

판정: **Revise / Not Run**

- 실제 사용자 인터뷰: 0명
- 일기 연구: 0명
- 조정 사용성 테스트: 0명
- 행동 데이터: 분석 계층 미구현

통과 조건:

1. JTBD 인터뷰 12명 중 6명 이상이 유도 없이 반복 문제와 현재 대체재를 구체적으로 설명한다.
2. 일기 연구 8명 중 4명 이상이 5일 중 3일 이상 실제 micro-break 맥락을 기록한다.
3. 사용성 5명 중 4명 이상이 도움 없이 핵심 과업을 수행하고, 광고 비용·보상·거절 결과는 5명 모두 정확히 이해한다.
4. 교통/중립/캐릭터 소재 비교에서 테마 효과와 코어 루프 효과를 분리한다.

## 구현 재감사

기존 vertical slice는 보존하되 Gate를 사후 승인하는 근거로 사용하지 않는다.

| 항목 | 현재 판정 | 근거 |
|---|---|---|
| 순수 규칙 | Pass | SwiftPM 11/11 |
| 앱 단위 테스트 | Pass | Xcode 14/14, 저장 recovery·광고 callback 포함 |
| UI smoke | Pass | 첫 실행→홈→튜토리얼→게임 1/1 |
| 원격 CI | Pass (현재 범위) | run `31311249450`: game-core와 ios-app-build 모두 통과. 앱 단위/UI/Release의 원격 실행은 아직 미구현 |
| 분석·관측성 | Fail | 이벤트 계약 초안만 있고 실제 sink·데이터 QA 없음 |
| 사용자·접근성 검증 | Fail | VoiceOver 코어 플레이, Reduce Motion, 대비, Larger Text와 실제 사용자 테스트 미완료 |
| 배포 준비 | Fail | 고유 bundle ID, signing, archive, App Store Connect 정보 미완료 |

## 에이전트 충돌과 통합

| Conflict | 결론 |
|---|---|
| 시장/GTM은 동일 시드 공유를 차별화 후보로 봤지만 현재 제품은 텍스트 기록 공유만 제공 | 현재 문구는 기록 공유로 유지. 동일 시드는 Stage 2 클릭 프로토타입과 서버/딥링크 ADR 후에만 승인 |
| 자동 테스트는 코어 규칙을 지지하지만 UX Agent는 재미·이해를 검증하지 못했다고 판정 | 둘 다 맞음. 구현 정확성과 제품 적합성을 분리하고 실제 사용자 Gate 전 출시 승인 금지 |
| 보상 광고는 수익 후보지만 리뷰 근거는 광고가 주요 불만임을 보여줌 | 광고 없는 코호트가 유지 Gate를 먼저 통과한 뒤 0회/1회 한도 실험 |
| iOS-first는 집중에 유리하지만 한국 시장은 Android 비중이 큼 | iOS로 문제·경험을 먼저 검증하고, Scale Gate에서 Android를 재평가 |

## 다음 Gate

현재 단계는 **Stage 2 Problem Validation**, 전체 판정은 **Revise**다. 사용자 모집, 인터뷰 12명, 일기 8명, 사용성 5명을 수행하기 전에는 성장·수익 기능 범위를 확정하지 않는다. 다음 담당은 User Research, Product Planning, UX Research, Data & Experimentation이며 Red Team이 Gate 2를 다시 반박한다.

## 2026-08-09 21:10 KST 재작업 Gate — 최신 판정

사용자 직접 피드백으로 기존 Solution Definition이 실패했다. 현재 단계는 **Stage 4 Solution Definition 재작업**, 판정은 **Revise**다.

| 기준 | 판정 | 근거 |
|---|---|---|
| 2초 안에 실제 열차로 식별 | 부분 Pass | 차체·창문·바퀴·선로·플랫폼·미닫이문을 SpriteKit 영구 노드로 구현. 실제 5명 노출 테스트는 미실행 |
| 5초 안에 목표 이해 | 부분 Pass | 하단 64pt 제동 CTA, 고정 정차선, `하차 0/22명` HUD 구현. 사용자 테스트 미실행 |
| 핵심 행동의 효과 | Pass(구현) | 감속, 문 개폐, 사람 형태 승하차, 패럴랙스, 정위치 파티클, 급정차 흔들림, 햅틱, 코드 생성 사운드 구현 |
| 순수 규칙 결정성 | Pass | 제동 경계·하차 계산·동일 입력 결정성 SwiftPM 테스트 추가 |
| 광고·재시도 공정성 | 부분 Pass | 무료 재시도 문구와 조건부 +12초 Continue 구현; 실제 광고 SDK·이해도 테스트 없음 |
| 사용자 재미·재시도 | Fail/Not Run | 최소 5명 중 4명 자발적 두 번째 운행, 재미 중앙값 4/7 검증 전 |

따라서 프로토타입 구현은 진행하되 Build Readiness와 1위 가능성은 승인하지 않는다.

## 2026-08-09 Product Harness Gate

공식 ProductSpec v0.1을 현재 사업 가설의 Product Harness로 채택했다. 기준 계약은 `docs/product-specs/real-train-braking.product-spec.md` revision 1이며, 격자→실제 열차·광고 판단은 별도 Decision Trace에 기록한다.

| Harness Gate | 판정 | 근거/차단 |
|---|---|---|
| Product Spec schema | Pass | 공식 `@productspec/parser` 로컬 검증 |
| Decision Trace schema | Pass | 공식 `validate-trace` 로컬 검증 |
| Prototype AC-1~AC-7 | Revise | ProductSpec/Trace 유효, SwiftPM 17/17, Xcode unit+Scene 25/25, UI 1/1, PrivacyInfo lint, secret pattern 0건. AC-4 문 개방 연속 영상과 AC-5 실기기 접근성 증거는 없음 |
| Problem discovery | Fail / Not Run | 인터뷰 0/12, 일기 0/8 |
| UX validation AC-8 | Fail / Not Run | 서로 다른 신규 사용자 2초 0/5, 5초 0/5, 3회 플레이 0/5 |
| TestFlight AC-9 | Fail / Not Run | 실기기 soak·성능·누수·30명 cohort 미실행 |
| App Store AC-10 | Blocked | 고유 bundle ID, 서명, App Store Connect, 메타데이터, 지원 URL 미확정 |
| Business Validation | Fail | 유지율·CPI·D90 contribution LTV·운영비 증거 없음 |

현재 허용 범위는 **vertical slice 내부 검증과 외부 사용자 모집**까지다. TestFlight·한국 App Store·유료 UA 확대는 각 Gate의 증거가 Agent Run과 Related Artifacts에 연결된 뒤 별도 승인한다.
