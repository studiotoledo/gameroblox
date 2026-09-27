-- Bases dos jogadores: dono, coletor de dinheiro, esteira, trava da porta,
-- upgrades e desbloqueio de pedestais.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)

local PlotService = {}
local S
local plots
local byPlayer: { [Player]: any } = {}

local LOCKED_COLOR = Color3.fromRGB(60, 60, 65)
local UNLOCKED_COLOR = Color3.fromRGB(95, 95, 110)

function PlotService.Init(services)
	S = services
	plots = services.Map.Plots
	for _, plot in plots do
		plot.UpgradePrompt.Triggered:Connect(function(player)
			PlotService.upgradeTreadmill(player, plot)
		end)
	end
end

function PlotService.getPlot(player: Player)
	return byPlayer[player]
end

function PlotService.getPlots()
	return plots
end

function PlotService.isLocked(plot): boolean
	return os.clock() < plot.LockedUntil
end

-- Ponto dentro da área da base (incluindo um pouco acima do chão)?
function PlotService.isInside(plot, position: Vector3): boolean
	local rel = plot.Origin:PointToObjectSpace(position)
	return math.abs(rel.X) <= Config.PlotWidth / 2
		and math.abs(rel.Z) <= Config.PlotDepth / 2
		and rel.Y > -5
		and rel.Y < 40
end

