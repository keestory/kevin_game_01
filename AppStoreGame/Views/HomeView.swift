import SwiftUI

struct HomeView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        ZStack {
            GeometryReader { proxy in
                Image("ReturnShotBackdrop")
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
                    .opacity(model.visualVariant == .impactPop ? 0.78 : 0.62)
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .accessibilityHidden(true)

            LinearGradient(
                colors: [
                    Color(hex: 0x071225).opacity(0.38),
                    Color(hex: model.visualVariant == .impactPop ? 0x311A33 : 0x0A2037).opacity(0.62),
                    Color(hex: 0x071225).opacity(0.94)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 19) {
                    HStack {
                        Label(
                            model.visualVariant == .impactPop ? "IMPACT CHAIN ARCADE" : "ACTIVE RETURN ARCADE",
                            systemImage: "circle.hexagongrid.fill"
                        )
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .foregroundStyle(Color.exitMint)
                        Spacer()
                        Button {
                            model.showSettings = true
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .font(.title3)
                                .frame(width: 44, height: 44)
                                .background(Color.white.opacity(0.08), in: Circle())
                        }
                        .foregroundStyle(.white)
                        .accessibilityLabel("설정")
                        .accessibilityIdentifier("settingsButton")
                    }

                    VStack(spacing: 3) {
                        Text("연쇄파괴")
                            .font(.system(size: 42, weight: .black, design: .rounded))
                        Text("RETURN SHOT")
                            .font(.system(size: 27, weight: .black, design: .rounded))
                            .foregroundStyle(Color.safetyYellow)
                        Text("마크를 잇고 · 코어를 깨고 · 기록을 넘어서")
                            .font(.system(.subheadline, design: .rounded, weight: .bold))
                            .foregroundStyle(.white.opacity(0.58))
                            .padding(.top, 6)
                    }
                    .accessibilityIdentifier("homeHero")

                    ReturnShotPreview(variant: model.visualVariant)

                    VStack(spacing: 14) {
                        HStack(spacing: 10) {
                            homeStat(title: "BEST SCORE", value: model.profile.bestScore.formatted(), color: .white)
                            homeStat(title: "BEST HEIGHT", value: "\(model.profile.bestHeight)m", color: Color.exitMint)
                            homeStat(title: "MAX COMBO", value: "×\(model.profile.bestCombo)", color: Color.safetyYellow)
                        }

                        Button(model.profile.bestScore == 0 ? "첫 기록 시작" : "기록 넘기") {
                            model.startGame()
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .accessibilityIdentifier("startGameButton")
                    }
                    .glassCard()

                    VStack(alignment: .leading, spacing: 11) {
                        rule(icon: "link", color: Color.exitMint, title: "5-LINK", body: "같은 색·무늬·마크를 이으면 6초 공명 폭주")
                        rule(icon: "wand.and.stars", color: Color(hex: 0xB58CFF), title: "스킬 코어", body: "구조마다 1개 · 직접 깨면 즉시 발동 · 같은 코어는 LV3까지")
                        rule(icon: "diamond.fill", color: Color.safetyYellow, title: "프리즘", body: "3번 투자해 큰 점수를 얻거나 지지대를 먼저 끊기")
                        rule(icon: "minus.square.fill", color: Color.alertCoral, title: "마이너스", body: "직접 맞히면 −250, 지지점을 무너뜨리면 +120")
                    }
                    .padding(17)
                    .background(Color.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 22))
                    .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.white.opacity(0.08)))

                    if model.profile.bestScore > 0 {
                        ShareLink(
                            item: "연쇄파괴: 리턴 샷 내 기록은 \(model.profile.bestScore)점 · \(model.profile.bestHeight)m!"
                        ) {
                            Label("기록 공유하기", systemImage: "square.and.arrow.up.fill")
                                .font(.system(.subheadline, design: .rounded, weight: .bold))
                                .foregroundStyle(.white.opacity(0.70))
                                .frame(minHeight: 44)
                                .contentShape(Rectangle())
                        }
                        .accessibilityIdentifier("shareRecordButton")
                    }
                }
                .padding(.horizontal, 19)
                .padding(.top, 10)
                .padding(.bottom, 30)
            }
        }
        .sheet(isPresented: $model.showSettings) {
            SettingsView()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    private func homeStat(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Text(title)
                .font(.system(size: 10, weight: .black, design: .rounded))
                .foregroundStyle(.white.opacity(0.52))
            Text(value)
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(color)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }

    private func rule(icon: String, color: Color, title: String, body: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .black))
                .foregroundStyle(color)
                .frame(width: 30)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.subheadline, design: .rounded, weight: .black))
                Text(body)
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.70))
            }
        }
    }
}

