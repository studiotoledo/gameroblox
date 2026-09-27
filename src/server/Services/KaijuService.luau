-- Coração do jogo: cada kaiju é uma "entidade" controlada pelo servidor.
-- Estados: Nest (no ninho), Slot (numa base), Carried (na cabeça de alguém), Dropped (no chão).

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local KaijuData = require(ReplicatedStorage.Shared.KaijuData)
local KaijuModel = require(ReplicatedStorage.Shared.KaijuModel)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local KaijuService = {}
local S
local folder: Folder

local entities: { [number]: any } = {}
local carrying: { [Player]: any } = {}
local lastFullWarning: { [Player]: number } = {}
local lastInventoryWarning: { [Player]: number } = {}
local nextUid = 0

---------------------------------------------------------------------------
-- Números
---------------------------------------------------------------------------

function KaijuService.income(e): number
	local def = KaijuData.ById[e.Id]
	local mut = Config.MutationsByName[e.Mutation] or Config.MutationsByName.Normal
	return def.Income * Config.Stages[e.Stage].IncomeMult * mut.Mult
end

local function growTime(e): number?
	local stage = Config.Stages[e.Stage]
	if not stage.GrowTime then
		return nil
	end
	local def = KaijuData.ById[e.Id]
	return stage.GrowTime * Config.Rarities[def.Rarity].GrowFactor
end

local function sellValue(e): number
	return math.floor(KaijuService.income(e) * Config.SellSeconds)
end

local function displayName(e): string
	local name = KaijuData.ById[e.Id].Name
	if e.Mutation ~= "Normal" then
		return name .. " " .. e.Mutation
	end
	return name
end

---------------------------------------------------------------------------
-- Visual (modelo + placa)
---------------------------------------------------------------------------

local function newLabel(parent: Instance, y: number, h: number, size: number?): TextLabel
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Position = UDim2.fromScale(0, y)
	label.Size = UDim2.fromScale(1, h)
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.1
	label.Parent = parent
	if size then
		local constraint = Instance.new("UITextSizeConstraint")
		constraint.MaxTextSize = size
		constraint.Parent = label
	end
	return label
end

local function buildBillboard(e)
	local bb = Instance.new("BillboardGui")
	bb.Name = "Info"
	bb.Size = UDim2.fromOffset(220, 92)
	bb.LightInfluence = 0
	bb.MaxDistance = 80
	bb.Adornee = e.Model.PrimaryPart
	local def = KaijuData.ById[e.Id]
	local rarity = Config.Rarities[def.Rarity]

	local mutation = newLabel(bb, 0, 0.2, 16)
	local name = newLabel(bb, 0.2, 0.28, 24)
	name.Text = def.Name
	local sub = newLabel(bb, 0.48, 0.2, 16)
	sub.TextColor3 = rarity.Color
	local income = newLabel(bb, 0.68, 0.18, 16)
	income.TextColor3 = Color3.fromRGB(120, 255, 140)
	local grow = newLabel(bb, 0.86, 0.14, 13)
	grow.TextColor3 = Color3.fromRGB(220, 220, 220)

	local mut = Config.MutationsByName[e.Mutation]
	if mut and mut.Name ~= "Normal" then
		mutation.Text = "✦ " .. string.upper(mut.Name) .. " ✦"
		mutation.TextColor3 = mut.Label or Color3.new(1, 1, 1)
	end
	if def.Rarity == "Secreto" then
		local gradient = Instance.new("UIGradient")
		gradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80, 80)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 90)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 200, 255)),
		})
		gradient.Parent = sub
	end

	bb.Parent = e.Model.PrimaryPart
	e.Gui = { Billboard = bb, Sub = sub, Income = income, Grow = grow }
end

local function refreshBillboard(e)
	local gui = e.Gui
	if not gui then
		return
	end
	local def = KaijuData.ById[e.Id]
	gui.Sub.Text = def.Rarity .. " • " .. Config.Stages[e.Stage].Name
	gui.Income.Text = Format.money(KaijuService.income(e)) .. "/s"
	local gt = growTime(e)
	if not gt then
		gui.Grow.Text = "Tamanho máximo!"
	elseif e.State == "Slot" then
		gui.Grow.Text = string.format("Vira %s em %s", Config.Stages[e.Stage + 1].Name, Format.time(gt - e.Growth))
	else
		gui.Grow.Text = "Cresce só na base"
	end
	-- dados lidos pelo painel "Vender" do cliente
	local model = e.Model
	model:SetAttribute("State", e.State)
	model:SetAttribute("OwnerUserId", e.OwnerUserId or 0)
	model:SetAttribute("KaijuName", displayName(e))
	model:SetAttribute("Rarity", def.Rarity)
	model:SetAttribute("StageName", Config.Stages[e.Stage].Name)
	model:SetAttribute("Income", KaijuService.income(e))
	model:SetAttribute("SellValue", math.floor(KaijuService.income(e) * Config.SellSeconds))
