-- TomasUI · Core.lua
-- Aplica el perfil empaquetado (ElvUI Profile + Private, Plater, modo edición) cuando hay
-- una versión nueva, iguala la escala de UI a la del autor y reexpresa las posiciones de
-- los movers para que no dependan del ancho del monitor. Además coloca el swing timer,
-- Details! y el marco de misiones según Config.lua.

local addonName, ns = ...

local EDGE_MARGIN = 400 -- unidades de UI: más cerca del borde que esto = "pegado al borde"
local PREFIX = '|cff33ccffTomasUI|r: '

local function Print(...) print(PREFIX, ...) end
ns.Print = Print

local function Clamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end

-- Escribe value en t siguiendo una ruta "a.b.c"
local function SetPath(t, path, value)
	local keys = { strsplit('.', path) }
	for i = 1, #keys - 1 do
		if type(t[keys[i]]) ~= 'table' then t[keys[i]] = {} end
		t = t[keys[i]]
	end
	t[keys[#keys]] = value
end

-- Lee el valor de t en la ruta "a.b.c" (nil si falta algún tramo)
local function GetPath(t, path)
	for key in string.gmatch(path, '[^.]+') do
		if type(t) ~= 'table' then return nil end
		t = t[key]
	end
	return t
end

-- Al entrar: si el perfil activo es el nuestro y le falta algún ajuste forzado
-- (p. ej. añadido en una versión nueva), lo escribimos sin reimportar todo el perfil.
-- Los de marcos de unidad se ven al momento; el resto tras el siguiente /reload.
function ns.ApplyLiveOverrides()
	-- ns.ActiveConfig: la función local ActiveConfig se define más abajo
	local cfg = ns.ActiveConfig and ns.ActiveConfig()
	local E = ElvUI and ElvUI[1]
	if not (cfg and E and E.db) then return end
	local unitframes = false
	for path, value in pairs(cfg.profileOverrides or {}) do
		local current = GetPath(E.db, path)
		-- un "false" sobre algo que no existe no tiene nada que desactivar
		if current ~= value and not (value == false and current == nil) then
			SetPath(E.db, path, value)
			if path:find('^unitframe%.') then unitframes = true end
		end
	end
	if unitframes and not InCombatLockdown() then
		local UF = E:GetModule('UnitFrames', true)
		if UF and UF.Update_AllFrames then pcall(UF.Update_AllFrames, UF) end
	end
end

-- Config activa solo si el personaje usa el perfil de TomasUI en ElvUI
local function ActiveConfig()
	local E = ElvUI and ElvUI[1]
	if not (E and E.data) then return end
	if E.data:GetCurrentProfile() == ns.Config.profileName then return ns.Config end
end
ns.ActiveConfig = ActiveConfig

local function UsesRangedSwing()
	local _, class = UnitClass('player')
	return ns.Config.rangedSwingClasses[class] or false
end

-------------------------------------------------------------------------------
-- Escala
-------------------------------------------------------------------------------
-- En WoW la altura de la pantalla en unidades de UI es 768 / escala, sea cual sea la
-- resolución, así que basta con usar la misma escala que el autor.
function ns.TargetScale()
	return Clamp(768 / ns.Data.ref.uiH, 0.4, 1.15)
end

-------------------------------------------------------------------------------
-- Movers: reexpresar cada posición en coordenadas de la pantalla del autor
-------------------------------------------------------------------------------
-- Los movers centrales se anclan al centro horizontal; los pegados a un borde siguen
-- anclados a su borde. En vertical: mitad superior → arriba, mitad inferior → abajo.
-- Los anclados a otro marco no se tocan (ya son relativos).
local H_FRAC = { LEFT = 0, RIGHT = 1 }
local V_FRAC = { BOTTOM = 0, TOP = 1 }

local function PointFractions(point)
	local h, v = 0.5, 0.5
	for k, f in pairs(V_FRAC) do if point:find(k) then v = f end end
	for k, f in pairs(H_FRAC) do if point:find(k) then h = f end end
	return h, v
end

local function ParentSize(parentName)
	local ref = ns.Data.ref
	if parentName == 'ElvUIParent' then return ref.elvW, ref.elvH end
	if parentName == 'UIParent' then return ref.uiW, ref.uiH end
end

function ns.NormalizeMoverString(str)
	if type(str) ~= 'string' then return str end
	local delim = str:find('\031') and '\031' or ','
	local point, parent, relPoint, x, y = strsplit(delim, str)
	x, y = tonumber(x), tonumber(y)
	if not (point and parent and relPoint and x and y) then return str end

	local W, H = ParentSize(parent)
	if not W then return str end

	local hf, vf = PointFractions(relPoint)
	local absX, absY = W * hf + x, H * vf + y

	local hName, hOff
	if absX > EDGE_MARGIN and absX < W - EDGE_MARGIN then
		hName, hOff = '', absX - W / 2
	elseif absX <= W / 2 then
		hName, hOff = 'LEFT', absX
	else
		hName, hOff = 'RIGHT', absX - W
	end

	local vName, vOff
	if absY > H / 2 then
		vName, vOff = 'TOP', absY - H
	else
		vName, vOff = 'BOTTOM', absY
	end

	return format('%s,%s,%s,%d,%d', point, parent, vName .. hName,
		math.floor(hOff + 0.5), math.floor(vOff + 0.5))
end

local function NormalizeMovers(movers)
	if type(movers) ~= 'table' then return end
	for name, str in pairs(movers) do
		movers[name] = ns.NormalizeMoverString(str)
	end
end

-------------------------------------------------------------------------------
-- Aplicar
-------------------------------------------------------------------------------
local function ApplyElvUI()
	local E, _, V, P, G = unpack(ElvUI)
	local D = E:GetModule('Distributor')
	local data, cfg = ns.Data, ns.Config

	-- Los datos pueden venir como tabla o como cadena !E2! (/tui export)
	local function Read(value, expectedType)
		if type(value) == 'table' then return E:CopyTable({}, value) end
		if type(value) == 'string' and value ~= '' then
			local t, _, d = D:Decode(value)
			if t == expectedType then return d end
		end
	end

	-- Perfil
	local pData = Read(data.elvProfile, 'profile')
	if type(pData) ~= 'table' then
		Print('No he podido leer el perfil de ElvUI.')
		return false
	end
	NormalizeMovers(pData.movers)
	if ns.RemapFonts then
		local extra = cfg.font and cfg.font.replaceElvUI
		ns.RemapFonts(pData, extra)
		ns.FillFontDefaults(pData, P, extra)
	end
	for path, value in pairs(cfg.profileOverrides or {}) do SetPath(pData, path, value) end
	D:SetImportedProfile('profile', cfg.profileName, pData, true)
	-- ElvUI no importa algunos ajustes (D.blacklistedKeys, p. ej. chat.hideVoiceButtons):
	-- los escribimos directamente en el perfil guardado
	local saved = ElvDB and ElvDB.profiles and ElvDB.profiles[cfg.profileName]
	if type(saved) == 'table' then
		for path, value in pairs(cfg.profileOverrides or {}) do SetPath(saved, path, value) end
	end

	-- Ajustes privados (por personaje)
	local vData = Read(data.elvPrivate, 'private')
	local key = ElvPrivateDB.profileKeys and ElvPrivateDB.profileKeys[E.mynameRealm]
	if type(vData) == 'table' and key then
		if ns.RemapFonts then
			local extra = cfg.font and cfg.font.replaceElvUI
			ns.RemapFonts(vData, extra)
			ns.FillFontDefaults(vData, V, extra)
		end
		for path, value in pairs(cfg.privateOverrides or {}) do SetPath(vData, path, value) end
		ElvPrivateDB.profiles[key] = E:FilterTableFromBlacklist(vData, D.blacklistedKeys.private)
	end

	-- Ajustes globales que ElvUI no incluye en sus exportaciones
	if not TomasUIDB.keepOwnScale then
		E.global.general.UIScale = ns.TargetScale()
	end
	E.global.general.ultrawide = data.ref.ultrawide or false
	E.global.general.eyefinity = data.ref.eyefinity or false
	for name, panelCfg in pairs(cfg.customPanels or {}) do
		local panel = E:CopyTable({}, G.datatexts.newPanelInfo)
		for k, v in pairs(panelCfg) do panel[k] = v end
		E.global.datatexts.customPanels[name] = panel
	end
	for path, value in pairs(cfg.globalOverrides or {}) do SetPath(E.global, path, value) end

	return true
end

local function ApplyPlater()
	local platerData = ns.Data.plater
	if not platerData or platerData == '' then return true end
	if type(platerData) == 'table' then platerData = CopyTable(platerData) end
	if not C_AddOns.IsAddOnLoaded('Plater') then
		Print('Plater no está activado; me salto su perfil.')
		return true
	end
	-- Cambiar las fuentes por la nuestra antes de importar
	if type(platerData) == 'string' and ns.RemapFonts and Plater.DecompressData and Plater.CompressData then
		local ok, t = pcall(Plater.DecompressData, platerData, 'print', true)
		if ok and type(t) == 'table' then
			ns.RemapFonts(t)
			local ok2, s = pcall(Plater.CompressData, t, 'print')
			if ok2 and type(s) == 'string' and s ~= '' then platerData = s end
		end
	end
	if PlaterAPI and PlaterAPI.ImportProfile then
		PlaterAPI:ImportProfile(platerData, ns.Config.profileName)
	else
		Plater.ImportAndSwitchProfile(ns.Config.profileName, platerData, false, false, true, false)
	end
	return true
end

local function ApplyDetailsProfile()
	local str = ns.Data.details
	if not str or str == '' then return end
	local D = _G.Details
	if not (D and D.ImportProfile) then
		Print('Details! no está activado; me salto su perfil.')
		return
	end
	-- Cambiar las fuentes por la nuestra antes de importar
	if ns.RemapFonts and D.DecompressData and D.CompressData then
		local ok, t = pcall(D.DecompressData, D, str, 'print')
		if ok and type(t) == 'table' then
			ns.RemapFonts(t)
			local ok2, s = pcall(D.CompressData, D, t, 'print', true)
			if ok2 and type(s) == 'string' and s ~= '' then str = s end
		end
	end
	-- nombre del perfil, sin autoejecutar código, sin ventana de confirmación, sobrescribiendo
	local ok, err = pcall(D.ImportProfile, D, str, ns.Config.profileName, false, false, true)
	if not ok then Print('|cffff4444No he podido importar el perfil de Details!:|r ' .. tostring(err)) end
end

function ns.Apply()
	if InCombatLockdown() then
		Print('En combate: lo aplico al salir.')
		ns.pendingApply = true
		return
	end
	local okCall, ok = pcall(ApplyElvUI)
	if not okCall then
		Print('|cffff4444Error al aplicar:|r ' .. tostring(ok))
		return
	end
	if not ok then return end
	ApplyPlater()
	ApplyDetailsProfile()
	TomasUICharDB.applied = ns.Data.version
	pcall(ns.EnsureEditModeLayouts)
	ReloadUI()
end

-------------------------------------------------------------------------------
-- Aviso de versión nueva
-------------------------------------------------------------------------------
StaticPopupDialogs['TOMASUI_UPDATE'] = {
	text = 'TomasUI: hay una versión nueva del perfil (%s).\n\nSe sobrescribirán tus perfiles de ElvUI, Plater y Details! llamados "TomasUI" y se recargará la interfaz.',
	button1 = 'Aplicar',
	button2 = 'Ahora no',
	OnAccept = function() ns.Apply() end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1,
	preferredIndex = 3,
}

function ns.VersionLabel(v)
	local s = tostring(v)
	if #s == 12 then
		return format('%s-%s-%s %s:%s', s:sub(1, 4), s:sub(5, 6), s:sub(7, 8), s:sub(9, 10), s:sub(11, 12))
	end
	return s
end

function ns.IsAuthorCharacter()
	local E = unpack(ElvUI)
	for _, key in ipairs(ns.Config.authors or {}) do
		if key == E.mynameRealm then return true end
	end
	return false
end

function ns.CheckForUpdate(force)
	if (TomasUIDB.author or ns.IsAuthorCharacter()) and not force then return end
	if force or (TomasUICharDB.applied or 0) < ns.Data.version then
		StaticPopup_Show('TOMASUI_UPDATE', ns.VersionLabel(ns.Data.version))
	end
end

-------------------------------------------------------------------------------
-- Swing timer de Blizzard
-------------------------------------------------------------------------------
local swingHooked, swingPlacing = {}, false

local function PlaceSwingFrame(frame)
	if swingPlacing then return end
	local cfg = ActiveConfig()
	cfg = cfg and cfg.swingTimer
	if not cfg then return end
	swingPlacing = true
	frame:SetScale(1)
	frame:ClearAllPoints()
	frame:SetPoint(cfg.point, ElvUI[1].UIParent, cfg.point, cfg.x, cfg.y)
	frame:SetSize(cfg.width, cfg.height)
	if frame.StatusBar then
		frame.StatusBar:ClearAllPoints()
		frame.StatusBar:SetAllPoints(frame)
	end
	frame:SetFrameStrata('LOW') -- la barra de lanzamiento (MEDIUM) queda por encima
	swingPlacing = false
end

function ns.PlaceSwingTimer()
	local cfg = ActiveConfig()
	if not (cfg and cfg.swingTimer) then return end
	-- Solo se coloca el swing que importa para la clase; el otro lo deja el modo edición
	local frame = _G[UsesRangedSwing() and 'SwingTimerRangedFrame' or 'SwingTimerMainHandFrame']
	if not frame then return end
	if not swingHooked[frame] then
		swingHooked[frame] = true
		local function Reapply() PlaceSwingFrame(frame) end
		hooksecurefunc(frame, 'SetPoint', Reapply)
		hooksecurefunc(frame, 'SetScale', Reapply)
		hooksecurefunc(frame, 'SetSize', Reapply)
	end
	PlaceSwingFrame(frame)
end

-------------------------------------------------------------------------------
-- Ocultar la barra de clase (puntos de combo) sin perder el poder adicional
-------------------------------------------------------------------------------
-- ElvUI solo muestra el poder adicional si la barra de clase está activada,
-- así que se deja activada y se oculta su marco.
local classBarHooked = false
function ns.HideClassBar()
	local cfg = ActiveConfig()
	if not (cfg and cfg.hideClassBar) then return end
	local bars = _G.ElvUF_Player_ClassBar
	if not bars then return end
	if not classBarHooked then
		classBarHooked = true
		local function KeepHidden(self)
			local c = ActiveConfig()
			if c and c.hideClassBar and self:IsShown() then self:Hide() end
		end
		hooksecurefunc(bars, 'Show', KeepHidden)
		hooksecurefunc(bars, 'SetShown', KeepHidden)
	end
	bars:Hide()
end

-------------------------------------------------------------------------------
-- Línea vertical en el borde de la vida
-------------------------------------------------------------------------------
-- Se ancla al borde de la textura de la barra. Para ocultarla con la vida al 100 %
-- (valor oculto para los addons) se usa una curva escalonada que evalúa el propio juego
-- y cuyo resultado va directo a la opacidad de la textura (mismo truco que ElvUI).
local fullHealthCurve
local function GetFullHealthCurve()
	if not fullHealthCurve and C_CurveUtil and C_CurveUtil.CreateCurve and Enum.LuaCurveType then
		fullHealthCurve = C_CurveUtil.CreateCurve()
		fullHealthCurve:SetType(Enum.LuaCurveType.Step)
		fullHealthCurve:AddPoint(0, 1)
		fullHealthCurve:AddPoint(1, 0)
	end
	return fullHealthCurve
end

-- Color de clase (o reacción en PNJ) aclarado; si no se puede leer, el color fijo
local function GetSparkColor(health, unit)
	local cfg = health.TomasUISparkCfg or {}
	local base = cfg.color or { 0.25, 0.25, 0.25, 1 }
	if not (cfg.classColor and unit) then return base end

	local E = ElvUI[1]
	local color
	local ok = pcall(function()
		if UnitIsPlayer(unit) then
			local _, class = UnitClass(unit)
			if class and not E:IsSecretValue(class) then
				color = (E.oUF and E.oUF.colors.class[class]) or RAID_CLASS_COLORS[class]
			end
		else
			local reaction = UnitReaction(unit, 'player')
			if reaction and not E:IsSecretValue(reaction) then
				color = E.oUF and E.oUF.colors.reaction[reaction]
			end
		end
	end)
	if not (ok and color) then return base end

	local r, g, b = color.r or color[1], color.g or color[2], color.b or color[3]
	local k = cfg.lighten or 0.4
	return { r + (1 - r) * k, g + (1 - g) * k, b + (1 - b) * k, 1 }
end

local function UpdateSparkVisibility(health, unit)
	local spark = health.TomasUISpark
	if not (spark and health.TomasUISparkEnabled) then return end
	unit = unit or (health.__owner and health.__owner.unit)
	local c = GetSparkColor(health, unit)
	local curve = GetFullHealthCurve()
	if unit and curve and UnitHealthPercent then
		local ok, alpha = pcall(UnitHealthPercent, unit, false, curve)
		if ok and alpha ~= nil then
			spark:SetVertexColor(c[1], c[2], c[3], alpha)
			return
		end
	end
	spark:SetVertexColor(c[1], c[2], c[3], c[4] or 1)
end

local function UpdateHealthSpark(frame)
	local health = frame and frame.Health
	if not health or not health.GetStatusBarTexture then return end
	local active = ActiveConfig()
	local cfg = active and active.healthSpark

	health.TomasUISparkEnabled = cfg and true or false
	if not cfg then
		if health.TomasUISpark then health.TomasUISpark:Hide() end
		return
	end
	if health.GetOrientation and health:GetOrientation() == 'VERTICAL' then return end

	local E = ElvUI[1]
	local spark = health.TomasUISpark
	if not spark then
		spark = health:CreateTexture(nil, 'OVERLAY', nil, 5)
		spark:SetTexture(E.media.blankTex)
		health.TomasUISpark = spark
	end
	health.TomasUISparkCfg = cfg
	spark:SetBlendMode(cfg.blend or 'BLEND')
	local reverse = health.GetReverseFill and health:GetReverseFill()
	spark:ClearAllPoints()
	spark:SetPoint(reverse and 'LEFT' or 'RIGHT', health:GetStatusBarTexture(), reverse and 'LEFT' or 'RIGHT')
	spark:SetPoint('TOP', health, 'TOP')
	spark:SetPoint('BOTTOM', health, 'BOTTOM')
	spark:SetWidth(E:Scale(cfg.width or 2))

	if not health.TomasUISparkHooked and type(health.PostUpdate) == 'function' then
		health.TomasUISparkHooked = true
		hooksecurefunc(health, 'PostUpdate', function(self, unit) UpdateSparkVisibility(self, unit) end)
	end
	spark:Show()
	UpdateSparkVisibility(health, frame.unit)
end

function ns.SetupHealthSpark()
	local E = ElvUI and ElvUI[1]
	if not E then return end
	if not ns.healthSparkHooked then
		ns.healthSparkHooked = true
		hooksecurefunc(E:GetModule('UnitFrames'), 'Configure_HealthBar', function(_, frame) UpdateHealthSpark(frame) end)
	end
	for _, frame in ipairs(E.oUF and E.oUF.objects or {}) do
		UpdateHealthSpark(frame)
	end
end

-------------------------------------------------------------------------------
-- Modo edición de Blizzard
-------------------------------------------------------------------------------
-- Activa la distribución que corresponde a la clase
function ns.ApplyEditModeLayout(verbose)
	if TomasUIDB.noEditModeSwitch then return end
	if InCombatLockdown() or not (C_EditMode and C_EditMode.GetLayouts and C_EditMode.SetActiveLayout) then return end

	local names = ns.Config.editModeLayouts
	local wanted = UsesRangedSwing() and names.ranged or names.melee
	local info = C_EditMode.GetLayouts()
	if not (info and info.layouts) then return end

	-- El índice activo cuenta primero las distribuciones predefinidas de Blizzard
	local numPresets = 2
	if EditModePresetLayoutManager and EditModePresetLayoutManager.GetCopyOfPresetLayouts then
		numPresets = #EditModePresetLayoutManager:GetCopyOfPresetLayouts()
	end

	for i, layout in ipairs(info.layouts) do
		if layout.layoutName == wanted then
			local index = numPresets + i
			if info.activeLayout ~= index then
				C_EditMode.SetActiveLayout(index)
				Print('Modo edición: distribución "' .. wanted .. '" activada para esta clase.')
			elseif verbose then
				Print('Modo edición: ya estás usando "' .. wanted .. '".')
			end
			return
		end
	end
	if verbose then Print('No encuentro una distribución del modo edición llamada "' .. wanted .. '".') end
end

-- Copia de las distribuciones TomasUI del autor (para /tui export)
function ns.SnapshotEditModeLayouts()
	if not (C_EditMode and C_EditMode.GetLayouts and C_EditMode.ConvertLayoutInfoToString) then return end
	local info = C_EditMode.GetLayouts()
	if not (info and info.layouts) then return end
	local snapshot = {}
	for _, layout in ipairs(info.layouts) do
		for _, name in pairs(ns.Config.editModeLayouts) do
			if layout.layoutName == name then
				local ok, str = pcall(C_EditMode.ConvertLayoutInfoToString, layout)
				if ok and str then snapshot[name] = str end
			end
		end
	end
	if next(snapshot) then TomasUIDB.editModeSnapshot = snapshot end
end

-- Crea las distribuciones del pack que falten
function ns.EnsureEditModeLayouts()
	local packed = ns.Data.editModeLayouts
	if not packed or not next(packed) then return end
	if InCombatLockdown() or not (C_EditMode and C_EditMode.GetLayouts and C_EditMode.SaveLayouts and C_EditMode.ConvertStringToLayoutInfo) then return end

	local info = C_EditMode.GetLayouts()
	if not (info and info.layouts) then return end
	local existing = {}
	for _, layout in ipairs(info.layouts) do existing[layout.layoutName] = true end

	local added = {}
	for name, str in pairs(packed) do
		if not existing[name] then
			local ok, layout = pcall(C_EditMode.ConvertStringToLayoutInfo, str)
			if ok and layout then
				layout.layoutName = name
				layout.layoutType = Enum.EditModeLayoutType and Enum.EditModeLayoutType.Account or layout.layoutType
				tinsert(info.layouts, layout)
				tinsert(added, name)
			end
		end
	end

	if #added > 0 then
		local ok, err = pcall(C_EditMode.SaveLayouts, info)
		if ok then
			Print('Modo edición: creadas las distribuciones ' .. table.concat(added, ', ') .. '. Usa /reload para activarlas.')
			return true
		end
		Print('|cffff4444No he podido crear las distribuciones del modo edición:|r ' .. tostring(err))
	end
end

-- Ajusta el marco de misiones en las distribuciones TomasUI (vía API del modo edición,
-- sin mover marcos de Blizzard desde el addon)
function ns.ApplyEditModeTweaks()
	local cfg = ActiveConfig()
	local ot = cfg and cfg.editMode and cfg.editMode.objectiveTracker
	if not ot or InCombatLockdown() then return end
	if not (C_EditMode and C_EditMode.GetLayouts and C_EditMode.SaveLayouts) then return end

	local info = C_EditMode.GetLayouts()
	if not (info and info.layouts) then return end

	local ours = {}
	for _, name in pairs(cfg.editModeLayouts) do ours[name] = true end

	local SYSTEM = Enum.EditModeSystem and Enum.EditModeSystem.ObjectiveTracker or 12
	local HEIGHT = Enum.EditModeObjectiveTrackerSetting and Enum.EditModeObjectiveTrackerSetting.Height or 0
	local changed = false

	for _, layout in ipairs(info.layouts) do
		if ours[layout.layoutName] then
			for _, sys in ipairs(layout.systems or {}) do
				if sys.system == SYSTEM then
					local a = sys.anchorInfo
					if a and (a.point ~= ot.point or a.relativeTo ~= 'UIParent' or a.relativePoint ~= ot.relativePoint
						or a.offsetX ~= ot.x or a.offsetY ~= ot.y or sys.isInDefaultPosition) then
						a.point, a.relativeTo, a.relativePoint, a.offsetX, a.offsetY = ot.point, 'UIParent', ot.relativePoint, ot.x, ot.y
						sys.isInDefaultPosition = false
						changed = true
					end
					for _, setting in ipairs(sys.settings or {}) do
						if setting.setting == HEIGHT and ot.heightValue and setting.value ~= ot.heightValue then
							setting.value = ot.heightValue
							changed = true
						end
					end
				end
			end
		end
	end

	if changed then
		local ok, err = pcall(C_EditMode.SaveLayouts, info)
		if ok then
			Print('Modo edición: marco de misiones recolocado. Usa /reload para verlo.')
		else
			Print('|cffff4444No he podido ajustar el marco de misiones:|r ' .. tostring(err))
		end
	end
end

-------------------------------------------------------------------------------
-- Details!: una sola ventana
-------------------------------------------------------------------------------
function ns.ApplyDetails()
	local active = ActiveConfig()
	local cfg = active and active.details
	local D = _G.Details
	if not (cfg and D and D.GetInstance and D.GetNumInstances) or InCombatLockdown() then return end

	local main = D:GetInstance(1)
	if not (main and main.baseframe) then return end

	for id = 2, D:GetNumInstances() do
		local window = D:GetInstance(id)
		if window and window:IsEnabled() then window:ShutDown() end
	end

	if not main:IsEnabled() then main:EnableInstance() end
	pcall(main.UngroupInstance, main)

	main.baseframe:ClearAllPoints()
	main.baseframe:SetPoint(cfg.point, UIParent, cfg.point, cfg.x, cfg.y)
	main:SetSize(cfg.width, cfg.height) -- también guarda la posición en el perfil de Details
end

-------------------------------------------------------------------------------
-- Eventos
-------------------------------------------------------------------------------
local f = CreateFrame('Frame')
f:RegisterEvent('ADDON_LOADED')
f:RegisterEvent('PLAYER_ENTERING_WORLD')
f:RegisterEvent('PLAYER_REGEN_ENABLED')
f:RegisterEvent('EDIT_MODE_LAYOUTS_UPDATED')
f:SetScript('OnEvent', function(_, event, arg1, arg2)
	if event == 'ADDON_LOADED' and arg1 == addonName then
		TomasUIDB = TomasUIDB or {}
		TomasUICharDB = TomasUICharDB or {}
	elseif event == 'ADDON_LOADED' and arg1 == 'Blizzard_SwingTimer' then
		C_Timer.After(0, ns.PlaceSwingTimer)
	elseif event == 'EDIT_MODE_LAYOUTS_UPDATED' then
		C_Timer.After(0, ns.PlaceSwingTimer)
	elseif event == 'PLAYER_ENTERING_WORLD' then
		local isInitialLogin, isReload = arg1, arg2
		C_Timer.After(1, function()
			if ns.IsAuthorCharacter() then ns.SnapshotEditModeLayouts() end
			local ok, created = pcall(ns.EnsureEditModeLayouts)
			if not (ok and created) then
				ns.ApplyEditModeLayout()
				pcall(ns.ApplyEditModeTweaks)
			end
			pcall(ns.ApplyLiveOverrides)
			ns.PlaceSwingTimer()
			ns.HideClassBar()
			ns.SetupHealthSpark()
		end)
		C_Timer.After(4, function() pcall(ns.ApplyDetails) end)
		if isInitialLogin or isReload then
			C_Timer.After(3, function() ns.CheckForUpdate() end)
		end
	elseif event == 'PLAYER_REGEN_ENABLED' and ns.pendingApply then
		ns.pendingApply = nil
		ns.Apply()
	end
end)

-------------------------------------------------------------------------------
-- Comandos
-------------------------------------------------------------------------------
SLASH_TOMASUI1 = '/tui'
SLASH_TOMASUI2 = '/tomasui'
SlashCmdList.TOMASUI = function(msg)
	local cmd, arg = strsplit(' ', (msg or ''):lower(), 2)
	if cmd == 'export' then
		ns.ShowExport()
	elseif cmd == 'aplicar' or cmd == 'apply' then
		ns.CheckForUpdate(true)
	elseif cmd == 'edicion' then
		if arg == 'off' then
			TomasUIDB.noEditModeSwitch = true
			Print('Ya no cambiaré la distribución del modo edición automáticamente.')
		else
			TomasUIDB.noEditModeSwitch = nil
			ns.ApplyEditModeLayout(true)
		end
	elseif cmd == 'rol' then
		Print(ns.FriendlyPlatesStatus())
		ns.UpdateFriendlyPlates()
	elseif cmd == 'autor' then
		TomasUIDB.author = not TomasUIDB.author
		Print('Modo autor ' .. (TomasUIDB.author and 'ACTIVADO (no se te pedirá aplicar el perfil).' or 'desactivado.'))
	elseif cmd == 'escala' then
		if arg == 'propia' then
			TomasUIDB.keepOwnScale = true
			Print('Mantendré tu escala de ElvUI al aplicar el perfil.')
		elseif arg == 'auto' then
			TomasUIDB.keepOwnScale = nil
			Print(format('Usaré la escala equivalente a la del autor (%.4f en este monitor).', ns.TargetScale()))
		else
			Print(format('Escala actual %.4f · equivalente a la del autor %.4f · modo: %s. Usa "/tui escala auto" o "/tui escala propia".',
				ElvUI[1].global.general.UIScale, ns.TargetScale(), TomasUIDB.keepOwnScale and 'propia' or 'auto'))
		end
	else
		local version = C_AddOns.GetAddOnMetadata(addonName, 'Version') or '?'
		Print('v' .. version .. ' · Comandos:')
		print('  /tui aplicar — aplica el perfil empaquetado ahora')
		print('  /tui edicion [off] — elegir la distribución del modo edición según la clase (o desactivarlo)')
		print('  /tui rol — especialización detectada y modo de las placas aliadas')
		print('  /tui escala [auto|propia] — igualar la escala del autor o mantener la tuya')
		print('  /tui export — (autor) exporta tus perfiles actuales para publicar una versión nueva')
		print('  /tui autor — (autor) no pedir aplicar el perfil en este PC')
		print(format('  Perfil empaquetado: %s · aplicado en este personaje: %s',
			ns.VersionLabel(ns.Data.version), TomasUICharDB.applied and ns.VersionLabel(TomasUICharDB.applied) or 'ninguno'))
	end
end

-- Plater: con "mostrar nombre de hermandad", Plater añade "<hermandad>" como segunda
-- línea del nombre (mismo color y tamaño) y deja las auras ancladas a la barra, así
-- que quedan tapadas. Lo sustituimos por un texto propio para la hermandad (tamaño 12,
-- dorado de los títulos de PNJ amistosos) entre el nombre y la barra, y anclamos las
-- auras justo encima del nombre. En "solo nombre" no se muestran auras.
do
	local GUILD_SIZE = nil -- nil: mismo tamaño que el nombre; un número fija el tamaño
	local GUILD_RAISE = 2 -- píxeles extra entre la barra y la hermandad (y el nombre encima)
	local AURA_GAP = GUILD_RAISE -- separación entre el nombre y las auras: la misma que nombre-barra

	local function WantsGuild(plateFrame)
		local cfg = plateFrame and plateFrame.PlateConfig
		return cfg and cfg.show_guild_name and plateFrame.playerGuildName
			and not plateFrame.IsFriendlyPlayerWithoutHealthBar and true or false
	end

	-- Sin barra de vida ("solo nombre"), sin auras. Plater las oculta al pasar a ese
	-- modo, pero a veces se quedan visibles; las ocultamos siempre que falte la barra.
	local function HideAurasWithoutBar(uf)
		if uf.healthBar and not uf.healthBar:IsShown() then
			if uf.BuffFrame and uf.BuffFrame:IsShown() then uf.BuffFrame:Hide() end
			if uf.BuffFrame2 and uf.BuffFrame2:IsShown() then uf.BuffFrame2:Hide() end
		end
	end

	local function GuildColor()
		local Plater = _G.Plater
		local pc = Plater and Plater.db and Plater.db.profile.plate_config
		local c = pc and pc.friendlynpc and pc.friendlynpc.big_actortitle_text_color
		if type(c) == 'table' then return c[1] or 1, c[2] or 0.8, c[3] or 0, c[4] or 1 end
		return 1, 0.8, 0, 1
	end

	-- Righteous no tiene letras cirílicas: si Plater translitera los nombres
	-- (opción "Translit"), hacemos lo mismo con títulos de PNJ y hermandades.
	local function Translit(s)
		if type(s) ~= 'string' or s == '' then return s end
		if issecretvalue and issecretvalue(s) then return s end
		local Plater = _G.Plater
		local profile = Plater and Plater.db and Plater.db.profile
		if not (profile and profile.use_name_translit) then return s end
		local LT = LibStub and LibStub('LibTranslit-1.0', true)
		if not LT then return s end
		return LT:Transliterate(s, '*')
	end

	local function GuildString(uf)
		if not uf.TUIGuild then
			uf.TUIGuild = uf.healthBar:CreateFontString(nil, 'OVERLAY')
		end
		return uf.TUIGuild
	end

	-- Plater coloca el nombre y las auras desde varios sitios y en distinto orden;
	-- en vez de corregir después de cada función, nos enganchamos al SetPoint del
	-- nombre y del marco de auras de cada placa y lo corregimos al instante.
	local busy = false

	local function PlaceAuras(uf, plateFrame)
		local Plater = _G.Plater
		local name = plateFrame.CurrentUnitNameString
		local profile = Plater and Plater.db and Plater.db.profile
		if not (profile and name) then return end
		local a1, a2 = profile.aura_frame1_anchor, profile.aura_frame2_anchor
		busy = true
		if uf.BuffFrame then
			uf.BuffFrame:ClearAllPoints()
			uf.BuffFrame:SetPoint('BOTTOM', name, 'TOP', (a1 and a1.x) or 0, AURA_GAP)
		end
		if uf.BuffFrame2 then
			uf.BuffFrame2:ClearAllPoints()
			uf.BuffFrame2:SetPoint('BOTTOM', name, 'TOP', (a2 and a2.x) or 0, AURA_GAP + ((a2 and a1) and (a2.y - a1.y) or 0))
		end
		busy = false
	end

	-- La hermandad ocupa el sitio que Plater da al nombre; el nombre sube encima
	local function PlaceName(uf, plateFrame, p, rel, rp, x, y)
		local g, name = uf.TUIGuild, plateFrame.CurrentUnitNameString
		if not (g and name and p) or rel == g then return end
		busy = true
		g:ClearAllPoints()
		g:SetPoint(p, rel, rp, x, (y or 0) + GUILD_RAISE)
		name:ClearAllPoints()
		name:SetPoint('BOTTOM', g, 'TOP', 0, 1)
		busy = false
	end

	-- Cualquier placa con barra (jugadores y PNJ, aliados o enemigos) y sin nuestra
	-- hermandad: el nombre, GUILD_RAISE más arriba que donde lo pone Plater
	local function RaisePlainName(plateFrame)
		local uf = plateFrame and plateFrame.unitFrame
		return uf and uf.healthBar and uf.healthBar:IsShown()
			and not plateFrame.IsFriendlyPlayerWithoutHealthBar and not plateFrame.IsNpcWithoutHealthBar
			and not WantsGuild(plateFrame) or false
	end

	local function RaiseName(uf, plateFrame, p, rel, rp, x, y)
		local name = plateFrame.CurrentUnitNameString
		if not (name and p) or rel == uf.TUIGuild then return end
		busy = true
		name:SetPoint(p, rel, rp, x, (y or 0) + GUILD_RAISE)
		busy = false
		uf.TUINameRaised = true
	end

	-- "Solo nombre": halo detrás del nombre de los aliados con poca vida. La vida de
	-- otros jugadores es un valor oculto para los addons; una curva escalonada que
	-- evalúa el propio juego decide la opacidad (como la línea de vida de ElvUI).
	local glowCurve
	local function GlowCurve(cfg)
		if not glowCurve and C_CurveUtil and C_CurveUtil.CreateCurve and Enum.LuaCurveType then
			glowCurve = C_CurveUtil.CreateCurve()
			glowCurve:SetType(Enum.LuaCurveType.Step)
			glowCurve:AddPoint(0, (cfg.color and cfg.color[4]) or 0.8)
			glowCurve:AddPoint(cfg.threshold or 0.5, 0)
		end
		return glowCurve
	end

	local function UpdateGlow(plateFrame)
		local uf = plateFrame and plateFrame.unitFrame
		local cfg = ns.Config.lowHealthGlow
		if not (uf and cfg) then return end
		local glow = uf.TUIGlow
		local unit = uf.namePlateUnitToken or plateFrame.namePlateUnitToken
		local name = plateFrame.CurrentUnitNameString
		local wanted = unit and name and plateFrame.IsFriendlyPlayerWithoutHealthBar
			and plateFrame.actorType == 'friendlyplayer'
		-- En combate el juego oculta también si está muerto: compararlo da error,
		-- así que solo lo usamos cuando es un valor normal
		if wanted then
			local ok, dead = pcall(UnitIsDeadOrGhost, unit)
			if ok and not (issecretvalue and issecretvalue(dead)) and dead == true then wanted = false end
		end
		local curve = wanted and GlowCurve(cfg)
		local ok, alpha
		if curve and UnitHealthPercent then ok, alpha = pcall(UnitHealthPercent, unit, false, curve) end
		if not (ok and type(alpha) ~= 'nil') then -- type() sirve también con valores ocultos
			if glow then glow:Hide() end
			return
		end
		if not glow then
			glow = uf:CreateTexture(nil, 'BACKGROUND')
			-- por defecto, la textura "Spark" de ElvUI (un punto suave que estirado hace de halo)
			local E = ElvUI and ElvUI[1]
			glow:SetTexture(cfg.texture or (E and E.Media and E.Media.Textures and E.Media.Textures.Spark))
			glow:SetBlendMode(cfg.blend or 'ADD')
			uf.TUIGlow = glow
		end
		local px, py = cfg.padX or 14, cfg.padY or 6
		glow:ClearAllPoints()
		glow:SetPoint('TOPLEFT', name, 'TOPLEFT', -px, py)
		glow:SetPoint('BOTTOMRIGHT', name, 'BOTTOMRIGHT', px, -py)
		local c = cfg.color or { 1, 0.15, 0.1, 0.8 }
		glow:SetVertexColor(c[1], c[2], c[3], alpha)
		glow:Show()
	end
	ns.UpdateLowHealthGlow = UpdateGlow

	-- Texto del nivel con color ("27" en dorado) y, si hay, el separador ("·" en blanco)
	local function LevelLabel(level, cfg)
		local r, g, b
		if level <= 0 then
			r, g, b = 1, 0.1, 0.1
		elseif cfg.difficultyColor and GetCreatureDifficultyColor then
			local c = GetCreatureDifficultyColor(level)
			r, g, b = c.r, c.g, c.b
		else
			local c = cfg.color or { 1, 0.82, 0 }
			r, g, b = c[1], c[2], c[3]
		end
		local text = format('|cff%02x%02x%02x%s|r', r * 255, g * 255, b * 255, level > 0 and level or '??')
		local sep = cfg.separator
		if sep == nil then sep = '·' end
		if sep ~= '' then
			local sc = cfg.separatorColor or { 1, 1, 1 }
			text = text .. format(' |cff%02x%02x%02x%s|r', sc[1] * 255, sc[2] * 255, sc[3] * 255, sep)
		end
		return text
	end

	-- Nivel dentro del texto del nombre ("27 · Nombre"), con position = 'inline'
	local function InlineLevel(plateFrame)
		local cfg = ns.Config.nameOnlyLevel
		local uf = plateFrame.unitFrame
		local unit = uf and uf.namePlateUnitToken
		if not (cfg and cfg.enabled and cfg.position == 'inline' and unit and plateFrame.actorType == 'friendlyplayer') then return end
		local ok, level = pcall(UnitLevel, unit)
		if not (ok and type(level) == 'number') or (issecretvalue and issecretvalue(level)) then return end
		return LevelLabel(level, cfg) .. ' '
	end

	-- "Solo nombre" de jugadores aliados: (nivel ·) nombre y debajo la hermandad en dorado
	local function NameOnlyText(plateFrame, withGuild)
		local uf = plateFrame.unitFrame
		local name = plateFrame.namePlateUnitName or (uf and uf.namePlateUnitName)
		if type(name) ~= 'string' or (issecretvalue and issecretvalue(name)) then return end
		-- el nombre sin código de color: conserva el color de clase que le da Plater
		local text = (InlineLevel(plateFrame) or '') .. name
		if withGuild and plateFrame.playerGuildName then
			local r, g, b = GuildColor()
			text = text .. '\n' .. format('|cff%02x%02x%02x', r * 255, g * 255, b * 255)
				.. '<' .. Translit(plateFrame.playerGuildName) .. '>|r'
		end
		return text
	end

	local function UpdateNameOnlyText(plateFrame)
		local nameString = plateFrame and plateFrame.CurrentUnitNameString
		if not (nameString and plateFrame.IsFriendlyPlayerWithoutHealthBar and plateFrame.actorType == 'friendlyplayer') then return end
		local withGuild = plateFrame.PlateConfig and plateFrame.PlateConfig.show_guild_name and plateFrame.playerGuildName and true
		local cfg = ns.Config.nameOnlyLevel
		local inline = cfg and cfg.enabled and cfg.position == 'inline'
		if not (withGuild or inline) then return end
		local text = NameOnlyText(plateFrame, withGuild)
		if text then nameString:SetText(text) end
	end

	-- "Solo nombre" de jugadores aliados: nivel en un texto aparte, más pequeño, a la
	-- encima del nombre (o a su izquierda), en un color fijo o de dificultad
	local function LevelColor(level)
		local c = (GetCreatureDifficultyColor and GetCreatureDifficultyColor(level))
			or (GetQuestDifficultyColor and GetQuestDifficultyColor(level))
		if type(c) == 'table' and c.r then return c.r, c.g, c.b end
		return 1, 0.82, 0
	end

	local function UpdateNameOnlyLevel(plateFrame)
		local uf = plateFrame and plateFrame.unitFrame
		local cfg = ns.Config.nameOnlyLevel
		if not uf then return end
		local lvl = uf.TUILevel
		local name = plateFrame.CurrentUnitNameString
		local unit = uf.namePlateUnitToken
		local wanted = cfg and cfg.enabled and cfg.position ~= 'inline' and name and unit and plateFrame.IsFriendlyPlayerWithoutHealthBar
			and plateFrame.actorType == 'friendlyplayer'
		local level
		if wanted then
			local ok, l = pcall(UnitLevel, unit)
			if ok and type(l) == 'number' and not (issecretvalue and issecretvalue(l)) then level = l end
		end
		local playerName = plateFrame.namePlateUnitName or uf.namePlateUnitName
		if not level or type(playerName) ~= 'string' or (issecretvalue and issecretvalue(playerName)) then
			if lvl then lvl:Hide() end
			return
		end
		local file, size, flags = name:GetFont()
		if not file then if lvl then lvl:Hide() end return end
		if not lvl then
			lvl = uf:CreateFontString(nil, 'OVERLAY')
			uf.TUILevel = lvl
			-- texto invisible para medir el ancho de la primera línea (solo el nombre)
			uf.TUILevelMeasure = uf:CreateFontString(nil, 'OVERLAY')
			uf.TUILevelMeasure:Hide()
		end
		local lsize = math.max(8, (size or 12) - (cfg.smaller or 3))
		lvl:SetFont(file, lsize, flags or '')
		lvl:SetShadowColor(name:GetShadowColor())
		lvl:SetShadowOffset(name:GetShadowOffset())
		lvl:SetTextColor(1, 1, 1)
		lvl:SetText(LevelLabel(level, cfg))
		lvl:ClearAllPoints()
		if cfg.position == 'left' then
			-- el nombre va centrado: su primera línea empieza a media anchura del centro
			local m = uf.TUILevelMeasure
			m:SetFont(file, size or 12, flags or '')
			m:SetText(playerName)
			local ok, w = pcall(m.GetStringWidth, m)
			if not (ok and type(w) == 'number') then w = 0 end
			lvl:SetPoint('RIGHT', name, 'TOP', -(w / 2) - (cfg.gap or 3), -((size or 12) / 2))
		else
			-- centrado encima del nombre
			lvl:SetPoint('BOTTOM', name, 'TOP', 0, cfg.gap or 1)
		end
		lvl:Show()
	end
	ns.UpdateNameOnlyLevel = UpdateNameOnlyLevel

	local function HookPlate(uf, plateFrame)
		uf.TUIPlate = plateFrame
		-- Plater usa un texto de nombre distinto con barra y en "solo nombre", y recicla
		-- las placas: enganchamos cada texto de nombre la primera vez que lo vemos
		local name = plateFrame.CurrentUnitNameString
		if name and not name.TUIHooked then
			name.TUIHooked = true
			hooksecurefunc(name, 'SetPoint', function(self, p, rel, rp, x, y)
				local pf = uf.TUIPlate
				-- solo si es el nombre que la placa está usando ahora
				if busy or not pf or pf.CurrentUnitNameString ~= self then return end
				-- Plater acaba de colocar el nombre: aún no está subido
				uf.TUINameRaised = false
				if WantsGuild(pf) then
					PlaceName(uf, pf, p, rel, rp, x, y)
					PlaceAuras(uf, pf)
				elseif RaisePlainName(pf) then
					RaiseName(uf, pf, p, rel, rp, x, y)
					PlaceAuras(uf, pf)
				end
			end)
		end
		if uf.TUIHooked then return end
		uf.TUIHooked = true
		for _, key in ipairs({ 'BuffFrame', 'BuffFrame2' }) do
			local bf = uf[key]
			if bf then
				hooksecurefunc(bf, 'SetPoint', function()
					local pf = uf.TUIPlate
					if busy or not pf or not (WantsGuild(pf) or RaisePlainName(pf)) then return end
					PlaceAuras(uf, pf)
				end)
				-- Plater muestra las auras antes de ocultar la barra o después de
				-- mostrarla: comprobando la barra en cada Show no fallamos ningún orden
				local function Check() HideAurasWithoutBar(uf) end
				hooksecurefunc(bf, 'Show', Check)
				hooksecurefunc(bf, 'SetShown', Check)
			end
		end
	end

	local function Layout(plateFrame)
		local uf = plateFrame and plateFrame.unitFrame
		if not (_G.Plater and uf and uf.healthBar) then return end
		local name = plateFrame.CurrentUnitNameString
		if not name then return end
		HookPlate(uf, plateFrame)
		HideAurasWithoutBar(uf)
		UpdateNameOnlyText(plateFrame)
		UpdateNameOnlyLevel(plateFrame)
		UpdateGlow(plateFrame)
		if not WantsGuild(plateFrame) then
			if uf.TUIGuild then uf.TUIGuild:Hide() end
			-- solo una vez por cada vez que Plater coloca el nombre, para no ir sumando
			if RaisePlainName(plateFrame) then
				if not uf.TUINameRaised then RaiseName(uf, plateFrame, name:GetPoint(1)) end
				PlaceAuras(uf, plateFrame)
			end
			return
		end
		local g = GuildString(uf)
		local file, size, flags = name:GetFont()
		-- GUILD_SIZE = nil: mismo tamaño que el nombre
		if file then g:SetFont(file, GUILD_SIZE or size, flags or '') end
		g:SetShadowColor(name:GetShadowColor())
		g:SetShadowOffset(name:GetShadowOffset())
		g:SetTextColor(GuildColor())
		g:SetText('<' .. Translit(plateFrame.playerGuildName) .. '>')
		g:Show()
		PlaceName(uf, plateFrame, name:GetPoint(1))
		PlaceAuras(uf, plateFrame)
	end

	local hooked = false
	local function HookPlater()
		local Plater = _G.Plater
		if hooked or not (Plater and Plater.UpdateUnitName and Plater.UpdatePlateSize and Plater.AddGuildNameToPlayerName) then return end
		hooked = true
		-- Escudito de "no interrumpible": Plater lo centra en el borde de la barra de
		-- lanzamiento del lado del icono y lo tapa; lo pasamos al borde contrario
		if Plater.UpdateCastbarIcon then
			hooksecurefunc(Plater, 'UpdateCastbarIcon', function(castBar)
				local profile = Plater.db and Plater.db.profile
				local shield = castBar and castBar.BorderShield
				if not (profile and shield and profile.castbar_icon_customization_enabled and profile.castbar_icon_show) then return end
				local side = profile.castbar_icon_attach_to_side == 'right' and 'left' or 'right'
				shield:ClearAllPoints()
				shield:SetPoint('center', castBar, side, 0, 0)
			end)
		end
		-- sin segunda línea en el nombre cuando ponemos nuestro texto de hermandad
		local original = Plater.AddGuildNameToPlayerName
		Plater.AddGuildNameToPlayerName = function(plateFrame, ...)
			if WantsGuild(plateFrame) then return end
			-- "solo nombre": Plater pone la hermandad como segunda línea del nombre;
			-- la dejamos ahí pero en dorado (mismo tamaño que el nombre)
			if plateFrame and plateFrame.IsFriendlyPlayerWithoutHealthBar and plateFrame.playerGuildName
				and plateFrame.CurrentUnitNameString then
				local text = NameOnlyText(plateFrame, true)
				if text then
					plateFrame.CurrentUnitNameString:SetText(text)
					return
				end
			end
			return original(plateFrame, ...)
		end
		-- títulos de PNJ (p. ej. "<Esbirro de Бобр>") transliterados como los nombres
		if Plater.GetActorSubName then
			local originalSub = Plater.GetActorSubName
			Plater.GetActorSubName = function(...)
				return Translit(originalSub(...))
			end
		end
		local function After(plateFrame) pcall(Layout, plateFrame) end
		hooksecurefunc(Plater, 'UpdatePlateSize', After)
		hooksecurefunc(Plater, 'UpdateUnitName', After)
		if Plater.UpdatePlateText then hooksecurefunc(Plater, 'UpdatePlateText', After) end
	end

	local f = CreateFrame('Frame')
	f:RegisterEvent('PLAYER_LOGIN')
	f:SetScript('OnEvent', HookPlater)
	HookPlater()

	-- vida de las placas: actualizar el halo
	local g = CreateFrame('Frame')
	for _, ev in ipairs({ 'UNIT_HEALTH', 'UNIT_MAXHEALTH', 'NAME_PLATE_UNIT_ADDED', 'UNIT_LEVEL' }) do pcall(g.RegisterEvent, g, ev) end
	g:SetScript('OnEvent', function(_, event, unit)
		if type(unit) ~= 'string' or not unit:find('^nameplate') then return end
		local plate = C_NamePlate and C_NamePlate.GetNamePlateForUnit and C_NamePlate.GetNamePlateForUnit(unit)
		if not (plate and plate.unitFrame) then return end
		if event == 'UNIT_LEVEL' then
			pcall(UpdateNameOnlyText, plate)
			pcall(UpdateNameOnlyLevel, plate)
		else
			pcall(UpdateGlow, plate)
		end
	end)
end

-- Plater: jugadores aliados en "solo nombre", salvo con especialización de sanador,
-- que muestra sus barras de vida. Se cambia la opción "Only Show Player Name" del
-- perfil TomasUI de Plater al entrar y al cambiar de especialización o talentos.
do
	-- Puntos gastados en un árbol de talentos clásico. GetTalentTabInfo cambia de
	-- formato según el cliente: (nombre, icono, puntos, ...) o (id, nombre, desc,
	-- icono, puntos, ...). Si no da puntos, sumamos los rangos de sus talentos.
	local function TreePoints(tab)
		local r = { GetTalentTabInfo(tab) }
		local name, points
		if type(r[1]) == 'number' then name, points = r[2], r[5] else name, points = r[1], r[3] end
		if type(points) ~= 'number' and GetNumTalents and GetTalentInfo then
			points = 0
			for i = 1, (GetNumTalents(tab) or 0) do
				local rank = select(5, GetTalentInfo(tab, i))
				if type(rank) == 'number' then points = points + rank end
			end
		end
		return type(name) == 'string' and name or ('árbol ' .. tab), type(points) == 'number' and points or 0
	end

	-- WoW Forever: los tres árboles clásicos son grupos de un único árbol de
	-- rasgos (C_Traits), en el orden de la ventana de talentos.
	-- Devuelve una lista { {name, points}, ... } o nil.
	local function ByOrder(a, b) return (a.orderIndex or 0) < (b.orderIndex or 0) end
	local function TraitTrees()
		if not (C_ClassTalents and C_ClassTalents.GetActiveConfigID and C_Traits
			and C_Traits.GetGroupDisplayInfoByTreeID and C_Traits.GetGroupCurrencyInfo) then return end
		local configID = C_ClassTalents.GetActiveConfigID()
		local config = configID and C_Traits.GetConfigInfo(configID)
		local treeID = config and config.treeIDs and config.treeIDs[1]
		if not treeID then return end
		local groups = C_Traits.GetGroupDisplayInfoByTreeID(treeID)
		if type(groups) ~= 'table' or #groups == 0 then return end
		table.sort(groups, ByOrder)
		local list = {}
		for i, g in ipairs(groups) do
			local info = C_Traits.GetGroupCurrencyInfo(configID, { g.groupID })
			info = info and info[1]
			local c = info and info.currencyInfos and info.currencyInfos[1]
			list[i] = { name = g.displayName or ('árbol ' .. i), points = (c and type(c.spent) == 'number') and c.spent or 0 }
		end
		return list
	end

	-- Árboles clásicos de toda la vida (otros clientes)
	local function ClassicTrees()
		if not GetTalentTabInfo then return end
		local list = {}
		for tab = 1, ((GetNumTalentTabs and GetNumTalentTabs()) or 3) do
			local ok, name, points = pcall(TreePoints, tab)
			if ok then list[#list + 1] = { name = name, points = points } end
		end
		return #list > 0 and list or nil
	end

	-- El árbol con más puntos decide el rol
	local function TreeRole()
		local ok, list = pcall(TraitTrees)
		if not (ok and list) then list = ClassicTrees() end
		if not list then return end
		local _, class = UnitClass('player')
		local healers = (ns.Config.friendlyPlates and ns.Config.friendlyPlates.healerTrees or {})[class]
		local best, bestPoints, bestName, detail = nil, 0, nil, {}
		for i, t in ipairs(list) do
			detail[#detail + 1] = format('%s %d', t.name, t.points)
			if t.points > bestPoints then best, bestPoints, bestName = i, t.points, t.name end
		end
		if not best then return nil, nil, table.concat(detail, ' / ') end
		local isHealer = false
		for _, t in ipairs(healers or {}) do if t == best then isHealer = true end end
		return isHealer and 'HEALER' or 'DAMAGER', bestName, table.concat(detail, ' / ')
	end

	-- Especialización moderna (por si el cliente la tiene)
	local function ModernRole()
		local S = C_SpecializationInfo
		local getSpec = (S and S.GetSpecialization) or GetSpecialization
		local getInfo = (S and S.GetSpecializationInfo) or GetSpecializationInfo
		local spec = getSpec and getSpec()
		if not (spec and spec > 0) then return end
		local name, role
		if getInfo then
			local _, n, _, _, r = getInfo(spec)
			name, role = n, r
		end
		if not role and GetSpecializationRole then role = GetSpecializationRole(spec) end
		return role, name
	end

	local function SpecRole()
		local role, name, detail = TreeRole()
		if role then return role, name, detail end
		local mrole, mname = ModernRole()
		return mrole, mname, detail
	end

	local function Wanted()
		local cfg = ns.Config.friendlyPlates
		if not cfg then return end
		local role = SpecRole()
		if cfg.barsForHealers and role == 'HEALER' then return false end
		return cfg.nameOnly and true or false
	end

	-- Ajustes forzados de Plater (Config.platerOverrides), sobre el perfil TomasUI
	function ns.ApplyPlaterOverrides()
		local Plater = _G.Plater
		local db = Plater and Plater.db
		local overrides = ns.Config.platerOverrides
		if not (overrides and db and db.profile and db.GetCurrentProfile) then return end
		if db:GetCurrentProfile() ~= ns.Config.profileName then return end
		local changed = false
		for path, value in pairs(overrides) do
			local t, keys = db.profile, { strsplit('.', path) }
			for i = 1, #keys - 1 do
				if type(t[keys[i]]) ~= 'table' then t[keys[i]] = {} end
				t = t[keys[i]]
			end
			if t[keys[#keys]] ~= value then
				t[keys[#keys]] = value
				changed = true
			end
		end
		if changed then
			if Plater.RefreshDBUpvalues then pcall(Plater.RefreshDBUpvalues) end
			if Plater.UpdateAllPlates then pcall(Plater.UpdateAllPlates, true) end
		end
	end

	function ns.UpdateFriendlyPlates()
		local Plater = _G.Plater
		local db = Plater and Plater.db
		if not (db and db.profile and db.profile.plate_config and db.GetCurrentProfile) then return end
		if db:GetCurrentProfile() ~= ns.Config.profileName then return end
		local want = Wanted()
		if want == nil then return end
		local pc = db.profile.plate_config.friendlyplayer
		if not pc or pc.only_thename == want then return end
		pc.only_thename = want
		if Plater.UpdateAllPlates then pcall(Plater.UpdateAllPlates) end
	end

	function ns.FriendlyPlatesStatus()
		local role, name, detail = SpecRole()
		local want = Wanted()
		return format('talentos: %s · principal: %s · rol: %s · aliados: %s',
			tostring(detail or '?'), tostring(name or '?'), tostring(role or '?'),
			want == nil and 'sin cambios' or (want and 'solo nombre' or 'barras de vida'))
	end

	local function Schedule() C_Timer.After(0.5, ns.UpdateFriendlyPlates) end

	local f = CreateFrame('Frame')
	for _, ev in ipairs({ 'PLAYER_ENTERING_WORLD', 'PLAYER_SPECIALIZATION_CHANGED', 'ACTIVE_TALENT_GROUP_CHANGED',
		'PLAYER_TALENT_UPDATE', 'CHARACTER_POINTS_CHANGED', 'TRAIT_CONFIG_UPDATED',
		'TRAIT_TREE_CURRENCY_INFO_UPDATED', 'ACTIVE_COMBAT_CONFIG_CHANGED' }) do
		pcall(f.RegisterEvent, f, ev) -- no todos los eventos existen en todos los clientes
	end
	f:SetScript('OnEvent', function(_, event, unit)
		if event == 'PLAYER_SPECIALIZATION_CHANGED' and unit and unit ~= 'player' then return end
		Schedule()
		if event == 'PLAYER_ENTERING_WORLD' then
			C_Timer.After(3, ns.UpdateFriendlyPlates)
			C_Timer.After(3, function() pcall(ns.ApplyPlaterOverrides) end)
		end
	end)
end
