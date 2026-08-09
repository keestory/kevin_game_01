# Draft Analytics Plan — 한 칸만! 만원열차

> 상태: DRAFT / 계측 미구현
> 현재 단계: Stage 0/1 재검증
> 모든 목표값은 시장 관측값이 아니라 **내부 가설·Gate**다.

## 1. 의사결정 목적

분석은 “기능이 사용되었는가”보다 다음 위험 가설을 판정해야 한다.

1. 첫 사용자가 코어 규칙을 이해하는가.
2. 첫 실패가 재도전으로 이어지는가.
3. 안전 손잡이와 혼잡 완화가 유지율을 높이는가.
4. 구조 광고가 단기 수익보다 장기 이탈을 만들지 않는가.
5. 공유·친구 도전이 실제 플레이로 이어지는가.

## 2. North Star와 입력 지표

### North Star 후보

`주간 활성 사용자당 자발적 재도전 완료 수`

정의: 한 결과 화면 후 10분 안에 사용자가 직접 시작해 완료한 추가 런 수. 광고 자동 복귀, 테스트 봇, 충돌 재실행은 제외한다.

이 지표가 장기 가치와 연결되는지는 아직 미검증이다. D1/D7과의 상관을 베타에서 확인한 뒤 확정한다.

### 입력·가드레일

| 지표 | 내부 중단선 | 내부 목표 | 비고 |
|---|---:|---:|---|
| 첫 역 완료율 | 90% | 95%+ | 활성화 |
| 첫 판→두 번째 판 | 65% | 75%+ | 재도전 |
| 첫 세션 완료 런 | 4 | 6+ | 중앙값 병기 |
| D1 | 30% | 35~40% | 설치 캘린더 기준 정의 필요 |
| D7 | 8% | 12%+ | 표본·채널 분리 |
| 구조 광고 선택률 | 15% | 20~30% | 높을수록 무조건 좋지 않음 |
| 광고 후 다음 판 | 55% | 65%+ | 가드레일 |
| 결과 공유 시작률 | 3% | 5~8% | 완료와 구분 |
| 크래시 없는 세션 | 99.5% | 99.7%+ | 기술 가드레일 |
| 첫 실패 직후 종료 | 20% | 12% 이하 | UX 가드레일 |
| 접근성 모드 과업 성공 | 80% | 100% | 5명 연구와 별도 |

## 3. 식별자와 개인정보 원칙

- `install_id`: 기기 Keychain에 생성하는 임의 UUID 후보. 광고 ID, Apple ID, 기기 serial과 연결하지 않는다.
- `session_id`: 앱 활성 세션별 임의 UUID.
- `run_id`: 런 시작별 임의 UUID.
- 이름, 연락처, 친구 이름, 공유 대상, 메시지 본문을 수집하지 않는다.
- 세부 탭 좌표는 기본적으로 수집하지 않는다. 필요 시 열 번호만 기록한다.
- IP·광고 식별자·SDK 자동 수집은 도입 전에 Security/Privacy 승인을 받는다.
- 만 14세 미만 포함 가능성을 연령 등급 단계에서 검토하고 불필요한 프로파일링을 금지한다.
- 이벤트 보관 기간, 삭제, 내보내기, 공급자 리전은 SDK 선택 전 미확인이다.

## 4. 공통 이벤트 속성

| 속성 | 형식 | 설명 | PII |
|---|---|---|---|
| `event_version` | Int | 스키마 버전 | 아니오 |
| `app_version` | String | 앱 버전 | 아니오 |
| `rules_version` | String | 밸런스/시드 규칙 버전 | 아니오 |
| `install_id` | UUID | 무작위 설치 식별자 | 가명 정보 |
| `session_id` | UUID | 세션 식별자 | 아니오 |
| `timestamp_utc` | ISO-8601 | 발생 시각 | 아니오 |
| `locale` | enum | `ko-KR` 등 | 낮은 위험 |
| `device_class` | enum | small/standard/large | 아니오 |
| `accessibility_flags` | bitset | Reduce Motion, Larger Text 범주 등 최소화 | 민감 가능; 명시적 검토 필요 |

접근성 사용 여부는 건강·장애 추론 위험이 있으므로 기본 전송하지 않는다. 테스트 참여자가 동의한 연구 빌드에서만 익명 집계하는 안을 검토한다.

## 5. 이벤트 택소노미

