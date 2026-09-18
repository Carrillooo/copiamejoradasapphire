# Sapphire Personal

Versión personal y corregida de [Sapphire](https://github.com/cshariq/Sapphire),
la app para el notch del Mac. App nativa de macOS (Swift / SwiftUI / AppKit).

**Objetivo de despliegue:** macOS 26.0, Apple Silicon.

> Obra derivada bajo **GNU AGPL v3.0**, a partir del commit `798d117` de upstream.
> El README original está en [`README-UPSTREAM.md`](README-UPSTREAM.md) y las
> atribuciones en [`CREDITS.md`](CREDITS.md). Ver [`NOTICE-SAPPHIRE-PERSONAL.md`](NOTICE-SAPPHIRE-PERSONAL.md).

## Qué cambia respecto a upstream

### Seguridad — Face ID

Upstream **autenticaba sin comprobar suplantación**. `frameIsReal` arrancaba en
`true` y la evaluación de liveness estaba dentro de un `if let`, así que los
cuatro caminos en que `evaluateAntiSpoof` devuelve `nil` pasaban de largo y
desbloqueaban. Como el modelo de liveness **no se distribuye con el
repositorio**, ése era el comportamiento por defecto: una foto en un móvil
desbloqueaba.

También había un `if false &&` que desactivaba la comprobación durante el
registro, con lo que se podía registrar una fotografía como plantilla facial.

Ambos corregidos. Sin modelo de liveness, ahora **no autentica** y cae a
contraseña.

### Spotify

- Reanudar enviaba una URI vacía (`play track ""` / `{"uris":[""]}` → HTTP 400):
  no reanudaba, y la interfaz mostraba «reproduciendo» con la música parada.
- La URI se interpolaba en AppleScript sin validar (inyección).
- El volumen no se acotaba y `seek` aceptaba `NaN`.

### Interfaz

Registro facial con anillo de tramos radiales estilo Face ID —mueves la cabeza y
cada sector se enciende al capturar su ángulo— y tarjeta de autenticación con
los estados Buscando / Localizado / Desbloqueado. Liquid Glass en macOS 26 con
respaldo en versiones anteriores. Respeta *Reducir movimiento*.

## Documentación

- [`DOCS-ES/AUDITORIA.md`](DOCS-ES/AUDITORIA.md) — hallazgos con líneas exactas,
  tabla de estado de funciones y plan por fases.
- [`DOCS-ES/COMPILAR.md`](DOCS-ES/COMPILAR.md) — cómo compilarlo en tu Mac.

## Antes de compilar

Los binarios grandes de upstream (el modelo `ArcFace` de 84 MB, vídeos de demo,
`SystemSounds`, `.dylib`) no se versionan aquí. Recupéralos con:

```bash
./scripts-personal/restaurar-binarios.sh
```

## Estado

**Este código no se ha compilado.** Se escribió en un contenedor Linux sin
macOS ni Xcode; la verificación fue por lectura. Ver `DOCS-ES/AUDITORIA.md §4`
para qué está comprobado y qué no.
