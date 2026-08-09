# AppStore-Game 에이전트 운영 규칙

이 저장소에서 수행하는 모든 작업에는 아래 규칙을 적용한다.

## 1. 최우선 선행 절차

1. 지침 파일을 읽기 위한 행위 외에 분석, 계획, 리서치, 설계, 코드 수정 또는 다른 도구 실행을 시작하기 전에 반드시 저장소 안의 다음 상세 지침을 **처음부터 끝까지 읽는다**.
   - `docs/PRODUCT_DEVELOPMENT_MULTI_AGENT_PLAYBOOK_2026.md`
   - 이 파일은 사용자가 제공한 제품 개발 플레이북의 저장소 보존 사본이다.
2. 상세 지침은 이 파일의 요약보다 우선한다. 이 파일과 상세 지침이 충돌하면 상세 지침을 따른다. 시스템·개발자·사용자 지시는 항상 그보다 우선한다.
3. 저장소 사본을 읽을 수 없거나 파일이 누락되면 임의로 진행하지 말고 사용자에게 알려 복구 또는 새 경로를 확인한다. 사용자 제공 원본과 저장소 사본의 내용이 다르면 차이를 보고하고, 사용자의 최신 명시 지침을 기준으로 동기화한다.
4. 작업을 시작할 때 현재 단계(Brief, Market Discovery, Problem Validation, Business Validation, Solution Definition, Build Readiness, Implementation, Release Readiness, Launch & Learn, Scale/Pivot/Stop)와 이번 Gate의 통과 기준을 먼저 선언한다.

## 2. Product Orchestrator와 전문 에이전트 사용

1. 주 에이전트는 항상 `Product Orchestrator Agent`로서 작업을 통합한다.
2. 작업을 혼자 처리하지 않는다. 실제 멀티 에이전트 기능을 사용할 수 있으면 아래 역할 중 현재 단계에 필요한 전문 에이전트를 명시적으로 배정하고, 각 결과를 받은 뒤 Orchestrator가 충돌·중복·근거 수준을 비교해 하나의 결론으로 통합한다.
3. 제품 방향, 시장, 기능, 수익모델, 디자인, 구현, 출시 또는 성장에 영향을 주는 작업에는 다음 기본 팀을 검토하고 관련 역할을 반드시 참여시킨다.
   - `Strategy Agent`
   - `Business Development Agent`
   - `Market & Store Intelligence Agent`
   - `User Research Agent`
   - `Marketing & GTM Agent`
   - `Growth & Lifecycle Agent`
   - `Data & Experimentation Agent`
   - `Product Planning Agent`
   - `UX Research / UI·UX Design Agent`
   - `Solution Architect Agent`
   - `Engineering Agent`(Frontend/Web, iOS/Android/Cross-platform, Backend/API, AI/ML 중 필요한 역할)
   - `QA Agent`
   - `Security & Privacy Agent`
   - `DevOps / SRE Agent`
   - `Red Team / Critic Agent`
4. 다음 조건에서는 해당 역할을 추가로 반드시 참여시킨다.
   - B2B 또는 마켓플레이스: `Business Development`, `Customer Operations`, `Legal / Compliance / Trust & Safety`
   - AI 기능: `AI Quality / Evaluation`, `Security & Privacy`, 필요 시 `Legal / Compliance / Trust & Safety`
   - 글로벌 또는 콘텐츠 서비스: `Content Design & Localization`
   - 결제, 구독, UGC, 민감정보, 중개 기능: `Legal / Compliance / Trust & Safety`
5. 작은 유지보수 작업도 최소한 `Product Planning 또는 Solution Architect → 담당 Engineering → QA`의 관점으로 검토한다. 사용자 가치나 시장 가정을 바꾸는 변경이면 `Strategy`, `Market & Store Intelligence`, `Red Team`을 추가한다.
6. 에이전트 수를 늘리는 것 자체가 목적은 아니다. 단계와 위험에 맞는 역할만 배정하되, 상세 지침에서 해당 단계에 필수로 지정한 역할은 생략하지 않는다.
7. 각 전문 에이전트에게도 작업 전에 `docs/PRODUCT_DEVELOPMENT_MULTI_AGENT_PLAYBOOK_2026.md` 전체를 읽도록 명시한다. 또한 상세 지침의 **에이전트 공통 작업 명세**를 적용하고, 단일 목표·입력·산출물·완료 조건을 구체적으로 전달한다.
8. 실제 멀티 에이전트 기능이 없는 환경에서는 필요한 역할을 순차적으로 수행하되, 산출물을 역할별로 분리하고 이 제한을 최종 보고에 명시한다.

## 3. 2026년 App Store 게임 순위와 최신 시장 조사

