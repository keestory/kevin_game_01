# 자산 출처 기록

확인일: 2026-08-09

## 앱 아이콘

- 파일: `AppStoreGame/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png`
- 제작 방식: OpenAI 이미지 생성 도구로 이 프로젝트를 위해 신규 생성
- 생성일: 2026-08-09
- 입력 요약: 짙은 남색 iOS 앱 아이콘, 노란 지하철 문, 민트색의 둥글고 웃는 승객, 단순한 기하학 장식, 텍스트 없음, 실제 교통기관 로고 없음
- 참조 이미지: 사용하지 않음
- 확인 사항: 제3자 로고·노선도·상표를 의도적으로 포함하지 않았으며, 실제 출시 전 소유자가 최종 상표·유사성 검토를 수행해야 함

이 기록은 제작 과정의 추적성을 위한 것이며 법률 의견이나 제3자 권리 비침해 보증이 아닙니다.

## 실제 열차 vertical slice 콘셉트

- 파일: `docs/04-design/concepts/real-train-vertical-slice-concept-v1.png`
- 제작 방식: OpenAI 내장 ImageGen으로 이 프로젝트 전용 신규 생성
- 생성일: 2026-08-09
- 입력 요약: 세로형 2.5D 장난감 디오라마 지하철, 3량, 미닫이문, 플랫폼, 사람 형태 승객, 정차·승하차 효과, 남색·노랑·민트 팔레트
- 참조 이미지: 사용하지 않음
- 사용 범위: 구현 방향·구도 참고용. 앱 런타임에는 포함하지 않으며 SpriteKit 코드로 독자 재구성함
- 권리 주의: 실제 교통기관 로고·고유 도색·노선도·상표를 의도적으로 제외했으며 출시 전 유사성 검토가 필요함

## 플랫폼 라우팅 디오라마 콘셉트 rev2

- 파일: `docs/04-design/concepts/platform-routing-diorama-concept-v2.png`
- 제작 방식: 프로젝트 오너가 제공한 방향성 이미지를 ImageGen의 시각 참고로 사용하되, 가상 도시·열차 외형·인물·목적지 문양·UI를 새로 생성
- 생성일: 2026-08-09
- 입력 요약: 세로형 야간 도시, 사선 원근의 가상 지하철, 네 개의 목적지 큐와 문, 실제 승하차 순간, 큰 좌우 레버
- 참조 이미지 사용 범위: 깊이·조작 명료성·toy-diorama 품질의 방향성만 참고. 제공 이미지는 저장소나 앱에 복사하지 않음
- 사용 범위: ProductSpec rev2의 시각 기준 및 오너 승인용. 앱 런타임에는 포함하지 않음
- 독자화 조치: 실제 랜드마크·철도 로고·도색·캐릭터·아이콘·문구를 제외하고 목적지와 도시를 가상화
- 권리 주의: 출시 전에 reference side-by-side similarity review와 최종 상표 검토가 필요함

## 분리형 2.5D 열차 제작 자산

- 런타임 파일: `AppStoreGame/Resources/Assets.xcassets/DioramaTrain.imageset/DioramaTrain.png`
- 원본 생성 파일: Codex ImageGen 세션 `exec-0d9d910d-2e67-45b6-a7c0-c335e70c752a.png`
- 제작 방식: 참조 이미지 없이, 네 개의 빈 문 개구부를 가진 독자적인 가상 도시철도 열차를 ImageGen으로 신규 생성
- 생성일: 2026-08-09
- 입력 요약: 전면과 측면이 보이는 indigo·ivory 3/4 열차, 네 개의 빈 문, 인물·로고·텍스트·실제 도색 없음
- 편집 이력: 단색 마젠타 배경으로 생성한 뒤 CoreGraphics chroma key로 투명화했으며, 문·승객·glow는 SpriteKit 별도 레이어로 구현
- SHA-256: `c522327db2cb106b526370c3d8bf38061bb180c37f4e8f6f6de1c200acbc68f4`
- 검사 상태: 1398×591, 실제 alpha 채널 확인, 런타임 포함 승인. 출시 전 독립 유사성·상표 검토는 남음

## 2.5D 통근 승객 시트

- 런타임 파일: `AppStoreGame/Resources/Assets.xcassets/CommuterSheet.imageset/CommuterSheet.png`
- 원본 생성 파일: Codex ImageGen 세션 `exec-f3e944a6-ef1e-4223-a10a-b92758e06dcc.png`
- 제작 방식: 참조 이미지 없이 서로 다른 연령·복장의 가상 통근 승객 8명을 ImageGen으로 신규 생성
- 생성일: 2026-08-09
- 입력 요약: 2.5D 장난감 디오라마 인물, 정면 전신, 로고·텍스트·실존 인물 없음, 마젠타 배경
- 편집 이력: CoreGraphics chroma key로 투명화하고 8칸 런타임 texture atlas로 사용
- SHA-256: `52971b37277394a36e4b8c629b8e3de75a5f1310ae176686a45f08b740b1ebf5`
- 검사 상태: 2172×724, 실제 alpha 채널 확인, 런타임 포함 승인. 출시 전 독립 유사성 검토는 남음

## 오너 승인 런타임 마스터 화면

- 런타임 파일: `AppStoreGame/Resources/Assets.xcassets/OwnerMasterScene.imageset/OwnerMasterScene.png`
- 제공 방식: 프로젝트 오너가 대화에 직접 첨부하고, 다른 재해석 대신 해당 디자인을 그대로 복제해 사용하라고 명시
- 제공·승인일: 2026-08-09
- 원본 SHA-256: `47de693c84bd4f10fa8d25e831bac0e16bb1d7ef6dcb035f56454cc0967dd8fe`
- 런타임 SHA-256: `c63b5679d044dc43e5a8d5a2a7771a00c8e6dc863926afa440ec0e13c4458ae4`
- 편집 이력: 원본 941×1672 픽셀은 재생성·리터치하지 않고 유지. iPhone 세로 안전영역 대응을 위해 `sips`로 위·아래에 동일한 `#061129` 패딩을 추가해 941×2046으로 확장
- 런타임 사용: SpriteKit 배경 마스터로 사용하고, 현재/목표/연속 정확/타이머, 문턱 승객, 결과·파티클, 중앙 버튼 hit target은 코드 레이어로 구현
- 권리 상태: prototype 사용은 오너의 명시적 요청으로 기록. 공개 상용 출시 전 오너의 원본 권리·상용 사용 권한 확인과 실제 철도·랜드마크·제3자 유사성 검토는 별도 Gate로 남김

## 코드 생성 사운드

- 파일 자산 없음. `GameAudioService`가 사인파를 합성해 출발·제동·문·성공·실패의 짧은 원본 효과음을 런타임에 생성함
- 실제 철도 안내음·차임·녹음은 사용하지 않음
