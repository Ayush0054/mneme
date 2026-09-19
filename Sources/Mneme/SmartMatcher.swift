import Foundation
import Darwin

enum SmartMatcher {
    static func match(_ request: MatchRequest) async throws -> MatchResult {
        guard let resources = Bundle.main.resourceURL else {
            throw MnemeError.message("Launch the packaged Mneme.app.")
        }
        let helper = resources.appendingPathComponent("matcher.py")
        let configuration = resources.appendingPathComponent("python-path.txt")
        guard let python = try? String(contentsOf: configuration, encoding: .utf8)
            .trimmingCharacters(in: .whitespacesAndNewlines),
              FileManager.default.isExecutableFile(atPath: python) else {
            throw MnemeError.message("Python helper is not set up. Follow the setup steps in README.md.")
        }
        let payload = try JSONEncoder().encode(request)
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                let input = Pipe()
                let output = Pipe()
                process.executableURL = URL(fileURLWithPath: python)
                process.arguments = ["-I", helper.path]
                // Keep keys out of argv/environment; do not inherit SDK debug logging or a custom endpoint.
                process.environment = ["PATH": "/usr/bin:/bin", "LANG": "en_US.UTF-8",
                                       "TYPESAFE_LOG_LEVEL": "off", "PYTHONDONTWRITEBYTECODE": "1"]
                process.standardInput = input
                process.standardOutput = output
                process.standardError = FileHandle.nullDevice
                let timeout = DispatchWorkItem {
                    if process.isRunning { kill(process.processIdentifier, SIGKILL) }
                }
                do {
                    try process.run()
                    try? input.fileHandleForReading.close()
                    try? output.fileHandleForWriting.close()
                    // A helper that exits before reading must not deliver SIGPIPE to the app.
                    _ = fcntl(input.fileHandleForWriting.fileDescriptor, F_SETNOSIGPIPE, 1)
                    DispatchQueue.global().asyncAfter(deadline: .now() + 18, execute: timeout)
                    defer {
                        timeout.cancel()
                        try? input.fileHandleForWriting.close()
                        try? output.fileHandleForReading.close()
                    }
                    try input.fileHandleForWriting.write(contentsOf: payload)
                    try input.fileHandleForWriting.close()
                    // Helper emits one small JSON response, no logs or probability arrays.
                    process.waitUntilExit()
                    let data = output.fileHandleForReading.readDataToEndOfFile()
                    guard process.terminationStatus == 0, !data.isEmpty else {
                        throw MnemeError.message("Smart Paste timed out or the Python helper could not start.")
                    }
                    let result = try JSONDecoder().decode(MatchResult.self, from: data)
                    if let error = result.error { throw MnemeError.message(error) }
                    continuation.resume(returning: result)
                } catch {
                    timeout.cancel()
                    if process.isRunning { process.terminate() }
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
