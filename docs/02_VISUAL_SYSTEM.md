# 02. Visual System

## 1. 컬러 구조

실제 값은 `tokens/design-tokens.json`을 사용한다.

### Neutral

- Canvas: 거의 검은 네이비
- Surface 1: HUD와 패널
- Surface 2: 카드와 모달
- Border: 차가운 청회색
- Text Primary: 푸른 기가 거의 없는 흰색
- Text Secondary: 저채도 블루 그레이

### Element

| 속성 | 주색 | 보조색 | 모양 언어 |
|---|---|---|---|
| Fire | orange | warm yellow | 불꽃 혀, 잔불, 상승 곡선 |
| Electric | electric blue | white-blue | 지그재그, 분기, 순간 점멸 |
| Piercing | acid green | lime-white | 창끝, 직선, 절단선 |
| Explosion | red-orange | white-hot | 방사 링, 파편, 충격파 |
| Arcane/Multi | violet | magenta | 궤도, 복제 잔상, 구체 |
| Ice | cyan | pale blue | 육각 결정, 균열, 서리 |
| Laser | crimson | white | 가는 직선, 축적 후 발사 |
| Shield | cyan-blue | blue-white | 육각망, 돔, 리플 |
| Slow Time | purple | lavender | 시계 링, 잔상, 시간 왜곡 |

## 2. 표면과 경계

### Surface levels

- `surface.0`: 플레이 캔버스 배경
- `surface.1`: HUD의 반투명 바
- `surface.2`: 카드, 툴팁
- `surface.3`: 모달, 보상 패널

### Border

- 기본: 1px, 낮은 대비
- 활성: 속성 색 1px + 외부 글로우
- 선택: 2px + 내부 하이라이트
- 위험: 적색 펄스, 색만 쓰지 말고 삼각 경고 아이콘 병행

## 3. 반경

- 작은 배지: 6px
- 버튼/카드: 10px
- 큰 패널: 16px
- 공, 원형 게이지: 999px

벽돌은 기본 4px로 비교적 각지게 유지한다.

## 4. 타이포그래피

### 권장 글꼴

- Display: `Bebas Neue`, `Teko`, `Arial Narrow`, sans-serif
- UI/Body Korean: `Pretendard`, `Noto Sans KR`, system-ui, sans-serif
- Number: tabular 숫자를 지원하는 UI 폰트

### 스케일

| 토큰 | 용도 |
|---|---|
| display-xl | 게임 로고, 결과 화면 점수 |
| display-lg | 보스 경고, 대형 콤보 |
| title-lg | 화면 제목 |
| title-md | 카드·패널 제목 |
| body-md | 기본 설명 |
| label-sm | HUD 라벨 |
| micro | 개발자 오버레이 |

숫자 카운터에는 `font-variant-numeric: tabular-nums`를 적용한다.

## 5. 아이콘

아이콘은 24×24 그리드, 2px 스트로크를 기본으로 한다.

- Fire: 불꽃
- Electric: 번개
- Piercing: 화살촉/창
- Explosion: 방사형 별
- Multi: 겹치는 세 원
- Ice: 육각 눈 결정
- Homing: 타깃과 곡선 화살표
- Laser: 수직 광선
- Shield: 육각 방패
- Slow Time: 끊어진 시계 링

Color Assist 모드에서는 아이콘을 항상 공 옆 미니 배지와 HUD에 반복 표시한다.

## 6. 벽돌 시스템

### 벽돌 종류

- Normal: 1 hit
- Reinforced: 2–3 hit
- Armor: 특정 방향 또는 특정 속성만 유효
- Explosive: 파괴 시 인접 피해
- Conductor: 전기 체인을 확장
- Frozen: 다음 충돌 피해 증가
- Portal: 공 위치 또는 각도 변경
- Mystery: 파워업 드롭
- Boss Core: 다단계 상태

### 내구도 표현

색만 어둡게 하지 않는다.

1. 새 벽돌: 깨끗한 표면, 얕은 내부 하이라이트
2. 70%: 작은 모서리 균열
3. 40%: 중심 균열과 미세 파편
4. 10%: 밝은 균열 코어, 흔들림
5. 파괴: 조각 분리 후 페이드

## 7. 공 시스템

공은 세 레이어로 표현한다.

1. Core: 흰색 또는 매우 밝은 속성색
2. Shell: 금속/에너지 재질
3. Trail: 현재 속성과 속도 전달

공이 빠를수록 shell은 진행 방향으로 stretch되지만 core 크기는 크게 변하지 않아 추적 가능성을 유지한다.

## 8. 패들 시스템

패들은 단순 막대가 아니라 플레이어의 장비다.

- 중심 코어: 충돌 지점과 차지 상태
- 양 끝 캡: 폭과 업그레이드 상태
- 하부 스러스터: 빠른 이동 시 반대 방향 제트
- 스킬 슬롯: 레이저, 자석, 보호막 활성 상태

## 9. 배경

배경은 저주파 모션만 사용한다.

- 화면 중심과 플레이 필드 뒤의 대비를 유지한다.
- 고대비 별, 간판, 기계 불빛은 공보다 낮은 밝기로 제한한다.
- 보스 등장, Frenzy 등 특정 순간에만 반응 강도를 높인다.
