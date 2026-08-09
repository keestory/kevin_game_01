# Endless Score Pivot — 2026-08-10

확인일: 2026-08-10 KST

단계: `Stage 1 — Market Discovery 재시작`

판정: `후보 탐색 Pass / Prototype Revise-Go / Solution·출시·한국 무료 1위 Gate Fail·Unknown`

## 1. Executive Decision

열차의 정차·승하차·인원 맞추기 게임은 제품 방향에서 중단한다. 현재 구현은 보존하되 더 이상 그래픽·효과·수익화 기능을 추가하지 않는다.

새 단일 후보는 **`연쇄파괴: 리턴 샷`**이다.

> 한 엄지로 패들을 계속 끌어 공을 받아치고, 접촉 위치와 패들 속도로 반사각을 만든다. 구조물의 약점을 꿰뚫어 연쇄 붕괴시키며 점수·높이·콤보 개인 기록을 끝없이 갱신하는 세로형 물리 아케이드.

이 결정은 완성 게임 제작 승인이 아니다. `2일 deterministic collision spike`와 `5일 광고 없는 graybox`만 승인하는 검증용 결정이다.

## 2. 기존 열차 게임을 중단하는 이유

오너의 반복 플레이 피드백에서 다음 문제가 일관되게 확인됐다.

- 1개 역에서 의미 있는 입력이 한 번뿐이라 플레이어가 대부분 구경한다.
- 5개 역과 60초가 끝나면 숙련을 계속 증명할 기록 공간이 없다.
- 성공이 타이밍 한 번에 치우쳐 반사각·경로·위험 선택 같은 조작 숙련이 없다.
- 실제 열차 그래픽을 강화해도 코어 상호작용 부재를 해결하지 못했다.

따라서 열차 외형을 다시 개선하는 것은 원인 해결이 아니라 시각적 리스킨이다.

## 3. 2026-08-10 시장 관측

무료와 매출 차트는 별도로 본다. 동적 차트는 같은 날에도 Apple 웹과 RSS의 갱신 시각에 따라 하위 순서가 달랐으므로 순간 순위를 지속 수요로 일반화하지 않는다.

