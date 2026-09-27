-- Portais de velocidade: quem não tem a velocidade mínima de uma zona é empurrado de volta.
-- A checagem é por posição, então pular ou contornar o portal não adianta.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local ZoneService = {}
local S
local knockback = Remotes.get("Knockback")
local lastWarning: { [Player]: number } = {}

local function baseSpeed(player: Player): number
	local data = S.DataService.get(player)
	return Config.BaseWalkSpeed + (data and data.SpeedStat or 0)
end

local function check(player: Player)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return
	end
	local speed = baseSpeed(player)
	local z = hrp.Position.Z
	for _, zone in Config.Zones do
		if z > zone.ZStart and speed < zone.RequiredSpeed then
			local back = Vector3.new(hrp.Position.X, hrp.Position.Y + 2, zone.ZStart - 10)
			char:PivotTo(CFrame.lookAt(back, back - Vector3.new(0, 0, 1)))
			knockback:FireClient(player, Vector3.new(0, 25, -60))
			local now = os.clock()
			if (lastWarning[player] or 0) + 3 < now then
				lastWarning[player] = now
				S.Notify.send(
					player,
					string.format(
						"⚡ %s exige velocidade %d. Você tem %d: treine na esteira!",
						zone.Name,
						zone.RequiredSpeed,
						math.floor(speed)
					),
					"warn"
				)
			end
			return
		end
	end
end

function ZoneService.Init(services)
	S = services
	Players.PlayerRemoving:Connect(function(player)
		lastWarning[player] = nil
	end)
end

function ZoneService.Start()
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc < 0.2 then
			return
		end
		acc = 0
		for _, player in Players:GetPlayers() do
			check(player)
		end
	end)
end

return ZoneService
