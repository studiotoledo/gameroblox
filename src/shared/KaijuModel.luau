-- Monta os modelos 3D dos kaijus a partir de peças, sem precisar de assets externos.
-- O modelo é construído virado para -Z (frente) com os pés em Y = 0 e escala 1 (Filhote).
-- Todas as peças ficam soldadas a "Root", que é o PrimaryPart e o pivô (nos pés).

local Config = require(script.Parent.Config)

local KaijuModel = {}

local BALL = Enum.PartType.Ball
local WHITE = Color3.new(1, 1, 1)
local GOLD = Color3.fromRGB(255, 205, 50)

type Colors = { Body: Color3, Belly: Color3, Accent: Color3, Eye: Color3 }

local function darker(c: Color3, f: number?): Color3
	return c:Lerp(Color3.new(0, 0, 0), f or 0.25)
end

local function mk(
	model: Model,
	name: string,
	size: Vector3,
	cf: CFrame,
	color: Color3,
	role: string,
	extra: { [string]: any }?
): BasePart
	local className = extra and extra.ClassName or "Part"
	local p = Instance.new(className) :: BasePart
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.Massless = true
	p.CastShadow = true
	p:SetAttribute("Role", role)
	if extra then
		for key, value in extra do
			if key ~= "ClassName" then
				(p :: any)[key] = value
			end
		end
	end
	p.Parent = model
	return p
end

local function eyes(m: Model, c: Colors, center: Vector3, spacing: number, size: number)
	for _, sx in { -1, 1 } do
		local x = center.X + sx * spacing
		mk(m, "Eye", Vector3.one * size, CFrame.new(x, center.Y, center.Z), WHITE, "Eye", { Shape = BALL })
		mk(
			m,
			"Pupil",
			Vector3.one * size * 0.55,
			CFrame.new(x, center.Y - size * 0.05, center.Z - size * 0.3),
			c.Eye,
			"Pupil",
			{ Shape = BALL }
		)
	end
end

local function crown(m: Model, base: Vector3, width: number, depth: number)
	local y = base.Y + 0.12
	mk(m, "Crown", Vector3.new(width * 0.6, 0.22, depth * 0.6), CFrame.new(base.X, y, base.Z), GOLD, "Detail", {
		Material = Enum.Material.Foil,
	})
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			mk(
				m,
				"CrownTip",
				Vector3.new(0.14, 0.3, 0.14),
				CFrame.new(base.X + sx * width * 0.24, y + 0.25, base.Z + sz * depth * 0.24),
				GOLD,
				"Detail",
				{ Material = Enum.Material.Foil }
			)
		end
	end
end

