#!/usr/bin/env bash
# Compila Iris y deja Iris.app en build/Build/Products/Release/.
#
#   ./scripts-personal/construir-app.sh              # firma ad-hoc, sin Apple ID
#   ./scripts-personal/construir-app.sh TEAMID       # firma con tu equipo
#   ./scripts-personal/construir-app.sh TEAMID Debug # configuración Debug
#
# El Team ID lo ves en Xcode -> Settings -> Accounts, o con:
#   security find-identity -v -p codesigning
set -euo pipefail

TEAM="${1:-}"
CONFIG="${2:-Release}"

if [ "$(uname)" != "Darwin" ]; then
  echo "Esto necesita macOS con Xcode. No se puede compilar en otro sistema." >&2
  exit 1
fi

if ! command -v xcodebuild >/dev/null; then
  echo "No hay xcodebuild. Instala Xcode desde la App Store." >&2
  exit 1
fi

if [ ! -d "Sapphire/Services/FaceID/Models/ArcFace.mlpackage" ]; then
  echo "AVISO: falta el modelo ArcFace. El reconocimiento facial no funcionará."
  echo "       Recupéralo con ./scripts-personal/restaurar-binarios.sh"
  echo
fi

echo "=== Entorno ==="
sw_vers | sed 's/^/  /'
echo "  arquitectura: $(uname -m)"
xcodebuild -version | sed 's/^/  /'
echo

# El proyecto viene con DEVELOPMENT_TEAM = KVQFWJ7C7S, el equipo del autor
# original. Hay que sobreescribirlo siempre: con tu equipo, o con firma ad-hoc.
if [ -n "$TEAM" ]; then
  echo "=== Compilando ($CONFIG) firmando con el equipo $TEAM ==="
  SIGN_ARGS=(
    CODE_SIGN_STYLE=Automatic
    DEVELOPMENT_TEAM="$TEAM"
  )
else
  echo "=== Compilando ($CONFIG) con firma ad-hoc ==="
  echo "    (en Apple Silicon una app sin firma no arranca; ad-hoc es el mínimo)"
  # Entitlements reducidos: los normales llevan
  # com.apple.developer.system-extension.install, un entitlement restringido
  # que sin perfil de Apple impide que macOS lance la app.
  SIGN_ARGS=(
    CODE_SIGN_IDENTITY="-"
    CODE_SIGN_STYLE=Manual
    DEVELOPMENT_TEAM=""
    PROVISIONING_PROFILE_SPECIFIER=""
    ENABLE_HARDENED_RUNTIME=NO
    SAPPHIRE_ENTITLEMENTS=Sapphire/Sapphire-adhoc.entitlements
    WIDGETS_ENTITLEMENTS=Sapphire/Sapphire-adhoc.entitlements
  )
fi
echo

set -o pipefail
xcodebuild \
  -project Sapphire.xcodeproj \
  -scheme Sapphire \
  -configuration "$CONFIG" \
  -derivedDataPath build \
  -destination 'generic/platform=macOS' \
  ONLY_ACTIVE_ARCH=NO \
  "${SIGN_ARGS[@]}" \
  build 2>&1 | tee build.log || {
    echo
    echo "=== La compilación ha fallado. Errores: ==="
    grep -E "error:" build.log | sort -u | head -40 || true
    echo
    echo "El registro completo está en build.log"
    exit 1
  }

APP="build/Build/Products/$CONFIG/Iris.app"
echo
echo "Listo: $APP"
echo "Para abrirla:        open \"$APP\""
echo "Para hacer un .dmg:  ./scripts-personal/crear-dmg.sh \"$APP\""
