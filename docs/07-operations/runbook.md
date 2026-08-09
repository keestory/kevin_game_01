# 운영 Runbook

## 1. 서비스 개요

현재 제품은 서버 없는 iOS 앱이다. 운영 표면은 App Store/TestFlight 배포, 앱 크래시, 로컬 진행 데이터, 향후 광고/분석 공급자다. 서버 uptime SLO는 해당 없으며, 현재 telemetry가 없어 crash-free session과 퍼널 지표는 측정할 수 없다.

## 2. 지원 환경과 로컬 검증

- macOS + Xcode 26.6, Swift 6.3.3
- deployment target iOS 17, iPhone portrait
- 외부 package 없음

```bash
git status --short --branch
swift test --scratch-path /private/tmp/kevin-game-spm
xcodebuild -project AppStoreGame.xcodeproj -scheme AppStoreGame \
  -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /private/tmp/kevin-game-derived CODE_SIGNING_ALLOWED=NO build
plutil -lint AppStoreGame/Resources/PrivacyInfo.xcprivacy AppStoreGame/Info.plist
```

정식 배포 전에는 `test-plan.md`의 simulator test와 Release archive도 실행한다.

## 3. CI

현재 `.github/workflows/swift-tests.yml`은 main push/PR에서 `swift test`와 unsigned generic iOS Simulator 앱 build를 실행하도록 변경됐다. 새 iOS job은 아직 원격 실행 전(Pending)이다. 실패 시:

1. run의 commit SHA, runner image, Swift version을 기록한다.
2. 동일 SHA에서 `/private/tmp` scratch 경로로 재현한다.
3. 규칙 실패인지 toolchain/image 변화인지 분리한다.
4. flaky 재실행으로 덮지 말고 seed와 실패 fixture를 보존한다.

후속 개선: 새 iOS app build 결과를 required check로 지정하고, Xcode 단위/UI smoke 및 Release 구성을 단계적으로 CI에 포함한다.

## 4. 릴리스 절차

1. [release-checklist](../06-quality/release-checklist.md)의 차단 항목이 0인지 확인한다.
2. 서명된 archive의 bundle ID, version/build, entitlements, embedded SDK, PrivacyInfo를 검사한다.
3. TestFlight 내부→외부 그룹 순으로 배포하고 clean install/update를 확인한다.
4. 단계적 출시를 기본으로 하며 중단 임계치와 담당자를 기록한다.
5. 출시 commit/tag, archive, dSYM, App Store 제출 값을 연결해 보관한다. 인증서·키는 저장소/일반 artifact에 넣지 않는다.

## 5. 기능별 장애 처리

| 증상 | 즉시 확인 | 안전한 완화 |
|---|---|---|
| 앱 시작 crash | build/OS/기기, crash stack, migration 입력 | 이전 안정 버전 출시 중단/rollback; 저장을 무조건 삭제하지 않음 |
| 진행 기록 초기화 | 앱 업데이트/삭제, payload version, save 오류 | 원본 payload 보존 후 migration hotfix; 허위 복구 약속 금지 |
| 게임 시간이 background에서 진행 | scenePhase, snapshot phase, 광고 callback 시각 | 해당 릴리스 중단; foreground 명시 재개 수정 |
| 광고 보상 중복/누락 | placement, 익명 run ID, impression ID, callback 순서 | 광고 placement kill switch; 게임 기본 루프는 유지 |
| 광고 로드 실패 | SDK/네트워크/재고 상태 | 보상 선택지만 unavailable 처리; 앱 시작/게임을 차단하지 않음 |
| 개인정보 불일치 | archive SDK, 실제 요청 domain, manifest/label | SDK 초기화/광고 중단, Privacy incident 절차 진입 |

현재 Release 광고는 unavailable이라 원격 kill switch가 없다. 실제 SDK를 추가할 때 앱 업데이트 없이 비활성화할 수 있는 최소 구성과 안전한 기본값을 필수로 한다.

## 6. 로컬 데이터 초기화

QA에서는 전용 UserDefaults suite 또는 앱 삭제를 사용한다. 운영 사용자의 데이터를 자동 삭제하거나 migration 실패 즉시 덮어쓰지 않는다. 재현에 payload가 필요하면 사용자 동의 후 개인 식별정보 없는 최소 fixture로 변환한다.

## 7. 관측과 출시 중단 기준

현재 관측성은 부재하므로 정량 자동 중단이 불가능하다(P1). 출시 전 최소한 다음을 익명·버전형 이벤트 또는 App Store 지표로 검증한다: app_start, run_start, first_success, rescue_offer, rescue_outcome, run_finish, fatal/nonfatal 오류. 개인정보 없이 build, schema version, state, error category만 기록한다.

제안 초기 중단 기준은 기준선 대비 crash-free sessions 급락, 시작 불가 P0 재현, 진행 유실 P1 다수, 보상 무결성 오류, 선언하지 않은 데이터 전송 중 하나다. 정확한 수치는 TestFlight 기준선을 얻은 뒤 소유자와 승인한다(현재 Unknown).

## 8. 롤백

App Store에서 이미 설치된 binary를 원격 제거할 수 없으므로 단계적 출시 일시중지, 이전 안정 build 재제출, 서버/SDK kill switch를 조합한다. schema는 backward compatibility를 유지하고 rollback 앱이 새 schema를 파괴하지 않도록 future-version fail closed를 먼저 구현한다.
