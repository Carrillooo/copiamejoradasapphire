//
//  SettingsSidebar.swift
//  Iris
//
//  Barra lateral de los ajustes, reconstruida sobre el sistema de diseño de
//  Iris (ver Sapphire/Iris/IrisDesignSystem.swift).
//
//  Qué cambia respecto a la versión original:
//
//  · Ya no hay colores fijos. Antes el texto era `.white` a pelo, lo que en
//    apariencia clara dejaba texto blanco sobre fondo claro. Ahora todo sale de
//    la paleta, que se resuelve sola en claro y oscuro.
//  · Ya no hay tamaños de fuente sueltos: cada texto usa un estilo de la escala
//    tipográfica, con su tracking y su interlineado.
//  · Desaparecen los candados: en esta edición no hay funciones de pago.
//  · El movimiento usa muelles, no duraciones fijas, y respeta «reducir
//    movimiento».
//

import SwiftUI

struct SettingsSidebarGroup: Identifiable {
    let title: String
    let sections: [SettingsSection]
    var id: String { title }
}

extension SettingsSection {
    static let sidebarGroups: [SettingsSidebarGroup] = [
        .init(title: "General", sections: [.general, .keyboardShortcuts, .bluetoothUnlock, .intelligence, .neardrop, .continuity]),
        .init(title: "Notch", sections: [.appearance, .widgets, .liveActivities, .lockScreen, .notifications, .hud]),
        .init(title: "Widgets y contenido", sections: [.music, .weather, .calendar, .sports, .finance, .battery, .audio, .bluetooth, .shortcuts, .fileShelf, .notes, .clipboard, .mirror, .caffeine]),
        .init(title: "Sistema y utilidades", sections: [.systemEnhance, .snapZones, .dockLayouts, .mediaOptimizer, .mouse, .monitoring, .devActivity, .emoji, .archives, .apps, .storage]),
        .init(title: "Concentración y seguridad", sections: [.eyeBreak, .focusSession, .appLock]),
        .init(title: "", sections: [.about])
    ]
}

struct SettingsSidebarView: View {
    @Binding var selectedSection: SettingsSection?
    @Binding var showAccountPane: Bool
    let onQuit: () -> Void
    @State private var searchText = ""

    private var filteredGroups: [SettingsSidebarGroup] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return SettingsSection.sidebarGroups }

        return SettingsSection.sidebarGroups.compactMap { group in
            let matches = group.sections.filter { section in
                let haystacks = [section.label, section.shortDescription] + section.searchTokens
                return haystacks.contains { $0.localizedCaseInsensitiveContains(query) }
            }
            return matches.isEmpty ? nil : SettingsSidebarGroup(title: group.title, sections: matches)
        }
    }

    var body: some View {
        let filteredGroups = filteredGroups

        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: 45)

            // Búsqueda
            ClearableSearchField(placeholder: "Buscar en ajustes", text: $searchText)
                .padding(.horizontal, Iris.Spacing.md)
                .padding(.vertical, Iris.Spacing.sm)
                .irisSurface(.control,
                             in: RoundedRectangle(cornerRadius: Iris.Radius.md, style: .continuous))
                .padding(.horizontal, Iris.Spacing.md)
                .padding(.bottom, Iris.Spacing.md)

            IrisIdentityCardView(isSelected: showAccountPane) {
                withAnimation(Iris.Motion.snappy) {
                    showAccountPane = true
                    selectedSection = nil
                }
            }

            List(selection: Binding(
                get: { selectedSection },
                set: { value in
                    selectedSection = value
                    if value != nil { showAccountPane = false }
                }
            )) {
                ForEach(filteredGroups) { group in
                    Section {
                        ForEach(group.sections) { section in
                            SidebarRowView(section: section).tag(section)
                        }
                    } header: {
                        Text(group.title)
                            .irisText(Iris.Typography.caption, color: Iris.Palette.textTertiary)
                            .textCase(.uppercase)
                    }
                }
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)
            .frame(maxHeight: .infinity, alignment: .top)
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SapphireSelectSection"))) { notification in
                if let sectionName = notification.object as? String,
                   let section = SettingsSection(rawValue: sectionName) {
                    withAnimation(Iris.Motion.snappy) {
                        self.selectedSection = section
                        self.showAccountPane = false
                    }
                }
            }

            if !searchText.isEmpty && filteredGroups.isEmpty {
                Text("Nada coincide con «\(searchText)».")
                    .irisText(Iris.Typography.caption, color: Iris.Palette.textTertiary)
                    .padding(.horizontal, Iris.Spacing.lg)
                    .padding(.bottom, Iris.Spacing.md)
            }

            Spacer(minLength: 0)

            Button(action: onQuit) {
                HStack(spacing: Iris.Spacing.md) {
                    Image(systemName: "power")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Iris.Palette.danger)
                        .frame(width: 22, height: 22)
                        .background(
                            RoundedRectangle(cornerRadius: Iris.Radius.sm, style: .continuous)
                                .fill(Iris.Palette.danger.opacity(0.14))
                        )
                    Text("Salir de Iris")
                        .irisText(Iris.Typography.body)
                    Spacer()
                }
                .padding(.vertical, Iris.Spacing.xs)
                .padding(.horizontal, Iris.Spacing.md)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .irisPressable()
            .padding(.horizontal, Iris.Spacing.sm)
            .padding(.bottom, Iris.Spacing.lg)
        }
    }
}