end

local function refreshBillboardOffset(e)
	local height = e.Model:GetExtentsSize().Y
	e.Gui.Billboard.StudsOffsetWorldSpace = Vector3.new(0, height + 1.5, 0)
end

---------------------------------------------------------------------------
-- Prompts
---------------------------------------------------------------------------

local function clearPrompts(e)
	for _, p in e.Prompts do
		p:Destroy()
	end
	table.clear(e.Prompts)
end

local function addPrompt(
	e,
	action: string,
	actionText: string,
	objectText: string,
	hold: number,
	attrs: { [string]: any },
	key: Enum.KeyCode?
)
	local p = Instance.new("ProximityPrompt")
	p.ActionText = actionText
	p.ObjectText = objectText
	p.HoldDuration = hold
	p.RequiresLineOfSight = false
	p.MaxActivationDistance = 7 + 3 * Config.Stages[e.Stage].Scale
	if key then
		p.KeyboardKeyCode = key
		p.GamepadKeyCode = Enum.KeyCode.ButtonY
	end
	for k, v in attrs do
		p:SetAttribute(k, v)
	end
	p.Triggered:Connect(function(player)
		KaijuService.onPrompt(player, e, action)
	end)
	p.Parent = e.Model.PrimaryPart
	table.insert(e.Prompts, p)
end

local function refreshPrompts(e)
	clearPrompts(e)
	local name = displayName(e)
	if e.State == "Nest" then
		addPrompt(e, "take", "Roubar", name, 0.3, { Kind = "Steal" })
	elseif e.State == "Dropped" then
		addPrompt(e, "take", "Pegar", name, 0.2, { Kind = "Steal" })
	elseif e.State == "Slot" then
		addPrompt(e, "take", "Roubar", name, 1.2, { Kind = "Steal", ExceptUserId = e.OwnerUserId })
		addPrompt(
			e,
			"sell",
			"Vender",
			name .. " • " .. Format.money(sellValue(e)),
			1,
			{ OnlyUserId = e.OwnerUserId },
			Enum.KeyCode.F
		)
	end
end

---------------------------------------------------------------------------
-- Ciclo de vida
---------------------------------------------------------------------------

