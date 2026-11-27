import SwiftUI
import UIKit

enum InstallMethod: String, CaseIterable, Identifiable {
    case jailbreak, sideloadly, certificate
    var id: String { rawValue }
    var title: String {
        switch self { case .jailbreak: return "Джейлбрейк / TrollStore"; case .sideloadly: return "Через ПК — Sideloadly"; case .certificate: return "Подписать сертификатом" }
    }
    var subtitle: String {
        switch self { case .jailbreak: return "Без перевыпуска"; case .sideloadly: return "Сохранить IPA и поставить с ПК"; case .certificate: return "Свой .p12 + mobileprovision" }
    }
    var hint: String {
        switch self {
        case .jailbreak: return "IPA откроется в TrollStore, если он установлен."
        case .sideloadly: return "IPA сохранится в Файлы. Откройте его в Sideloadly на ПК."
        case .certificate: return "Выберите .p12 и .mobileprovision. Пароль хранится только в связке ключей."
        }
    }
    var cta: String {
        switch self { case .jailbreak: return "Установить"; case .sideloadly: return "Сохранить IPA"; case .certificate: return "Выбрать сертификат" }
    }
    var symbol: String {
        switch self { case .jailbreak: return "lock.open"; case .sideloadly: return "laptopcomputer"; case .certificate: return "checkmark.shield" }
    }
    var tint: Color {
        switch self { case .jailbreak: return Palette.tertiary; case .sideloadly: return Color(hex: 0xD7BAFF); case .certificate: return Palette.primary }
    }
}

enum Installer {
    @MainActor
    static func install(_ ipa: URL, method: InstallMethod, extra: [URL]) async throws {
        switch method {
        case .jailbreak:
            // TrollStore принимает IPA через свою URL-схему.
            let url = URL(string: "apple-magnifier://install?url=\(ipa.absoluteString)")!
            guard UIApplication.shared.canOpenURL(url) else { throw PatchError("TrollStore не найден") }
            await UIApplication.shared.open(url)
        case .sideloadly:
            share(ipa)
        case .certificate:
            // Подпись на устройстве делается внешней библиотекой (zsign) — см. README, «Подпись».
            guard extra.contains(where: { $0.pathExtension == "p12" }),
                  extra.contains(where: { $0.pathExtension == "mobileprovision" })
            else { throw PatchError("Нужны оба файла: .p12 и .mobileprovision") }
            throw PatchError("Подпись на устройстве подключается вместе с zsign — см. README")
        }
    }

    @MainActor
    private static func share(_ url: URL) {
        let vc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        UIApplication.shared.connectedScenes.compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first?.rootViewController?.present(vc, animated: true)
    }
}

enum Decryptor {
    /// Расшифровка установленного TikTok работает только с правами TrollStore/джейлбрейка.
    static var isAvailable: Bool { UIApplication.shared.canOpenURL(URL(string: "apple-magnifier://")!) }

    static func decryptInstalled(bundleID: String) async throws -> URL {
        throw PatchError("Расшифровка подключается отдельным модулем (TrollDecrypt-совместимым) — см. README")
    }
}
