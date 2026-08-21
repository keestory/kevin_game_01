import Foundation

enum LocalResearchEventStoreError: Error, Equatable {
    case envelopeExceedsByteLimit
    case capacityExceeded
    case sourceContainsInvalidLines(Int)
    case sourceReadFailed
}

struct LocalResearchReadAudit: Equatable {
    let envelopes: [DescentResearchRunEnvelope]
    let invalidLineCount: Int
    let futureSchemaLineCount: Int
    let byteCount: Int
    let readFailed: Bool

    var isTrustworthy: Bool {
        !readFailed && invalidLineCount == 0 && futureSchemaLineCount == 0
    }
}

/// Research-build-only JSONL storage. Each line is one complete run and is
/// upserted by run ID, allowing the result action to be added without duplicates.
/// Corrupt or future-version lines are surfaced as a hard data-quality failure.
/// A write never rewrites or silently drops an unreadable source file.
@MainActor
final class LocalResearchEventStore: DescentResearchEventSink {
    static let defaultMaximumBytes = 1_000_000
    static let defaultMaximumRuns = 100

    let fileURL: URL
    private let maximumBytes: Int
    private let maximumRuns: Int
    private let encoder: JSONEncoder
    private let decoder = JSONDecoder()

    init(
        directoryURL: URL? = nil,
        maximumBytes: Int = defaultMaximumBytes,
        maximumRuns: Int = defaultMaximumRuns
    ) {
        let baseURL = directoryURL ?? FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0].appendingPathComponent("DescentResearch", isDirectory: true)
        self.fileURL = baseURL.appendingPathComponent("runs-v1.jsonl")
        self.maximumBytes = max(1, maximumBytes)
        self.maximumRuns = max(1, maximumRuns)
        self.encoder = JSONEncoder()
        self.encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
    }

    func persist(_ envelope: DescentResearchRunEnvelope) throws {
        let encodedEnvelope = try encoder.encode(envelope)
        guard encodedEnvelope.count + 1 <= maximumBytes else {
            throw LocalResearchEventStoreError.envelopeExceedsByteLimit
        }

        let audit = auditReadAll()
        guard !audit.readFailed else {
            throw LocalResearchEventStoreError.sourceReadFailed
        }
        let invalidCount = audit.invalidLineCount + audit.futureSchemaLineCount
        guard invalidCount == 0 else {
            throw LocalResearchEventStoreError.sourceContainsInvalidLines(invalidCount)
        }

        let replacesExistingRun = audit.envelopes.contains {
            $0.context.runID == envelope.context.runID
        }
        guard replacesExistingRun || audit.envelopes.count < maximumRuns else {
            throw LocalResearchEventStoreError.capacityExceeded
        }

        var envelopes = audit.envelopes.filter {
            $0.context.runID != envelope.context.runID
        }
        envelopes.append(envelope)

        let lines = try envelopes.map(encoder.encode)
        guard combinedSize(of: lines) <= maximumBytes else {
            throw LocalResearchEventStoreError.capacityExceeded
        }

        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        var output = Data()
        for line in lines {
            output.append(line)
            output.append(0x0A)
        }
        try output.write(to: fileURL, options: .atomic)
        try FileManager.default.setAttributes(
            [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
            ofItemAtPath: fileURL.path
        )
    }

    func readAll() -> [DescentResearchRunEnvelope] {
        auditReadAll().envelopes
    }

    func auditReadAll() -> LocalResearchReadAudit {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return LocalResearchReadAudit(
                envelopes: [],
                invalidLineCount: 0,
                futureSchemaLineCount: 0,
                byteCount: 0,
                readFailed: false
            )
        }

        let data: Data
        do {
            data = try Data(contentsOf: fileURL)
        } catch {
            return LocalResearchReadAudit(
                envelopes: [],
                invalidLineCount: 0,
                futureSchemaLineCount: 0,
                byteCount: 0,
                readFailed: true
            )
        }

        var envelopes: [DescentResearchRunEnvelope] = []
        var invalidLineCount = 0
        var futureSchemaLineCount = 0
        for line in data.split(separator: 0x0A) {
            guard let envelope = try? decoder.decode(
                DescentResearchRunEnvelope.self,
                from: Data(line)
            ) else {
                invalidLineCount += 1
                continue
            }
            guard envelope.schemaVersion == DescentResearchRunEnvelope.currentSchemaVersion else {
                futureSchemaLineCount += 1
                continue
            }
            envelopes.append(envelope)
        }

        return LocalResearchReadAudit(
            envelopes: envelopes,
            invalidLineCount: invalidLineCount,
            futureSchemaLineCount: futureSchemaLineCount,
            byteCount: data.count,
            readFailed: false
        )
    }

    func deleteAll() throws {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        try FileManager.default.removeItem(at: fileURL)
    }

    private func combinedSize(of lines: [Data]) -> Int {
        lines.reduce(0) { $0 + $1.count + 1 }
    }
}
