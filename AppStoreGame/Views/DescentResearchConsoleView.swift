import SwiftUI

#if DEBUG
@MainActor
final class DescentResearchConsoleModel: ObservableObject {
    @Published private(set) var audit: LocalResearchReadAudit
    @Published private(set) var report: DescentResearchReport
    @Published private(set) var exportURL: URL?
    @Published private(set) var operationMessage: String?

    private let store: LocalResearchEventStore
    private let sampleEnvelopes: [DescentResearchRunEnvelope]?

    init(
        store: LocalResearchEventStore = LocalResearchEventStore(),
        sampleEnvelopes: [DescentResearchRunEnvelope]? = nil
    ) {
        self.store = store
        self.sampleEnvelopes = sampleEnvelopes
        self.audit = LocalResearchReadAudit(
            envelopes: [],
            invalidLineCount: 0,
            futureSchemaLineCount: 0,
            byteCount: 0,
            readFailed: false
        )
        self.report = DescentResearchReport.make(from: [])
        refresh()
    }

    var isSample: Bool { sampleEnvelopes != nil }

    var sourceViolationCount: Int {
        (audit.readFailed ? 1 : 0) + audit.invalidLineCount + audit.futureSchemaLineCount
    }

    var totalViolationCount: Int {
        sourceViolationCount + report.violations.count
    }

    var isEmpty: Bool {
        audit.envelopes.isEmpty && sourceViolationCount == 0
    }

    var isCapacityWarning: Bool {
        audit.envelopes.count >= 80 || audit.byteCount >= 800_000
    }

    var canExportSummary: Bool {
        !audit.envelopes.isEmpty && audit.isTrustworthy && report.isDataQualityValid
    }

    func refresh() {
        let nextAudit: LocalResearchReadAudit
        if let sampleEnvelopes {
            nextAudit = LocalResearchReadAudit(
                envelopes: sampleEnvelopes,
                invalidLineCount: 0,
                futureSchemaLineCount: 0,
                byteCount: 42_000,
                readFailed: false
            )
        } else {
            nextAudit = store.auditReadAll()
        }
        operationMessage = nil
        audit = nextAudit
        report = DescentResearchReport.make(from: nextAudit.envelopes)
        exportURL = canExportSummary ? makeCSVExportURL() : nil
        if !nextAudit.envelopes.isEmpty, exportURL == nil {
            operationMessage = "DQ가 정상일 때만 요약 CSV를 내보낼 수 있습니다. 원본 JSONL은 변경되지 않았습니다."
        }
    }

    func deleteAll() {
        guard !isSample else {
            operationMessage = "샘플 데이터는 삭제되지 않습니다."
            return
        }
        do {
            try store.deleteAll()
            let verified = store.auditReadAll()
            guard verified.envelopes.isEmpty,
                  verified.byteCount == 0,
                  verified.isTrustworthy else {
                operationMessage = "삭제 확인에 실패했습니다. 원본 상태를 다시 확인하세요."
                return
            }
            refresh()
            operationMessage = "로컬 연구 데이터를 삭제했습니다."
        } catch {
            operationMessage = "삭제하지 못했습니다. 원본 데이터는 유지됩니다."
        }
    }

    func runCount(participant: String, variant: DescentResearchVariant) -> Int {
        report.runs.filter {
            $0.participantSlot == participant && $0.variant == variant
        }.count
    }

    private func makeCSVExportURL() -> URL? {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("descent-choice-research-summary.csv")
        do {
            try report.csvData().write(to: url, options: .atomic)
            return url
        } catch {
            operationMessage = "CSV 생성에 실패했습니다. 원본 JSONL은 변경되지 않았습니다."
            return nil
        }
    }
}

