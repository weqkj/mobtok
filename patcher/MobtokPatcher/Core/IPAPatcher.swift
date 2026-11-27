import Foundation
import ZIPFoundation

struct PatchError: LocalizedError {
    let errorDescription: String?
    init(_ s: String) { errorDescription = s }
}

/// Распаковка → проверка → копирование dylib в Frameworks → LC_LOAD_DYLIB → упаковка.
/// Всё на фоновом потоке; UI получает только прогресс.
struct IPAPatcher {
    let source: URL
    let dylib: URL?
    let workDir: URL
    let outDir: URL

    static let loadPath = "@executable_path/Frameworks/mobtok.dylib"

    /// Библиотеки, которые подгружают моды и инжекторы. Свои фреймворки TikTok
    /// подключены как *.framework и сюда не попадают.
    static let injectorNames = ["CydiaSubstrate", "libsubstrate", "libsubstitute", "substrate", "ellekit",
                                "libellekit", "libhooker", "Orion", "Cephei", "AltList"]

    static func isForeign(_ path: String) -> Bool {
        guard path.hasPrefix("@executable_path/") || path.hasPrefix("@rpath/") || path.hasPrefix("@loader_path/")
                || path.hasPrefix("/Library/MobileSubstrate") || path.hasPrefix("/var/jb") else { return false }
        if path == loadPath { return true }   // наш прошлый патч — переустановим заново
        let file = (path as NSString).lastPathComponent
        if file.hasSuffix(".dylib") { return true }
        return injectorNames.contains { path.localizedCaseInsensitiveContains($0) }
    }

    /// Убирает чужие моды: load-команды из бинарника и сами файлы из бандла.
    static func stripOtherMods(app: URL, binary: URL) throws -> [String] {
        let fm = FileManager.default
        let paths = try MachO.removeForeignDylibs(at: binary, isForeign: isForeign)
        var names: [String] = []
        for p in paths {
            var rel = p
            for prefix in ["@executable_path/", "@loader_path/"] where rel.hasPrefix(prefix) { rel.removeFirst(prefix.count) }
            if rel.hasPrefix("@rpath/") { rel = "Frameworks/" + rel.dropFirst("@rpath/".count) }
            if !rel.hasPrefix("/") {
                var file = app.appendingPathComponent(rel)
                // для фреймворка удаляем всю папку .framework
                if let r = rel.range(of: ".framework/") { file = app.appendingPathComponent(String(rel[..<r.lowerBound]) + ".framework") }
                try? fm.removeItem(at: file)
            }
            let n = (p as NSString).lastPathComponent
            if p != loadPath { names.append(n) }
        }
        // бандлы ресурсов модов и подписи
        for leftover in ["Frameworks/CydiaSubstrate.framework", "Frameworks/ellekit.framework", "_CodeSignature", "embedded.mobileprovision"] {
            try? fm.removeItem(at: app.appendingPathComponent(leftover))
        }
        return names
    }

    typealias Report = (Double, PatchJob.Phase, String) -> Void

    func run(report: @escaping Report) async throws -> URL {
        try await Task.detached(priority: .userInitiated) {
            let fm = FileManager.default
            let unpack = workDir.appendingPathComponent(UUID().uuidString)
            defer { try? fm.removeItem(at: unpack) }

            report(0.05, .unpacking, source.lastPathComponent)
            try fm.unzipItem(at: source, to: unpack)

            report(0.35, .checking, "Info.plist")
            let payload = unpack.appendingPathComponent("Payload")
            guard let app = try fm.contentsOfDirectory(at: payload, includingPropertiesForKeys: nil)
                .first(where: { $0.pathExtension == "app" }) else { throw PatchError("В IPA нет папки Payload/*.app") }
            let info = try PropertyListSerialization.propertyList(
                from: Data(contentsOf: app.appendingPathComponent("Info.plist")), format: nil) as? [String: Any] ?? [:]
            guard let exe = info["CFBundleExecutable"] as? String else { throw PatchError("Не найден CFBundleExecutable") }
            let version = info["CFBundleShortVersionString"] as? String ?? "?"
            let binary = app.appendingPathComponent(exe)
            if try MachO.isEncrypted(binary) { throw PatchError("IPA зашифрован. Нужен расшифрованный файл.") }

            report(0.45, .injecting, "Поиск других модов…")
            let removed = try Self.stripOtherMods(app: app, binary: binary)
            if !removed.isEmpty { report(0.5, .injecting, "Удалено: " + removed.joined(separator: ", ")) }

            report(0.55, .injecting, "TikTok \(version)")
            guard let dylib else { throw PatchError("mobtok.dylib не найден в сборке патчера") }
            let fw = app.appendingPathComponent("Frameworks", isDirectory: true)
            try fm.createDirectory(at: fw, withIntermediateDirectories: true)
            let dst = fw.appendingPathComponent("mobtok.dylib")
            try? fm.removeItem(at: dst)
            try fm.copyItem(at: dylib, to: dst)
            try MachO.insertLoadDylib(at: binary, path: Self.loadPath)

            report(0.75, .packing, "mobtok.ipa")
            let out = outDir.appendingPathComponent("mobtok-\(version).ipa")
            try? fm.removeItem(at: out)
            try fm.zipItem(at: payload, to: out, shouldKeepParent: true, compressionMethod: .deflate)
            report(1, .done, "Сохранено: \(out.lastPathComponent)")
            return out
        }.value
    }
}
