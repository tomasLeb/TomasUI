-- TomasUI: fuente incluida en el addon.
-- Registra la fuente en LibSharedMedia (ElvUI, Plater y Details! la ven como
-- una opción más) y ofrece ns.RemapFonts para cambiar, en los perfiles que
-- importamos, las fuentes de Blizzard por la nuestra.

local _, ns = ...

local cfg = ns.Config.font
if not cfg then return end

local LSM = LibStub and LibStub('LibSharedMedia-3.0', true)
if LSM then
	LSM:Register('font', cfg.name, cfg.file)
end

-- ElvUI calcula las fuentes generales de Blizzard (STANDARD_TEXT_FONT, etc.)
-- al cargarse, antes que nosotros: las recalculamos ya con la fuente registrada.
local E = ElvUI and unpack(ElvUI)
if E and E.private and E.private.general and E.db and E.db.general then
	pcall(E.UpdateMedia, E)
	pcall(E.UpdateBlizzardSpecialFonts, E)
end

local names, files = {}, {}
for _, n in ipairs(cfg.replace or {}) do names[n] = true end
for _, f in ipairs(cfg.replaceFiles or {}) do files[f:lower()] = true end

local function NameSet(extra)
	if not extra then return names end
	local set = {}
	for n in pairs(names) do set[n] = true end
	for _, n in ipairs(extra) do set[n] = true end
	return set
end

-- Recorre la tabla y cambia nombres de fuente ("Arial Narrow") por el nuestro
-- y rutas de fichero ("Fonts\ARIALN.TTF") por la ruta del nuestro.
-- extra: lista opcional de nombres que también se cambian.
-- Devuelve cuántos valores ha cambiado.
function ns.RemapFonts(tbl, extra)
	local set = NameSet(extra)
	local seen, count = {}, 0
	local function walk(t)
		if seen[t] then return end
		seen[t] = true
		for k, v in pairs(t) do
			local tv = type(v)
			if tv == 'table' then
				walk(v)
			elseif tv == 'string' then
				if set[v] then
					t[k] = cfg.name
					count = count + 1
				elseif files[v:lower()] then
					t[k] = cfg.file
					count = count + 1
				end
			end
		end
	end
	if type(tbl) == 'table' then walk(tbl) end
	return count
end

-- Los perfiles de ElvUI solo guardan lo que difiere de los valores por defecto.
-- Para las fuentes que se quedaron en su valor por defecto, escribimos la nuestra
-- en el perfil (target) siguiendo la tabla de valores por defecto (defaults).
function ns.FillFontDefaults(target, defaults, extra)
	local set = NameSet(extra)
	local count = 0
	local function walk(t, d, depth)
		if depth > 12 then return end
		for k, dv in pairs(d) do
			local tv = t[k]
			if type(dv) == 'table' then
				if tv == nil then
					local sub = {}
					walk(sub, dv, depth + 1)
					if next(sub) then t[k] = sub end
				elseif type(tv) == 'table' then
					walk(tv, dv, depth + 1)
				end
			elseif type(dv) == 'string' and tv == nil and set[dv] then
				t[k] = cfg.name
				count = count + 1
			end
		end
	end
	if type(target) == 'table' and type(defaults) == 'table' then walk(target, defaults, 0) end
	return count
end
