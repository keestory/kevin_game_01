# Return Shot 내부 경계 계약

- 기준일: 2026-08-18 KST
- 외부 HTTP/WebSocket API, 서버 인증, 계정, 토큰, 원격 구성: 없음

## Scene → AppModel 이벤트

`GameSceneDelegate`는 현재 Scene에서 AppModel로 단방향 이벤트를 보낸다. AppModel은 `scene === currentScene`, active run ID, `.game` route를 모두 만족할 때만 처리한다.

| `GameEvent` | 의미 | 수신자 의무 |
|---|---|---|
| `snapshot(RunSnapshot)` | UI용 최신 점수·높이·콤보·LINK·power·PB | 메모리 투영만 갱신, 저장하지 않음 |
| `paddleReturn(edgeShot)` | 권위 paddle collision | 튜토리얼 종료와 보조 피드백 |
| `brickDestroyed(points)` | 권위 positive 제거 | 시각·햅틱·오디오 보조 피드백만 수행 |
| `powerActivated` | 5-LINK 6초 power 시작 | 중복 점수 변경 없이 효과만 수행 |
| `negativeHit` | 직접 마이너스 penalty | 경고 피드백 |
| `cleanDrop` | support 붕괴로 위험 제거 | 성공 피드백 |
| `finished(RunResult)` | 한 run의 최종 결과 | 프로필에 1회 반영, Scene 해제, 결과 route 전이 |

## 규칙 이벤트 계약

`GameRules.stepReturnShot`은 120Hz tick마다 `ShotSimulationEvent` 배열을 반환한다. 이벤트 순서는 권위 규칙이 결정하며 Scene 애니메이션은 이를 되돌리거나 추가 점수를 만들 수 없다.

- 같은 seed와 quantized input은 같은 구조·충돌 순서·점수·checksum을 만들어야 한다.
- swept collision은 한 tick 안의 빠른 공이 벽돌을 통과하지 않게 한다.
- LINK는 eligible direct contact만 갱신한다.
- prism 반복 contact, shockwave, debris, unsupported fall은 LINK를 변경하지 않는다.
- negative direct hit와 unsupported fall은 한 brick에 중복 적용하지 않는다.
- support graph의 모든 권위 edge는 화면에도 표시한다.

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
