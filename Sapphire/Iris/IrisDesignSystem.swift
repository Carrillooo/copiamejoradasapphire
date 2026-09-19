//
//  IrisDesignSystem.swift
//  Iris
//
//  Los fundamentos visuales de Iris: color, tipografía, espaciado, forma,
//  material y movimiento. Todo lo demás de la interfaz se construye sobre esto,
//  para que no haya un solo valor puesto a ojo.
//
//  Sigue los principios de diseño de Apple (Designing Fluid Interfaces,
//  The Details of UI Typography, Principles of Great Design):
//
//  · El movimiento se describe con muelles, no con duraciones. Un muelle es
//    interrumpible y conserva la velocidad; una animación de duración fija, no.
//  · El rebote se reserva para lo que venía con impulso (un arrastre, un
//    lanzamiento). Lo que sólo aparece, aparece sin rebotar.
//  · El interlineado y el tracking dependen del tamaño: texto grande más
//    apretado, texto pequeño más suelto. Un valor fijo está mal en algún sitio.
//  · El peso del material marca la jerarquía. Nunca se apila un material claro
//    sobre otro claro: la legibilidad se hunde.
//  · Reducir movimiento, reducir transparencia y aumentar contraste no son
//    casos límite: se comprueban aquí, en la base.
//

import SwiftUI
import AppKit

public enum Iris {}

// MARK: - Accesibilidad del sistema

public extension Iris {
    /// Preferencias de accesibilidad de macOS, consultadas en el momento.
    enum A11y {
        public static var reduceMotion: Bool {
            NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        }
        public static var reduceTransparency: Bool {
            NSWorkspace.shared.accessibilityDisplayShouldReduceTransparency
        }
        public static var increaseContrast: Bool {
            NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast
        }
    }
}

// MARK: - Color

public extension Iris {
    enum Palette {
        /// Construye un color que se resuelve solo en claro y oscuro.
        static func dynamic(light: NSColor, dark: NSColor) -> Color {
            Color(nsColor: NSColor(name: nil) { appearance in
                appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? dark : light
            })
        }

        private static func srgb(_ r: Int, _ g: Int, _ b: Int, _ a: CGFloat = 1) -> NSColor {
            NSColor(srgbRed: CGFloat(r) / 255, green: CGFloat(g) / 255,
                    blue: CGFloat(b) / 255, alpha: a)
        }

        // --- Identidad -----------------------------------------------------
        // El violeta del iris. En oscuro sube en luminosidad: el mismo tono
        // sobre fondo negro se percibe más apagado y hay que compensarlo.
        public static let accent = dynamic(light: srgb(99, 61, 227),
                                           dark:  srgb(167, 139, 250))
        public static let accentMuted = dynamic(light: srgb(99, 61, 227, 0.12),
                                                dark:  srgb(167, 139, 250, 0.18))

        // --- Texto ---------------------------------------------------------
        // Sobre material translúcido el gris plano pierde contraste, así que el
        // secundario y el terciario no bajan tanto como en una superficie opaca.
        public static let textPrimary = dynamic(light: srgb(17, 17, 22),
                                                dark:  srgb(245, 245, 250))
        public static let textSecondary = dynamic(light: srgb(17, 17, 22, 0.66),
                                                  dark:  srgb(245, 245, 250, 0.72))
        public static let textTertiary = dynamic(light: srgb(17, 17, 22, 0.42),
                                                 dark:  srgb(245, 245, 250, 0.48))

        // --- Superficies ---------------------------------------------------
        public static let surfaceBase = dynamic(light: srgb(246, 246, 249),
                                                dark:  srgb(18, 18, 22))
        public static let surfaceRaised = dynamic(light: srgb(255, 255, 255),
                                                  dark:  srgb(30, 30, 36))
        public static let surfaceSunken = dynamic(light: srgb(238, 238, 243),
                                                  dark:  srgb(12, 12, 15))

