# Return Shot 접근성 체크리스트

> 기준일: 2026-08-18 KST / 상태: PARTIAL
>
> 목표: WCAG 2.2 AA와 Apple 게임 접근성 지침. 실기기 보조기술 테스트 전 App Store 접근성 지원을 선언하지 않는다.

## 현재 감사

| 영역 | 상태 | 현재 근거 / 다음 조치 |
|---|---|---|
| 색 이외 구분 | Pass for visual MVP | 벽돌마다 색+무늬+마크+형태, 프리즘 HP pip, 마이너스 큰 `−`, 스킬 문자 glyph·종류 아이콘·L1~L3, armor plate |
| VoiceOver 메뉴 | Partial | 주요 버튼 label·identifier 있음; 읽기 순서 실사용 필요 |
| VoiceOver 코어 | Partial P1 | SpriteView가 점수·높이·콤보·LINK·4종 스킬 레벨·관통 charge·armor를 읽고 adjustable/custom action으로 패들을 48pt씩 이동; 시간 압박 속 실사용 미검증 |
| Voice/Switch Control | P1 | 핵심 흐름 실기기 미검증 |
| Dynamic Type | P1 | SwiftUI semantic style 다수; 최대 접근성 크기 home/game/result 미검증 |
| 터치 크기 | Pass for audited controls | pause·primary·home share 44pt 이상 |
| 대비 | Partial P1 | A 화면은 육안 Pass, 결과 통계 보조 텍스트 68%로 수정; 정량 대비 측정 필요 |
| Reduce Motion | Partial P1 | 배경 drift·trail·비필수 effect 제거, SwiftUI 전환 축소; 실기기 확인 필요 |
| 오디오 대체 | Pass for current build | 필수 상태는 시각·텍스트·햅틱으로 전달, 오디오 없음 |
| 햅틱 제어 | Pass | 설정에서 독립 OFF |
| 반응형 | Pass for tested phones | 17 Pro·17e game, SE home/game/result와 재도전 CTA 첫 화면 노출 확인 |

## VoiceOver 핵심 과업

- [ ] 홈→게임→일시정지→재개→결과→재도전 읽기 순서가 자연스럽다.
- [ ] SpriteView의 접근성 값이 매 프레임 음성을 끊지 않는다.
- [ ] adjustable increment/decrement와 named custom action으로 패들을 좌우 이동한다.
- [ ] 공 miss, LINK 5, 공명 폭주, 마이너스 penalty를 필요한 빈도로 알린다.
- [ ] 코어 획득·레벨업, 관통 잔여 charge, 새 armor 구조를 필요한 빈도로 알린다.
- [ ] 시각장애 사용자와 시간 압박·연속 반사 동등성을 검증한다.

현재 코드는 대체 입력 경로를 제공하지만 실제 VoiceOver 사용성은 **미검증**이다.

## Dynamic Type와 대비

- [ ] 최대 접근성 크기에서 홈·결과는 스크롤되고 primary CTA가 잘리지 않는다.
- [ ] HUD 핵심 숫자와 pause가 겹치지 않는다.
- [ ] Increase Contrast에서 HUD·coachmark·결과 통계가 구분된다.
- [ ] 핵심 텍스트 4.5:1, 큰 텍스트·필수 그래픽 3:1을 실제 캡처로 측정한다.
- [x] 결과 통계 제목 opacity를 45%에서 68%로 높였다.
- [x] 홈 기록 공유 touch target을 최소 44pt로 보장했다.

## Motion과 인지

- [x] Reduce Motion에서 background drift, trail, 비필수 particle을 제거한다.
- [x] HUD·판정·마이너스 위험을 motion이나 색 하나로만 전달하지 않는다.
- [ ] 광과민 위험을 위해 flash 빈도·면적을 실기기 영상으로 측정한다.
- [ ] 첫 5초 coachmark를 실제 5명에게 보여 정보량과 이해를 검증한다.

## Gate

접근성 Gate는 현재 **Revise**다. VoiceOver·최대 Dynamic Type·Increase Contrast·Switch Control·Reduce Motion 실기기 흐름을 통과하기 전 Release Gate에 진입하지 않는다.
