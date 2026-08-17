# Return Shot 데이터 모델과 마이그레이션

## 데이터 분류

| 데이터 | 수명 | 외부 전송 | 민감도 |
|---|---|---|---|
| `PlayerProfile` | UserDefaults JSON | 없음 | 낮음, 개인 식별정보 아님 |
| sound/haptics 설정 | UserDefaults Bool | 없음 | 낮음 |
| `ReturnShotState`, `RunSnapshot`, `RunResult` | 현재 run 메모리 | 없음 | 낮음 |
| 계정·이메일·연락처·위치·광고 ID | 수집하지 않음 | 없음 | 해당 없음 |

앱 삭제 시 로컬 데이터가 삭제된다. 백업·동기화·중단 run 복구는 지원하지 않는다.

## `PlayerProfile` schema v1

| 필드 | 기본 | 불변조건 | 용도 |
|---|---:|---|---|
| `version` | 1 | 정확히 1 | schema guard |
| `bestScore` | 0 | 0 이상 | 최고 점수 |
| `bestHeight` | 0 | 0 이상 | 최고 높이 |
| `bestCombo` | 0 | 0 이상 | 최고 콤보 |
| `bestLink` | 0 | 0 이상 | 최고 LINK |
| `totalRuns` | 0 | 0 이상 | 완료 run 수 |
| `tutorialSeen` | false | Bool | 첫 리턴 안내 여부 |

decoder는 누락 필드에 기본값을 적용하고 음수 정수를 0으로 clamp한다. `version != 1` 또는 손상 JSON은 decode를 거부하고 최초 raw payload를 `returnShot.playerProfile.recovery`에 보존한다.

## 일시 모델

- `ReturnShotState`: seed, tick, ball, paddle, score, height, combo, LINK, power, segment, bricks, phase의 권위 상태.
- `ShotBrick`: signature, role, HP, support IDs, penalty cooldown과 제거 상태.
- `RunSnapshot`: SwiftUI 투영. 영구 저장하거나 replay proof로 사용하지 않는다.
- `RunResult`: 결과 화면과 프로필 최고값 갱신에만 사용한다.

실제 quantized input replay를 추가할 때는 schema version, seed, tick별 paddle target, rule version, checksum을 원자적 record로 정의해야 한다. 현재 합성 입력 결정성 테스트만 존재한다.

## 보존·초기화와 debt

- QA는 `-uiTesting` 격리 프로필 또는 앱 삭제를 사용한다.
- 운영 빌드에 디버그 초기화 경로를 노출하지 않는다.
- 사용자 데이터를 migration 실패 즉시 덮어쓰지 않는다.
- 저장 실패 관측, recovery UI, recovery payload 삭제 시점은 미구현이다.
