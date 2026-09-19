//
//  main.swift — banco de pruebas visual de Iris
//
//  Renderiza los componentes del sistema de diseño a PNG, en claro y en
//  oscuro, usando SwiftUI de verdad. Se compila suelto con swiftc junto a
//  IrisDesignSystem.swift: no depende de que compile la app entera, así que
//  sirve para mirar los componentes en segundos en vez de en media hora.
//
//      swiftc -O main.swift ../../Sapphire/Iris/IrisDesignSystem.swift -o irispreview
//      ./irispreview salida/
//

import SwiftUI
import AppKit

// MARK: - Muestras

/// Réplica fiel de una fila de interruptor de los ajustes, con los mismos
/// componentes del sistema de diseño que usa la app.
private struct SampleToggleRow: View {
    let title: String
    let description: String
    @State var isOn: Bool

    var body: some View {
        HStack(spacing: Iris.Spacing.md) {
            VStack(alignment: .leading, spacing: Iris.Spacing.xxs) {
                Text(title).irisText(Iris.Typography.headline)
                if !description.isEmpty {
                    Text(description)
                        .irisText(Iris.Typography.caption, color: Iris.Palette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: Iris.Spacing.lg)
            Toggle("", isOn: .constant(isOn)).labelsHidden().toggleStyle(.switch)
        }
        .padding(.horizontal, Iris.Spacing.lg)
        .padding(.vertical, Iris.Spacing.md)
    }
}

private struct SampleIconBadge: View {
    let systemImage: String
    let color: Color
    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: 17, weight: .medium))
            .foregroundStyle(color)
            .frame(width: 34, height: 34)
            .background(
                RoundedRectangle(cornerRadius: Iris.Radius.sm, style: .continuous)
                    .fill(color.opacity(0.15))
            )
    }
}

private struct SampleSidebarRow: View {
    let label: String
    let icon: String
    let colors: [Color]
    var selected: Bool = false

    var body: some View {
        HStack(spacing: Iris.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Iris.Palette.onAccent)
                .frame(width: 22, height: 22)
                .background(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                .clipShape(RoundedRectangle(cornerRadius: Iris.Radius.sm - 2, style: .continuous))
            Text(label).irisText(Iris.Typography.body)
            Spacer()
        }
        .padding(.vertical, Iris.Spacing.xs)
        .padding(.horizontal, Iris.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Iris.Radius.md, style: .continuous)
                .fill(selected ? Iris.Palette.accentMuted : Color.clear)
        )
    }
}

/// La hoja de estilo: tipografía, color, superficies y componentes juntos,
/// para poder juzgarlos de un vistazo y comparar claro contra oscuro.
private struct IrisSpecimen: View {
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // --- Barra lateral -------------------------------------------
            VStack(alignment: .leading, spacing: Iris.Spacing.xs) {
                HStack(spacing: Iris.Spacing.md) {
                    ZStack {
                        Circle().fill(LinearGradient(
                            colors: [Iris.Palette.accent, Iris.Palette.accent.opacity(0.55)],
                            startPoint: .topLeading, endPoint: .bottomTrailing))
                        Circle().strokeBorder(Color.white.opacity(0.85), lineWidth: 2.5).padding(9)
                        Circle().fill(Color.black.opacity(0.75)).padding(14)
                    }
                    .frame(width: 36, height: 36)
                    VStack(alignment: .leading, spacing: Iris.Spacing.xxs) {
                        Text("Iris").irisText(Iris.Typography.headline)
                        Text("Edición personal")
                            .irisText(Iris.Typography.caption, color: Iris.Palette.textTertiary)
                    }
                    Spacer()
                }
                .padding(.horizontal, Iris.Spacing.md)
                .padding(.vertical, Iris.Spacing.md)

                Text("GENERAL")
                    .irisText(Iris.Typography.caption, color: Iris.Palette.textTertiary)
                    .padding(.horizontal, Iris.Spacing.md)
                    .padding(.top, Iris.Spacing.sm)

                SampleSidebarRow(label: "General", icon: "gearshape.fill",
                                 colors: [.gray, .gray.opacity(0.6)], selected: true)
                SampleSidebarRow(label: "Notch", icon: "rectangle.topthird.inset.filled",
                                 colors: [.purple, .indigo])
                SampleSidebarRow(label: "Música", icon: "music.note",
                                 colors: [.pink, .red])
                SampleSidebarRow(label: "Concentración", icon: "moon.fill",
                                 colors: [.indigo, .blue])
                Spacer()
            }
            .frame(width: 230)
            .padding(.vertical, Iris.Spacing.lg)
            .background(Iris.Palette.surfaceSunken)

