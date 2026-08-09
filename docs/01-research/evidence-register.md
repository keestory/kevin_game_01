# Evidence Register — 한국 iPhone 무료 Games, 2026-08-10

> 20:52 KST 실제 열차 콘셉트 재조사 RT01~RT10은 [real-train-refresh-2026-08-09.md](real-train-refresh-2026-08-09.md)에 추가했다. 동적 차트 웹·RSS의 갱신 시각 차이를 분리 기록한다.
>
> 2026-08-10 endless 기록형 피벗의 최신 Apple 무료·매출 관측, 물리 파괴 경쟁작, 대안 폐기 근거는 [endless-score-pivot-2026-08-10.md](endless-score-pivot-2026-08-10.md)에 분리했다. 기존 E01~E27은 2026-08-09 스냅샷으로 유지한다.

## 등급과 사용 규칙

- `A`: 공식·1차 자료 또는 스토어의 직접 관측. 원자료가 맞다는 뜻이며, 그것을 전체 사용자에게 일반화할 수 있다는 뜻은 아니다.
- `B`: 방법과 범위가 확인되는 공공 설문·연구 또는 상업적 추정. 표본·추정법·시점 한계를 함께 적용한다.
- `C`: 2차 기사, 방법론이 불완전한 조사, 해외 웹 대체재 등 방향성 참고 자료.
- 동적 차트와 평점은 재현 가능한 역사 자료가 아니다. 아래 관측 시각 이후 순서와 수치는 바뀔 수 있다.
- 핵심 결론은 서로 다른 기관의 근거를 2개 이상 연결하며, `한 칸만! 만원열차` 자체의 성과로 치환하지 않는다.

## 근거 목록

