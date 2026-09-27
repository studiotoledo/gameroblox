-- Ações dos botões do HUD (remote "Action") e sistemas de recompensa:
-- teleporte para a base, modo lento, compras com dinheiro do jogo, vender,
-- renascimento, presente por tempo jogado, recompensa diária e bônus de amigos/Premium.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local RewardsService = {}
local S
local lastAction: { [Player]: number } = {}

local function today(): number
	return os.time() // 86400
end

local function incomeReward(player: Player, seconds: number, minimum: number): number
	return math.max(minimum, math.floor(((player:GetAttribute("Income") :: number?) or 0) * seconds))
end

---------------------------------------------------------------------------
-- Multiplicador de renda (renascimentos + amigos + Premium)
---------------------------------------------------------------------------

function RewardsService.refreshMultiplier(player: Player)
	local data = S.DataService.get(player)
	if not data then
		return
	end
	local friends = 0
	for _, other in Players:GetPlayers() do
		if other ~= player then
			local ok, isFriend = pcall(player.IsFriendsWithAsync, player, other.UserId)
			if ok and isFriend then
				friends += 1
			end
		end
	end
	local friendBoost = math.min(Config.MaxFriendBoost, friends * Config.FriendBoost)
	local premiumBoost = if player.MembershipType == Enum.MembershipType.Premium then Config.PremiumBoost else 0
	local rebirthMult = 1 + data.Rebirths * Config.Rebirth.IncomeBonus
	player:SetAttribute("FriendBoost", friendBoost)
	player:SetAttribute("PremiumBoost", premiumBoost)
	player:SetAttribute("Rebirths", data.Rebirths)
	player:SetAttribute("IncomeMult", rebirthMult * (1 + friendBoost + premiumBoost))
end

---------------------------------------------------------------------------
-- Diário e presentes
---------------------------------------------------------------------------

local function refreshDaily(player: Player)
	local data = S.DataService.get(player)
	if not data then
		return
	end
	-- sequência quebra se passou mais de um dia sem resgatar
	local streak = if data.LastDaily >= today() - 1 then data.DailyStreak else 0
	player:SetAttribute("DailyReady", data.LastDaily < today())
	player:SetAttribute("DailyStreak", streak)
end

local function claimDaily(player: Player)
	local data = S.DataService.get(player)
	if not data or data.LastDaily >= today() then
		S.Notify.send(player, "Você já pegou a recompensa de hoje. Volte amanhã!", "warn")
		return
	end
	data.DailyStreak = if data.LastDaily == today() - 1 then data.DailyStreak + 1 else 1
	data.LastDaily = today()
	local day = math.min(data.DailyStreak, Config.DailyMaxStreak)
	local reward = incomeReward(player, Config.DailyIncomeSeconds, Config.DailyMinimum) * day
	S.EconomyService.addCash(player, reward)
	refreshDaily(player)
	S.Notify.send(
		player,
		string.format("📅 Dia %d! Você ganhou %s", data.DailyStreak, Format.money(reward)),
		"success"
	)
end

local function claimGift(player: Player)
	local readyAt = player:GetAttribute("GiftReadyAt") or math.huge
	if os.time() < readyAt then
		S.Notify.send(player, "O presente ainda não está pronto.", "warn")
		return
	end
	local reward = incomeReward(player, Config.GiftIncomeSeconds, Config.GiftMinimum)
	S.EconomyService.addCash(player, reward)
	player:SetAttribute("GiftReadyAt", os.time() + Config.GiftInterval)
	S.Notify.send(player, "🎁 Presente aberto! " .. Format.money(reward), "success")
end

---------------------------------------------------------------------------
-- Renascimento
---------------------------------------------------------------------------

