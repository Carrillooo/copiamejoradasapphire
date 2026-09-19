//
//  IrisCodeSignature.swift
//  Iris
//
//  Cómo va firmada esta copia de Iris, y qué puede y qué no puede hacer por eso.
//

import Foundation
import Security

/// Lee la firma de código de la propia app.
///
/// Importa por una razón concreta: el ayudante privilegiado de Iris se registra
/// con `SMAppService.daemon(...)`, que arranca un proceso como root. macOS sólo
/// lanza un demonio root si va firmado con un certificado de desarrollador de
/// Apple. Una firma ad-hoc —la que lleva cualquier compilación hecha sin una
/// cuenta de desarrollador de pago— se registra bien (el estado queda en
/// «enabled») pero launchd nunca lo arranca.
///
/// Sin esta comprobación, la app interpretaba ese silencio como una avería
/// reparable, ofrecía reinstalar el ayudante, fallaba otra vez y se reiniciaba
/// sola para volver a intentarlo: el bucle del aviso SAP-H1.
enum IrisCodeSignature {

    /// `true` si la app va firmada ad-hoc, es decir, sin certificado.
    static let isAdHoc: Bool = info.isAdHoc

    /// Identificador de equipo de Apple, si la firma lleva uno.
    static let teamIdentifier: String? = info.teamIdentifier

    /// `true` si esta copia puede, en principio, arrancar un demonio root.
    ///
    /// «En principio»: que la firma valga no garantiza que el usuario haya dado
    /// permiso en Elementos de Inicio. Eso se comprueba aparte.
    static var canRunPrivilegedHelper: Bool {
        !isAdHoc && !(teamIdentifier ?? "").isEmpty
    }

    /// Explicación para enseñar al usuario cuando el ayudante no puede existir.
    static let unavailabilityReason = """
        Esta copia de Iris está firmada ad-hoc, sin certificado de desarrollador \
        de Apple. macOS no arranca componentes con permisos de administrador \
        firmados así, de modo que el ayudante del sistema no puede funcionar.
        """

    // MARK: - Lectura de la firma

    private struct Info {
        let isAdHoc: Bool
        let teamIdentifier: String?
    }

    /// Bandera `adhoc` de `CS_ADHOC` en `kSecCodeInfoFlags`.
    private static let adHocFlag: UInt32 = 0x0002

    private static let info: Info = {
        var code: SecCode?
        guard SecCodeCopySelf([], &code) == errSecSuccess, let code else {
            // Si no se puede leer la propia firma, lo prudente es asumir que no
            // hay certificado: así se evita el bucle, y lo peor que pasa es que
            // una copia legítima no ofrezca el ayudante hasta que se relance.
            return Info(isAdHoc: true, teamIdentifier: nil)
        }

        var staticCode: SecStaticCode?
        guard SecCodeCopyStaticCode(code, [], &staticCode) == errSecSuccess, let staticCode else {
            return Info(isAdHoc: true, teamIdentifier: nil)
        }

        var raw: CFDictionary?
        guard SecCodeCopySigningInformation(
            staticCode,
            SecCSFlags(rawValue: kSecCSSigningInformation),
            &raw
        ) == errSecSuccess, let dictionary = raw as? [String: Any] else {
            return Info(isAdHoc: true, teamIdentifier: nil)
        }

        let flags = (dictionary[kSecCodeInfoFlags as String] as? NSNumber)?.uint32Value ?? 0
        let team = dictionary[kSecCodeInfoTeamIdentifier as String] as? String

        return Info(isAdHoc: flags & adHocFlag != 0, teamIdentifier: team)
    }()
}
