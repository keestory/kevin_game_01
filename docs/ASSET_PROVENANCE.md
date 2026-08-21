# 자산 출처 기록

확인일: 2026-08-09

## 앱 아이콘

- 파일: `AppStoreGame/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png`
- 제작 방식: OpenAI 이미지 생성 도구로 이 프로젝트를 위해 신규 생성
- 생성일: 2026-08-17
- 원본 생성 파일: Codex ImageGen 세션 `exec-2a491964-8abf-4457-997c-3f679a3908ac.png`
- 입력 요약: 짙은 남색 바탕, 민트색 패들과 반사하는 흰 공, 코랄 별·블루 삼각·앰버 프리즘 블록의 작은 연쇄 붕괴, 텍스트·숫자·캐릭터·열차·로고 없음
- 참조 이미지: 사용하지 않음
- 편집 이력: ImageGen 원본을 1024×1024 sRGB PNG로 리사이즈해 AppIcon 단일 원본으로 사용
- SHA-256: `389fc80389fc4b9065731c08348883b32badd920a4ff43fdb4994c8100326a03`
- 확인 사항: 제3자 로고·상표와 인접 게임의 대포·유리 복도 구도를 의도적으로 제외했으며, 실제 출시 전 소유자가 최종 상표·유사성 검토를 수행해야 함

이 기록은 제작 과정의 추적성을 위한 것이며 법률 의견이나 제3자 권리 비침해 보증이 아닙니다.

## Return Shot 런타임 배경

- 런타임 파일: `AppStoreGame/Resources/Assets.xcassets/ReturnShotBackdrop.imageset/ReturnShotBackdrop.png`
- 원본 생성 파일: Codex ImageGen 세션 `exec-226d5afe-e1ca-4b32-81e8-6834edd27c95.png`
- 제작 방식: 참조 이미지 없이 OpenAI 내장 ImageGen으로 이 프로젝트 전용 신규 생성
- 생성일: 2026-08-17
- 입력 요약: 세로형 어두운 kinetic laboratory shaft, 중앙 70% 저대비 여백, 가장자리 민트·앰버 조명, 무광 세라믹·종이 레이어, 게임 오브젝트·문구·로고 없음
- 사용 범위: 홈·게임·결과의 저대비 배경. 공·패들·벽돌·HUD·판정은 모두 코드 레이어이며 생성 이미지와 분리
- 독자화 조치: 대포·유리 복도·기차·캐릭터·브릭·상표·문구를 제외해 인접 파괴 게임의 대표 구도와 겹치지 않도록 함
- 검사 상태: 1024×1536, 중앙 플레이 가독성을 위한 저대비 자산으로 Vision 확인. 실제 출시 전 별도 유사성·권리 검토 필요

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

- 보존 파일: `docs/04-design/archive/train-assets/DioramaTrain.imageset/DioramaTrain.png`
- 원본 생성 파일: Codex ImageGen 세션 `exec-0d9d910d-2e67-45b6-a7c0-c335e70c752a.png`
- 제작 방식: 참조 이미지 없이, 네 개의 빈 문 개구부를 가진 독자적인 가상 도시철도 열차를 ImageGen으로 신규 생성
- 생성일: 2026-08-09
- 입력 요약: 전면과 측면이 보이는 indigo·ivory 3/4 열차, 네 개의 빈 문, 인물·로고·텍스트·실제 도색 없음
- 편집 이력: 단색 마젠타 배경으로 생성한 뒤 CoreGraphics chroma key로 투명화했으며, 문·승객·glow는 SpriteKit 별도 레이어로 구현
- SHA-256: `c522327db2cb106b526370c3d8bf38061bb180c37f4e8f6f6de1c200acbc68f4`
- 검사 상태: 1398×591, 실제 alpha 채널 확인. Return Shot 전환 후 앱 번들에서 제외하고 학습 증거로만 보존

## 2.5D 통근 승객 시트

- 보존 파일: `docs/04-design/archive/train-assets/CommuterSheet.imageset/CommuterSheet.png`
- 원본 생성 파일: Codex ImageGen 세션 `exec-f3e944a6-ef1e-4223-a10a-b92758e06dcc.png`
- 제작 방식: 참조 이미지 없이 서로 다른 연령·복장의 가상 통근 승객 8명을 ImageGen으로 신규 생성
- 생성일: 2026-08-09
- 입력 요약: 2.5D 장난감 디오라마 인물, 정면 전신, 로고·텍스트·실존 인물 없음, 마젠타 배경
- 편집 이력: CoreGraphics chroma key로 투명화하고 8칸 런타임 texture atlas로 사용
- SHA-256: `52971b37277394a36e4b8c629b8e3de75a5f1310ae176686a45f08b740b1ebf5`
- 검사 상태: 2172×724, 실제 alpha 채널 확인. Return Shot 전환 후 앱 번들에서 제외하고 학습 증거로만 보존