| Event | 발생 조건 | 필수 속성 | PII | 현재 상태 |
|---|---|---|---|---|
| `app_opened` | 앱 활성화 최초 1회 | cold_start | 없음 | 미구현 |
| `home_viewed` | 홈이 가시 상태 | highest_stage, assisted | 없음 | 미구현 |
| `tutorial_shown` | 튜토리얼 실제 표시 | tutorial_version | 없음 | 미구현 |
| `tutorial_completed` | 시작 CTA 탭 | elapsed_ms | 없음 | 미구현 |
| `run_started` | 실제 플레이 phase 진입 | run_id, stage, seed_type, difficulty | 없음 | 미구현 |
| `first_input` | 런 최초 유효 탭 | run_id, elapsed_ms, column | 없음 | 미구현 |
| `match_resolved` | 하차 발생 | run_id, removed_count, cascade_count | 없음 | 미구현 |
| `safety_handle_used` | 손잡이 차감 | run_id, remaining_handles, elapsed_ms | 없음 | 미구현 |
| `rescue_offer_shown` | 구조 UI 가시 | run_id, free, reason | 없음 | 미구현 |
| `rescue_choice` | 수락/거절 | run_id, choice, free | 없음 | 미구현 |
| `rewarded_ad_outcome` | SDK callback 확정 | run_id, outcome, provider_error_class | 광고 ID 금지 | 미구현 |
| `run_finished` | 결과 확정 | run_id, stage, completed, score, duration, rescue_used, assisted, end_reason | 없음 | 미구현 |
| `retry_selected` | 결과에서 재도전 | prior_run_id, next_stage | 없음 | 미구현 |
| `share_sheet_opened` | 시스템 공유 시트 요청 | run_id, surface | 공유 대상 없음 | 미구현 |
| `challenge_link_opened` | 향후 딥링크 검증 성공 | challenge_id, source_surface | 친구 정보 없음 | 미구현 |
| `challenge_finished` | 동일 시드 도전 결과 | challenge_id, run_id, latest_score | 친구 정보 없음 | 미구현 |
| `setting_changed` | 설정 값 변경 | setting_name, value_enum | 접근성 민감값 제외 | 미구현 |
| `app_error` | 복구 가능한 제품 오류 | error_class, route | 원문/비밀 금지 | 미구현 |

`passenger_placed` 전량 수집은 비용과 노이즈가 크므로 기본 MVP에서 제외한다. 규칙 디버깅이 필요하면 동의한 테스트 빌드에서 표본 세션만 수집한다.

ShareLink가 완료 여부를 제공하지 않는 경우 `share_completed` 이벤트를 만들지 않는다. 공유 시트 오픈을 완료로 추정하면 안 된다.

## 6. 퍼널 정의

### Activation

```text
app_opened
→ home_viewed
→ run_started
→ first_input
→ 첫 match_resolved
→ 첫 run_finished
→ retry_selected
→ 두 번째 run_finished
```

### Failure & Rescue

```text
rescue_offer_shown
→ rescue_choice
→ rewarded_ad_outcome
→ run_finished
→ retry_selected
```

분모를 `제안 노출`, `수락`, `광고 시작`, `보상 완료`로 분리한다.

### Referral 후보

```text
share_sheet_opened
→ challenge_link_opened
→ challenge_finished
→ 24시간 내 재대결
```

텍스트 공유만 있는 현재 빌드에서는 링크 이후 퍼널을 측정할 수 없다.

## 7. 실험 계획

| ID | 가설 | 설계 | Primary | Guardrail | 중단 기준 |
|---|---|---|---|---|---|
| E01 | 외부 설명 없이 규칙 이해 | 5명 조정 사용성 테스트 | 4/5 핵심 과업 성공 | 좌절·오선택 | 2명 이상 실패 |
| E02 | 첫 실패는 6역보다 8역이 유지에 유리 | TestFlight 무작위 A/B | 첫 판→두 번째 판, 첫 세션 런 | 첫 10분 지루함 | 어느 안이든 첫 실패 직후 종료 20%+ |
| E03 | 무료 첫 구조가 즉시 광고보다 신뢰를 높임 | 클릭 프로토타입 후 제한 A/B | 다음 판 시작 | 강제성 인식 | 오선택 1/5 또는 종료 증가 |
| E04 | `기록 공유`보다 동일 시드 도전이 강함 | 딥링크 전 클릭 프로토타입 | 도전 시작 의향/완료 | 스팸 인식 | 링크 오픈→완료 50% 미만 |
| E05 | 혼잡 완화 공개가 신뢰를 높임 | 문구 A/B + 인터뷰 | 재도전, 이해도 | 조작 인식 | 30% 이상이 벌·조작으로 인식 |

표본 지침:

- E01은 Gate 최소치 5명이며 통계적 시장 검증이 아니다.
- 무설명 코어 테스트는 최소 30명으로 오류 패턴을 본다.
- 유지율/광고 실험은 TestFlight 300명 이상 계획을 출발점으로 하되, 실제 baseline과 최소 탐지 효과를 계산해 표본을 확정한다.
- 채널·기기·신규/복귀를 섞어 Simpson's paradox를 만들지 않는다.

## 8. 데이터 품질 Gate

출시 실험 전 다음을 충족해야 한다.

- 이벤트 누락률 <1%, 중복률 <1%.
- `run_started`마다 `run_finished` 또는 명시적 `abandoned`가 연결됨.
- 동일 광고 impression으로 보상이 중복 기록되지 않음.
- 앱 버전과 rules version으로 결과를 재현 가능.
- 기기 시간 변경이 일일 시드·D1 계산에 주는 영향 문서화.
- 개발·UI 테스트·직원 트래픽 제외 규칙 존재.
- 개인정보처리방침, Privacy Manifest, SDK 실제 수집이 일치.

## 9. 현재 판정

**Data & Experimentation Gate: FAIL.** 이벤트 구현과 데이터 QA가 없으며 사용자 테스트도 실행되지 않았다. 이 문서는 구현 계약 초안이지 실측 결과가 아니다.
