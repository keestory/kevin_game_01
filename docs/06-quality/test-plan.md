# Return Shot 테스트 계획

- 기준일: 2026-08-18 KST
- 기준 계약: `docs/product-specs/return-shot-chain.product-spec.md` rev2
- 단계: Stage 6 Implementation
- 원칙: 코드·XCUITest·스크린샷은 실제 사용자 재미와 실기기 성능을 대체하지 않는다.

## 자동 규칙 테스트

| 범위 | 필수 계약 |
|---|---|
| 결정성 | 같은 seed 구조, 30/60/120Hz 합성 입력 checksum 동일 |
| 반사 | 접촉 offset과 패들 속도가 각도를 바꾸고 수평 무한 왕복 방지 |
| 충돌 | swept collision로 빠른 공의 tunneling 0 |
| LINK | 색·무늬·마크 독립, 정확히 5회에 6초 power 1회 |
| 프리즘 | 3HP, 반복 적중 LINK farming 금지, 완파/낙하 중복 없음 |
| 마이너스 | 직접 `−250`, cooldown·최대 2회, 지지 붕괴 `+120` |
| support graph | 모든 참조 유효, 제거 transaction 결정론적 |
| UI band | 권위 공이 HUD·coachmark 예약 영역에 진입하지 않음 |
| 기록 | score·height·combo·PB delta 계약과 저장 migration |

현재 `AppStoreGameTests/GameRulesTests.swift`의 12개 테스트가 위 범위를 실행한다.

## UI 흐름

`AppStoreGameUITests`는 격리된 seed 42와 fast-fail hook으로 다음을 검증한다.

1. 홈의 시작 CTA 존재
2. 시작 후 SpriteView 존재
3. 한 엄지 drag 입력
4. 일시정지 overlay와 재개
5. 결과 화면과 기록 delta
6. `같은 구조 다시` 후 새 gameplay Scene

테스트 hook은 Release 규칙을 바꾸지 않으며 종료는 재개 뒤에만 arm한다.

## 시각·반응형 QA

| 화면 | 증거 | 현재 |
|---|---|---|
| iPhone 17 Pro A/B | home, game, result 캡처 | Pass |
| iPhone 17e A | game 캡처 | Pass |
| iPhone SE 3세대 375×667 A | game 캡처 | Pass |
| SE home/result | 750×1334 캡처와 전체 UI 흐름 | Pass |
| 최대 Dynamic Type·Increase Contrast | 실제 화면 검사 | Pending P1 |
| VoiceOver·Switch Control | 핵심 흐름 실사용 | Pending P1 |

Vision 검사는 위계·간격·대비·텍스트·반응형·모바일·터치 명확성을 화면마다 확인한다. iPhone 앱에서 hover는 N/A이며 44pt target과 pressed state로 대체한다.

## 수동 사용자 Gate

- 5명 중 4명: 설명 없이 5초 안에 첫 리턴
- 5명 중 3명: 자발적 세 번째 run
- Run 3 score 또는 height 중앙값: Run 1 대비 `+20%`
- active-touch 중앙값 `≥60%`
- 5명 중 4명: LINK·프리즘·마이너스 간접 제거 설명
- 불공정 죽음·공 관통·중복 점수: 0건

## 실기기 성능·안정성

- 최소 지원 iPhone 10분 soak, 목표 60fps·hard floor 30fps
- 100ms 초과 gameplay hitch 0회
- retry 20회 뒤 메모리 증가 5MB 이하, leak 0
- background/foreground, 저전력, 열상태, 메모리 경고, Reduce Motion

## 재현 명령

```sh
swift test --scratch-path /private/tmp/ReturnShotSwiftPM
```

```sh
xcodebuild -project AppStoreGame.xcodeproj -scheme AppStoreGame \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
  -derivedDataPath /private/tmp/ReturnShotTestDerived \
  CODE_SIGNING_ALLOWED=NO test
```

추가 필수 검사: `plutil -lint`, `git diff --check`, secret scan, asset provenance hash, Assets.car contents. Release에는 signed archive/export와 App Store Connect 교차 확인을 추가한다.

## 최신 영수증

- SwiftPM: 12/12
- Xcode unit: 12/12
- XCUITest: 1/1, 22.667초
- 전체: 13/13, 114.094초
- xcresult: `/private/tmp/ReturnShotFinalDerived/Logs/Test/Test-AppStoreGame-2026.08.18_00-20-57-+0900.xcresult`
