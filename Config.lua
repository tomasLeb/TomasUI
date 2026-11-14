-- TomasUI · Config.lua
-- Configuración que se mantiene a mano (no la toca /tui export).
-- Todo lo que vive fuera del perfil de ElvUI/Plater o que hay que forzar encima va aquí.
-- Las rutas "a.b.c" apuntan a claves anidadas de la tabla correspondiente.

local _, ns = ...

ns.Config = {
	-- Nombre del perfil que se crea en ElvUI y Plater
	profileName = 'TomasUI',

	-- Personajes del autor (clave de ElvUI "Nombre Reino"): no se les pide aplicar el perfil
	-- y en ellos se guarda una copia de las distribuciones del modo edición para exportarlas.
	authors = {
		'Amarant Rojo', 'Artemisa Heartilly', 'Balthier Ivalice',
		'Dagger Alexandros', 'Fusoya Lunarian', 'Juez Gabranth',
	},

	-- Distribuciones del modo edición de Blizzard según el golpe que importa a la clase
	editModeLayouts = { ranged = 'TomasUI - Ranged', melee = 'TomasUI - Melee' },
	rangedSwingClasses = { HUNTER = true, WARLOCK = true, MAGE = true, PRIEST = true },

	-- Se fuerzan encima del perfil de ElvUI al aplicar
	profileOverrides = {
		['datatexts.panels.RightChatDataPanel.enable'] = false,
		['chat.hideVoiceButtons'] = true, -- sin el altavoz de canales de chat
		['chat.editBoxPosition'] = 'ABOVE_CHAT', -- escribir encima del chat: no tapa mensajes

		-- Mascota con el mismo alto que jugador y objetivo: vida y poder de 21 cada una
		-- (sin esto ElvUI le da 36 y la vida queda más baja que el poder)
		['unitframe.units.pet.height'] = 42,

		-- El texto de nivel a la izquierda del marco de objetivo (v1.3.0) ya no se usa:
		-- se desactiva en los perfiles que lo tengan
		['unitframe.units.target.customTexts.TomasUI_Nivel.enable'] = false,
	},

	-- Se fuerzan encima de los ajustes privados de ElvUI (por personaje) al aplicar
	privateOverrides = {
		['general.minimap.hideTracking'] = true,
		['general.minimap.hideCalendar'] = false,
		['general.totemTracker'] = false,
	},

	-- Se fuerzan encima del perfil TomasUI de Plater al entrar al juego
	platerOverrides = {
		['plate_config.friendlyplayer.actorname_use_class_color'] = true, -- nombres de aliados en color de clase
		['plate_config.enemyplayer.actorname_use_class_color'] = true, -- y de enemigos
		['plate_config.friendlyplayer.show_guild_name'] = true, -- hermandad bajo el nombre (aliados)
		['plate_config.enemyplayer.show_guild_name'] = true, -- y enemigos
	},

	-- Ajustes globales de ElvUI (no van en las exportaciones de perfil)
	globalOverrides = {
		['datatexts.settings.System.NoLabel'] = true,
		['datatexts.settings.Durability.NoLabel'] = true,
	},

	-- Paneles de datos propios del hueco central (ElvUI los guarda en ajustes globales)
	-- Fuente propia incluida en el addon (Media/). Las fuentes de la lista
	-- "replace" se cambian por esta al aplicar el perfil (ElvUI, Plater, Details!).
	font = {
		name = 'Righteous',
		file = [[Interface\AddOns\TomasUI\Media\Righteous-Regular.ttf]],
		replace = { 'Arial Narrow', 'Friz Quadrata TT', 'Skurri' },
		replaceFiles = { [[Fonts\ARIALN.TTF]], [[Fonts\FRIZQT__.TTF]], [[Fonts\skurri.ttf]] },
		-- solo en ElvUI: sus fuentes propias, también cuando están en su valor por defecto
		replaceElvUI = { 'PT Sans Narrow', 'Expressway' },
	},

	customPanels = {
		TomasUI_FPS = { width = 54, height = 36, numPoints = 1, growth = 'HORIZONTAL', backdrop = false, panelTransparency = true, border = false, fonts = { enable = true, font = 'Righteous', fontSize = 12, fontOutline = 'SHADOW' } },
		TomasUI_Dur = { width = 54, height = 36, numPoints = 1, growth = 'HORIZONTAL', backdrop = false, panelTransparency = true, border = false, fonts = { enable = true, font = 'Righteous', fontSize = 12, fontOutline = 'SHADOW' } },
	},

	-- Swing timer de Blizzard en el hueco de la barra de lanzamiento del jugador
	swingTimer = { point = 'BOTTOM', x = -426, y = 240, width = 210, height = 21 },

	-- Oculta los puntos de combo de ElvUI (se ven en Plater) pero mantiene el maná en formas
	hideClassBar = true,

	-- Línea en el borde de la vida: color de clase/reacción aclarado, solo si falta vida
	healthSpark = { classColor = true, lighten = 0.4, color = { 0.25, 0.25, 0.25, 1 }, blend = 'BLEND', width = 2 },

	-- Marco de misiones (modo edición): debajo de la microbarra, altura máx. 590
	-- (el modo edición guarda la altura como (altura - 400) / 10 -> 19)
	editMode = {
		objectiveTracker = { point = 'TOPRIGHT', relativePoint = 'TOPRIGHT', x = -3, y = -300, heightValue = 19 },
	},

	-- Plater, jugadores aliados: "solo nombre" (sin barra ni auras), salvo con una
	-- especialización de sanador (el árbol con más puntos), que muestra sus barras de vida
	-- (árboles de sanador por clase, en el orden de la ventana de talentos)
	friendlyPlates = {
		nameOnly = true, barsForHealers = true,
		healerTrees = { PRIEST = { 1, 2 }, PALADIN = { 1 }, DRUID = { 3 }, SHAMAN = { 3 } },
	},

	-- Plater, "solo nombre" de jugadores aliados: nivel del jugador.
	-- position: 'left' = texto aparte a la izquierda ("27 ·"), con nombre y hermandad
	-- centrados como sin nivel; 'inline' = en el mismo texto del nombre ("27 · Nombre");
	-- 'above' = centrado encima. gap = separación y smaller = puntos menos que el
	-- nombre (solo 'left' y 'above'); separator = '' para quitar el "·".
	-- color = { r, g, b } fijo (dorado de "mismo nivel"); con difficultyColor = true,
	-- en color de dificultad
	nameOnlyLevel = {
		enabled = true, position = 'left', separator = '>', separatorColor = { 1, 1, 1 },
		gap = 2, smaller = 0, color = { 1, 0.82, 0 }, difficultyColor = false,
	},

	-- Plater, "solo nombre": halo detrás del nombre de los aliados por debajo de
	-- threshold de vida (0.25 = 25 %). color = { r, g, b, opacidad }
	lowHealthGlow = {
		threshold = 0.25,
		color = { 1, 0.15, 0.1, 0.8 },
		-- texture = ruta de otra textura; sin ella, la "Spark" de ElvUI
		blend = 'ADD',
		padX = 14, padY = 6, -- cuánto sobresale del nombre
	},

	-- Details!: una sola ventana abajo a la derecha (10 filas de 13 + 2)
	details = { point = 'BOTTOMRIGHT', x = -3, y = 3, width = 261, height = 150 },
}
