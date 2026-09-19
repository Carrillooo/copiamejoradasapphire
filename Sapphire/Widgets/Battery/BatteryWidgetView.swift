//
//  BatteryWidgetView.swift
//  Iris
//
//  El widget de batería de la fila del notch.
//
//  Antes se llamaba «System Power» y su cifra grande era el consumo en vatios.
//  Ese dato, el de la temperatura y el del adaptador vienen TODOS del SMC, que
//  se lee a través del ayudante privilegiado. En una copia firmada ad-hoc el
//  ayudante no arranca, así que el widget enseñaba «--» vatios, «--» grados y
//  una barra vacía: cuatro quintas partes de un widget muerto en mitad del
//  notch.
//
//  Ahora lo primero que dice es el porcentaje de batería, que sale de IOKit y
//  funciona siempre. Lo del SMC sólo aparece cuando hay ayudante vivo para
//  darlo. Sin él no se deja un hueco con guiones: simplemente no está.
//

import SwiftUI

struct BatteryWidgetView: View {
    @Environment(\.navigationStack) private var navigationStack
    @ObservedObject private var helperManager = HelperManager.shared
    @StateObject private var stats = BatteryStatsViewModel()
    @State private var statsPollingRequester = "BatteryWidget-\(UUID().uuidString)"

    /// `true` si hay ayudante vivo, es decir, si los datos del SMC llegan.
    private var smcAvailable: Bool { helperManager.isRunning }

    private var power: SystemPowerReading {
        SystemPowerReading(
            systemLoad: stats.systemPower,
            adapterPower: stats.adapterPower,
            adapterConnected: (stats.powerAdapterInfo?.maxPower ?? 0) > 0,
            isCharging: stats.isCharging
        )
    }

    private var levelColor: Color {
        if stats.isCharging { return .green }
        if stats.batteryLevel <= 10 { return .red }
        if stats.batteryLevel <= 20 { return .orange }
        return Iris.Notch.textPrimary
    }

    private var statusLine: String {
        if stats.isCharging {
            return stats.timeRemaining == "--" ? "Cargando" : "\(stats.timeRemaining) para llena"
        }
        if stats.lowPowerModeEnabled { return "Bajo consumo" }
        return stats.timeRemaining == "--" ? "Con batería" : "\(stats.timeRemaining) restantes"
    }

    private var batterySymbol: String {
        if stats.isCharging { return "battery.100.bolt" }
        switch stats.batteryLevel {
        case ...10:  return "battery.0"
        case ...35:  return "battery.25"
        case ...65:  return "battery.50"
        case ...85:  return "battery.75"
        default:     return "battery.100"
        }
    }

    var body: some View {
        Button {
            Task {
                try? await Task.sleep(for: .seconds(NotchConfiguration.primaryWidgetSwitchDelay))
                navigationStack.wrappedValue.append(NotchWidgetMode.batteryDetailView)
            }
        } label: {
            HStack(alignment: .center, spacing: Iris.Spacing.lg) {
                primaryInfo.layoutPriority(1)
                secondaryInfo
            }
            .padding(.horizontal, Iris.Notch.inset)
        }
        .buttonStyle(.plain)
        // Mismo alto que el resto de la fila: es lo que hace que se lea como
        // una fila. Sin .preferredColorScheme ni blancos a mano: la superficie
        // ya es negra y los colores salen de Iris.Notch.
        .frame(height: Iris.Notch.rowHeight)
        .contentShape(Rectangle())
        .help("Abrir el detalle de batería y energía")
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Batería")
        .accessibilityValue("\(stats.batteryLevel) por ciento. \(statusLine)")
        .onAppear {
            stats.start()
            // Los sensores del SMC sólo se piden si alguien puede leerlos.
            // Pedirlos sin ayudante es despertar al lector para nada.
            StatsManager.shared.setPolling(
                for: statsPollingRequester,
                requiredStats: smcAvailable ? [.systemPower, .batteryPower] : []
            )
        }
        .onDisappear {
            stats.stop()
            StatsManager.shared.setPolling(for: statsPollingRequester, requiredStats: [])
        }
    }

    // MARK: - Lo que se lee primero

    private var primaryInfo: some View {
        HStack(spacing: Iris.Spacing.sm) {
            Image(systemName: batterySymbol)
                .font(.system(size: 26, weight: .medium))
                .foregroundStyle(levelColor)
                .contentTransition(.symbolEffect(.replace))
                .frame(width: 34, alignment: .leading)

            VStack(alignment: .leading, spacing: 1) {
                HStack(alignment: .lastTextBaseline, spacing: 1) {
                    Text("\(stats.batteryLevel)")
                        .irisText(Iris.Notch.metric, color: levelColor)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                    Text("%")
                        .irisText(Iris.Notch.label, color: Iris.Notch.textSecondary)
                }
                .lineLimit(1)

                Text(statusLine)
                    .irisText(Iris.Notch.label, color: Iris.Notch.textSecondary)
                    .lineLimit(1)

                Text("Salud \(stats.maxCapacityPercentage) % · \(stats.cycleCount) ciclos")
                    .irisText(Iris.Notch.detail, color: Iris.Notch.textTertiary)
                    .lineLimit(1)
            }
        }
        .animation(Iris.Motion.standard, value: stats.batteryLevel)
        .animation(Iris.Motion.standard, value: stats.isCharging)
    }

    // MARK: - Lo del SMC, sólo si hay quien lo lea

    @ViewBuilder
    private var secondaryInfo: some View {
        if smcAvailable {
            VStack(alignment: .leading, spacing: Iris.Spacing.xs) {
                IrisNotchReadout(
                    icon: power.adapterConnected ? "powerplug.fill" : "bolt.fill",
                    value: power.heroWatts > 0 ? String(format: "%.1f W", power.heroWatts) : "--"
                )
                IrisNotchReadout(
                    icon: "thermometer.medium",
                    value: stats.temperature > 0 ? String(format: "%.1f°", stats.temperature) : "--"
                )
                // Aquí había un `PowerSplitBar`. Es un stub: una cápsula de un
                // color liso, sin partir nada ni representar ninguna
                // proporción. Ocupaba sitio en el notch aparentando un gráfico
                // que no existe.
            }
        }
    }
}