struct DescentResearchConsoleView: View {
    @StateObject private var model: DescentResearchConsoleModel
    @State private var confirmsDeletion = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(usesSampleData: Bool = false) {
        _model = StateObject(wrappedValue: DescentResearchConsoleModel(
            sampleEnvelopes: usesSampleData ? DescentResearchConsoleSample.make() : nil
        ))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GamePalette.canvas.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: GameSpacing.large) {
                        statusHeader
                        dataQualityBanner

                        if model.isEmpty {
                            emptyState
                        } else {
                            nextAssignmentCard
                            primaryMetrics
                            participantSection
                            dataActions
                        }

                        if let message = model.operationMessage {
                            Text(message)
                                .font(.footnote.weight(.bold))
                                .foregroundStyle(GamePalette.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(GameSpacing.medium)
                                .background(GamePalette.surface1, in: RoundedRectangle(cornerRadius: GameRadius.card))
                                .accessibilityIdentifier("researchOperationMessage")
                        }
                    }
                    .padding(.horizontal, GameSpacing.large)
                    .padding(.vertical, GameSpacing.medium)
                }
            }
            .navigationTitle("Choice Arena 연구")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(GamePalette.surface0, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        model.refresh()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("연구 데이터 새로고침")
                    .accessibilityIdentifier("researchRefreshButton")
                }
            }
        }
        .preferredColorScheme(.dark)
        .confirmationDialog(
            "로컬 연구 데이터를 영구 삭제할까요?",
            isPresented: $confirmsDeletion,
            titleVisibility: .visible
        ) {
            Button("모든 로컬 연구 데이터 삭제", role: .destructive) {
                model.deleteAll()
            }
            .accessibilityIdentifier("researchDeleteConfirmButton")
            Button("취소", role: .cancel) {}
        } message: {
            Text("현재 기기의 JSONL과 집계 대상 run이 삭제됩니다. 이 작업은 되돌릴 수 없습니다.")
        }
        .accessibilityIdentifier("researchConsole")
    }

    private var statusHeader: some View {
        HStack(alignment: .top, spacing: GameSpacing.medium) {
            VStack(alignment: .leading, spacing: 3) {
                Text("RESEARCH CONSOLE · DEBUG")
                    .font(.system(.headline, design: .monospaced, weight: .black))
                    .foregroundStyle(GamePalette.textPrimary)
                Text("판정 전 로컬 데이터 · 외부 전송 없음")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(GamePalette.textSecondary)
            }
            Spacer()
            Text(model.isSample ? "SAMPLE" : "LOCAL")
                .font(.system(.caption2, design: .monospaced, weight: .black))
                .foregroundStyle(GamePalette.warning)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(GamePalette.warning.opacity(0.12), in: Capsule())
                .overlay(Capsule().stroke(GamePalette.warning.opacity(0.65)))
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("researchConsoleHeading")
    }

    private var dataQualityBanner: some View {
        let empty = model.isEmpty
        let failed = !empty && model.totalViolationCount > 0
        let warning = !failed && model.isCapacityWarning
        let color = failed ? GamePalette.danger : (warning ? GamePalette.warning : GamePalette.success)
        let icon = failed ? "xmark.octagon.fill" : (warning ? "exclamationmark.triangle.fill" : "checkmark.shield.fill")
        let title = empty
            ? "DQ 대기 · 아직 run 없음"
            : (failed ? "DQ FAIL · \(model.totalViolationCount)건" : (warning ? "DQ 경고 · 저장 한도 접근" : "DQ 정상"))

        return HStack(spacing: GameSpacing.medium) {
            Image(systemName: icon)
                .font(.title3.weight(.black))
                .foregroundStyle(color)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(GamePalette.textPrimary)
                Text(dqDetail)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(GamePalette.textSecondary)
            }
            Spacer()
        }
        .frame(minHeight: 44)
        .padding(GameSpacing.medium)
        .background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: GameRadius.card))
        .overlay(RoundedRectangle(cornerRadius: GameRadius.card).stroke(color.opacity(0.75)))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("researchDQBanner")
    }

    private var dqDetail: String {
        if model.audit.readFailed { return "저장 파일을 읽을 수 없어 집계를 중단했습니다." }
        if model.audit.invalidLineCount > 0 || model.audit.futureSchemaLineCount > 0 {
            return "손상 \(model.audit.invalidLineCount) · 미래 schema \(model.audit.futureSchemaLineCount)"
        }
        return "\(model.audit.envelopes.count) runs · \(model.report.primary.dataQualityValidParticipantCount)/10 참가자 정상"
    }

    private var emptyState: some View {
        VStack(spacing: GameSpacing.medium) {
            Image(systemName: "tray")
                .font(.system(size: 36, weight: .black))
                .foregroundStyle(GamePalette.info)
            Text("아직 연구 런이 없습니다")
                .font(.title3.weight(.black))
                .foregroundStyle(GamePalette.textPrimary)
            Text("P01은 A(no-Arena) · ORDER 1부터 시작합니다.")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(GamePalette.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 220)
        .glassCard()
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("researchEmptyState")
    }

    private var nextAssignmentCard: some View {
        VStack(alignment: .leading, spacing: GameSpacing.medium) {
            HStack {
                Label(
                    nextAssignment == nil ? "REQUIRED RUNS COMPLETE" : "NEXT ASSIGNMENT",
                    systemImage: nextAssignment == nil ? "checkmark.seal.fill" : "person.crop.circle.badge.clock"
                )
                    .font(.system(.caption, design: .monospaced, weight: .black))
                    .foregroundStyle(GamePalette.warning)
                Spacer()
                if let assignment = nextAssignment {
                    Text(assignment.sequence.rawValue)
                        .font(.system(.caption, design: .monospaced, weight: .black))
                        .foregroundStyle(GamePalette.info)
                }
            }
            if let assignment = nextAssignment {
                Text("\(assignment.participant) · \(variantLabel(assignment.variant)) · ORDER \(assignment.order)")
                    .font(.title3.weight(.black))
                    .foregroundStyle(GamePalette.textPrimary)
                Text(assignment.arguments)
                    .font(.system(.caption2, design: .monospaced, weight: .semibold))
                    .foregroundStyle(GamePalette.textSecondary)
                    .textSelection(.enabled)
                HStack(spacing: GameSpacing.small) {
                    checklist("고정 seed")
                    checklist("동일 기체")
                    checklist("PB 0")
                }
            } else {
                Text("P01–P10의 A/B 필수 2회 수집 완료")
                    .font(.title3.weight(.black))
                    .foregroundStyle(GamePalette.textPrimary)
                Text("DQ가 정상일 때만 Primary를 판정하고, 선택 3회차는 ITT 분모 10명으로 집계합니다.")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(GamePalette.textSecondary)
            }
        }
        .padding(GameSpacing.large)
        .background(GamePalette.surface1, in: RoundedRectangle(cornerRadius: GameRadius.panel))
        .overlay(RoundedRectangle(cornerRadius: GameRadius.panel).stroke(GamePalette.warning.opacity(0.7)))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(nextAssignmentAccessibilityLabel)
        .accessibilityIdentifier("researchNextAssignmentCard")
    }

    @ViewBuilder
    private var primaryMetrics: some View {
        let cards = primaryCardData
        if dynamicTypeSize.isAccessibilitySize {
            VStack(spacing: GameSpacing.small) {
                ForEach(cards, id: \.id) { card in primaryCard(card) }
            }
        } else {
            HStack(spacing: GameSpacing.small) {
                ForEach(cards, id: \.id) { card in primaryCard(card) }
            }
        }
    }

    private var participantSection: some View {
        VStack(alignment: .leading, spacing: GameSpacing.small) {
            HStack {
                Text("PARTICIPANTS")
                    .font(.system(.caption, design: .monospaced, weight: .black))
                    .tracking(1)
                    .foregroundStyle(GamePalette.textMuted)
                Spacer()
                Text("분석 단위 N=10")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(GamePalette.textSecondary)
            }
            ForEach(model.report.participants, id: \.participantSlot) { participant in
                participantRow(participant)
            }
        }
        .accessibilityIdentifier("researchParticipantTable")
    }

    private var dataActions: some View {
        VStack(spacing: GameSpacing.medium) {
            if let exportURL = model.exportURL {
                ShareLink(
                    item: exportURL,
                    preview: SharePreview("Descent Choice 연구 요약 CSV")
                ) {
                    Label("요약 CSV 내보내기", systemImage: "square.and.arrow.up")
                        .font(.headline.weight(.black))
                        .foregroundStyle(GamePalette.deep)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(GamePalette.info, in: RoundedRectangle(cornerRadius: GameRadius.button))
                }
                .accessibilityIdentifier("researchExportButton")
            }

            Button(role: .destructive) {
                confirmsDeletion = true
            } label: {
                Label("로컬 연구 데이터 삭제", systemImage: "trash")
                    .font(.subheadline.weight(.black))
                    .frame(maxWidth: .infinity, minHeight: 48)
            }
            .buttonStyle(.bordered)
            .tint(GamePalette.danger)
            .disabled(model.isSample)
            .accessibilityHint("확인 후 현재 기기의 연구 JSONL을 삭제합니다")
            .accessibilityIdentifier("researchDeleteButton")
        }
    }

    private func primaryCard(_ card: PrimaryCard) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(card.title)
                .font(.system(.caption2, design: .monospaced, weight: .black))
                .foregroundStyle(GamePalette.textMuted)
            Text(card.value)
                .font(.headline.weight(.black))
                .foregroundStyle(card.color)
            Text("판정 보류 · \(model.report.primary.dataQualityValidParticipantCount)/10")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(GamePalette.textSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 76, alignment: .leading)
        .padding(GameSpacing.small)
        .background(GamePalette.surface1, in: RoundedRectangle(cornerRadius: GameRadius.card))
        .overlay(RoundedRectangle(cornerRadius: GameRadius.card).stroke(GamePalette.borderSubtle))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(card.id)
    }

    private func participantRow(_ participant: DescentResearchParticipantSummary) -> some View {
        let aRuns = model.runCount(participant: participant.participantSlot, variant: .noArena)
        let bRuns = model.runCount(participant: participant.participantSlot, variant: .choiceArena)
        let valid = participant.isDataQualityValid
        let color = valid ? GamePalette.success : GamePalette.warning
        return HStack(spacing: GameSpacing.medium) {
            Text(participant.participantSlot)
                .font(.system(.subheadline, design: .monospaced, weight: .black))
                .foregroundStyle(GamePalette.textPrimary)
                .frame(width: 38, alignment: .leading)
            Text(participant.sequence.rawValue)
                .font(.system(.caption, design: .monospaced, weight: .black))
                .foregroundStyle(GamePalette.info)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 3) {
                Text("A \(aRuns)회 · B \(bRuns)회")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(GamePalette.textPrimary)
                Text(valid ? "DQ 정상" : "DQ 확인 필요")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(color)
            }
            Spacer()
            Image(systemName: valid ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(color)
        }
        .frame(minHeight: dynamicTypeSize.isAccessibilitySize ? 88 : 60)
        .padding(.horizontal, GameSpacing.medium)
        .background(GamePalette.surface1.opacity(0.86), in: RoundedRectangle(cornerRadius: GameRadius.card))
        .overlay(RoundedRectangle(cornerRadius: GameRadius.card).stroke(GamePalette.borderSubtle))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(participant.participantSlot), 순서 \(participant.sequence.rawValue), A \(aRuns)회, B \(bRuns)회, \(valid ? "데이터 품질 정상" : "데이터 품질 확인 필요")")
        .accessibilityIdentifier("researchParticipant\(participant.participantSlot)")
    }

    private func checklist(_ text: String) -> some View {
        Label(text, systemImage: "checkmark.circle.fill")
            .font(.caption2.weight(.bold))
            .foregroundStyle(GamePalette.textSecondary)
    }

    private var primaryCardData: [PrimaryCard] {
        let primary = model.report.primary
        let atr = primary.choiceArenaRequiredRunMedianActiveTouchRatio
            .map { "\(Int(($0 * 100).rounded()))%" } ?? "—"
        return [
            PrimaryCard(
                id: "researchPrimaryRetryKPI",
                title: "3회차 완료 B/A",
                value: "\(primary.choiceArenaVoluntaryThirdRunCompletions)/\(primary.noArenaVoluntaryThirdRunCompletions)",
                color: GamePalette.warning
            ),
            PrimaryCard(
                id: "researchPrimaryScoreKPI",
                title: "+20% SCORE B/A",
                value: "\(primary.choiceArenaRun1ToRun3GainCount)/\(primary.noArenaRun1ToRun3GainCount)",
                color: GamePalette.fireCore
            ),
            PrimaryCard(
                id: "researchPrimaryTouchKPI",
                title: "ACTIVE TOUCH B",
                value: atr,
                color: GamePalette.info
            )
        ]
    }

    private var nextAssignment: Assignment? {
        for participant in model.report.participants {
            let ordered: [DescentResearchVariant] = participant.sequence == .ab
                ? [.noArena, .choiceArena]
                : [.choiceArena, .noArena]
            for variant in ordered {
                if model.runCount(participant: participant.participantSlot, variant: variant) < 2 {
                    let order = ordered.first == variant ? 1 : 2
                    return Assignment(
                        participant: participant.participantSlot,
                        sequence: participant.sequence,
                        variant: variant,
                        order: order
                    )
                }
            }
        }
        return nil
    }

    private var nextAssignmentAccessibilityLabel: String {
        guard let assignment = nextAssignment else {
            return "필수 런 수집 완료, P01부터 P10까지 A B 각 2회"
        }
        return "다음 배정, \(assignment.participant), \(variantLabel(assignment.variant)), 순서 \(assignment.order), \(assignment.sequence.rawValue)"
    }

    private func variantLabel(_ variant: DescentResearchVariant) -> String {
        variant == .noArena ? "A · NO ARENA" : "B · CHOICE"
    }

    private struct PrimaryCard {
        let id: String
        let title: String
        let value: String
        let color: Color
    }

    private struct Assignment {
        let participant: String
        let sequence: DescentResearchSequence
        let variant: DescentResearchVariant
        let order: Int

        var arguments: String {
            let variantArgument = variant == .noArena ? " -descentVariantNoArena" : ""
            return "-descentResearch\(variantArgument) -descentParticipant \(participant) -descentOrderIndex \(order)"
        }
    }
}

