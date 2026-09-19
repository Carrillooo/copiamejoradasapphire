//
//  FaceIDAppleStyleViews.swift
//  Iris
//
//  El anillo de tramos radiales del registro facial, con la gramática visual
//  del Face ID de Apple: ocho sectores que se encienden según el ángulo de la
//  cabeza, y que se van llenando marca a marca mientras mantienes la pose.
//
//  Nota: esto es reconocimiento por webcam, NO el Face ID de Apple. No hay
//  hardware TrueDepth ni Secure Enclave de por medio. Los textos de la interfaz
//  lo dicen de forma explícita.
//

import SwiftUI

// MARK: - Geometría de poses

/// Sector angular del anillo asociado a cada pose direccional.
///
/// Los ángulos van en grados con 0° arriba y sentido horario, que es como se
/// leen las marcas del anillo de Face ID.
enum FaceIDPoseGeometry {
    /// Las ocho poses que ocupan el anillo, en el sentido de las agujas del reloj.
    ///
    /// Son ocho sectores de 45° que cubren la circunferencia ENTERA. Antes sólo
    /// había seis y quedaban dos huecos muertos a 135° y 225°, así que el
    /// anillo no podía llenarse del todo por muy bien que fuera el registro.
    ///
    /// «Acercarse» y «separarse» no son direcciones, pero ocupar con ellas los
    /// dos huecos hace que cada marca del anillo signifique algo y que llegar
    /// al final se vea: la circunferencia se completa.
    static let directional: [(bucket: FacePoseBucket, degrees: Double)] = [
        (.up,        0),
        (.tiltRight, 45),
        (.right,     90),
        (.closer,    135),
        (.down,      180),
        (.farther,   225),
        (.left,      270),
        (.tiltLeft,  315)
    ]

    /// La pose frontal no tiene dirección y no ocupa sector: su progreso se ve
    /// en el arco interior de la pantalla de registro, no en el anillo.

    /// Semiancho del sector.
    static let sectorHalfWidth: Double = 22.5

    /// Devuelve la pose dueña del tramo situado en `degrees`.
    ///
    /// Se resuelve por sector más cercano en vez de por distancia angular con
    /// `<=`: así una marca que cae justo en la frontera entre dos sectores va a
    /// uno solo, y los ocho sectores salen con el mismo número de marcas.
    static func bucket(forTickAt degrees: Double) -> FacePoseBucket? {
        let index = Int((degrees / 45.0).rounded()) % directional.count
        return directional[(index + directional.count) % directional.count].bucket
    }

    /// Diferencia de `a` a `b` en el rango (-180, 180].
    static func signedAngle(from a: Double, to b: Double) -> Double {
        var diff = (b - a).truncatingRemainder(dividingBy: 360)
        if diff > 180 { diff -= 360 }
        if diff <= -180 { diff += 360 }
        return diff
    }

}

// MARK: - Anillo de tramos

/// Anillo de marcas radiales al estilo del registro de Face ID.
///
/// Cada marca pertenece a un sector; el sector se ilumina cuando su pose ya se
/// ha capturado. Las marcas sin pose asignada quedan tenues y sólo dan estructura.
struct FaceIDPoseRing: View {
    /// `rawValue` de las poses ya capturadas (`CameraController.registrationPoseCaptured`).
    let capturedPoses: Set<String>
    /// Pose que se está pidiendo ahora, para resaltar su sector.
    var targetPose: FacePoseBucket?
    /// Cuánto lleva capturado de la pose actual, de 0 a 1.
    ///
    /// Sin esto el anillo sólo se movía al TERMINAR una pose: hacías el gesto,
    /// no pasaba nada visible, y sólo al completarlo saltaban seis marcas de
    /// golpe. En Face ID el anillo avanza mientras mueves la cabeza, y eso es
    /// lo que te dice que vas bien. Aquí las marcas del sector en curso se van
    /// encendiendo una a una con el progreso.
    var holdProgress: Double = 0
    var diameter: CGFloat = 300
    var accent: Color = .accentColor

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let tickCount = 48
    private var tickLength: CGFloat { diameter * 0.075 }
    private var tickWidth: CGFloat { max(2, diameter * 0.011) }
    private var ringRadius: CGFloat { diameter / 2 + tickLength * 0.9 }

    /// Marcas por sector: 48 entre las 8 poses del anillo.
    private var ticksPerSector: Int {
        max(1, tickCount / FaceIDPoseGeometry.directional.count)
    }

    private var totalPoses: Int { FacePoseBucket.allCases.count }

