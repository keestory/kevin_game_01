# Draft Acceptance Criteria — 한 칸만! 만원열차

> 상태: DRAFT / 검증 전
> 판정 기준: `Met`, `Partial`, `Fail`, `Not built`, `Not tested`
> P0/P1가 하나라도 열려 있으면 UX/Product Gate는 Fail이다.

## 1. 심각도

- **P0:** 크래시, 진행 데이터 손실, 광고 보상 중복/오지급, 플레이 차단, 개인정보·정책 중대 위반.
- **P1:** 핵심 규칙 이해 실패, 잘못된 사용자 문구, 접근성 핵심 과업 불가, 첫 실패/광고 오선택, 재현 가능한 주요 UX 결함.
- **P2:** 우회 가능한 시각·편의 문제, 출시 후 개선 가능한 비핵심 기능.

## 2. Core Gameplay

| ID | Priority | Given / When / Then | 검증 | 현재 상태 |
|---|---:|---|---|---|
| AC-CORE-01 | P0 | Given 빈 보드, When 유효 열을 탭, Then 승객이 가장 낮은 빈칸에 1회 배치된다 | 단위+UI | Met/실사용 미검증 |
| AC-CORE-02 | P0 | Given 같은 목적지 3명이 상하좌우 연결, When 마지막 승객 배치, Then 그룹이 하차하고 점수가 1회 반영된다 | 단위 | Met |
| AC-CORE-03 | P0 | Given 같은 시드·스테이지·규칙, When 동일 수의 승객 생성, Then 순서가 동일하다 | 단위 | Met |
| AC-CORE-04 | P1 | Given 첫 사용자, When 설명 없이 시작, Then 60초 안에 첫 배치를 완료한다 | 5명 테스트 | Not tested |
| AC-CORE-05 | P1 | Given 첫 사용자, When 첫 매치를 경험, Then 90초 안에 “같은 배지 3명” 규칙을 설명한다 | 5명 테스트 | Not tested |
| AC-CORE-06 | P1 | Given 색각 차이, When 승객을 판독, Then 색 없이 도형만으로도 목적지를 구분한다 | 접근성 테스트 | Partial |

## 3. Onboarding & Difficulty

| ID | Priority | Given / When / Then | 검증 | 현재 상태 |
|---|---:|---|---|---|
| AC-ONB-01 | P1 | Given 첫 실행, When 홈 표시, Then 5초 안에 운행 시작 CTA를 찾는다 | 5명 테스트 | Not tested |
| AC-ONB-02 | P1 | Given 첫 실행, When 운행 시작, Then 가입·알림·광고가 플레이보다 먼저 나타나지 않는다 | UI | Met |
| AC-ONB-03 | P1 | Given 튜토리얼 종료, When 플레이 시작, Then 준비 없이 시간이 부당하게 소모되지 않는다 | UI/관찰 | Not tested |
| AC-DIFF-01 | P1 | Given 1~3역, When 신규 사용자가 플레이, Then 최초 시도 클리어율 목표가 90% 이상이다 | 계측 베타 | Not tested |
| AC-DIFF-02 | P1 | Given 2회 연속 실패, When 홈으로 복귀, Then 혼잡 완화 적용과 변경점을 사용자가 인지한다 | UI+5명 | Partial/Not tested |
| AC-DIFF-03 | P1 | Given 혼잡 완화, When 사용자에게 설명, Then 70% 이상이 벌이나 몰래 조작으로 인식하지 않는다 | 설문 | Not tested |

## 4. Failure, Safety Handles & Rescue