private enum DescentResearchConsoleSample {
    static func make() -> [DescentResearchRunEnvelope] {
        var envelopes: [DescentResearchRunEnvelope] = []
        for participantNumber in 1...10 {
            let participant = String(format: "P%02d", participantNumber)
            let sequence: DescentResearchSequence = participantNumber <= 5 ? .ab : .ba
            let seed = 0xD35C_EA71_2026_0000 ^ UInt64(participantNumber)
            let ship = DescentShipKind.allCases[(participantNumber - 1) % DescentShipKind.allCases.count]
            for variant in DescentResearchVariant.allCases {
                let order = (sequence == .ab) == (variant == .noArena) ? 1 : 2
                for runIndex in 1...2 {
                    envelopes.append(makeEnvelope(
                        participant: participant,
                        variant: variant,
                        order: order,
                        runIndex: runIndex,
                        seed: seed,
                        ship: ship,
                        continuesToThird: participantNumber <= (variant == .choiceArena ? 2 : 1)
                    ))
                }
                if participantNumber <= (variant == .choiceArena ? 2 : 1) {
                    envelopes.append(makeEnvelope(
                        participant: participant,
                        variant: variant,
                        order: order,
                        runIndex: 3,
                        seed: seed,
                        ship: ship,
                        continuesToThird: false
                    ))
                }
            }
        }
        return envelopes
    }

