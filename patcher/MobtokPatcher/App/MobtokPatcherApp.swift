import SwiftUI

@main
struct MobtokPatcherApp: App {
    @StateObject private var state = AppState()

    init() { MTFont.registerAll() }
    var body: some Scene {
        WindowGroup {
            RootView().environmentObject(state)
                .preferredColorScheme(.dark)    // M3 тёмная схема поверх летающих фигур
                .tint(Palette.primary)
                .font(.mtBody)
        }
    }
}

enum Step: Int { case welcome, disclaimer, source, install }

@MainActor
final class AppState: ObservableObject {
    @AppStorage("mobtok.accepted") var accepted = false
    @Published var step: Step = .welcome
    @Published var sourceIPA: URL?
    @Published var job = PatchJob()

    init() { if accepted { step = .source } }

    func go(_ s: Step) {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.86)) { step = s }
    }
}

struct RootView: View {
    @EnvironmentObject var state: AppState
    var body: some View {
        ZStack {
            AuroraBackground()
            Group {
                switch state.step {
                case .welcome: WelcomeView()
                case .disclaimer: DisclaimerView()
                case .source: SourceView()
                case .install: InstallView()
                }
            }
            .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)))
        }
    }
}
