-- Envia mensagens (toasts) para a interface dos jogadores.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)

local remote = Remotes.get("Notify")

local Notify = {}

-- kind: "info" | "success" | "warn" | "cash" | "announce"
function Notify.send(player: Player, text: string, kind: string?)
	remote:FireClient(player, text, kind or "info")
end

function Notify.all(text: string, kind: string?)
	remote:FireAllClients(text, kind or "info")
end

return Notify