local function buildHead(m: Model, def, c: Colors, pos: Vector3, size: Vector3, withSnout: boolean)
	mk(m, "Head", size, CFrame.new(pos), c.Body, "Body")
	local front = pos.Z - size.Z / 2
	local eyeSize = math.min(size.X, size.Y) * 0.38
	eyes(m, c, Vector3.new(pos.X, pos.Y + size.Y * 0.15, front), size.X * 0.27, eyeSize)

	if def.Beak then
		mk(
			m,
			"Beak",
			Vector3.new(size.X * 0.4, size.Y * 0.25, size.Z * 0.45),
			CFrame.new(pos.X, pos.Y - size.Y * 0.18, front - size.Z * 0.18),
			Color3.fromRGB(255, 170, 40),
			"Detail"
		)
	elseif withSnout then
		local sn = Vector3.new(size.X * 0.75, size.Y * 0.45, size.Z * 0.55)
		local sc = Vector3.new(pos.X, pos.Y - size.Y * 0.22, front - sn.Z / 2 + 0.05)
		mk(m, "Snout", sn, CFrame.new(sc), c.Body, "Body")
		for _, sx in { -1, 1 } do
			mk(
				m,
				"Tooth",
				Vector3.new(0.14, 0.2, 0.14),
				CFrame.new(sc.X + sx * sn.X * 0.3, sc.Y - sn.Y / 2 - 0.06, sc.Z - sn.Z / 2 + 0.12),
				WHITE,
				"Detail"
			)
		end
	else
		mk(
			m,
			"Mouth",
			Vector3.new(size.X * 0.45, 0.1, 0.05),
			CFrame.new(pos.X, pos.Y - size.Y * 0.25, front - 0.02),
			darker(c.Body, 0.6),
			"Detail"
		)
	end

	local top = pos.Y + size.Y / 2
	if def.Horns then
		for _, sx in { -1, 1 } do
			mk(
				m,
				"Horn",
				Vector3.new(0.22, 0.6, 0.22),
				CFrame.new(pos.X + sx * size.X * 0.3, top + 0.25, pos.Z) * CFrame.Angles(0, 0, -sx * 0.35),
				c.Accent,
				"Accent"
			)
		end
	end
	if def.Ears then
		for _, sx in { -1, 1 } do
			mk(
				m,
				"Ear",
				Vector3.new(0.4, 0.5, 0.15),
				CFrame.new(pos.X + sx * size.X * 0.36, top + 0.18, pos.Z + 0.1) * CFrame.Angles(0, 0, -sx * 0.3),
				c.Body,
				"Body"
			)
		end
	end
	if def.Comb then
		mk(m, "Comb", Vector3.new(0.2, 0.45, size.Z * 0.6), CFrame.new(pos.X, top + 0.2, pos.Z), c.Accent, "Accent")
	end
	if def.Crown then
		crown(m, Vector3.new(pos.X, top, pos.Z), size.X, size.Z)
	end
	if def.Tusks then
		for _, sx in { -1, 1 } do
			mk(
				m,
				"Tusk",
				Vector3.new(0.18, 0.18, 0.8),
				CFrame.new(pos.X + sx * size.X * 0.28, pos.Y - size.Y * 0.35, front - 0.25) * CFrame.Angles(0.5, 0, 0),
				Color3.fromRGB(245, 240, 225),
				"Detail"
			)
		end
	end
end

-- Cada arquétipo monta o corpo e devolve os pontos da "coluna" (onde vão os espinhos),
-- a altura do topo das costas e onde ficam as asas.
local Archetypes = {}

function Archetypes.dino(m: Model, def, c: Colors)
	for _, sx in { -1, 1 } do
		mk(m, "Leg", Vector3.new(0.7, 1.0, 0.8), CFrame.new(sx * 0.55, 0.5, 0.1), darker(c.Body, 0.1), "Body")
		if def.Shoes then
			mk(m, "Shoe", Vector3.new(0.85, 0.35, 1.1), CFrame.new(sx * 0.55, 0.17, -0.05), WHITE, "Detail")
			mk(m, "ShoeStripe", Vector3.new(0.87, 0.1, 0.5), CFrame.new(sx * 0.55, 0.25, 0.1), c.Accent, "Detail")
		end
		mk(
			m,
			"Arm",
			Vector3.new(0.4, 0.8, 0.4),
			CFrame.new(sx * 1.05, 2.0, -0.45) * CFrame.Angles(-0.6, 0, 0),
			c.Body,
			"Body"
		)
	end
	mk(m, "Torso", Vector3.new(1.8, 1.7, 1.6), CFrame.new(0, 1.85, 0.1), c.Body, "Body")
	mk(m, "Belly", Vector3.new(1.2, 1.2, 0.1), CFrame.new(0, 1.75, -0.72), c.Belly, "Belly")
	mk(m, "Tail1", Vector3.new(1.0, 0.8, 1.2), CFrame.new(0, 1.3, 1.35) * CFrame.Angles(0.25, 0, 0), c.Body, "Body")
	mk(m, "Tail2", Vector3.new(0.6, 0.5, 1.0), CFrame.new(0, 0.95, 2.3) * CFrame.Angles(0.3, 0, 0), c.Body, "Body")
	buildHead(m, def, c, Vector3.new(0, 3.25, -0.25), Vector3.new(1.5, 1.3, 1.4), not def.Beak)
	return {
		Spine = { Vector3.new(0, 2.75, 0.7), Vector3.new(0, 1.9, 1.4), Vector3.new(0, 1.35, 2.3) },
		BackTop = 2.7,
		WingAnchor = Vector3.new(0, 2.4, 0.4),
	}
end