| ID | 출처·URL | 게시일/자료시점 | 확인일 | 지역 | 플랫폼 | 차트/자료 유형 | 구분 | 등급 | 핵심 관측과 한계 |
|---|---|---|---|---|---|---|---|---|---|
| E01 | [Apple 한국 iPhone 인기 Games](https://apps.apple.com/kr/iphone/charts/6014?chart=top-free&l=ko-KR) | 실시간 갱신 | 2026-08-09 19:58 KST | 한국 | iPhone App Store | Games / Top Free | 관측값 | A | 상위 25개 순서를 직접 추출. 다운로드 수·순위 산식·UA 규모는 Apple이 공개하지 않음. |
| E02 | [Apple iTunes Lookup API — 비교 앱 10개](https://itunes.apple.com/lookup?id=6749251466,6761979765,1551772053,6786589102,6776989094,6752672568,6759763476,6471045672,1617391485,6761760135&country=kr&entity=software) | 앱별 출시·업데이트일 상이 | 2026-08-09 | 한국 | iPhone App Store | 앱 메타데이터 | 관측값 | A | 출시일, 최신 버전일, 한국 평점·평가 수, 장르. 평점 수는 설치 수가 아니며 국가/시점에 따라 변함. |
| E03 | [Bus Traffic Fever! Apple 최근 리뷰](https://itunes.apple.com/kr/rss/customerreviews/page=1/id=6759763476/sortby=mostrecent/json) | 동적 피드 | 2026-08-09 | 한국 | iPhone App Store | 최근 고객 리뷰 | 관측값 | A | 최근 5개를 코딩. 자기선택·소표본이라 빈도 일반화 불가. |
| E04 | [Block Out! Apple 최근 리뷰](https://itunes.apple.com/kr/rss/customerreviews/page=1/id=6752672568/sortby=mostrecent/json) | 동적 피드 | 2026-08-09 | 한국 | iPhone App Store | 최근 고객 리뷰 | 관측값 | A | 최근 5개를 코딩. 버전·노출 순서 편향 가능. |
| E05 | [Block Blast Apple 최근 리뷰](https://itunes.apple.com/kr/rss/customerreviews/page=1/id=1617391485/sortby=mostrecent/json) | 동적 피드 | 2026-08-09 | 한국 | iPhone App Store | 최근 고객 리뷰 | 관측값 | A | 최근 5개를 코딩. 설치자 전체를 대표하지 않음. |
| E06 | [테이스티 트레블 Apple 최근 리뷰](https://itunes.apple.com/kr/rss/customerreviews/page=1/id=6471045672/sortby=mostrecent/json) | 동적 피드 | 2026-08-09 | 한국 | iPhone App Store | 최근 고객 리뷰 | 관측값 | A | 최근 5개를 코딩. 결제·에너지 불만이 보이나 모집단 빈도는 미확인. |
| E07 | [Meowdoku! Apple 최근 리뷰](https://itunes.apple.com/kr/rss/customerreviews/page=1/id=6761760135/sortby=mostrecent/json) | 동적 피드 | 2026-08-09 | 한국 | iPhone App Store | 최근 고객 리뷰 | 관측값 | A | 최근 5개를 코딩. 광고와 친구 기능 의견을 방향성으로만 사용. |
| E08 | [Google Play Games 카테고리](https://play.google.com/store/apps/category/GAME?hl=ko&gl=KR) | 실시간 갱신 | 2026-08-09 | 한국 설정 | Google Play | Games / browse·인기 영역 | 관측값 | A | Block Blast, Meowdoku, Arrows 등 퍼즐 노출 확인. 페이지 섹션을 엄밀한 전체 순위로 해석하지 않음. |
| E09 | [Bus Traffic Fever! Google Play](https://play.google.com/store/apps/details?id=jp.co.goodroid.hyper.busflow&hl=ko&gl=KR) | 업데이트 2026-07-01 | 2026-08-09 | 한국 설정 | Google Play | 앱 상세·인기 무료 퍼즐 | 관측값 | A | 1,000만+ 다운로드, 4.0점, 약 5.79만 리뷰, #8 인기 무료 퍼즐, 광고 포함·IAP. 노출된 최신 리뷰에도 긴/부적절/강제 광고 불만. |
| E10 | [KOCCA 2024 게임 이용자 실태조사](https://welcon.kocca.kr/ko/info/report/1954596) | 원보고서 2024-12-30, 등록 2025-01-03 | 2026-08-09 | 한국 | PC·모바일·콘솔 | 전국 이용자 설문 | 사실/설문 | A | 조사 개요와 원보고서. 자기보고·2024년 자료라는 시차가 있음. |
| E11 | [KOCCA 조사 보도자료](https://welcon.kocca.kr/ko/info/business/1954603) | 2025-01-06 | 2026-08-09 | 한국 | 멀티플랫폼 | 게임 이용자 8천명, 이용률 1만명 | 사실/설문 | A | 게임 이용률 59.9%, 게임 이용자 중 모바일 91.7%. 인디 발견: 영상 41.0%, 순위 34.0%, 지인추천 33.3%, 광고 32.7%. |
| E12 | [KOCCA 2024 Korean Game User Insights](https://welcon.kocca.kr/mobile/en/support/resources/377) | 2025-08-13; 원자료 2024-12-30 | 2026-08-09 | 한국 | 모바일 중심 | 모바일 이용자 n=7,402 재정리 | 사실/설문 | A | 모바일 선호 장르 Top3 합산: 퍼즐·퀴즈 38.0%, RPG 23.9%, 테이블·카지노 20.0%, 하이퍼캐주얼 10.4%. 평균 이용·지출은 장르별 값이 아님. |
| E13 | [KOCCA 한국 인디게임 이용자 요약 PDF](https://welcon.kocca.kr/cmm/fms/FileDown.do?atchFileId=FILE_3cf38fbc-1aba-462a-9041-aa2d6e1f05af&fileSn=1&preview=Y) | 게시일 미표시, 2024 조사 재정리 | 2026-08-09 | 한국 | 멀티플랫폼 | 인디게임 이용자 n=2,247 | 사실/설문 | A | 선택 이유: 가벼운 콘셉트 54.4%, 신선한 소재 49.3%, 간단 조작 34.8%, 짧은 플레이 22.0%. 20대 인디 경험률 41.8%; `본 게임` 수요는 아님. |
| E14 | [Sensor Tower 2025 한국 게임 시장](https://sensortower.com/ko/blog/state-of-gaming-in-korea-2025-report-KR) | 2025-11 | 2026-08-09 | 한국 | App Store+Google Play | 다운로드·IAP·광고 추정 | 외부 추정 | B | 2025 IAP 53억달러 전망, Google Play 75%; 미드코어 수익 79%, 캐주얼 +8%, 하이브리드 캐주얼 +37%. 2025년 1~9월 퍼즐 광고비 4,700만달러 추정. 광고수익·제3자 Android 스토어 제외. |
| E15 | [Sensor Tower 2025년 하반기 한국 결산](https://sensortower.com/ko/blog/2H2025-mobile-games-recap-in-Korea) | 2026-01 | 2026-08-09 | 한국 | 모바일 | 다운로드·수익 추정 | 외부 추정 | B | Block Blast가 2025-12 한국 약 90만 다운로드로 다운로드 성장 1위라는 추정. 장기 운영 단순 퍼즐의 가능성이지 신규 인디의 재현 보장은 아님. |
| E16 | [Adjust Gaming App Insights 2026](https://www.adjust.com/resources/ebooks/gaming-app-insights/) | 2026판, 정확한 일자 미표시 | 2026-08-09 | 글로벌/지역별 | 모바일 | 설치·세션·유지·UA 벤치마크 | 외부 분석 | B | 2026 성장의 초점을 고LTV·유지·라이브옵스·reward-driven engagement로 설명. 공개 랜딩만으로 한국 iOS 수치를 확인하지 못함. |
| E17 | [KMGA·Yango 2026 모바일 앱 리포트 기사](https://www.gamemeca.com/en/view.php?gid=1775664) | 2026-05-27 | 2026-08-09 | 한국 | 모바일 앱 | 전문가 설문 n=204의 2차 기사 | 외부 조사/2차 | C | 39%가 국내 포화 인식, 67%가 명확한 가치의 광고 참여 의향이라는 기사 요약. 응답자와 `사용자` 분모 표현이 불명확해 방향성만 사용. |
| E18 | [KDI 모바일 생태계 경쟁 연구](https://www.kdi.re.kr/research/reportView?pub_no=19166) | 2025-12-31 | 2026-08-09 | 한국 | 앱마켓 | 2023년 기반 정책 연구 | 외부 연구 | B | 한국에서 Google Play이 다운로드·매출의 70% 초과, 게임은 App Store 매출의 71%라는 분석. 2023년 자료라 현재 iPhone SAM 산정에는 직접 사용하지 않음. |
| E19 | [Apple App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) | 상시 갱신 | 2026-08-09 | 글로벌 | iOS | 정책 | 사실/정책 | A | 2.3 정확한 메타데이터, 2.5.18 광고 표시·닫기/건너뛰기·신고, 3.2.2(x) 광고 등 앱 내부 행동 보상 허용/스토어 행동 강제 금지, 4.1 copycat, 5.1 개인정보. |
| E20 | [Google Play Ads Policy](https://support.google.com/googleplay/android-developer/answer/9857753?hl=ko) | 상시 갱신 | 2026-08-09 | 글로벌 | Android | 정책 | 사실/정책 | A | 예기치 않은 전면광고와 게임 시작/플레이 중 방해 금지. 명시적으로 opt-in한 보상형 광고는 별도 취급. |
| E21 | [Apple Pre-order](https://developer.apple.com/app-store/pre-orders/) | 상시 갱신 | 2026-08-09 | 글로벌 | App Store | 출시 도구 | 사실/공식 | A | 신규 앱은 공개 후 출시일까지 2~180일, 출시일 자동 다운로드·알림. 성과 보장은 아님. |
| E22 | [Apple Product Page Optimization](https://developer.apple.com/app-store/product-page-optimization/) | 상시 갱신 | 2026-08-09 | 글로벌 | App Store | 전환 실험 도구 | 사실/공식 | A | 원본 대비 최대 3개 treatment, 최대 90일, 아이콘·스크린샷·프리뷰 비교 가능. |
| E23 | [Apple Featuring Nomination](https://developer.apple.com/help/app-store-connect/manage-featuring-nominations/nominate-your-app-for-featuring/) | 상시 갱신 | 2026-08-09 | 글로벌/지역 지정 | App Store | 편집 추천 신청 | 사실/공식 | A | 출시·업데이트 추천 신청 가능, Apple은 최소 3주 전 제출 권고. 피처링은 보장되지 않음. |
| E24 | [Apple Ads 키워드 도움말](https://ads.apple.com/kr/app-store/help/keywords/0014-add-and-manage-keywords) | 상시 갱신 | 2026-08-09 | 한국 | App Store | 검색 광고 | 사실/공식 | A | 관련 키워드·검색 유형·추천 키워드 운영 가능. 경쟁 키워드의 실제 CPT/CPI는 미확인. |
| E25 | [Poki 무료 웹게임](https://poki.com/) | 상시 갱신 | 2026-08-09 | 글로벌 | 모바일·PC 웹 | 무설치 대체재 | 운영자 주장/관측 | C | 1,500개 게임, 월 1억 플레이어, 무설치·무다운로드라고 자체 설명. 한국 이용 규모는 미확인. |
| E26 | [Poki Traffic Rush!](https://poki.com/en/g/traffic-rush) | 업데이트 2024-09 | 2026-08-09 | 글로벌 | 모바일·PC 웹 | 교통·원터치 대체 게임 | 관측/해외 유사 | C | 모바일·태블릿 지원, 한 번 탭하는 교통 타이밍 게임, 65만+ 투표. 한국 현지 수요 증거는 아님. |
| E27 | [CookieRun: Crumble 공식 사전등록](https://pre.cookieruncrumble.com/ko) | 2026-06~07 캠페인 | 2026-08-09 | 한국/글로벌 | 웹→모바일 | 경쟁작 사전등록 | 관측값 | A | 현재 Apple 1위 경쟁작이 출시 전 공식 사전등록을 운영했다는 사실. 사전등록자 수와 순위 인과는 미공개. |

## E01 차트 스냅샷 원문 기록

2026-08-09 19:58:15 KST에 E01에서 관측한 순서다. Apple은 다운로드 수와 순위 산식을 함께 제공하지 않았다.

| 순위 | 앱 | 순위 | 앱 |
|---:|---|---:|---|
| 1 | 쿠키런 키우기 - 쿠키런: 크럼블 | 14 | 테이스티 트레블: 합성 게임 |
| 2 | 여전사 키우기 : 듀얼 방치형 | 15 | Z 루트 |
| 3 | 퍼즐 오브 Z | 16 | 미친 타워 |
| 4 | 티니핑 매직 매치 | 17 | Block Blast |
| 5 | 블라이트 워 : 방치형 RPG | 18 | Pokémon GO |
| 6 | 히어로 랜드M | 19 | 총잡이 고양이 idle |
| 7 | Block Out! - Color Sort Puzzle | 20 | 드래곤빌리지3 |
| 8 | Roblox | 21 | Pokémon Champions |
| 9 | Family Go! | 22 | 의미심장 스토리 |
| 10 | WOS | 23 | Vardian |
| 11 | NBA 덩크 시티 | 24 | Search It |
| 12 | Jewel Coloring | 25 | Meowdoku! |
| 13 | Bus Traffic Fever! |  |  |

이름, 장르 메타데이터와 실제 스토어 설명을 보수적으로 함께 본 결과 퍼즐/하이브리드 캐주얼 성격이 뚜렷한 앱은 최소 9개였다: 퍼즐 오브 Z, 티니핑 매직 매치, Block Out!, Jewel Coloring, Bus Traffic Fever!, 테이스티 트레블, Block Blast, Search It, Meowdoku!. 이는 25개 모집단의 영구 장르 점유율이 아니라 한 시점의 하한 관측이다.

## 핵심 결론 교차검증 맵

| 결론 | 1차 근거 | 독립 교차근거 | 판정 |
|---|---|---|---|
| 퍼즐·간단 조작 수요가 한국에 존재한다 | E01, E08 | E12, E13, E14 | `지지됨`; 정확한 iPhone 세그먼트 크기는 미확인 |
| 무료차트 1위는 코어 재미만으로 설명할 수 없다 | E01+E02의 최신작 집중 | E14의 높은 광고 지출, E27의 사전등록 | `지지됨`; Apple 순위 산식·다운로드 임계치는 미확인 |
| 강제·과도한 광고는 차별화 가능한 고통이다 | E03~E07, E09 | E17, E19, E20 | `지지됨`; 실제 이 게임에서 광고를 덜 보면 LTV가 성립하는지는 미확인 |
| 영상·스토어·추천은 초기 획득 후보 채널이다 | E11, E13 | E21~E24 | `채널 후보`; 본 게임의 CAC·전환은 미검증 |
| iPhone 단독은 한국 전체 성장 경로가 아니다 | E18 | E14 | `지지됨`; iOS-first 검증 자체를 반박하지는 않음 |
| 웹 무설치 게임도 대체재다 | E25, E26 | 없음 | `약한 근거`; 한국 사용자 인터뷰로 확인 필요 |

## 미확인 자료

- 2026-08-09 한국 iPhone 무료 Games 1위에 필요한 일·시간당 다운로드 수와 유료/오가닉 비중.
- 한국 iOS 퍼즐 CPI, rewarded-video eCPM, fill rate, payer conversion의 동일 기간·동일 장르 수치.
- `한 칸만! 만원열차`의 D1/D7, 한 세션 재도전, 공유→설치, 광고 후 재방문.
- 지하철·퇴근길 소재가 실제로 설치 또는 재방문을 높이는지 여부.
- 2026 Google Play 한국 전체 Games의 엄밀한 순위 스냅샷. E08은 browse·인기 섹션 관측이다.
