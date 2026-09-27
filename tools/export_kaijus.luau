-- Exporta a geometria dos kaijus (gerada pelo KaijuModel.luau de verdade) em JSON,
-- rodando fora do Roblox com uma imitação mínima da API (Vector3, CFrame, Instance...).
-- Uso: luaurun tools/export_kaijus.luau > kaijus.json
-- (o runner expõe readfile() e loadsource(); veja tools/README.md)

local ROOT = "src/shared/"

---------------------------------------------------------------------------
-- Vector3
---------------------------------------------------------------------------
local V3 = {}
V3.__index = function(v, k)
	if k == "Magnitude" then
		return math.sqrt(v.X * v.X + v.Y * v.Y + v.Z * v.Z)
	elseif k == "Unit" then
		local m = math.sqrt(v.X * v.X + v.Y * v.Y + v.Z * v.Z)
		return V3.new(v.X / m, v.Y / m, v.Z / m)
	end
	return rawget(V3, k)
end
function V3.new(x, y, z)
	return setmetatable({ X = x or 0, Y = y or 0, Z = z or 0 }, V3)
end
V3.__add = function(a, b)
	return V3.new(a.X + b.X, a.Y + b.Y, a.Z + b.Z)
end
V3.__sub = function(a, b)
	return V3.new(a.X - b.X, a.Y - b.Y, a.Z - b.Z)
end
V3.__mul = function(a, b)
	if type(a) == "number" then
		a, b = b, a
	end
	if type(b) == "number" then
		return V3.new(a.X * b, a.Y * b, a.Z * b)
	end
	return V3.new(a.X * b.X, a.Y * b.Y, a.Z * b.Z)
end
V3.__div = function(a, b)
	return V3.new(a.X / b, a.Y / b, a.Z / b)
end
V3.__unm = function(a)
	return V3.new(-a.X, -a.Y, -a.Z)
end
local Vector3 = { new = V3.new, one = V3.new(1, 1, 1), zero = V3.new(0, 0, 0) }

---------------------------------------------------------------------------
-- CFrame (posição + matriz de rotação 3x3 em linhas)
---------------------------------------------------------------------------
local CF = {}
CF.__index = function(c, k)
	if k == "Position" then
		return V3.new(c.p[1], c.p[2], c.p[3])
	elseif k == "LookVector" then
		return V3.new(-c.r[1][3], -c.r[2][3], -c.r[3][3])
	end
	return rawget(CF, k)
end
local function mkcf(p, r)
	return setmetatable({ p = p, r = r }, CF)
end
local I = { { 1, 0, 0 }, { 0, 1, 0 }, { 0, 0, 1 } }
local function matmul(a, b)
	local out = {}
	for i = 1, 3 do
		out[i] = {}
		for j = 1, 3 do
			out[i][j] = a[i][1] * b[1][j] + a[i][2] * b[2][j] + a[i][3] * b[3][j]
		end
	end
	return out
end
local function matvec(a, v)
	return {
		a[1][1] * v[1] + a[1][2] * v[2] + a[1][3] * v[3],
		a[2][1] * v[1] + a[2][2] * v[2] + a[2][3] * v[3],
		a[3][1] * v[1] + a[3][2] * v[2] + a[3][3] * v[3],
	}
end
CF.__mul = function(a, b)
	if getmetatable(b) == CF then
		local pv = matvec(a.r, b.p)
		return mkcf({ a.p[1] + pv[1], a.p[2] + pv[2], a.p[3] + pv[3] }, matmul(a.r, b.r))
	end
	local pv = matvec(a.r, { b.X, b.Y, b.Z })
	return V3.new(a.p[1] + pv[1], a.p[2] + pv[2], a.p[3] + pv[3])
end
local CFrame = {}
function CFrame.new(x, y, z)
	if type(x) == "table" then
		return mkcf({ x.X, x.Y, x.Z }, I)
	end
	return mkcf({ x or 0, y or 0, z or 0 }, I)
end
function CFrame.Angles(rx, ry, rz)
	local cx, sx = math.cos(rx), math.sin(rx)
	local cy, sy = math.cos(ry), math.sin(ry)
	local cz, sz = math.cos(rz), math.sin(rz)
	local Rx = { { 1, 0, 0 }, { 0, cx, -sx }, { 0, sx, cx } }
	local Ry = { { cy, 0, sy }, { 0, 1, 0 }, { -sy, 0, cy } }
	local Rz = { { cz, -sz, 0 }, { sz, cz, 0 }, { 0, 0, 1 } }
	return mkcf({ 0, 0, 0 }, matmul(matmul(Rx, Ry), Rz))
end
function CFrame.lookAt(pos, target)
	local look = (target - pos).Unit
	local right = V3.new(-look.Z, 0, look.X) -- look x up(0,1,0)
	if right.Magnitude < 1e-6 then
		right = V3.new(1, 0, 0)
	else
		right = right.Unit
	end
	local up = V3.new(
		right.Y * look.Z - right.Z * look.Y,
		right.Z * look.X - right.X * look.Z,
		right.X * look.Y - right.Y * look.X
	)
	return mkcf({ pos.X, pos.Y, pos.Z }, {
		{ right.X, up.X, -look.X },
		{ right.Y, up.Y, -look.Y },
		{ right.Z, up.Z, -look.Z },
	})
