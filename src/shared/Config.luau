-- Ajustes gerais de balanceamento do jogo. Tudo que é "número de design" mora aqui.

local Config = {}

Config.DataStoreName = "RoubeUmKaiju_v1"
Config.AutosaveInterval = 120

-- Jogador
Config.BaseWalkSpeed = 16
Config.MaxSpeedStat = 200
Config.StartingCash = 0

-- Bases
Config.MaxPlots = 8
Config.PlotSpacing = 76
Config.PlotWidth = 64
Config.PlotDepth = 56
Config.SlotCount = 10
Config.StartingSlots = 6
Config.SlotUnlockCosts = { 500, 3000, 15000, 75000 }
Config.LockDuration = 45

-- Renda
Config.SellSeconds = 30 -- vender = X segundos da renda do kaiju
Config.OfflineCapSeconds = 2 * 60 * 60
Config.OfflineIncomeRate = 0.5

-- Roubo
Config.DropReturnTime = 15 -- segundos até um kaiju derrubado voltar pra casa
Config.SlapCooldown = 0.9
Config.SlapRange = 8

-- Esteira
Config.Treadmill = {
	BaseRate = 0.12, -- velocidade ganha por segundo no nível 0
	RatePerLevel = 0.06,
	MaxLevel = 15,
	CostBase = 75,
	CostGrowth = 2.1,
}

function Config.treadmillRate(level: number): number
	return Config.Treadmill.BaseRate + Config.Treadmill.RatePerLevel * level
end

function Config.treadmillCost(level: number): number
	return math.floor(Config.Treadmill.CostBase * Config.Treadmill.CostGrowth ^ level)
end

-- Estágios de crescimento. GrowTime = segundos (antes do fator de raridade) para ir ao próximo.
Config.Stages = {
	{ Name = "Filhote", Scale = 1, IncomeMult = 1, CarrySpeed = 1.0, GrowTime = 90 },
	{ Name = "Jovem", Scale = 1.6, IncomeMult = 3, CarrySpeed = 0.8, GrowTime = 420 },
	{ Name = "Adulto", Scale = 2.3, IncomeMult = 8, CarrySpeed = 0.6, GrowTime = 1500 },
	{ Name = "Titã", Scale = 3.2, IncomeMult = 25, CarrySpeed = 0.4 },
}

Config.Rarities = {
	Comum = { Order = 1, Color = Color3.fromRGB(210, 210, 210), GrowFactor = 1 },
	Incomum = { Order = 2, Color = Color3.fromRGB(85, 220, 110), GrowFactor = 1.2 },
	Raro = { Order = 3, Color = Color3.fromRGB(70, 150, 255), GrowFactor = 1.5 },
	["Épico"] = { Order = 4, Color = Color3.fromRGB(185, 95, 255), GrowFactor = 2 },
	["Lendário"] = { Order = 5, Color = Color3.fromRGB(255, 190, 40), GrowFactor = 3, Announce = true },
	["Mítico"] = { Order = 6, Color = Color3.fromRGB(255, 70, 100), GrowFactor = 4, Announce = true },
	Secreto = { Order = 7, Color = Color3.fromRGB(255, 255, 255), GrowFactor = 6, Announce = true },
}

-- Mutações: Weight é a chance relativa de aparecer num ninho.
Config.Mutations = {
	{ Name = "Normal", Mult = 1, Weight = 885 },
	{
		Name = "Dourado",
		Mult = 2,
		Weight = 70,
		Color = Color3.fromRGB(255, 200, 50),
		Blend = 0.8,
		Reflectance = 0.25,
		Label = Color3.fromRGB(255, 205, 60),
	},
	{
		Name = "Diamante",
		Mult = 3,
		Weight = 30,
		Color = Color3.fromRGB(150, 235, 255),
		Blend = 0.85,
		Material = Enum.Material.Glass,
		Transparency = 0.15,
		Label = Color3.fromRGB(150, 235, 255),
	},
	{
		Name = "Neon",
		Mult = 4,
		Weight = 12,
		AccentNeon = true,
		AccentColor = Color3.fromRGB(0, 255, 200),
		Light = Color3.fromRGB(0, 255, 200),
		Label = Color3.fromRGB(0, 255, 200),
	},
	{
		Name = "Radioativo",
		Mult = 6,
		Weight = 3,
		Color = Color3.fromRGB(120, 255, 60),
		Blend = 0.55,
		AccentNeon = true,
		AccentColor = Color3.fromRGB(150, 255, 0),
		Particles = Color3.fromRGB(150, 255, 0),
		Light = Color3.fromRGB(150, 255, 0),
		Label = Color3.fromRGB(150, 255, 0),
	},
}

Config.MutationsByName = {}
for _, m in Config.Mutations do
	Config.MutationsByName[m.Name] = m
end

-- Zonas, da mais perto da base para a mais longe. Z = distância a partir das bases.
Config.Zones = {
	{
		Name = "Praia Tranquila",
		ZStart = 110,
		ZEnd = 260,
		Color = Color3.fromRGB(235, 215, 160),
		Material = Enum.Material.Sand,
		Nests = 7,
		GuardSpeed = 14,
		Weights = { Comum = 80, Incomum = 18, Raro = 2 },
	},
	{
		Name = "Floresta Selvagem",
		ZStart = 270,
		ZEnd = 440,
		Color = Color3.fromRGB(90, 160, 70),
		Material = Enum.Material.Grass,
		Nests = 7,
		GuardSpeed = 24,
		Weights = { Comum = 45, Incomum = 38, Raro = 14, ["Épico"] = 3 },
	},
	{
		Name = "Vulcão Furioso",
		ZStart = 450,
		ZEnd = 640,
		Color = Color3.fromRGB(60, 50, 50),
		Material = Enum.Material.Basalt,
		Nests = 6,
		GuardSpeed = 34,
		Weights = { Incomum = 35, Raro = 40, ["Épico"] = 20, ["Lendário"] = 5 },
	},
	{
		Name = "Geleira Eterna",
		ZStart = 650,
		ZEnd = 860,
		Color = Color3.fromRGB(200, 230, 245),
		Material = Enum.Material.Glacier,
		Nests = 6,
		GuardSpeed = 46,
		Weights = { Raro = 40, ["Épico"] = 40, ["Lendário"] = 16, ["Mítico"] = 4 },
	},
	{
		Name = "Abismo Cósmico",
		ZStart = 870,
		ZEnd = 1100,
		Color = Color3.fromRGB(45, 25, 70),
		Material = Enum.Material.Slate,
		Nests = 5,
		GuardSpeed = 60,
		Weights = { ["Épico"] = 45, ["Lendário"] = 38, ["Mítico"] = 14, Secreto = 3 },
	},
}

Config.MapHalfWidth = 312
Config.NestRespawn = { Min = 6, Max = 14 }
Config.NestLifetime = 90
Config.GuardAggroRange = 90
Config.GuardScale = 3

return Config
