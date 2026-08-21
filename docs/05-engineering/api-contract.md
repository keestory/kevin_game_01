# Return Shot 내부 경계 계약

- 기준일: 2026-08-18 KST
- 외부 HTTP/WebSocket API, 서버 인증, 계정, 토큰, 원격 구성: 없음

## Scene → AppModel 이벤트

`GameSceneDelegate`는 현재 Scene에서 AppModel로 단방향 이벤트를 보낸다. AppModel은 `scene === currentScene`, active run ID, `.game` route를 모두 만족할 때만 처리한다.

| `GameEvent` | 의미 | 수신자 의무 |
|---|---|---|
| `snapshot(RunSnapshot)` | UI용 최신 점수·높이·콤보·LINK·power·PB·스킬 레벨·armor | 메모리 투영만 갱신, 저장하지 않음 |
| `paddleReturn(edgeShot)` | 권위 paddle collision | 튜토리얼 종료와 보조 피드백 |
| `brickDestroyed(points)` | 권위 positive 제거 | 시각·햅틱·오디오 보조 피드백만 수행 |
| `powerActivated` | 5-LINK 6초 power 시작 | 중복 점수 변경 없이 효과만 수행 |
| `negativeHit` | 직접 마이너스 penalty | 경고 피드백 |
| `cleanDrop` | support 붕괴로 위험 제거 | 성공 피드백 |
| `itemCollected(AttackItemKind)` | 직접 완파로 스킬 코어 획득·레벨업 | 중복 규칙 변경 없이 종류별 효과·햅틱·오디오만 수행 |
| `finished(RunResult)` | 한 run의 최종 결과 | 프로필에 1회 반영, Scene 해제, 결과 route 전이 |

## 규칙 이벤트 계약

`GameRules.stepReturnShot`은 120Hz tick마다 `ShotSimulationEvent` 배열을 반환한다. 이벤트 순서는 권위 규칙이 결정하며 Scene 애니메이션은 이를 되돌리거나 추가 점수를 만들 수 없다.

- 같은 seed와 quantized input은 같은 구조·충돌 순서·점수·checksum을 만들어야 한다.
- swept collision은 한 tick 안의 빠른 공이 벽돌을 통과하지 않게 한다.
- LINK는 eligible direct contact만 갱신한다.
- prism 반복 contact, shockwave, debris, unsupported fall은 LINK를 변경하지 않는다.
- negative direct hit와 unsupported fall은 한 brick에 중복 적용하지 않는다.
- support graph의 모든 권위 edge는 화면에도 표시한다.
- 공격 파동은 positive 일반/프리즘 벽돌만 1 damage 처리하며 negative와 모든 carrier를 제외한다.
- 공격 파동은 LINK를 올리지 않고 다른 코어를 수집하지 않으며, 한 번의 파동에서 combo를 최대 1만 올린다.
- armor는 core HP보다 먼저 소모되고 armor 적중 자체는 core 점수를 지급하지 않는다.
- 관통 charge는 positive 직접 접촉에서만 1 소모된다. negative 접촉에는 소모하지 않는다.

## 공격 코어 규칙 계약

| 코어 | L1 / L2 / L3 | 권위 대상 |
|---|---|---|
| 번개 | 최근접 1 / 2 / 3개에 1 피해 | source 외 가까운 positive |
| 화염 | 반경 72 / 92 / 112, 최대 3 / 5 / 7개에 1 피해 | 반경 안 positive |
| 바람 | source 위 2 / 3 / 4개에 1 피해 | y가 높은 positive |
| 관통 | 1 / 2 / 3 charge 지급 | 이후 positive 직접 접촉 |

이 순서·대상·레벨·armor·charge는 replay checksum에 포함한다. Scene의 파티클·오디오·햅틱·애니메이션 콜백은 어떤 권위 상태도 변경하지 않는다.

## 저장 계약

- key: `returnShot.playerProfile.v1`
- recovery key: `returnShot.playerProfile.recovery`
- payload: `PlayerProfile` schema version 1

지원하지 않는 version이나 손상 payload는 덮어쓰지 않고 최초 원본을 recovery key에 보존한 뒤 기본 프로필을 반환한다. 음수 기록 필드는 0으로 clamp한다. 저장 실패 관측성은 아직 P1/P2 debt다.

## 미래 외부 경계

| 경계 | 도입 전 필수 |
|---|---|
| 익명 분석·크래시 | 이벤트 사전, 목적·보존·삭제, PrivacyInfo/App Store 답변, offline queue 한도 |
| 광고·IAP | core retention Gate, 정책·연령·환불, SDK signature/privacy, fail-open gameplay, kill switch |
| Game Center/서버 점수 | 인증·idempotency·replay proof·치팅/남용·rate limit |
| 공유 challenge link | seed/version 서명, 길이·만료·조작 방지, Universal Link 검증 |

외부 경계 추가는 ADR, 보안·개인정보 검토, 실패 UX, 계약 테스트와 롤백 계획을 동반한다.
