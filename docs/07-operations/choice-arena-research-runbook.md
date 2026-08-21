# Choice Arena 10명 로컬 연구 Runbook

- 기준일: 2026-08-20 KST
- 단계: Stage 2 Problem Validation
- 소유: UX Research 진행, Data & Experimentation 판정, QA·Security DQ 확인
- 현재 Gate: 실행 도구 `Go`, 사용자 근거 `Revise`

이 Runbook은 제품 성과를 주장하기 위한 문서가 아니라 10명 방향성 연구를 오염 없이 실행하기 위한 절차다. 참가자 이름·연락처와 P01–P10 대응표는 앱·저장소 밖에 보관한다.

## 1. 시작 전 hard Gate

1. Debug build만 사용한다. Release와 일반 Debug에서는 연구 logger가 꺼져 있어야 한다.
2. `-descentResearchConsole`을 열고 DQ가 `정상`, 손상/future line/read 오류가 0인지 확인한다.
3. 이전 연구 데이터가 남아 있으면 먼저 CSV를 export하고 checksum/행 수를 기록한 뒤 확인형 전체 삭제를 수행한다. 삭제 전 백업 없는 제거는 금지한다.
4. P01–P10의 다음 배정이 계획과 일치하는지 확인한다. 잘못된 participant/order/variant 조합은 우회하지 않는다.
5. 참가자 내 두 variant는 같은 기체·seed·기기 class·접근성 조건을 사용한다.
6. 동의 범위, 로컬 저장, 최대 30일 보관, 삭제 예정일을 설명한다.

손상 원자료, 저장 실패 overlay, 상한 초과, 배정 오류가 하나라도 있으면 그 런은 시작하지 않는다.

## 2. 고정 배정

| 참가자 | 1차 | 2차 |
|---|---|---|
| P01–P05 | A no-Arena, order 1 | B Choice Arena, order 2 |
| P06–P10 | B Choice Arena, order 1 | A no-Arena, order 2 |

예시 launch arguments:

```text
# P01 1차 A
-descentResearch -descentVariantNoArena -descentParticipant P01 -descentOrderIndex 1

# P01 2차 B
-descentResearch -descentParticipant P01 -descentOrderIndex 2

# P06 1차 B
-descentResearch -descentParticipant P06 -descentOrderIndex 1

# P06 2차 A
-descentResearch -descentVariantNoArena -descentParticipant P06 -descentOrderIndex 2
```

## 3. 참가자별 진행

1. 별도 familiarization seed로 최대 20초 동안 `끌어서 이동하며 자동 발사됩니다`만 안내한다.
2. 참가자가 기체를 직접 고르게 하고 두 variant에서 같은 기체를 유지한다.
3. variant별 run 1과 run 2를 필수 수행한다. 입력·선택·전략을 지시하지 않는다.
4. run 2 결과 뒤 멘트는 `이제 자유롭게 해보셔도 됩니다`로 고정한다. `한 판 더 하세요`, `기록을 깨보세요`처럼 retry를 유도하지 않는다.
5. 60 active seconds 안에 참가자가 스스로 retry하고 같은 seed·ship의 run 3 terminal까지 끝낸 경우에만 자발적 3회차다.
6. 각 block 직후 fun·agency·annoyance 1–7, 선택 효과 자유 설명, prompt count, broad input mode를 facilitator CSV에 기록한다. 자유발화 전문이나 신원은 기록하지 않는다.

VoiceOver/Switch Control 또는 대체 입력은 현재 앱 event의 active-touch로 동일하게 계측되지 않는다. 해당 참가자의 task success는 보고하되 ActiveTouchRatio 비교에는 섞지 말고 `input_mode` 한계를 명시한다.

## 4. 런 사이 확인

- 시작된 run은 `finished` 또는 명시적 `abandoned` terminal 정확히 1개여야 한다.
- A에는 Choice event가 없어야 한다.
- B에서 Arena 도달 시 presented→selected가 각각 1개여야 한다.
- run 2에는 `optionalRetryWindowOpened(60000)`가 있어야 한다.
- variant 간 participant seed·ship이 같아야 한다.
- 저장 실패 안내가 나타나면 즉시 중단하고 해당 run을 invalid로 유지한다. 삭제 후 재실행으로 원자료를 숨기지 않는다.

## 5. Console 판정·export

1. `-descentResearchConsole`을 연다.
2. DQ가 정상인지 먼저 본다. DQ 오류가 있으면 Primary를 해석하지 않는다.
3. 필수 A/B 수집 완료와 다음 배정을 확인한다.
4. Primary 세 가지를 participant 10명 ITT로 확인한다.
   - B 자발적 3회차 완료 ≥6/10, A 대비 +2명 이상
   - B Run1→Run3 ComparableScore +20% ≥6/10, A 대비 +2명 이상
   - B 필수 run ActiveTouchRatio 중앙값 ≥60%, paired delta ≥-5%p
5. participant-variant summary CSV를 export하고 facilitator observation CSV와 participant slot으로만 결합한다.
6. 두 사람이 원자료 2개 세션을 독립 대조하고 차이 0을 확인한다.

## 6. Stop 및 삭제

- DQ 오류, carried-touch 오선택, 보조기술 선택 불능은 즉시 Stop 또는 실험 무효다.
- B의 자발적 3회차/R20/active-touch Gate가 실패하면 Arena를 유지했다고 결론 내리지 않는다.
- 원시 JSONL은 Gate 판정 뒤 최대 30일만 보관한다. export hash와 비식별 aggregate를 남긴 후 Console의 확인형 전체 삭제를 실행하고 파일 부재를 재확인한다.
- 공개 GitHub, 이메일, 메신저에 원시 JSONL이나 참가자 대응표를 올리지 않는다.

## 7. 완료 기록

- 실행일, 기기 class, 앱 commit SHA, rules version
- P01–P10 A/B 완료 수와 invalid 수
- JSONL byte/line 수, CSV SHA-256, 삭제 예정일과 삭제 확인일
- DQ violation, protocol deviation, moderator prompt
- Go / Revise / Stop 및 폐기한 해석