local function createEntity(id: string, stage: number, mutation: string?, growth: number?)
	local def = KaijuData.ById[id]
	nextUid += 1
	local e = {
		Uid = nextUid,
		Id = id,
		Stage = math.clamp(stage, 1, #Config.Stages),
		Growth = growth or 0,
		Mutation = if mutation and Config.MutationsByName[mutation] then mutation else "Normal",
		State = "None",
		Prompts = {},
	}
	local model = KaijuModel.build(def, e.Mutation)
	model:SetAttribute("KaijuUid", e.Uid)
	if Config.Stages[e.Stage].Scale ~= 1 then
		model:ScaleTo(Config.Stages[e.Stage].Scale)
	end
	e.Model = model
	buildBillboard(e)
	entities[e.Uid] = e
	return e
end

local function detach(e)
	local root = e.Model.PrimaryPart
	root.Anchored = true
	if e.Weld then
		e.Weld:Destroy()
		e.Weld = nil
	end
end

-- Item na hotbar mostrando o kaiju que o jogador está carregando.
local CARRY_TOOL_ATTRIBUTE = "CarryTool"

local function removeCarryTool(player: Player)
	for _, container in { player:FindFirstChildOfClass("Backpack"), player.Character } do
		if container then
			for _, child in container:GetChildren() do
				if child:IsA("Tool") and child:GetAttribute(CARRY_TOOL_ATTRIBUTE) then
					child:Destroy()
				end
			end
		end
	end
end

local function giveCarryTool(player: Player, e)
	removeCarryTool(player)
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack then
		return
	end
	local tool = Instance.new("Tool")
	tool.Name = "🦖 " .. displayName(e)
	tool.ToolTip = Config.Stages[e.Stage].Name .. " • leve para a sua base"
	tool.RequiresHandle = false
	tool.CanBeDropped = false
	tool:SetAttribute(CARRY_TOOL_ATTRIBUTE, true)
	tool.Activated:Connect(function()
		KaijuService.dropByPlayer(player)
	end)
	tool.Parent = backpack
end

local function clearCarrier(e)
	local player = e.Carrier
	if player then
		e.Carrier = nil
		if carrying[player] == e then
			carrying[player] = nil
			player:SetAttribute("Carrying", "")
			removeCarryTool(player)
			S.CharacterService.refreshSpeed(player)
		end
	end
end

function KaijuService.removeEntity(e)
	if entities[e.Uid] ~= e then
		return
	end
	entities[e.Uid] = nil
	clearCarrier(e)
	if e.Plot and e.Plot.Slots[e.SlotIndex] and e.Plot.Slots[e.SlotIndex].Entity == e then
		e.Plot.Slots[e.SlotIndex].Entity = nil
	end
	if e.HomePlot and e.HomePlot.Slots[e.HomeSlot].Entity == e then
		e.HomePlot.Slots[e.HomeSlot].Entity = nil
	end
	if e.Nest and e.Nest.Current == e then
		e.Nest.Current = nil
	end
	e.State = "Removed"
	e.Model:Destroy()
end

-- Índice: registra que o jogador já teve esse kaiju
function KaijuService.markDiscovered(player: Player, id: string, mutation: string?)
	local data = S.DataService.get(player)
	if not data then
		return
	end
	data.Discovered[id] = true
	if mutation and mutation ~= "Normal" then
		data.DiscoveredMutations[mutation] = data.DiscoveredMutations[mutation] or {}
		data.DiscoveredMutations[mutation][id] = true
	end
	KaijuService.publishDiscovered(player)
end

-- Envia ao cliente o que já foi descoberto: "id,id" e "Mutação:id,id;Mutação:id"
function KaijuService.publishDiscovered(player: Player)
	local data = S.DataService.get(player)
	if not data then
		return
	end
	local ids = {}
	for known in data.Discovered do
		table.insert(ids, known)
	end
	player:SetAttribute("Discovered", table.concat(ids, ","))
	local groups = {}
	for mutation, set in data.DiscoveredMutations do
		local list = {}
		for known in set do
			table.insert(list, known)
		end
		table.insert(groups, mutation .. ":" .. table.concat(list, ","))
	end
	player:SetAttribute("DiscoveredMutations", table.concat(groups, ";"))
end

function KaijuService.placeInSlot(e, plot, index: number)
	local slot = plot.Slots[index]
	detach(e)
	slot.Entity = e
	e.State = "Slot"
	e.Plot = plot
	e.SlotIndex = index
	e.OwnerUserId = plot.Owner.UserId
	e.HomeUserId, e.HomePlot, e.HomeSlot, e.OriginZone, e.Nest = nil, nil, nil, nil, nil
	e.Model:PivotTo(slot.CFrame)
	e.Model.Parent = folder
	KaijuService.markDiscovered(plot.Owner, e.Id, e.Mutation)
	refreshPrompts(e)
	refreshBillboard(e)
	refreshBillboardOffset(e)
end

function KaijuService.spawnInNest(nest, id: string, mutation: string)
	local e = createEntity(id, 1, mutation)
	e.State = "Nest"
	e.Nest = nest
	nest.Current = e
	e.Model:PivotTo(CFrame.new(nest.Position) * CFrame.Angles(0, math.random() * math.pi * 2, 0))
	e.Model.Parent = folder
	refreshPrompts(e)
	refreshBillboard(e)
	refreshBillboardOffset(e)
	return e
end

-- Devolve o kaiju para a base de onde foi roubado (ou some, se veio de um ninho).
local function returnHome(e)
	local plot = e.HomePlot
	if plot and plot.Owner and plot.Owner.UserId == e.HomeUserId and plot.Slots[e.HomeSlot].Entity == e then
		local owner = plot.Owner
		clearCarrier(e)
		KaijuService.placeInSlot(e, plot, e.HomeSlot)
		S.Notify.send(owner, "Seu " .. displayName(e) .. " voltou para a base!", "success")
	else
		KaijuService.removeEntity(e)
	end
end

local function groundAt(position: Vector3): Vector3
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local exclude = { folder }
	for _, p in Players:GetPlayers() do
		if p.Character then
			table.insert(exclude, p.Character)
		end
	end
	params.FilterDescendantsInstances = exclude
	local hit = workspace:Raycast(position + Vector3.new(0, 5, 0), Vector3.new(0, -60, 0), params)
	return if hit then hit.Position else Vector3.new(position.X, 0.2, position.Z)
end

-- Derruba o kaiju que o jogador está carregando.
function KaijuService.drop(player: Player, reason: string?)
	local e = carrying[player]
	if not e then
		return
	end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local position = if hrp then hrp.Position else e.Model.PrimaryPart.Position
	detach(e)
	clearCarrier(e)

	if e.OriginZone and reason == "guard" then
		-- a mãe pegou o filhote de volta
		KaijuService.removeEntity(e)
		return
	end

	e.State = "Dropped"
	e.Model:PivotTo(CFrame.new(groundAt(position)) * CFrame.Angles(0, math.random() * math.pi * 2, 0))
	refreshPrompts(e)
	refreshBillboard(e)
	e.DropToken = (e.DropToken or 0) + 1
	local token = e.DropToken
	task.delay(Config.DropReturnTime, function()
		if entities[e.Uid] == e and e.State == "Dropped" and e.DropToken == token then
			returnHome(e)
		end
	end)
end

-- O jogador larga o kaiju de propósito (tecla G, botão do HUD ou clique com o item da hotbar).
function KaijuService.dropByPlayer(player: Player)
	local e = carrying[player]
	if not e then
		return
	end
	local name = displayName(e)
	KaijuService.drop(player, "manual")
	S.Notify.send(player, "Você largou " .. name .. ".", "info")
end

local function attach(e, hrp: BasePart)
	local root = e.Model.PrimaryPart
	e.Model:PivotTo(hrp.CFrame * CFrame.new(0, 3.2, 0))
	local weld = Instance.new("Weld")
	weld.Part0 = hrp
	weld.Part1 = root
	weld.C0 = CFrame.new(0, 3.2, 0)
	weld.Parent = root
	root.Anchored = false
	e.Weld = weld
end

local function startCarry(player: Player, e)
	if carrying[player] then
		S.Notify.send(player, "Você já está carregando um kaiju!", "warn")
		return
	end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum or hum.Health <= 0 or S.PlotService.isTraining(player) then
		return
	end
	-- validação de distância no servidor (prompts podem ser disparados por exploit)
	local reach = 12 + 3 * Config.Stages[e.Stage].Scale
	if (hrp.Position - e.Model.PrimaryPart.Position).Magnitude > reach then
		return
	end

	if e.State == "Slot" then
		if e.OwnerUserId == player.UserId then
			return
		end
		if S.PlotService.isLocked(e.Plot) then
			S.Notify.send(player, "🔒 Essa base está trancada!", "warn")
			return
		end
		local owner = e.Plot.Owner
		e.HomeUserId = e.OwnerUserId
		e.HomePlot = e.Plot
		e.HomeSlot = e.SlotIndex
		-- o pedestal continua reservado até o ladrão chegar na base dele
		if owner then
			S.Notify.send(
				owner,
				"⚠️ " .. player.DisplayName .. " está roubando seu " .. displayName(e) .. "!",
				"warn"
			)
		end
	elseif e.State == "Nest" then
		local nest = e.Nest
		e.Nest = nil
		nest.Current = nil
		e.OriginZone = nest.Zone.Index
		S.NestService.onTaken(nest)
	elseif e.State == "Dropped" then
		if e.HomeUserId == player.UserId then
			returnHome(e)
			return
		end
	else
		return
	end

	e.DropToken = (e.DropToken or 0) + 1
	attach(e, hrp)
	e.State = "Carried"
	e.Carrier = player
	carrying[player] = e
	player:SetAttribute("Carrying", displayName(e) .. " (" .. Config.Stages[e.Stage].Name .. ")")
	giveCarryTool(player, e)
	S.CharacterService.refreshSpeed(player)
	refreshPrompts(e)
	refreshBillboard(e)
end

local function deposit(player: Player, e, plot): boolean
	local index = S.PlotService.findFreeSlot(plot)
	if not index then
		local now = os.clock()
		if (lastFullWarning[player] or 0) + 4 < now then
			lastFullWarning[player] = now
			S.Notify.send(player, "Sua base está cheia! Venda um kaiju ou desbloqueie espaços.", "warn")
		end
		return false
	end

	local data = S.DataService.get(player)
	local name = displayName(e)
	if e.HomePlot then
		local victim = e.HomePlot.Owner
		if e.HomePlot.Slots[e.HomeSlot].Entity == e then
			e.HomePlot.Slots[e.HomeSlot].Entity = nil
		end
		if victim then
			S.Notify.send(victim, "💢 " .. player.DisplayName .. " roubou seu " .. name .. "!", "warn")
			local vdata = S.DataService.get(victim)
			if vdata then
				vdata.Stats.TimesRobbed += 1
			end
		end
		S.Notify.send(player, "Você roubou " .. name .. "! 😈", "success")
		if data then
			data.Stats.Steals += 1
		end
	else
		S.Notify.send(player, "Você capturou " .. name .. "!", "success")
		if data then
			data.Stats.Captured += 1
		end
	end
	clearCarrier(e)
	KaijuService.placeInSlot(e, plot, index)
	return true
end

function KaijuService.onPrompt(player: Player, e, action: string)
	if entities[e.Uid] ~= e then
		return
	end
	if action == "take" then
		startCarry(player, e)
	elseif action == "sell" then
		KaijuService.sell(player, e)
	end
end

function KaijuService.sell(player: Player, e): number
	if entities[e.Uid] ~= e or e.State ~= "Slot" or e.OwnerUserId ~= player.UserId then
		return 0
	end
	local value = sellValue(e)
	local name = displayName(e)
	KaijuService.removeEntity(e)
	S.EconomyService.addCash(player, value)
	S.Notify.send(player, "Vendeu " .. name .. " por " .. Format.money(value), "cash")
	return value
end

function KaijuService.sellByUid(player: Player, uid: number)
	local e = entities[uid]
	if e then
		KaijuService.sell(player, e)
	end
end

function KaijuService.sellAll(player: Player)
	local total, count = 0, 0
	for _, e in entities do
		if e.State == "Slot" and e.OwnerUserId == player.UserId then
			local value = sellValue(e)
			KaijuService.removeEntity(e)
			total += value
			count += 1
		end
	end
	if count > 0 then
		S.EconomyService.addCash(player, total)
		S.Notify.send(player, string.format("Vendeu %d kaiju(s) por %s", count, Format.money(total)), "cash")
	end
end

---------------------------------------------------------------------------
-- API usada por outros serviços
---------------------------------------------------------------------------

function KaijuService.isCarrying(player: Player): boolean
	return carrying[player] ~= nil
end

function KaijuService.getCarried(player: Player)
	return carrying[player]
end

function KaijuService.getCarryMultiplier(player: Player): number
	local e = carrying[player]
	return if e then Config.Stages[e.Stage].CarrySpeed else 1
end

-- Lista de todos os que carregam algo (usado pelos guardiões).
function KaijuService.getCarriers()
	return carrying
end

function KaijuService.serialize(player: Player)
	local list = {}
	local uid = player.UserId
	for _, e in entities do
		local slot
		if e.State == "Slot" and e.OwnerUserId == uid then
			slot = e.SlotIndex
		elseif e.HomeUserId == uid then
			slot = e.HomeSlot
		end
		if slot then
			table.insert(
				list,
				{ Id = e.Id, Stage = e.Stage, Growth = math.floor(e.Growth), Mutation = e.Mutation, Slot = slot }
			)
		end
	end
	return list
end

function KaijuService.loadPlayer(player: Player, records, offlineSeconds: number)
	local plot = S.PlotService.getPlot(player)
	if not plot then
		return
	end
	local totalIncome = 0
	for _, r in records do
		if not KaijuData.ById[r.Id] then
			continue
		end
		-- aplica o crescimento offline antes de montar o modelo
		local temp = {
			Id = r.Id,
			Stage = math.clamp(r.Stage or 1, 1, #Config.Stages),
			Growth = r.Growth or 0,
			Mutation = r.Mutation or "Normal",
		}
		local remaining = offlineSeconds
		while remaining > 0 do
			local gt = growTime(temp)
			if not gt then
				break
			end
			local need = gt - temp.Growth
			if remaining >= need then
				temp.Stage += 1
				temp.Growth = 0
				remaining -= need
			else
				temp.Growth += remaining
				remaining = 0
			end
		end

		local index = if S.PlotService.isSlotUsable(plot, r.Slot or 0) then r.Slot else S.PlotService.findFreeSlot(plot)
		if index then
			local e = createEntity(temp.Id, temp.Stage, temp.Mutation, temp.Growth)
			KaijuService.placeInSlot(e, plot, index)
			totalIncome += KaijuService.income(e)
		end
	end

	if offlineSeconds > 60 and totalIncome > 0 then
		local earned = math.floor(totalIncome * offlineSeconds * Config.OfflineIncomeRate)
		plot.Pending += earned
		S.Notify.send(
			player,
			string.format("Enquanto você estava fora seus kaijus geraram %s! Pegue no coletor.", Format.money(earned)),
			"success"
		)
	end
end

-- Chamado quando o jogador sai: limpa tudo que é dele ou que ele carrega.
function KaijuService.clearPlayer(player: Player)
	local uid = player.UserId
	local carried = carrying[player]
	if carried then
		detach(carried)
		clearCarrier(carried)
		if carried.HomeUserId and carried.HomeUserId ~= uid then
			returnHome(carried)
		else
			KaijuService.removeEntity(carried)
		end
	end
	for _, e in entities do
		if (e.State == "Slot" and e.OwnerUserId == uid) or e.HomeUserId == uid then
			local thief = e.Carrier
			if e.State == "Carried" then
				detach(e)
			end
			KaijuService.removeEntity(e)
			if thief then
				S.Notify.send(thief, "O dono saiu do jogo e o kaiju sumiu!", "warn")
			end
		end
	end
	lastFullWarning[player] = nil
	lastInventoryWarning[player] = nil
end

---------------------------------------------------------------------------
-- Loops
---------------------------------------------------------------------------

local function stageUp(e)
	e.Stage += 1
	e.Growth = 0
	e.Model:ScaleTo(Config.Stages[e.Stage].Scale)
	if e.State == "Slot" then
		e.Model:PivotTo(e.Plot.Slots[e.SlotIndex].CFrame)
	end
	refreshPrompts(e)
	refreshBillboardOffset(e)

	local burst = Instance.new("ParticleEmitter")
	burst.Color = ColorSequence.new(Color3.fromRGB(255, 255, 150))
	burst.LightEmission = 1
	burst.Size = NumberSequence.new(0.6, 0)
	burst.Speed = NumberRange.new(8, 14)
	burst.SpreadAngle = Vector2.new(180, 180)
	burst.Lifetime = NumberRange.new(0.5, 0.9)
	burst.Rate = 0
	burst.Parent = e.Model.PrimaryPart
	burst:Emit(40)
	task.delay(2, function()
		burst:Destroy()
	end)

	local owner = e.Plot and e.Plot.Owner
	if owner then
		S.Notify.send(
			owner,
			string.format("Seu %s cresceu e virou %s! 🦖", displayName(e), Config.Stages[e.Stage].Name),
			"success"
		)
	end
end

local function incomeTick()
	local totals = {}
	for _, e in entities do
		if e.State == "Slot" and e.Plot and e.Plot.Owner then
			local plot = e.Plot
			local inc = KaijuService.income(e) * (plot.Owner:GetAttribute("IncomeMult") or 1)
			plot.Pending += inc
			totals[plot] = (totals[plot] or 0) + inc
			local gt = growTime(e)
			if gt then
				e.Growth += 1
				if e.Growth >= gt then
					stageUp(e)
				end
			end
			refreshBillboard(e)
		end
	end
	for _, plot in S.PlotService.getPlots() do
		if plot.Owner then
			plot.Owner:SetAttribute("Income", totals[plot] or 0)
		end
	end
end

---------------------------------------------------------------------------
-- Inventário: ao cruzar da Praia para a área das bases, o filhote sai da cabeça
-- e fica guardado (não pode mais ser derrubado nem roubado). Ao entrar na base,
-- vai sozinho para um pedestal livre.
---------------------------------------------------------------------------

local INVENTORY_TOOL_ATTRIBUTE = "InventoryTool"

local function inventoryOf(player: Player)
	local data = S.DataService.get(player)
	return data and data.Inventory
end

local function warnThrottled(player: Player, text: string)
	local now = os.clock()
	if (lastInventoryWarning[player] or 0) + 4 < now then
		lastInventoryWarning[player] = now
		S.Notify.send(player, text, "warn")
	end
end

local function recordIncome(record): number
	local def = KaijuData.ById[record.Id]
	local mutation = Config.MutationsByName[record.Mutation or "Normal"] or Config.MutationsByName.Normal
	return def.Income * Config.Stages[record.Stage or 1].IncomeMult * mutation.Mult
end

-- Atualiza a hotbar (só kaijus recém-capturados) e a lista do depósito usada no painel "Minha base".
function KaijuService.refreshInventoryTools(player: Player)
	for _, container in { player:FindFirstChildOfClass("Backpack"), player.Character } do
		if container then
			for _, child in container:GetChildren() do
				if child:IsA("Tool") and child:GetAttribute(INVENTORY_TOOL_ATTRIBUTE) then
					child:Destroy()
				end
			end
		end
	end
	local inventory = inventoryOf(player)
	if not inventory then
		return
	end
	local listed = {}
	for i, record in inventory do
		if KaijuData.ById[record.Id] then
			local def = KaijuData.ById[record.Id]
			table.insert(listed, {
				Index = i,
				Id = record.Id,
				Name = displayName(record),
				Rarity = def.Rarity,
				Stage = Config.Stages[record.Stage or 1].Name,
				Income = recordIncome(record),
			})
		end
	end
	player:SetAttribute("Storage", HttpService:JSONEncode(listed))

	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack then
		return
	end
	for _, record in inventory do
		if record.New and KaijuData.ById[record.Id] then
			local tool = Instance.new("Tool")
			tool.Name = "🛡️ " .. displayName(record)
			tool.ToolTip = Config.Stages[record.Stage or 1].Name .. " • guardado, entre na sua base"
			tool.RequiresHandle = false
			tool.CanBeDropped = false
			tool:SetAttribute(INVENTORY_TOOL_ATTRIBUTE, true)
			tool.Parent = backpack
		end
	end
end

local function secure(player: Player, e)
	local inventory = inventoryOf(player)
	if not inventory then
		return
	end
	if #inventory >= Config.InventorySize then
		warnThrottled(player, "Depósito cheio! Venda ou coloque kaijus na base.")
		return
	end
	local name = displayName(e)
	table.insert(
		inventory,
		{ Id = e.Id, Stage = e.Stage, Growth = math.floor(e.Growth), Mutation = e.Mutation, New = true }
	)
	detach(e)
	KaijuService.removeEntity(e)
	local data = S.DataService.get(player)
	if data then
		data.Stats.Captured += 1
	end
	KaijuService.refreshInventoryTools(player)
	S.Notify.send(
		player,
		"🛡️ " .. name .. " está seguro no seu inventário! Entre na sua base para colocar.",
		"success"
	)
end

-- Coloca na base os kaijus recém-capturados (os guardados de propósito ficam no depósito).
local function depositInventory(player: Player, plot)
	local inventory = inventoryOf(player)
	if not inventory then
		return
	end
	local placed = 0
	local i = 1
	while i <= #inventory do
		local record = inventory[i]
		if not record.New then
			i += 1
			continue
		end
		local index = S.PlotService.findFreeSlot(plot)
		if not index then
			record.New = nil
			warnThrottled(player, 'Base cheia! O kaiju foi para o depósito (abra "Minha base").')
			i += 1
			continue
		end
		table.remove(inventory, i)
		if KaijuData.ById[record.Id] then
			local e = createEntity(record.Id, record.Stage or 1, record.Mutation, record.Growth)
			KaijuService.placeInSlot(e, plot, index)
			placed += 1
		end
	end
	KaijuService.refreshInventoryTools(player)
	if placed > 0 then
		S.Notify.send(player, string.format("%d kaiju(s) colocado(s) na sua base!", placed), "success")
	end
end

---------------------------------------------------------------------------
-- Painel "Minha base": remover, colocar e equipar os melhores
---------------------------------------------------------------------------

local function toRecord(e)
	return { Id = e.Id, Stage = e.Stage, Growth = math.floor(e.Growth), Mutation = e.Mutation }
end

function KaijuService.storeFromSlot(player: Player, uid: number)
	local e = entities[uid]
	local inventory = inventoryOf(player)
	if not e or not inventory or e.State ~= "Slot" or e.OwnerUserId ~= player.UserId then
		return
	end
	if #inventory >= Config.InventorySize then
		S.Notify.send(player, "Depósito cheio!", "warn")
		return
	end
	table.insert(inventory, toRecord(e))
	KaijuService.removeEntity(e)
	KaijuService.refreshInventoryTools(player)
end

function KaijuService.placeFromInventory(player: Player, index: number)
	local inventory = inventoryOf(player)
	local plot = S.PlotService.getPlot(player)
	local record = inventory and inventory[index]
	if not record or not plot or not KaijuData.ById[record.Id] then
		return
	end
	local slot = S.PlotService.findFreeSlot(plot)
	if not slot then
		S.Notify.send(player, "Sua base está cheia! Remova um kaiju primeiro.", "warn")
		return
	end
	table.remove(inventory, index)
	local e = createEntity(record.Id, record.Stage or 1, record.Mutation, record.Growth)
	KaijuService.placeInSlot(e, plot, slot)
	KaijuService.refreshInventoryTools(player)
end

-- Deixa nos pedestais os kaijus que mais rendem e guarda o resto no depósito.
function KaijuService.equipBest(player: Player)
	local inventory = inventoryOf(player)
	local plot = S.PlotService.getPlot(player)
	local data = S.DataService.get(player)
	if not inventory or not plot or not data then
		return
	end
	local all = {}
	for _, e in entities do
		if e.State == "Slot" and e.OwnerUserId == player.UserId then
			table.insert(all, { Income = KaijuService.income(e), Entity = e })
		end
	end
	for i, record in inventory do
		if KaijuData.ById[record.Id] then
			table.insert(all, { Income = recordIncome(record), Record = record, Index = i })
		end
	end
	table.sort(all, function(a, b)
		return a.Income > b.Income
	end)
	local capacity = math.min(data.SlotsUnlocked, #plot.Slots)
	-- 1) guarda quem ficou fora do top
	for rank = capacity + 1, #all do
		local item = all[rank]
		if item.Entity then
			table.insert(inventory, toRecord(item.Entity))
			KaijuService.removeEntity(item.Entity)
		end
	end
	-- 2) coloca quem entrou no top (removendo do depósito do fim para o começo)
	local toPlace = {}
	for rank = 1, math.min(capacity, #all) do
		if all[rank].Record then
			table.insert(toPlace, all[rank])
		end
	end
	table.sort(toPlace, function(a, b)
		return a.Index > b.Index
	end)
	for _, item in toPlace do
		local slot = S.PlotService.findFreeSlot(plot)
		if not slot then
			break
		end
		table.remove(inventory, item.Index)
		local r = item.Record
		local e = createEntity(r.Id, r.Stage or 1, r.Mutation, r.Growth)
		KaijuService.placeInSlot(e, plot, slot)
	end
	KaijuService.refreshInventoryTools(player)
	S.Notify.send(player, "Os melhores kaijus foram colocados na base!", "success")
end

local function inventoryTick()
	for _, player in Players:GetPlayers() do
		local inventory = inventoryOf(player)
		local hasNew = false
		for _, record in inventory or {} do
			if record.New then
				hasNew = true
				break
			end
		end
		if hasNew then
			local plot = S.PlotService.getPlot(player)
			local char = player.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if plot and hrp and S.PlotService.isInside(plot, hrp.Position) then
				local ok, err = xpcall(depositInventory, debug.traceback, player, plot)
				if not ok then
					warn("[KaijuService] Falha ao colocar kaiju do inventário: " .. tostring(err))
				end
			end
		end
	end
end

local SAFE_LINE_Z = Config.Zones[1].ZStart

local function carrierTick()
	for player, e in carrying do
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not hrp or not hum or hum.Health <= 0 or not e.Weld or e.Weld.Part0 ~= hrp then
			KaijuService.drop(player, "lost")
		elseif e.OriginZone and hrp.Position.Z < SAFE_LINE_Z then
			-- filhote de ninho cruzou a linha das zonas: fica seguro no inventário
			secure(player, e)
		else
			local plot = S.PlotService.getPlot(player)
			if plot and S.PlotService.isInside(plot, hrp.Position) then
				local ok, err = xpcall(deposit, debug.traceback, player, e, plot)
				if not ok then
					warn("[KaijuService] Falha ao guardar kaiju de " .. player.Name .. ": " .. tostring(err))
				end
			else
				-- entrou na base errada: avisa e aponta a certa
				for _, other in S.PlotService.getPlots() do
					if other ~= plot and S.PlotService.isInside(other, hrp.Position) then
						local now = os.clock()
						if (lastFullWarning[player] or 0) + 4 < now then
							lastFullWarning[player] = now
							S.Notify.send(player, "Essa não é a sua base! Siga a seta até a SUA BASE.", "warn")
						end
						break
					end
				end
			end
		end
	end
end

function KaijuService.Init(services)
	S = services
	folder = services.Map.KaijuFolder
	Remotes.get("DropKaiju").OnServerEvent:Connect(function(player)
		KaijuService.dropByPlayer(player)
	end)
end

function KaijuService.Start()
	task.spawn(function()
		while true do
			task.wait(1)
			incomeTick()
		end
	end)
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc >= 0.1 then
			acc = 0
			carrierTick()
			inventoryTick()
		end
	end)
end

return KaijuService
