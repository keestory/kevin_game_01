# Accessibility Checklist & Current Audit

> 상태: DRAFT / 2026-08-09 코드·화면 구조 감사
> 목표: WCAG 2.2 AA와 Apple 플랫폼 접근성 지침
> 실기기 보조기술 테스트 전 App Store 접근성 지원을 선언하지 않는다.

참고 1차 자료:

- [Apple Accessibility HIG](https://developer.apple.com/design/human-interface-guidelines/accessibility)
- [Apple VoiceOver HIG](https://developer.apple.com/design/human-interface-guidelines/voiceover)
- [Apple Motion HIG](https://developer.apple.com/design/human-interface-guidelines/motion)
- [Apple Designing for Games](https://developer.apple.com/design/human-interface-guidelines/designing-for-games)
- [Reduced Motion evaluation criteria](https://developer.apple.com/help/app-store-connect/manage-app-accessibility/reduced-motion-evaluation-criteria)

## 1. 현황 요약

| 영역 | 상태 | 근거 / 조치 | 심각도 |
|---|---|---|---:|
| 색 이외 구분 | Partial Pass | 색+원·세모·별·네모 사용; 실제 색각 테스트 없음 | P1 |
| VoiceOver 메뉴 | Partial | 일부 버튼 레이블 존재 | P1 |
| VoiceOver 코어 플레이 | Fail | SpriteView가 단일 보드 레이블이며 현재 열·승객 상태와 대체 열 선택이 없음 | P1 |
| Voice Control | Not tested | 식별 가능한 버튼은 일부 있으나 게임 탭 대체 없음 | P1 |
| Switch Control | Not tested | 선택기 타이밍과 직접 터치 의존 | P1 |
| Larger Text | Untested | HUD 최소는 11pt로 조정됐으나 고정 크기와 최대 접근성 크기 재배치 미검증 | P1 |
| 컨트롤 크기 | Pass for audited control | 일시정지 44×44pt 확인; 전체 화면 실기기 감사 필요 | — |
| 충분한 대비 | Not measured | 반투명 material과 낮은 opacity 텍스트 다수 | P1 |
| Reduce Motion | Fail/Partial | SwiftUI 전환 일부만 반영; SpriteKit 배경·선택기·입자 계속 움직임 | P1 |
| 오디오 대체 | Partial | 시각·햅틱 피드백 존재; 실제 오디오 미구현 | P2 |
| 햅틱 제어 | Pass | 설정으로 끌 수 있음 | — |
| 효과음 제어 | Not applicable | 효과음 미구현이며 현재 UI에서 무동작 토글을 제거함 | — |
| 단순 제스처 | Pass | 코어 입력은 단일 탭 | — |
| 시간 압박 대체 | Fail | 접근성용 스캔/감속 입력 방식 없음 | P1 |
| 깜박임/광과민 | Not measured | 입자 빈도와 명도 변화 측정 필요 | P1 |
| 방향·안전 영역 | Partial | Portrait 고정, 실기기 safe area 매트릭스 없음 | P2 |
| 오류 이해 | Partial | 구조 오류 문구 존재, 실제 테스트 없음 | P1 |

## 2. Vision

### [ ] VoiceOver 핵심 과업

통과 조건:

- 홈, 튜토리얼, 설정, 구조, 결과의 읽기 순서가 자연스럽다.
- 보드가 현재 선택 열, 다음 승객, 각 열 높이, 남은 손잡이를 의미 있는 빈도로 알린다.
- 사용자가 화면을 볼 수 없어도 열을 선택하고 배치할 대체 입력이 있다.
- 점수 변화가 매 프레임 읽혀 음성 큐를 방해하지 않는다.
- 매치·위험·종료 변화에 적절한 accessibility notification을 보낸다.

현재 상태: **Fail.** 보드 전체 레이블과 힌트만 존재하며 코어 조작 동등성을 제공하지 않는다.

검증 후보:

1. 다섯 열을 명시적 접근성 버튼으로 노출.
2. 자동 이동 대신 VoiceOver/스위치용 단계 선택 모드.
3. 다음 승객과 열 높이를 custom action/rotor로 제공.

실제 사용자와 테스트하기 전 하나를 채택하지 않는다.

### [ ] Larger Text

- SwiftUI 텍스트는 semantic style과 Dynamic Type을 사용한다.
- SpriteKit HUD는 Dynamic Type 변화에 맞춰 재배치하거나 접근성 HUD를 별도 제공한다.
- 최대 접근성 크기에서 홈·튜토리얼·구조·결과를 스크롤할 수 있다.
- 텍스트가 CTA나 점수를 가리지 않는다.
- 게임 필수 HUD 최소는 현재 11pt다. 가능한 본문 17pt와 최대 접근성 크기 재배치를 검증한다.

현재 상태: **Not tested.** 9pt HUD는 11pt로 수정됐지만 고정 크기와 최대 Larger Text 동작은 검증되지 않았다.

### [ ] Contrast & Differentiate Without Color

- 모든 텍스트·아이콘 조합을 실제 캡처로 측정한다.
- 낮은 opacity의 흰색 텍스트와 material 배경을 화면별 검사한다.
- 목적지는 도형+색으로 구분한다.
- 선택 열은 색뿐 아니라 굵은 외곽선/화살표/열 번호로 구분한다.
- 성공·위험은 문구와 아이콘을 병기한다.

현재 상태: 도형 병기는 긍정적이나 대비는 **Not measured**.

## 3. Mobility

### [ ] Touch Targets

- 기본 목표 44×44pt 이상.
- 일시정지 버튼은 현재 44pt로 조정됐다.
- 버튼 간 오탭 방지 여백을 확인한다.
- 화면 아무 곳 탭은 단순하지만 손 떨림·반복 탭 피로를 관찰한다.

### [ ] Voice Control / Switch Control

- 모든 버튼에 명확하고 고유한 레이블을 제공한다.
- 게임의 임의 화면 탭 외에도 열 선택을 직접 수행할 접근성 요소를 제공한다.
- 포커스 이동 중 게임 시간이 흐르지 않는 모드를 검토한다.
- Switch Control 스캔 속도에서 선택기 이동을 따라갈 수 있는지 실기기 테스트한다.

현재 상태: **Not tested / core flow likely Fail**.

## 4. Motion

Reduce Motion 활성 시:

- 배경 창문 불빛의 무한 이동을 중지한다.
- 매치 입자 폭발을 제거한다.
- scale/spring 전환을 crossfade 또는 즉시 갱신으로 바꾼다.
- 선택기의 지속 좌우 이동은 코어 규칙이므로, 감속 또는 직접 열 선택이라는 대체 방식을 연구한다.
- 중요한 상태를 모션만으로 전달하지 않는다.

현재 상태: **Fail.** SwiftUI overlay animation 일부만 비활성화되며 SpriteKit 모션은 유지된다.

## 5. Hearing

- 성공·위험·종료를 소리만으로 전달하지 않는다.
- 향후 효과음에는 시각·햅틱 대체를 유지한다.
- 효과음을 도입할 때 햅틱과 독립적으로 제어한다.
- 오디오가 없는 현재 빌드에서는 효과음 토글을 노출하지 않는다.

현재 상태: 시각·햅틱 피드백과 햅틱 토글이 있으며 효과음 토글은 제거됐다. 향후 오디오 도입 시 다시 감사한다.

## 6. Cognitive & Timing

- 첫 화면의 새로운 개념은 최대 3개로 제한한다.
- 선택기 속도 변화는 갑작스럽지 않고 예고 가능해야 한다.
- 실패 원인 열을 강조하고 다음 행동을 한 문장으로 설명한다.
- 광고 구조 혜택을 숫자로 명시한다.
- 혼잡 완화는 낙인 없이 변경점을 공개한다.
- 시간 제한 없이 규칙을 연습하는 모드 또는 첫 스테이지 정지형 안내를 테스트한다.

현재 정적 튜토리얼은 인지 부담과 실제 행동 전이를 검증하지 않았다.

## 7. Seizure / Flashing

- 3Hz 이상 깜박임이 있는지 60fps 녹화로 검사한다.
- 입자, glow, 흰색 flash의 면적과 빈도를 측정한다.
- 광과민성 경고가 필요한 효과는 기본적으로 제거한다.

현재 상태: **Not measured**.

## 8. Device Test Matrix

최소 조합:

| 기기/설정 | 점검 |
|---|---|
| 작은 iPhone + 기본 텍스트 | 레이아웃·터치 |
| 19.5:9 iPhone + 기본 텍스트 | safe area·보드 비율 |
| 최대 Larger Text | 잘림·스크롤·CTA |
| VoiceOver | 전체 핵심 흐름 |
| Voice Control | 버튼·게임 입력 |
| Switch Control | 포커스·시간 압박 |
| Reduce Motion | SpriteKit 포함 모션 |
| Increase Contrast/Reduce Transparency | glass card·HUD |
| 색각 필터 3종 | 목적지 판독 |
| 소리/햅틱 각각 Off | 대체 피드백 |

## 9. Gate

**Accessibility Gate: FAIL.** VoiceOver 코어 플레이, Larger Text, Reduce Motion, 대비와 보조기술 실사용에서 열린 P1이 있다. 감사한 일시정지 컨트롤 크기와 HUD 최소 글자 크기는 해소됐다. 접근성 지원 라벨은 실기기 테스트 후에만 선언한다.