function Archetypes.quad(m: Model, def, c: Colors)
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			mk(
				m,
				"Leg",
				Vector3.new(0.55, 0.85, 0.55),
				CFrame.new(sx * 0.65, 0.42, sz * 0.75),
				darker(c.Body, 0.1),
				"Body"
			)
		end
	end
	mk(m, "Torso", Vector3.new(1.8, 1.3, 2.4), CFrame.new(0, 1.45, 0.1), c.Body, "Body")
	mk(m, "Belly", Vector3.new(1.2, 0.9, 0.1), CFrame.new(0, 1.4, -1.12), c.Belly, "Belly")
	mk(m, "Tail", Vector3.new(0.4, 0.4, 1.1), CFrame.new(0, 1.75, 1.75) * CFrame.Angles(0.45, 0, 0), c.Body, "Body")

	local heads = def.Heads or 1
	if heads == 1 then
		buildHead(m, def, c, Vector3.new(0, 2.05, -1.5), Vector3.new(1.3, 1.1, 1.1), not def.Tusks)
	else
		for i = 1, heads do
			local x = (i - (heads + 1) / 2) * 0.95
			local y = if i == math.ceil(heads / 2) and heads % 2 == 1 then 2.65 else 2.35
			mk(m, "Neck", Vector3.new(0.4, y - 1.6, 0.4), CFrame.new(x, (y + 1.6) / 2, -1.3), c.Body, "Body")
			buildHead(m, def, c, Vector3.new(x, y, -1.5), Vector3.new(0.85, 0.8, 0.85), true)
		end
	end

	if def.Shell then
		mk(m, "Shell", Vector3.new(2.1, 1.0, 2.6), CFrame.new(0, 1.85, 0.1), c.Accent, "Accent")
		for _, z in { -0.65, 0, 0.65 } do
			mk(
				m,
				"ShellBand",
				Vector3.new(2.15, 1.05, 0.18),
				CFrame.new(0, 1.85, 0.1 + z),
				darker(c.Accent, 0.35),
				"Detail"
			)
		end
	end

	local backTop = if def.Shell then 2.35 else 2.1
	return {
		Spine = {
			Vector3.new(0, backTop + 0.05, -0.5),
			Vector3.new(0, backTop + 0.05, 0.2),
			Vector3.new(0, backTop + 0.05, 0.9),
		},
		BackTop = backTop,
		WingAnchor = Vector3.new(0, backTop - 0.2, -0.1),
	}
end

function Archetypes.blob(m: Model, def, c: Colors)
	mk(m, "Torso", Vector3.new(2.2, 1.8, 2.0), CFrame.new(0, 1.0, 0), c.Body, "Body")
	mk(m, "Belly", Vector3.new(1.5, 1.0, 0.1), CFrame.new(0, 0.8, -1.02), c.Belly, "Belly")
	for _, sx in { -1, 1 } do
		mk(m, "Foot", Vector3.new(0.7, 0.35, 0.6), CFrame.new(sx * 0.75, 0.17, -0.9), darker(c.Body, 0.15), "Body")
	end
	buildHead(m, def, c, Vector3.new(0, 2.25, -0.2), Vector3.new(1.8, 0.8, 1.5), false)
	if def.Tentacles then
		for i = 0, 5 do
			local a = i / 6 * math.pi * 2
			local p = Vector3.new(math.cos(a) * 1.15, 0.2, math.sin(a) * 1.15)
			mk(
				m,
				"Tentacle",
				Vector3.new(0.35, 0.35, 1.0),
				CFrame.lookAt(p, p * 2 + Vector3.new(0, 0.2, 0)),
				c.Accent,
				"Accent"
			)
		end
	else
		-- bochechas que "estufam"
		for _, sx in { -1, 1 } do
			mk(
				m,
				"Cheek",
				Vector3.new(0.6, 0.6, 0.6),
				CFrame.new(sx * 1.1, 1.5, -0.6),
				c.Accent,
				"Accent",
				{ Shape = BALL }
			)
		end
	end
	return { Spine = {}, BackTop = 2.6, WingAnchor = Vector3.new(0, 1.6, 0.3) }
end

