import SwiftUI

struct InstallView: View {
    @EnvironmentObject var state: AppState
    @State private var method: InstallMethod = .certificate
    @State private var certPicker = false
    @State private var log: [String] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Установка").font(.mt(36, .bold, relativeTo: .largeTitle)).foregroundStyle(Palette.ink).padding(.bottom, 20).rise(0)

            progressCard.glass().rise(1)

            Text("СПОСОБ УСТАНОВКИ").font(.mtFoot).foregroundStyle(Palette.muted)
                .padding(.top, 24).padding(.leading, 16).padding(.bottom, 6)
            VStack(spacing: 0) {
                ForEach(InstallMethod.allCases) { m in
                    Button { withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { method = m } } label: {
                        HStack(spacing: 12) {
                            IconTile(symbol: m.symbol, tint: m.tint)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(m.title).foregroundStyle(Palette.ink)
                                Text(m.subtitle).font(.mtFoot).foregroundStyle(Palette.muted)
                            }
                            Spacer()
                            if method == m {
                                Image(systemName: "checkmark").font(.mtHeadline).foregroundStyle(Palette.primary)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .padding(.horizontal, 16).padding(.vertical, 10).contentShape(Rectangle())
                    }
                    .buttonStyle(BounceStyle())
                    .accessibilityAddTraits(method == m ? .isSelected : [])
                    if m != InstallMethod.allCases.last { Divider().overlay(Palette.outline.opacity(0.3)).padding(.leading, 72) }
                }
            }.glass().rise(2)

            Text(method.hint).font(.mtFoot).foregroundStyle(Palette.muted)
                .padding(.top, 8).padding(.horizontal, 16).id(method).transition(.opacity)

            Spacer()
            Button(action: run) {
                Text(state.job.phase == .done ? method.cta : "Собрать мод")
            }
            .buttonStyle(PillButtonStyle()).disabled(state.job.isRunning).rise(3)
        }
        .padding(.horizontal, 20).padding(.top, 24).padding(.bottom, 12)
        .fileImporter(isPresented: $certPicker, allowedContentTypes: [.data], allowsMultipleSelection: true) { r in
            if case .success(let urls) = r { Task { await install(with: urls) } }
        }
    }

    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(state.job.phase.title)
                Spacer()
                if state.job.phase == .done { Text("mobtok.ipa").foregroundStyle(Palette.primary) }
            }.font(.mtSub).foregroundStyle(Palette.ink)
            ProgressView(value: state.job.progress).tint(state.job.phase == .failed ? Color(hex: 0xFFB4AB) : Palette.primary)
                .animation(.easeInOut(duration: 0.4), value: state.job.progress)
            Text(state.job.detail).font(.mtFoot).foregroundStyle(Palette.muted).fixedSize(horizontal: false, vertical: true).textSelection(.enabled)
        }.padding(16)
    }

    private func run() {
        if state.job.phase == .done {
            if method == .certificate { certPicker = true } else { Task { await install(with: []) } }
            return
        }
        guard let src = state.sourceIPA else { return }
        Task { await state.job.start(source: src) }
    }

    private func install(with files: [URL]) async {
        guard let out = state.job.output else { return }
        do { try await Installer.install(out, method: method, extra: files) }
        catch { state.job.fail(error.localizedDescription) }
    }
}