| ID | Priority | Given / When / Then | 검증 | 현재 상태 |
|---|---:|---|---|---|
| AC-FAIL-01 | P0 | Given 손잡이가 남음, When 가득 찬 열에 배치, Then 손잡이 1개만 차감하고 규칙대로 승객을 제거한다 | 단위+UI | Partial |
| AC-FAIL-02 | P1 | Given 손잡이 사용, When 복구, Then 원인 열·차감·감속을 시각/텍스트/햅틱 중 2개 이상으로 알린다 | 관찰 | Partial |
| AC-RES-01 | P0 | Given 첫 구조, When 수락, Then 광고 없이 평생 한 번만 지급된다 | 단위/통합 | Partial |
| AC-RES-02 | P0 | Given 광고 callback, When 동일 impression ID가 반복, Then 보상은 한 번만 지급된다 | 통합 | Partial: set 기반 guard 존재, 명시적 중복 callback 회귀 테스트와 실제 SDK E2E 없음 |
| AC-RES-03 | P0 | Given 광고 거절·실패·불가, When 결과 화면 이동, Then 새 판을 무료로 즉시 시작할 수 있다 | UI | Partial |
| AC-RES-04 | P1 | Given 구조 화면, When 사용자 5명이 확인, Then 5/5가 광고 여부·보상·거절 결과를 정확히 설명한다 | 5명 테스트 | Not tested |
| AC-RES-05 | P1 | Given 구조 화면, Then 광고·거절 CTA가 각각 명확한 대비와 최소 44×44pt 영역을 가진다 | 접근성 감사 | Not measured |
| AC-RES-06 | P1 | Given 부활 사용 기록, When 공식 경쟁 등록, Then 제외 또는 구조 기록으로 명확히 분리한다 | 통합 | Not built |
| AC-RES-07 | P0 | Given 유효 보상 callback이 앱 비활성 중 도착, Then 현재 런에 pending으로 보관하고 자동 재개하지 않으며 복귀 후 명시적 CTA로 적용한다 | 단위+코드 감사 | Met at model/source; 실제 SDK UI E2E 미검증 |
| AC-RES-08 | P0 | Given 이전 런의 늦은 callback, Then 새 런·프로필에 보상을 적용하지 않는다 | 단위 | Met |

## 5. Sharing & Friend Challenge

| ID | Priority | Given / When / Then | 검증 | 현재 상태 |
|---|---:|---|---|---|
| AC-SHARE-01 | P1 | Given 텍스트만 공유, Then CTA는 `기록 공유하기`로 사실대로 표시한다 | 콘텐츠 감사 | Met (코드 확인) |
| AC-SHARE-02 | P1 | Given `같은 막차` CTA, When 친구가 링크 실행, Then 동일 시드·규칙·스테이지로 진입한다 | E2E | Not built |
| AC-SHARE-03 | P0 | Given 친구 보상, Then 설치·가입·평점이 아니라 도전 완료 후 양쪽에 동일하게 지급한다 | 정책+통합 | Not built |
| AC-SHARE-04 | P0 | Given 초대, Then 연락처 업로드나 가입이 코어 플레이 조건이 아니다 | 개인정보 감사 | Current pass |
| AC-SHARE-05 | P1 | Given 도전 결과, Then 부활·보정 여부와 기록 조건이 동일하다 | E2E | Not built |

## 6. Content & Localization

| ID | Priority | Given / When / Then | 검증 | 현재 상태 |
|---|---:|---|---|---|
| AC-COPY-01 | P1 | Given 스테이지 성공, Then 실제 역 번호가 제목에 표시된다 | 단위+코드 감사 | Met; 회귀 테스트 포함 |
| AC-COPY-02 | P1 | Given 효과음 미구현, Then 작동하지 않는 효과음 토글을 노출하지 않는다 | 코드 감사 | Met; 햅틱 토글만 노출 |
| AC-COPY-03 | P1 | Given 실패, Then 비난·죄책감 대신 실패 원인과 무료 재도전을 설명한다 | 콘텐츠 테스트 | Partial |
| AC-COPY-04 | P1 | Given 광고 제안, Then `광고 1회`, 정확한 보상, 보상 미지급 조건을 한국어로 명시한다 | 콘텐츠 테스트 | Partial |
| AC-L10N-01 | P2 | Given 한국어 외 언어 추가, Then 모든 사용자 문구가 Strings Catalog에서 관리된다 | 정적 검사 | Not built |
| AC-L10N-02 | P1 | Given 콘텐츠, Then 실제 교통기관 상표·노선도를 복제하지 않는다 | 법무/디자인 | Current pass, 최종 감사 필요 |

