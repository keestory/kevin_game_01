# 03. Gameplay Feel

## 1. 기본 물리 목표

벽돌깨기의 재미는 예측 가능성과 통제 가능한 변주의 균형에서 나온다.

### 권장 시작값

| 항목 | 값 |
|---|---:|
| Logical field width | 1080 |
| Logical field height | 1920 |
| Paddle width | 220 |
| Paddle height | 36 |
| Ball diameter | 28 |
| Initial ball speed | 760 px/s |
| Soft speed cap | 1,420 px/s |
| Hard speed cap | 1,650 px/s |
| Paddle max speed | 1,900 px/s |
| Paddle acceleration | 8,000 px/s² |
| Paddle deceleration | 10,000 px/s² |
| Minimum vertical component | total speed의 0.30 |

고정 타임스텝 또는 delta clamp를 사용해 저프레임에서도 터널링과 각도 폭주를 방지한다.

## 2. 패들 반사

반사각은 충돌 위치와 패들 속도를 함께 반영한다.

```text
normalizedOffset = (ballX - paddleCenterX) / (paddleWidth / 2)
angleContribution = normalizedOffset × maxBounceAngle
velocityContribution = paddleVelocityX × influence
```

권장 최대 반사각은 수직 기준 ±65도다. 수평에 너무 가까운 각은 최소 수직 성분 규칙으로 보정한다.

## 3. 충돌 피드백 레벨

| 레벨 | 사례 | Hit stop | Shake | Flash |
|---|---|---:|---:|---:|
| L1 | 일반 벽돌 | 18–24ms | 1–2px | local only |
| L2 | 강화 벽돌 파괴 | 28–36ms | 2–4px | alpha 0.06 |
| L3 | 폭발/크리티컬 | 38–52ms | 4–7px | alpha 0.10 |
| L4 | 보스 코어 파괴 | 65–90ms | 8–12px | alpha 0.16 |

연속 타격에서는 120ms 윈도우 내 hit stop 누적 상한을 70ms로 둔다.

## 4. Squash & Stretch

### 공

- 충돌 직전: 진행 방향 1.08, 수직 0.94
- 충돌 프레임: 진행 방향 0.82, 수직 1.18
- 이탈 2프레임: 진행 방향 1.18, 수직 0.88
- 80–110ms 내 원형 복귀

### 패들

- 공을 받을 때 수직 0.88, 수평 1.05
- 강한 차지 샷은 140ms 동안 overshoot

## 5. 카메라

카메라 피드백은 위치 셰이크, 줌 펀치, 배경 반응을 분리한다.

- 일반 충돌: 위치 셰이크만
- 콤보 20 이상: 배경 미세 펄스
- 폭발/보스: 위치 + 1.01–1.03 줌 펀치
- Reduce Motion: 위치 셰이크 30%, 줌 제거

셰이크는 무작위 좌표보다 감쇠하는 impulse noise를 사용한다.

## 6. 콤보 시스템

### 증가

공이 바닥으로 떨어지지 않고 벽돌을 연속 파괴할 때 증가한다.

### 단계

| 콤보 | 상태 | 연출 |
|---:|---|---|
| 0–9 | Base | 기본 사운드와 임팩트 |
| 10–19 | Heat | 콤보 텍스트 색상 상승, 트레일 +10% |
| 20–49 | Overdrive | 배경 반응, 점수 링, 사운드 레이어 추가 |
| 50+ | Frenzy | 제한된 크로마 분리, 임팩트 +15%, 최대 가독성 상한 |

### 리셋

- 공을 모두 잃음
- 스테이지 전환
- 특정 보스 무적 패턴 진입 시 선택적 유지/동결

## 7. 데미지 숫자와 점수

- 일반 타격: 작은 숫자, 250ms
- 크리티컬: 속성색, 420ms, 약한 회전
- 체인/폭발: 개별 숫자는 합산 옵션 제공
- 5개 이상 동시 발생 시 그룹 합산으로 시야 보호

## 8. 사운드 리듬

속성별 기본 음색:

- Fire: 저중역 타격 + 잔불 crackle
- Electric: 짧은 고역 transient + chain pitch step
- Piercing: 금속성 slice
- Explosion: 저역 thump + 중역 debris
- Ice: 유리 결정 + 짧은 고역 shimmer
- Arcane/Multi: 위상감 있는 톤

콤보가 오르면 단순 볼륨이 아니라 pitch와 추가 레이어를 상승시킨다. 동일 샘플은 ±3% 피치와 2–4개 variation으로 반복감을 줄인다.

## 9. 입력 감각

- 터치: 패들이 손가락 아래를 즉시 따라가되 화면 가장자리에서 보정
- 드래그 dead zone: 2–4 logical px
- 키보드: 가속/감속 적용, 즉시 정지는 피함
- 마우스: 포인터 위치 직접 추적 + 최대 속도 제한
- 모바일 진동: 큰 폭발과 보스 파괴만, 설정에서 해제 가능