## 오너 승인 런타임 마스터 화면

- 보존 파일: `docs/04-design/archive/train-assets/OwnerMasterScene.imageset/OwnerMasterScene.png`
- 제공 방식: 프로젝트 오너가 대화에 직접 첨부하고, 다른 재해석 대신 해당 디자인을 그대로 복제해 사용하라고 명시
- 제공·승인일: 2026-08-09
- 원본 SHA-256: `47de693c84bd4f10fa8d25e831bac0e16bb1d7ef6dcb035f56454cc0967dd8fe`
- 런타임 SHA-256: `c63b5679d044dc43e5a8d5a2a7771a00c8e6dc863926afa440ec0e13c4458ae4`
- 편집 이력: 원본 941×1672 픽셀은 재생성·리터치하지 않고 유지. iPhone 세로 안전영역 대응을 위해 `sips`로 위·아래에 동일한 `#061129` 패딩을 추가해 941×2046으로 확장
- 보존 상태: 과거 열차 prototype의 오너 승인 근거로만 보존하며 Return Shot 앱 번들에는 포함하지 않음
- 권리 상태: prototype 사용은 오너의 명시적 요청으로 기록. 공개 상용 출시 전 오너의 원본 권리·상용 사용 권한 확인과 실제 철도·랜드마크·제3자 유사성 검토는 별도 Gate로 남김

## 코드 생성 사운드

- 파일 자산 없음. `GameAudioService`가 사인파를 합성해 출발·제동·문·성공·실패의 짧은 원본 효과음을 런타임에 생성함
- 실제 철도 안내음·차임·녹음은 사용하지 않음

## Brick Breaker 디자인 시스템 보드

- 파일: `references/brick-breaker-design-system-board.png`
- 제공 방식: 사용자가 제공한 `brick-breaker-codex-kit` v1.0.0의 참고 이미지로 2026-08-18 프로젝트에 복사
- 원본 SHA-256: `54fe5e90dc9fb46c3446cc00ef119e8233593f82c2fa5b0ce1484db26bafeccd`
- 검사 상태: 1536×1024, PNG, 8-bit RGB, non-interlaced
- 사용 범위: 시각 언어와 정보 계층 검토용 비권위 reference. Xcode asset catalog·앱 런타임·SwiftPM resource에 포함하지 않음
- 금지: 픽셀 복제, 제3자 권리 확인 전 상용 배포, 이미지 자체를 gameplay truth로 사용
- 권리 상태: 키트에 LICENSE·NOTICE·저작권자·상업/수정/재배포 허가가 없어 `미확인`. 사용자의 복사 요청은 프로젝트 반입 근거이며 독립적인 권리 보증으로 해석하지 않음
- 전체 반입 기록: `docs/05-engineering/brick-breaker-kit-import-2026-08-18.md`

## Return Shot Action Art v2 런타임 자산

- 생성일: 2026-08-18 KST
- 제작 방식: OpenAI 내장 ImageGen으로 Return Shot 전용 독자 원본 생성
- 방향성 참고: 오너가 제공한 1536×1024 Action Design System 보드(SHA-256 `c6c35216d8b1d1cf57a390654cb9ca341eead149aefd492ed2ab4f5eaa1a25d6`)
- 참고 범위: 금속 베벨, 재질 깊이, 어두운 아케이드 HUD, 공격별 색·형태 문법, 배경의 3단 깊이만 사용
- 독자화 조치: 참고 보드의 로고, 문구, UI 배치, 벽돌 픽셀, 공·패들 형태, 스킬 그림을 복사하지 않고 자산별 텍스트 브리프로 새로 생성. `BRICK BREAKER` 이름, boss, multiball, freeze, homing, laser, shield, slow time을 제외
- 공통 후처리: 원본은 보존하고 프로젝트 사본만 `sips`로 런타임 크기에 축소. 생성기가 실제 alpha 대신 체크 패턴을 굽는 경우 alpha라고 허위 기록하지 않고, 오브젝트는 SpriteKit shape 내부 texture crop으로 제한하며 VFX·HUD·wordmark는 pure-black 배경을 additive/screen blend로 합성
- 총 프로젝트 크기: 약 3.8MB

