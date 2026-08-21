# Unit Economics — 숫자를 만들지 않는 모델

## 현재 판정

한국 iOS 퍼즐의 동기간 CPI, rewarded-video eCPM·fill rate, 본 제품의 광고 선택률·ARPDAU·유지율·결제 전환이 없다. 따라서 손익분기 CPI나 1위 획득 예산을 신뢰할 수 있게 계산할 수 없다. 한국 모바일 게임 IAP 53억 달러, Block Blast 90만 다운로드 같은 시장 추정은 본 제품 LTV 입력이 아니다. [E14, E15](../01-research/evidence-register.md)

## 계산식

```text
광고 ARPDAU
= DAU당 보상형 광고 완료 수 × fill rate × eCPM / 1,000

IAP ARPDAU
= payer conversion × gross ARPPU × net receipt rate / 활동 일수

D30 gross LTV
= Σ(day별 생존 확률 × day별 ARPDAU), day 0..30

cohort contribution LTV
= gross LTV - 광고/결제 수수료 - 서버/지원/콘텐츠 변동비

허용 CPI(내부 제안)
= 관측 D90 contribution LTV × 0.5 안전계수

공유 K-factor
= 사용자당 유효 공유 수 × 공유 클릭률 × 설치 완료율
```

Apple 수수료와 광고 네트워크 정산률은 실제 계약·자격·지역 세금을 확인한 값만 입력한다. 공개 시장 평균을 팀 수익으로 복사하지 않는다.

## 최소 계측

| 입력 | cohort 기준 | 상태 |
|---|---|---|
| install source / creative / keyword | 일·캠페인 | 미확인 |
| tutorial complete, first win, retry | 설치 cohort | 미확인 |
| D1 / D3 / D7 / D30 retention | source·OS·version | 미확인 |
| rewarded offer / opt-in / complete / return | 위치·빈도 | 미확인 |
| payer conversion / refund / net receipt | SKU·cohort | 미확인 |
| share / open / install / first game | privacy-safe link | 미확인 |
| CPI / organic uplift | 채널·시간 | 미확인 |

## 의사결정 Gate

1. 광고 없이 D1 ≥30%, D7 ≥10%, 세션 내 재도전 ≥40%를 내부 다음 단계 기준으로 본다.
2. 이후 구조 광고 0회 대 1회 한도를 비교해 광고 ARPDAU와 유지 손실을 함께 측정한다.
3. 최소 4주 cohort 없이 D90 LTV를 확정하지 않는다. 초기에는 관측 구간 외 값을 범위로만 둔다.
4. 소액 UA에서 `CPI ≤ 관측 D90 contribution LTV × 0.5`가 재현되기 전 규모를 키우지 않는다.
5. share K-factor는 설치 보상 없이 측정하고, 어뷰징·중복 기기·자기추천을 제외한다.

위 D1/D7/재도전과 0.5 안전계수는 외부 벤치마크가 아닌 내부 제안이다. 제품·팀 자본 상황에 따라 Gate에서 재결정한다.

## 민감도 표

| 변수 | 관측값 | 증가할 때의 1차 효과 | 함께 확인할 역효과·교란 |
|---|---|---|---|
| 한국 iOS CPI | Unknown | 회수기간 증가, 허용 예산 감소 | 소재별 D1 차이, 오가닉 혼입 |
| rewarded eCPM / fill rate | Unknown | 광고 ARPDAU 증가 | 네트워크·계절·연령별 변동 |
| 광고 완료/DAU | Unknown | 단기 광고매출 증가 | 빈도 상승에 따른 D1/D7·세션 감소 |
| D1/D7/D30 유지율 | Unknown | 노출 기회와 LTV 증가 | 유료 cohort와 자연유입의 품질 차이 |
| payer conversion / net ARPPU | Unknown | IAP ARPDAU 증가 | 환불, 지원, 플랫폼 수수료·세금 |
| 일일 퍼즐·소재 운영비 | Unknown | contribution LTV 감소 | 품질·업데이트 속도와의 상호작용 |
| 자연 유입·공유 K-factor | Unknown | blended CPI 감소 가능 | 차트·크리에이터·공유 인과 중복 |

방향만 표시했으며 임의의 시장 평균, 중간값, 낙관값을 채우지 않았다. 동일 기간·지역·장르의 실측 cohort가 생긴 뒤 base/downside/upside를 계산한다.

## Business Validation

**Fail.** 다음 다섯 가지가 모두 미검증이다.

1. 선택형 구조 광고가 유지율을 보존하면서 의미 있는 ARPDAU를 만드는가.
2. 광고 제거·외형 상품에 실제 결제가 발생하는가.
3. 관측 D90 contribution LTV가 실제 한국 iOS CPI를 안전 여유를 두고 넘는가.
4. 일일 퍼즐·크리에이티브·QA 운영비를 소규모 팀이 감당하는가.
5. 차트 1위에 필요한 다운로드량과 획득비가 승인 가능한가.

따라서 현재 결정은 **Stage 2 Revise**, 유료 획득 확대는 **Stop**이다. 강제 친구 설치 보상은 수익·성장 모델에 포함하지 않는다.

현재 단위경제 판정은 **Unknown**이며 UA 확대는 **Stop**이다.
