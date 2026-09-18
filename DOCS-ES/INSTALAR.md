# Instalar Sapphire Personal en tu Mac

## Por qué macOS avisa (y cuándo no avisa)

Para que un `.dmg` descargado se instale sin un solo aviso, la app tiene que ir
firmada con un **Developer ID** y **notarizada por Apple**. Eso exige la cuenta
de desarrollador de pago (99 €/año). Un Apple ID gratuito no vale: sus
certificados son de desarrollo, caducan a los 7 días y no permiten notarizar.

Esa es una regla de Gatekeeper, no una carencia de este proyecto.

Tres escenarios, de menos a más fricción:

| Cómo la obtienes | Avisos de macOS |
|---|---|
| La compilas tú en tu Mac (camino B) | **Ninguno.** La cuarentena sólo se aplica a lo descargado |
| `.dmg` descargado, firma ad-hoc (camino A) | Un aviso la primera vez. Se resuelve en Ajustes, sin Terminal |
| `.dmg` notarizado (camino C) | Ninguno. Requiere cuenta de pago |

---

## Camino A — descargar el .dmg ya compilado

No necesitas Xcode. GitHub compila la app y deja el `.dmg` listo.

1. Pestaña **Actions** del repositorio.
2. Abre la última ejecución de **«Construir app de macOS»**.
3. Descarga el artefacto **`Sapphire-dmg`** y descomprímelo.
4. Abre el `.dmg` y **arrastra Sapphire a la carpeta Aplicaciones**, como
   cualquier app.
5. La primera vez que la abras, macOS dirá que no puede comprobarla. **Sin
   tocar el Terminal:**
   - Ve a  → *Ajustes del Sistema* → *Privacidad y seguridad*.
   - Baja hasta abajo: verás «Se ha bloqueado el uso de "Sapphire"…».
   - Pulsa **«Abrir de todos modos»** y confirma.

   Sólo hay que hacerlo una vez por versión.

Si prefieres el Terminal, una línea hace lo mismo:

```bash
xattr -dr com.apple.quarantine /Applications/Sapphire.app
```

> **La pega del camino A:** la firma ad-hoc cambia en cada compilación, así que
> macOS considera cada versión una app nueva y **vuelve a pedirte los permisos**
> (cámara, automatización, accesibilidad) al actualizar. Para probarla está
> bien; para el día a día, el camino B.

---

## Camino B — compilar en tu Mac *(recomendado)*

Firma estable, permisos concedidos una sola vez y **cero avisos de Gatekeeper**,
porque una app que no se ha descargado nunca entra en cuarentena.
Un **Apple ID gratuito basta**.

### 1. Preparar

```bash
git clone https://github.com/Carrillooo/copiamejoradasapphire.git
cd copiamejoradasapphire
./scripts-personal/restaurar-binarios.sh
```

### 2. Añadir tu Apple ID a Xcode

Xcode → *Settings* → *Accounts* → **+** → *Apple ID*. Eso crea un «Personal
Team». Para ver tu Team ID:

```bash
security find-identity -v -p codesigning
```

### 3. Compilar e instalar

```bash
./scripts-personal/construir-app.sh TU_TEAM_ID
cp -R build/Build/Products/Release/Sapphire.app /Applications/
open /Applications/Sapphire.app
```

El proyecto viene con `DEVELOPMENT_TEAM = KVQFWJ7C7S`, el equipo del autor
original de Sapphire: **en tu Mac no vale**. El script lo sobreescribe siempre,
por eso conviene usarlo en lugar de pulsar «Run» en Xcode a secas.

---

## Camino C — .dmg notarizado *(si tienes cuenta de desarrollador)*

Ya está montado. Añade estos secretos en *Settings → Secrets and variables →
Actions* del repositorio y el workflow firmará y notarizará solo:

| Secreto | Qué es |
|---|---|
| `DEVELOPER_ID_P12` | Tu certificado *Developer ID Application* exportado a `.p12` y codificado en base64 |
| `DEVELOPER_ID_P12_PASSWORD` | La contraseña del `.p12` |
| `DEVELOPER_ID_NAME` | `Developer ID Application: Tu Nombre (TEAMID)` |
| `AC_APPLE_ID` | El correo de tu cuenta de desarrollador |
| `AC_TEAM_ID` | Tu Team ID |
| `AC_PASSWORD` | Una contraseña específica de app, de appleid.apple.com |

Para exportar el certificado a base64:

```bash
base64 -i certificado.p12 | pbcopy
```

Con esos secretos puestos, el `.dmg` que produce el workflow se instala como el
de cualquier app comercial: doble clic, arrastrar, abrir. Sin avisos.

En local es lo mismo:

```bash
DEVELOPER_ID="Developer ID Application: Tu Nombre (TEAMID)" \
AC_APPLE_ID="tu@correo.com" AC_TEAM_ID="TEAMID" AC_PASSWORD="xxxx-xxxx-xxxx-xxxx" \
./scripts-personal/crear-dmg.sh
```

---

## Permisos

Concédelos sólo cuando uses cada función:

| Permiso | Para qué | Dónde |
|---|---|---|
| Cámara | Reconocimiento facial | Privacidad y seguridad → Cámara |
| Automatización | Control local de Spotify | Privacidad y seguridad → Automatización |
| Accesibilidad | Gestión de ventanas, llamadas | Privacidad y seguridad → Accesibilidad |
| Bluetooth | Desbloqueo por proximidad | Privacidad y seguridad → Bluetooth |

---

## Si algo va mal

**«No se puede abrir porque Apple no puede comprobar…»** → es la cuarentena.
Ajustes del Sistema → Privacidad y seguridad → «Abrir de todos modos».

**«Signing for … requires a development team»** al compilar → estás usando el
equipo del autor original. Usa `construir-app.sh` con tu Team ID.

**«SDK does not support deployment target»** → tu Xcode es anterior al SDK de
macOS 26. Actualiza Xcode, o baja el objetivo:

```bash
./scripts-personal/construir-app.sh "" Release   # y edita MACOSX_DEPLOYMENT_TARGET
```

**El reconocimiento facial no autentica nunca** → es deliberado y es lo
correcto. Falta el modelo de detección de suplantación, que no se distribuye con
el código. Sin él la app **no autentica**, en vez de dejar entrar a cualquiera
con una foto. Ver `AUDITORIA.md §1.1`.

**Otro error de compilación** → pásame el `build.log`.
