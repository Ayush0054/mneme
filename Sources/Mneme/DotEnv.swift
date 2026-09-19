import Foundation

enum DotEnv {
    /// Read only TYPESAFE_API_KEY. Never source the file or evaluate shell expressions.
    static func apiKey() throws -> String? {
        guard let resources = Bundle.main.resourceURL else { return nil }
        let location = resources.appendingPathComponent("project-path.txt")
        guard FileManager.default.fileExists(atPath: location.path) else { return nil }
        let root = try String(contentsOf: location, encoding: .utf8)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard root.hasPrefix("/") else {
            throw MnemeError.message("The project path is invalid. Package Mneme again.")
        }
        let file = URL(fileURLWithPath: root).appendingPathComponent(".env")
        guard FileManager.default.fileExists(atPath: file.path) else { return nil }
        let contents: String
        do {
            let handle = try FileHandle(forReadingFrom: file)
            defer { try? handle.close() }
            let data = try handle.read(upToCount: 65_537) ?? Data()
            guard data.count <= 65_536, let text = String(data: data, encoding: .utf8) else {
                throw MnemeError.message("Use a UTF-8 .env file smaller than 64 KB.")
            }
            contents = text
        } catch {
            throw MnemeError.message("Could not read the project's .env. Use a readable UTF-8 file smaller than 64 KB.")
        }
        var result: String?
        for rawLine in contents.split(whereSeparator: \.isNewline) {
            var line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            if line.hasPrefix("export ") { line = String(line.dropFirst(7)).trimmingCharacters(in: .whitespaces) }
            guard !line.hasPrefix("#"), let separator = line.firstIndex(of: "="),
                  line[..<separator].trimmingCharacters(in: .whitespaces) == "TYPESAFE_API_KEY" else { continue }
            var value = String(line[line.index(after: separator)...]).trimmingCharacters(in: .whitespaces)
            if let quote = value.first, quote == "\"" || quote == "'" {
                let rest = value.dropFirst()
                guard let end = rest.firstIndex(of: quote) else { throw invalidValue() }
                let suffix = rest[rest.index(after: end)...].trimmingCharacters(in: .whitespaces)
                guard suffix.isEmpty || suffix.hasPrefix("#") else { throw invalidValue() }
                value = String(rest[..<end])
            } else if let comment = value.range(of: #"\s+#"#, options: .regularExpression) {
                value = String(value[..<comment.lowerBound]).trimmingCharacters(in: .whitespaces)
            }
            guard value.unicodeScalars.count <= 8_192 else { throw invalidValue() }
            result = value.isEmpty ? nil : value
        }
        return result
    }

    private static func invalidValue() -> MnemeError {
        .message("Invalid TYPESAFE_API_KEY in .env. Use one line, with optional matching quotes.")
    }
}
