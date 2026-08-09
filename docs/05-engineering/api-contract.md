# API 및 내부 경계 계약

- 현재 외부 HTTP/WebSocket API: 없음
- 서버 인증·계정·토큰·원격 구성: 없음
- 이 문서는 현재 프로세스 내부 계약과 미래 외부 연동의 도입 조건을 정의한다.

## 1. Scene 이벤트 계약

`TrainGameSceneDelegate`는 Scene에서 AppModel로 단방향 이벤트를 보낸다.

| 이벤트 | 의미 | 수신자 의무 |
|---|---|---|
| `snapshot(RunSnapshot)` | 화면 투영용 최신 런 상태 | MainActor에서 교체; 영구 데이터로 간주하지 않음 |
| `perfect`, `match`, `overflow` | 즉시 피드백 신호 | 햅틱이 꺼져도 시각 피드백 유지 |
| `rescueRequested` | Scene이 정지된 구조 대기 상태 | 중복 모달 금지, 게임 시간 진행 금지 |
| `finished(RunResult)` | 한 런의 최종 결과 | 1회만 프로필에 반영하고 결과 화면으로 전이 |

## 2. 보상형 광고 계약

```swift
@MainActor
protocol RewardedAdServing {
    var isReady: Bool { get }
    func showRescueAd() async -> RewardedAdOutcome
}
```

결과 의미:

- `rewarded(impressionID)`: SDK의 보상 확정 콜백을 받은 경우만 반환한다. 닫힘·노출 콜백은 보상이 아니다.
- `dismissed`: 사용자가 보상 확정 전에 닫았다. 프로필과 런을 변경하지 않는다.
- `unavailable`: 재고, 연결, 구성 등으로 시작할 수 없다.
- `failed`: 시작 후 오류 또는 결과를 신뢰할 수 없다. fail closed 한다.

필수 불변조건:

1. 같은 `impressionID`는 한 프로세스에서 최대 한 번만 지급한다.
2. 보상은 `rewarded` 뒤에만 지급하고, 실패·취소에는 대체 보상을 자동 지급하지 않는다.
3. 호출 중 포기/홈 이동/새 Scene 전이가 일어나면 콜백은 원래 런 ID와 대조해야 한다. 현재 런 ID가 없어 구현 보강이 필요하다.
4. 앱이 active가 아니면 프로필 지급과 Scene 재개를 분리하고, 재개는 active 복귀 뒤 명시적으로 수행한다. 현재 `pendingRewardRunID`와 run/Scene binding으로 구현되며 simulator 회귀 테스트가 통과했다.
5. 실제 SDK 어댑터는 SDK 오류를 사용자 개인정보가 없는 내부 오류 범주로 변환한다.

## 3. 저장 계약

`PersistenceService.load()`는 유효한 현재/지원 구버전 프로필을 반환하고, 손상·지원하지 않는 미래 버전은 기본 프로필 또는 격리된 복구 경로로 처리해야 한다. `save`는 원자적 의미를 갖고 실패를 관측 가능하게 해야 한다.

현재 UserDefaults key는 `oneMoreCar.playerProfile.v1`, payload schema는 v2다. key의 `v1`은 schema 권위가 아니며 JSON의 `version`이 권위다. decoder는 raw version 1...2만 허용하고 그 밖의 payload는 거부한다. Persistence는 최초 decode 실패 원본을 `oneMoreCar.playerProfile.recovery`에 보존한 뒤 기본 프로필을 반환한다.

## 4. 미래 외부 경계

| 경계 | 최소 요청/응답 | 도입 전 필수 조건 |
|---|---|---|
| 분석 전송 | event name, event schema version, 익명 install/run ID, timestamp | 이벤트 사전, 동의/목적 판단, 보존기간, 삭제 경로, offline queue 한도 |
| 광고 SDK | load/show, reward ID, placement, error category | SDK 서명·privacy manifest, 데이터 흐름표, ATT 판단, 연령 적합성, kill switch |
| 친구 도전 딥링크 | version, challenge seed, optional score | 서명/검증, 길이 제한, 만료, replay·조작 방지, Universal Link 검증 |
| 서버 권위 점수 | idempotency key, run proof, score | 인증/남용 모델, 서버 검증, rate limit, 개인정보·운영 설계 |

서버가 없으므로 현재 “API 성공률”이나 원격 복구를 가정하면 안 된다. 외부 경계 추가는 ADR, 보안 검토, 개인정보 고지, 실패 UX, 계약 테스트를 동반해야 한다.
