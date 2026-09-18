#!/usr/bin/env bash
# Empaqueta Iris.app en un .dmg con la ventana de instalación clásica:
# el icono de la app a la izquierda, Aplicaciones a la derecha, y arrastras.
#
#   ./scripts-personal/crear-dmg.sh [ruta/a/Iris.app]
#
# Firma y notarización (opcional). Si defines estas variables, el .dmg sale
# firmado con Developer ID y notarizado por Apple, y entonces se instala como
# cualquier app: sin avisos, sin Terminal, sin "Abrir de todos modos".
# Requiere cuenta de desarrollador de pago.
#
#   DEVELOPER_ID="Developer ID Application: Nombre (TEAMID)"
#   AC_APPLE_ID="tu@correo.com"
#   AC_TEAM_ID="TEAMID"
#   AC_PASSWORD="xxxx-xxxx-xxxx-xxxx"   # contraseña específica de app
#
# Sin esas variables, el .dmg se genera igual pero con firma ad-hoc: funciona,
# pero macOS avisará la primera vez (ver DOCS-ES/INSTALAR.md).
set -euo pipefail

APP="${1:-build/Build/Products/Release/Iris.app}"

if [ "$(uname)" != "Darwin" ]; then
  echo "Esto sólo funciona en macOS: hdiutil no existe en otros sistemas." >&2
  exit 1
fi
if [ ! -d "$APP" ]; then
  echo "No encuentro la app en: $APP" >&2
  echo "Compílala antes con ./scripts-personal/construir-app.sh" >&2
  exit 1
fi

VOL="Iris"
NAME="Iris-$(date +%Y%m%d)"
DIST="dist"
STAGE="$(mktemp -d)"
RW="$(mktemp -u).dmg"
cleanup() {
  [ -n "${MOUNTED:-}" ] && hdiutil detach "$MOUNTED" -quiet 2>/dev/null || true
  rm -rf "$STAGE" "$RW"
}
trap cleanup EXIT

mkdir -p "$DIST"
rm -f "$DIST/$NAME.dmg"

# --- Firma con Developer ID, si está disponible -----------------------------
if [ -n "${DEVELOPER_ID:-}" ]; then
  echo "Firmando la app con: $DEVELOPER_ID"
  # --deep está obsoleto; hay que firmar de dentro hacia fuera. Primero todo lo
  # anidado (helpers, extensiones, frameworks), luego el bundle principal.
  find "$APP/Contents" \( -name "*.app" -o -name "*.xpc" -o -name "*.framework" -o -name "*.dylib" -o -name "*.bundle" \) -depth | while read -r item; do
    codesign --force --options runtime --timestamp --sign "$DEVELOPER_ID" "$item" || true
  done
  codesign --force --options runtime --timestamp \
    --entitlements Sapphire/Sapphire.entitlements \
    --sign "$DEVELOPER_ID" "$APP"
  codesign --verify --deep --strict --verbose=2 "$APP"
else
  echo "Sin DEVELOPER_ID: la app conserva la firma con que se compiló (ad-hoc)."
fi

# --- Contenido del disco ----------------------------------------------------
echo "Preparando el contenido…"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"

# --- Imagen de lectura/escritura para poder maquetar la ventana -------------
echo "Creando imagen temporal…"
hdiutil create -srcfolder "$STAGE" -volname "$VOL" -fs HFS+ \
  -format UDRW -quiet "$RW"

MOUNTED="/Volumes/$VOL"
hdiutil attach "$RW" -mountpoint "$MOUNTED" -nobrowse -quiet

# Maquetado de la ventana: tamaño, iconos grandes y las dos posiciones.
# Es lo que hace que se vea como el instalador de cualquier app de Mac.
osascript <<OSA 2>/dev/null || echo "Aviso: no se pudo maquetar la ventana (¿sin sesión gráfica?). El .dmg funciona igual."
tell application "Finder"
  tell disk "$VOL"
    open
    set current view of container window to icon view
    set toolbar visible of container window to false
    set statusbar visible of container window to false
    set the bounds of container window to {200, 120, 800, 520}
    set theViewOptions to the icon view options of container window
    set arrangement of theViewOptions to not arranged
    set icon size of theViewOptions to 128
    set position of item "Iris.app" of container window to {150, 190}
    set position of item "Applications" of container window to {450, 190}
    close
    open
    update without registering applications
    delay 2
  end tell
end tell
OSA

sync
hdiutil detach "$MOUNTED" -quiet
MOUNTED=""

# --- Comprimir a sólo lectura ----------------------------------------------
echo "Comprimiendo…"
hdiutil convert "$RW" -format UDZO -imagekey zlib-level=9 -quiet -o "$DIST/$NAME.dmg"

# --- Firmar y notarizar el .dmg --------------------------------------------
if [ -n "${DEVELOPER_ID:-}" ]; then
  codesign --force --sign "$DEVELOPER_ID" "$DIST/$NAME.dmg"

  if [ -n "${AC_APPLE_ID:-}" ] && [ -n "${AC_TEAM_ID:-}" ] && [ -n "${AC_PASSWORD:-}" ]; then
    echo "Enviando a notarizar (esto tarda unos minutos)…"
    xcrun notarytool submit "$DIST/$NAME.dmg" \
      --apple-id "$AC_APPLE_ID" \
      --team-id "$AC_TEAM_ID" \
      --password "$AC_PASSWORD" \
      --wait
    echo "Grapando el ticket…"
    xcrun stapler staple "$DIST/$NAME.dmg"
    xcrun stapler validate "$DIST/$NAME.dmg"
    echo
    echo "Notarizado. Este .dmg se instala sin ningún aviso."
  else
    echo "Firmado con Developer ID pero SIN notarizar."
    echo "Gatekeeper seguirá avisando hasta que se notarice."
  fi
fi

echo
echo "Listo: $DIST/$NAME.dmg"
if [ -z "${DEVELOPER_ID:-}" ]; then
  echo
  echo "Firma ad-hoc: al descargarlo, macOS pedirá confirmación la primera vez."
  echo "Instrucciones sin Terminal en DOCS-ES/INSTALAR.md."
fi
