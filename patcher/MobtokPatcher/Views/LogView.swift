import SwiftUI

struct LogView: View {
    @ObservedObject private var log = Log.shared
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Журнал").font(.mt(28, .bold, relativeTo: .title)).foregroundStyle(Palette.ink)
                Spacer()
                Button("Закрыть") { dismiss() }.font(.mtSubMedium)
            }
            ScrollView {
                Text(log.lines.isEmpty ? "Пока пусто" : log.text)
                    .font(.system(size: 12, design: .monospaced)).foregroundStyle(Palette.ink)
                    .frame(maxWidth: .infinity, alignment: .leading).textSelection(.enabled).padding(14)
            }
            .glass(20)
            HStack(spacing: 12) {
                Button("Копировать") { UIPasteboard.general.string = log.text }.buttonStyle(PillButtonStyle(filled: false))
                Button("Поделиться") { Installer.share(log.url) }.buttonStyle(PillButtonStyle())
            }
        }
        .padding(20).background(AuroraBackground()).preferredColorScheme(.dark)
    }
}

struct DecryptHelpView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Как расшифровать TikTok").font(.mt(26, .bold, relativeTo: .title)).foregroundStyle(Palette.ink)
                Text("Оригинал из App Store зашифрован Apple (FairPlay), в такой файл мод вшить нельзя. Нужна расшифрованная копия. Это нормально: так устроены все моды.")
                    .font(.mtSub).foregroundStyle(Palette.muted)
                step("1", "Есть TrollStore", "Поставьте TrollDecrypt, выберите TikTok, получите расшифрованный IPA и выберите его здесь.")
                step("2", "Есть джейлбрейк", "Используйте bfdecrypt или flexdecrypt: расшифрованный IPA появится в «Файлах».")
                step("3", "Нет ни того ни другого", "Расшифровку делают на ПК или у знакомых с джейлбрейком. TikTok нужен ровно той версии, которую ставите.")
                Text("Расшифрованный файл можно один раз сохранить и дальше собирать из него хоть каждый день.")
                    .font(.mtFoot).foregroundStyle(Palette.muted)
                Button("Понятно") { dismiss() }.buttonStyle(PillButtonStyle()).padding(.top, 8)
            }.padding(20)
        }
        .background(AuroraBackground()).preferredColorScheme(.dark)
    }
    private func step(_ n: String, _ t: String, _ s: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(n).font(.mt(17, .bold)).foregroundStyle(Palette.onPrimary).frame(width: 32, height: 32).background(Circle().fill(Palette.primary))
            VStack(alignment: .leading, spacing: 3) { Text(t).font(.mtHeadline).foregroundStyle(Palette.ink); Text(s).font(.mtSub).foregroundStyle(Palette.muted) }
        }.padding(14).frame(maxWidth: .infinity, alignment: .leading).glass(22)
    }
}
