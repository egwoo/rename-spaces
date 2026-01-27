import Foundation

final class AppLogger {
    static let shared = AppLogger()

    private let queue = DispatchQueue(label: "SpacesRenamer.AppLogger")
    private let fileHandle: FileHandle?
    private let fileURL: URL
    private let formatter: ISO8601DateFormatter

    private init() {
        let logDir = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("Logs/SpacesRenamer", isDirectory: true)
        if let logDir {
            try? FileManager.default.createDirectory(at: logDir, withIntermediateDirectories: true)
        }
        self.fileURL = logDir?.appendingPathComponent("app.log")
            ?? URL(fileURLWithPath: "/tmp/SpacesRenamer.log")

        if !FileManager.default.fileExists(atPath: fileURL.path) {
            FileManager.default.createFile(atPath: fileURL.path, contents: nil)
        }

        self.fileHandle = try? FileHandle(forWritingTo: fileURL)
        self.fileHandle?.seekToEndOfFile()
        self.formatter = ISO8601DateFormatter()
    }

    func log(_ message: String, level: String = "INFO") {
        let timestamp = formatter.string(from: Date())
        let line = "[\(timestamp)] [\(level)] \(message)\n"
        queue.async { [fileHandle] in
            guard let data = line.data(using: .utf8) else {
                return
            }
            fileHandle?.write(data)
        }
    }

    func logURL() -> URL {
        fileURL
    }
}
