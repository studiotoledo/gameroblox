-- Controles extras: correr sozinho na esteira (animação + sair pulando ou pelo botão)
-- e largar o kaiju carregado (tecla G ou botão).

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Remotes = require(ReplicatedStorage.Shared.Remotes)

local player = Players.LocalPlayer
local treadmillRemote = Remotes.get("Treadmill")
local dropRemote = Remotes.get("DropKaiju")

local Controls = {}

-- animações de corrida padrão do Roblox, usadas se o Animate do personagem não tiver uma
local DEFAULT_RUN = {
	[Enum.HumanoidRigType.R15] = "rbxassetid://913376220",
	[Enum.HumanoidRigType.R6] = "rbxassetid://180426354",
}

local runTrack: AnimationTrack? = nil

local function stopRun()
	if runTrack then
		runTrack:Stop(0.2)
		runTrack = nil
	end
end

local function playRun()
	stopRun()
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local animator = hum and hum:FindFirstChildOfClass("Animator")
	if not hum or not animator then
		return
	end
	local animation: Animation? = nil
	local animate = char:FindFirstChild("Animate")
	local run = animate and animate:FindFirstChild("run")
	local existing = run and run:FindFirstChildOfClass("Animation")
	if existing then
		animation = existing
	else
		local a = Instance.new("Animation")
		a.AnimationId = DEFAULT_RUN[hum.RigType] or DEFAULT_RUN[Enum.HumanoidRigType.R15]
		animation = a
	end
	local track = animator:LoadAnimation(animation :: Animation)
	track.Priority = Enum.AnimationPriority.Movement
	track.Looped = true
	track:Play(0.2)
	track:AdjustSpeed(1.4)
	runTrack = track
end

local function button(parent: Instance, text: string, color: Color3, position: UDim2): TextButton
	local b = Instance.new("TextButton")
	b.AnchorPoint = Vector2.new(0.5, 1)
	b.Position = position
	b.Size = UDim2.fromOffset(240, 48)
	b.BackgroundColor3 = color
	b.Font = Enum.Font.FredokaOne
	b.TextScaled = true
	b.TextColor3 = Color3.new(1, 1, 1)
	b.Text = text
	b.Visible = false
	b.AutoButtonColor = true
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = b
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = b
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 8)
	padding.PaddingBottom = UDim.new(0, 8)
	padding.Parent = b
	b.Parent = parent
	return b
end

function Controls.start()
	local gui = Instance.new("ScreenGui")
	gui.Name = "Controls"
	gui.ResetOnSpawn = false
	gui.Parent = player:WaitForChild("PlayerGui")

	local stopButton = button(gui, "🏃 Parar de correr", Color3.fromRGB(255, 150, 40), UDim2.new(0.5, 0, 1, -140))
	local dropButton = button(gui, "✋ Largar kaiju (G)", Color3.fromRGB(230, 70, 70), UDim2.new(0.5, 0, 1, -140))

	local function requestStop()
		if player:GetAttribute("Training") then
			treadmillRemote:FireServer("stop")
		end
	end
	local function requestDrop()
		if (player:GetAttribute("Carrying") or "") ~= "" then
			dropRemote:FireServer()
		end
	end

	stopButton.Activated:Connect(requestStop)
	dropButton.Activated:Connect(requestDrop)
	UserInputService.JumpRequest:Connect(requestStop)
	ContextActionService:BindAction("LargarKaiju", function(_, state)
		if state == Enum.UserInputState.Begin then
			requestDrop()
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.G, Enum.KeyCode.ButtonB)

	local function refresh()
		local isTraining = player:GetAttribute("Training") == true
		local isCarrying = (player:GetAttribute("Carrying") or "") ~= ""
		stopButton.Visible = isTraining
		dropButton.Visible = isCarrying and not isTraining
		if isTraining and not runTrack then
			playRun()
		elseif not isTraining and runTrack then
			stopRun()
		end
	end
	player:GetAttributeChangedSignal("Training"):Connect(refresh)
	player:GetAttributeChangedSignal("Carrying"):Connect(refresh)
	player.CharacterAdded:Connect(function()
		runTrack = nil
		task.defer(refresh)
	end)
	refresh()
end

return Controls
