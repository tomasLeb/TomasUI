# Cambios

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
