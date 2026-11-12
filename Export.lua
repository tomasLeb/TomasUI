-- TomasUI · Export.lua
-- /tui export: recoge el estado actual del autor (perfil "TomasUI" de ElvUI, Plater y Details!,
-- ajustes privados del personaje, distribuciones del modo edición y medidas de pantalla).
--  · Lo guarda en TomasUIDB.export (SavedVariables) para que tools/build_data.py genere
--    Data.lua directamente desde la carpeta WTF tras un /reload.
--  · Y lo muestra como Data.lua completo en una ventana, por si se prefiere copiar y pegar.

local _, ns = ...

local function Collect()
	local E = unpack(ElvUI)
	local D = E:GetModule('Distributor')
	local name = ns.Config.profileName

	local _, elvProfile = D:ExportProfile('profile', name, 'text')
	if not elvProfile then return nil, 'No encuentro el perfil "' .. name .. '" en ElvUI.' end
	local _, elvPrivate = D:ExportProfile('private', nil, 'text')

	local plater = ''
	if C_AddOns.IsAddOnLoaded('Plater') and PlaterAPI and PlaterAPI.ExportProfile then
		local keys = PlaterAPI:GetProfileKeys() or {}
		local key = keys[name] and name or PlaterAPI:GetCurrentProfileKey()
		plater = PlaterAPI:ExportProfile(key) or ''
	end

	local details = ''
	local D = _G.Details
	if D and D.ExportCurrentProfile then
		local profileName = (D.GetProfile and D:GetProfile(name, false)) and name or nil
		local ok, str = pcall(D.ExportCurrentProfile, D, profileName)
		if ok and type(str) == 'string' then details = str end
	end

	ns.SnapshotEditModeLayouts()

	local physW, physH = GetPhysicalScreenSize()
	local elvW, elvH = E.UIParent:GetSize()

	return {
		version = tonumber(date('%Y%m%d%H%M')),
		ref = {
			physW = physW, physH = physH,
			uiScale = E.global.general.UIScale,
			uiW = GetScreenWidth(), uiH = GetScreenHeight(),
			elvW = elvW, elvH = elvH,
			ultrawide = E.global.general.ultrawide and true or false,
			eyefinity = E.global.general.eyefinity and true or false,
		},
		elvProfile = elvProfile,
		elvPrivate = elvPrivate or '',
		plater = plater,
		details = details,
		editModeLayouts = TomasUIDB.editModeSnapshot or ns.Data.editModeLayouts or {},
	}
end

local function Num(n)
	if n == math.floor(n) then return tostring(n) end
	return format('%.10g', n)
end

local function ToDataLua(d)
	local layouts = {}
	for name, str in pairs(d.editModeLayouts) do
		tinsert(layouts, format('\t\t[%q] = [=[%s]=],', name, str))
	end
	table.sort(layouts)
	local r = d.ref
	return format([[-- TomasUI · Data.lua
-- GENERADO por /tui export (o tools/build_data.py). No editar a mano: la configuración va en Config.lua.
local _, ns = ...

ns.Data = {
	version = %d,
	ref = {
		physW = %s, physH = %s,
		uiScale = %s,
		uiW = %s, uiH = %s,
		elvW = %s, elvH = %s,
		ultrawide = %s, eyefinity = %s,
	},
	editModeLayouts = {
%s
	},
	elvProfile = [=[%s]=],
	elvPrivate = [=[%s]=],
	plater = [=[%s]=],
	details = [=[%s]=],
}
]], d.version, Num(r.physW), Num(r.physH), Num(r.uiScale), Num(r.uiW), Num(r.uiH), Num(r.elvW), Num(r.elvH),
		tostring(r.ultrawide), tostring(r.eyefinity), table.concat(layouts, '\n'), d.elvProfile, d.elvPrivate, d.plater, d.details or '')
end

local frame
local function GetFrame()
	if frame then return frame end
	frame = CreateFrame('Frame', 'TomasUIExportFrame', UIParent, 'BackdropTemplate')
	frame:SetSize(700, 450)
	frame:SetPoint('CENTER')
	frame:SetFrameStrata('DIALOG')
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag('LeftButton')
	frame:SetScript('OnDragStart', frame.StartMoving)
	frame:SetScript('OnDragStop', frame.StopMovingOrSizing)
	frame:SetBackdrop({ bgFile = 'Interface\\Buttons\\WHITE8x8', edgeFile = 'Interface\\Buttons\\WHITE8x8', edgeSize = 1 })
	frame:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
	frame:SetBackdropBorderColor(0, 0, 0, 1)

	local title = frame:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
	title:SetPoint('TOPLEFT', 10, -10)
	title:SetText('TomasUI · Data.lua (también guardado para tools/build_data.py tras /reload)')

	local close = CreateFrame('Button', nil, frame, 'UIPanelCloseButton')
	close:SetPoint('TOPRIGHT', 2, 2)

	local scroll = CreateFrame('ScrollFrame', nil, frame, 'UIPanelScrollFrameTemplate')
	scroll:SetPoint('TOPLEFT', 10, -32)
	scroll:SetPoint('BOTTOMRIGHT', -30, 10)

	local edit = CreateFrame('EditBox', nil, scroll)
	edit:SetMultiLine(true)
	edit:SetMaxLetters(0)
	edit:SetAutoFocus(true)
	edit:SetFontObject(ChatFontNormal)
	edit:SetWidth(650)
	edit:SetScript('OnEscapePressed', function() frame:Hide() end)
	scroll:SetScrollChild(edit)
	frame.edit = edit

	return frame
end

function ns.ShowExport()
	if InCombatLockdown() then
		ns.Print('sal de combate para exportar.')
		return
	end
	local data, err = Collect()
	if not data then
		ns.Print(err)
		return
	end
	TomasUIDB.export = data
	TomasUIDB.author = true -- quien exporta es el autor: no se le pedirá aplicar su propio perfil

	ns.Print(format('Exportado (versión %s). Haz /reload para que quede guardado en disco.', ns.VersionLabel(data.version)))
	local f = GetFrame()
	f.edit:SetText(ToDataLua(data))
	f.edit:HighlightText()
	f:Show()
end