        /// Relleno sutil para elevar un elemento sobre su superficie. Sustituye
        /// a los `Color.white.opacity(0.06…0.12)` sueltos, que en apariencia
        /// clara eran blanco sobre blanco, es decir, invisibles.
        ///
        /// En claro tira a blanco y en oscuro aclara: elevar es acercarse a la
        /// luz. Tiene que verse DISTINTO de `fillSunken` en las dos
        /// apariencias; con los valores anteriores (negro 5% y negro 4,5%) en
        /// claro eran indistinguibles, que es lo que se vio al renderizarlos.
        public static let fillElevated = dynamic(light: srgb(255, 255, 255, 0.92),
                                                 dark:  srgb(255, 255, 255, 0.08))
        /// Relleno hundido, para pozos y campos. Sustituye a los
        /// `Color.black.opacity(0.15…0.2)`, que en clara eran un velo gris.
        public static let fillSunken = dynamic(light: srgb(0, 0, 0, 0.085),
                                               dark:  srgb(0, 0, 0, 0.32))
        /// Contenido sobre un relleno de color saturado (insignias, degradados).
        /// Aquí el blanco sí es correcto, y conviene que se note que es
        /// deliberado y no un color fijo olvidado.
        public static let onAccent = Color.white

        // --- Bordes --------------------------------------------------------
        /// El borde superior claro simula la luz que engancha el canto del
        /// material. Con «aumentar contraste» se vuelve un borde definido.
        public static var hairline: Color {
            A11y.increaseContrast
                ? dynamic(light: srgb(0, 0, 0, 0.55), dark: srgb(255, 255, 255, 0.55))
                : dynamic(light: srgb(0, 0, 0, 0.10), dark: srgb(255, 255, 255, 0.12))
        }

        // --- Estado --------------------------------------------------------
        public static let success = dynamic(light: srgb(20, 133, 74),  dark: srgb(61, 214, 140))
        public static let warning = dynamic(light: srgb(176, 104, 4),  dark: srgb(245, 185, 66))
        public static let danger  = dynamic(light: srgb(191, 43, 43),  dark: srgb(255, 118, 118))
    }
}

// MARK: - Tipografía

public extension Iris {
    /// Escala tipográfica. Tamaño, peso, tracking e interlineado se definen
    /// juntos: el tracking correcto depende del tamaño, y un valor único para
    /// toda la interfaz está mal en algún sitio.
    struct TextStyle {
        public let size: CGFloat
        public let weight: Font.Weight
        public let tracking: CGFloat
        public let lineSpacing: CGFloat
        public let design: Font.Design

        public var font: Font { .system(size: size, weight: weight, design: design) }
    }

    enum Typography {
        // Texto grande: tracking negativo. Al crecer, las letras se perciben
        // demasiado separadas y hay que cerrarlas.
        public static let display = TextStyle(size: 34, weight: .bold, tracking: -0.7,
                                              lineSpacing: 1, design: .rounded)
        public static let title = TextStyle(size: 22, weight: .semibold, tracking: -0.35,
                                            lineSpacing: 2, design: .rounded)
        public static let headline = TextStyle(size: 16, weight: .semibold, tracking: -0.1,
                                               lineSpacing: 2, design: .default)
        // Cuerpo: tracking casi nulo, interlineado holgado.
        public static let body = TextStyle(size: 13, weight: .regular, tracking: 0,
                                           lineSpacing: 4, design: .default)
        public static let callout = TextStyle(size: 12, weight: .medium, tracking: 0.05,
                                              lineSpacing: 3, design: .default)
        // Texto pequeño: tracking positivo para que no se empaste.
        public static let caption = TextStyle(size: 11, weight: .regular, tracking: 0.15,
                                              lineSpacing: 2, design: .default)
        public static let mono = TextStyle(size: 12, weight: .medium, tracking: 0,
                                           lineSpacing: 2, design: .monospaced)
    }
}

public extension View {
    /// Aplica un estilo tipográfico completo: fuente, tracking e interlineado.
    func irisText(_ style: Iris.TextStyle, color: Color? = nil) -> some View {
        self.font(style.font)
            .tracking(style.tracking)
            .lineSpacing(style.lineSpacing)
            .foregroundStyle(color ?? Iris.Palette.textPrimary)
    }
}

// MARK: - Espaciado y forma

public extension Iris {
    /// Escala de espaciado. Todo múltiplo de 4: dos valores contiguos nunca se
    /// confunden, y nada queda «casi alineado».
    enum Spacing {
        public static let xxs: CGFloat = 2
        public static let xs: CGFloat = 4
        public static let sm: CGFloat = 8
        public static let md: CGFloat = 12
        public static let lg: CGFloat = 16
        public static let xl: CGFloat = 24
        public static let xxl: CGFloat = 32
        public static let xxxl: CGFloat = 48
    }

