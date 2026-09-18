#!/usr/bin/env bash
# Descarga los binarios OPCIONALES de upstream que no se versionan aquí.
#
# Lo que hace falta para COMPILAR (SystemSounds, los .dylib de libimobiledevice)
# sí está en el repositorio: la app compila sin ejecutar este script.
#
# Esto sólo trae:
#   - ArcFace.mlpackage (84 MB): modelo de reconocimiento facial. Sin él la app
#     compila y arranca, pero el reconocimiento facial no funciona.
#   - Assets/*.mp4 y *.mov (54 MB): vídeos de demostración del README.
set -euo pipefail

UPSTREAM="https://github.com/cshariq/Sapphire.git"
COMMIT="798d117d"                     # commit del que procede esta copia
DEST="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "Clonando upstream (sólo lo necesario)…"
# Sin --no-checkout: necesitamos los ficheros en disco. sparse-checkout limita
# la descarga a las rutas que faltan.
git clone --filter=blob:none --sparse --depth 50 "$UPSTREAM" "$TMP/sapphire"
git -C "$TMP/sapphire" sparse-checkout set \
  "Sapphire/Services/FaceID/Models" \
  "Assets"

# El commit exacto puede quedar fuera de los 50 últimos; si no está, se usa la
# punta de la rama y se avisa, en vez de fallar.
if git -C "$TMP/sapphire" cat-file -e "$COMMIT^{commit}" 2>/dev/null; then
  git -C "$TMP/sapphire" checkout --quiet "$COMMIT"
else
  echo "AVISO: el commit $COMMIT no está en el historial descargado."
  echo "       Se usan los binarios de la punta de la rama."
fi

copiar() {
  local ruta="$1" etiqueta="$2"
  if [ -e "$TMP/sapphire/$ruta" ]; then
    echo "Restaurando $etiqueta…"
    mkdir -p "$DEST/$(dirname "$ruta")"
    cp -R "$TMP/sapphire/$ruta" "$DEST/$(dirname "$ruta")/"
  else
    echo "AVISO: $ruta no está en upstream." >&2
  fi
}

copiar "Sapphire/Services/FaceID/Models/ArcFace.mlpackage" "modelo ArcFace (84 MB)"

echo "Restaurando vídeos de demostración…"
mkdir -p "$DEST/Assets"
find "$TMP/sapphire/Assets" \( -name '*.mp4' -o -name '*.mov' \) \
  -exec cp {} "$DEST/Assets/" \; 2>/dev/null || true

# --- Verificación: el script no termina en silencio si no ha hecho nada ------
MODELO="$DEST/Sapphire/Services/FaceID/Models/ArcFace.mlpackage"
echo
if [ -d "$MODELO" ]; then
  echo "✓ Modelo ArcFace restaurado ($(du -sh "$MODELO" | cut -f1))"
else
  echo "✗ No se ha podido restaurar el modelo ArcFace." >&2
  echo "  La app compilará, pero el reconocimiento facial no funcionará." >&2
  exit 1
fi
echo "✓ Vídeos de demostración: $(find "$DEST/Assets" \( -name '*.mp4' -o -name '*.mov' \) | wc -l | tr -d ' ') ficheros"

echo
echo "Nota: el modelo de LIVENESS (PassiveLiveness) no está en upstream — se"
echo "descarga y descifra en ejecución con la clave del autor original. Sin él,"
echo "la autenticación facial queda deshabilitada a propósito (fail-closed)."
echo "Ver DOCS-ES/AUDITORIA.md §1.1."
