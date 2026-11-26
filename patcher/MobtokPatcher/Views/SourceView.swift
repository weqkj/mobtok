import SwiftUI
import UniformTypeIdentifiers

struct SourceView: View {
    @EnvironmentObject var state: AppState
    @State private var picking = false
    @State private var targeted = false
    @State private var error: String?

    private static let ipaType = UTType(filenameExtension: "ipa") ?? .data

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Источник").font(.system(size: 34, weight: .bold)).padding(.bottom, 20).rise(0)

            dropZone.rise(1)

            Text("ИЛИ ИЗ УСТАНОВЛЕННОГО")
                .font(.footnote).foregroundStyle(Palette.muted).padding(.top, 24).padding(.leading, 16).padding(.bottom, 6)
            installedRow.glass().rise(2)

            if let error {
                Text(error).font(.footnote).foregroundStyle(.red).padding(.top, 8).padding(.horizontal, 16)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            } else {
                Text("Нужен расшифрованный IPA. Патчер проверит версию перед сборкой.")
                    .font(.footnote).foregroundStyle(Palette.muted).padding(.top, 8).padding(.horizontal, 16)
            }
            Spacer()
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
                .foregroundStyle(state.sourceIPA == nil ? Palette.primary : .green)
                .symbolRenderingModeIfAvailable()
            Text(state.sourceIPA?.lastPathComponent ?? "Перетащите TikTok.ipa").font(.headline).lineLimit(1)
            Button("или выберите в Файлах") { picking = true }.font(.subheadline)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(.white.opacity(targeted ? 0.7 : 0.45)))
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
        HStack(spacing: 12) {
            IconTile(symbol: "lock.open", tint: .orange)
            VStack(alignment: .leading, spacing: 2) {
                Text("Расшифровать установленный TikTok")
                Text(Decryptor.isAvailable ? "Доступно через TrollStore" : "Нужен TrollStore или джейлбрейк")
                    .font(.footnote).foregroundStyle(Decryptor.isAvailable ? .green : Palette.muted)
            }
            Spacer()
            Button("Начать") {
                Task {
                    do { state.sourceIPA = try await Decryptor.decryptInstalled(bundleID: "com.zhiliaoapp.musically") }
                    catch { self.error = error.localizedDescription }
                }
            }
            .font(.subheadline.weight(.semibold)).padding(.horizontal, 16).padding(.vertical, 8)
            .background(Capsule().fill(Palette.primaryContainer)).disabled(!Decryptor.isAvailable)
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
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