| 런타임 파일 | ImageGen 원본 세션 | 규격 | SHA-256 | 사용 |
|---|---|---:|---|---|
| `RS_Playfield_Background.png` | `exec-89297dbf-5ffe-4213-8607-5b6ed1ad6be3.png` | 841×1870 | `ccf62c33e2cab8cfe052904c6d5bb276df1933039efea9ed5c40ce6b3e4801ac` | 세로 기계 도시 배경 |
| `RS_Brick_Material.png` | `exec-368e2234-1725-4e33-859c-43bdc895ef3c.png` | 512×227 | `b1b85a62895dbc95a8957a6abbac8a8359a4d38301cd67cf32d133ce2acad4fe` | 벽돌 shape 내부 재질 |
| `RS_Ball_Chrome.png` | `exec-2a1523aa-7add-4411-b9a6-766e2b81b1c3.png` | 256×256 | `1f356aca97becb0608eae6f9bf479fc1384983eb372350493def526808d99324` | 공 shape 내부 재질 |
| `RS_Paddle_Arcade.png` | `exec-e4334974-9b34-417e-8f9c-b1ac6ef9cca8.png` | 512×256 | `c7aae6eb2ed7b719289181a49014eb4c8534eee26a532d7604ffe7c818a45a06` | 기계형 패들 재질 |
| `RS_VFX_Lightning.png` | `exec-88c7ddb6-7003-4064-a2a7-4b0f1e576531.png` | 512×512 | `b5dd052179f0d95c6a2c6a0d78f022fad9b5ff93c1430e3f1efe04a8e4055af7` | 번개 additive impact |
| `RS_VFX_Flame.png` | `exec-4b473604-bc31-47ee-b31e-b6a4d4a089b8.png` | 512×512 | `23e197189977e30e62d4a86239eb9b8ee12c2a05213e4e78db593b256feef1a0` | 화염 additive impact |
| `RS_VFX_Wind.png` | `exec-d7859a1b-e8bd-4e24-baa9-e812e6ac3371.png` | 512×512 | `8c37c76a4b339ec315a854b836ceb964803d585aafccaafaebbc460c49df143c` | 바람 additive impact |
| `RS_VFX_Pierce.png` | `exec-3241cfa3-42f6-4689-8214-6133f5723291.png` | 512×512 | `7b04b894f4eaf7e9ecbc968e6f7c42ca551d1879cabf1465da99acad4deab043` | 관통 additive impact |
| `RS_Logo_Wordmark.png` | `exec-232fe3a1-4ad8-476e-b83d-a1765fc1ab8a.png` | 1024×512 | `5ce48769116209c2773d9873ca520e08ad3958f93ffc59c9085f95c043ea506b` | 정확한 `RETURN SHOT` 홈 wordmark |
| `RS_HUD_Frame.png` | `exec-7975e40f-215b-428c-b449-c09c97530f29.png` | 1024×426 | `5d790bfb836dfba1e1594d3fda884c730f67bfde1ec6df8c0cf16d4627c22d7b` | native HUD 문구 바깥 장식 frame |

- 권리 상태: ImageGen 신규 출력이지만 법률 의견이나 비침해 보증은 아니다. 공개·상용 출시 전 오너의 reference 사용 권한, 생성물 이용 조건, side-by-side 비유사성, 상표를 다시 확인한다.

## Descent Breaker 오너 제공 런타임 시트

- 제공일: 2026-08-19 KST
- 제공 방식: 프로젝트 오너가 대화에 직접 첨부하고 게임 에셋으로 전달
- 최초 첨부 형식: 1280×960 JPEG, RGB, 흰 배경. 이후 오너가 ChatGPT 공유 링크로 동일 계열의 1448×1086 RGBA 투명 PNG 6장을 전달했다.
- 런타임 처리: 오브젝트·파괴 단계·아이템·VFX·플레이어 공격·HUD는 투명 PNG를 atlas crop으로 직접 사용한다. 시뮬레이션·충돌·점수·drop 판정에는 이미지 픽셀을 사용하지 않는다.
- ImageGen 검사: 내장 ImageGen으로 `DB_Objects`의 투명 배경 분리를 2회 시도했으나 출력이 RGBA가 아닌 RGB 체크무늬 합성으로 확인되어 파생 PNG는 앱에 반입하지 않았다. 이후 공유 링크에서 받은 실제 RGBA 원본으로 교체했다.

