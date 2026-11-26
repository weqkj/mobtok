import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var state: AppState
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            Image("Logo").resizable().frame(width: 96, height: 96)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .shadow(color: .black.opacity(0.25), radius: 12, y: 12).rise(0)
            Text("mobtok").font(.system(size: 34, weight: .bold)).padding(.top, 16).rise(1)
            Text("Соберите мод TikTok за пару минут — без компьютера и лишних шагов.")
                .font(.body).foregroundStyle(Palette.muted).multilineTextAlignment(.center)
                .padding(.top, 8).rise(2)
            Spacer()
            VStack(alignment: .leading, spacing: 18) {
                row("square.and.arrow.down", .blue, "Свой IPA или установленный TikTok", "Перетащите файл или расшифруйте приложение")
                row("slider.horizontal.3", .green, "Настройки — прямо в TikTok", "Меню mobtok появится в настройках приложения")
                row("iphone", .indigo, "Три способа установки", "Джейлбрейк, Sideloadly или сертификат")
            }.rise(3)
            Button("Продолжить") { state.go(.disclaimer) }
                .buttonStyle(PillButtonStyle()).padding(.top, 32).rise(4)
        }
        .padding(.horizontal, 20).padding(.bottom, 12)
    }

    private func row(_ s: String, _ c: Color, _ t: String, _ sub: String) -> some View {
        HStack(spacing: 14) {
            IconTile(symbol: s, tint: c)
            VStack(alignment: .leading, spacing: 2) {
                Text(t).font(.subheadline.weight(.semibold))
                Text(sub).font(.footnote).foregroundStyle(Palette.muted)
            }
        }
    }
}
