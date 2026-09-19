//
//  FocusWidgetView.swift
//  Sapphire
//
//  Created by Shariq Charolia on 2026-08-25
//

import SwiftUI

struct FocusWidgetView: View {
    @EnvironmentObject private var focusManager: FocusSessionManager
    @EnvironmentObject private var settings: SettingsModel
    @Environment(\.navigationStack) private var navigationStack

    private var accent: Color { focusManager.isFocusBlock ? .green : .orange }
    private var accentColors: [Color] {
        focusManager.isFocusBlock ? [.green, .mint, .teal] : [.orange, .yellow, .pink]
    }

    private var phaseLabel: String {
        if focusManager.isPaused { return "EN PAUSA" }
        return focusManager.isFocusBlock ? "CONCENTRACIÓN" : "DESCANSO"
    }

    private var blockedCount: Int {
        guard focusManager.isBlockingActive else { return 0 }
        return settings.settings.focusBlockedApps.count + settings.settings.focusBlockedWebsites.count
    }

    var body: some View {
        Button {
            Task {
                try? await Task.sleep(for: .seconds(NotchConfiguration.primaryWidgetSwitchDelay))
                navigationStack.wrappedValue.append(NotchWidgetMode.focusSessionDetailView)
            }
        } label: {
            ZStack {
                HStack(alignment: .center, spacing: Iris.Spacing.lg) {
                    primaryInfo.layoutPriority(1)
                    secondaryInfo
                }
                .padding(.horizontal, Iris.Notch.inset)
            }
        }
        .buttonStyle(.plain)
        // Mismo alto e interior que el resto de widgets del notch: es lo que
        // hace que la fila se lea como una fila. Sin .preferredColorScheme:
        // la superficie ya es negra y los colores salen de Iris.Notch.
        .frame(height: Iris.Notch.rowHeight)
        .contentShape(Rectangle())
        .animation(Iris.Motion.standard, value: focusManager.phase)
    }

    // MARK: - Primary readout

    @ViewBuilder
    private var primaryInfo: some View {
        HStack(spacing: 8) {
            if focusManager.isSessionActive {
                FocusWidgetTimerRing(
                    focusManager: focusManager,
                    accent: accent,
                    accentColors: accentColors
                )
            } else {
                Image(systemName: "moon.fill")
                    .font(.system(size: 40))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(
                        LinearGradient(colors: [.purple, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .shadow(radius: 2)
            }

            VStack(alignment: .leading, spacing: 1) {
                // La cuenta atrás es una cifra y va con el estilo de cifra; el
                // nombre es una palabra y va con el de título. Usar `metric`
                // para ambos hacía que "Concentración" dominara toda la fila.
                Group {
                    if focusManager.isSessionActive {
                        FocusWidgetCountdownText(focusManager: focusManager)
                            .irisText(Iris.Notch.metric, color: Iris.Notch.textPrimary)
                    } else {
                        Text("Concentración")
                            .irisText(Iris.Notch.title, color: Iris.Notch.textPrimary)
                    }
                }
                .lineLimit(1)
                .animation(Iris.Motion.standard, value: focusManager.isSessionActive)

                Text(focusManager.isSessionActive ? phaseLabel : "Listo para empezar")
                    .irisText(Iris.Notch.label,
                              color: focusManager.isSessionActive ? accent : Iris.Notch.textSecondary)
                    .lineLimit(1)

                Text(focusManager.isSessionActive
                     ? (blockedCount > 0 ? "Bloqueando \(blockedCount) distracción\(blockedCount == 1 ? "" : "es")" : "Sin bloqueos")
                     : "\(Int(settings.settings.focusSessionDuration / 60)) min · \(FocusSessionManager.format(focusManager.completedToday)) hoy")
                    .irisText(Iris.Notch.detail, color: Iris.Notch.textTertiary)
                    .lineLimit(1)
            }
        }
    }

    // MARK: - Secondary stats (streak leads)

    private var secondaryInfo: some View {
        // Alineada a la izquierda, como en el resto de widgets: con los
        // iconos a ancho fijo las cifras caen en la misma vertical.
        VStack(alignment: .leading, spacing: Iris.Spacing.xs) {
            streakRow
            IrisNotchReadout(icon: "sun.max.fill",
                             value: FocusSessionManager.format(focusManager.completedToday))
            IrisNotchReadout(
                icon: focusManager.isSessionActive ? "square.stack.3d.up.fill" : "checkmark.seal.fill",
                value: focusManager.isSessionActive
                    ? "\(focusManager.blocksCompletedThisSession) bloques"
                    : "\(focusManager.history.count) sesiones"
            )
        }
        .animation(Iris.Motion.standard, value: focusManager.isSessionActive)
        .animation(Iris.Motion.standard, value: focusManager.currentStreak)
    }

    private var streakRow: some View {
        HStack(spacing: Iris.Spacing.sm) {
            StreakFlame(size: 14, isActive: focusManager.currentStreak > 0)
                .frame(width: 14, alignment: .center)

            Text(streakText)
                .irisText(Iris.Notch.readout, color: .orange)
                .lineLimit(1)
        }
        .id(streakText)
        .transition(.opacity)
    }

    private var streakText: String {
        let s = focusManager.currentStreak
        return s == 1 ? "1 día seguido" : "\(s) días seguidos"
    }
}

@MainActor
private struct FocusWidgetTimerRing: View {
    let focusManager: FocusSessionManager
    let accent: Color
    let accentColors: [Color]

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            ZStack {
                ProgressRingView(
                    progress: focusManager.progress(at: context.date),
                    lineWidth: 4,
                    active: AngularGradient(colors: accentColors, center: .center)
                )
                Image(systemName: focusManager.isFocusBlock ? "figure.mind.and.body" : "cup.and.saucer.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(accent)
            }
            .animation(.default, value: focusManager.remaining(at: context.date))
        }
        .frame(width: 44, height: 44)
        .shadow(color: accent.opacity(0.45), radius: 6)
    }
}

@MainActor
private struct FocusWidgetCountdownText: View {
    let focusManager: FocusSessionManager

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let remaining = focusManager.remaining(at: context.date)
            let label = FocusSessionManager.format(remaining)
            Text(label)
                .id(label)
                .contentTransition(.numericText(countsDown: true))
                .animation(.default, value: remaining)
        }
    }
}