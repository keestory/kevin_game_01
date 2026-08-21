# 05. UI Components

## 1. HUD 기본 배치

모바일 세로형 기준:

- 상단 좌측: Pause, Stage
- 상단 중앙: Score, Combo
- 상단 우측: Life 또는 Boss HP
- 좌측 세로 레일: 일시정지되지 않는 패시브/상태
- 우측 세로 레일: 활성 파워업과 남은 시간
- 하단: 패들 주변 최소 UI, 터치 영역 방해 금지

보스 스테이지에서는 상단 중앙 점수 영역을 축소하고 Boss HP를 가장 높은 계층으로 올린다.

## 2. Button

### Variants

- Primary: 다음 진행, 시작
- Secondary: 설정, 상세
- Element: 스킬 선택
- Danger: 포기, 초기화
- Ghost: HUD 보조 액션

### States

- Idle
- Hover/Focus
- Pressed
- Disabled
- Loading

Pressed는 색만 진해지는 것이 아니라 `scale 0.97`, 내부 하이라이트 감소, 60ms 응답을 사용한다.

## 3. Panel

패널은 어두운 반투명 표면과 얇은 경계로 구성한다.

- Header
- Body
- Optional footer
- Optional status rail

전투 중 모달은 가능한 한 사용하지 않는다. 일시정지 또는 보상 선택처럼 게임 시간을 멈출 수 있는 경우에만 허용한다.

## 4. Badge

- Multiplier: `×2`, `×3`
- Element: 속성 아이콘
- Status: shield charge, burn stack
- Rarity: common, rare, epic, legendary

배지는 20–32px 높이로 유지하고 작은 크기에서 텍스트보다 아이콘을 우선한다.

## 5. Counter

- Score
- Currency
- Life
- Combo
- Charge

숫자 변화는 자리별 롤링보다 짧은 scale pulse를 기본으로 한다. 빠른 점수 누적에서는 100–180ms 단위로 묶어 업데이트한다.

## 6. Power-up Slot

필수 요소:

- 아이콘
- 속성 문양
- 남은 시간 또는 charge
- 활성/비활성 상태
- 교체 예정 표시

남은 시간은 원형 게이지 또는 하단 바를 사용한다. 숫자만 제공하지 않는다.

## 7. Brick Component

상태:

- Normal
- Hovered in editor/debug
- Hit
- Damaged
- Status applied
- About to explode
- Destroyed

`Hit` 상태는 80ms 이내, `Damaged`는 지속 상태다. 두 상태를 혼동하지 않는다.

## 8. Combo Banner

- 5: 작은 텍스트
- 10: `COMBO ×10` + 짧은 pulse
- 20: 색상 단계 변화
- 50: Frenzy 배너, 800ms 후 축소 HUD로 이동

배너가 공의 현재 위치를 가리지 않도록 화면 중앙이 아닌 상단 35% 부근에서 출현한다.

## 9. Critical Feedback

크리티컬 문구는 속성별로 색상을 바꾸되 형태는 일관되게 유지한다.

- 12° 기울기
- 1–2px 어두운 외곽선
- 짧은 속도선
- 350ms 이내 제거

동시 3개 이상이면 하나의 `CHAIN CRITICAL ×N`으로 합친다.

## 10. Pause Screen

필수:

- Resume
- Restart
- Settings
- Quit
- 현재 활성 파워업 요약

배경은 정지된 게임 화면을 40–55% 어둡게 하고 강한 blur는 모바일 성능 때문에 선택적으로 사용한다.

## 11. Settings

### Gameplay

- Aim assist
- Haptics
- Screen shake

### Accessibility

- Reduce Motion
- Photosensitivity Safe Mode
- Color Assist
- High Contrast Ball
- Damage Number Aggregation

### Performance

- Effects: High / Medium / Low
- 60 FPS / 30 FPS cap
- Background motion on/off

## 12. 반응형 규칙

- 9:16: 전체 HUD
- 19.5:9: 상단 safe area 반영
- 4:3: 좌우 패널 여백 증가
- Desktop landscape: 플레이 필드를 중앙에 유지하고 좌우에 상태/디버그 패널 배치
- HUD 터치 타깃 최소 44 CSS px
