# 테스트 계획

- 기준일: 2026-08-09
- 대상: Build Readiness 및 현재 vertical slice 구현
- 판정 원칙: P0/P1 미해결이면 Implementation Gate는 통과하지 않는다.

## 1. 심각도

| 등급 | 기준 | 예 |
|---|---|---|
| P0 | 데이터/개인정보 대규모 유출, 실행 불가, 보상 무한 지급, 치명적 출시 위반 | 앱 시작 crash, 실제 광고의 무제한 보상 |
| P1 | 핵심 루프·진행·보상·lifecycle 오류, 출시/검증 차단 | background 중 게임 재개, 미래 저장 손상, 앱 CI 부재 |
| P2 | 우회 가능한 기능·접근성·운영 품질 결함 | 일부 VoiceOver 순서, 진단 메시지 누락 |
| P3 | 미세한 표현·정리 | 비핵심 문구 정렬 |

## 2. 현재 자동화 증거

| 계층 | 범위 | 결과 | 한계 |
|---|---|---|---|
| SwiftPM 단위 | 보드, seed, 난이도, 도움, v1/future migration, 결과 문구 | 2026-08-09 독립 재실행 11/11 통과 | AppModel/Scene/서비스 제외 |
| Xcode 단위 | SwiftPM 범위 + recovery/stale run/inactive reward | 2026-08-09 독립 재실행 14/14 통과 | 중복 ID·실패·pending 완료 edge case 부족 |
| Xcode UI smoke | 첫 실행→게임 | 2026-08-09 독립 재실행 통과 | rescue/accessibility 경로 제외 |
| Xcode app build | generic iOS Simulator, signing off | 2026-08-09 로컬 성공; CI job 추가 | 새 commit 원격 실행은 Pending |
| Release archive | 서명/배포 | 미실시 | team/bundle ID 미설정 |

원격 증거: [GitHub Actions run 31308952608](https://github.com/keestory/kevin_game_01/actions/runs/31308952608)는 변경 전 `swift test`만 성공했다. 새 `ios-app-build` job은 아직 commit/push 전이므로 원격 결과를 성공으로 간주하지 않는다.

## 3. 필수 테스트 시나리오

### 게임 규칙/난이도

- 같은 seed와 동일 입력 sequence가 동일한 보드·점수·결과를 만든다.
- 각 stage에서 목표 점수는 증가하고 selector floor, destination 수, safety handle 범위를 지킨다.
- overflow 시 보드 불변, safety handle 소비, 0개가 되면 구조 제안 전이를 검증한다.
- 도움 모드가 사용자에게 표시되고 정상 모드보다 어렵지 않음을 검증한다.

### 보상형 구조

- 무료 구조는 설치 단위 1회만 사용되고 저장된다.
- `rewarded(id)`는 1회만 +15초/프로필 반영한다.
- 동일 ID의 중복 callback은 무시한다.
- dismissed/unavailable/failed는 상태·누계를 변경하지 않는다.
- 광고 로딩 중 중복 탭과 포기를 막는다.
- callback 전 홈 이동/새 런 시작 시 낡은 callback을 폐기한다.
- inactive/background 중 callback은 Scene을 재생하지 않고 active 복귀 후 명시적으로 진행한다.
- 실제 SDK 도입 시 닫힘 callback과 reward callback 순서가 바뀌거나 중복되는 fixture를 포함한다.

### 저장/migration

- no data, v1, v2 round-trip, 손상 JSON, 타입 오류, 음수 값, version 3/99 fixture를 검증한다.
- 지원하지 않는 미래 버전을 로드한 뒤 원본이 덮어써지지 않는지 검증한다.
- 저장 실패를 주입해 게임이 crash하지 않고 오류가 관측되는지 확인한다.

### lifecycle/일시정지

- playing에서 inactive/background 진입 즉시 elapsed가 멈춘다.
- active 복귀는 사용자 resume 전까지 시간을 진행하지 않는다.
- tutorial, pause overlay, rescue offer, ad loading 각각에서 background/foreground를 왕복한다.
- 화면 잠금, 전화/오디오 interruption, 빠른 scenePhase 반복에도 중복 finish/보상이 없다.

### 접근성/현지화

- VoiceOver로 홈→튜토리얼→게임→일시정지→결과를 수행한다.
- 색 없이 승객 종류, 성공/실패, 선택 열을 구분할 수 있다.
- Reduce Motion, Reduce Transparency, Bold Text, 큰 Dynamic Type에서 화면 잘림을 검사한다.
- 햅틱 off에서도 모든 필수 상태를 인지할 수 있다.
- 한국어 문자열 잘림과 숫자/시간 형식을 작은/큰 iPhone에서 확인한다.

### 성능/안정성

- 실제 지원 최저 성능 기기에서 15분 연속 플레이, p95 프레임 시간과 메모리 증가를 계측한다.
- background/foreground 50회, 연속 새 게임 100회에서 leak/crash가 없다.
- SpriteKit 노드 수가 한 런 동안 무제한 증가하지 않는지 Instruments로 확인한다.

## 4. CI 승인 기준

PR 필수:

1. `swift test`
2. `xcodebuild build-for-testing` 또는 `test`로 앱+단위 테스트 컴파일
3. 최소 smoke UI test
4. `git diff --check`, secret scan, PrivacyInfo plist 검증

main/release 필수:

1. Release configuration build/archive
2. 서명/entitlement 검증
3. clean install 및 v1 upgrade test
4. 개인정보 manifest와 App Store Connect 답변의 수동 교차 확인

## 5. 재현 명령

```bash
swift test --scratch-path /private/tmp/kevin-game-spm
xcodebuild -project AppStoreGame.xcodeproj -scheme AppStoreGame \
  -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /private/tmp/kevin-game-derived CODE_SIGNING_ALLOWED=NO build
xcodebuild -project AppStoreGame.xcodeproj -scheme AppStoreGame \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -derivedDataPath /private/tmp/kevin-game-tests test
plutil -lint AppStoreGame/Resources/PrivacyInfo.xcprivacy AppStoreGame/Info.plist
git diff --check
```

시뮬레이터 이름/OS는 설치된 런타임에 맞춰 고정하고 CI 이미지 변경 시 명시적으로 갱신한다.
