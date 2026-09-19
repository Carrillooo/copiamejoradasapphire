//
//  WeatherWidgetView.swift
//  Iris
//
//  Reconstruido sobre la capa de notch del sistema de diseño
//  (Sapphire/Iris/IrisDesignSystem.swift → Iris.Notch).
//
//  Qué iba mal en la versión anterior:
//
//  · Tamaños inventados: 44, 42, .headline, .subheadline, .callout, y
//    espaciados 10/8/2/4/5. Cada widget elegía los suyos, así que la fila del
//    notch no compartía ningún ritmo y se leía como cosas sueltas.
//  · Sin ubicación, `conditionDescription` ES la frase "Grant Location access
//    in ... Permissions settings to show weather.", y se pintaba con
//    lineLimit(1) + minimumScaleFactor(0.7): un párrafo encogido hasta ser
//    ilegible, ocupando el sitio de lo que sí importa.
//  · `.preferredColorScheme(.dark)` forzado sobre una superficie que ya es
//    negra: no hacía falta, y arrastraba el resto de la jerarquía.
//

import SwiftUI

struct WeatherWidgetView: View {
    @Environment(\.navigationStack) var navigationStack
    @ObservedObject private var viewModel = WeatherViewModel.shared

    /// Sin datos no hay nada que enseñar: se muestra el estado vacío corto en
    /// lugar de rellenar los huecos con guiones.
    private var sinDatos: Bool { viewModel.weatherData == nil }

    var body: some View {
        Group {
            if sinDatos {
                IrisNotchEmptyState(
                    systemImage: "location.slash",
                    title: "Tiempo no disponible",
                    hint: "Permite la ubicación en Ajustes"
                )
            } else {
                contenido
            }
        }
        .frame(height: Iris.Notch.rowHeight)
        .padding(.horizontal, Iris.Notch.inset)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(Iris.Motion.standard) {
                navigationStack.wrappedValue.append(.weatherPlayer)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            sinDatos
            ? "Tiempo no disponible. Permite la ubicación en Ajustes."
            : "\(viewModel.temperature), \(viewModel.conditionDescription), \(viewModel.locationName)"
        )
    }

    private var contenido: some View {
        HStack(alignment: .center, spacing: Iris.Spacing.lg) {
            Image(systemName: viewModel.iconName)
                .font(.system(size: 34))
                .symbolRenderingMode(.multicolor)
                .frame(width: 40)
                .id(viewModel.iconName)
                .transition(.opacity)

            VStack(alignment: .leading, spacing: 1) {
                Text(viewModel.temperature)
                    .irisText(Iris.Notch.metric, color: Iris.Notch.textPrimary)
                    .id(viewModel.temperature)
                    .transition(.opacity)

                Text(viewModel.conditionDescription)
                    .irisText(Iris.Notch.label, color: Iris.Notch.textSecondary)
                    .lineLimit(1)
                    .id(viewModel.conditionDescription)
                    .transition(.opacity)

                Text(viewModel.locationName)
                    .irisText(Iris.Notch.detail, color: Iris.Notch.textTertiary)
                    .lineLimit(1)
                    .id(viewModel.locationName)
                    .transition(.opacity)
            }
            .layoutPriority(1)

            lecturas
        }
        .animation(Iris.Motion.standard, value: viewModel.locationName)
    }

    /// Columna de lecturas. Alineadas a la izquierda y con los iconos a ancho
    /// fijo, para que las cifras caigan en la misma vertical y la columna se
    /// lea de un golpe en vez de en zigzag.
    private var lecturas: some View {
        VStack(alignment: .leading, spacing: Iris.Spacing.xs) {
            IrisNotchReadout(icon: "wind", value: viewModel.windInfo)
            IrisNotchReadout(icon: "drop.fill", value: viewModel.precipChance)
            IrisNotchReadout(icon: "humidity.fill", value: viewModel.humidity)
        }
        .animation(Iris.Motion.standard, value: viewModel.windInfo)
    }
}
