-- Interface principal: dinheiro, renda, velocidade, aviso de carregando,
-- notificações e anúncios de kaijus raros.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local player = Players.LocalPlayer

local HUD = {}

local FONT = Enum.Font.FredokaOne
local KIND_COLORS = {
	info = Color3.fromRGB(60, 140, 255),
	success = Color3.fromRGB(50, 200, 90),
	warn = Color3.fromRGB(255, 90, 70),
	cash = Color3.fromRGB(40, 180, 70),
	announce = Color3.fromRGB(255, 170, 0),
}

local function corner(parent: Instance, radius: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
end

local function stroke(parent: Instance, thickness: number, color: Color3?)
	local s = Instance.new("UIStroke")
	s.Thickness = thickness
	s.Color = color or Color3.new(0, 0, 0)
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
end

local function text(parent: Instance, props: { [string]: any }): TextLabel
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Font = FONT
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	for k, v in props do
		(label :: any)[k] = v
	end
	local s = Instance.new("UIStroke")
	s.Thickness = 2
	s.Parent = label
	label.Parent = parent
	return label
end

local function pill(parent: Instance, name: string, color: Color3, position: UDim2, size: UDim2): Frame
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.AnchorPoint = Vector2.new(0.5, 0)
	frame.Position = position
	frame.Size = size
	frame.BackgroundColor3 = color
	corner(frame, 14)
	stroke(frame, 3)
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 90
	gradient.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(0.75, 0.75, 0.75))
	gradient.Parent = frame
	frame.Parent = parent
	return frame
end

