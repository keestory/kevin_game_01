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
                        Label("오늘의 혼잡도 운행", systemImage: "tram.fill")
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
                        Text("문 닫습니다!")
                            .font(.system(size: 46, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                        Text("지옥철")
                            .font(.system(size: 31, weight: .black, design: .rounded))
                            .foregroundStyle(Color.safetyYellow)
                        Text("현재 인원이 목표와 같을 때 문을 닫아요")
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
                                Text("\(model.profile.highestStage)단계 · 5개 역")
                                    .font(.system(.title3, design: .rounded, weight: .heavy))
                                Text("우르르 승하차하는 인원을 딱 맞춰주세요")
                                    .font(.footnote.weight(.medium))
                                    .foregroundStyle(.white.opacity(0.58))
                            }
                            Spacer()
                            Text("정확 3/5")
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

                        Button("60초 지옥철 출발") {
                            model.startGame()
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .accessibilityIdentifier("startGameButton")
                    }
                    .glassCard()

                    HStack(spacing: 10) {
                        Label("인원 타이밍", systemImage: "number.circle.fill")
                        Text("•")
                        Label("우르르 승하차", systemImage: "person.3.fill")
                        Text("•")
                        Label("실제 승하차", systemImage: "door.left.hand.open")
                    }
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.48))

                    if model.profile.bestScore > 0 {
                        ShareLink(
                            item: "문 닫습니다! 지옥철 내 최고 점수는 \(model.profile.bestScore)점. 목표 인원에 딱 맞출 수 있을까?"
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
            RoundedRectangle(cornerRadius: 30)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: 0x173F5C), Color(hex: 0x081833)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(alignment: .bottom) {
                    LinearGradient(
                        colors: [Color(hex: 0x33445B), Color(hex: 0x182437)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 60)
                }

            VStack(spacing: -10) {
                Image("DioramaTrain")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 350, height: 148)
                    .shadow(color: .black.opacity(0.46), radius: 12, y: 9)

                HStack(spacing: -3) {
                    ForEach(0..<10, id: \.self) { index in
                        Image(systemName: "person.fill")
                            .font(.system(size: 22 + CGFloat(index % 3) * 3, weight: .black))
                            .foregroundStyle(index.isMultiple(of: 3) ? Color.safetyYellow : Color.exitMint)
                            .shadow(color: .black.opacity(0.35), radius: 3, y: 2)
                    }
                }
            }

            HStack(spacing: 8) {
                Text("현재 14")
                    .foregroundStyle(Color.exitMint)
                Image(systemName: "equal")
                    .foregroundStyle(.white.opacity(0.60))
                Text("목표 14")
                    .foregroundStyle(Color.safetyYellow)
            }
            .font(.system(size: 16, weight: .black, design: .rounded))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.trainNavy.opacity(0.88), in: Capsule())
            .offset(y: -70)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("사선으로 보이는 도시철도 열차와 승하차 군중, 현재와 목표 14명")
        .frame(height: 206)
        .clipShape(RoundedRectangle(cornerRadius: 30))
        .overlay(RoundedRectangle(cornerRadius: 30).stroke(Color.exitMint.opacity(0.22)))
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
