import SwiftUI

// MARK: - Палитра: Material You 3, тёмная схема из иконки (seed #FFD8E4)

enum Palette {
    static let surface          = Color(hex: 0x191113)
    static let surfaceHigh      = Color(hex: 0x2A1F22)
    static let primary          = Color(hex: 0xFFB0C8)   // кнопки, акценты
    static let onPrimary        = Color(hex: 0x3B1220)
    static let primaryContainer = Color(hex: 0x5E1133)
    static let onContainer      = Color(hex: 0xFFD8E4)
    static let tertiary         = Color(hex: 0xF0BC95)
    static let ink              = Color(hex: 0xF0DEE1)   // основной текст
    static let muted            = Color(hex: 0xD5C2C6)   // вторичный текст
    static let outline          = Color(hex: 0x9E8C90)
}

extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255, blue: Double(hex & 0xFF) / 255)
    }
}

// MARK: - Летающие фигуры M3 с motion blur

/// Физика фигур на фоне. Кнопки вызывают `kick()` — фигуры получают импульс,
/// разлетаются и плавно тормозят. Пока они быстрые, за ними тянется размытие.
@MainActor
final class ShapeField: ObservableObject {
    static let shared = ShapeField()

    struct Body {
        var kind: Int            // 0 cookie, 1 clover, 2 pill, 3 flower, 4 circle
        var color: Color
        var size: CGFloat
        var pos: CGPoint         // 0…1 относительно экрана
        var vel: CGVector        // доли экрана в секунду
        var angle: Double
        var spin: Double
    }

    private(set) var bodies: [Body] = [
        Body(kind: 0, color: Color(hex: 0x8C2F55), size: 230, pos: .init(x: 0.12, y: 0.10), vel: .init(dx: 0.012, dy: 0.008), angle: 0, spin: 0.10),
        Body(kind: 1, color: Color(hex: 0x6E3B8F), size: 190, pos: .init(x: 0.92, y: 0.30), vel: .init(dx: -0.010, dy: 0.010), angle: 1, spin: -0.08),
        Body(kind: 2, color: Color(hex: 0x8A4A2B), size: 170, pos: .init(x: 0.18, y: 0.70), vel: .init(dx: 0.008, dy: -0.010), angle: 0.6, spin: 0.06),
        Body(kind: 3, color: Color(hex: 0x5E1133), size: 260, pos: .init(x: 0.85, y: 0.88), vel: .init(dx: -0.008, dy: -0.006), angle: 2, spin: 0.05),
        Body(kind: 4, color: Color(hex: 0x7D2948), size: 120, pos: .init(x: 0.55, y: 0.50), vel: .init(dx: 0.010, dy: 0.012), angle: 0, spin: 0),
    ]
    private var last: Date?

    /// Импульс от нажатия: фигуры отталкиваются от точки (по умолчанию — низ экрана, где кнопки).
    func kick(from origin: CGPoint = .init(x: 0.5, y: 0.92), power: CGFloat = 0.9) {
        for i in bodies.indices {
            var d = CGVector(dx: bodies[i].pos.x - origin.x, dy: bodies[i].pos.y - origin.y)
            let len = max(0.15, sqrt(d.dx * d.dx + d.dy * d.dy))
            d = CGVector(dx: d.dx / len, dy: d.dy / len)
            bodies[i].vel.dx += d.dx * power / len * 0.35
            bodies[i].vel.dy += d.dy * power / len * 0.35
            bodies[i].spin += Double.random(in: -1.2...1.2)
        }
    }

    func step(to now: Date) {
        let dt = min(1.0 / 20, now.timeIntervalSince(last ?? now))
        last = now
        guard dt > 0 else { return }
        let drag = pow(0.18, dt)                 // плавное торможение после толчка
        for i in bodies.indices {
            var b = bodies[i]
            b.pos.x += b.vel.dx * dt; b.pos.y += b.vel.dy * dt
            b.angle += b.spin * dt
            // мягкие стенки: отскок с потерей энергии
            if b.pos.x < -0.05 || b.pos.x > 1.05 { b.vel.dx *= -0.7; b.pos.x = min(max(b.pos.x, -0.05), 1.05) }
            if b.pos.y < -0.05 || b.pos.y > 1.05 { b.vel.dy *= -0.7; b.pos.y = min(max(b.pos.y, -0.05), 1.05) }
            // скорость сходится к медленному дрейфу, а не к нулю
            let speed = sqrt(b.vel.dx * b.vel.dx + b.vel.dy * b.vel.dy)
            if speed > 0.015 { b.vel.dx *= drag; b.vel.dy *= drag }
            b.spin = b.spin * drag + (b.spin > 0 ? 0.05 : -0.05) * (1 - drag)
            bodies[i] = b
        }
    }

