-- Orquestra entrada/saída de jogadores e o salvamento automático.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local PlayerService = {}
local S
local loaded: { [Player]: boolean } = {}

local function snapshot(player: Player)
	local data = S.DataService.get(player)
	if not data then
		return
	end
	data.Kaijus = S.KaijuService.serialize(player)
	data.LastOnline = os.time()
end

local function onAdded(player: Player)
	local data = S.DataService.load(player)
	if player.Parent == nil then
		S.DataService.release(player)
		return
	end
	if not data then
		player:Kick("Não foi possível carregar seus dados. Tente entrar de novo em instantes.")
		return
	end
	local plot = S.PlotService.assign(player)
	if not plot then
		S.DataService.release(player)
		player:Kick("Este servidor está cheio. Tente outro servidor!")
		return
	end

	player:SetAttribute("Carrying", "")
	player:SetAttribute("Income", 0)
	S.EconomyService.setup(player)

	local offline = 0
	if data.LastOnline > 0 then
		offline = math.clamp(os.time() - data.LastOnline, 0, Config.OfflineCapSeconds)
	end
	S.KaijuService.loadPlayer(player, data.Kaijus, offline)
	S.PlotService.refreshAll(player)
	S.CharacterService.setup(player)

	loaded[player] = true
	player:SetAttribute("Loaded", true)
	S.Notify.send(player, "Bem-vindo ao Roube um Kaiju! Roube filhotes nas zonas e leve para a sua base.", "info")
end

local function onRemoving(player: Player)
	if not loaded[player] then
		return
	end
	loaded[player] = nil
	snapshot(player)
	S.KaijuService.clearPlayer(player)
	S.PlotService.release(player)
	S.DataService.save(player)
	S.DataService.release(player)
end

function PlayerService.Init(services)
	S = services
end

function PlayerService.Start()
	Players.PlayerAdded:Connect(onAdded)
	Players.PlayerRemoving:Connect(onRemoving)
	for _, player in Players:GetPlayers() do
		task.spawn(onAdded, player)
	end

	task.spawn(function()
		while true do
			task.wait(Config.AutosaveInterval)
			for player in loaded do
				snapshot(player)
				task.spawn(S.DataService.save, player)
			end
		end
	end)

	game:BindToClose(function()
		local pending = 0
		for player in loaded do
			pending += 1
			snapshot(player)
			task.spawn(function()
				S.DataService.save(player)
				pending -= 1
			end)
		end
		local deadline = os.clock() + 25
		while pending > 0 and os.clock() < deadline do
			task.wait(0.1)
		end
	end)
end

return PlayerService
