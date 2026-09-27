-- Catálogo de kaijus. Income = $/s no estágio Filhote, sem mutação.
-- Archetype define o corpo (dino, quad, blob, crab, ape); os demais campos são enfeites.

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

local List = {
	-- Comum
	{
		Id = "tubaraozilla",
		Name = "Tubarãozilla",
		Rarity = "Comum",
		Income = 1,
		Archetype = "dino",
		Fin = true,
		Spikes = false,
		Colors = { Body = rgb(95, 130, 175), Belly = rgb(235, 240, 245), Accent = rgb(55, 80, 120) },
	},
	{
		Id = "sapao",
		Name = "Sapão Trovão",
		Rarity = "Comum",
		Income = 2,
		Archetype = "blob",
		Colors = { Body = rgb(95, 190, 70), Belly = rgb(240, 225, 110), Accent = rgb(255, 230, 40) },
	},
	{
		Id = "capivarossauro",
		Name = "Capivarossauro",
		Rarity = "Comum",
		Income = 3,
		Archetype = "quad",
		Ears = true,
		Colors = { Body = rgb(150, 100, 60), Belly = rgb(200, 160, 115), Accent = rgb(95, 60, 35) },
	},
	-- Incomum
	{
		Id = "polvo",
		Name = "Polvo Bombado",
		Rarity = "Incomum",
		Income = 8,
		Archetype = "blob",
		Tentacles = true,
		Colors = { Body = rgb(220, 90, 170), Belly = rgb(255, 180, 215), Accent = rgb(150, 40, 110) },
	},
	{
		Id = "galinha",
		Name = "Galinha Titânica",
		Rarity = "Incomum",
		Income = 12,
		Archetype = "dino",
		Beak = true,
		Comb = true,
		Spikes = false,
		Colors = { Body = rgb(245, 245, 240), Belly = rgb(255, 250, 230), Accent = rgb(230, 50, 50) },
	},
	-- Raro
	{
		Id = "tatu",
		Name = "Tatu Blindado",
		Rarity = "Raro",
		Income = 35,
		Archetype = "quad",
		Shell = true,
		Ears = true,
		Spikes = false,
		Colors = { Body = rgb(160, 130, 110), Belly = rgb(215, 190, 170), Accent = rgb(110, 100, 95) },
	},
	{
		Id = "caranguejo",
		Name = "Caranguejo Rei",
		Rarity = "Raro",
		Income = 50,
		Archetype = "crab",
		Crown = true,
		Colors = { Body = rgb(225, 70, 45), Belly = rgb(255, 170, 120), Accent = rgb(170, 35, 25) },
	},
	-- Épico
	{
		Id = "dragao_chinelo",
		Name = "Dragão de Chinelo",
		Rarity = "Épico",
		Income = 150,
		Archetype = "dino",
		Wings = true,
		Horns = true,
		Shoes = true,
		Colors = { Body = rgb(70, 170, 90), Belly = rgb(230, 220, 130), Accent = rgb(255, 210, 0) },
	},
	{
		Id = "mamute_neon",
		Name = "Mamute Neon",
		Rarity = "Épico",
		Income = 220,
		Archetype = "quad",
		Tusks = true,
		Ears = true,
		Colors = { Body = rgb(60, 60, 110), Belly = rgb(90, 90, 150), Accent = rgb(0, 230, 255) },
	},
	-- Lendário
	{
		Id = "gorilao",
		Name = "Gorilão Cósmico",
		Rarity = "Lendário",
		Income = 700,
		Archetype = "ape",
		Colors = { Body = rgb(55, 45, 90), Belly = rgb(150, 130, 200), Accent = rgb(255, 120, 255) },
	},
	{
		Id = "fenix",
		Name = "Fênix de Lava",
		Rarity = "Lendário",
		Income = 1000,
		Archetype = "dino",
		Beak = true,
		Wings = true,
		Comb = true,
		Colors = { Body = rgb(255, 120, 30), Belly = rgb(255, 220, 90), Accent = rgb(255, 40, 0) },
	},
	-- Mítico
	{
		Id = "rei_tubarao",
		Name = "Rei Tubarão de Tênis",
		Rarity = "Mítico",
		Income = 3500,
		Archetype = "dino",
		Fin = true,
		Crown = true,
		Shoes = true,
		Spikes = false,
		Colors = { Body = rgb(40, 90, 160), Belly = rgb(240, 245, 255), Accent = rgb(255, 60, 60) },
	},
	{
		Id = "hidra",
		Name = "Hidra Tripla",
		Rarity = "Mítico",
		Income = 5000,
		Archetype = "quad",
		Heads = 3,
		Horns = true,
		Colors = { Body = rgb(40, 120, 100), Belly = rgb(170, 220, 170), Accent = rgb(200, 255, 80) },
	},
	-- Secreto
	{
		Id = "gatinho_apocalipse",
		Name = "Gatinho do Apocalipse",
		Rarity = "Secreto",
		Income = 20000,
		Archetype = "quad",
		Ears = true,
		Horns = true,
		Colors = { Body = rgb(25, 25, 30), Belly = rgb(60, 60, 70), Accent = rgb(255, 30, 60), Eye = rgb(255, 30, 60) },
	},
	{
		Id = "capivara_suprema",
		Name = "Capivara Suprema",
		Rarity = "Secreto",
		Income = 30000,
		Archetype = "quad",
		Ears = true,
		Crown = true,
		Wings = true,
		Colors = { Body = rgb(230, 175, 60), Belly = rgb(255, 230, 150), Accent = rgb(255, 255, 255) },
	},
}

-- "Mães Kaiju": uma por zona, na mesma ordem de Config.Zones.
local Guards = {
	{
		Id = "guardiao_caranguejo",
		Name = "Caranguejo Guardião",
		Archetype = "crab",
		Rarity = "Raro",
		Colors = { Body = rgb(200, 60, 40), Accent = rgb(120, 30, 20), Eye = rgb(255, 0, 0) },
	},
	{
		Id = "guardiao_gorila",
		Name = "Gorila Guardião",
		Archetype = "ape",
		Rarity = "Raro",
		Colors = { Body = rgb(60, 70, 50), Belly = rgb(120, 130, 100), Eye = rgb(255, 0, 0) },
	},
	{
		Id = "guardiao_rex",
		Name = "Rex de Lava",
		Archetype = "dino",
		Rarity = "Épico",
		Horns = true,
		Colors = { Body = rgb(60, 30, 25), Accent = rgb(255, 100, 0), Eye = rgb(255, 60, 0) },
	},
	{
		Id = "guardiao_mamute",
		Name = "Mamute Glacial",
		Archetype = "quad",
		Rarity = "Épico",
		Tusks = true,
		Ears = true,
		Colors = { Body = rgb(150, 180, 210), Accent = rgb(80, 200, 255), Eye = rgb(255, 0, 0) },
	},
	{
		Id = "guardiao_dragao",
		Name = "Dragão do Abismo",
		Archetype = "dino",
		Rarity = "Lendário",
		Wings = true,
		Horns = true,
		Colors = { Body = rgb(40, 20, 70), Accent = rgb(200, 60, 255), Eye = rgb(255, 0, 80) },
	},
}

local KaijuData = {
	List = List,
	Guards = Guards,
	ById = {},
	ByRarity = {},
}

for _, def in List do
	KaijuData.ById[def.Id] = def
	KaijuData.ByRarity[def.Rarity] = KaijuData.ByRarity[def.Rarity] or {}
	table.insert(KaijuData.ByRarity[def.Rarity], def)
end

return KaijuData
