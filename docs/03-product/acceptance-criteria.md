# Acceptance Criteria — 실제 열차 60초 vertical slice

> 기준일: 2026-08-09
> 상태: 구현 검증 중 / 사용자 테스트 전
> P0/P1가 열려 있으면 Solution Gate는 `Revise`다.

## Core & Timing

| ID | Pri | Given / When / Then | 검증 | 상태 |
|---|---:|---|---|---|
| AC-CORE-01 | P0 | 같은 StationPlan과 탭 시각이면 프레임률·효과와 무관하게 같은 등급·하차·점수가 나온다 | 단위 | Met |
| AC-CORE-02 | P0 | 5개 역은 하차 가능 5/6/6/7/8명과 지정 제동 창을 가진다 | 단위 | Met |
| AC-CORE-03 | P0 | 경계값은 정위치→안전→가까움에 포함되고 그 밖은 통과다 | 단위 | Met |
| AC-CORE-04 | P0 | 목표 점수를 일찍 얻어도 5번째 역 전 결과 화면으로 이동하지 않는다 | 통합 | 구현, 테스트 추가 필요 |
| AC-CORE-05 | P1 | 첫 제동 버튼은 시작 후 1초 안에 활성 가능 상태가 되고 최적 입력은 약 6초다 | UI/관찰 | 구현, 미측정 |
| AC-CORE-06 | P1 | 첫 단계 목표는 22명이며 신규 1차 성공률 65~80%를 목표로 조정한다 | 베타 | Not tested |

## Visual & Feedback

| ID | Pri | Given / When / Then | 검증 | 상태 |
|---|---:|---|---|---|
| AC-VIS-01 | P1 | 첫 프레임 0.5초 내 화면 폭 55% 이상의 차체·문·창·바퀴·선로·플랫폼이 보인다 | 캡처+5명 | 구현, 사용자 미검증 |
| AC-VIS-02 | P1 | 승객은 머리·몸·다리 형태로 문을 실제 통과하고 원형 토큰 낙하로 대체되지 않는다 | 캡처 | Met(코드), 시각 QA 필요 |
| AC-VIS-03 | P1 | 제동 결과마다 감속·텍스트·사운드·햅틱 중 최소 3채널이 일치한다 | 탐색 | 구현, 실기기 미검증 |
| AC-VIS-04 | P1 | 정위치 파티클 ≤20, 급정차 불꽃 ≤8, 전체 화면 섬광 없음 | 코드+탐색 | Met(코드) |
| AC-VIS-05 | P1 | 앱 런타임은 실제 교통기관 로고·노선도·안내음 또는 ImageGen 콘셉트 이미지를 포함하지 않는다 | 자산 감사 | Met |

## Onboarding & UX

| ID | Pri | Given / When / Then | 검증 | 상태 |
|---|---:|---|---|---|
| AC-UX-01 | P1 | 텍스트를 가린 2초 노출에서 5/5가 지하철/열차로 식별한다 | 5명 | Not tested |
| AC-UX-02 | P1 | 5초 노출 후 4/5가 정차선에 맞춰 탭해 승객을 내리는 게임이라고 설명한다 | 5명 | Not tested |
| AC-UX-03 | P1 | 첫 제동 무도움 입력 중앙값 ≤8초다 | 5명 | Not tested |
| AC-UX-04 | P1 | 4/5 이상이 요청 없이 두 번째 운행을 시작하고 재미 중앙값 ≥4/7이다 | 5명×3회 | Not tested |
| AC-UX-05 | P1 | 튜토리얼은 플레이를 막지 않고 첫 제동 결과까지 유지되며, 첫 결과 후 사라진다 | UI/단위 | 구현, E2E 필요 |

## Failure, Ads & Sharing

| ID | Pri | Given / When / Then | 검증 | 상태 |
|---|---:|---|---|---|
| AC-FAIL-01 | P0 | 목표 미달이어도 광고·초대·가입 없이 같은 운행을 1탭으로 재시작한다 | UI | 구현, E2E 필요 |
| AC-RES-01 | P0 | 목표까지 8명 초과 남으면 Continue를 제안하지 않는다 | 단위/통합 | Met(장면 조건) |
| AC-RES-02 | P0 | 첫 무료 Continue는 추가 역 1회·+12초만 지급한다 | 통합 | 구현, E2E 필요 |
| AC-RES-03 | P0 | 광고 reward는 동일 impression에 1회, 이전 런에는 0회 적용된다 | 단위 | 기존 테스트 Met |
| AC-RES-04 | P1 | 5/5가 광고 여부·보상·거절 결과를 정확히 설명한다 | 5명 | Not tested |
| AC-SHARE-01 | P1 | CTA는 설치 보상·동일 시드가 아니라 `운행 기록 공유하기`로 정확히 표현한다 | 콘텐츠 | Met |

## Accessibility

| ID | Pri | Given / When / Then | 검증 | 상태 |
|---|---:|---|---|---|
| AC-A11Y-01 | P1 | 제동 버튼은 64pt 이상이며 Voice Control·Switch Control로 작동한다 | 실기기 | 크기 Met, 보조기술 Not tested |
| AC-A11Y-02 | P1 | Reduce Motion에서 먼 도시·속도선·객차 진동·흔들림·파티클이 사라진다 | 코드+실기기 | 코드 Met, 실기기 필요 |
| AC-A11Y-03 | P1 | 사운드·햅틱을 각각 꺼도 접근·제동·문·결과를 시각적으로 안다 | 탐색 | Partial |
| AC-A11Y-04 | P1 | 필수 정보는 색 외에 선·아이콘·도형·텍스트·숫자로 중복된다 | 코드+5명 | Partial |
| AC-A11Y-05 | P1 | iPhone SE급·17 Pro, 최대 Larger Text에서 HUD·열차·CTA가 겹치지 않는다 | 스냅샷/실기기 | Not tested |

## Quality & Performance

| ID | Pri | Given / When / Then | 검증 | 상태 |
|---|---:|---|---|---|
| AC-QA-01 | P0 | SwiftPM, iOS 앱 단위, UI smoke, unsigned Simulator build가 모두 통과한다 | CI/로컬 | 재검증 중 |
| AC-QA-02 | P1 | 최소 지원 기기 평균 ≥55fps, p95 ≤22ms, 동시 파티클 ≤24다 | Instruments | 파티클 코드 Met, 성능 Not tested |
| AC-QA-03 | P1 | pause/background에서 clock·Scene action·audio가 멈추고 자동 재개하지 않는다 | 통합/탐색 | Partial |
| AC-QA-04 | P1 | 10회 연속 운행의 메모리 증가 ≤10MB, 누수 0이다 | Instruments | Not tested |

## Gate

현재 판정은 **Revise**다. 자동 테스트 통과 외에 5명 사용성·접근성·실기기 성능 P1이 남아 있다.