    enum Radius {
        public static let sm: CGFloat = 8
        public static let md: CGFloat = 12
        public static let lg: CGFloat = 18
        public static let xl: CGFloat = 26
        public static let pill: CGFloat = 999

        /// Radio interior concéntrico: un elemento metido dentro de otro tiene
        /// que ceder exactamente el hueco que lo separa del borde, o las
        /// curvas no quedan paralelas.
        public static func concentric(outer: CGFloat, inset: CGFloat) -> CGFloat {
            max(0, outer - inset)
        }
    }
}

// MARK: - Movimiento

public extension Iris {
    /// Muelles, no duraciones. Los valores son los que usa Apple:
    /// reposicionar 1.0/0.4, rotación 0.8/0.4, panel 0.8/0.3.
    enum Motion {
        /// Por defecto: críticamente amortiguado, sin rebote. Para lo que
        /// simplemente aparece, cambia o se recoloca.
        public static var standard: Animation {
            A11y.reduceMotion ? .easeOut(duration: 0.2)
                              : .spring(response: 0.4, dampingFraction: 1.0)
        }
        /// Rápido, para respuestas a una pulsación.
        public static var snappy: Animation {
            A11y.reduceMotion ? .easeOut(duration: 0.15)
                              : .spring(response: 0.28, dampingFraction: 1.0)
        }
        /// Con rebote. SÓLO cuando el gesto traía impulso: un lanzamiento, un
        /// arrastre soltado. Rebotar en un menú que sólo se abre se siente mal.
        public static var momentum: Animation {
            A11y.reduceMotion ? .easeOut(duration: 0.2)
                              : .spring(response: 0.4, dampingFraction: 0.8)
        }
        /// Paneles y cajones.
        public static var sheet: Animation {
            A11y.reduceMotion ? .easeOut(duration: 0.2)
                              : .spring(response: 0.3, dampingFraction: 0.8)
        }

        /// Proyecta dónde acabaría algo lanzado a esta velocidad, para decidir
        /// el destino a partir de la trayectoria y no del punto de suelta.
        /// Es la fórmula de decaimiento exponencial del scroll, no v²/2a.
        public static func project(velocity: CGFloat, decelerationRate: CGFloat = 0.998) -> CGFloat {
            (velocity / 1000) * decelerationRate / (1 - decelerationRate)
        }

        /// Resistencia progresiva al pasarse de un borde: se frena, no se topa.
        public static func rubberband(overshoot: CGFloat, dimension: CGFloat,
                                      constant: CGFloat = 0.55) -> CGFloat {
            guard dimension > 0 else { return 0 }
            return (overshoot * dimension * constant) / (dimension + constant * abs(overshoot))
        }
    }
}

// MARK: - Materiales

public extension Iris {
    /// Nivel del material. El peso marca la jerarquía: lo estructural pesa
    /// más, lo interactivo pesa menos y atrae la mirada.
    enum SurfaceLevel {
        case chrome      // barras y estructura
        case panel       // paneles y hojas
        case control     // controles flotantes
        case overlay     // lo que se superpone a todo

        var material: Material {
            switch self {
            case .chrome:  return .ultraThickMaterial
            case .panel:   return .thickMaterial
            case .control: return .regularMaterial
            case .overlay: return .ultraThinMaterial
            }
        }

        /// Las superficies grandes leen como más gruesas: sombra más profunda.
        var shadowRadius: CGFloat {
            switch self {
            case .chrome:  return 18
            case .panel:   return 24
            case .control: return 10
            case .overlay: return 30
            }
        }

        var shadowOpacity: Double {
            switch self {
            case .chrome:  return 0.18
            case .panel:   return 0.22
            case .control: return 0.12
            case .overlay: return 0.28
            }
        }
    }
}

private struct IrisSurface<S: InsettableShape>: ViewModifier {
    let level: Iris.SurfaceLevel
    let shape: S
    let tinted: Bool

