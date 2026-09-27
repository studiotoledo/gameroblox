-- Gera o mapa inteiro por código: chão, 8 bases, zonas com ninhos e decoração.
-- As bases ficam em fila no Z = 0 com a entrada virada para +Z; as zonas vão ficando
-- mais distantes (e mais valiosas) no sentido +Z.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local MapBuilder = {}

local PLOT_FLOOR_TOP = 0.6
local PEDESTAL_TOP = 1.8

local function part(props: { [string]: any }): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	for key, value in props do
		if key ~= "Parent" then
			(p :: any)[key] = value
		end
	end
	p.Parent = props.Parent
	return p
end

local function cylinder(
	parent: Instance,
	name: string,
	height: number,
	diameter: number,
	pos: Vector3,
	color: Color3,
	material: Enum.Material?
): Part
	return part({
		Name = name,
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(height, diameter, diameter),
		CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90)),
		Color = color,
		Material = material or Enum.Material.SmoothPlastic,
		Parent = parent,
	})
end

local function billboard(
	adornee: BasePart,
	offsetY: number,
	size: UDim2,
	maxDistance: number?
): (BillboardGui, TextLabel)
	local bb = Instance.new("BillboardGui")
	bb.Name = "Label"
	bb.Size = size
	bb.StudsOffsetWorldSpace = Vector3.new(0, offsetY, 0)
	bb.LightInfluence = 0
	bb.MaxDistance = maxDistance or 120
	bb.Adornee = adornee
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.2
	label.Parent = bb
	bb.Parent = adornee
	return bb, label
end

local function prompt(parent: BasePart, actionText: string, objectText: string, hold: number?): ProximityPrompt
	local pp = Instance.new("ProximityPrompt")
	pp.ActionText = actionText
	pp.ObjectText = objectText
	pp.HoldDuration = hold or 0
	pp.RequiresLineOfSight = false
	pp.MaxActivationDistance = 10
	pp:SetAttribute("OnlyUserId", 0)
	pp.Parent = parent
	return pp
end

---------------------------------------------------------------------------
-- Bases
---------------------------------------------------------------------------

local PLOT_COLORS = {
	Color3.fromRGB(255, 95, 95),
	Color3.fromRGB(255, 170, 60),
	Color3.fromRGB(255, 225, 70),
	Color3.fromRGB(110, 220, 100),
	Color3.fromRGB(70, 200, 230),
	Color3.fromRGB(90, 130, 255),
	Color3.fromRGB(180, 110, 255),
	Color3.fromRGB(255, 120, 200),
}

