-- Ponto de entrada do servidor: monta o mapa e inicia os serviços na ordem certa.

local Services = script.Services

local MapBuilder = require(Services.MapBuilder)

local S = {
	Map = MapBuilder.build(),
	Notify = require(Services.Notify),
	DataService = require(Services.DataService),
	EconomyService = require(Services.EconomyService),
	PlotService = require(Services.PlotService),
	KaijuService = require(Services.KaijuService),
	NestService = require(Services.NestService),
	GuardService = require(Services.GuardService),
	ZoneService = require(Services.ZoneService),
	EventService = require(Services.EventService),
	RewardsService = require(Services.RewardsService),
	CharacterService = require(Services.CharacterService),
	SlapService = require(Services.SlapService),
	PlayerService = require(Services.PlayerService),
}

local ORDER = {
	"DataService",
	"EconomyService",
	"PlotService",
	"KaijuService",
	"NestService",
	"GuardService",
	"ZoneService",
	"EventService",
	"RewardsService",
	"CharacterService",
	"SlapService",
	"PlayerService",
}

for _, name in ORDER do
	local service = S[name]
	if service.Init then
		service.Init(S)
	end
end
for _, name in ORDER do
	local service = S[name]
	if service.Start then
		service.Start()
	end
end

print("[Roube um Kaiju] servidor pronto")