| 런타임 asset | 역할 | SHA-256 |
|---|---|---|
| `DB_Objects.png` | 일반/강화/스파이크/드론/코어, 플레이어·후속 보스 후보 | `8bdb4140c585af1f79d3187b9e48782ff19867ab6542e6134404d25d9e4ef0ee` |
| `DB_BreakStates.png` | 오브젝트 단계 파괴 프레임 | `c53c6b050c7c55d81f67b65fec38c1d42c523c67724353eff1946370ce91627e` |
| `DB_SkillItems.png` | 불·전기·관통·바람·폭발 pickup | `0676de8970d11792ca886466c1cd8ba0a3c569838523578f5ffdcc09eba1fe36` |
| `DB_SkillVFX.png` | 5속성 발동 VFX 후보 | `4f16967289da6f36ddeb9f55c5d9a9c524037284866429a925ec46601ab00910` |
| `DB_PlayerAttacks.png` | 플레이어 기체·기본/속성 공격 후보 | `55789ea0a2d266ee7af9a047db88e40af8d01742adc904866268caa4f3b32e5f` |
| `DB_HUD.png` | reactor·shield·pause·skill rail 장식 | `80aecbefbd84fd029c84ec4a0c61249d93f1dddd54cbc39e1b6debd680298d78` |
| `DB_Feedback.jpg` | danger·pickup·critical·reward feedback 후보 | `744a907d498c05425cba53f5e7a5fcd91ab6c397c2a62753557b2e2a8cf2b331` |

- 권리 상태: 오너가 직접 제작했다고 명시하고 프로젝트 에셋으로 전달했다. 공개·상용 출시 전 저작권 보유·학습 원본·제3자 상표/디자인 유사성에 대한 최종 오너 확인은 별도 Release Gate로 남긴다.

## Descent Breaker GPT Combat Signature v1

- 생성·반입일: 2026-08-21 KST
- 제작 방식: OpenAI 내장 Imagegen으로 이 프로젝트 전용 신규 생성
- 스타일 참고: 현재 런타임의 오너 제공 `DB_PlayerAttacks.png`, `DB_SkillVFX.png`만 사용. 기체·UI·구도를 복제하지 않고 금속/발광 밀도와 속성 색 문법만 참고
- 런타임 방식: 생성기가 투명 요청 및 배경 추출 편집에서 두 차례 모두 RGB 체크무늬를 출력해 해당 6개 후보는 반려했다. 최종 3개는 균일한 순수 검정 배경의 additive 전용 RGB로 다시 생성하고 SpriteKit `.add` 합성으로만 사용한다. 실제 RGBA라고 기록하거나 불투명 오브젝트에 사용하지 않는다.
- 원본 보존: `references/asset-sources/descent-gpt/2026-08-21/`
- 후처리: 원본을 보존하고 `sips -Z 512`로 sRGB 런타임 파생본만 축소. 수동 premultiply 또는 생성물 리터치는 하지 않음

| 런타임 파일 | Imagegen 원본 | 원본 SHA-256 | 런타임 규격 | 런타임 SHA-256 | 사용 |
|---|---|---|---:|---|---|
| `DB_VFX_ElectricImpact_R1.png` | `exec-9b2ca044-a517-4ef3-b397-aa681e2777b0.png` | `45f43e0767efb4d1add8654c1c453915b9eb8844e26ee6c507cb7415a7161d18` | 512×512 RGB | `e5b306639b2a9bc4c4f657076f649117339e24fc34e9cd9337e3dc1fd4cc7910` | 실제 충돌 origin의 다중 분기 전기 코어 |
| `DB_VFX_WindBurst_R1.png` | `exec-b231e1cf-65e7-445c-94d8-8df785083b79.png` | `6524bee57121bba4715297052761ba1077a550be432f0dbf6577f8f7ddfe258a` | 409×512 RGB | `8192bc22be5c412c12724be42d178668c6e066a9030629abce0067b98e91562b` | 고정 origin의 상승 와류 motif |
| `DB_VFX_PlayerAura_R1.png` | `exec-1b0bce14-576c-4848-a202-a7e35af14e8f.png` | `2f9391725ee3c8f8d48c83184cede583d94a51f6fcab941e70737a8dd3d3c7db` | 512×432 RGB | `f45313f18775dcbfd967db93e65de3f715fbf0cf1d74950292afc4bdfe44c21d` | 기체 아래 공격 기원 리액터 오라 |

- 프롬프트 요약: 전기=직선 레이저가 아닌 5방향 분기 relay, 바람=거대한 토네이도가 아닌 이중 곡선과 상승 chevron, 오라=불투명 플랫폼이 아닌 cyan ellipse·orange core·짧은 exhaust. 공통적으로 텍스트·숫자·로고·워터마크·UI·기체·적·전체 화면 flash를 금지
- 게임 경계: `DescentArtCatalog`와 `DescentGameScene`의 비권위 presentation layer만 변경하며 충돌·데미지·점수·drop·120Hz ordering은 변경하지 않음
- 권리 상태: Imagegen 신규 출력이지만 법률 의견이나 제3자 권리 비침해 보증은 아니다. 공개·상용 출시 전 생성물 이용 조건, 참조 사용 권한, side-by-side 비유사성, 상표 검토가 필요하다.