            // --- Contenido ------------------------------------------------
            ScrollView {
                VStack(alignment: .leading, spacing: Iris.Spacing.xl) {
                    VStack(alignment: .leading, spacing: Iris.Spacing.xs) {
                        Text("Apariencia").irisText(Iris.Typography.display)
                        Text("Escala tipográfica, superficies y controles del sistema de diseño.")
                            .irisText(Iris.Typography.body, color: Iris.Palette.textSecondary)
                    }

                    // Tipografía
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Tipografía")
                            .irisText(Iris.Typography.headline)
                            .padding(.horizontal, Iris.Spacing.lg)
                            .padding(.top, Iris.Spacing.lg)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        VStack(alignment: .leading, spacing: Iris.Spacing.md) {
                            Text("Display 34 · tracking −0.7").irisText(Iris.Typography.display)
                            Text("Title 22 · tracking −0.35").irisText(Iris.Typography.title)
                            Text("Headline 16 · tracking −0.1").irisText(Iris.Typography.headline)
                            Text("Body 13 · tracking 0 — el cuerpo lleva el interlineado más holgado, porque es el que se lee seguido.")
                                .irisText(Iris.Typography.body, color: Iris.Palette.textSecondary)
                            Text("Caption 11 · tracking +0.15 — el texto pequeño se abre para que no se empaste.")
                                .irisText(Iris.Typography.caption, color: Iris.Palette.textTertiary)
                        }
                        .padding(Iris.Spacing.lg)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .irisCard(.panel, radius: Iris.Radius.xl)

                    // Controles
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Controles")
                            .irisText(Iris.Typography.headline)
                            .padding(.horizontal, Iris.Spacing.lg)
                            .padding(.top, Iris.Spacing.lg)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        SampleToggleRow(title: "Abrir al pasar el cursor",
                                        description: "Despliega el notch sin hacer clic.", isOn: true)
                        Divider().overlay(Iris.Palette.hairline).padding(.leading, Iris.Spacing.lg)
                        SampleToggleRow(title: "Detección de suplantación",
                                        description: "Exige el modelo de liveness. Si falta, no desbloquea.", isOn: false)
                        Divider().overlay(Iris.Palette.hairline).padding(.leading, Iris.Spacing.lg)
                        SampleToggleRow(title: "Reducir movimiento",
                                        description: "Sustituye los muelles por fundidos cortos.", isOn: false)
                    }
                    .irisCard(.panel, radius: Iris.Radius.xl)

                    // Color y superficie
                    VStack(alignment: .leading, spacing: Iris.Spacing.lg) {
                        Text("Color y superficie")
                            .irisText(Iris.Typography.headline)
                        HStack(spacing: Iris.Spacing.md) {
                            SampleIconBadge(systemImage: "bolt.fill", color: Iris.Palette.accent)
                            SampleIconBadge(systemImage: "checkmark", color: Iris.Palette.success)
                            SampleIconBadge(systemImage: "exclamationmark.triangle.fill", color: Iris.Palette.warning)
                            SampleIconBadge(systemImage: "xmark", color: Iris.Palette.danger)
                            Spacer()
                        }
                        HStack(spacing: Iris.Spacing.md) {
                            ForEach(["Primario", "Secundario", "Terciario"], id: \.self) { name in
                                Text(name)
                                    .irisText(Iris.Typography.caption,
                                              color: name == "Primario" ? Iris.Palette.textPrimary
                                                   : name == "Secundario" ? Iris.Palette.textSecondary
                                                   : Iris.Palette.textTertiary)
                            }
                            Spacer()
                        }
                        HStack(spacing: Iris.Spacing.md) {
                            RoundedRectangle(cornerRadius: Iris.Radius.md, style: .continuous)
                                .fill(Iris.Palette.fillElevated)
                                .frame(height: 44)
                                .overlay(Text("fillElevated").irisText(Iris.Typography.caption))
                            RoundedRectangle(cornerRadius: Iris.Radius.md, style: .continuous)
                                .fill(Iris.Palette.fillSunken)
                                .frame(height: 44)
                                .overlay(Text("fillSunken").irisText(Iris.Typography.caption))
                        }
                    }
                    .padding(Iris.Spacing.lg)
                    .irisCard(.panel, radius: Iris.Radius.xl)
                }
                .padding(Iris.Spacing.xl)
            }
            .frame(maxWidth: .infinity)
            .background(Iris.Palette.surfaceBase)
        }
        .frame(width: 900, height: 780)
    }
}

// MARK: - Render

@MainActor
func render(_ view: some View, appearanceName: NSAppearance.Name, to url: URL) {
    guard let appearance = NSAppearance(named: appearanceName) else {
        FileHandle.standardError.write(Data("No se pudo crear la apariencia\n".utf8)); return
    }
    var image: NSImage?
    appearance.performAsCurrentDrawingAppearance {
        let renderer = ImageRenderer(content: view.environment(\.colorScheme,
                                     appearanceName == .darkAqua ? .dark : .light))
        renderer.scale = 2
        image = renderer.nsImage
    }
    guard let image,
          let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:]) else {
        FileHandle.standardError.write(Data("Fallo al renderizar \(url.lastPathComponent)\n".utf8)); return
    }
    try? png.write(to: url)
    print("  escrito \(url.lastPathComponent) — \(png.count / 1024) KB")
}

let outDir = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "previews")
try? FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

MainActor.assumeIsolated {
    render(IrisSpecimen(), appearanceName: .aqua, to: outDir.appendingPathComponent("iris-claro.png"))
    render(IrisSpecimen(), appearanceName: .darkAqua, to: outDir.appendingPathComponent("iris-oscuro.png"))
}
print("Listo.")