function HUD.start()
	local gui = Instance.new("ScreenGui")
	gui.Name = "HUD"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = player:WaitForChild("PlayerGui")

	-- dinheiro
	local cashPill = pill(gui, "Cash", Color3.fromRGB(60, 200, 90), UDim2.new(0.5, 0, 0, 8), UDim2.fromOffset(240, 52))
	local cashScale = Instance.new("UIScale")
	cashScale.Parent = cashPill
	local cashLabel = text(cashPill, {
		Size = UDim2.new(1, -16, 1, -8),
		Position = UDim2.fromOffset(8, 4),
		Text = "💰 $0",
	})
	local incomeLabel = text(gui, {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 62),
		Size = UDim2.fromOffset(200, 24),
		TextColor3 = Color3.fromRGB(150, 255, 160),
		Text = "+$0/s",
	})

	-- velocidade
	local speedPill =
		pill(gui, "Speed", Color3.fromRGB(255, 190, 40), UDim2.new(0, 110, 0.5, -26), UDim2.fromOffset(190, 44))
	speedPill.AnchorPoint = Vector2.new(0.5, 0.5)
	local speedLabel = text(speedPill, {
		Size = UDim2.new(1, -12, 1, -8),
		Position = UDim2.fromOffset(6, 4),
		Text = "⚡ 16",
	})

	local nextLabel = text(gui, {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0, 110, 0.5, 0),
		Size = UDim2.fromOffset(210, 20),
		TextColor3 = Color3.fromRGB(255, 225, 140),
		Text = "",
	})

	-- carregando
	local carry = pill(gui, "Carry", Color3.fromRGB(255, 120, 40), UDim2.new(0.5, 0, 0, 94), UDim2.fromOffset(460, 44))
	carry.Visible = false
	local carryLabel = text(carry, {
		Size = UDim2.new(1, -16, 1, -8),
		Position = UDim2.fromOffset(8, 4),
	})

	-- anúncio grande
	local announce =
		pill(gui, "Announce", Color3.fromRGB(255, 170, 0), UDim2.new(0.5, 0, 0.22, 0), UDim2.new(0.7, 0, 0, 64))
	announce.Visible = false
	local announceSize = Instance.new("UISizeConstraint")
	announceSize.MaxSize = Vector2.new(720, 64)
	announceSize.Parent = announce
	local announceLabel = text(announce, {
		Size = UDim2.new(1, -20, 1, -10),
		Position = UDim2.fromOffset(10, 5),
	})
	local rainbow = Instance.new("UIGradient")
	rainbow.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 90, 90)),
		ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 230, 80)),
		ColorSequenceKeypoint.new(0.66, Color3.fromRGB(90, 220, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 110, 255)),
	})
	rainbow.Parent = announceLabel

	-- notificações (empilhadas em baixo)
	local toasts = Instance.new("Frame")
	toasts.Name = "Toasts"
	toasts.AnchorPoint = Vector2.new(0.5, 1)
	toasts.Position = UDim2.new(0.5, 0, 1, -90)
	toasts.Size = UDim2.new(0.8, 0, 0, 200)
	toasts.BackgroundTransparency = 1
	toasts.Parent = gui
	local layout = Instance.new("UIListLayout")
	layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Padding = UDim.new(0, 6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = toasts
	local toastOrder = 0

	local function toast(message: string, kind: string)
		toastOrder += 1
		local frame = Instance.new("Frame")
		frame.Size = UDim2.new(1, 0, 0, 36)
		frame.BackgroundColor3 = KIND_COLORS[kind] or KIND_COLORS.info
		frame.BackgroundTransparency = 0.1
		frame.LayoutOrder = toastOrder
		corner(frame, 10)
		stroke(frame, 2)
		local sizeLimit = Instance.new("UISizeConstraint")
		sizeLimit.MaxSize = Vector2.new(560, 36)
		sizeLimit.Parent = frame
		text(frame, { Size = UDim2.new(1, -16, 1, -8), Position = UDim2.fromOffset(8, 4), Text = message })
		frame.Parent = toasts

		local items = {}
		for _, child in toasts:GetChildren() do
			if child:IsA("Frame") then
				table.insert(items, child)
			end
		end
		table.sort(items, function(a, b)
			return a.LayoutOrder < b.LayoutOrder
		end)
		for i = 1, #items - 4 do
			items[i]:Destroy()
		end

		task.delay(if kind == "cash" then 1.8 else 3.5, function()
			if frame.Parent then
				local tween = TweenService:Create(frame, TweenInfo.new(0.3), { BackgroundTransparency = 1 })
				tween:Play()
				tween.Completed:Wait()
				frame:Destroy()
			end
		end)
	end

	local announceToken = 0
	local function showAnnouncement(message: string)
		announceToken += 1
		local token = announceToken
		announceLabel.Text = message
		announce.Visible = true
		announce.Size = UDim2.new(0.7, 0, 0, 0)
		TweenService:Create(announce, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Size = UDim2.new(0.7, 0, 0, 64) })
			:Play()
		task.spawn(function()
			local t = 0
			while announceToken == token and t < 5 do
				t += task.wait()
				rainbow.Offset = Vector2.new(math.sin(t * 2) * 0.3, 0)
			end
			if announceToken == token then
				announce.Visible = false
			end
		end)
	end

	-- ligações com os atributos do jogador
	local lastCash = 0
	local function updateCash()
		local cash = player:GetAttribute("Cash") or 0
		cashLabel.Text = "💰 " .. Format.money(cash)
		if cash > lastCash then
			cashScale.Scale = 1.15
			TweenService:Create(cashScale, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Scale = 1 }):Play()
		end
		lastCash = cash
	end
	local function updateIncome()
		incomeLabel.Text = "+" .. Format.money(player:GetAttribute("Income") or 0) .. "/s"
	end
	local function updateSpeed()
		local speed = math.floor(Config.BaseWalkSpeed + (player:GetAttribute("SpeedStat") or 0))
		local nextZone
		for _, zone in Config.Zones do
			if zone.RequiredSpeed > speed then
				nextZone = zone
				break
			end
		end
		speedLabel.Text = "⚡ Velocidade " .. speed
		nextLabel.Text = if nextZone
			then string.format("Próxima zona: %s (%d)", nextZone.Name, nextZone.RequiredSpeed)
			else "Todas as zonas liberadas!"
	end
	local function updateCarry()
		local carrying = player:GetAttribute("Carrying") or ""
		carry.Visible = carrying ~= ""
		carryLabel.Text = "🦖 " .. carrying .. " — leve para a sua base!"
	end

	player:GetAttributeChangedSignal("Cash"):Connect(updateCash)
	player:GetAttributeChangedSignal("Income"):Connect(updateIncome)
	player:GetAttributeChangedSignal("SpeedStat"):Connect(updateSpeed)
	player:GetAttributeChangedSignal("Carrying"):Connect(updateCarry)
	updateCash()
	updateIncome()
	updateSpeed()
	updateCarry()

	Remotes.get("Notify").OnClientEvent:Connect(function(message: string, kind: string)
		if kind == "announce" then
			showAnnouncement(message)
		else
			toast(message, kind)
		end
	end)
end

return HUD
