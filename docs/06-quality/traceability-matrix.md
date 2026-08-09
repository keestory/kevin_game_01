# 요구사항 추적 매트릭스

상태: `PASS` 증거 있음, `PARTIAL` 일부 증거, `FAIL` Gate 차단, `UNKNOWN` 검증되지 않음.

| ID | 요구사항/수용 기준 | 구현 근거 | 테스트/운영 근거 | 상태 |
|---|---|---|---|---|
| BR-ARCH-01 | SwiftUI 셸, SpriteKit 장면, 순수 규칙의 경계가 명시됨 | `AppModel`, `GameScene`, `GameRules` | ADR-0001, architecture | PASS |
| BR-API-01 | 외부 API 부재와 미래 연동 경계가 명시됨 | 외부 dependency/네트워크 없음 | api-contract | PASS |
| GAME-DET-01 | 같은 seed는 같은 승객 sequence | `SeededRandom`, `GameRules` | `testDailySequenceIsDeterministic` | PASS |
| GAME-DIFF-01 | 초반 관대, stage 상승에 따라 난이도 상승 | `stageDifficulty` | 난이도/도움 단위 테스트 | PASS |
| GAME-LIFE-01 | playing이 아닌 상태에서 시간 미진행 | `GameScene.update` phase guard, RootView→AppModel 활성 상태 전달 | inactive reward 테스트 | PASS |
| GAME-LIFE-02 | 비활성/낡은 런의 보상 callback이 Scene을 재개하지 않음 | activeRunID, Scene identity, pendingRewardRunID | stale run/inactive reward Xcode 테스트 통과 | PASS |
| AD-01 | 무료 구조는 설치 단위 1회 | `freeRescueUsed` 저장 | AppModel 테스트 없음 | PARTIAL |
| AD-02 | 보상 확정 callback만 구조 지급 | `RewardedAdOutcome.rewarded`, run/Scene binding | rewarded inactive/stale 테스트 | PASS (현재 mock 경계) |
| AD-03 | 중복 impression은 1회만 지급 | 메모리 `processedImpressionIDs` | 중복 ID 직접 테스트 없음 | PARTIAL (P2 test debt) |
| AD-04 | Release는 실제 SDK 전까지 fail closed | `UnavailableRewardedAdService` | Release behavior 테스트 없음 | PARTIAL |
| DATA-01 | v1 기록을 v2로 보존 migration | custom decoder | v1 fixture 통과 | PASS |
| DATA-02 | 미래 schema는 명시적으로 거부하고 원본 보존 | raw version guard, recovery key | SwiftPM reject + Xcode backup 테스트 통과 | PASS |
| DATA-03 | 손상·저장 실패가 관측 가능 | crash는 피하나 오류 무시 | 테스트/로그 없음 | FAIL (P2) |
| PRIV-01 | 현 빌드는 tracking/수집 없음과 manifest가 일치 | `PrivacyInfo.xcprivacy`, SDK 없음 | plist/SDK 수동 감사 | PASS |
| PRIV-02 | 실제 광고/분석 SDK 데이터 흐름 검증 | 해당 SDK 없음 | 도입 Gate만 문서화 | UNKNOWN |
| OBS-01 | 시작→첫 성공→런 종료→구조 퍼널 측정 | 분석 계층 없음 | 이벤트 검증 없음 | FAIL (P1) |
| CI-01 | PR에서 순수 규칙 테스트 | SwiftPM workflow | 원격 run 31308952608 성공 | PASS |
| CI-02 | PR에서 iOS 앱 타깃 컴파일 | `ios-app-build` job 추가 | 원격 run `31311249450` 성공 | PASS |
| REL-01 | 배포 ID/서명/Archive 준비 | team 비어 있음, example bundle ID | Archive 미실시 | FAIL (P1, Release) |
| A11Y-01 | 핵심 경로 VoiceOver/큰 글자/Reduce Motion/색 비의존 | 일부 ID·크기 수정, SpriteKit 직접 조작 미지원 | 제품 수용 기준 Fail/Not tested | FAIL (P1) |
| USER-01 | 첫 사용자 핵심 과업과 광고 이해 검증 | 테스트 계획 존재 | 최소 5명 사용성 테스트 미실행 | FAIL (P1) |
| PERF-01 | 지원 기기 장시간 플레이 안정성 | delta clamp, 작은 로컬 상태 | 기기 Instruments 없음 | UNKNOWN |
| OPS-01 | 사고 분류, 대응, 롤백 문서 | 코드 외 문서 | runbook/incident-response | PASS (문서) |

## Gate 연결

- Build Readiness 차단: 제품 `A11Y-01`, `USER-01`과 계측/데이터 계획의 실행 전 blocker가 남아 있다.
- Implementation 차단: `OBS-01`, `A11Y-01`, `USER-01`, `REL-01`이 Fail이다. `CI-02` 앱 컴파일은 통과했지만 앱 단위/UI/Release 원격 실행은 Release Checklist에 남아 있다.
- 이전 `GAME-LIFE-02`, `DATA-02` P1은 현재 코드와 독립 simulator 테스트로 해소됐다.
- 핵심 제품 루프 자체의 결정론 및 난이도 단위 증거는 통과했으나, 이것만으로 앱 전체 품질을 대표하지 않는다.

## Unknown / Conflict

- 제품 수용 기준은 실제 진행 데이터 손실과 광고 보상 중복·오지급을 P0로 정의한다. 본 감사에서 아직 실제 광고 SDK가 없고 해당 사고가 재현되지 않아 “예방 통제/테스트 부재”는 P1로 기록했다. Release에서 재현되거나 대량 오지급 가능성이 확인되면 즉시 P0로 승격한다.
- 제품 분석 계획의 Keychain 기반 `install_id`와 이벤트 사전은 제안 문서이며 현재 구현·PrivacyInfo 데이터 흐름이 아니다. 도입 여부와 공급자는 Unknown이다.
- App Store Connect 개인정보 답변, 실제 서명 archive, 최저 지원 실기기 성능, 5명 사용성/광고 이해 테스트 결과는 저장소에서 확인할 수 없다.
- PRD의 “Release 광고 CTA 숨김”은 현재 unavailable 서비스와 조건부 UI로 구현되어 있으나 실제 광고 매출 기능은 아니다.
