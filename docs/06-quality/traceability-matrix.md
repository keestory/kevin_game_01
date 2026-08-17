# Return Shot 요구사항 추적 매트릭스

기준일: 2026-08-18 KST. `PASS`는 현재 증거, `PARTIAL`은 일부 증거, `FAIL`은 Gate 차단, `UNKNOWN`은 미검증이다.

| ID | 요구사항 | 구현 근거 | 검증 근거 | 상태 |
|---|---|---|---|---|
| RS-AC-1 | 5명 중 4명, 5초 내 첫 리턴 | drag·coachmark 구현 | 사용자 테스트 미실행 | FAIL P1 |
| RS-AC-2 | active-touch 60%, 지속 입력 | 실시간 paddle target | 계측·사용자 테스트 없음 | FAIL P1 |
| RS-AC-3 | 권위 direct contact만 LINK 변경 | `GameRules` event ordering | LINK 단위 테스트 | PASS |
| RS-AC-4 | 속성 5연속에 6초 power 1회 | 독립 counter·tick timer | duplicate/cadence 테스트 | PASS |
| RS-AC-5 | 프리즘 3HP와 단일 보상 | prism hit/collapse 규칙 | 3-hit·낙하 테스트 | PASS |
| RS-AC-6 | 마이너스 직접 −250, 낙하 +120 | penalty cooldown·collapse | direct/indirect 테스트 | PASS |
| RS-AC-7 | 유효하고 표시되는 support graph | all `supportIDs` 렌더 | seed 구조·참조 테스트, A/SE 캡처 | PASS |
| RS-AC-8 | endless와 동일 seed 재시도 | miss→result→retry | XCUITest 1/1 | PASS |
| RS-AC-9 | 실제 quantized replay checksum | 120Hz·swept collision | 합성 30/60/120Hz만 통과; replay log 없음 | PARTIAL P1 |
| RS-AC-10 | 색 비의존·Reduce Motion | 마크·무늬·형태, effect 축소 | 캡처 Pass; 보조기술 실기기 미실행 | PARTIAL P1 |
| RS-AC-11 | Run 3 기록 +20%, 재미 4/7 | PB·동일 seed 제공 | 5명 테스트 미실행 | FAIL P1 |
| RS-AC-12 | build·QA·security·performance | secret scan, local unit/UI | 실기기·signed archive·원격 전체 CI 없음 | FAIL P1 |
| RS-AC-13 | 구조마다 직접 획득 가능한 코어 1개 | deterministic carrier·4종 순환 | seed/segment 단위 테스트, Scene badge 렌더 | PASS |
| RS-AC-14 | 4종별 L1~L3 공격 차이 | bounded lightning/flame/wind/pierce 규칙 | 범위·대상·charge 8개 단위 테스트 | PASS |
| RS-AC-15 | 공격 연쇄가 기존 LINK·코어 규칙을 오염하지 않음 | carrier/negative 제외·no recursion | item-only removal·wave combo 테스트 | PASS |
| RS-AC-16 | 단계 armor가 core HP보다 먼저 소모 | segment armor curve·별도 plate | armor/core/score·checksum 테스트 | PASS |
| RS-AC-17 | 코어·armor를 색 없이 읽을 수 있음 | 문자 glyph·아이콘·level·plate | 캡처/코드 감사; 사용자·VoiceOver 미실행 | PARTIAL P1 |
| ARCH-01 | SwiftUI·Scene·Rules 경계 | `AppModel`, `GameScene`, `GameRules` | architecture·compile | PASS |
| DATA-01 | 안전한 profile migration | versioned decode·clamp | migration 단위 테스트 | PASS |
| PRIV-01 | 현 빌드 수집·tracking 없음 | SDK·네트워크 없음 | manifest/코드 감사 | PASS |
| A11Y-01 | VoiceOver 대체 패들 입력 | adjustable/custom action 48pt 이동 | compile 후 실사용 필요 | PARTIAL P1 |
| VIS-01 | HUD가 공·판정을 가리지 않음 | `topWall=540` | 회귀 테스트와 17 Pro/SE 캡처 | PASS |
| REL-01 | 소유 bundle·서명 archive | `com.keestory.returnshot` | Development Team·archive 없음 | FAIL P1 |
| OBS-01 | 퍼널·크래시 관측성 | 없음 | 없음 | FAIL P1 |

## Gate

- Skill Core MVP: **Go** — P0 0, 25개 규칙 테스트·핵심 UI 흐름 통과.
- 전체 Implementation: **Revise** — 실제 사용자, 접근성, replay, 관측성 P1이 남음.
- Release: **Stop** — signing/archive, 원격 전체 CI, 실기기 soak, App Store Connect 검증 없음.
- 한국 무료 1위: **Unknown** — retained installs, CPI/LTV, organic multiplier, 필요 일간 설치량 미확인.
