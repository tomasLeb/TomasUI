# Cambios

## v1.4.0 — 2026-11-14

- Plater: en "solo nombre", el **nivel** de los jugadores aliados va en la misma línea que el nombre, `27 · Nombre`: el nivel en dorado, el punto en blanco y el nombre en su color de clase (`??` en rojo si es una calavera). Se ajusta en `nameOnlyLevel` de `Config.lua` (también se puede poner encima o a la izquierda del nombre, o en color de dificultad).
- ElvUI: quitado el texto de nivel a la izquierda del marco de objetivo; se desactiva en los perfiles que ya lo tenían.

## v1.3.5 — 2026-11-14

- Plater: el halo de vida baja en "solo nombre" aparece por debajo del 25 % de vida (antes, 50 %).

## v1.3.4 — 2026-11-13

- Plater: el escudito gris de "no interrumpible" va en el borde contrario al icono del hechizo (a la derecha con tu perfil), para que no lo tape.

## v1.3.3 — 2026-11-13

- Plater: en todas las placas con barra, las auras quedan justo encima del nombre, con la misma separación que entre el nombre y la barra (antes solo con hermandad; sin ella quedaban pegadas al nombre).

## v1.3.2 — 2026-11-13

- Plater: corregido el nombre que a veces quedaba encima de la hermandad. Pasaba cuando Plater reutilizaba una placa que antes había estado en "solo nombre".

## v1.3.1 — 2026-11-13

- Plater: la **hermandad** se muestra bajo el nombre de los jugadores (aliados y enemigos) en todos los personajes, forzado sobre el perfil. Faltaba en el perfil empaquetado.

## v1.3.0 — 2026-11-13

### Plater
- **Jugadores aliados en "solo nombre"**, sin barra ni auras. Si tu árbol de talentos con más puntos es de sanador (Disciplina o Sagrado en sacerdote, Sagrado en paladín, Restauración en druida y chamán), se ven sus barras de vida. Cambia solo al gastar o cambiar puntos. `/tui rol` muestra lo que detecta.
- En "solo nombre", **halo rojo detrás del nombre** de los aliados por debajo del 50 % de vida (también en combate). Usa la textura "Spark" de ElvUI.
- En "solo nombre" ya no se quedan auras visibles por error.
- **Nombres en color de clase** (aliados y enemigos), forzado sobre el perfil.
- **Hermandad** de jugadores en su propia línea, del mismo tamaño que el nombre, y nombre y hermandad 2 px más separados de la barra. En las placas con barra sin hermandad (jugadores y PNJ), el nombre también sube 2 px.
- **Texto en ruso:** los títulos de PNJ (p. ej. `<Esbirro de …>`) y las hermandades se pasan a letras latinas como los nombres, cuando Plater tiene activada esa opción (Righteous no tiene letras cirílicas).

### ElvUI
- **Nivel del objetivo** a la izquierda de su barra de vida, fuera del marco, en color de dificultad.
- **Marco de mascota** con el mismo alto que jugador y objetivo (42): vida y poder iguales.

### Interno
- Los ajustes forzados de ElvUI y Plater se aplican al entrar al juego si faltan en el perfil, sin tener que reimportarlo.

## v1.2.1 — 2026-11-13

- La caja para escribir en el chat se abre encima del chat, sin tapar mensajes.
- Oculto el botón de voz (altavoz) del chat.
- Corregido: los ajustes que ElvUI no importa desde un perfil (como ocultar los botones de voz) ahora también se aplican.
- Los que ya tengan TomasUI verán el aviso para aplicar la versión nueva.

## v1.2.0 — 2026-11-12

- La fuente **Righteous** viene incluida en el addon (`Media/`, licencia OFL): ya no hace falta tocar la carpeta `Fonts` del juego.
- Al aplicar, todo pasa a Righteous: en ElvUI, Plater y Details! lo que usaba Arial Narrow o Friz Quadrata, y en ElvUI también PT Sans Narrow y Expressway (incluidos los valores por defecto: placas, bocadillos, nombres y números de daño).
- Righteous aparece en las listas de fuentes de ElvUI, Plater y Details!.
- Queda con la fuente de Blizzard lo que el addon no puede cambiar: la pantalla de selección de personajes y el texto de combate sobre ti (daño y curación recibidos).

## v1.1.0 — 2026-11-12

- El pack incluye el perfil de **Details!** (aspecto, barras de abajo arriba…): se importa como perfil `TomasUI` al aplicar y se exporta con `/tui export`.
- El aviso de versión nueva menciona Details!.

## v1.0.0 — 2026-11-12

Primera versión pública.

### Perfil (pixel perfect)
- Rejilla de 3/6 unidades: limpia en 1080p y 1440p.
- Bloque central de 1062 de ancho: barras de acción con hueco central, grupo y bandas (5 × 210), barra de experiencia.
- Hueco central con paneles de durabilidad (arriba) y FPS/latencia (abajo).
- Barras de lanzamiento de jugador y objetivo debajo de sus marcos (21 de alto); el maná siempre visible.
- Auras de jugador, objetivo y grupo: 10 por fila de 21, pegadas al marco.
- Objetivo del objetivo y del foco anclados a su marco.
- Maná en formas de druida a la izquierda del jugador; puntos de combo ocultos (se ven en Plater).
- Columna derecha de 261: minimapa (calendario arriba a la izquierda, sin rastreo), microbarra, marco de misiones y Details!.
- Marco BNet y consultas al MJ arriba a la izquierda; aviso de cambio de capa encima de la barra de bolsas.
- Sin panel de datos izquierdo ni derecho; cuadro de chat dentro del chat.

### Addon
- Aviso de versión nueva y `/tui aplicar`.
- Misma escala que el autor y recolocación de marcos independiente del ancho del monitor.
- Swing timer de Blizzard bajo la barra de lanzamiento (mano derecha o distancia según la clase).
- Distribuciones del modo edición `TomasUI - Melee` / `TomasUI - Ranged`: se crean si faltan y se activa la de la clase.
- Marco de misiones recolocado vía modo edición, con hueco abajo para Details!.
- Details!: una sola ventana abajo a la derecha.
- Línea en el borde de la vida (color de clase aclarado), solo cuando falta vida.
- `/tui export` + `tools/build_data.py` para publicar versiones nuevas.
