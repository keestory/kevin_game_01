import SwiftUI

struct HomeView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.trainNavy, Color(hex: 0x172746), .trainNavy],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            DecorativeRoute()
                .opacity(0.34)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 22) {
                    HStack {
                        Label("오늘의 막차", systemImage: "tram.fill")
                            .font(.system(.subheadline, design: .rounded, weight: .bold))
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

                    VStack(spacing: 2) {
                        Text("한 칸만!")
                            .font(.system(size: 52, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                        Text("만원열차")
                            .font(.system(size: 31, weight: .black, design: .rounded))
                            .foregroundStyle(Color.safetyYellow)
                        Text("퇴근길 60초 원터치 퍼즐")
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.62))
                            .padding(.top, 7)
                    }
                    .padding(.top, 10)

                    PassengerPreview()
                        .padding(.vertical, 5)

                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(model.profile.highestStage)역 운행")
                                    .font(.system(.title3, design: .rounded, weight: .heavy))
                                Text(model.currentDifficulty.assisted ? "혼잡 완화 운행이 적용됐어요" : "목표 점수를 채우면 다음 역으로")
                                    .font(.footnote.weight(.medium))
                                    .foregroundStyle(model.currentDifficulty.assisted ? Color.exitMint : .white.opacity(0.58))
                            }
                            Spacer()
                            Text("목표 \(model.currentDifficulty.targetScore.formatted())")
                                .font(.system(.caption, design: .monospaced, weight: .bold))
                                .foregroundStyle(Color.safetyYellow)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .background(Color.safetyYellow.opacity(0.12), in: Capsule())
                        }

                        HStack(spacing: 14) {
                            stat(title: "최고 점수", value: model.profile.bestScore.formatted())
                            Divider().overlay(Color.white.opacity(0.12))
                            stat(
                                title: "안전 손잡이",
                                value: "×\(model.currentDifficulty.safetyHandles)"
                            )
                        }

                        Button("\(model.profile.highestStage)역 운행 시작") {
                            model.startGame()
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .accessibilityIdentifier("startGameButton")
                    }
                    .glassCard()

                    HStack(spacing: 10) {
                        Label("탭 한 번", systemImage: "hand.tap.fill")
                        Text("•")
                        Label("3명 연결", systemImage: "point.3.connected.trianglepath.dotted")
                        Text("•")
                        Label("함께 하차", systemImage: "door.left.hand.open")
                    }
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.48))

                    if model.profile.bestScore > 0 {
                        ShareLink(
                            item: "한 칸만! 내 최고 점수는 \(model.profile.bestScore)점. 몇 점까지 갈 수 있을까?"
                        ) {
                            Label("친구에게 기록 공유하기", systemImage: "person.2.wave.2.fill")
                                .font(.system(.subheadline, design: .rounded, weight: .bold))
                                .foregroundStyle(.white.opacity(0.72))
                                .padding(.vertical, 8)
                        }
                        .accessibilityIdentifier("shareChallengeButton")
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 30)
            }
        }
        .sheet(isPresented: $model.showSettings) {
            SettingsView()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    private func stat(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.48))
            Text(value)
                .font(.system(.title3, design: .rounded, weight: .heavy))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct PassengerPreview: View {
    private let kinds = PassengerKind.allCases

    var body: some View {
        HStack(spacing: -8) {
            ForEach(Array(kinds.enumerated()), id: \.offset) { index, kind in
                ZStack {
                    Circle()
                        .fill(Color(hex: kind.tintHex))
                    Circle()
                        .stroke(Color.white.opacity(0.8), lineWidth: 2)
                    Text(kind.badge)
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundStyle(kind == .star ? Color(hex: 0x5A4510) : .white)
                }
                .frame(width: 58, height: 58)
                .rotationEffect(.degrees(Double(index - 2) * 4))
                .offset(y: index.isMultiple(of: 2) ? 2 : -2)
                .zIndex(Double(index))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("다섯 종류의 승객")
    }
}

private struct DecorativeRoute: View {
    var body: some View {
        GeometryReader { proxy in
            Path { path in
                path.move(to: CGPoint(x: -20, y: proxy.size.height * 0.28))
                path.addCurve(
                    to: CGPoint(x: proxy.size.width + 30, y: proxy.size.height * 0.72),
                    control1: CGPoint(x: proxy.size.width * 0.72, y: proxy.size.height * 0.05),
                    control2: CGPoint(x: proxy.size.width * 0.18, y: proxy.size.height * 0.88)
                )
            }
            .stroke(Color.safetyYellow, style: StrokeStyle(lineWidth: 2, dash: [5, 13]))
        }
    }
}
