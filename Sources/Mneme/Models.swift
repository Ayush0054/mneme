import Foundation

struct Clip: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let text: String
    let source: String
    let copiedAt: Date

    init(text: String, source: String) {
        id = UUID()
        self.text = text
        self.source = source
        copiedAt = Date()
    }

    var preview: String { String(text.prefix(240)).replacingOccurrences(of: "\n", with: "  ↵  ") }
}

struct FieldContext: Codable, Equatable, Sendable {
    let app: String
    let role: String
    let label: String
    let placeholder: String
    let help: String

    var hasClues: Bool { !label.isEmpty || !placeholder.isEmpty || !help.isEmpty }
    var displayName: String { !label.isEmpty ? label : (!placeholder.isEmpty ? placeholder : "Text field") }
}

struct Candidate: Encodable, Sendable {
    let id: String
    let text: String
    let source: String
    let label: String

    init(clip: Clip, text: String, label: String, index: Int) {
        id = "\(clip.id.uuidString):\(index)"
        self.text = text
        source = clip.source.prefixScalars(300)
        self.label = label.prefixScalars(300)
    }
}

extension String {
    // Match Python's Unicode code-point limit without cutting through a UTF-8 sequence.
    func prefixScalars(_ count: Int) -> String {
        String(String.UnicodeScalarView(unicodeScalars.prefix(count)))
    }
}

struct MatchRequest: Encodable, Sendable {
    let apiKey: String
    let field: FieldContext
    let candidates: [Candidate]
}

struct MatchResult: Decodable, Sendable {
    let choice: String?
    let confidence: Double?
    let probabilities: [String: Double]?
    let error: String?
}

enum MnemeError: LocalizedError {
    case message(String)
    var errorDescription: String? {
        switch self { case .message(let message): return message }
    }
}