function Archetypes.crab(m: Model, def, c: Colors)
	mk(m, "Torso", Vector3.new(2.4, 0.9, 1.8), CFrame.new(0, 1.2, 0), c.Body, "Body")
	mk(m, "Belly", Vector3.new(1.8, 0.1, 1.3), CFrame.new(0, 0.74, 0), c.Belly, "Belly")
	for _, sx in { -1, 1 } do
		for i = -1, 1 do
			mk(
				m,
				"Leg",
				Vector3.new(0.2, 1.0, 0.2),
				CFrame.new(sx * 1.35, 0.55, i * 0.55) * CFrame.Angles(0, 0, sx * 0.5),
				darker(c.Body, 0.15),
				"Body"
			)
		end
		mk(m, "ClawArm", Vector3.new(0.3, 0.3, 0.8), CFrame.new(sx * 1.2, 1.3, -1.1), c.Body, "Body")
		mk(m, "Claw", Vector3.new(0.8, 0.7, 0.8), CFrame.new(sx * 1.45, 1.5, -1.6), c.Accent, "Accent")
		mk(
			m,
			"ClawGap",
			Vector3.new(0.82, 0.12, 0.45),
			CFrame.new(sx * 1.45, 1.5, -1.8),
			darker(c.Accent, 0.6),
			"Detail"
		)
		mk(m, "EyeStalk", Vector3.new(0.15, 0.6, 0.15), CFrame.new(sx * 0.4, 1.9, -0.6), c.Body, "Body")
	end
	eyes(m, c, Vector3.new(0, 2.3, -0.6), 0.4, 0.42)
	mk(m, "Mouth", Vector3.new(0.7, 0.1, 0.05), CFrame.new(0, 1.1, -0.92), darker(c.Body, 0.6), "Detail")
	if def.Crown then
		crown(m, Vector3.new(0, 1.65, 0.1), 1.4, 1.2)
	end
	return {
		Spine = { Vector3.new(-0.6, 1.7, 0.3), Vector3.new(0.6, 1.7, 0.3) },
		BackTop = 1.65,
		WingAnchor = Vector3.new(0, 1.5, 0.4),
	}
end

function Archetypes.ape(m: Model, def, c: Colors)
	for _, sx in { -1, 1 } do
		mk(m, "Leg", Vector3.new(0.75, 1.0, 0.8), CFrame.new(sx * 0.55, 0.5, 0.1), darker(c.Body, 0.1), "Body")
		mk(m, "Arm", Vector3.new(0.65, 2.1, 0.65), CFrame.new(sx * 1.4, 1.75, -0.1), c.Body, "Body")
		mk(m, "Fist", Vector3.new(0.8, 0.6, 0.8), CFrame.new(sx * 1.4, 0.55, -0.2), darker(c.Body, 0.2), "Body")
	end
	mk(m, "Torso", Vector3.new(2.1, 1.9, 1.4), CFrame.new(0, 1.95, 0.1), c.Body, "Body")
	mk(m, "Belly", Vector3.new(1.3, 1.2, 0.1), CFrame.new(0, 2.0, -0.62), c.Belly, "Belly")
	buildHead(m, def, c, Vector3.new(0, 3.45, -0.15), Vector3.new(1.3, 1.15, 1.15), false)
	mk(m, "Face", Vector3.new(0.9, 0.55, 0.08), CFrame.new(0, 3.25, -0.76), c.Belly, "Belly")
	return {
		Spine = { Vector3.new(0, 2.95, 0.5), Vector3.new(0, 2.5, 0.8) },
		BackTop = 2.9,
		WingAnchor = Vector3.new(0, 2.6, 0.5),
	}
end

local function addFeatures(m: Model, def, c: Colors, info)
	local order = Config.Rarities[def.Rarity] and Config.Rarities[def.Rarity].Order or 1
	local spikeMaterial = if order >= 4 then Enum.Material.Neon else Enum.Material.SmoothPlastic

	if def.Spikes ~= false then
		for _, p in info.Spine do
			mk(
				m,
				"Spike",
				Vector3.new(0.18, 0.45, 0.45),
				CFrame.new(p) * CFrame.Angles(math.rad(45), 0, 0),
				c.Accent,
				"Accent",
				{ Material = spikeMaterial }
			)
		end
	end

	if def.Fin then
		mk(
			m,
			"Fin",
			Vector3.new(0.25, 1.1, 1.0),
			CFrame.new(0, info.BackTop + 0.5, 0.45),
			c.Accent,
			"Accent",
			{ ClassName = "WedgePart" }
		)
	end

	if def.Wings then
		local a = info.WingAnchor
		for _, sx in { -1, 1 } do
			mk(
				m,
				"Wing",
				Vector3.new(0.15, 1.4, 1.6),
				CFrame.new(a.X + sx * 1.15, a.Y + 0.5, a.Z) * CFrame.Angles(0, 0, -sx * 0.7),
				c.Accent,
				"Accent",
				{ Material = spikeMaterial, Transparency = 0.1 }
			)
		end
	end
