# Instalar Sapphire Personal en tu Mac

Hay dos caminos. El segundo es mejor para uso diario.

---

## Camino A — descargar el .dmg que compila GitHub

No necesitas Xcode. GitHub compila la app en un runner macOS y deja el `.dmg`
listo para descargar.

1. Ve a la pestaña **Actions** del repositorio.
2. Abre la ejecución más reciente de **«Construir app de macOS»** (o lánzala tú
   con *Run workflow*).
3. Descarga el artefacto **`Sapphire-dmg`**.
4. Descomprime, abre el `.dmg` y arrastra `Sapphire.app` a *Aplicaciones*.
5. Quita la cuarentena y ábrela por primera vez:

   ```bash
   xattr -dr com.apple.quarantine /Applications/Sapphire.app
   open /Applications/Sapphire.app
   ```

**La pega:** esa app va firmada *ad-hoc*, no con un Developer ID. La firma
cambia en cada compilación, así que macOS considera cada versión una app nueva
y **te volverá a pedir todos los permisos** (cámara, automatización,
accesibilidad) cada vez que actualices. Para probarla está bien; para usarla a
diario, mejor el camino B.

---

## Camino B — compilar en tu Mac con tu propio Apple ID

Te da una firma estable: concedes los permisos una vez y se quedan.
No hace falta pagar los 99 €/año: **un Apple ID gratuito sirve**.

### 1. Preparar

```bash
git clone https://github.com/Carrillooo/copiamejoradasapphire.git
cd copiamejoradasapphire
./scripts-personal/restaurar-binarios.sh
```

### 2. Añadir tu Apple ID a Xcode

Xcode → *Settings* → *Accounts* → **+** → *Apple ID*. Con eso Xcode crea un
«Personal Team». Busca tu Team ID:

```bash
security find-identity -v -p codesigning
```

### 3. Compilar

```bash
./scripts-personal/construir-app.sh TU_TEAM_ID
```

Sin Team ID, compila con firma ad-hoc:

```bash
./scripts-personal/construir-app.sh
```

El proyecto viene con `DEVELOPMENT_TEAM = KVQFWJ7C7S`, que es el equipo del
autor original de Sapphire: **en tu Mac no vale**. El script lo sobreescribe
siempre, por eso hay que usarlo en vez de pulsar «Run» en Xcode a secas. Si
prefieres Xcode, cambia el equipo a mano en *Signing & Capabilities*.

### 4. Instalar

```bash
cp -R build/Build/Products/Release/Sapphire.app /Applications/
open /Applications/Sapphire.app
```

O haz un `.dmg`: `./scripts-personal/crear-dmg.sh`

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

**«No se puede abrir porque Apple no puede comprobar que no contiene
software malicioso»** → es la cuarentena:
`xattr -dr com.apple.quarantine /Applications/Sapphire.app`

**La compilación falla con «Signing for … requires a development team»** →
estás compilando sin sobreescribir el equipo del autor. Usa
`construir-app.sh` con tu Team ID.

**Falla con «SDK does not support deployment target»** → tu Xcode es anterior
al SDK de macOS 26. Actualiza Xcode, o compila con un objetivo más bajo:

```bash
xcodebuild -project Sapphire.xcodeproj -scheme Sapphire -configuration Release \
  -derivedDataPath build MACOSX_DEPLOYMENT_TARGET=15.0 \
  CODE_SIGN_IDENTITY="-" CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM="" build
```

**El reconocimiento facial no autentica nunca** → es lo correcto y es
deliberado. Falta el modelo de detección de suplantación, que no se distribuye
con el código fuente. Sin él la app **no autentica** en vez de dejar pasar a
cualquiera con una foto. Ver `AUDITORIA.md §1.1`.

**Otro error de compilación** → pásame `build.log`, que es justo lo que me
falta para cerrar esto.
