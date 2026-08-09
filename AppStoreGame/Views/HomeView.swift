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
                        Label("오늘의 정위치 운행", systemImage: "tram.fill")
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
                        Text("정위치!")
                            .font(.system(size: 52, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                        Text("만원열차")
                            .font(.system(size: 31, weight: .black, design: .rounded))
                            .foregroundStyle(Color.safetyYellow)
                        Text("정차선에 맞춰 승객을 내려요")
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.62))
                            .padding(.top, 7)
                    }
                    .padding(.top, 10)

                    TrainPreview()
                        .padding(.vertical, 5)

                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(model.profile.highestStage)단계 운행")
                                    .font(.system(.title3, design: .rounded, weight: .heavy))
                                Text(model.currentDifficulty.assisted ? "편안한 제동 구간이 적용됐어요" : "5개 역에서 목표 인원을 내려주세요")
                                    .font(.footnote.weight(.medium))
                                    .foregroundStyle(model.currentDifficulty.assisted ? Color.exitMint : .white.opacity(0.58))
                            }
                            Spacer()
                            Text("목표 \(model.currentDifficulty.targetExited)명")
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
                                title: "운행 노선",
                                value: "5개 역"
                            )
                        }

                        Button("60초 운행 시작") {
                            model.startGame()
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .accessibilityIdentifier("startGameButton")
                    }
                    .glassCard()

                    HStack(spacing: 10) {
                        Label("원탭 제동", systemImage: "hand.tap.fill")
                        Text("•")
                        Label("실제 열차", systemImage: "tram.fill")
                        Text("•")
                        Label("실제 승하차", systemImage: "door.left.hand.open")
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
                        .accessibilityIdentifier("shareRecordButton")
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

private struct TrainPreview: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: 0xE9EEF1), Color(hex: 0x9CA9B4)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(Color.safetyYellow)
                        .frame(height: 9)
                        .padding(.horizontal, 14)
                        .padding(.top, 17)
                }
                .overlay {
                    HStack(spacing: 12) {
                        ForEach(0..<3, id: \.self) { index in
                            ZStack {
                                RoundedRectangle(cornerRadius: 9)
                                    .fill(Color(hex: 0x18324A))
                                    .frame(width: 72, height: 72)
                                HStack(spacing: 7) {
                                    Image(systemName: "person.fill")
                                        .foregroundStyle(Color(hex: PassengerKind.destinations[index].tintHex))
                                    Image(systemName: "person.fill")
                                        .foregroundStyle(Color(hex: PassengerKind.destinations[index + 1].tintHex))
                                }
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(Color.white.opacity(0.66), lineWidth: 2)
                                    .frame(width: 32, height: 94)
                            }
                        }
                    }
                    .padding(.top, 18)
                }
                .frame(height: 146)

            HStack(spacing: 190) {
                wheel
                wheel
            }
            .offset(y: 72)

            HStack(spacing: 4) {
                ForEach(0..<8, id: \.self) { _ in
                    Capsule()
                        .fill(Color.white.opacity(0.30))
                        .frame(width: 20, height: 3)
                }
            }
            .offset(y: -64)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("문과 창문과 바퀴가 보이는 실제 지하철 한 량")
        .padding(.horizontal, 8)
        .padding(.bottom, 15)
    }

    private var wheel: some View {
        Circle()
            .fill(Color(hex: 0x1D2430))
            .frame(width: 39, height: 39)
            .overlay(Circle().stroke(Color(hex: 0x77889A), lineWidth: 5))
            .overlay(Circle().fill(Color(hex: 0xC9D0D6)).frame(width: 11, height: 11))
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