    var body: some View {
        ZStack {
            ForEach(0..<tickCount, id: \.self) { index in
                tick(at: index)
            }
        }
        .frame(width: ringRadius * 2, height: ringRadius * 2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progreso del registro facial")
        .accessibilityValue("\(capturedPoses.count) de \(totalPoses) posiciones capturadas")
    }

    private func degrees(for index: Int) -> Double {
        Double(index) / Double(tickCount) * 360.0
    }

    /// Posición de la marca dentro de su sector, de 0 en adelante.
    ///
    /// Se mide desde el borde del sector, no desde el índice global, para que
    /// el llenado empiece siempre por el mismo extremo y no dependa de en qué
    /// parte del círculo caiga el sector.
    private func positionWithinSector(index: Int, owner: FacePoseBucket) -> Int {
        guard let centre = FaceIDPoseGeometry.directional.first(where: { $0.bucket == owner })?.degrees else { return 0 }
        let offset = FaceIDPoseGeometry.signedAngle(from: centre, to: degrees(for: index))
        let step = 360.0 / Double(tickCount)
        return Int(((offset + FaceIDPoseGeometry.sectorHalfWidth) / step).rounded(.down))
    }

    @ViewBuilder
    private func tick(at index: Int) -> some View {
        let deg = degrees(for: index)
        let owner = FaceIDPoseGeometry.bucket(forTickAt: deg)
        let isCaptured = owner.map { capturedPoses.contains($0.rawValue) } ?? false
        let isTargetSector = owner != nil && owner == targetPose && !isCaptured

        // Dentro del sector que se está pidiendo, se encienden tantas marcas
        // como progreso lleve la pose.
        let filledByHold: Bool = {
            guard isTargetSector, let owner else { return false }
            let lit = Int((holdProgress * Double(ticksPerSector)).rounded(.down))
            return positionWithinSector(index: index, owner: owner) < lit
        }()

        let isLit = isCaptured || filledByHold

        Capsule()
            .fill(tickColor(lit: isLit, target: isTargetSector))
            .frame(width: tickWidth, height: tickLength * tickScale(lit: isLit, target: isTargetSector))
            .offset(y: -ringRadius + tickLength / 2)
            .rotationEffect(.degrees(deg))
            .animation(
                reduceMotion ? .none : .spring(response: 0.34, dampingFraction: 0.72),
                value: isLit
            )
    }

    private func tickColor(lit: Bool, target: Bool) -> Color {
        if lit { return accent }
        if target { return accent.opacity(0.5) }
        return Color.primary.opacity(0.18)
    }

    private func tickScale(lit: Bool, target: Bool) -> CGFloat {
        if lit { return 1.35 }
        if target { return 1.12 }
        return 1.0
    }
}

// MARK: - Fases de la autenticación en el notch

/// Fase visible de la autenticación facial, para pintar el notch.
enum FaceIDNotchPhase: Equatable {
    case idle
    /// Buscando una cara en el encuadre.
    case searching
    /// Cara detectada, comprobando identidad y liveness.
    case located
    /// Identidad confirmada.
    case unlocked
    /// No se puede autenticar. El texto explica por qué.
    case failed(String)

    var title: String {
        switch self {
        case .idle:              return ""
        case .searching:         return "Buscando tu cara…"
        case .located:           return "Localizado"
        case .unlocked:          return "Desbloqueado"
        case .failed(let why):   return why
        }
    }

    var symbol: String {
        switch self {
        case .idle, .searching: return "faceid"
        case .located:          return "person.crop.circle.badge.checkmark"
        case .unlocked:         return "lock.open.fill"
        case .failed:           return "exclamationmark.triangle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .idle, .searching: return .accentColor
        case .located:          return .green
        case .unlocked:         return .green
        case .failed:           return .orange
        }
    }
}

extension FaceIDNotchPhase {
    /// Traduce el estado del motor a la fase que se pinta en el notch.
    static func from(state: CameraState, faceIsRecognized: Bool) -> FaceIDNotchPhase {
        switch state {
        case .authenticating, .detecting:
            return faceIsRecognized ? .located : .searching
        case .recognized:
            return .located
        case .needsReenrollment:
            return .failed("Hay que volver a registrar la cara")
        case .idle, .registeredAndIdle, .registering:
            return .idle
        }
    }
}

// Aquí vivían `FaceIDNotchAuthView` y `FaceIDAppleStyleEnrollmentView`.
//
// Ninguna de las dos se instanciaba en ningún sitio. La de autenticación
// duplicaba lo que ya pinta LiveActivityComponents en la pantalla de bloqueo
// del notch, y la de registro era una segunda pantalla de registro que competía
// con FaceIDRegistrationView —la que sí se abre desde los ajustes—, sin el
// progreso de la pose, sin la fase de ángulos extra y sin avisar cuando el
// registro no puede continuar.
//
// Tener dos pantallas para lo mismo, con una sola conectada, es la razón de que
// arreglar el registro no cambiara nada de lo que se veía. Se conservan el
// anillo (`FaceIDPoseRing`) y su geometría, que son lo que usa la pantalla real.
