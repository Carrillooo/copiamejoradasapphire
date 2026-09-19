//
//  IrisAvailability.swift
//  Iris
//
//  Qué ofrece de verdad esta edición.
//
//  El repositorio público de Sapphire trae varias funciones como cáscara vacía:
//  el tipo existe y la interfaz lo lista, pero detrás no hay implementación
//  (ver Sapphire/Stubs/). No están bloqueadas por un plan de pago —Iris no
//  tiene planes—, sencillamente el código no se publica.
//
//  Enseñar esos ajustes sería poner interruptores que no hacen nada. Así que se
//  ocultan de la interfaz, en un único sitio, en lugar de borrar los casos de
//  los enum: quitarlos rompería los `switch` exhaustivos de medio proyecto sin
//  ganar nada.
//
//  Cuando alguna se implemente de verdad, basta con sacarla de la lista de
//  abajo y vuelve a aparecer.
//

import Foundation

extension Iris {
    enum Availability {
        /// Secciones de ajustes cuya pantalla es un stub de una a ocho líneas.
        static let hiddenSettingsSections: Set<SettingsSection> = [
            .sports,        // SportsSettingsView: stub
            .finance,       // FinanceSettingsView: stub
            .intelligence,  // IntelligenceSettingsView: stub
            .appLock,       // AppLockSettingsView + AppLockManager: stubs
            .monitoring,    // MonitoringSettingsView: stub
            .continuity     // ContinuitySettingsView + ContinuityManager: stubs
        ]

        /// Widgets sin vista real.
        ///
        /// Ojo con `storage`: los AJUSTES de almacenamiento sí están
        /// implementados (StorageSettingsView, 176 líneas) y se quedan; lo que
        /// es un stub es el WIDGET. Son cosas distintas.
        static let hiddenWidgets: Set<WidgetType> = [
            .sports,        // SportsWidgetView: stub
            .finance,       // FinanceWidgetView: stub
            .storage,       // StorageWidgetView: stub
            .agent          // su visibilidad ya devolvía `false` siempre
        ]

        /// Live activities sin contenido real.
        static let hiddenLiveActivities: Set<LiveActivityType> = [
            .sports,
            .finance
        ]
    }
}

extension SettingsSection {
    /// Secciones que esta edición muestra. Sustituye a `allCases` en la interfaz.
    static var availableCases: [SettingsSection] {
        allCases.filter { !Iris.Availability.hiddenSettingsSections.contains($0) }
    }
    var isAvailableInIris: Bool {
        !Iris.Availability.hiddenSettingsSections.contains(self)
    }
}

extension WidgetType {
    static var availableCases: [WidgetType] {
        allCases.filter { !Iris.Availability.hiddenWidgets.contains($0) }
    }
    var isAvailableInIris: Bool {
        !Iris.Availability.hiddenWidgets.contains(self)
    }
}

extension LiveActivityType {
    static var availableCases: [LiveActivityType] {
        allCases.filter { !Iris.Availability.hiddenLiveActivities.contains($0) }
    }
    var isAvailableInIris: Bool {
        !Iris.Availability.hiddenLiveActivities.contains(self)
    }
}
