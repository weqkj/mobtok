import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var state: AppState
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            Image("Logo").resizable().frame(width: 120, height: 120)
                .shadow(color: Palette.primary.opacity(0.35), radius: 24, y: 10).rise(0)
            Text("mobtok").font(.system(size: 36, weight: .bold, design: .rounded)).foregroundStyle(Palette.ink).padding(.top, 16).rise(1)
            Text("Соберите мод TikTok за пару минут — без компьютера и лишних шагов.")
                .font(.body).foregroundStyle(Palette.muted).multilineTextAlignment(.center)
                .padding(.top, 8).rise(2)
            Spacer()
            VStack(alignment: .leading, spacing: 18) {
                row("square.and.arrow.down", Palette.primary, "Свой IPA или установленный TikTok", "Перетащите файл или расшифруйте приложение")
                row("slider.horizontal.3", Palette.tertiary, "Настройки — прямо в TikTok", "Меню mobtok появится в настройках приложения")
                row("iphone", Color(hex: 0xD7BAFF), "Три способа установки", "Джейлбрейк, Sideloadly или сертификат")
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
                Text(t).font(.subheadline.weight(.semibold)).foregroundStyle(Palette.ink)
                Text(sub).font(.footnote).foregroundStyle(Palette.muted)
            }
        }
    }
}