    private static func makeEnvelope(
        participant: String,
        variant: DescentResearchVariant,
        order: Int,
        runIndex: Int,
        seed: UInt64,
        ship: DescentShipKind,
        continuesToThird: Bool
    ) -> DescentResearchRunEnvelope {
        let previousBest = runIndex == 1 ? 0 : 1_100
        let bonus = variant == .choiceArena ? 100 : 0
        let comparableScore = runIndex == 3 ? 1_300 : (runIndex == 2 ? 1_100 : 1_000)
        var domainEvents: [DescentResearchEvent] = [.runStarted]
        if variant == .choiceArena {
            domainEvents.append(.choicePresented(tick: 3_600, score: 540))
            domainEvents.append(.choiceSelected(choice: .redline, activeLatencyMilliseconds: 1_200))
        }
        domainEvents.append(.inputSummary(DescentResearchInputSummary(
            firstMoveMilliseconds: 800,
            activeTouchMilliseconds: 38_000,
            activePlayMilliseconds: 60_000,
            meaningfulLaneChanges: 25
        )))
        if runIndex == 2 {
            domainEvents.append(.optionalRetryWindowOpened(durationMilliseconds: 60_000))
        }
        domainEvents.append(.runFinished(DescentResearchRunSummary(
            tick: 7_200,
            score: comparableScore + bonus,
            previousBestScore: previousBest,
            maxCombo: 18,
            dangerSaves: 3,
            dropsCollected: 3,
            breaches: 0,
            redlineBonusScore: bonus,
            endReason: .survivedSixtySeconds
        )))
        if runIndex == 2 {
            domainEvents.append(.resultAction(
                action: continuesToThird ? .retry : .home,
                latencyMilliseconds: continuesToThird ? 8_000 : 62_000
            ))
        }
        let events = domainEvents.enumerated().map {
            DescentResearchSequencedEvent(sequence: $0.offset, event: $0.element)
        }
        return DescentResearchRunEnvelope(
            context: DescentResearchContext(
                researchSessionID: UUID(),
                runID: UUID(),
                participantSlot: participant,
                orderIndex: order,
                variant: variant,
                seed: seed,
                ship: ship,
                runIndex: runIndex,
                bestScoreBefore: previousBest,
                rulesVersion: DescentResearchRules.currentVersion
            ),
            events: events
        )
    }
}
#endif