end

local function applyMutation(m: Model, mutationName: string?)
	local mut = mutationName and Config.MutationsByName[mutationName]
	if not mut or mut.Name == "Normal" then
		return
	end
	for _, p in m:GetDescendants() do
		if p:IsA("BasePart") then
			local role = p:GetAttribute("Role")
			if role == "Body" or role == "Belly" then
				if mut.Color then
					p.Color = p.Color:Lerp(mut.Color, mut.Blend or 0.75)
				end
				if mut.Material then
					p.Material = mut.Material
				end
				if mut.Reflectance then
					p.Reflectance = mut.Reflectance
				end
				if mut.Transparency then
					p.Transparency = mut.Transparency
				end
			elseif role == "Accent" then
				if mut.AccentColor then
					p.Color = mut.AccentColor
				end
				if mut.AccentNeon then
					p.Material = Enum.Material.Neon
				end
			end
		end
	end
	local torso = m:FindFirstChild("Torso")
	if torso and mut.Light then
		local light = Instance.new("PointLight")
		light.Color = mut.Light
		light.Range = 10
		light.Brightness = 1.5
		light.Parent = torso
	end
	if torso and mut.Particles then
		local pe = Instance.new("ParticleEmitter")
		pe.Color = ColorSequence.new(mut.Particles)
		pe.LightEmission = 1
		pe.Size = NumberSequence.new(0.3, 0)
		pe.Rate = 8
		pe.Lifetime = NumberRange.new(0.8, 1.4)
		pe.Speed = NumberRange.new(1, 2)
		pe.SpreadAngle = Vector2.new(180, 180)
		pe.Parent = torso
	end
end

local function addRarityEffects(m: Model, def)
	local rarity = Config.Rarities[def.Rarity]
	local torso = m:FindFirstChild("Torso")
	if not rarity or not torso then
		return
	end
	if rarity.Order >= 5 then
		local sparkle = Instance.new("ParticleEmitter")
		sparkle.Name = "RaritySparkle"
		sparkle.Color = ColorSequence.new(rarity.Color)
		sparkle.LightEmission = 1
		sparkle.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.5, 0.35),
			NumberSequenceKeypoint.new(1, 0),
		})
		sparkle.Rate = 5
		sparkle.Lifetime = NumberRange.new(1, 1.6)
		sparkle.Speed = NumberRange.new(0.5, 1.5)
		sparkle.SpreadAngle = Vector2.new(180, 180)
		sparkle.Parent = torso
	end
end

-- Constrói o modelo de um kaiju. def = entrada do KaijuData (ou uma tabela no mesmo formato).
function KaijuModel.build(def, mutationName: string?): Model
	local m = Instance.new("Model")
	m.Name = def.Name
	local colors = def.Colors
	local c: Colors = {
		Body = colors.Body,
		Belly = colors.Belly or colors.Body:Lerp(WHITE, 0.5),
		Accent = colors.Accent or darker(colors.Body, 0.35),
		Eye = colors.Eye or Color3.fromRGB(25, 25, 30),
	}

	local builder = Archetypes[def.Archetype] or Archetypes.dino
	local info = builder(m, def, c)
	addFeatures(m, def, c, info)

	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = Vector3.new(2, 0.2, 2)
	root.CFrame = CFrame.new(0, 0.1, 0)
	root.Transparency = 1
	root.CanCollide = false
	root.CanTouch = false
	root.CanQuery = false
	root.Massless = true
	root.Anchored = true
	root.Parent = m
	m.PrimaryPart = root

	for _, p in m:GetChildren() do
		if p:IsA("BasePart") and p ~= root then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = root
			weld.Part1 = p
			weld.Parent = p
		end
	end

	applyMutation(m, mutationName)
	addRarityEffects(m, def)
	return m
end

return KaijuModel
