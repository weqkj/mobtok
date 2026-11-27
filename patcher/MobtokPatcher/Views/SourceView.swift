import SwiftUI
import UniformTypeIdentifiers

struct SourceView: View {
    @EnvironmentObject var state: AppState
    @State private var picking = false
    @State private var targeted = false
    @State private var error: String?
    @State private var link = ""
    @StateObject private var downloader = IPADownloader()

    private static let ipaType = UTType(filenameExtension: "ipa") ?? .data

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Источник").font(.system(size: 36, weight: .bold, design: .rounded)).foregroundStyle(Palette.ink).padding(.bottom, 20).rise(0)

            dropZone.rise(1)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    header("ИЛИ ПО ССЫЛКЕ")
                    urlRow.glass().rise(2)
                    header("ИЛИ ИЗ УСТАНОВЛЕННОГО")
                    installedRow.glass().rise(3)

            if let error {
                Text(error).font(.footnote).foregroundStyle(Color(hex: 0xFFB4AB)).padding(.top, 8).padding(.horizontal, 16)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            } else {
                Text("Нужен расшифрованный IPA. Патчер проверит версию перед сборкой.")
                    .font(.footnote).foregroundStyle(Palette.muted).padding(.top, 8).padding(.horizontal, 16)
            }
                }
            }
            Button("Далее") { state.go(.install) }
                .buttonStyle(PillButtonStyle()).disabled(state.sourceIPA == nil)
                .opacity(state.sourceIPA == nil ? 0.5 : 1).rise(4)
        }
        .padding(.horizontal, 20).padding(.top, 24).padding(.bottom, 12)
        .fileImporter(isPresented: $picking, allowedContentTypes: [Self.ipaType]) { accept($0) }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: error)
    }

    private var dropZone: some View {
        VStack(spacing: 8) {
            Image(systemName: state.sourceIPA == nil ? "square.and.arrow.up" : "checkmark.circle.fill")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(state.sourceIPA == nil ? Palette.primary : Palette.tertiary)
                .symbolRenderingModeIfAvailable()
            Text(state.sourceIPA?.lastPathComponent ?? "Перетащите TikTok.ipa").font(.headline).lineLimit(1)
                .foregroundStyle(Palette.ink)
            Button("или выберите в Файлах") { picking = true }.font(.subheadline)
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
                    Text("Расшифровать установленный TikTok").font(.body).foregroundStyle(Palette.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(Decryptor.isAvailable ? "Доступно через TrollStore" : "Нужен TrollStore или джейлбрейк")
                        .font(.footnote).foregroundStyle(Decryptor.isAvailable ? Palette.tertiary : Palette.muted)
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
                Text(downloader.status).font(.footnote).foregroundStyle(Palette.muted)
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
        Text(t).font(.footnote).foregroundStyle(Palette.muted)
            .padding(.top, 20).padding(.leading, 16).padding(.bottom, 6)
    }

    private func accept(_ r: Result<URL, Error>) {
        switch r {
        case .success(let url):
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            let dst = Workspace.inbox.appendingPathComponent("source.ipa")
            do {
                try? FileManager.default.removeItem(at: dst)
                try FileManager.default.copyItem(at: url, to: dst)
                withAnimation(.spring()) { state.sourceIPA = dst; error = nil }
            } catch { self.error = "Не удалось открыть файл: \(error.localizedDescription)" }
        case .failure(let e): error = e.localizedDescription
        }
    }
}

private extension View {
    @ViewBuilder func symbolRenderingModeIfAvailable() -> some View {
        if #available(iOS 17, *) { self.contentTransition(.symbolEffect(.replace)) } else { self }
    }
}
