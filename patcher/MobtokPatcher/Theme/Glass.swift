import SwiftUI

enum Palette {
    static let primary = Color(red: 0.04, green: 0.34, blue: 0.82)      // M3 tonal primary
    static let primaryContainer = Color(red: 0.84, green: 0.89, blue: 0.99)
    static let ink = Color(red: 0.11, green: 0.11, blue: 0.12)
    static let muted = Color(red: 0.27, green: 0.27, blue: 0.31)
}

/// Медленно плывущие цветные пятна под стеклом. Рисуется через Canvas + TimelineView,
/// без таймеров и без пересчёта layout — дёшево даже на старых устройствах.
struct AuroraBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        TimelineView(.animation(minimumInterval: 1/30, paused: reduceMotion)) { ctx in
            let t = ctx.date.timeIntervalSinceReferenceDate / 7
            Canvas { g, size in
                g.addFilter(.blur(radius: 60))
                let blobs: [(Color, CGFloat, CGPoint)] = [
                    (Color(red: 0.54, green: 0.71, blue: 1.0), 340, CGPoint(x: 0.1 + 0.08 * sin(t), y: 0.05 + 0.05 * cos(t))),
                    (Color(red: 0.79, green: 0.72, blue: 1.0), 300, CGPoint(x: 0.95 - 0.07 * cos(t * 0.8), y: 0.95 - 0.06 * sin(t))),
                ]
                for (c, d, p) in blobs {
                    let r = CGRect(x: p.x * size.width - d/2, y: p.y * size.height - d/2, width: d, height: d)
                    g.fill(Path(ellipseIn: r), with: .color(c))
                }
            }
        }
        .background(Color(red: 0.93, green: 0.95, blue: 0.98))
        .ignoresSafeArea()
    }
}

/// Liquid Glass: на iOS 26+ системный эффект, ниже — материал + блик по краю.
struct GlassCard: ViewModifier {
    var radius: CGFloat = 24
    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .strokeBorder(LinearGradient(colors: [.white.opacity(0.9), .white.opacity(0.2)],
                                                         startPoint: .top, endPoint: .bottom), lineWidth: 1)
                    )
                    .shadow(color: Color(red: 0.16, green: 0.24, blue: 0.47).opacity(0.10), radius: 12, y: 8)
            }
    }
}

extension View {
    func glass(_ radius: CGFloat = 24) -> some View { modifier(GlassCard(radius: radius)) }

    /// Каскадное появление: index задаёт задержку.
    func rise(_ index: Int) -> some View { modifier(Rise(index: index)) }
}

private struct Rise: ViewModifier {
    let index: Int
    @State private var shown = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown || reduceMotion ? 0 : 18)
            .scaleEffect(shown || reduceMotion ? 1 : 0.98)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.82).delay(Double(index) * 0.06)) { shown = true }
            }
    }
}

/// M3 «таблетка» с пружинным нажатием.
struct PillButtonStyle: ButtonStyle {
    var filled = true
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold))
            .frame(maxWidth: .infinity, minHeight: 56)
            .foregroundStyle(filled ? Color.white : Palette.primary)
            .background(Capsule().fill(filled ? Palette.primary : Palette.primaryContainer))
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .brightness(configuration.isPressed ? -0.05 : 0)
            .animation(.spring(response: 0.35, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct IconTile: View {
    let symbol: String
    let tint: Color
    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 20, weight: .medium))
            .foregroundStyle(tint)
            .frame(width: 44, height: 44)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(tint.opacity(0.18)))
            .accessibilityHidden(true)
    }
}
