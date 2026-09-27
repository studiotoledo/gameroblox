-- Evento periódico "Hora dos Raros": por alguns minutos os ninhos sorteiam raridades
-- altas com mais frequência. O horário fica em atributos do workspace para o HUD mostrar.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local EventService = {}
local S

function EventService.isActive(): boolean
	return os.time() < (workspace:GetAttribute("EventEndsAt") or 0)
end

-- Multiplica o peso de cada raridade enquanto o evento está ativo.
function EventService.adjustWeights(weights: { [string]: number }): { [string]: number }
	if not EventService.isActive() then
		return weights
	end
	local adjusted = {}
	for rarity, weight in weights do
		local info = Config.Rarities[rarity]
		adjusted[rarity] = if info and info.Order >= 4 then weight * Config.Event.Luck else weight
	end
	return adjusted
end

function EventService.Init(services)
	S = services
	workspace:SetAttribute("EventName", Config.Event.Name)
	workspace:SetAttribute("EventEndsAt", 0)
	workspace:SetAttribute("NextEventAt", os.time() + Config.Event.Interval)
end

function EventService.Start()
	task.spawn(function()
		while true do
			task.wait(1)
			local now = os.time()
			if now >= (workspace:GetAttribute("NextEventAt") or math.huge) then
				workspace:SetAttribute("EventEndsAt", now + Config.Event.Duration)
				workspace:SetAttribute("NextEventAt", now + Config.Event.Duration + Config.Event.Interval)
				S.Notify.all(
					string.format(
						"🍀 %s! Kaijus raros aparecem %dx mais por %d minutos!",
						Config.Event.Name,
						Config.Event.Luck,
						Config.Event.Duration // 60
					),
					"announce"
				)
			end
		end
	end)
end

return EventService
