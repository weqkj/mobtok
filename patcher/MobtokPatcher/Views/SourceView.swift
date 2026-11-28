import SwiftUI
import UniformTypeIdentifiers

struct SourceView: View {
    @EnvironmentObject var state: AppState
    @State private var picking = false
    @State private var targeted = false
    @State private var error: String?
    @State private var link = ""
    @State private var showLog = false
    @State private var showHelp = false
    @StateObject private var downloader = IPADownloader()

    private static let ipaType = UTType(filenameExtension: "ipa") ?? .data

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Источник").font(.mt(36, .bold, relativeTo: .largeTitle)).foregroundStyle(Palette.ink).padding(.bottom, 20).rise(0)

            dropZone.rise(1)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    header("ИЛИ ПО ССЫЛКЕ")
                    urlRow.glass().rise(2)
                    header("ИЛИ ИЗ УСТАНОВЛЕННОГО")
                    installedRow.glass().rise(3)

            if let error {
                Text(error).font(.mtFoot).foregroundStyle(Color(hex: 0xFFB4AB)).padding(.top, 8).padding(.horizontal, 16)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            } else {
                Text("Нужен расшифрованный IPA. Патчер проверит версию перед сборкой.")
                    .font(.mtFoot).foregroundStyle(Palette.muted).padding(.top, 8).padding(.horizontal, 16)
            }
                }
            }
            HStack { Button("Как расшифровать TikTok") { showHelp = true }; Spacer(); Button("Журнал") { showLog = true } }
                .font(.mtSub).padding(.horizontal, 16).padding(.bottom, 8)
            Button("Далее") { state.go(.install) }
                .buttonStyle(PillButtonStyle()).disabled(state.sourceIPA == nil)
                .opacity(state.sourceIPA == nil ? 0.5 : 1).rise(4)
        }
        .padding(.horizontal, 20).padding(.top, 24).padding(.bottom, 12)
        .sheet(isPresented: $picking) {
            DocumentPicker(onPick: { url in picking = false; accept(.success(url)) }, onCancel: { picking = false })
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: error)
        .sheet(isPresented: $showLog) { LogView() }
        .sheet(isPresented: $showHelp) { DecryptHelpView() }
    }

    private var dropZone: some View {
        VStack(spacing: 8) {
            Image(systemName: state.sourceIPA == nil ? "square.and.arrow.up" : "checkmark.circle.fill")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(state.sourceIPA == nil ? Palette.primary : Palette.tertiary)
                .symbolRenderingModeIfAvailable()
            Text(state.sourceIPA?.lastPathComponent ?? "Перетащите TikTok.ipa").font(.mtHeadline).lineLimit(1)
                .foregroundStyle(Palette.ink)
            Button("или выберите в Файлах") { picking = true }.font(.mtSub)
        }
        .frame(maxWidth: .infinity, minHeight: 170)
        .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(.ultraThinMaterial))
        .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous)
            .strokeBorder(Palette.primary.opacity(targeted ? 0.9 : 0.45), style: StrokeStyle(lineWidth: 1.5, dash: [6, 5])))
        .scaleEffect(targeted ? 1.02 : 1)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: targeted)
        .onDrop(of: [Self.ipaType], isTargeted: $targeted) { providers in
            providers.first?.loadFileRepresentation(forTypeIdentifier: Self.ipaType.identifier) { url, _ in
                guard let url else { return }
                let copy = FileManager.default.temporaryDirectory.appendingPathComponent(url.lastPathComponent)
                try? FileManager.default.removeItem(at: copy)
                try? FileManager.default.copyItem(at: url, to: copy)
                Task { @MainActor in accept(.success(copy)) }
            }
            return true
        }
    }

    private var installedRow: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                IconTile(symbol: "lock.open", tint: Palette.tertiary)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Расшифровать установленный TikTok").font(.mtBody).foregroundStyle(Palette.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(Decryptor.isAvailable ? "Доступно через TrollStore" : "Нужен TrollStore или джейлбрейк")
                        .font(.mtFoot).foregroundStyle(Decryptor.isAvailable ? Palette.tertiary : Palette.muted)
                }
            }
            Button("Расшифровать") {
                Task {
                    do { state.sourceIPA = try await Decryptor.decryptInstalled(bundleID: "com.zhiliaoapp.musically") }
                    catch { self.error = error.localizedDescription }
                }
            }
            .buttonStyle(PillButtonStyle(filled: false)).disabled(!Decryptor.isAvailable)
        }
        .padding(16)
    }

    private var urlRow: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                IconTile(symbol: "link", tint: Palette.primary)
                TextField("https://…/TikTok.ipa", text: $link)
                    .textInputAutocapitalization(.never).autocorrectionDisabled().keyboardType(.URL)
                    .foregroundStyle(Palette.ink)
            }
            if downloader.isRunning {
                ProgressView(value: downloader.progress).tint(Palette.primary)
                    .animation(.easeInOut(duration: 0.3), value: downloader.progress)
                Text(downloader.status).font(.mtFoot).foregroundStyle(Palette.muted)
            }
            Button(downloader.isRunning ? "Отменить" : "Скачать") {
                if downloader.isRunning { downloader.cancel(); return }
                guard let url = URL(string: link.trimmingCharacters(in: .whitespaces)),
                      ["http", "https"].contains(url.scheme?.lowercased() ?? "") else {
                    error = "Вставьте прямую ссылку на .ipa"; return
                }
                Task {
                    do { let file = try await downloader.download(url); accept(.success(file)) }
                    catch is CancellationError {}
                    catch { self.error = error.localizedDescription }
                }
            }
            .buttonStyle(PillButtonStyle(filled: false))
        }
        .padding(16)
    }

    private func header(_ t: String) -> some View {
        Text(t).font(.mtFoot).foregroundStyle(Palette.muted)
            .padding(.top, 20).padding(.leading, 16).padding(.bottom, 6)
    }

    private func accept(_ r: Result<URL, Error>) {
        switch r {
        case .failure(let e): error = e.localizedDescription
        case .success(let url):
            Task {
                do {
                    Log.shared.add("Выбран файл: \(url.lastPathComponent)")
                    let dst = try await Self.importFile(url)
                    Log.shared.add("Файл скопирован в рабочую папку")
                    withAnimation(.spring()) { state.sourceIPA = dst; error = nil }
                } catch { Log.shared.add("ОШИБКА импорта: \(error)"); self.error = "Не удалось открыть файл: \(error.localizedDescription)" }
            }
        }
    }

    /// Копирует выбранный файл в рабочую папку. Чтение идёт через NSFileCoordinator
    /// внутри security-scope: так работают iCloud, «На iPhone» и сторонние провайдеры.
    private static func importFile(_ url: URL) async throws -> URL {
        try await Task.detached(priority: .userInitiated) {
            let fm = FileManager.default
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            Log.write("Источник: \(url.path), существует: \(fm.fileExists(atPath: url.path))")
            let dst = Workspace.inbox.appendingPathComponent("\(UUID().uuidString).ipa")
            var lastError: Error = PatchError("Файл не скопировался")
            // 1) обычное копирование; 2) через координатор (подгружает файл из iCloud)
            for attempt in 0..<2 {
                do {
                    if attempt == 0 { try fm.copyItem(at: url, to: dst) }
                    else {
                        var ce: NSError?; var inner: Error?
                        NSFileCoordinator().coordinate(readingItemAt: url, options: [], error: &ce) { u in
                            do { try fm.copyItem(at: u, to: dst) } catch { inner = error }
                        }
                        if let e = ce ?? inner as NSError? { throw e }
                    }
                    break
                } catch { lastError = error; Log.write("Попытка \(attempt + 1) не удалась: \(error.localizedDescription)") }
            }
            guard fm.fileExists(atPath: dst.path) else { throw lastError }
            for f in (try? fm.contentsOfDirectory(at: Workspace.inbox, includingPropertiesForKeys: nil)) ?? [] where f.lastPathComponent != dst.lastPathComponent {
                try? fm.removeItem(at: f)
            }
            let size = (try? fm.attributesOfItem(atPath: dst.path)[.size] as? Int) ?? -1
            Log.write("Скопировано: \(size / 1_048_576) МБ → \(dst.lastPathComponent)")
            return dst
        }.value
    }
}

private extension View {
    @ViewBuilder func symbolRenderingModeIfAvailable() -> some View {
        if #available(iOS 17, *) { self.contentTransition(.symbolEffect(.replace)) } else { self }
    }
}