function PlotService.findFreeSlot(plot): number?
	local data = plot.Owner and S.DataService.get(plot.Owner)
	local unlocked = data and data.SlotsUnlocked or Config.StartingSlots
	for i = 1, math.min(unlocked, #plot.Slots) do
		if not plot.Slots[i].Entity then
			return i
		end
	end
	return nil
end

function PlotService.isSlotUsable(plot, index: number): boolean
	local data = plot.Owner and S.DataService.get(plot.Owner)
	local unlocked = data and data.SlotsUnlocked or Config.StartingSlots
	return index >= 1 and index <= unlocked and plot.Slots[index] ~= nil and plot.Slots[index].Entity == nil
end

---------------------------------------------------------------------------
-- Visual dos pedestais / textos
---------------------------------------------------------------------------

local function slotUnlockCost(data): number?
	local n = data.SlotsUnlocked - Config.StartingSlots + 1
	return Config.SlotUnlockCosts[n]
end

function PlotService.refreshSlots(plot)
	local data = plot.Owner and S.DataService.get(plot.Owner)
	local unlocked = data and data.SlotsUnlocked or Config.StartingSlots
	for i, slot in plot.Slots do
		local isUnlocked = i <= unlocked
		slot.Pedestal.Color = if isUnlocked then UNLOCKED_COLOR else LOCKED_COLOR
		slot.Ring.Color = if isUnlocked then plot.Color else LOCKED_COLOR
		slot.Ring.Material = if isUnlocked then Enum.Material.Neon else Enum.Material.SmoothPlastic

		local wantPrompt = data ~= nil and i == unlocked + 1 and slotUnlockCost(data) ~= nil
		if wantPrompt then
			local cost = slotUnlockCost(data)
			if not slot.UnlockPrompt then
				local pp = Instance.new("ProximityPrompt")
				pp.ActionText = "Desbloquear espaço"
				pp.HoldDuration = 0.3
				pp.RequiresLineOfSight = false
				pp.MaxActivationDistance = 10
				pp.Triggered:Connect(function(player)
					PlotService.unlockSlot(player, plot)
				end)
				pp:SetAttribute("OnlyUserId", plot.Owner.UserId)
				pp.Parent = slot.Pedestal
				slot.UnlockPrompt = pp
			end
			slot.UnlockPrompt.ObjectText = "🔒 " .. Format.money(cost)
			slot.UnlockPrompt:SetAttribute("OnlyUserId", plot.Owner.UserId)
		elseif slot.UnlockPrompt then
			slot.UnlockPrompt:Destroy()
			slot.UnlockPrompt = nil
		end
	end
end

local function refreshTreadmill(plot)
	local data = plot.Owner and S.DataService.get(plot.Owner)
	local level = data and data.TreadmillLevel or 0
	plot.TreadmillLabel.Text = string.format("⚡ ESTEIRA Nv.%d  (+%.2f/s)", level + 1, Config.treadmillRate(level))
	if not data then
		plot.UpgradePrompt.ObjectText = ""
	elseif level >= Config.Treadmill.MaxLevel then
		plot.UpgradePrompt.ObjectText = "Nível máximo!"
	else
		plot.UpgradePrompt.ObjectText =
			string.format("Nv.%d → %d  •  %s", level + 1, level + 2, Format.money(Config.treadmillCost(level)))
	end
end

local function refreshLock(plot)
	local remaining = plot.LockedUntil - os.clock()
	if remaining > 0 then
		plot.Barrier.Transparency = 0.25
		plot.LockLabel.Text = string.format("🔒 TRANCADA %ds", math.ceil(remaining))
		plot.LockButton.Color = Color3.fromRGB(80, 80, 90)
	else
		plot.Barrier.Transparency = 1
		plot.LockLabel.Text = if plot.Owner then "🔓 PISE PARA TRANCAR" else ""
		plot.LockButton.Color = Color3.fromRGB(230, 40, 50)
	end
end

local function refreshCollector(plot)
	if plot.Owner then
		plot.CollectorLabel.Text = string.format("💰 %s\nPise para coletar", Format.money(plot.Pending))
	else
		plot.CollectorLabel.Text = ""
	end
end

---------------------------------------------------------------------------
-- Dono
---------------------------------------------------------------------------

-- As bases do centro ficam em frente ao caminho das zonas, então são entregues primeiro.
local function plotsByPreference()
	local ordered = table.clone(plots)
	local middle = (#plots + 1) / 2
	table.sort(ordered, function(a, b)
		return math.abs(a.Index - middle) < math.abs(b.Index - middle)
	end)
	return ordered
end

function PlotService.assign(player: Player)
	for _, plot in plotsByPreference() do
		if not plot.Owner then
			plot.Owner = player
			plot.Pending = 0
			plot.LockedUntil = 0
			plot.Model:SetAttribute("OwnerUserId", player.UserId)
			plot.OwnerLabel.Text = "Base de " .. player.DisplayName
			plot.UpgradePrompt:SetAttribute("OnlyUserId", player.UserId)
			byPlayer[player] = plot
			player:SetAttribute("PlotIndex", plot.Index)
			PlotService.refreshSlots(plot)
			refreshTreadmill(plot)
			refreshLock(plot)
			refreshCollector(plot)
			return plot
		end
	end
	return nil
end

function PlotService.release(player: Player)
	local plot = byPlayer[player]
	if not plot then
		return
	end
	byPlayer[player] = nil
	plot.Owner = nil
	plot.Pending = 0
	plot.LockedUntil = 0
	plot.Model:SetAttribute("OwnerUserId", 0)
	plot.OwnerLabel.Text = "Base livre"
	plot.UpgradePrompt:SetAttribute("OnlyUserId", 0)
	for _, slot in plot.Slots do
		slot.Entity = nil
	end
	PlotService.refreshSlots(plot)
	refreshTreadmill(plot)
	refreshLock(plot)
	refreshCollector(plot)
end

function PlotService.refreshAll(player: Player)
	local plot = byPlayer[player]
	if plot then
		PlotService.refreshSlots(plot)
		refreshTreadmill(plot)
	end
end

---------------------------------------------------------------------------
-- Ações
---------------------------------------------------------------------------

local function isNear(player: Player, part: BasePart, range: number): boolean
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	return hrp ~= nil and (hrp.Position - part.Position).Magnitude <= range
end

function PlotService.upgradeTreadmill(player: Player, plot)
	if plot.Owner ~= player or not isNear(player, plot.UpgradePrompt.Parent :: BasePart, 16) then
		return
	end
	local data = S.DataService.get(player)
	if data.TreadmillLevel >= Config.Treadmill.MaxLevel then
		S.Notify.send(player, "Sua esteira já está no nível máximo!", "warn")
		return
	end
	local cost = Config.treadmillCost(data.TreadmillLevel)
	if not S.EconomyService.trySpend(player, cost) then
		S.Notify.send(player, "Você precisa de " .. Format.money(cost) .. " para melhorar a esteira.", "warn")
		return
	end
	data.TreadmillLevel += 1
	S.EconomyService.refresh(player)
	refreshTreadmill(plot)
	S.Notify.send(player, string.format("Esteira melhorada para o nível %d! ⚡", data.TreadmillLevel + 1), "success")
end

function PlotService.unlockSlot(player: Player, plot)
	if plot.Owner ~= player then
		return
	end
	local data = S.DataService.get(player)
	local cost = slotUnlockCost(data)
	if not cost then
		return
	end
	if not S.EconomyService.trySpend(player, cost) then
		S.Notify.send(player, "Você precisa de " .. Format.money(cost) .. " para desbloquear esse espaço.", "warn")
		return
	end
	data.SlotsUnlocked += 1
	S.EconomyService.refresh(player)
	PlotService.refreshSlots(plot)
	S.Notify.send(player, "Novo espaço desbloqueado na sua base!", "success")
end

local function isFree(player: Player): boolean
	return not S.KaijuService.isCarrying(player)
end

local function onStep(dt: number)
	for _, plot in plots do
		local owner = plot.Owner
		if not owner then
			continue
		end
		local char = owner.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hrp and hum and hum.Health > 0 then
			local rel = plot.Origin:PointToObjectSpace(hrp.Position)

			-- coletor
			local collectorRel = plot.Origin:PointToObjectSpace(plot.Collector.Position)
			if math.abs(rel.X - collectorRel.X) <= 4.5 and math.abs(rel.Z - collectorRel.Z) <= 3.5 and rel.Y < 8 then
				local amount = math.floor(plot.Pending)
				if amount >= 1 then
					plot.Pending -= amount
					S.EconomyService.addCash(owner, amount)
					S.Notify.send(owner, "+" .. Format.money(amount), "cash")
					refreshCollector(plot)
				end
			end

			-- esteira (só enquanto não carrega nada)
			local tRel = plot.TreadmillCenter:PointToObjectSpace(hrp.Position)
			if
				math.abs(tRel.X) <= plot.TreadmillSize.X / 2
				and math.abs(tRel.Z) <= plot.TreadmillSize.Z / 2
				and tRel.Y < 6
				and isFree(owner)
			then
				local data = S.DataService.get(owner)
				if data then
					S.EconomyService.addSpeed(owner, Config.treadmillRate(data.TreadmillLevel) * dt)
				end
			end

			-- botão de trancar
			local lockRel = plot.Origin:PointToObjectSpace(plot.LockButton.Position)
			if
				not PlotService.isLocked(plot)
				and Vector2.new(rel.X - lockRel.X, rel.Z - lockRel.Z).Magnitude <= 3
				and rel.Y < 8
			then
				plot.LockedUntil = os.clock() + Config.LockDuration
				S.Notify.send(
					owner,
					string.format("🔒 Base trancada por %d segundos!", Config.LockDuration),
					"success"
				)
			end
		end

		-- empurra invasores para fora enquanto estiver trancada
		if PlotService.isLocked(plot) then
			for _, other in Players:GetPlayers() do
				if other ~= owner then
					local ochar = other.Character
					local ohrp = ochar and ochar:FindFirstChild("HumanoidRootPart") :: BasePart?
					if ohrp and PlotService.isInside(plot, ohrp.Position) then
						ochar:PivotTo(plot.OutsideCFrame)
						S.Notify.send(other, "🔒 Essa base está trancada!", "warn")
					end
				end
			end
		end
	end
end

function PlotService.Start()
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc >= 0.2 then
			onStep(acc)
			acc = 0
		end
	end)
	task.spawn(function()
		while true do
			task.wait(1)
			for _, plot in plots do
				refreshLock(plot)
				refreshCollector(plot)
			end
		end
	end)
end

return PlotService