local function rebirth(player: Player)
	local data = S.DataService.get(player)
	if not data then
		return
	end
	local cost = Config.rebirthCost(data.Rebirths)
	if data.Cash < cost then
		S.Notify.send(player, "Você precisa de " .. Format.money(cost) .. " para renascer.", "warn")
		return
	end
	if S.KaijuService.isCarrying(player) then
		S.Notify.send(player, "Guarde o kaiju antes de renascer.", "warn")
		return
	end
	S.PlotService.stopTraining(player)
	data.Rebirths += 1
	data.Cash = 0
	data.SpeedStat = 0
	data.TreadmillLevel = 0
	S.EconomyService.refresh(player)
	S.PlotService.refreshAll(player)
	S.CharacterService.refreshSpeed(player)
	RewardsService.refreshMultiplier(player)
	S.Notify.all(string.format("🔄 %s renasceu pela %dª vez!", player.DisplayName, data.Rebirths), "announce")
end

---------------------------------------------------------------------------
-- Ações do HUD
---------------------------------------------------------------------------

local function teleportToBase(player: Player)
	if S.KaijuService.isCarrying(player) then
		S.Notify.send(player, "Não dá para teleportar carregando um kaiju. Corra!", "warn")
		return
	end
	local plot = S.PlotService.getPlot(player)
	local char = player.Character
	if plot and char then
		S.PlotService.stopTraining(player)
		char:PivotTo(plot.SpawnCFrame)
	end
end

local function toggleSlowMode(player: Player)
	player:SetAttribute("SlowMode", not player:GetAttribute("SlowMode"))
	S.CharacterService.refreshSpeed(player)
end

local ACTIONS = {
	base = teleportToBase,
	slowmode = toggleSlowMode,
	buy_treadmill = function(player)
		local plot = S.PlotService.getPlot(player)
		if plot then
			S.PlotService.upgradeTreadmill(player, plot, true)
		end
	end,
	buy_slot = function(player)
		local plot = S.PlotService.getPlot(player)
		if plot then
			S.PlotService.unlockSlot(player, plot)
		end
	end,
	sell = function(player, uid)
		if type(uid) == "number" then
			S.KaijuService.sellByUid(player, uid)
		end
	end,
	sellall = function(player)
		S.KaijuService.sellAll(player)
	end,
	remove = function(player, uid)
		if type(uid) == "number" then
			S.KaijuService.storeFromSlot(player, uid)
		end
	end,
	place = function(player, index)
		if type(index) == "number" then
			S.KaijuService.placeFromInventory(player, index)
		end
	end,
	equipbest = function(player)
		S.KaijuService.equipBest(player)
	end,
	rebirth = rebirth,
	daily = claimDaily,
	gift = claimGift,
}

function RewardsService.setup(player: Player)
	local data = S.DataService.get(player)
	if not data then
		return
	end
	player:SetAttribute("SlowMode", false)
	player:SetAttribute("GiftReadyAt", os.time() + Config.GiftInterval)
	S.KaijuService.publishDiscovered(player)
	S.KaijuService.refreshInventoryTools(player)
	refreshDaily(player)
	for _, other in Players:GetPlayers() do
		task.spawn(RewardsService.refreshMultiplier, other)
	end
end

function RewardsService.Init(services)
	S = services
	Remotes.get("Action").OnServerEvent:Connect(function(player, action, arg)
		local handler = type(action) == "string" and ACTIONS[action]
		if not handler or not S.DataService.get(player) then
			return
		end
		-- limite simples contra spam de cliques
		local now = os.clock()
		if (lastAction[player] or 0) + 0.25 > now then
			return
		end
		lastAction[player] = now
		handler(player, arg)
	end)
	Players.PlayerRemoving:Connect(function(player)
		lastAction[player] = nil
		task.defer(function()
			for _, other in Players:GetPlayers() do
				task.spawn(RewardsService.refreshMultiplier, other)
			end
		end)
	end)
end

function RewardsService.Start()
	-- a virada do dia libera a recompensa diária de quem está jogando
	task.spawn(function()
		while true do
			task.wait(60)
			for _, player in Players:GetPlayers() do
				if S.DataService.get(player) then
					refreshDaily(player)
				end
			end
		end
	end)
end

return RewardsService
