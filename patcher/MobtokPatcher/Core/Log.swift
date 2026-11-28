import UIKit

/// Журнал патчера: пишется в Documents/mobtok.log и в память (для экрана «Журнал»).
@MainActor
final class Log: ObservableObject {
    static let shared = Log()
    @Published private(set) var lines: [String] = []
    let url = Workspace.root.appendingPathComponent("mobtok.log")

    private static let fmt: DateFormatter = { let f = DateFormatter(); f.dateFormat = "HH:mm:ss"; return f }()

    private init() {
        lines = ((try? String(contentsOf: url)) ?? "").split(separator: "\n").suffix(300).map(String.init)
        add("— запуск mobtok \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"), iOS \(UIDevice.current.systemVersion) —")
    }

    nonisolated static func write(_ s: String) { Task { @MainActor in shared.add(s) } }

    func add(_ s: String) {
        let line = "\(Self.fmt.string(from: Date())) \(s)"
        lines.append(line)
        if lines.count > 300 { lines.removeFirst(lines.count - 300) }
        if let h = try? FileHandle(forWritingTo: url) { h.seekToEndOfFile(); h.write(Data((line + "\n").utf8)); try? h.close() }
        else { try? (line + "\n").write(to: url, atomically: true, encoding: .utf8) }
    }

    func clear() { lines = []; try? FileManager.default.removeItem(at: url) }
    var text: String { lines.joined(separator: "\n") }
}
