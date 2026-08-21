# 04. Effects Catalog

## 1. 공통 구조

각 효과는 아래 여섯 층으로 정의한다.

1. Gameplay: 실제 규칙
2. Core: 공 중심 또는 발사체의 핵심 형태
3. Trail: 이동 방향과 지속성
4. Impact: 접촉 순간의 형태
5. Residue: 잔열, 균열, 전기 잔류 등
6. Audio: 효과의 시간 리듬

## 2. Fire

### Gameplay

- 타격한 벽돌에 Burn을 부여한다.
- 기본 3 ticks, 260ms 간격.
- 같은 벽돌에 재적용 시 남은 지속시간을 갱신하고 최대 3 stack.
- Burn으로 파괴된 벽돌도 콤보를 유지한다.

### Visual

- Core: 백열 중심 + 주황 shell
- Trail: 위로 말리는 불꽃 혀, 작은 ember
- Impact: 접촉면을 따라 퍼지는 부채꼴 화염
- Residue: 벽돌 균열 내부의 주황 발광

### Readability cue

삼각형에 가까운 불꽃 아이콘과 상승하는 입자.

### Performance fallback

트레일을 ribbon 대신 6–10개의 pooled sprite로 축소한다.

## 3. Electric

### Gameplay

- 타격 후 가장 가까운 유효 벽돌 최대 3개에 연쇄 피해.
- 체인 거리 기본 210px.
- 같은 벽돌 중복 타격 금지.
- Conductor 벽돌은 체인 수 +1 또는 거리 +25%.

### Visual

- Core: 흰색 중심과 파란 corona
- Trail: 짧은 지그재그 스파크
- Impact: 2–4갈래 방전
- Chain: 직선이 아니라 중간 노드가 흔들리는 segmented bolt

### Readability cue

지그재그 번개 문양, 40–80ms 단위의 순간 점등.

### Safety

Photosensitivity Safe Mode에서는 밝기 점멸을 줄이고 볼트 형태 이동으로 전달한다.

## 4. Piercing

### Gameplay

- 지정 횟수만큼 벽돌과 충돌해도 반사하지 않는다.
- 기본 4 pierce charges.
- 보스 실드 또는 indestructible 오브젝트에는 반사.
- 각 관통 후 피해량은 기본 8% 감소, 최소 70%.

### Visual

- Core: 길게 압축된 밝은 창끝
- Trail: 직선형 초록 절단선
- Impact: 얇은 X자 slash와 뒤쪽 파편
- Residue: 벽돌 중앙을 가르는 발광 절단 흔적

### Readability cue

진행 방향과 같은 축의 뾰족한 실루엣.

## 5. Explosion

### Gameplay

- 충돌점 반경 155px에 방사 피해.
- 중심 100%, 가장자리 35%로 감쇠.
- 폭발로 폭발 벽돌이 파괴되어도 1회만 추가 연쇄 가능.
- 프레임 폭주를 막기 위해 한 프레임 최대 연쇄 24개.

### Visual

- Core: orange-red hot core
- Impact: 빠른 백색 코어 → 주황 링 → 적색 파편
- Shockwave: 140–220ms 원형 확장
- Screen: 짧은 로컬 왜곡 또는 줌 펀치

### Readability cue

방사형 별과 원형 충격파.

## 6. Multi Ball

### Gameplay

- 현재 공의 방향을 기준으로 ±18도에 2개 복제.
- 기본 최대 활성 공 8개.
- 복제 공은 현재 element와 trajectory 효과를 상속하되 남은 지속시간 70%.
- 동일 프레임 점수 팝업은 그룹 처리.

### Visual

- Core: 보라색 복제 링
- Spawn: 원본 주변 궤도 80ms 후 분리
- Trail: 각 공에 짧은 위상 잔상

### Readability cue

겹치는 세 원 아이콘.

## 7. Ice / Freeze

### Gameplay

- 타격한 벽돌에 Brittle 2.2초 부여.
- Brittle 상태의 다음 직접 타격은 1.6× 피해 후 상태 해제.
- 이동형 장애물과 보스 부품은 이동 속도 35% 감소.
- 공 자체를 느리게 하는 효과와 혼동하지 않는다.

### Visual

- Core: 푸른 백색 결정 shell
- Trail: 작은 육각 결정과 서리
- Impact: 접촉점에서 자라는 결정 가지
- Residue: 표면 서리와 균열

### Readability cue

육각 눈 결정 문양과 각진 파편.

## 8. Homing

### Gameplay

- 공이 매 프레임 가장 가까운 유효 벽돌로 즉시 꺾이지 않고 제한된 각속도로 회전한다.
- 권장 turn rate: 80–120°/s.
- 패들에서 출발한 직후 180ms grace period.
- 목표가 없으면 기존 궤적 유지.

### Visual

- Trail: 목표 방향으로 휘는 보라 곡선
- Target: 선택된 벽돌에 얇은 reticle
- Impact: 나선형 수렴

### Readability cue

곡선 화살표와 타깃 링.

## 9. Laser

### Gameplay

- 패들이 240ms 간격으로 레이저를 발사.
- 기본 지속시간 8초.
- 보스에는 별도 피해 계수 적용.
- 공 충돌과 레이저 피해의 점수 소스를 구분한다.

### Visual

- Charge: 패들 포트의 80ms 밝기 상승
- Beam: 밝은 중심 2–4px + 붉은 외곽 glow
- Impact: 작은 수직 spark shower

### Readability cue

가늘고 완전히 직선인 수직 광선.

## 10. Shield

### Gameplay

- 바닥에 1회 공을 반사하는 에너지 장벽 생성.
- 기본 2 charges.
- 반사 시 공 속도 92%로 완화하고 최소 수직 성분 보정.

### Visual

- Idle: 화면 하단 얇은 육각망
- Trigger: 충돌 지점에서 돔 리플
- Charge count: HUD와 장벽 양끝 노드로 표시

### Readability cue

육각 방패 문양.

## 11. Slow Time

### Gameplay

- 전체 게임 time scale을 0.62로 4.5초 적용.
- UI, 입력, 일부 VFX lifetime은 unscaled time 사용.
- 중첩 획득 시 duration 갱신, 배율 추가 감소 없음.

### Visual

- 화면 가장자리 보라 시간 링
- 공 뒤에 간격이 넓은 afterimage
- 배경 입자는 느려지되 HUD는 정상 속도

### Readability cue

끊어진 시계 링과 일정 간격 잔상.

## 12. 효과 조합

### 좋은 조합

- Fire + Piercing: 여러 벽돌에 burn을 빠르게 배포
- Electric + Multi Ball: 분산 체인, 단 체인 시각 상한 필요
- Ice + Homing: brittle 목표를 의도적으로 추적
- Explosion + Slow Time: 큰 연쇄를 읽기 쉽게 연출

### 제한이 필요한 조합

- Electric + Multi Ball + Explosion: 동시 파티클 상한과 점수 그룹화 필수
- Piercing + Homing: 궤적 변경이 과해지지 않도록 homing turn rate 70% 적용
- Laser + Multi Ball: UI 점수 피드백이 과밀해지므로 laser 숫자 합산

## 13. 시각 예산

동시 발생 시 다음 상한을 적용한다.

| 항목 | Normal | Low FX |
|---|---:|---:|
| 활성 공 | 8 | 5 |
| 일반 파티클 | 420 | 180 |
| 큰 폭발 링 | 6 | 3 |
| 전기 체인 세그먼트 | 48 | 24 |
| 데미지 텍스트 | 18 | 8 |
| 화면 전체 post effect | 2 | 1 |
