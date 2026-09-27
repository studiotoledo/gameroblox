-- Funções utilitárias compartilhadas.

local Util = {}

-- Sorteia uma chave de uma tabela { [chave] = peso }.
function Util.weightedKey(weights: { [any]: number }, rng: Random?): any
	local total = 0
	for _, w in weights do
		total += w
	end
	local roll = (rng or Random.new()):NextNumber() * total
	for key, w in weights do
		roll -= w
		if roll <= 0 then
			return key
		end
	end
	return next(weights)
end

-- Sorteia um item de uma lista cujos itens têm o campo Weight.
function Util.weightedItem(list: { any }, rng: Random?): any
	local total = 0
	for _, item in list do
		total += item.Weight
	end
	local roll = (rng or Random.new()):NextNumber() * total
	for _, item in list do
		roll -= item.Weight
		if roll <= 0 then
			return item
		end
	end
	return list[1]
end

return Util
