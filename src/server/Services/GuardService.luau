-- Uma "Mãe Kaiju" gigante patrulha cada zona e persegue quem rouba filhotes dela.
-- Quem for mais rápido que o guardião escapa; quem for pego perde o filhote.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local KaijuData = require(ReplicatedStorage.Shared.KaijuData)
local KaijuModel = require(ReplicatedStorage.Shared.KaijuModel)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local GuardService = {}
local S
local guards = {}
local knockback = Remotes.get("Knockback")

local function buildGuard(zone)
	local def = KaijuData.Guards[zone.Index] or KaijuData.Guards[1]
	local model = KaijuModel.build(def, "Normal")
	model.Name = def.Name
	model:ScaleTo(Config.GuardScale)

	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(260, 50)
	bb.StudsOffsetWorldSpace = Vector3.new(0, model:GetExtentsSize().Y + 2, 0)
	bb.LightInfluence = 0
	bb.MaxDistance = 200
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(255, 80, 80)
	label.TextStrokeTransparency = 0
	label.Text = string.format("👑 %s  ⚡%d", def.Name, zone.Config.GuardSpeed)
	label.Parent = bb
	bb.Parent = model.PrimaryPart

	local home = zone.Nests[1] and zone.Nests[1].Position or Vector3.new(0, 0.2, (zone.MinZ + zone.MaxZ) / 2)
	local guard = {
		Zone = zone,
		Model = model,
		Position = Vector3.new(home.X + 10, 0.2, home.Z),
		Goal = nil,
		Speed = zone.Config.GuardSpeed,
		Reach = 5 + Config.GuardScale * 1.2,
		Bob = math.random() * 10,
	}
	model:PivotTo(CFrame.new(guard.Position))
	model.Parent = zone.Folder
	return guard
end

local function findTarget(guard)
	local best, bestDist = nil, Config.GuardAggroRange
	for player, e in S.KaijuService.getCarriers() do
		if e.OriginZone == guard.Zone.Index then
			local char = player.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if hrp then
				local p = hrp.Position
				local inZone = p.Z >= guard.Zone.MinZ - 15 and p.Z <= guard.Zone.MaxZ + 15
				local dist = (Vector3.new(p.X, 0, p.Z) - Vector3.new(guard.Position.X, 0, guard.Position.Z)).Magnitude
				if inZone and dist < bestDist then
					best, bestDist = player, dist
				end
			end
		end
	end
	return best
end

local function pickWanderGoal(guard)
	local nests = guard.Zone.Nests
	local nest = nests[math.random(1, math.max(1, #nests))]
	local base = if nest then nest.Position else guard.Position
	return Vector3.new(base.X + math.random(-25, 25), 0.2, base.Z + math.random(-25, 25))
end

local function step(guard, dt: number)
	local zone = guard.Zone
	local target = findTarget(guard)
	local goal, speed
	if target then
		goal = (target.Character :: Model):GetPivot().Position
		speed = guard.Speed
	else
		if not guard.Goal or (guard.Goal - guard.Position).Magnitude < 3 then
			guard.Goal = pickWanderGoal(guard)
		end
		goal = guard.Goal
		speed = guard.Speed * 0.35
	end

	local flat = Vector3.new(goal.X - guard.Position.X, 0, goal.Z - guard.Position.Z)
	local dist = flat.Magnitude
	local dir = if dist > 0.01 then flat.Unit else Vector3.new(0, 0, -1)
	local move = math.min(dist, speed * dt)
	local pos = guard.Position + dir * move
	pos = Vector3.new(
		math.clamp(pos.X, zone.MinX + 10, zone.MaxX - 10),
		0.2,
		math.clamp(pos.Z, zone.MinZ + 5, zone.MaxZ - 5)
	)
	guard.Position = pos

	guard.Bob += dt * (if target then 12 else 5)
	local bob = math.abs(math.sin(guard.Bob)) * (if target then 1.2 else 0.4)
	guard.Model:PivotTo(CFrame.lookAt(pos + Vector3.new(0, bob, 0), pos + Vector3.new(0, bob, 0) + dir))

	if target and dist <= guard.Reach then
		local char = target.Character
		S.KaijuService.drop(target, "guard")
		S.Notify.send(target, "A Mãe Kaiju pegou o filhote de volta! Treine mais velocidade na esteira. ⚡", "warn")
		if char then
			knockback:FireClient(target, dir * 70 + Vector3.new(0, 45, 0))
		end
	end
end

function GuardService.Init(services)
	S = services
end

function GuardService.Start()
	for _, zone in S.Map.Zones do
		table.insert(guards, buildGuard(zone))
	end
	RunService.Heartbeat:Connect(function(dt)
		if #Players:GetPlayers() == 0 then
			return
		end
		for _, guard in guards do
			step(guard, dt)
		end
	end)
end

return GuardService