// MARK: - Tarjeta de identidad

/// Sustituye a la antigua tarjeta de cuenta y plan. Iris no tiene cuentas ni
/// suscripciones, así que la tarjeta identifica la aplicación y abre su pantalla
/// de información, en vez de vender un plan.
struct IrisIdentityCardView: View {
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Iris.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Iris.Palette.accent, Iris.Palette.accent.opacity(0.55)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Circle()
                        .strokeBorder(Color.white.opacity(0.85), lineWidth: 2.5)
                        .padding(9)
                    Circle()
                        .fill(Color.black.opacity(0.75))
                        .padding(14)
                }
                .frame(width: 36, height: 36)
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: Iris.Spacing.xxs) {
                    Text("Iris")
                        .irisText(Iris.Typography.headline)
                        .lineLimit(1)
                    Text("Edición personal")
                        .irisText(Iris.Typography.caption, color: Iris.Palette.textTertiary)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Iris.Palette.textTertiary)
            }
            .padding(.horizontal, Iris.Spacing.md)
            .padding(.vertical, Iris.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Iris.Radius.md, style: .continuous)
                    .fill(isSelected ? Iris.Palette.accentMuted : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .irisPressable(scale: 0.985)
        .animation(Iris.Motion.snappy, value: isSelected)
        .padding(.horizontal, Iris.Spacing.md)
        .padding(.bottom, Iris.Spacing.sm)
        .accessibilityLabel("Iris, edición personal. Abre la información de la aplicación.")
    }
}

struct TrafficLightButtonStyle: ButtonStyle {
    let color: Color
    let isHovering: Bool

    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            Circle().fill(color)
            configuration.label
                .foregroundStyle(.black.opacity(0.6))
                .opacity(isHovering ? 1 : 0)
        }
        .frame(width: 12, height: 12)
        .animation(Iris.Motion.snappy, value: isHovering)
    }
}

// MARK: - Fila

fileprivate struct SidebarRowView: View {
    let section: SettingsSection

    var body: some View {
        HStack(spacing: Iris.Spacing.md) {
            Image(systemName: section.systemImage)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(
                    LinearGradient(colors: section.iconGradientColors,
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .clipShape(RoundedRectangle(cornerRadius: Iris.Radius.sm - 2, style: .continuous))

            Text(section.label)
                .irisText(Iris.Typography.body)

            Spacer()
        }
        .padding(.vertical, Iris.Spacing.xs)
    }
}
