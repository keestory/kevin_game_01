# 릴리스 체크리스트

현재 판정: **Build Readiness FAIL / Implementation Gate FAIL / App Store Release NOT READY**. 항목을 지웠다는 사실이 아니라 아래 증거 링크/산출물이 있어야 완료다.

## 코드 동결 전

- [ ] P0/P1가 0개이며 추적 매트릭스가 최신이다.
- [ ] 보상 callback의 중복 ID·dismissed·failed·pending 완료 테스트가 통과한다. runID·inactive 테스트는 완료했다.
- [ ] v2 round-trip·손상·음수 migration fixture가 통과한다. v1/future-version/recovery 테스트는 완료했다.
- [ ] 핵심 퍼널 이벤트 schema와 검증 가능한 관측 수단이 있다. 분석을 의도적으로 미도입한다면 출시 Go/No-Go 승인과 대체 측정 계획을 기록한다.
- [ ] 앱/단위/UI/Release 빌드가 CI 필수 체크다.
- [ ] 접근성, 한국어, 작은/큰 iPhone, 실제 최저 지원 기기 성능을 승인했다.

## 서명과 패키징

- [ ] `com.example.OneMoreCar`를 소유한 고유 bundle ID로 교체했다.
- [ ] Apple Developer team, 자동/수동 signing 정책과 최소 권한 App Store Connect 역할을 설정했다.
- [ ] Release archive 및 export가 clean runner에서 재현된다.
- [ ] entitlements, capabilities, embedded frameworks, dSYM, app version/build number를 검토했다.
- [ ] 앱 아이콘/launch asset과 라이선스·출처를 확인했다.

## 개인정보·보안

- [ ] archive에 실제 포함된 모든 SDK 목록과 signature/privacy manifest를 검사했다.
- [ ] `PrivacyInfo.xcprivacy`, App Store Connect 개인정보 답변, 개인정보 처리방침, 실제 네트워크 흐름이 일치한다.
- [ ] ATT 필요 여부와 `NSUserTrackingUsageDescription` 유무가 실제 동작과 일치한다.
- [ ] 광고가 있다면 광고 식별, 닫기/건너뛰기, 연령 적합성, 부적절 광고 신고, 보상 조건을 검토했다.
- [ ] secret scan과 dependency 취약점/라이선스 검토가 통과한다.
- [ ] 디버그 플래그, 테스트 광고 ID, 내부 endpoint가 Release에 남지 않는다.

## TestFlight

- [ ] 새 설치, 업데이트(v1 저장 포함), 앱 삭제/재설치 경로를 검증했다.
- [ ] background/foreground, 화면 잠금, 네트워크 단절, 광고 없음/실패를 검증했다.
- [ ] 최소 15분 soak 및 메모리/에너지/frame hitch를 실제 기기에서 확인했다.
- [ ] 크래시/로그/이벤트가 build number와 연결되고 개인정보를 포함하지 않는다.
- [ ] 지원/개인정보/마케팅 URL과 리뷰 노트를 확인했다.

## 제출과 출시

- [ ] App Store 메타데이터·스크린샷이 실제 기능만 설명한다. Debug mock 보상 광고를 출시 기능으로 표시하지 않는다.
- [ ] 연령 등급, 광고 포함 여부, 인앱 구매 항목을 실제 빌드와 일치시킨다.
- [ ] 단계적 출시/수동 출시와 rollback 기준을 정했다.
- [ ] 담당자·비상 연락·incident commander와 출시 시간대를 지정했다.
- [ ] 출시 후 1시간/24시간/7일 점검 항목과 중단 임계치를 승인했다.

## 현재 명시적 차단

1. 핵심 퍼널/크래시 관측성 부재(P1).
2. VoiceOver 코어 조작, Reduce Motion, 큰 글자·대비 등 제품 접근성 Gate 실패(P1).
3. 최소 5명 핵심 과업·광고 이해 사용성 Gate 미실행(P1).
4. 원격 CI는 game-core와 iOS 앱 컴파일을 통과했지만 앱 단위/UI/Release job은 미구현.
5. 개발 팀·고유 bundle ID·서명 Archive 미설정(P1 Release).
6. 실기기 성능/App Store Connect 개인정보 답변 미검증(Unknown).

해소됨: future-version reject/recovery backup, stale run 및 inactive reward Scene 재개 방지.
