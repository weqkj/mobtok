import Foundation
import SwiftUI

enum Workspace {
    static let root: URL = {
        let u = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return u
    }()
    static var inbox: URL { make("Inbox") }
    static var work: URL { make("Work") }
    static var output: URL { make("Output") }
    private static func make(_ n: String) -> URL {
        let u = root.appendingPathComponent(n, isDirectory: true)
        try? FileManager.default.createDirectory(at: u, withIntermediateDirectories: true)
        return u
    }
}

@MainActor
final class PatchJob: ObservableObject {
    enum Phase: Equatable {
        case idle, unpacking, checking, injecting, packing, done, failed
        var title: String {
            switch self {
            case .idle: return "Готово к сборке"
            case .unpacking: return "Распаковка…"
            case .checking: return "Проверка версии…"
            case .injecting: return "Внедрение mobtok…"
            case .packing: return "Упаковка…"
            case .done: return "Патч готов"
            case .failed: return "Ошибка"
            }
        }
    }
    @Published private(set) var phase: Phase = .idle
    @Published private(set) var progress: Double = 0
    @Published private(set) var detail = "Нажмите «Собрать мод»"
    private(set) var output: URL?
    var isRunning: Bool { ![.idle, .done, .failed].contains(phase) }

    func start(source: URL) async {
        let patcher = IPAPatcher(source: source,
                                 dylib: Bundle.main.url(forResource: "mobtok", withExtension: "dylib"),
                                 workDir: Workspace.work, outDir: Workspace.output)
        do {
            output = try await patcher.run { [weak self] p, ph, d in
                Task { @MainActor in self?.progress = p; self?.phase = ph; self?.detail = d }
            }
            phase = .done; progress = 1
        } catch { fail(error.localizedDescription) }
    }

    func fail(_ msg: String) { phase = .failed; detail = msg }
}
