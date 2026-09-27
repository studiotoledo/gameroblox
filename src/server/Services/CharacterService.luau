-- Personagem: nasce na própria base, velocidade de andar e morte (derruba o kaiju).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local CharacterService = {}
local S

function CharacterService.Init(services)
	S = services
end

function CharacterService.refreshSpeed(player: Player)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local data = S.DataService.get(player)
	if not hum or not data then
		return
	end
	hum.WalkSpeed = (Config.BaseWalkSpeed + data.SpeedStat) * S.KaijuService.getCarryMultiplier(player)
end

local function onCharacter(player: Player, char: Model)
	local hum = char:WaitForChild("Humanoid", 10) :: Humanoid?
	if not hum or char.Parent == nil then
		return
	end
	local plot = S.PlotService.getPlot(player)
	if plot and char:WaitForChild("HumanoidRootPart", 10) then
		task.wait(0.1)
		if char.Parent then
			char:PivotTo(plot.SpawnCFrame)
		end
	end
	CharacterService.refreshSpeed(player)
	S.SlapService.giveTool(player)
	S.KaijuService.refreshInventoryTools(player)
	hum.Died:Connect(function()
		S.PlotService.stopTraining(player)
		S.KaijuService.drop(player, "died")
	end)
end

function CharacterService.setup(player: Player)
	player.CharacterAdded:Connect(function(char)
		onCharacter(player, char)
	end)
	player.CharacterRemoving:Connect(function()
		S.PlotService.stopTraining(player)
		S.KaijuService.drop(player, "died")
	end)
	if player.Character then
		task.spawn(onCharacter, player, player.Character)
	end
end

return CharacterService