    func body(content: Content) -> some View {
        content
            .background {
                if Iris.A11y.reduceTransparency {
                    // Con «reducir transparencia» el material desaparece: se
                    // sustituye por una superficie sólida, no por un blur flojo.
                    shape.fill(Iris.Palette.surfaceRaised)
                } else {
                    shape.fill(level.material)
                    if tinted { shape.fill(Iris.Palette.accentMuted) }
                }
            }
            .overlay {
                shape.strokeBorder(Iris.Palette.hairline, lineWidth: 1)
            }
            .shadow(color: .black.opacity(Iris.A11y.reduceTransparency ? 0 : level.shadowOpacity),
                    radius: level.shadowRadius, x: 0, y: level.shadowRadius / 3)
    }
}

public extension View {
    /// Superficie de Iris: material, borde y sombra coherentes con su nivel.
    func irisSurface<S: InsettableShape>(_ level: Iris.SurfaceLevel,
                                         in shape: S,
                                         tinted: Bool = false) -> some View {
        modifier(IrisSurface(level: level, shape: shape, tinted: tinted))
    }

    /// Tarjeta estándar, con esquinas continuas.
    func irisCard(_ level: Iris.SurfaceLevel = .panel,
                  radius: CGFloat = Iris.Radius.lg,
                  tinted: Bool = false) -> some View {
        irisSurface(level, in: RoundedRectangle(cornerRadius: radius, style: .continuous),
                    tinted: tinted)
    }
}

// MARK: - Respuesta a la pulsación

/// Reacciona en el momento de pulsar, no al soltar. Esperar al soltar para dar
/// respuesta se percibe muerto.
public struct IrisPressable: ViewModifier {
    @State private var isPressed = false
    var scale: CGFloat = 0.97

    public func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? scale : 1.0)
            .animation(Iris.Motion.snappy, value: isPressed)
            .onContinuousHover { phase in
                if case .ended = phase { isPressed = false }
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in if !isPressed { isPressed = true } }
                    .onEnded { _ in isPressed = false }
            )
    }
}

public extension View {
    func irisPressable(scale: CGFloat = 0.97) -> some View {
        modifier(IrisPressable(scale: scale))
    }
}

// MARK: - Interruptor

/// Interruptor propio de Iris.
///
/// Es un `ToggleStyle`, no un control inventado: por dentro sigue siendo un
/// `Toggle`, así que conserva el foco por teclado, VoiceOver y el estado
/// accesible. Sólo cambia cómo se dibuja.
///
/// El pulgar se mueve con muelle, y el muelle lleva un punto de rebote porque
/// aquí el gesto sí tiene physicality: algo se desplaza de un extremo a otro.
/// Con «reducir movimiento» el muelle se sustituye por un fundido corto.
public struct IrisSwitchToggleStyle: ToggleStyle {
    public init() {}

    private var width: CGFloat { 38 }
    private var height: CGFloat { 22 }
    private var thumb: CGFloat { 18 }

    public func makeBody(configuration: Configuration) -> some View {
        // Sin Spacer: con `labelsHidden()` un Spacer se comería todo el ancho
        // disponible y descolocaría la fila. Quien necesite separación la pone
        // fuera, que es donde se decide la composición.
        HStack(spacing: Iris.Spacing.sm) {
            configuration.label
            track(isOn: configuration.isOn)
                .contentShape(Rectangle())
                .onTapGesture { configuration.isOn.toggle() }
                .accessibilityHidden(true)
        }
    }

    @ViewBuilder
    private func track(isOn: Bool) -> some View {
        ZStack(alignment: isOn ? .trailing : .leading) {
            Capsule()
                .fill(isOn ? Iris.Palette.accent : Iris.Palette.fillSunken)
                .overlay(
                    Capsule().strokeBorder(
                        isOn ? Color.clear : Iris.Palette.hairline,
                        lineWidth: 1
                    )
                )

            Circle()
                .fill(Color.white)
                .frame(width: thumb, height: thumb)
                .shadow(color: .black.opacity(0.22), radius: 1.5, x: 0, y: 1)
                .padding(.horizontal, (height - thumb) / 2)
        }
        .frame(width: width, height: height)
        .animation(Iris.Motion.momentum, value: isOn)
    }
}

public extension ToggleStyle where Self == IrisSwitchToggleStyle {
    static var irisSwitch: IrisSwitchToggleStyle { IrisSwitchToggleStyle() }
}