private struct ReturnShotPreview: View {
    let variant: VisualVariant

    private let signatures: [(Color, String)] = [
        (Color.exitMint, "★ ≡"),
        (Color.exitMint, "● ⠿"),
        (Color.exitMint, "▲ ▦"),
        (Color(hex: 0x6AA8FF), "★ ▦"),
        (Color.alertCoral, "● ≡")
    ]

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Image("ReturnShotBackdrop")
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: variant == .impactPop ? 20 : 28))
                    .accessibilityHidden(true)

                RoundedRectangle(cornerRadius: 28)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: 0x071225).opacity(0.48),
                                Color(hex: variant == .impactPop ? 0x321D3A : 0x132742).opacity(0.70)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        ForEach(0..<5, id: \.self) { index in
                            Text(signatures[index].1)
                                .font(.system(size: 11, weight: .black, design: .rounded))
                                .frame(maxWidth: .infinity, minHeight: 34)
                                .background(signatures[index].0.opacity(variant == .impactPop ? 0.82 : 0.68), in: RoundedRectangle(cornerRadius: variant == .impactPop ? 5 : 9))
                                .overlay(RoundedRectangle(cornerRadius: variant == .impactPop ? 5 : 9).stroke(signatures[index].0, lineWidth: variant == .impactPop ? 2 : 1))
                                .overlay(alignment: .topTrailing) {
                                    if index == 0 {
                                        Image(systemName: "bolt.fill")
                                            .font(.system(size: 8, weight: .black))
                                            .foregroundStyle(.white)
                                            .frame(width: 18, height: 18)
                                            .background(Color(hex: 0x071225), in: Circle())
                                            .overlay(Circle().stroke(Color.safetyYellow, lineWidth: 1.5))
                                            .offset(x: 4, y: -4)
                                    }
                                }
                        }
                    }

                    HStack(spacing: 8) {
                        Text("⌁")
                            .frame(maxWidth: .infinity, minHeight: 31)
                            .background(Color.safetyYellow.opacity(0.18), in: RoundedRectangle(cornerRadius: 9))
                            .overlay(RoundedRectangle(cornerRadius: 9).stroke(Color.safetyYellow))
                        Text("◆  ●●●")
                            .font(.system(size: 10, weight: .black))
                            .frame(maxWidth: .infinity, minHeight: 31)
                            .background(Color(hex: 0x514276), in: RoundedRectangle(cornerRadius: 9))
                            .overlay(RoundedRectangle(cornerRadius: 9).stroke(Color.safetyYellow, lineWidth: 2))
                        Text("−")
                            .font(.system(size: 23, weight: .black))
                            .frame(maxWidth: .infinity, minHeight: 31)
                            .background(Color(hex: 0x3B1524), in: RoundedRectangle(cornerRadius: 9))
                            .overlay(RoundedRectangle(cornerRadius: 9).stroke(Color.alertCoral, lineWidth: 2))
                    }

                    Spacer()

                    Circle()
                        .fill(.white)
                        .frame(width: 22, height: 22)
                        .overlay(Circle().stroke(Color.exitMint, lineWidth: 4))
                        .shadow(color: Color.exitMint.opacity(0.8), radius: 8)
                        .offset(x: 44)

                    Capsule()
                        .fill(Color(hex: 0x122B43))
                        .frame(width: 115, height: 19)
                        .overlay(Capsule().stroke(Color.exitMint, lineWidth: 4))
                        .shadow(color: Color.exitMint.opacity(0.5), radius: 9)
                }
                .padding(19)

                Text("민트 LINK 4/5")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(Color.exitMint)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.trainNavy.opacity(0.9), in: Capsule())
                    .position(x: proxy.size.width / 2, y: proxy.size.height * 0.57)
            }
        }
        .frame(height: 226)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("패들로 공을 받아 같은 마크를 잇고, 공격 코어와 프리즘, 마이너스 지지 구조를 공략하는 화면")
    }
}