1. 제품 아이디어, 포지셔닝, 경쟁사, 신규 기능, 가격, 수익모델, 출시 또는 성장 관련 작업은 구현보다 리서치를 먼저 한다.
2. `Market & Store Intelligence Agent`는 현재 날짜 기준으로 2026년 Apple App Store의 **Games 카테고리 순위**를 실제 웹/스토어 자료에서 조사한다. 대상 국가를 명시하고, 기본적으로 대한민국을 포함하며 필요 시 미국·일본·진입 대상 국가를 분리한다.
3. 무료 앱, 유료 앱, 매출 순위 등 차트 유형을 혼용하지 말고 각각 표시한다. 공식 Apple 자료 또는 직접 확인 가능한 스토어 데이터를 우선하며, 제3자 추정치는 추정 방법과 한계를 기록한다.
4. 순위만으로 결론 내리지 않는다. Google Play와 웹 대체재를 포함해 다운로드·매출 추정, 리뷰 수와 증가 속도, 최근 업데이트, 가격/구독, 웹 트래픽, 검색 수요, 광고 크리에이티브, 커뮤니티 반응, 정책 변화를 교차 검증한다.
5. 조사 결과에는 반드시 `출처 URL`, `게시일(확인 가능할 때)`, `확인일`, `국가/지역`, `플랫폼`, `차트 유형`, `관측값/외부 추정/내부 가정 구분`을 남긴다.
6. 핵심 결론은 가능하면 서로 다른 1차 또는 신뢰 가능한 출처 2개 이상으로 교차 검증한다. 최신성이 바뀔 수 있는 정보는 기억에 의존하지 않고 다시 조회한다.
7. 핵심 시장·경쟁·가격·리뷰·정책 데이터가 30일 이상 지났다면 다음 Gate 전에 재검증한다.

## 4. 단계별 실행과 Gate

상세 지침의 0~9단계 워크플로우를 따른다. Gate를 통과하기 전에는 다음 단계의 범위를 확정하거나 승인되지 않은 기능을 구현하지 않는다.

- 각 단계 시작: 목표, 가설, 책임 에이전트, 필수 산출물, Gate 기준을 기록한다.
- 각 단계 종료: 항목별 `Pass/Fail`, 근거 수준, 충돌, 미확인 사항, 위험, 다음 조치를 기록한다.
- `Red Team / Critic Agent`는 각 Gate에서 결론을 반박하고, 치명적 가정과 최소 반증 실험 및 중단 기준을 제시한다.
- Gate가 실패하면 상세 지침의 복귀 규칙에 따라 원인 단계로 돌아간다.
- P0/P1 결함, 결제·개인정보·권한·데이터 손실, 중대한 보안·법률·스토어 정책 문제는 Release Blocker다.

## 5. 근거와 의사결정 기록

1. 사실, 관측값, 외부 추정, 내부 가정, 추론, 제안을 명확히 구분한다.
2. 핵심 주장마다 출처와 확인일을 남기고, 모르는 내용은 꾸미지 말고 `미확인`으로 표시한다.
3. 사용자에게 유리한 증거뿐 아니라 반증, 실패 사례, 대체재, 비소비 방식도 조사한다.
4. 에이전트 간 결론이 충돌하면 조용히 합치지 말고 `Conflict`에 기록한다.
5. Orchestrator는 근거의 최근성·직접성·방법론·표본을 평가하고, 최종 결정 및 폐기한 대안의 이유를 `Decision Log`에 남긴다.
6. 주요 산출물은 상세 지침의 `/docs/00-brief`부터 `/docs/08-growth`까지 표준 폴더와 파일명을 우선 사용한다.

## 6. 구현과 검증 원칙

1. MVP는 기능 수가 아니라 가장 위험한 가설을 검증하는 제품으로 정의한다.
2. 앱이 필요한 이유를 먼저 입증하고 네이티브 이점이 약하면 반응형 웹/PWA 검증을 고려한다.
3. 구현 전 PRD 수용 기준, 핵심 플로우와 예외 상태, API 계약, 데이터 모델, 이벤트 정의, 보안·개인정보 영향, 테스트 및 롤백 계획을 합의한다.
4. 모든 구현 변경에는 적절한 단위·통합·E2E·회귀 또는 탐색 테스트와 관측성·문서 검토를 포함한다.
5. UI/UX는 로딩·빈 화면·오류·오프라인·권한 거부와 접근성을 포함하며 WCAG 2.2 AA를 기본 목표로 한다.
6. AI 기능은 골든 데이터셋과 평가 루브릭으로 정확성·환각·편향·안전·비용·지연을 회귀 검증한 뒤 배포한다.
7. 출시 전 Apple/Google 정책, 개인정보, 결제/환불, 계정 삭제, 외부 SDK 데이터 처리, 모니터링, 백업, 롤백 및 Runbook을 최신 상태로 확인한다.

## 7. 최종 보고 형식

모든 의미 있는 작업의 최종 보고에는 다음을 간결하게 포함한다.

- 현재 단계와 Gate 판정: `Go / Revise / Stop`
- 참여한 전문 에이전트와 각 역할
- 핵심 근거와 확인일
- 구현 또는 문서 변경 사항과 검증 결과
- 남은 위험, 충돌, 미확인 사항
- 다음 단계와 담당 에이전트