## 7. Accessibility

| ID | Priority | Given / When / Then | 검증 | 현재 상태 |
|---|---:|---|---|---|
| AC-A11Y-01 | P1 | Given VoiceOver, When 핵심 플레이, Then 현재 열·다음 승객·결과를 인지하고 배치할 수 있다 | 실기기 | Fail/Not supported |
| AC-A11Y-02 | P1 | Given Larger Text 최대 접근성 크기, Then 홈·튜토리얼·구조·결과의 텍스트와 CTA가 잘리지 않는다 | 스냅샷+실기기 | Not tested |
| AC-A11Y-03 | P1 | Given Reduce Motion, Then SpriteKit 배경 이동·입자·확대 축소가 정적 또는 감소 상태가 된다 | 실기기 | Fail/Partial |
| AC-A11Y-04 | P1 | Given 주요 버튼, Then 기본 목표 크기는 44×44pt 이상이다 | 코드 측정 | Met for audited controls: 일시정지 44×44pt |
| AC-A11Y-05 | P1 | Given HUD, Then 필수 정보는 11pt 이상이며 본문은 가능한 17pt 기본을 따른다 | 코드 측정 | Met for audited HUD minimum: 11pt; Larger Text는 별도 미검증 |
| AC-A11Y-06 | P1 | Given 모든 필수 텍스트, Then WCAG 2.2 AA 대비를 측정·통과한다 | 도구 측정 | Not measured |
| AC-A11Y-07 | P1 | Given 소리 꺼짐, Then 모든 중요한 상태는 시각 또는 햅틱으로도 전달된다 | 실기기 | Partial |

## 8. Analytics & Privacy

| ID | Priority | Given / When / Then | 검증 | 현재 상태 |
|---|---:|---|---|---|
| AC-DATA-01 | P0 | Given 이벤트 발생, Then 이벤트명·버전·세션·스테이지·규칙 버전을 기록한다 | 통합 | Not built |
| AC-DATA-02 | P0 | Given 분석 데이터, Then 이름·연락처·공유 대상·정확한 광고 식별자를 수집하지 않는다 | 데이터 감사 | Not built |
| AC-DATA-03 | P0 | Given SDK 추가, Then Privacy Manifest와 App Store 데이터 공개가 실제 동작과 일치한다 | 개인정보 감사 | Not built |
| AC-DATA-04 | P1 | Given 테스트 세션, Then 핵심 퍼널 이벤트 누락·중복이 각각 1% 미만이다 | 데이터 QA | Not tested |
| AC-DATA-05 | P1 | Given ShareLink, Then OS가 완료 결과를 제공하지 않으면 `share_completed`를 추정 생성하지 않는다 | 코드 감사 | Not built |

## 9. 현재 Open P0/P1

### P0

- 분석/광고 SDK 도입 전 데이터 흐름과 보상 idempotency 통합 테스트가 없음.
- 향후 친구 보상은 서버 검증·중복 방지·정책 검토가 없음.

현재 프로덕션 SDK와 친구 보상이 미구현이므로 즉시 사용자 피해는 없지만, 구현 전 차단 조건이다.

### P1

1. VoiceOver로 코어 보드 조작 불가.
2. SpriteKit이 Reduce Motion을 충분히 반영하지 않음.
3. 대비, Larger Text, Switch Control, Voice Control 미검증.
4. 구조 광고 보상·거절 이해도 사용자 테스트 미실행.
5. 최소 5명 사용성 테스트 미실행.

HUD 11pt, 일시정지 44pt, `shareRecordButton` 정합성 항목은 2026-08-09 현재 코드 감사에서 해소됐다.

## 10. Gate

**FAIL.** 위 P1을 해소하고 최소 5명 테스트에서 핵심 과업 4/5, 광고 이해 5/5를 충족해야 재판정한다.
