# 스킬 코어 시각 감사 — 2026-08-18

- 단계: Stage 6 Implementation
- 범위: 번개·화염·바람·관통 코어, L1~3 HUD, 구조 armor 0~2
- 기준 캡처: `docs/screenshots/return-shot-skill-core-game.png`
- 장치: iPhone 17 Pro Simulator, iOS 26.5, 402×874pt
- 추가 캡처: `docs/screenshots/return-shot-skill-core-se.png`, iPhone SE 3세대 375×667pt
- 판정: 초기 구조 402×874와 375×667 화면 `Pass`, 발동 최성기·실기기 접근성 `Pending P1`

## 발견과 수정

| 발견 | 수정 | 재확인 |
|---|---|---|
| 공격 발동 ring·중앙 문구가 공보다 높은 z에서 추적을 가릴 수 있음 | 공격 cue를 공 아래 z14에 두고 fill을 제거, 레벨 문구는 SwiftUI feedback pill로 이동 | Swift 6 build Pass, 코드 z-order 감사 Pass |
| 9pt 코어 glyph와 10×4 armor가 작고 우상단에서 겹칠 수 있음 | 코어 badge 24pt·glyph 11/14pt, armor 12×5pt를 좌상단에 배치 | 캡처와 코드 감사 Pass |
| HUD가 미획득 L0 네 종류를 항상 보여 소음 발생 | L1 이상만 표시, 관통은 `Lx ×charge`, result도 획득 종류만 표시 | UI hierarchy와 캡처 Pass |
| 네 공격이 색 하나에 의존 | 코어 glyph·SF Symbol·텍스트 이름을 유지하고, 발동 cue를 번개 bolt·화염 flame·바람 3중 곡선·관통 이중 화살촉으로 분리 | 코드 감사 Pass, 색각 필터 실기기 Pending |
| UI test가 `skillCoreHUD`를 잘못된 element type으로 조회 | 전용 `-skipTutorial` fixture와 실제 `StaticText` 접근성 계층으로 수정 | iPhone 17 Pro·SE XCUITest Pass |

## 화면 판단

- 시각 위계: SCORE·높이·콤보가 1차, feedback과 구조가 2차, 벽돌 속 24pt 코어 badge가 조준 대상으로 읽힌다.
- 간격: HUD와 feedback pill은 필드 상단 판정 영역을 침범하지 않고, 코어 badge와 좌상단 armor 위치를 분리했다.
- 대비·텍스트: 흰 glyph와 어두운 원형 badge를 기본으로 쓰며 색은 공격 종류의 보조 신호다.
- 모바일 조작: 새 버튼·모달·픽업 탭이 없고 기존 한 엄지 drag만 사용한다.
- 클릭 명확성·hover: 게임 필드는 연속 drag 표면이며 iPhone hover는 N/A다. pause와 주요 CTA는 44pt 이상이다.
- 자연스러운 흐름: carrier 직접 완파 → 자동 공격 → feedback pill 레벨 갱신 → 결과의 획득 스킬만 요약한다.

## 남은 P1

- 375×667 초기 구조는 Pass. armor 1/2, 프리즘 3HP, 획득 스킬 4종이 동시에 보이는 후반 상태 캡처는 Pending.
- 번개·화염·바람 L3와 관통 charge의 실제 발동 프레임·30fps 하한·공 비가림 영상 검사.
- Reduce Motion, 회색조/색상 필터, 최대 Dynamic Type, VoiceOver 실기기 흐름.
- 사용자 5명 중 4명이 코어 직접 파괴·레벨업·armor와 core HP 차이를 설명하는지 검증.

이 감사는 화면과 코드의 휴리스틱 QA이며 재미·retention·한국 무료 1위 가능성의 증거가 아니다.