| 근거 | 직접 관측 | 사용할 수 있는 결론 / 한계 |
|---|---|---|
| [Apple 한국 iPhone 무료 Games](https://apps.apple.com/kr/iphone/charts/6014?chart=top-free) | CookieRun 계열 #1, Block Out #7, Bus Traffic Fever #11, Block Blast #16을 확인. 웹에는 Smash Fest #24가 노출됐으나 RSS 끝부분과 불일치 | 간단한 퍼즐·물리 파괴 게임의 획득 가능성만 지지. 장기 유지·매출·1위 재현 근거가 아님 |
| [Apple 한국 무료 Games RSS](https://itunes.apple.com/kr/rss/topfreeapplications/limit=100/genre=6014/json) | 2026-08-10 00:46 KST 갱신. 상위 핵심 순서는 웹과 유사했으나 Top 25 끝부분은 불일치 | 동적 스냅샷. 역사 재현 자료가 아니며 정확한 설치량은 미공개 |
| [Apple 한국 매출 Games RSS](https://itunes.apple.com/kr/rss/topgrossingapplications/limit=100/genre=6014/json) | 같은 갱신 시각에 CookieRun, WOS, Gossip Harbor, Lineage M, Kingshot, Royal Match 등이 상위 | 현재 매출 상위는 강한 메타·라이브 운영작 중심. endless arcade 매출 적합성은 `Unknown` |
| [Smash Fest — Apple KR](https://apps.apple.com/kr/app/smash-fest/id6748084174) | 4.7, 약 2.6K 한국 평가. 노출 리뷰에 장기 플레이·사운드 만족과 반복 레이아웃·광고 불만이 함께 존재 | 파괴 피드백과 기록 욕구의 방향성 proxy. 자기선택 리뷰라 D1/D7을 추정할 수 없음 |
| [Block Blast — Apple KR](https://apps.apple.com/kr/app/%EB%B8%94%EB%A1%9D-%EB%B8%94%EB%9D%BC%EC%8A%A4%ED%8A%B8-block-blast/id1617391485) | 4.7, 약 65K 한국 평가. 점수·콤보를 반복하는 단순 퍼즐 | 한국에서 간단 조작과 기록 추격 수요가 존재함을 지지. 신규 인디의 성과 보장은 아님 |
| [Slingshot Smash — Google Play](https://play.google.com/store/apps/details?id=slingshot.building.destroy) | 글로벌 Android 5천만+ 표시, 물리 파괴·최대 점수 | destruction creative의 글로벌 획득성 proxy. 한국 iPhone 유지·수익 자료가 아님 |
| [Bricks Ball Crusher — Apple KR](https://apps.apple.com/kr/app/bricks-ball-crusher/id1473232934) | 약 9.3K 한국 평가, 점수·랭킹·대량 스테이지 | 조준·반사·점수 수요 지지. 10,000+ handcrafted stage는 소규모 팀에 경고 |
| [Encircle — Google Play](https://play.google.com/store/apps/details?id=com.dawikk.encircle) | 선을 그어 루프를 닫고 입자를 포획하는 거의 동일한 규칙, 5+ 다운로드 표시 | `Looplight` 원안은 차별성도 시장 반응도 약해 중단 |

개별 경쟁작의 한국 iOS D1/D7, CPI, ARPDAU, LTV와 한국 무료 1위에 필요한 일간 설치량은 공개 근거로 확인하지 못했다.

## 4. 후보 비교와 폐기

| 후보 | 장점 | 결정적 위험 | 판정 |
|---|---|---|---|
| 연쇄파괴: 리턴 샷 | 지속 drag, 반사각 숙련, 파괴 쾌감, procedural endless, 기록 추격 | 고전 Breakout 복제품처럼 보일 수 있음, 물리 공정성과 가시성 비용 | `Revise-Go` |
| analog endless runner | 입력 빈도·거리 기록이 명확 | Subway Surfers 계열의 강한 incumbent, 트랙·시즌 콘텐츠 treadmill | `Stop` |
| one-thumb rhythm | 입력·정확도·콤보가 명확 | 음악 카탈로그·라이선스·저지연 판정·오디오 QA가 핵심 해자 | `Stop` |
| Looplight 포획 | continuous draw와 영역 리스크 | Encircle과 핵심 규칙이 거의 같고 관측된 시장 반응이 약함 | `Stop` |
| 열차 인원·정차 타이밍 | 한국적 소재, 짧은 설명 | 입력 빈도·숙련·endless 기록이 부족하며 반복 오너 테스트에서 재미 실패 | `Stop` |

## 5. 검증할 코어

### 5.1 조작

- 공은 자동으로 왕복하고 플레이어는 하단 패들을 좌우 drag한다.
- 패들은 최대 속도로 손가락을 추종한다. 즉시 teleport하지 않아 이동 속도도 기술이 된다.
- 반사각은 `접촉 위치`와 `패들 이동 속도`가 함께 결정한다.
- 중앙·정지 리턴은 생존에 유리하고, 가장자리·고속 리턴은 높은 각도와 배율에 유리하다.
- 목표 active-touch 중앙값은 플레이 시간의 60% 이상, 의미 입력은 분당 20~40회다. 이는 시장 사실이 아니라 테스트 기준이다.

### 5.2 파괴

- 위쪽에는 행 단위 블록이 아니라 `유리 조각 — 연결부 — 핵심 지지점` 구조 그래프가 생성된다.
- 빛나는 지지점을 맞히면 연결된 3개 이상의 조각이 연쇄 붕괴한다.
- 화면은 높이 방향으로 계속 상승하며 스테이지 종료가 없다.
- 파편은 점수용 물리 객체가 아니라 짧은 cosmetic feedback으로만 사용해 공을 가리지 않는다.

### 5.3 기록

- 기본 기록: `총점`, `최고 높이`, `최대 연쇄`, `리턴 샷 연속 횟수`.
- 좌측 ruler에 개인 최고 높이선을 계속 표시한다.
- 동일 seed 재도전에서는 이전 run의 pace ghost와 최근 공 궤적을 낮은 투명도로 보여준다.
- 실패 후 0.6초 안에 결과를 보여주고, `같은 구조 다시` 한 번 탭으로 0.8초 이내 재시작한다.
- 60초에 게임을 끝내지 않는다. 실수할 때까지 계속 기록이 상승한다.

### 5.4 점수 가설

- 유리 타격: 10점
- 직접 파괴: 30점
- 지지점 붕괴: 연결 조각당 50점
- 연쇄 배율: 1.0 → 1.5 → 2.0 → 최대 4.0
- 고위험 `리턴 샷` 중 파괴: ×2
- 개인 최고 높이선 돌파: 현재 combo 기반 보너스

정확한 수치는 graybox에서 조정한다. 점수 booster나 유료 부활은 leaderboard와 분리하지 않는 한 금지한다.

## 6. 첫 60초 경험 가설

| 시간 | 경험 |
|---|---|
| 0–5초 | 패들과 낙하지점을 pulse하고 `드래그로 받아쳐요` 한 줄만 표시. 첫 공이 5초 안에 돌아옴 |
| 5–15초 | 1HP 유리 6개와 지지점 1개. 첫 연쇄붕괴를 seed로 보장 |
| 15–30초 | 비대칭 구조와 벽 bank shot 도입 |
| 30–45초 | 2HP 연결부와 고위험 `리턴 샷` 배율 활성 |
| 45–60초 | 회전 연결부, 두 지지점 중 경로 선택, PB pace 표시 |
| 60초 이후 | 종료 없이 속도와 구조 복잡도를 단계적으로 올리되, 속도 상한 이후에는 밀도만 증가 |

첫 30초 동안 2초를 넘는 강제 입력 공백을 허용하지 않는다.

## 7. Breakout 복제품이 되지 않기 위한 P0

다음 다섯 요소가 실제 플레이 의사결정을 바꾸지 못하면 차별화 실패다.

1. 패들 속도가 반사각에 실질적으로 기여한다.
2. 지지점 조준이 개별 블록 타격보다 큰 연쇄붕괴를 만든다.
3. 스테이지 클리어가 아니라 endless height chase가 핵심 기록이다.
4. `리턴 샷`이 명확한 고위험·고보상 선택이다.
5. PB pace ghost가 매 run의 가까운 목표를 만든다.

그래픽·파티클은 이 조건을 대체하지 못한다.

## 8. Product Harness 검증 계획

### Phase A — 2일 deterministic collision spike

- SpriteKit은 렌더러로만 사용한다.
- 순수 Swift 120Hz fixed-tick 시뮬레이션과 swept collision으로 공·패들·구조물 판정을 만든다.
- 같은 seed와 입력 replay는 60/120Hz에서 같은 checksum과 점수를 내야 한다.
- 10,000개 seed에서 관통, 중복 파괴 점수, 화면 밖 불공정 spawn이 0건이어야 한다.

통과 조건:

- tunneling 0건, duplicate score 0건
- 평균 59fps 이상 목표, p95 frame 16.7ms 이하 목표
- deterministic replay checksum 일치

### Phase B — 5일 광고 없는 graybox

- A: 한 번 발사 후 자동 진행
- B: 공이 움직이는 동안 active paddle 조작
- 같은 seed를 사용해 B의 증분 가치를 검증한다.
- 한국 iPhone 캐주얼 사용자 5명에게 같은 seed를 3회씩 플레이하게 한다.

합격 조건:

- 5명 중 4명 이상이 5초 안에 첫 공을 받아치고 `받아쳐 위를 부순다`고 설명
- 첫 30초 active-touch 중앙값 60% 이상
- 첫 60초 의미 입력 분당 20~40회
- 5명 중 4명 이상이 `약점을 노리면 연쇄 파괴된다`고 이해
- Run 3의 score 또는 height 중앙값이 Run 1보다 20% 이상 상승
- 재미 중앙값 4/7 이상, 조작 만족도 5/7 이상
- 5명 중 3명 이상 자발적 즉시 재시도
- B가 A보다 재미 또는 자발적 3회차를 개선

## 9. Stop Conditions

다음 중 하나라도 발생하면 그래픽 제작을 늘리지 않고 중단 또는 재설계한다.

- 5초 첫 리턴 성공이 4/5 미만
- active-touch 중앙값 60% 미만 또는 의미 입력이 분당 20회 미만
- Run 3 기록이 Run 1보다 20% 이상 개선되지 않음
- 2명 이상이 반사각을 랜덤으로 느낀다고 응답
- 공 관통·offscreen spawn·파티클 가림에 의한 실패 1건
- 중앙 안전 리턴 또는 극단 왕복만 반복하는 단일 최적 전략 발견
- 3/5 이상이 세 번 플레이한 뒤에도 `그냥 벽돌깨기`라고만 설명
- 지지점 조준이 일반 타격보다 점수·높이에 유의미한 이점이 없음
- 10분 안에 구조물 6종이 반복적으로 느껴짐
- 손가락 피로 2/5 이상 또는 멀미·광과민 중단 1명 이상
- deterministic collision을 2일 안에 만들지 못함
- 지원 하한 기기에서 30fps hard floor 또는 발열 기준 실패

## 10. 수익화와 출시 판단

- no-ad D1/D7이 검증되기 전에는 광고·IAP를 붙이지 않는다.
- 무료 즉시 재시도는 항상 기본이다.
- 후속 후보는 공·패들·꼬리·구조물 cosmetic과 1회성 No Ads다.
- 점수·높이 leaderboard에 유료 booster, 유료 각도 보정, 광고 부활 기록을 섞지 않는다.
- 친구 설치·가입을 요구하는 보상은 계속 제외한다.
- 한국 무료 1위는 retained installs, 한국 CPI, organic multiplier, D90 contribution LTV와 필요한 일간 설치량을 실제 코호트로 확인하기 전까지 `Fail·Unknown`이다.

## 11. 에이전트 충돌과 Orchestrator 결정

- Strategy/Market은 물리 파괴의 획득 가능성을 지지했지만 현재 한국 매출 상위 근거가 없음을 경고했다.
- Game Design/UX는 continuous paddle, 약점 연쇄붕괴, PB ghost가 기존 게임의 입력·숙련·기록 문제를 직접 해결한다고 판단했다.
- Engineering/QA는 동적 SpriteKit 물리 대신 deterministic analytic collision을 권고했고 2일 spike 실패 시 즉시 중단하도록 했다.
- Red Team은 이 게임이 Breakout 계보임을 명시하고, 사용자가 차별 요소를 실제 행동으로 쓰지 않으면 복제품으로 판정하도록 했다.
- Product Orchestrator는 **완성 제작이 아니라 2일 spike와 5일 graybox만 승인**한다. 실제 사용자 증거 없이 그래픽 제작·광고·출시로 진행하지 않는다.

## 12. 아직 모르는 것

- 파괴 피드백이 10분 뒤에도 신선한가.
- active paddle가 자동 진행보다 실제로 더 재미있고 덜 피곤한가.
- 한국 사용자가 고전 벽돌깨기가 아니라 새 기록형 게임으로 인지하는가.
- D1/D7, CPI, LTV와 한국 무료 1위에 필요한 설치 velocity.
- 3D toy diorama가 2D graybox 대비 전환·재방문을 올리는가.

이 항목은 주장으로 채우지 않고 순차 실험으로만 해소한다.
