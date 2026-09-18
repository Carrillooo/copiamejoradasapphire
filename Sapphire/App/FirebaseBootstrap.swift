//
//  FirebaseBootstrap.swift
//  Sapphire
//
//  Created by Shariq Charolia on 2026-09-14

import FirebaseAppCheck
import FirebaseCore

@MainActor
enum FirebaseBootstrap {
    private(set) static var isConfigured = false

    static func configureIfNeeded() {
        guard !isConfigured else { return }

        // `FirebaseApp.configure()` ABORTA EL PROCESO si la configuración no es
        // válida, y el repositorio sólo trae un stub con la API_KEY vacía y un
        // GOOGLE_APP_ID de relleno. Eso mataba la app nada más arrancar, justo
        // después de pedir los permisos.
        //
        // Se valida antes con FirebaseOptions, que devuelve nil en lugar de
        // abortar. La telemetría es accesoria: no puede tirar la aplicación.
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let options = FirebaseOptions(contentsOfFile: path),
              let apiKey = options.apiKey, !apiKey.isEmpty,
              !options.googleAppID.isEmpty,
              !options.googleAppID.contains("000000000000") else {
            print("[Firebase] Sin configuración válida (falta GoogleService-Info.plist o es el stub). Telemetría desactivada.")
            return
        }

        #if DEBUG
        AppCheck.setAppCheckProviderFactory(AppCheckDebugProviderFactory())
        #else
        AppCheck.setAppCheckProviderFactory(DeviceCheckProviderFactory())
        #endif
        FirebaseApp.configure(options: options)
        isConfigured = true
    }
}