end

---------------------------------------------------------------------------
-- Color3 e afins
---------------------------------------------------------------------------
local C3 = {}
C3.__index = C3
local function color(r, g, b)
	return setmetatable({ R = r, G = g, B = b }, C3)
end
function C3:Lerp(o, t)
	return color(self.R + (o.R - self.R) * t, self.G + (o.G - self.G) * t, self.B + (o.B - self.B) * t)
end
local Color3 = {
	new = color,
	fromRGB = function(r, g, b)
		return color(r / 255, g / 255, b / 255)
	end,
}
local function stub(...)
	return { ... }
end
local stubLib = { new = stub }

local Enum = setmetatable({}, {
	__index = function(_, enumName)
		return setmetatable({}, {
			__index = function(_, item)
				return enumName .. "." .. item
			end,
		})
	end,
})

---------------------------------------------------------------------------
-- Instance
---------------------------------------------------------------------------
local Inst = {}
Inst.__index = function(t, k)
	local m = rawget(Inst, k)
	if m then
		return m
	end
	local props = rawget(t, "_props")
	if props[k] ~= nil then
		return props[k]
	end
	for _, c in rawget(t, "_children") do
		if c._props.Name == k then
			return c
		end
	end
	return nil
end
Inst.__newindex = function(t, k, v)
	if k == "Parent" then
		local old = t._props.Parent
		if old then
			for i, c in old._children do
				if c == t then
					table.remove(old._children, i)
					break
				end
			end
		end
		if v then
			table.insert(v._children, t)
		end
	end
	t._props[k] = v
end
local PART_CLASSES = { Part = true, WedgePart = true }
function Inst:IsA(name)
	if name == "BasePart" then
		return PART_CLASSES[self.ClassName] == true
	end
	return self.ClassName == name
end
function Inst:SetAttribute(k, v)
	self._attrs[k] = v
end
function Inst:GetAttribute(k)
	return self._attrs[k]
end
function Inst:GetChildren()
	return table.clone(self._children)
end
function Inst:GetDescendants()
	local out = {}
	local function walk(n)
		for _, c in n._children do
			table.insert(out, c)
			walk(c)
		end
	end
	walk(self)
	return out
end
function Inst:FindFirstChild(name)
	for _, c in self._children do
		if c._props.Name == name then
			return c
		end
	end
	return nil
end
function Inst:Emit() end
local Instance = {
	new = function(className)
		local t =
			setmetatable({ _props = { ClassName = className, Name = className }, _children = {}, _attrs = {} }, Inst)
		if PART_CLASSES[className] then
			t._props.Shape = "Enum.PartType.Block"
			t._props.Transparency = 0
			t._props.Material = "Enum.Material.Plastic"
		end
		return t
	end,
}

---------------------------------------------------------------------------
-- require
---------------------------------------------------------------------------
local env = {
	Vector3 = Vector3,
	CFrame = CFrame,
	Color3 = Color3,
	Enum = Enum,
	Instance = Instance,
	ColorSequence = stubLib,
	ColorSequenceKeypoint = stubLib,
	NumberSequence = stubLib,
	NumberSequenceKeypoint = stubLib,
	NumberRange = stubLib,
	Vector2 = stubLib,
	UDim2 = stubLib,
	math = math,
	string = string,
	table = table,
	pairs = pairs,
	ipairs = ipairs,
	next = next,
	type = type,
	tostring = tostring,
	setmetatable = setmetatable,
	getmetatable = getmetatable,
	rawget = rawget,
	error = error,
	print = print,
}

local cache = {}
local function load(name)
	if cache[name] then
		return cache[name]
	end
	local fn = loadsource(readfile(ROOT .. name .. ".luau"), name)
	local script = { Parent = setmetatable({}, {
		__index = function(_, k)
			return k
		end,
	}) }
	local moduleEnv = setmetatable({ script = script, require = load }, { __index = env })
	setfenv(fn, moduleEnv)
	cache[name] = fn()
	return cache[name]
end
env.require = load

local Config = load("Config")
local KaijuData = load("KaijuData")
local KaijuModel = load("KaijuModel")

---------------------------------------------------------------------------
-- JSON
---------------------------------------------------------------------------
local function num(n)
	return string.format("%.3f", n)
end
local function colorHex(c)
	return string.format(
		"#%02x%02x%02x",
		math.clamp(math.floor(c.R * 255 + 0.5), 0, 255),
		math.clamp(math.floor(c.G * 255 + 0.5), 0, 255),
		math.clamp(math.floor(c.B * 255 + 0.5), 0, 255)
	)
end
local function jstr(s)
	return '"' .. string.gsub(tostring(s), '[\\"]', "\\%0") .. '"'
