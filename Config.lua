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
	},

	-- Se fuerzan encima de los ajustes privados de ElvUI (por personaje) al aplicar
	privateOverrides = {
		['general.minimap.hideTracking'] = true,
		['general.minimap.hideCalendar'] = false,
		['general.totemTracker'] = false,
	},

	-- Ajustes globales de ElvUI (no van en las exportaciones de perfil)
	globalOverrides = {
		['datatexts.settings.System.NoLabel'] = true,
		['datatexts.settings.Durability.NoLabel'] = true,
	},

	-- Paneles de datos propios del hueco central (ElvUI los guarda en ajustes globales)
	customPanels = {
		TomasUI_FPS = { width = 54, height = 36, numPoints = 1, growth = 'HORIZONTAL', backdrop = false, panelTransparency = true, border = false, fonts = { enable = true, font = 'Arial Narrow', fontSize = 12, fontOutline = 'SHADOW' } },
		TomasUI_Dur = { width = 54, height = 36, numPoints = 1, growth = 'HORIZONTAL', backdrop = false, panelTransparency = true, border = false, fonts = { enable = true, font = 'Arial Narrow', fontSize = 12, fontOutline = 'SHADOW' } },
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

	-- Details!: una sola ventana abajo a la derecha (10 filas de 13 + 2)
	details = { point = 'BOTTOMRIGHT', x = -3, y = 3, width = 261, height = 150 },
}