local function buildPlot(index: number, parent: Instance)
	local cx = (index - (Config.MaxPlots + 1) / 2) * Config.PlotSpacing
	local origin = CFrame.new(cx, 0, 0)
	local w, d = Config.PlotWidth, Config.PlotDepth
	local color = PLOT_COLORS[(index - 1) % #PLOT_COLORS + 1]

	local model = Instance.new("Model")
	model.Name = "Plot" .. index
	model:SetAttribute("OwnerUserId", 0)
	model.Parent = parent

	local function at(x: number, y: number, z: number): CFrame
		return origin * CFrame.new(x, y, z)
	end

	part({
		Name = "Floor",
		Size = Vector3.new(w, PLOT_FLOOR_TOP, d),
		CFrame = at(0, PLOT_FLOOR_TOP / 2, 0),
		Color = Color3.fromRGB(70, 70, 80),
		Material = Enum.Material.Concrete,
		Parent = model,
	})
	-- faixa colorida da base
	part({
		Name = "Trim",
		Size = Vector3.new(w, 0.05, 2),
		CFrame = at(0, PLOT_FLOOR_TOP + 0.02, d / 2 - 1),
		Color = color,
		Material = Enum.Material.Neon,
		Parent = model,
	})

	-- paredes (fundo, laterais e frente com abertura de 16 studs)
	local wallH, wallT = 5, 1
	local wallColor = color:Lerp(Color3.new(0.2, 0.2, 0.25), 0.55)
	local function wall(size: Vector3, cf: CFrame)
		part({
			Name = "Wall",
			Size = size,
			CFrame = cf,
			Color = wallColor,
			Material = Enum.Material.Brick,
			Parent = model,
		})
	end
	local wy = PLOT_FLOOR_TOP + wallH / 2
	wall(Vector3.new(w, wallH, wallT), at(0, wy, -d / 2 + wallT / 2))
	wall(Vector3.new(wallT, wallH, d), at(-w / 2 + wallT / 2, wy, 0))
	wall(Vector3.new(wallT, wallH, d), at(w / 2 - wallT / 2, wy, 0))
	local gap = 16
	local seg = (w - gap) / 2
	wall(Vector3.new(seg, wallH, wallT), at(-(gap / 2 + seg / 2), wy, d / 2 - wallT / 2))
	wall(Vector3.new(seg, wallH, wallT), at(gap / 2 + seg / 2, wy, d / 2 - wallT / 2))

	-- extensão invisível das paredes: impede pular por cima para entrar na base
	local tallH = 60
	local ty = PLOT_FLOOR_TOP + wallH + tallH / 2
	local function tallWall(size: Vector3, cf: CFrame)
		part({ Name = "WallGuard", Size = size, CFrame = cf, Transparency = 1, CanQuery = false, Parent = model })
	end
	tallWall(Vector3.new(w, tallH, wallT), at(0, ty, -d / 2 + wallT / 2))
	tallWall(Vector3.new(wallT, tallH, d), at(-w / 2 + wallT / 2, ty, 0))
	tallWall(Vector3.new(wallT, tallH, d), at(w / 2 - wallT / 2, ty, 0))
	tallWall(Vector3.new(seg, tallH, wallT), at(-(gap / 2 + seg / 2), ty, d / 2 - wallT / 2))
	tallWall(Vector3.new(seg, tallH, wallT), at(gap / 2 + seg / 2, ty, d / 2 - wallT / 2))

	-- laser da porta (fica visível quando a base está trancada)
	local barrier = part({
		Name = "Barrier",
		Size = Vector3.new(gap, 7, 0.4),
		CFrame = at(0, PLOT_FLOOR_TOP + 3.5, d / 2 - wallT / 2),
		Color = Color3.fromRGB(255, 40, 60),
		Material = Enum.Material.ForceField,
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
		Parent = model,
	})

	-- pedestais (2 fileiras de 5)
	local slots = {}
	local xs = { -24, -12, 0, 12, 24 }
	local zs = { 6, -8 }
	for row, z in zs do
		for col, x in xs do
			local i = (row - 1) * #xs + col
			local pedestal = cylinder(
				model,
				"Pedestal" .. i,
				PEDESTAL_TOP - PLOT_FLOOR_TOP,
				7,
				(at(x, (PEDESTAL_TOP + PLOT_FLOOR_TOP) / 2, z)).Position,
				Color3.fromRGB(95, 95, 110)
			)
			local ring = cylinder(
				model,
				"Ring" .. i,
				0.3,
				7.6,
				(at(x, PLOT_FLOOR_TOP + 0.15, z)).Position,
				color,
				Enum.Material.Neon
			)
			slots[i] = {
				Index = i,
				Pedestal = pedestal,
				Ring = ring,
				CFrame = at(x, PEDESTAL_TOP, z) * CFrame.Angles(0, math.pi, 0), -- kaiju olhando pra entrada
				Entity = nil,
			}
		end
	end

	-- esteira: o jogador ativa pelo prompt e o boneco corre sozinho virado para -X
	local treadmillCenter = at(-24, PLOT_FLOOR_TOP, -21)
	part({
		Name = "TreadmillBase",
		Size = Vector3.new(12, 0.8, 6),
		CFrame = treadmillCenter * CFrame.new(0, 0.4, 0),
		Color = Color3.fromRGB(40, 40, 45),
		Material = Enum.Material.Metal,
		Parent = model,
	})
	local belt = part({
		Name = "TreadmillBelt",
		Size = Vector3.new(11, 0.2, 4.6),
		CFrame = treadmillCenter * CFrame.new(0.5, 0.9, 0),
		Color = Color3.fromRGB(25, 25, 25),
		Material = Enum.Material.Fabric,
		Parent = model,
	})
	local trainPrompt = prompt(belt, "Correr na esteira", "⚡ Ganhe velocidade", 0)
	trainPrompt.MaxActivationDistance = 12
	for _, sz in { -1, 1 } do
		part({
			Name = "TreadmillRail",
			Size = Vector3.new(12, 3, 0.4),
			CFrame = treadmillCenter * CFrame.new(0, 2.2, sz * 3),
			Color = color,
			Material = Enum.Material.Metal,
			Transparency = 0.3,
			Parent = model,
		})
	end
	local treadmillSign = part({
		Name = "TreadmillFront",
		Size = Vector3.new(0.6, 4, 6),
		CFrame = treadmillCenter * CFrame.new(-6.3, 2, 0),
		Color = Color3.fromRGB(40, 40, 45),
		Material = Enum.Material.Metal,
		Parent = model,
	})
	local _, treadmillLabel = billboard(treadmillSign, 4, UDim2.fromOffset(200, 50))
	treadmillLabel.Text = "⚡ ESTEIRA"

	-- máquina de upgrade da esteira
	local upgrader = part({
		Name = "Upgrader",
		Size = Vector3.new(3, 5, 3),
		CFrame = at(-13, PLOT_FLOOR_TOP + 2.5, -24),
		Color = Color3.fromRGB(255, 200, 40),
		Material = Enum.Material.SmoothPlastic,
		Parent = model,
	})
	part({
		Name = "UpgraderScreen",
		Size = Vector3.new(2.2, 1.6, 0.1),
		CFrame = at(-13, PLOT_FLOOR_TOP + 3.5, -22.45),
		Color = Color3.fromRGB(40, 255, 160),
		Material = Enum.Material.Neon,
		Parent = model,
	})
	local upgradePrompt = prompt(upgrader, "Melhorar esteira", "", 0.3)

	-- coletor de dinheiro
	local collector = part({
		Name = "Collector",
		Size = Vector3.new(8, 0.3, 6),
		CFrame = at(4, PLOT_FLOOR_TOP + 0.15, -22),
		Color = Color3.fromRGB(60, 230, 90),
		Material = Enum.Material.Neon,
		Parent = model,
	})
	local _, collectorLabel = billboard(collector, 4, UDim2.fromOffset(240, 60))
	collectorLabel.TextColor3 = Color3.fromRGB(120, 255, 140)

	-- botão de trancar
	local lockButton = cylinder(
		model,
		"LockButton",
		0.6,
		5,
		(at(18, PLOT_FLOOR_TOP + 0.3, 20)).Position,
		Color3.fromRGB(230, 40, 50),
		Enum.Material.Neon
	)
	local _, lockLabel = billboard(lockButton, 3.5, UDim2.fromOffset(200, 50))

	-- placa com o nome do dono
	local signPost = part({
		Name = "SignAnchor",
		Size = Vector3.new(1, 1, 1),
		CFrame = at(0, 12, d / 2),
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
		Parent = model,
	})
	-- foto do dono + nome + renda por segundo
	local ownerGui = Instance.new("BillboardGui")
	ownerGui.Name = "OwnerSign"
	ownerGui.Size = UDim2.fromOffset(260, 150)
	ownerGui.LightInfluence = 0
	ownerGui.MaxDistance = 400
	ownerGui.Adornee = signPost
	local avatar = Instance.new("ImageLabel")
	avatar.Name = "Avatar"
	avatar.AnchorPoint = Vector2.new(0.5, 0)
	avatar.Position = UDim2.fromScale(0.5, 0)
	avatar.Size = UDim2.fromOffset(72, 72)
	avatar.BackgroundColor3 = color
	avatar.Image = ""
	avatar.Visible = false
	local avatarCorner = Instance.new("UICorner")
	avatarCorner.CornerRadius = UDim.new(1, 0)
	avatarCorner.Parent = avatar
	local avatarStroke = Instance.new("UIStroke")
	avatarStroke.Thickness = 3
	avatarStroke.Color = Color3.new(1, 1, 1)
	avatarStroke.Parent = avatar
	avatar.Parent = ownerGui
	local ownerLabel = Instance.new("TextLabel")
	ownerLabel.Position = UDim2.fromOffset(0, 76)
	ownerLabel.Size = UDim2.new(1, 0, 0, 36)
	ownerLabel.BackgroundTransparency = 1
	ownerLabel.Font = Enum.Font.FredokaOne
	ownerLabel.TextScaled = true
	ownerLabel.TextColor3 = color
	ownerLabel.TextStrokeTransparency = 0
	ownerLabel.Text = "Base livre"
	ownerLabel.Parent = ownerGui
	local ownerIncome = Instance.new("TextLabel")
	ownerIncome.Position = UDim2.fromOffset(0, 112)
	ownerIncome.Size = UDim2.new(1, 0, 0, 30)
	ownerIncome.BackgroundTransparency = 1
	ownerIncome.Font = Enum.Font.FredokaOne
	ownerIncome.TextScaled = true
	ownerIncome.TextColor3 = Color3.fromRGB(120, 255, 140)
	ownerIncome.TextStrokeTransparency = 0
	ownerIncome.Text = ""
	ownerIncome.Parent = ownerGui
	ownerGui.Parent = signPost

	return {
		Index = index,
		Color = color,
		Model = model,
		Origin = origin,
		Slots = slots,
		SpawnCFrame = at(-4, PLOT_FLOOR_TOP + 3, -15) * CFrame.Angles(0, math.pi, 0),
		OutsideCFrame = at(0, PLOT_FLOOR_TOP + 3, d / 2 + 8),
		Barrier = barrier,
		Belt = belt,
		TreadmillCenter = treadmillCenter,
		TrainCFrame = treadmillCenter * CFrame.new(0.5, 4.7, 0) * CFrame.Angles(0, math.pi / 2, 0),
		TrainPrompt = trainPrompt,
		TreadmillLabel = treadmillLabel,
		UpgradePrompt = upgradePrompt,
		Collector = collector,
		CollectorLabel = collectorLabel,
		LockButton = lockButton,
		LockLabel = lockLabel,
		OwnerLabel = ownerLabel,
		OwnerAvatar = avatar,
		OwnerIncome = ownerIncome,
		Owner = nil,
		LockedUntil = 0,
		Pending = 0,
	}
end

---------------------------------------------------------------------------
-- Zonas
---------------------------------------------------------------------------

local Decorators = {}

function Decorators.palm(parent: Instance, pos: Vector3, rng: Random)
	local h = rng:NextNumber(9, 14)
	local lean = rng:NextNumber(-0.2, 0.2)
	local base = CFrame.new(pos) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), lean)
	part({
		Name = "Trunk",
		Size = Vector3.new(1.2, h, 1.2),
		CFrame = base * CFrame.new(0, h / 2, 0),
		Color = Color3.fromRGB(150, 110, 70),
		Material = Enum.Material.Wood,
		Parent = parent,
	})
	for i = 0, 4 do
		local a = i / 5 * math.pi * 2
		part({
			Name = "Leaf",
			Size = Vector3.new(7, 0.4, 1.8),
			CFrame = base * CFrame.new(0, h, 0) * CFrame.Angles(0, a, 0) * CFrame.new(3, -0.6, 0) * CFrame.Angles(
				0,
				0,
				-0.35
			),
			Color = Color3.fromRGB(60, 170, 70),
			Material = Enum.Material.Grass,
			CanCollide = false,
			Parent = parent,
		})
	end
