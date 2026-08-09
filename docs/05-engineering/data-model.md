# 데이터 모델과 마이그레이션

## 1. 데이터 분류

| 데이터 | 저장 | 현재 외부 전송 | 민감도 |
|---|---|---|---|
| `PlayerProfile` | UserDefaults JSON | 없음 | 낮음; 개인 식별정보 아님 |
| `settings.haptics` | UserDefaults Bool | 없음 | 낮음 |
| `RunSnapshot`, `RunResult`, 보드 | 메모리 | 없음 | 낮음 |
| 광고 impression ID | 메모리 Set | 없음 | 잠재적 SDK 식별자; 실제 SDK 도입 시 재분류 |
| 계정/이메일/연락처/위치 | 수집하지 않음 | 없음 | 해당 없음 |

앱 삭제 시 로컬 데이터가 함께 삭제되며, 현재 백업·기기간 동기화·사용자 복구 기능은 없다.

## 2. 영구 모델 `PlayerProfile` v3

| 필드 | 타입/기본값 | 불변조건 | 용도 |
|---|---|---|---|
| `version` | Int / 3 | 지원 schema 식별자 | migration 분기 |
| `bestScore` | Int / 0 | 0 이상이어야 함 | 최고 기록 |
| `totalRuns` | Int / 0 | 0 이상이어야 함 | 누적 운행 |
| `totalExited` | Int / 0 | 0 이상이어야 함 | 누적 하차 |
| `tutorialSeen` | Bool / false | - | 첫 안내 |
| `highestStage` | Int / 1 | 1 이상 | 난이도 |
| `consecutiveFailures` | Int / 0 | 0 이상 | 가시적 도움 난이도 |
| `freeRescueUsed` | Bool / false | 계정이 없어 설치 단위 | 최초 무료 구조 |
| `rewardedContinuesUsedTotal` | Int / 0 | 0 이상 | 보상 구조 누계 |

현재 decoder는 일부 정수 필드에만 하한을 적용한다. `bestScore`, `totalRuns`, `totalExited`도 음수 입력을 정규화하거나 decode 실패로 처리해야 한다.

## 3. 마이그레이션 정책

| 입력 | 기대 동작 | 현재 증거 |
|---|---|---|
| 저장 없음 | v3 기본 프로필 | 구현·AppModel 테스트 |
| v1 정상 JSON | 점수·누계 보존, 제동 단계/튜토리얼 초기화, v3로 승격 | 단위 테스트 통과 |
| v2 정상 JSON | 점수 보존, 폐기된 격자 단계/실패/구조 상태 초기화, 새 제동 튜토리얼 재노출 | 단위 테스트 통과 |
| v3 정상 JSON | 값 보존 | 구현됨, 왕복 테스트 후속 |
| 손상/타입 오류 | crash 없이 기본 프로필, 진단 신호 | 구현은 기본값 반환; 진단 없음 |
| version > 3 | 원본을 덮어쓰지 않고 fail closed/복구 유도 | decoder 거부 + recovery key 원본 보존 테스트 통과 |

현재 구현과 후속 보강:

1. payload의 raw `version`을 먼저 decode하고 `1...3`만 지원한다(구현·테스트 완료).
2. decode 실패 원본은 recovery key가 비어 있을 때만 보존한다(구현·테스트 완료).
3. migration 함수를 버전별 순수 함수로 분리하고 v3 round-trip/손상/음수 fixture를 추가한다(P2 후속).
4. 저장 실패/복구는 개인정보 없는 오류 코드로 기록한다.
5. 복구 UI/지원 절차와 recovery payload의 삭제 시점을 정한다.

## 4. 일시 모델

`RunSnapshot`은 UI 투영이며 Scene 내부 보드의 권위 있는 영구 복사본이 아니다. 앱 종료 후 런 복구를 지원하지 않는다. `RunResult`는 결과 화면과 프로필 갱신에만 사용한다. 향후 중단 복구를 추가할 경우 보드, RNG state, schema version, run ID, 저장 시각을 하나의 원자적 snapshot으로 정의해야 한다.

## 5. 보존·초기화

- 현재 명시적 “모든 데이터 삭제” UI는 없다.
- QA 초기화는 테스트 전용 UserDefaults suite 또는 앱 삭제로 수행한다.
- 운영 빌드에 디버그 초기화 인자를 노출하지 않는다.
- 분석/광고 SDK 도입 전까지 서버 보존기간은 해당 없음이다.
