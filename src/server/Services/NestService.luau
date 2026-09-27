-- Faz filhotes aparecerem nos ninhos das zonas, sorteando raridade e mutação.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local KaijuData = require(ReplicatedStorage.Shared.KaijuData)
local Util = require(ReplicatedStorage.Shared.Util)

local NestService = {}
local S
local rng = Random.new()

local function spawnNext(nest)
	if nest.Current then
		return
	end
	local zone = nest.Zone
	local rarity = Util.weightedKey(zone.Config.Weights, rng)
	local pool = KaijuData.ByRarity[rarity]
	if not pool then
		return
	end
	local def = pool[rng:NextInteger(1, #pool)]
	local mutation = Util.weightedItem(Config.Mutations, rng)
	local e = S.KaijuService.spawnInNest(nest, def.Id, mutation.Name)

	if Config.Rarities[rarity].Announce then
		local name = def.Name .. (if mutation.Name ~= "Normal" then " " .. mutation.Name else "")
		S.Notify.all(
			string.format("Um kaiju %s apareceu: %s em %s!", string.upper(rarity), name, zone.Config.Name),
			"announce"
		)
	end

	-- se ninguém roubar, some e dá lugar a outro
	task.delay(Config.NestLifetime, function()
		if nest.Current == e and e.State == "Nest" then
			S.KaijuService.removeEntity(e)
			spawnNext(nest)
		end
	end)
end

function NestService.onTaken(nest)
	task.delay(rng:NextNumber(Config.NestRespawn.Min, Config.NestRespawn.Max), function()
		spawnNext(nest)
	end)
end

function NestService.Init(services)
	S = services
end

function NestService.Start()
	for _, zone in S.Map.Zones do
		for _, nest in zone.Nests do
			task.delay(rng:NextNumber(0.5, 4), function()
				spawnNext(nest)
			end)
		end
	end
end

return NestService
