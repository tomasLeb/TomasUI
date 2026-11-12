# TomasUI

Interfaz para **WoW Forever** basada en ElvUI y Plater: pixel perfect y con el mismo aspecto en cualquier monitor.

- Un perfil de ElvUI y otro de Plater listos para usar.
- Igual en 1080p y 1440p (también ultrapanorámicos): misma escala y posiciones calculadas sobre una rejilla de 3/6 unidades.
- Coloca el swing timer de Blizzard, el marco de misiones y una ventana de Details!.
- Crea dos distribuciones del modo edición (`TomasUI - Melee` y `TomasUI - Ranged`) y activa la adecuada según tu clase.
- Te avisa cuando hay una versión nueva del perfil.

## Requisitos

| Addon | |
|---|---|
| [ElvUI](https://tukui.org/elvui) (versión Forever) | Obligatorio |
| [Plater](https://www.curseforge.com/wow/addons/plater-nameplates) | Recomendado (placas de nombre) |
| [Details!](https://www.curseforge.com/wow/addons/details) | Opcional (medidor de daño) |

## Instalación

### Con WowUp (recomendado: se actualiza solo)
1. En WowUp, elige **WoW Forever**.
2. *Get Addons* → **Install from URL** → `https://github.com/tomasLeb/TomasUI`
3. Cuando salga una versión nueva, WowUp la marcará para actualizar.

### A mano
1. Descarga el `.zip` de la última versión en [Releases](https://github.com/tomasLeb/TomasUI/releases).
2. Descomprímelo en `World of Warcraft\_forever_\Interface\AddOns\` (debe quedar la carpeta `TomasUI`).

### Primera vez en el juego
1. Entra con tu personaje. A los pocos segundos aparece un aviso: pulsa **Aplicar**. La interfaz se recarga.
2. Si te dice que ha creado las distribuciones del modo edición, haz `/reload` una vez más.
3. Repite el paso 1 con cada personaje (los ajustes privados de ElvUI son por personaje).

## Comandos

| Comando | Para qué |
|---|---|
| `/tui` | Ayuda y versión |
| `/tui aplicar` | Vuelve a aplicar el perfil empaquetado |
| `/tui edicion` | Activa la distribución del modo edición de tu clase |
| `/tui edicion off` | Deja de cambiarla automáticamente |
| `/tui escala` | Muestra la escala actual y la del autor |
| `/tui escala propia` / `auto` | Mantener tu escala de ElvUI / usar la del autor (por defecto) |

## Qué se toca al aplicar

- **ElvUI:** perfil `TomasUI` (se crea o sobrescribe y se activa), ajustes privados del personaje, escala de UI y dos paneles de datos propios.
- **Plater:** perfil `TomasUI`.
- **Modo edición:** crea `TomasUI - Melee` y `TomasUI - Ranged` si no existen (no toca tus otras distribuciones).
- **Details!:** deja una sola ventana abajo a la derecha.

Tus otros perfiles de ElvUI y Plater no se modifican: para volver atrás, elige tu perfil anterior en `/ec` → Perfiles.

---

## Para el autor: publicar una versión nueva

1. Haz los cambios en el juego (con el perfil `TomasUI` activo).
2. `/tui export` y luego `/reload` (para que se guarde en disco).
3. Genera `Data.lua`:
   ```
   python tools/build_data.py "C:\Program Files (x86)\World of Warcraft\_forever_\WTF\Account\<CUENTA>\SavedVariables\TomasUI.lua"
   ```
   (Alternativa: copiar el texto de la ventana de `/tui export` y pegarlo entero en `Data.lua`.)
4. Si cambias algo que no está en los perfiles (paneles propios, swing timer, Details!, marco de misiones, ajustes forzados), edita `Config.lua`.
5. Apunta los cambios en `CHANGELOG.md`, haz commit y crea una etiqueta de versión:
   ```
   git tag v1.1.0
   git push --follow-tags
   ```
   GitHub Actions empaqueta el addon y publica la release; WowUp la ofrecerá a todos.

### Estructura

| Fichero | Qué es |
|---|---|
| `Data.lua` | **Generado.** Perfiles exportados (ElvUI, privados, Plater), distribuciones del modo edición y medidas de la pantalla del autor. |
| `Config.lua` | **A mano.** Todo lo que no va en los perfiles o se fuerza encima. |
| `Core.lua` | Lógica: aplicar, escala, recolocar movers, swing timer, Details!, modo edición… |
| `Export.lua` | `/tui export`. |
| `tools/build_data.py` | SavedVariables → `Data.lua`. |
| `tools/decode.py` | Decodifica cadenas `!E2!` / `!PLATER:2!` a JSON para revisar cambios (`pip install cbor2`). |
| `tools/layout_pp.py` | Genera el perfil pixel perfect desde el perfil original (`tools/base_profile.txt`); documenta la rejilla. |

### Por qué se ve igual en todos los monitores

- **Escala:** ElvUI no exporta la escala de UI. TomasUI pone la misma que la del autor (0,711), así que la pantalla mide 1080 unidades de alto en cualquier resolución.
- **Posiciones:** lo central se ancla al centro de la pantalla y lo pegado a los bordes, a su borde; algunos marcos se anclan a otros (objetivo del objetivo al objetivo, estado de cola al minimapa…).
- **Rejilla:** en 1440p una unidad son 1,333 px, así que tamaños y posiciones van en múltiplos de 3 (y de 6 lo centrado) para caer en píxeles enteros.
