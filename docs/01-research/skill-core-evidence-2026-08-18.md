# Return Shot 스킬 코어 시장 검증

- 확인일: 2026-08-18 KST
- 국가/플랫폼: 대한민국 / iPhone Games, 보조 근거 Google Play 글로벌 누적
- 책임: Market & Store Intelligence, Strategy, Growth, Red Team, Product Orchestrator
- 판정: 4종 상시 중첩은 `Stop`, 1회 bounded 스킬 코어 vertical slice는 `Revise-Go`

## 관측 근거

| 출처 | 관측값 | 근거 유형과 한계 |
|---|---|---|
| [Apple 한국 iPhone 무료 Games](https://apps.apple.com/kr/iphone/charts/6014?chart=top-free) | `Royal Smash` #18, `Block Blast` #14 | 공식 순간 무료 차트. retention·매출 근거가 아님 |
| [Apple 한국 Games 매출 RSS](https://itunes.apple.com/kr/rss/topgrossingapplications/limit=25/genre=6014/json) | 2026-08-18 00:52 KST 갱신 Top 25에 직접 브릭·파괴작 없음 | 공식 순위지만 매출액은 미공개 |
| [Royal Smash — Google Play](https://play.google.com/store/apps/details?id=com.cyphergames.royalsmash) | 5M+ 누적 표시, 2026-08-16 갱신. 단순 파괴 훅과 다중 타격·물리·반복·광고 불만 공존 | 글로벌 Android 누적과 자기선택 리뷰이며 한국 iPhone 유지율이 아님 |
| [핀볼도사 — App Store KR](https://apps.apple.com/kr/app/%ED%95%80%EB%B3%BC%EB%8F%84%EC%82%AC/id1585781366), [Google Play](https://play.google.com/store/apps/details?id=com.habby.punball) | 벽돌깨기+run skill build의 직접 선행작, Google Play 5M+ 표시 | 네 속성이 새 시장 공백이라는 주장을 반박. 개별 D1/D7은 미확인 |
| [One More Brick — Google Play](https://play.google.com/store/apps/details?id=com.riftergames.onemorebrick) | 5M+ 표시, 작은 파워업 세트와 one-thumb endless | 제한된 파워업 vertical slice의 인접 지지 근거 |
| [Bricks Ball Crusher — Google Play](https://play.google.com/store/apps/details?id=com.iposedon.bricksbreakerballs) | 10M+ 표시, 200+ 스킬볼/블록·10,000+ 스테이지 | 기능 수가 장기 콘텐츠·QA·운영비를 크게 만든다는 반증 |

스토어 리뷰는 자발적·자기선택 표본이므로 불만 빈도나 retention을 계산하지 않는다. 다운로드 band는 글로벌 Android 누적이며 한국 iPhone 성과가 아니다.

## 통합 판단

- 관측: 단순 파괴 훅은 무료 차트 획득 후보지만 직접군의 한국 매출 Top 25 근거는 없다.
- 추론: 벽돌 안 코어는 기존 패들 입력을 늘리지 않고 조준 이유와 run별 빌드를 만들 수 있다.
- 반증: 네 공격을 동시에 지속시키고 HP를 계속 올리면 `PunBall` 축소판과 스펀지 난이도가 된다.
- 결정: 네 종류는 보존하되 구조당 코어 한 개, 직접 파괴 시 1회 bounded 공격, 공격별 Lv1~3, armor 0~2 cap만 검증한다.
- 금지: 강제광고, 유료 공격력, 광고 없이는 못 깨는 armor, 영구 stat wall.

## 검증과 Stop

- 5명 중 4명이 `표시 벽돌을 직접 깨면 공격이 성장·발동`한다고 설명해야 한다.
- active-touch 중앙값 60%와 Run 3 기록 개선을 baseline보다 악화시키면 안 된다.
- 일반 벽돌이 세 번을 초과해 맞아야 하거나 3초 이상 같은 목표를 반복하면 Stop한다.
- attack이 negative·LINK·다른 core를 한 번이라도 오판하면 Stop한다.
- 한국 무료 1위, D1/D7, CPI/LTV는 현재 `Fail / Unknown`이다.
