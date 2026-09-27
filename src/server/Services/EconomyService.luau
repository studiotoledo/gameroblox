-- Dinheiro, velocidade e leaderstats. Os valores ficam nos dados do jogador
-- e são espelhados em atributos do Player para a interface.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)

local EconomyService = {}
local S

function EconomyService.Init(services)
	S = services
end

local function refresh(player: Player)
	local data = S.DataService.get(player)
	if not data then
		return
	end
	player:SetAttribute("Cash", data.Cash)
	player:SetAttribute("SpeedStat", data.SpeedStat)
	player:SetAttribute("TreadmillLevel", data.TreadmillLevel)
	player:SetAttribute("SlotsUnlocked", data.SlotsUnlocked)
	local stats = player:FindFirstChild("leaderstats")
	if stats then
		local cash = stats:FindFirstChild("Dinheiro") :: StringValue?
		local speed = stats:FindFirstChild("Velocidade") :: IntValue?
		if cash then
			cash.Value = Format.money(data.Cash)
		end
		if speed then
			speed.Value = math.floor(Config.BaseWalkSpeed + data.SpeedStat)
		end
	end
end

function EconomyService.setup(player: Player)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	local cash = Instance.new("StringValue")
	cash.Name = "Dinheiro"
	cash.Parent = stats
	local speed = Instance.new("IntValue")
	speed.Name = "Velocidade"
	speed.Parent = stats
	stats.Parent = player
	refresh(player)
end

function EconomyService.getCash(player: Player): number
	local data = S.DataService.get(player)
	return data and data.Cash or 0
end

function EconomyService.addCash(player: Player, amount: number)
	local data = S.DataService.get(player)
	if not data or amount <= 0 then
		return
	end
	data.Cash += amount
	refresh(player)
end

function EconomyService.trySpend(player: Player, amount: number): boolean
	local data = S.DataService.get(player)
	if not data or data.Cash < amount then
		return false
	end
	data.Cash -= amount
	refresh(player)
	return true
end

function EconomyService.addSpeed(player: Player, amount: number)
	local data = S.DataService.get(player)
	if not data then
		return
	end
	local before = math.floor(data.SpeedStat)
	data.SpeedStat = math.min(Config.MaxSpeedStat, data.SpeedStat + amount)
	player:SetAttribute("SpeedStat", data.SpeedStat)
	if math.floor(data.SpeedStat) ~= before then
		refresh(player)
		S.CharacterService.refreshSpeed(player)
	end
end

function EconomyService.refresh(player: Player)
	refresh(player)
end

return EconomyService
