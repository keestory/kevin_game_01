# Incident Response

## 1. 목적과 역할

App Store/TestFlight 앱의 충돌, 기록 유실, 점수·규칙 무결성, 개인정보·공급망 사고에 대응한다. 실제 출시 전 담당자 이름과 연락 수단을 채운다.

| 역할 | 책임 | 현재 |
|---|---|---|
| Incident Commander | 등급/의사결정/종료 선언 | 미지정 |
| Engineering Lead | 재현, 완화, 수정, 빌드 증거 | 미지정 |
| Privacy/Security Lead | 데이터 범위·신고 의무 판단 | 미지정 |
| Product/Support | 사용자 영향·메시지·보상 정책 | 미지정 |
| Release Manager | 단계적 출시 중단/재제출 | 미지정 |

## 2. 등급

| 등급 | 기준 | 첫 대응 목표(제안) |
|---|---|---|
| SEV-0 | 선언하지 않은 데이터 유출/추적, 서명키 노출, 대규모 실행 불가 | 즉시, 15분 내 지휘 지정 |
| SEV-1 | 기록 대량 유실, 점수·규칙 무결성 악용, 높은 crash, 핵심 루프 불가 | 30분 내 지휘 지정 |
| SEV-2 | 부분 기능 저하, 광고 재고/분석 장애, 우회 가능 | 영업일 4시간 내 triage |
| SEV-3 | 소수 UI/문구/비핵심 품질 | 정상 backlog |

수치는 출시 기준선 후 확정한다. 개인정보 의심은 영향 사용자 수와 무관하게 Security/Privacy Lead에 즉시 올린다.

## 3. 공통 절차

1. **탐지/기록**: 최초 시각(KST/UTC), build, OS/기기, 설치/업데이트, 재현 단계, 사용자 영향을 기록한다.
2. **분류**: crash, migration, lifecycle, gameplay integrity, privacy, supply chain 중 하나 이상으로 분류하고 IC를 지정한다.
3. **봉쇄**: 단계적 출시 중단, SDK kill switch, PR/배포 동결 중 가장 작은 안전 조치를 적용한다.
4. **보존**: commit SHA, CI run, archive/manifest, symbolicated crash, 개인정보를 제거한 payload/callback sequence를 보존한다.
5. **완화/복구**: 재현 테스트를 먼저 추가하고 가장 작은 수정으로 새 build를 검증한다.
6. **소통**: 사실/추정/미확인을 분리하고 다음 갱신 시각을 공유한다.
7. **종료/회고**: 모니터링 기준을 충족한 뒤 종료하며 5영업일 내 원인·통제·소유자·기한을 기록한다.

## 4. 시나리오별 대응

### 저장/migration

- affected version과 raw schema version을 확인한다.
- 원본을 덮어쓰거나 전 사용자 데이터를 일괄 초기화하지 않는다.
- current/future/corrupt fixture로 hotfix와 rollback 양방향을 검증한다.
- 복구 불가 범위를 사실대로 알리고 추정 데이터를 만들지 않는다.

### 점수·규칙 중복 또는 불일치

- seed, tick, quantized paddle input, collision/removal event 순서와 checksum을 수집한다.
- duplicate contact, tunneling, 낡은 Scene, background delta, support edge 불일치를 확인한다.
- 재현 seed를 fixture로 고정하고 점수·리더보드 확장을 중지한다.
- 공격/남용 판단 전에 클라이언트 규칙 결함과 조작을 분리한다.

### 개인정보/SDK

- SDK 초기화와 관련 전송을 우선 중단한다.
- 데이터 항목, 목적, 수신 domain/사업자, 사용자/지역, 시작·종료 시각, 보존 상태를 확정한다.
- archive의 PrivacyInfo, App Store 답변, ATT 흐름과 실제 트래픽을 대조한다.
- 법무/Apple/사용자 통지 의무와 기한은 관할·사실에 근거해 별도 판단한다. 로그/티켓에 광고 ID나 원본 식별자를 붙이지 않는다.

### signing/supply chain

- 노출된 인증서, App Store Connect API key, CI token을 폐기/회전하고 audit log를 보존한다.
- 마지막 신뢰 가능한 commit/action SHA/runner에서 clean archive를 재생성한다.
- 권한과 branch protection을 검토하고 서명되지 않은 산출물 배포를 중단한다.

## 5. 현재 탐지 공백

분석·crash reporter·서버가 없으므로 현재 탐지는 Xcode/TestFlight/App Store 진단과 사용자 보고에 의존한다. 핵심 퍼널, 비치명 오류, 저장 실패, 규칙 checksum 이상을 자동 감지할 수 없다(P1). 관측 도구 도입 자체도 [security-review](../06-quality/security-review.md)의 개인정보/SDK Gate를 통과해야 한다.

## 6. 회고 템플릿

- 사건/등급/기간/영향 build 및 사용자 범위
- 사용자 영향과 데이터 영향
- 탐지 경로 및 탐지 지연
- 시간순 사실(추정은 별도)
- 근본 원인과 기여 요인
- 잘 작동한 통제/실패한 통제
- 수정 항목, 소유자, 기한, 검증 테스트
- 재발 시 자동 탐지·봉쇄 기준
- 문서/ADR/PrivacyInfo/App Store 답변 변경
