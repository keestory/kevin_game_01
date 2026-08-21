# Phase 0 — Design System Gallery & Effect Lab

## 목표

실제 게임을 크게 만들기 전에 디자인 토큰과 모든 효과를 독립적으로 검증한다.

## 구현 범위

### Design System Gallery

- 컬러 팔레트
- 타이포그래피 스케일
- 버튼 5 variants × 주요 states
- 패널, 배지, 카운터, 타이머
- 벽돌 종류와 내구도 단계
- 공과 패들 variants
- HUD 3종: normal, combo-heavy, boss
- 속성 아이콘과 문양

### Effect Lab

효과별 카드에 다음 컨트롤을 제공한다.

- Play once
- Loop
- Intensity 0–100
- Particle count
- Speed
- Background 밝기
- Reduce Motion
- Photosensitivity Safe
- Color Assist

각 효과는 접촉 전, impact, residue를 모두 보여준다.

### Stress Test

- 공 1/3/5/8개
- 벽돌 40/80/140개
- 복합 효과 presets
- particle cap 표시
- FPS, frame time, pool usage 표시

## 완료 조건

- 외부 이미지 에셋 없이 실행 가능
- 토큰 변경 시 Gallery와 Effect Lab이 함께 갱신
- 모든 효과가 색 외에 형태로 구분
- 390×844와 1440×900에서 UI 겹침 없음
- 접근성 토글이 즉시 반영
- 최소 5개 테스트 통과