// MARK: - El notch

/// El notch tiene reglas propias y no son las de una ventana.
///
/// · La superficie es negra SIEMPRE, porque se apoya en el bisel físico. El
///   texto va en claro con independencia de la apariencia del sistema; usar
///   aquí la paleta normal dejaría texto oscuro sobre negro.
/// · Se lee de un vistazo, de pasada y desde lejos. Nada de texto que se
///   encoja para caber: si no cabe, es que no debía estar ahí.
/// · Un estado vacío es una etiqueta, no una frase. Una explicación larga
///   convertida en microtexto no la lee nadie, y encima ocupa el sitio de lo
///   que sí importa.
public extension Iris {
    enum Notch {
        // --- Texto ------------------------------------------------------
        public static let textPrimary = Color.white
        public static let textSecondary = Color.white.opacity(0.72)
        public static let textTertiary = Color.white.opacity(0.45)

        /// Relleno para pastillas e insignias dentro del notch.
        public static let fill = Color.white.opacity(0.10)
        public static let hairline = Color.white.opacity(0.14)

        // --- Métricas ---------------------------------------------------
        /// Alto útil de la fila de widgets. Todos miden lo mismo: es lo que
        /// hace que la fila se lea como una fila y no como cosas sueltas.
        public static let rowHeight: CGFloat = 86
        /// Separación entre widgets contiguos.
        public static let gutter: CGFloat = Iris.Spacing.xl
        /// Margen interior de cada widget.
        public static let inset: CGFloat = Iris.Spacing.md

        // --- Tipografía -------------------------------------------------
        /// La cifra grande de un widget (temperatura, hora, porcentaje).
        public static let metric = TextStyle(size: 30, weight: .semibold, tracking: -0.6,
                                             lineSpacing: 0, design: .rounded)
        /// El nombre de lo que se muestra.
        public static let label = TextStyle(size: 13, weight: .medium, tracking: -0.05,
                                            lineSpacing: 0, design: .default)
        /// El detalle secundario.
        public static let detail = TextStyle(size: 11, weight: .regular, tracking: 0.1,
                                             lineSpacing: 0, design: .default)
        /// Cifras pequeñas alineadas en columna (viento, humedad…).
        public static let readout = TextStyle(size: 12, weight: .semibold, tracking: 0,
                                              lineSpacing: 0, design: .rounded)
    }
}

/// Estado «sin datos» de un widget del notch: un icono, una etiqueta corta y,
/// si hay algo que hacer, una pista de una línea. Nunca un párrafo.
public struct IrisNotchEmptyState: View {
    let systemImage: String
    let title: String
    var hint: String? = nil

    public init(systemImage: String, title: String, hint: String? = nil) {
        self.systemImage = systemImage
        self.title = title
        self.hint = hint
    }

    public var body: some View {
        HStack(spacing: Iris.Spacing.md) {
            Image(systemName: systemImage)
                .font(.system(size: 22, weight: .regular))
                .foregroundStyle(Iris.Notch.textTertiary)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .irisText(Iris.Notch.label, color: Iris.Notch.textSecondary)
                if let hint {
                    Text(hint)
                        .irisText(Iris.Notch.detail, color: Iris.Notch.textTertiary)
                        .lineLimit(1)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
}

/// Una lectura pequeña del notch: icono a ancho fijo y cifra.
///
/// El ancho fijo del icono es lo que hace que varias lecturas en columna
/// caigan en la misma vertical; sin él la columna se lee en zigzag. Las cifras
/// van monoespaciadas para que no bailen al cambiar.
public struct IrisNotchReadout: View {
    let icon: String
    let value: String
    var tint: Color? = nil

    public init(icon: String, value: String, tint: Color? = nil) {
        self.icon = icon
        self.value = value
        self.tint = tint
    }

    public var body: some View {
        HStack(spacing: Iris.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .medium))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(tint ?? Iris.Notch.textTertiary)
                .frame(width: 14, alignment: .center)

            Text(value)
                .irisText(Iris.Notch.readout, color: tint ?? Iris.Notch.textSecondary)
                .lineLimit(1)
                .monospacedDigit()
        }
        .id(value)
        .transition(.opacity)
    }
}
