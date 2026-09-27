-- Efeitos locais: empurrão (tapa / guardião).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)

local player = Players.LocalPlayer

local Effects = {}

function Effects.start()
	Remotes.get("Knockback").OnClientEvent:Connect(function(velocity: Vector3)
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not hrp or not hum then
			return
		end
		hum.PlatformStand = true
		hrp.AssemblyLinearVelocity = velocity
		task.delay(0.7, function()
			if hum.Parent then
				hum.PlatformStand = false
				hum:ChangeState(Enum.HumanoidStateType.GettingUp)
			end
		end)
	end)
end

return Effects
