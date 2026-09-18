#!/usr/bin/env bash
# Empaqueta un Sapphire.app ya compilado en un .dmg con enlace a /Applications.
#
#   ./scripts-personal/crear-dmg.sh ruta/a/Sapphire.app
#
# Sin argumento, busca la app en la ruta de compilación por defecto.
set -euo pipefail

APP="${1:-build/Build/Products/Release/Sapphire.app}"

if [ ! -d "$APP" ]; then
  echo "No encuentro la app en: $APP" >&2
  echo "Compílala antes con ./scripts-personal/construir-app.sh" >&2
  exit 1
fi

if [ "$(uname)" != "Darwin" ]; then
  echo "Esto sólo funciona en macOS: hdiutil no existe en otros sistemas." >&2
  exit 1
fi

VERSION="$(date +%Y%m%d)"
NAME="SapphirePersonal-$VERSION"
DIST="dist"
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

mkdir -p "$DIST"
rm -f "$DIST/$NAME.dmg"

echo "Preparando contenido…"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"

# Aviso dentro del propio DMG: sin esto, el usuario se encuentra con Gatekeeper
# y no sabe qué hacer.
cat > "$STAGE/LEEME.txt" <<'TXT'
Sapphire Personal
=================

1. Arrastra Sapphire.app a la carpeta Applications.

2. La app está firmada ad-hoc, no con un Developer ID de Apple. Al abrirla,
   macOS la bloqueará. Para permitirla, en el Terminal:

       xattr -dr com.apple.quarantine /Applications/Sapphire.app

   Y ábrela la primera vez con clic derecho -> Abrir.

3. Concede los permisos cuando los pida (cámara, automatización para Spotify,
   accesibilidad). Al estar firmada ad-hoc, la firma cambia en cada versión y
   macOS volverá a pedirlos tras cada actualización.

Obra derivada de https://github.com/cshariq/Sapphire bajo licencia AGPL-3.0.
TXT

echo "Creando $DIST/$NAME.dmg…"
hdiutil create \
  -volname "Sapphire Personal" \
  -srcfolder "$STAGE" \
  -ov -format UDZO \
  "$DIST/$NAME.dmg"

echo
echo "Listo: $DIST/$NAME.dmg"
