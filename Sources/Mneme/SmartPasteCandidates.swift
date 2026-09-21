import Foundation

extension Candidate {
    /// Build exact source spans locally; Jev classifies which one fits the destination.
    static func values(from clips: [Clip], allowMultiline: Bool) -> [Candidate] {
        let groups = clips.prefix(12).map { clip -> [Candidate] in
            var values: [Candidate] = []
            var seen = Set<String>()
            func append(_ raw: String, label: String) {
                let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !text.isEmpty, text.unicodeScalars.count <= 1_200,
                      allowMultiline || text.rangeOfCharacter(from: .newlines) == nil,
                      values.count < 16, seen.insert(text).inserted else { return }
                values.append(Candidate(clip: clip, text: text, label: label, index: values.count))
            }

            let excerpt = clip.text.prefixScalars(1_200)
            let truncated = clip.text.unicodeScalars.count > 1_200
            var lines = excerpt.components(separatedBy: .newlines)
            // A truncated last line could contain only half a name/email/number.
            if truncated { lines.removeLast() }
            for line in lines {
                if let colon = line.firstIndex(of: ":") {
                    let label = String(line[..<colon]).trimmingCharacters(in: .whitespaces)
                    let value = String(line[line.index(after: colon)...]).trimmingCharacters(in: .whitespaces)
                    if !label.isEmpty, label.count <= 80,
                       label.rangeOfCharacter(from: .letters) != nil,
                       !value.isEmpty, !value.hasPrefix("//") {
                        append(value, label: label)
                        continue
                    }
                }
                append(line, label: "Line from copied text")
            }

            let patterns = [
                ("Email", #"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}"#),
                ("Phone", #"\+?\d[\d ()\-.]{6,}\d"#),
                ("Link", #"https?://[^\s<>\"]+"#)
            ]
            for (label, pattern) in patterns {
                guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
                for match in regex.matches(in: excerpt, range: NSRange(excerpt.startIndex..., in: excerpt)) {
                    guard let range = Range(match.range, in: excerpt),
                          !truncated || range.upperBound < excerpt.endIndex else { continue }
                    append(String(excerpt[range]), label: label)
                }
            }
            // Never offer a truncated whole item, or a multiline block to a single-line field.
            if !truncated { append(clip.text, label: "Whole copied text") }
            return values
        }

        var result: [Candidate] = []
        var seen = Set<String>()
        // Give every source coverage; identical values must not split Jev's probabilities.
        for index in 0..<16 {
            for group in groups where index < group.count {
                let candidate = group[index]
                guard seen.insert(candidate.text).inserted else { continue }
                result.append(candidate)
                if result.count == 60 { return result }
            }
        }
        return result
    }
}