end

local function partsOf(model)
	local list = {}
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") and p.Name ~= "Root" then
			table.insert(list, p)
		end
	end
	return list
end

-- Geometria (igual em todas as mutações)
local function exportGeometry(parts)
	local out = {}
	for _, p in parts do
		local cf = p.CFrame
		local r = cf.r
		local shape = if p.ClassName == "WedgePart" then "Wedge" else string.match(p.Shape, "(%w+)$")
		table.insert(
			out,
			string.format(
				'{"n":%s,"s":%s,"sz":[%s,%s,%s],"m":[%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s]}',
				jstr(p.Name),
				jstr(shape),
				num(p.Size.X),
				num(p.Size.Y),
				num(p.Size.Z),
				num(r[1][1]),
				num(r[1][2]),
				num(r[1][3]),
				num(cf.p[1]),
				num(r[2][1]),
				num(r[2][2]),
				num(r[2][3]),
				num(cf.p[2]),
				num(r[3][1]),
				num(r[3][2]),
				num(r[3][3]),
				num(cf.p[3])
			)
		)
	end
	return "[" .. table.concat(out, ",") .. "]"
end

-- Aparência por mutação: [cor, material, transparência, reflexo] na mesma ordem das peças
local function exportLook(parts)
	local out = {}
	for _, p in parts do
		table.insert(
			out,
			string.format(
				"[%s,%s,%s,%s]",
				jstr(colorHex(p.Color)),
				jstr(string.match(p.Material, "(%w+)$")),
				num(p.Transparency or 0),
				num(p.Reflectance or 0)
			)
		)
	end
	return "[" .. table.concat(out, ",") .. "]"
end

local function exportDef(def, isGuard)
	local variants = {}
	local geometry
	local mutations = if isGuard then { Config.MutationsByName.Normal } else Config.Mutations
	for _, mut in mutations do
		local model = KaijuModel.build(def, mut.Name)
		local parts = partsOf(model)
		geometry = geometry or exportGeometry(parts)
		table.insert(variants, jstr(mut.Name) .. ":" .. exportLook(parts))
	end
	local rarity = Config.Rarities[def.Rarity]

	-- números reais do jogo: renda e tempo de crescimento por estágio
	local stages = {}
	for i, st in Config.Stages do
		local grow = if st.GrowTime then st.GrowTime * rarity.GrowFactor else -1
		table.insert(
			stages,
			string.format(
				'{"name":%s,"scale":%s,"income":%s,"grow":%s,"carry":%s}',
				jstr(st.Name),
				num(st.Scale),
				num((def.Income or 0) * st.IncomeMult),
				num(grow),
				num(st.CarrySpeed)
			)
		)
	end

	-- chance de aparecer em cada ninho de cada zona
	local zones = {}
	if not isGuard then
		for _, zone in Config.Zones do
			local total = 0
			for _, w in zone.Weights do
				total += w
			end
			local w = zone.Weights[def.Rarity] or 0
			if w > 0 then
				local pool = KaijuData.ByRarity[def.Rarity]
				local pct = w / total / #pool * 100
				table.insert(zones, string.format('{"zone":%s,"pct":%s}', jstr(zone.Name), num(pct)))
			end
		end
	end

	return string.format(
		'{"id":%s,"name":%s,"rarity":%s,"rarityColor":%s,"guard":%s,"income":%s,"geometry":%s,"variants":{%s},"stages":[%s],"zones":[%s]}',
		jstr(def.Id),
		jstr(def.Name),
		jstr(def.Rarity),
		jstr(colorHex(rarity.Color)),
		if isGuard then "true" else "false",
		num(def.Income or 0),
		geometry,
		table.concat(variants, ","),
		table.concat(stages, ","),
		table.concat(zones, ",")
	)
end

local items = {}
for _, def in KaijuData.List do
	table.insert(items, exportDef(def, false))
end
for i, def in KaijuData.Guards do
	local zone = Config.Zones[i]
	local entry = exportDef(def, true)
	entry = string.gsub(
		entry,
		'"zones":%[%]',
		string.format('"zones":[],"guardOf":%s,"guardSpeed":%d', jstr(zone.Name), zone.GuardSpeed)
	)
	table.insert(items, entry)
end

local mutations = {}
for _, m in Config.Mutations do
	local weightTotal = 0
	for _, mm in Config.Mutations do
		weightTotal += mm.Weight
	end
	table.insert(
		mutations,
		string.format(
			'{"name":%s,"mult":%s,"pct":%s,"light":%s,"particles":%s}',
			jstr(m.Name),
			num(m.Mult),
			num(m.Weight / weightTotal * 100),
			if m.Light then jstr(colorHex(m.Light)) else "null",
			if m.Particles then jstr(colorHex(m.Particles)) else "null"
		)
	)
end

print(
	string.format(
		'{"kaijus":[%s],"mutations":[%s],"guardScale":%s}',
		table.concat(items, ","),
		table.concat(mutations, ","),
		num(Config.GuardScale)
	)
)