    static func path(kind: Int, size: CGFloat) -> Path {
        let r = size / 2
        switch kind {
        case 2: return Path(roundedRect: CGRect(x: -r, y: -r * 0.55, width: size, height: r * 1.1), cornerRadius: r * 0.55)
        case 4: return Path(ellipseIn: CGRect(x: -r, y: -r, width: size, height: size))
        default:
            // «печенька», «клевер» и «цветок» из M3 Expressive — синусоида по радиусу
            let (lobes, depth): (Double, Double) = kind == 0 ? (9, 0.07) : kind == 1 ? (4, 0.16) : (6, 0.12)
            var p = Path()
            for i in 0...120 {
                let t = Double(i) / 120 * 2 * .pi
                let rr = r * (1 - depth + depth * cos(lobes * t))
                let pt = CGPoint(x: rr * cos(t), y: rr * sin(t))
                i == 0 ? p.move(to: pt) : p.addLine(to: pt)
            }
            p.closeSubpath()
            return p
        }
    }
}

struct AuroraBackground: View {
    @ObservedObject private var field = ShapeField.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { ctx in
            Canvas { g, size in
                field.step(to: ctx.date)
                g.addFilter(.blur(radius: 28))
                for b in field.bodies {
                    let shape = ShapeField.path(kind: b.kind, size: b.size)
                    let speed = sqrt(b.vel.dx * b.vel.dx + b.vel.dy * b.vel.dy)
                    // Motion blur: копии вдоль скорости с затуханием, только когда фигура быстрая
                    let samples = speed > 0.04 ? min(8, Int(speed * 40)) : 0
                    for s in stride(from: samples, through: 0, by: -1) {
                        let k = Double(s) / 8
                        var t = g
                        t.translateBy(x: (b.pos.x - b.vel.dx * k * 0.12) * size.width,
                                      y: (b.pos.y - b.vel.dy * k * 0.12) * size.height)
                        t.rotate(by: .radians(b.angle - b.spin * k * 0.05))
                        t.opacity = s == 0 ? 0.85 : 0.85 * (1 - k) * 0.35
                        t.fill(shape, with: .color(b.color))
                    }
                }
            }
        }
        .background(Palette.surface)
        .ignoresSafeArea()
        // дышащее свечение сверху — как подсветка стекла
        .overlay(alignment: .top) {
            LinearGradient(colors: [Palette.primary.opacity(0.10), .clear], startPoint: .top, endPoint: .center)
                .ignoresSafeArea().allowsHitTesting(false)
        }
    }
}

// MARK: - Liquid Glass

struct GlassCard: ViewModifier {
    var radius: CGFloat = 28
    func body(content: Content) -> some View {
        content
            .background {
                let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
                shape.fill(.ultraThinMaterial)
                    .overlay(shape.fill(Palette.surfaceHigh.opacity(0.35)))
                    .overlay(shape.strokeBorder(LinearGradient(colors: [.white.opacity(0.35), .white.opacity(0.04), Palette.primary.opacity(0.25)],
                                                               startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1))
                    .shadow(color: .black.opacity(0.35), radius: 18, y: 10)
            }
    }
}

extension View {
    func glass(_ radius: CGFloat = 28) -> some View { modifier(GlassCard(radius: radius)) }
    func rise(_ index: Int) -> some View { modifier(Rise(index: index)) }
}

private struct Rise: ViewModifier {
    let index: Int
    @State private var shown = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown || reduceMotion ? 0 : 22)
            .blur(radius: shown || reduceMotion ? 0 : 6)          // въезд с размытием движения
            .scaleEffect(shown || reduceMotion ? 1 : 0.97)
            .onAppear {
                withAnimation(.spring(response: 0.62, dampingFraction: 0.8).delay(Double(index) * 0.06)) { shown = true }
            }
    }
}

// MARK: - Кнопки M3: таблетка, пружина, толчок фигур

struct PillButtonStyle: ButtonStyle {
    var filled = true
    func makeBody(configuration: Configuration) -> some View {
        PillBody(configuration: configuration, filled: filled)
    }

    private struct PillBody: View {
        let configuration: Configuration
        let filled: Bool
        @Environment(\.isEnabled) private var enabled
        var body: some View {
            configuration.label
                .font(.mt(17, .medium, relativeTo: .headline))
                .frame(maxWidth: .infinity, minHeight: 56)
                .foregroundStyle(filled ? Palette.onPrimary : Palette.onContainer)
                .background {
                    Capsule().fill(filled ? Palette.primary : Palette.primaryContainer.opacity(0.85))
                        .overlay(Capsule().strokeBorder(.white.opacity(filled ? 0.25 : 0.12), lineWidth: 1))
                }
                .clipShape(RoundedRectangle(cornerRadius: configuration.isPressed ? 18 : 28, style: .continuous))  // M3: форма «сжимается» при нажатии
                .scaleEffect(configuration.isPressed ? 0.96 : 1)
                .opacity(enabled ? 1 : 0.45)
                .animation(.spring(response: 0.32, dampingFraction: 0.6), value: configuration.isPressed)
                .onChange(of: configuration.isPressed) { pressed in
                    if pressed {
                        ShapeField.shared.kick()
                        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    }
                }
        }
    }
}

/// Нажатие с пружиной и толчком фигур — для строк списков и мелких кнопок.
struct BounceStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { p in if p { ShapeField.shared.kick(power: 0.4) } }
    }
}

struct IconTile: View {
    let symbol: String
    let tint: Color
    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 20, weight: .semibold))
            .foregroundStyle(tint)
            .frame(width: 48, height: 48)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(tint.opacity(0.18)))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(tint.opacity(0.25), lineWidth: 1))
            .accessibilityHidden(true)
    }
}
