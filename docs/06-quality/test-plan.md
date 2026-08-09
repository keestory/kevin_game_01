# 테스트 계획 — Product Harness revision 1

- 기준일: 2026-08-09
- 대상: 실제 열차 제동 vertical slice
- 기준 계약: `docs/product-specs/real-train-braking.product-spec.md`
- 판정 원칙: 증거 없는 P0/P1은 통과가 아니라 Blocked다.

## 1. 자동 테스트

### 순수 규칙

- 동일 시드·StationPlan·입력 시각의 grade, 하차 인원, 점수 결정성.
- perfect/safe/near 경계와 ±1ms, nil·범위 밖 입력.
- 5역 수요 `[5, 6, 6, 7, 8]`, 1단계 목표 22/32, 도움 난이도의 단조성.
- 5역 최대 1,500점을 넘지 않는 targetScore.
- PlayerProfile v1/v2→v3 마이그레이션, 새 튜토리얼 재노출, 미래 버전 복구.

### AppModel·Scene

- 첫 coachmark는 첫 결과 전 유지되고 첫 결과 후 저장된다.
- 첫 세 운행은 Rewarded Continue를 노출·실행하지 않는다.
- 이전 Scene의 snapshot/rescue/finished와 교체된 런의 callback은 무시한다.
- inactive 중 reward는 자동 재개하지 않고 현재 런에만 pending 처리한다.
- 동일 impression은 1회만 반영한다.
- 기본 5역 종료에서 elapsed=duration, 결과는 targetExited로 결정된다.
- 무료 추가 역은 1회·+12초이고 무료 재시도는 한 번 탭으로 새 런을 시작한다.

### UI smoke

- 첫 실행 → 홈 → 운행 → 실제 열차 Scene → 제동 CTA.
- coachmark, `역 접근 중/지금 제동/승하차 중`, 문 개방, 결과, 재시도.
- pause/background/foreground, 구조 제안, 설정 지속, 공유 sheet.

## 2. 수동·실기기 테스트

| ProductSpec | 증거 | 통과 |
|---|---|---|
| AC-1 | 텍스트 없는 첫 프레임 원본 캡처 | 실제 열차 구성요소·IP 감사 |
| AC-2 | 첫 역 타이머+coachmark 연속 영상 | 제동 가능 전 60초, 첫 결과 후 안내 종료 |
| AC-4 | 문 닫힘→열림→하차→탑승→닫힘 60fps 영상 | 문턱 통과, 차체 관통·순간이동 없음 |
| AC-5 | VoiceOver·Switch Control·Reduce Motion 영상 | 핵심 상태 인지, 비필수 모션 제거 |
| AC-8 | 익명 사용자 원시 기록 | 2초 5/5, 5초 4/5, 재시도 4/5, 재미 4/7 |
| AC-9 | Instruments·TestFlight 보고서 | 30분 soak, hitch·leak·진행 손상 없음 |
| AC-10 | App Store 제출 체크리스트 | 서명·메타데이터·정책·지원 준비 완료 |

## 3. 성능·안정성

- 최소 지원 실제 iPhone에서 평균 55fps 이상, p95 frame time 22ms 이하.
- 15분 플레이 중 100ms 초과 gameplay hitch 0회.
- 10회 재시작 후 메모리 증가 10MB 이하, leak 0.
- background/foreground 50회, 새 게임 100회에서 crash·중복 finish·보상 오염 0.
- Reduce Motion, 저전력, 열상태, 오디오 interruption, 비행기모드를 포함한다.

## 4. PR 필수 체크

1. ProductSpec·Decision Trace·Agent Run schema validation과 spec consistency.
2. `swift test`.
3. Xcode unit·UI smoke.
4. unsigned iOS Simulator build.
5. `plutil -lint`, `git diff --check`, secret/privacy scan.

Release에는 추가로 signed archive, entitlement·PrivacyInfo·App Store Connect 교차 확인, clean install·v1/v2 upgrade, 실기기 성능·접근성·30분 soak가 필요하다.

## 5. 재현 명령

```bash
npm exec --package @productspec/parser -- productspec validate docs/product-specs/real-train-braking.product-spec.md
npm exec --package @productspec/parser -- productspec validate-trace docs/decision-traces/real-train-braking.decision-trace.json
swift test --scratch-path /private/tmp/kevin-game-spm
xcodebuild -project AppStoreGame.xcodeproj -scheme AppStoreGame \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
  -derivedDataPath /private/tmp/kevin-game-tests CODE_SIGNING_ALLOWED=NO test
plutil -lint AppStoreGame/Resources/PrivacyInfo.xcprivacy
git diff --check
```

명령·Xcode/Swift/OS·exit code·xcresult·스크린샷·commit SHA를 Agent Run 영수증에 기록한다.
