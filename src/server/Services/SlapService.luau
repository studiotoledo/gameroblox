-- A luva do tapa: acerta quem está na frente, derruba o kaiju que a vítima carrega
-- e dá um empurrão.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local SlapService = {}
local S
local knockback = Remotes.get("Knockback")
local lastSlap: { [Player]: number } = {}

local function slap(player: Player, tool: Tool)
	local now = os.clock()
	if (lastSlap[player] or 0) + Config.SlapCooldown > now then
		return
	end
	lastSlap[player] = now

	local anim = Instance.new("StringValue")
	anim.Name = "toolanim"
	anim.Value = "Slash"
	anim.Parent = tool
	task.delay(0.3, function()
		anim:Destroy()
	end)

	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return
	end
	local look = hrp.CFrame.LookVector
	for _, other in Players:GetPlayers() do
		if other == player then
			continue
		end
		local ochar = other.Character
		local ohrp = ochar and ochar:FindFirstChild("HumanoidRootPart") :: BasePart?
		local ohum = ochar and ochar:FindFirstChildOfClass("Humanoid")
		if not ohrp or not ohum or ohum.Health <= 0 then
			continue
		end
		local offset = ohrp.Position - hrp.Position
		if offset.Magnitude <= Config.SlapRange and offset.Unit:Dot(look) > 0.2 then
			local wasCarrying = S.KaijuService.isCarrying(other)
			S.KaijuService.drop(other, "slap")
			knockback:FireClient(other, look * 55 + Vector3.new(0, 35, 0))
			if wasCarrying then
				S.Notify.send(player, "👋 TAPA! " .. other.DisplayName .. " derrubou o kaiju!", "success")
				S.Notify.send(
					other,
					"👋 " .. player.DisplayName .. " te deu um tapa e você derrubou o kaiju!",
					"warn"
				)
			end
		end
	end
end

function SlapService.giveTool(player: Player)
	local backpack = player:WaitForChild("Backpack", 10)
	if not backpack or backpack:FindFirstChild("Tapa") then
		return
	end
	local tool = Instance.new("Tool")
	tool.Name = "Tapa"
	tool.ToolTip = "Dê um tapa em quem está carregando um kaiju!"
	tool.CanBeDropped = false
	tool.Grip = CFrame.new(0, 0, -0.4)

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(1.1, 1.1, 1.5)
	handle.Color = Color3.fromRGB(230, 50, 50)
	handle.Material = Enum.Material.SmoothPlastic
	handle.Massless = true
	handle.CanCollide = false
	handle.Parent = tool

	tool.Activated:Connect(function()
		slap(player, tool)
	end)
	tool.Parent = backpack
end

function SlapService.Init(services)
	S = services
	Players.PlayerRemoving:Connect(function(player)
		lastSlap[player] = nil
	end)
end

return SlapService
