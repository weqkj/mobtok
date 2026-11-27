import SwiftUI
import CoreText

/// Google Sans (кириллица, 400/500/700) и Google Sans Flex Wide Black (латиница, широкий жирный).
/// Обе под SIL OFL 1.1 — тексты лицензий лежат рядом в Fonts/.
enum MTFont {
    static let regular = "mobtokSans-Regular"
    static let medium = "mobtokSans-Medium"
    static let bold = "mobtokSans-Bold"
    static let display = "mobtokDisplay-WideBlack"

    static func registerAll() {
        for name in ["GoogleSans-Regular", "GoogleSans-Medium", "GoogleSans-Bold", "GoogleSansFlex-WideBlack"] {
            guard let url = Bundle.main.url(forResource: name, withExtension: "ttf") else { continue }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}

extension Font {
    /// Основной шрифт интерфейса. Масштабируется с Dynamic Type.
    static func mt(_ size: CGFloat, _ weight: Font.Weight = .regular, relativeTo style: Font.TextStyle = .body) -> Font {
        let name = weight == .bold || weight == .heavy || weight == .black ? MTFont.bold
                 : weight == .medium || weight == .semibold ? MTFont.medium : MTFont.regular
        return .custom(name, size: size, relativeTo: style)
    }
    /// Широкий жирный Google Sans Flex — только для латиницы (логотип, бейджи).
    static func mtDisplay(_ size: CGFloat) -> Font { .custom(MTFont.display, size: size, relativeTo: .largeTitle) }

    static let mtTitle = Font.mt(34, .bold, relativeTo: .largeTitle)
    static let mtHeadline = Font.mt(17, .medium, relativeTo: .headline)
    static let mtBody = Font.mt(17, relativeTo: .body)
    static let mtSub = Font.mt(15, relativeTo: .subheadline)
    static let mtSubMedium = Font.mt(15, .medium, relativeTo: .subheadline)
    static let mtFoot = Font.mt(13, relativeTo: .footnote)
}
