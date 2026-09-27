-- Esconde prompts que não fazem sentido para este jogador
-- (ex.: "Roubar" o próprio kaiju, ou "Vender" o kaiju de outra pessoa).
-- O servidor nunca mexe em ProximityPrompt.Enabled; quem decide aqui é o cliente,
-- e o servidor valida tudo de novo quando o prompt é acionado.

local Players = game:GetService("Players")

local player = Players.LocalPlayer

local PromptFilter = {}
local tracked: { [ProximityPrompt]: boolean } = {}

local function evaluate(prompt: ProximityPrompt)
	local enabled = true
	local only = prompt:GetAttribute("OnlyUserId")
	local except = prompt:GetAttribute("ExceptUserId")
	if only ~= nil and only ~= player.UserId then
		enabled = false
	end
	if except ~= nil and except == player.UserId then
		enabled = false
	end
	if prompt:GetAttribute("Kind") == "Steal" and (player:GetAttribute("Carrying") or "") ~= "" then
		enabled = false
	end
	prompt.Enabled = enabled
end

local function track(inst: Instance)
	if not inst:IsA("ProximityPrompt") or tracked[inst] then
		return
	end
	tracked[inst] = true
	evaluate(inst)
	inst.AttributeChanged:Connect(function()
		evaluate(inst)
	end)
	inst.Destroying:Connect(function()
		tracked[inst] = nil
	end)
	inst.AncestryChanged:Connect(function(_, parent)
		if parent == nil then
			tracked[inst] = nil
		end
	end)
end

function PromptFilter.start()
	workspace.DescendantAdded:Connect(track)
	for _, inst in workspace:GetDescendants() do
		track(inst)
	end
	player:GetAttributeChangedSignal("Carrying"):Connect(function()
		for prompt in tracked do
			evaluate(prompt)
		end
	end)
end

return PromptFilter