end

function Decorators.tree(parent: Instance, pos: Vector3, rng: Random)
	local h = rng:NextNumber(8, 14)
	part({
		Name = "Trunk",
		Size = Vector3.new(2, h, 2),
		CFrame = CFrame.new(pos + Vector3.new(0, h / 2, 0)),
		Color = Color3.fromRGB(110, 75, 45),
		Material = Enum.Material.Wood,
		Parent = parent,
	})
	local green = Color3.fromRGB(50, rng:NextInteger(120, 160), 55)
	part({
		Name = "Leaves",
		Size = Vector3.new(10, 6, 10),
		CFrame = CFrame.new(pos + Vector3.new(0, h + 2, 0)) * CFrame.Angles(0, rng:NextNumber(0, 1.5), 0),
		Color = green,
		Material = Enum.Material.Grass,
		Parent = parent,
	})
	part({
		Name = "Leaves",
		Size = Vector3.new(6, 4, 6),
		CFrame = CFrame.new(pos + Vector3.new(0, h + 6, 0)) * CFrame.Angles(0, rng:NextNumber(0, 1.5), 0),
		Color = green:Lerp(Color3.new(1, 1, 1), 0.1),
		Material = Enum.Material.Grass,
		Parent = parent,
	})
end

function Decorators.rock(parent: Instance, pos: Vector3, rng: Random, color: Color3?, material: Enum.Material?)
	local s = rng:NextNumber(3, 8)
	part({
		Name = "Rock",
		Size = Vector3.new(s, s * rng:NextNumber(0.5, 0.9), s * rng:NextNumber(0.7, 1.2)),
		CFrame = CFrame.new(pos + Vector3.new(0, s * 0.3, 0))
			* CFrame.Angles(rng:NextNumber(-0.3, 0.3), rng:NextNumber(0, 3), rng:NextNumber(-0.3, 0.3)),
		Color = color or Color3.fromRGB(120, 120, 125),
		Material = material or Enum.Material.Slate,
		Parent = parent,
	})
