-- Mostra onde fica a base do jogador: uma placa "SUA BASE" visível de longe
-- e, enquanto ele carrega um kaiju, uma linha brilhante ligando ele até a base.

local Players = game:GetService("Players")

local player = Players.LocalPlayer

local BaseMarker = {}

local marker: BillboardGui? = nil
local target: Attachment? = nil
local beam: Beam? = nil

local function findPlot(): Model?
	local index = player:GetAttribute("PlotIndex")
	local map = workspace:FindFirstChild("Map")
	local plots = map and map:FindFirstChild("Plots")
	return if index and plots then plots:FindFirstChild("Plot" .. index) :: Model? else nil
end

local function setupPlot()
	if marker then
		marker:Destroy()
		marker = nil
	end
	if target then
		target:Destroy()
		target = nil
	end
	local plot = findPlot()
	local floor = plot and plot:FindFirstChild("Floor") :: BasePart?
	if not floor then
		return
	end

	local gui = Instance.new("BillboardGui")
	gui.Name = "SuaBase"
	gui.Size = UDim2.fromOffset(200, 64)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 26, 0)
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.MaxDistance = 100000
	gui.Adornee = floor
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.Text = "🏠 SUA BASE"
	label.TextColor3 = Color3.fromRGB(120, 255, 140)
	label.TextStrokeTransparency = 0
	label.Parent = gui
	gui.Parent = player:WaitForChild("PlayerGui")
	marker = gui

	local attachment = Instance.new("Attachment")
	attachment.Name = "SuaBaseTarget"
	attachment.Position = Vector3.new(0, 2, 0)
	attachment.Parent = floor
	target = attachment
end

local function refreshBeam()
	if beam then
		beam:Destroy()
		beam = nil
	end
	local carrying = (player:GetAttribute("Carrying") or "") ~= ""
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not carrying or not hrp or not target then
		return
	end
	local from = hrp:FindFirstChild("SuaBaseFrom") :: Attachment?
	if not from then
		local attachment = Instance.new("Attachment")
		attachment.Name = "SuaBaseFrom"
		attachment.Parent = hrp
		from = attachment
	end
	local b = Instance.new("Beam")
	b.Attachment0 = from
	b.Attachment1 = target
	b.FaceCamera = true
	b.Width0 = 0.8
	b.Width1 = 0.8
	b.LightEmission = 1
	b.Color = ColorSequence.new(Color3.fromRGB(120, 255, 140))
	b.Transparency = NumberSequence.new(0.2)
	b.Segments = 1
	b.Parent = hrp
	beam = b
end

function BaseMarker.start()
	player:GetAttributeChangedSignal("PlotIndex"):Connect(function()
		setupPlot()
		refreshBeam()
	end)
	player:GetAttributeChangedSignal("Carrying"):Connect(refreshBeam)
	player.CharacterAdded:Connect(function(char)
		char:WaitForChild("HumanoidRootPart", 10)
		refreshBeam()
	end)
	task.spawn(function()
		-- o mapa é criado pelo servidor; espera ele existir
		workspace:WaitForChild("Map"):WaitForChild("Plots")
		setupPlot()
		refreshBeam()
	end)
end

return BaseMarker
