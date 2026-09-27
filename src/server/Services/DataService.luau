-- Carrega e salva os dados dos jogadores no DataStore.
-- Sem acesso ao DataStore (ex.: Studio sem "Enable Studio Access to API Services"),
-- o jogo roda em "modo memória" e avisa no Output.

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)

local DataService = {}

local store: DataStore? = nil
local profiles: { [Player]: any } = {}
local noSave: { [Player]: boolean } = {}

local function defaultData()
	return {
		Version = 1,
		Cash = Config.StartingCash,
		SpeedStat = 0,
		TreadmillLevel = 0,
		SlotsUnlocked = Config.StartingSlots,
		Kaijus = {},
		Inventory = {}, -- kaijus trazidos das zonas que ainda não foram para um pedestal
		LastOnline = 0,
		Stats = { Captured = 0, Steals = 0, TimesRobbed = 0 },
	}
end

local function reconcile(data, template)
	for key, value in template do
		if data[key] == nil then
			data[key] = if type(value) == "table" then table.clone(value) else value
		elseif type(value) == "table" and type(data[key]) == "table" and next(value) ~= nil then
			reconcile(data[key], value)
		end
	end
	return data
end

local function key(player: Player): string
	return "Player_" .. player.UserId
end

function DataService.Init()
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(Config.DataStoreName)
	end)
	if ok then
		store = result
	else
		warn("[DataService] DataStore indisponível, rodando em modo memória:", result)
	end
end

-- Retorna os dados ou nil se não foi possível carregar (o jogador deve ser expulso).
function DataService.load(player: Player)
	local data
	if store then
		for attempt = 1, 3 do
			local ok, result = pcall(function()
				return store:GetAsync(key(player))
			end)
			if ok then
				data = result or defaultData()
				break
			end
			warn(
				string.format(
					"[DataService] Falha ao carregar %s (tentativa %d): %s",
					player.Name,
					attempt,
					tostring(result)
				)
			)
			if RunService:IsStudio() then
				break
			end
			task.wait(attempt * 2)
		end
	end
	if not data then
		if store and not RunService:IsStudio() then
			return nil
		end
		warn("[DataService] Usando dados temporários para " .. player.Name .. " (não serão salvos)")
		data = defaultData()
		noSave[player] = true
	end
	reconcile(data, defaultData())
	profiles[player] = data
	return data
end

function DataService.get(player: Player)
	return profiles[player]
end

function DataService.save(player: Player): boolean
	local data = profiles[player]
	if not data or not store or noSave[player] then
		return false
	end
	for attempt = 1, 3 do
		local ok, err = pcall(function()
			store:UpdateAsync(key(player), function()
				return data
			end)
		end)
		if ok then
			return true
		end
		warn(string.format("[DataService] Falha ao salvar %s (tentativa %d): %s", player.Name, attempt, tostring(err)))
		task.wait(attempt)
	end
	return false
end

function DataService.release(player: Player)
	profiles[player] = nil
	noSave[player] = nil
end

return DataService
