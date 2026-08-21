# 실제 열차 콘셉트 시장 재조사

확인일: 2026-08-09 (Asia/Seoul)
국가/플랫폼: 대한민국 / iPhone App Store 우선, Google Play 교차 확인
책임: Market & Store Intelligence + Strategy + Product Orchestrator

## 판정

**Revise-Go:** `정차선 제동 원탭 + 실제 승하차` vertical slice는 진행한다. 본개발, 1위 예측, 수익모델 검증은 보류한다.

## Evidence Table

| ID | 출처 | 게시·갱신 | 관측/추정 | 근거 | 한계 |
|---|---|---|---|---|---|
| RT01 | [Apple 한국 무료 Games 웹 차트](https://apps.apple.com/kr/iphone/charts/6014?chart=top-free) | 동적, 20:52 KST 확인 | 관측/A | #1 쿠키런 키우기, #7 Block Out, #11 Bus Traffic Fever, #16 Block Blast, #25 Royal Match | 역사 스냅샷 아님 |
| RT02 | [Apple 무료 Games RSS](https://itunes.apple.com/kr/rss/topfreeapplications/limit=100/genre=6014/json) | 2026-08-09 | 관측/A | 같은 날 Bus Traffic Fever #13 | 웹과 갱신 시각 차이 |
| RT03 | [Apple 최고매출 Games RSS](https://itunes.apple.com/kr/rss/topgrossingapplications/limit=100/genre=6014/json) | 20:47 KST | 관측/A | Gossip Harbor #4, Royal Match #6, Tasty Travels #15; 직접 열차/교통 퍼즐 Top25 없음 | 매출액 비공개 |
| RT04 | [Bus Traffic Fever App Store](https://apps.apple.com/kr/app/bus-traffic-fever/id6759763476), [Google Play](https://play.google.com/store/apps/details?id=jp.co.goodroid.hyper.busflow) | 앱 2026-07 갱신 | 관측/A | 움직이는 차량·색상 승객 탑승, Play 글로벌 1,000만+ 설치 구간 | 한국 iPhone 수요·우리 루프 유지율 근거 아님 |
| RT05 | [Train Conductor World App Store](https://apps.apple.com/kr/app/train-conductor-world/id932228293), [Google Play](https://play.google.com/store/apps/details?id=com.thevoxelagents.tc3) | 2026-06 갱신 | 관측/A | 움직이는 열차·목적지·순간 판단, Play 글로벌 1,000만+ 설치 구간 | 한국 iOS 현지 적합 미확인 |
| RT06 | [Mini Metro App Store](https://apps.apple.com/kr/app/mini-metro/id837860959) | 2025-09 갱신 | 관측/A | 승객 혼잡·역·노선이 한 화면의 시스템으로 연결 | 유료/전략 게임, 직접 BM 비교 불가 |
| RT07 | [Bus Jam App Store](https://apps.apple.com/kr/app/bus-jam/id6450176534) | 동적 | 리뷰 관측/A+C | 자가선택 리뷰에서 잦은 광고·반복 레벨·불가능 레벨 불만이 제기됨 | 리뷰 수·기간·버전의 대표성 미확인 |
| RT08a | [Royal Match App Store](https://apps.apple.com/kr/app/%EB%A1%9C%EC%96%84-%EB%A7%A4%EC%B9%98-royal-match/id1482155847) | 2026-08 확인 | 관측/A | Apple 한국 최고매출 #6 | 매출액·원인 비공개 |
| RT08b | [Royal Match Google Play](https://play.google.com/store/apps/details?id=com.dreamgames.royalmatch) | 2026-08 확인 | 운영자 설명/A | Google Play 설명이 100% 무광고를 주장; IAP·이벤트 중심 | 팀·UA·콘텐츠 규모 재현 불가 |
| RT09 | [Apple App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/), [AdMob Rewarded iOS](https://developers.google.com/admob/ios/rewarded) | 2026-06~07 확인 | 정책/A | 광고 닫기·건너뛰기·선택과 reward callback 계약 | 실제 SDK 선택 후 재감사 필요 |
| RT10 | [Apple Designing for Games](https://developer.apple.com/design/human-interface-guidelines/designing-for-games), [Motion](https://developer.apple.com/design/human-interface-guidelines/motion) | 현재 문서 | 정책/A | 플레이로 학습, 목적 있는 모션, 시청각·햅틱 병행, Reduce Motion | 제품 재미를 보장하지 않음 |

## 통합 결론

1. 움직이는 열차와 승하차는 첫 2초 스토어 크리에이티브 훅 후보다.
2. 제동 반복만으로 D1과 매출이 생긴다는 근거는 없다. 5명×3회 재플레이와 방향성 A/B가 먼저다.
3. 첫 3판은 무광고, 실패 후 무료 재시도가 기본이다.
4. Continue는 미검증 가설이다. `마지막 제동 1회 되돌리기`를 우선 후보로 두고, 현재 구현의 `다음 역 +12초`와 별도 A/B하기 전에는 수익모델로 확정하지 않는다.
5. 친구 설치·가입 보상은 제외하고 결과 공유부터 검증한다.

## Contradictions / Unknowns

- Apple 웹과 RSS 순위가 같은 날 다르다. 캐시·갱신 시각 차이로 보고 둘 다 시각과 함께 기록한다.
- 차량 게임 글로벌 1,000만+ 사례와 한국 매출 Top25 부재가 동시에 존재한다.
- 한국 CPI, eCPM, LTV, 무료 1위 진입 다운로드 수, 본 게임 D1/D7는 모두 미확인이다.
- 이동 열차가 스토어 전환을 높여도 멀미·오탭·D1 하락을 만들 수 있다.

## 중단 기준

- 10명 중 8명 미만이 설명 없이 첫 행동 이해
- 이동형 오탭이 정지형보다 상대 20% 이상 증가
- 10명 중 2명 이상 멀미·시각 혼란 보고
- 최소 방향성 테스트에서 3회차 재플레이 또는 D1 개선 없음
- 최소 지원 iPhone에서 안정적 30fps 미달

이 수치는 업계 벤치마크가 아니라 사전 등록한 내부 실험 기준이다.
