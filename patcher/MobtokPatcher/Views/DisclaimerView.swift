import SwiftUI

enum Credits {
    static let author = "nebesnyy"
    static let telegram = URL(string: "https://t.me/SkyTok_Mod")!
    static let git = URL(string: "https://git.skytok.site/skytok/SkyTok")!
    static let site = URL(string: "https://skytok.site")!
}

struct DisclaimerView: View {
    @EnvironmentObject var state: AppState
    @State private var agree = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Прежде чем начать").font(.system(size: 30, weight: .bold, design: .rounded)).foregroundStyle(Palette.ink).rise(0)
            Text("Прочитайте и подтвердите").foregroundStyle(Palette.muted).padding(.bottom, 20).rise(0)

            VStack(alignment: .leading, spacing: 12) {
                Text("**Неофициальный мод.** mobtok не связан с ByteDance и TikTok. Используете на свой риск — аккаунт могут ограничить.")
                Text("**Вдохновлён SkyTok.** Идея — SkyTok от \(Credits.author). Код mobtok написан заново, из оригинала почти ничего не взято.")
            }
            .font(.subheadline).foregroundStyle(Palette.ink).padding(16).glass().rise(1)

            Text("АВТОР SKYTOK — \(Credits.author.uppercased())")
                .font(.footnote).foregroundStyle(Palette.muted).padding(.top, 22).padding(.leading, 16).padding(.bottom, 6)

            VStack(spacing: 0) {
                link("Telegram", Credits.telegram); Divider().overlay(Palette.outline.opacity(0.3)).padding(.leading, 16)
                link("Git", Credits.git); Divider().overlay(Palette.outline.opacity(0.3)).padding(.leading, 16)
                link("Сайт", Credits.site)
            }.glass().rise(2)

            Spacer()
            Toggle("Я понимаю и принимаю", isOn: $agree.animation(.spring())).tint(Palette.primary).foregroundStyle(Palette.ink).padding(.bottom, 16)
            Button("Принять") { state.accepted = true; state.go(.source) }
                .buttonStyle(PillButtonStyle()).disabled(!agree).opacity(agree ? 1 : 0.5).rise(3)
        }
        .padding(.horizontal, 20).padding(.top, 24).padding(.bottom, 12)
    }

    private func link(_ title: String, _ url: URL) -> some View {
        Link(destination: url) {
            HStack { Text(title).foregroundStyle(Palette.primary); Spacer(); Image(systemName: "chevron.right").foregroundStyle(.tertiary) }
                .padding(.horizontal, 16).frame(minHeight: 48).contentShape(Rectangle())
        }
    }
}