end

function Decorators.lava(parent: Instance, pos: Vector3, rng: Random)
	if rng:NextNumber() < 0.5 then
		cylinder(
			parent,
			"LavaPool",
			0.3,
			rng:NextNumber(6, 12),
			pos + Vector3.new(0, 0.2, 0),
			Color3.fromRGB(255, 100, 20),
			Enum.Material.Neon
		)
	else
		Decorators.rock(parent, pos, rng, Color3.fromRGB(45, 40, 40), Enum.Material.Basalt)
	end
end

function Decorators.ice(parent: Instance, pos: Vector3, rng: Random)
	local h = rng:NextNumber(5, 14)
	part({
		Name = "IceSpike",
		Size = Vector3.new(2.5, h, 2.5),
		CFrame = CFrame.new(pos + Vector3.new(0, h / 2 - 0.5, 0))
			* CFrame.Angles(rng:NextNumber(-0.25, 0.25), rng:NextNumber(0, 3), rng:NextNumber(-0.25, 0.25)),
		Color = Color3.fromRGB(170, 220, 255),
		Material = Enum.Material.Ice,
		Transparency = 0.2,
		Parent = parent,
	})
end

function Decorators.crystal(parent: Instance, pos: Vector3, rng: Random)
	local colors = { Color3.fromRGB(180, 80, 255), Color3.fromRGB(60, 220, 255), Color3.fromRGB(255, 80, 200) }
	local s = rng:NextNumber(2, 4)
	local c = part({
		Name = "Crystal",
		Size = Vector3.new(s, s * 2.5, s),
		CFrame = CFrame.new(pos + Vector3.new(0, rng:NextNumber(4, 10), 0))
			* CFrame.Angles(rng:NextNumber(0, 1), rng:NextNumber(0, 3), rng:NextNumber(0, 1)),
		Color = colors[rng:NextInteger(1, #colors)],
		Material = Enum.Material.Neon,
		CanCollide = false,
		Parent = parent,
	})
	local light = Instance.new("PointLight")
	light.Color = c.Color
	light.Range = 14
	light.Parent = c
end

local ZONE_DECOR = {
	function(parent, pos, rng)
		if rng:NextNumber() < 0.7 then
			Decorators.palm(parent, pos, rng)
		else
			Decorators.rock(parent, pos, rng, Color3.fromRGB(200, 190, 170), Enum.Material.Sandstone)
		end
	end,
	function(parent, pos, rng)
		if rng:NextNumber() < 0.8 then
			Decorators.tree(parent, pos, rng)
		else
			Decorators.rock(parent, pos, rng)
		end
	end,
	Decorators.lava,
	Decorators.ice,
	Decorators.crystal,
}

local function buildNest(parent: Instance, pos: Vector3, rng: Random)
	local nest = Instance.new("Model")
	nest.Name = "Nest"
	nest.Parent = parent
	cylinder(nest, "Straw", 0.4, 7, pos + Vector3.new(0, 0.2, 0), Color3.fromRGB(200, 170, 90), Enum.Material.Fabric)
	for i = 0, 9 do
		local a = i / 10 * math.pi * 2 + rng:NextNumber(-0.1, 0.1)
		part({
			Name = "Twig",
			Size = Vector3.new(0.6, 0.8, 3),
			CFrame = CFrame.new(pos + Vector3.new(math.cos(a) * 3.4, 0.5, math.sin(a) * 3.4))
				* CFrame.Angles(0, -a, 0.3),
			Color = Color3.fromRGB(120, 80, 45),
			Material = Enum.Material.Wood,
			CanCollide = false,
			Parent = nest,
		})
	end
	return nest
end

local function buildZone(index: number, zone, parent: Instance)
	local folder = Instance.new("Folder")
	folder.Name = "Zone" .. index
	folder.Parent = parent
	local rng = Random.new(index * 7919)
	local half = Config.MapHalfWidth
	local depth = zone.ZEnd - zone.ZStart
	local midZ = (zone.ZStart + zone.ZEnd) / 2

	part({
		Name = "Ground",
		Size = Vector3.new(half * 2, 0.4, depth),
		CFrame = CFrame.new(0, 0, midZ),
		Color = zone.Color,
		Material = zone.Material,
		Parent = folder,
	})

	-- portal de entrada com o nome da zona
	local gateColor = zone.Color:Lerp(Color3.new(0, 0, 0), 0.3)
	for _, sx in { -1, 1 } do
		part({
			Name = "GatePillar",
			Size = Vector3.new(4, 22, 4),
			CFrame = CFrame.new(sx * 34, 11, zone.ZStart),
			Color = gateColor,
			Material = Enum.Material.Slate,
			Parent = folder,
		})
	end
	local beam = part({
		Name = "GateBeam",
		Size = Vector3.new(72, 6, 4),
		CFrame = CFrame.new(0, 24, zone.ZStart),
		Color = gateColor,
		Material = Enum.Material.Slate,
		Parent = folder,
	})
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
		local gui = Instance.new("SurfaceGui")
		gui.Face = face
		gui.LightInfluence = 0
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 20
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.FredokaOne
		label.TextScaled = true
		label.TextColor3 = Color3.new(1, 1, 1)
		label.TextStrokeTransparency = 0
		local requirement = if zone.RequiredSpeed > 0
			then string.format("⚡ Precisa de velocidade %d", zone.RequiredSpeed)
			else "Entrada livre"
		label.Text = string.format("ZONA %d • %s\n%s", index, string.upper(zone.Name), requirement)
		label.Parent = gui
		gui.Parent = beam
	end

	-- cortina de energia: só passa quem tem a velocidade mínima (ZoneService barra os outros)
	if zone.RequiredSpeed > 0 then
		part({
			Name = "SpeedGate",
			Size = Vector3.new(half * 2, 30, 1),
			CFrame = CFrame.new(0, 15, zone.ZStart),
			Color = Color3.fromRGB(80, 200, 255),
			Material = Enum.Material.ForceField,
			Transparency = 0.2,
			CanCollide = false,
			CanQuery = false,
			CastShadow = false,
			Parent = folder,
		})
	end

	-- ninhos, espalhados com uma distância mínima entre eles
	local nests = {}
	local tries = 0
	while #nests < zone.Nests and tries < 500 do
		tries += 1
		local pos =
			Vector3.new(rng:NextNumber(-half + 30, half - 30), 0.2, rng:NextNumber(zone.ZStart + 20, zone.ZEnd - 20))
		local ok = math.abs(pos.X) > 8 or math.abs(pos.Z - zone.ZStart) > 30
		for _, other in nests do
			if (other.Position - pos).Magnitude < 60 then
				ok = false
				break
			end
		end
		if ok then
			local model = buildNest(folder, pos, rng)
			table.insert(nests, { Position = pos + Vector3.new(0, 0.4, 0), Model = model, Zone = nil, Current = nil })
		end
	end

	-- decoração longe dos ninhos e do caminho central
	local decorate = ZONE_DECOR[index] or Decorators.rock
	for _ = 1, math.floor(26 * depth / 150) do
		local pos =
			Vector3.new(rng:NextNumber(-half + 5, half - 5), 0.2, rng:NextNumber(zone.ZStart + 6, zone.ZEnd - 6))
		local clear = math.abs(pos.X) > 14
		for _, nest in nests do
			if (nest.Position - pos).Magnitude < 16 then
				clear = false
				break
			end
		end
		if clear then
			decorate(folder, pos, rng)
		end
	end

	-- vulcão ao fundo da zona 3
	if index == 3 then
		for i, s in { 90, 70, 50, 30 } do
			cylinder(
				folder,
				"Volcano",
				14,
				s,
				Vector3.new(220, 7 + (i - 1) * 14, zone.ZEnd - 50),
				Color3.fromRGB(70, 55, 50),
				Enum.Material.Basalt
			)
		end
		cylinder(
			folder,
			"Crater",
			1,
			24,
			Vector3.new(220, 56.5, zone.ZEnd - 50),
			Color3.fromRGB(255, 110, 20),
			Enum.Material.Neon
		)
	end

	return {
		Index = index,
		Config = zone,
		Folder = folder,
		Nests = nests,
		MinX = -half,
		MaxX = half,
		MinZ = zone.ZStart,
		MaxZ = zone.ZEnd,
	}
end

---------------------------------------------------------------------------

local function setupLighting()
	Lighting.ClockTime = 14.5
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
	atmosphere.Density = 0.28
	atmosphere.Haze = 1.2
	atmosphere.Color = Color3.fromRGB(200, 215, 255)
	atmosphere.Decay = Color3.fromRGB(120, 130, 170)
	atmosphere.Parent = Lighting
	local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect") or Instance.new("ColorCorrectionEffect")
	cc.Saturation = 0.15
	cc.Contrast = 0.05
	cc.Parent = Lighting
	if not Lighting:FindFirstChildOfClass("Sky") then
		Instance.new("Sky").Parent = Lighting
	end
end

function MapBuilder.build()
	local old = workspace:FindFirstChild("Map")
	if old then
		old:Destroy()
	end
	local baseplate = workspace:FindFirstChild("Baseplate")
	if baseplate then
		baseplate:Destroy()
	end

	local map = Instance.new("Folder")
	map.Name = "Map"
	map.Parent = workspace

	local half = Config.MapHalfWidth
	local lastZone = Config.Zones[#Config.Zones]
	local minZ, maxZ = -60, lastZone.ZEnd + 10
	-- O Roblox limita cada peça a 2048 studs por eixo; peças maiores são encolhidas
	-- (foi isso que fez o chão "sumir"). Por isso chão e paredes são feitos em faixas.
	local STRIP = 500
	local wallH = 60
	local z0 = minZ
	while z0 < maxZ do
		local z1 = math.min(z0 + STRIP, maxZ)
		local mid = (z0 + z1) / 2
		part({
			Name = "Ground",
			Size = Vector3.new(half * 2, 4, z1 - z0),
			CFrame = CFrame.new(0, -2, mid),
			Color = Color3.fromRGB(95, 100, 110),
			Material = Enum.Material.Asphalt,
			Parent = map,
		})
		-- paredes invisíveis nas bordas
		for _, sx in { -1, 1 } do
			part({
				Name = "Boundary",
				Size = Vector3.new(2, wallH, z1 - z0),
				CFrame = CFrame.new(sx * (half + 1), wallH / 2, mid),
				Transparency = 1,
				Parent = map,
			})
		end
		z0 = z1
	end
	for _, z in { minZ - 1, maxZ + 1 } do
		part({
			Name = "Boundary",
			Size = Vector3.new(half * 2, wallH, 2),
			CFrame = CFrame.new(0, wallH / 2, z),
			Transparency = 1,
			Parent = map,
		})
	end

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(10, 1, 10)
	spawn.CFrame = CFrame.new(0, 0.5, 60)
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Duration = 0
	spawn.Parent = map

	local plotsFolder = Instance.new("Folder")
	plotsFolder.Name = "Plots"
	plotsFolder.Parent = map
	local plots = {}
	for i = 1, Config.MaxPlots do
		plots[i] = buildPlot(i, plotsFolder)
	end

	local zonesFolder = Instance.new("Folder")
	zonesFolder.Name = "Zones"
	zonesFolder.Parent = map
	local zones = {}
	for i, zone in Config.Zones do
		zones[i] = buildZone(i, zone, zonesFolder)
		for _, nest in zones[i].Nests do
			nest.Zone = zones[i]
		end
	end

	local kaijus = Instance.new("Folder")
	kaijus.Name = "Kaijus"
	kaijus.Parent = workspace

	setupLighting()

	return { Plots = plots, Zones = zones, KaijuFolder = kaijus }
end

return MapBuilder
