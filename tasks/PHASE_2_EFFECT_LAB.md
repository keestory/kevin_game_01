# Phase 2 — Full Effect Integration

## 목표

10개 효과를 실제 플레이에 통합하고 조합 규칙을 검증한다.

## 작업

- Fire burn handler
- Electric chain target resolver
- Piercing charge and no-bounce collision
- Explosion radial query
- Multi Ball spawn inheritance
- Ice brittle status
- Homing target selection and angular steering
- Laser paddle weapon
- Shield floor barrier
- Slow Time scaled/unscaled clock separation

## 조합 프리셋

- Inferno Drill: Fire + Piercing
- Storm Swarm: Electric + Multi Ball
- Frozen Hunter: Ice + Homing
- Time Bomb: Explosion + Slow Time

## 테스트

- 각 효과 단독
- 같은 슬롯 교체
- utility 중첩
- 프레임당 연쇄 상한
- 다중 공 상속 지속시간
- Slow Time 중 UI 타이머 정상
- Low FX에서도 판정 동일
