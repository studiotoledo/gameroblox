-- Interface principal no estilo dos jogos "Steal a ...":
-- topo: Comprar / Base / Vender; esquerda: modo lento, dinheiro, velocidade e ganhos;
-- direita: Índice, Renascimento e Presentes; embaixo: bônus, diário e próximo evento.
-- Também mostra o aviso de carregando, notificações e anúncios.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local KaijuData = require(ReplicatedStorage.Shared.KaijuData)
local KaijuModel = require(ReplicatedStorage.Shared.KaijuModel)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local player = Players.LocalPlayer
local actionRemote = Remotes.get("Action")

local HUD = {}

local FONT = Enum.Font.FredokaOne
local WHITE = Color3.new(1, 1, 1)
local BLACK = Color3.new(0, 0, 0)
local COLORS = {
	blue = Color3.fromRGB(60, 160, 255),
	green = Color3.fromRGB(80, 200, 90),
	red = Color3.fromRGB(235, 80, 70),
	purple = Color3.fromRGB(170, 90, 255),
	orange = Color3.fromRGB(255, 160, 40),
	yellow = Color3.fromRGB(255, 205, 40),
	gray = Color3.fromRGB(120, 130, 140),
	panel = Color3.fromRGB(35, 40, 55),
	row = Color3.fromRGB(55, 62, 82),
}
local TOAST_COLORS = {
	info = COLORS.blue,
	success = COLORS.green,
	warn = COLORS.red,
	announce = COLORS.orange,
}

local function action(name: string, arg: any?)
	actionRemote:FireServer(name, arg)
end

---------------------------------------------------------------------------
-- Blocos de construção
---------------------------------------------------------------------------

local function corner(parent: Instance, radius: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
end

local function outline(parent: Instance, thickness: number)
	local s = Instance.new("UIStroke")
	s.Thickness = thickness
	s.Color = BLACK
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
end

local function shade(parent: Instance)
	local g = Instance.new("UIGradient")
	g.Rotation = 90
	g.Color = ColorSequence.new(WHITE, Color3.fromRGB(175, 175, 175))
	g.Parent = parent
end

local function label(parent: Instance, props: { [string]: any }): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Font = FONT
	l.TextScaled = true
	l.TextColor3 = WHITE
	for k, v in props do
		if k ~= "StrokeThickness" then
			(l :: any)[k] = v
		end
	end
	local thickness = props.StrokeThickness or 2.5
	if thickness > 0 then
		local s = Instance.new("UIStroke")
		s.Thickness = thickness
		s.Parent = l
	end
	l.Parent = parent
	return l
end

-- Botão "gordinho": cor de fundo com sombreado, contorno preto e texto com contorno.
local function chunkyButton(parent: Instance, text: string, color: Color3, size: UDim2, textSize: UDim2?): TextButton
	local b = Instance.new("TextButton")
	b.Size = size
	b.BackgroundColor3 = color
	b.Text = ""
	b.AutoButtonColor = true
	corner(b, 12)
	outline(b, 3)
	shade(b)
	label(b, {
		Name = "Label",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = textSize or UDim2.fromScale(0.86, 0.7),
		Text = text,
		StrokeThickness = 3,
	})
	b.Parent = parent
	return b
end

local function badge(parent: Instance): TextLabel
	local frame = Instance.new("Frame")
	frame.Name = "Badge"
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.new(1, -6, 0, 6)
	frame.Size = UDim2.fromOffset(34, 34)
	frame.BackgroundColor3 = COLORS.red
	frame.Visible = false
	frame.ZIndex = 5
	corner(frame, 17)
	outline(frame, 2)
	local text =
		label(frame, { Size = UDim2.fromScale(0.8, 0.8), Position = UDim2.fromScale(0.1, 0.1), Text = "!", ZIndex = 6 })
	frame.Parent = parent
	return text
end

-- Botão quadrado com ícone (emoji) e nome embaixo, como "Índice" e "Loja" da referência.
local function iconButton(parent: Instance, icon: string, name: string, color: Color3, order: number): TextButton
	local b = Instance.new("TextButton")
	b.Size = UDim2.fromOffset(104, 104)
	b.BackgroundColor3 = color
	b.Text = ""
	b.LayoutOrder = order
	corner(b, 16)
	outline(b, 3)
	shade(b)
	label(
		b,
		{ Position = UDim2.fromScale(0.15, 0.06), Size = UDim2.fromScale(0.7, 0.6), Text = icon, StrokeThickness = 0 }
	)
	label(
		b,
		{
			Position = UDim2.fromScale(0.04, 0.66),
			Size = UDim2.fromScale(0.92, 0.3),
			Text = name,
			StrokeThickness = 2.5,
		}
	)
	b.Parent = parent
	return b
end

local function roundButton(parent: Instance, icon: string, color: Color3, order: number): (TextButton, TextLabel)
	local b = Instance.new("TextButton")
	b.Size = UDim2.fromOffset(76, 76)
	b.BackgroundColor3 = color
	b.Text = ""
	b.LayoutOrder = order
	corner(b, 38)
	outline(b, 3)
	shade(b)
	label(
		b,
		{ Position = UDim2.fromScale(0.2, 0.08), Size = UDim2.fromScale(0.6, 0.55), Text = icon, StrokeThickness = 0 }
	)
	local sub = label(b, { Position = UDim2.fromScale(0.1, 0.6), Size = UDim2.fromScale(0.8, 0.32), Text = "" })
	b.Parent = parent
	return b, sub
end

---------------------------------------------------------------------------
-- Painéis (janelas)
---------------------------------------------------------------------------

local panels: { [string]: { Frame: Frame, Content: ScrollingFrame, Refresh: () -> () } } = {}
local openName: string? = nil

local function closePanels()
	for _, p in panels do
		p.Frame.Visible = false
	end
	openName = nil
end

local function togglePanel(name: string)
	if openName == name then
		closePanels()
		return
	end
	closePanels()
	local p = panels[name]
	p.Frame.Visible = true
	openName = name
	p.Refresh()
end

local function createPanel(root: Instance, name: string, title: string, color: Color3, refresh: (ScrollingFrame) -> ())
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.52)
	frame.Size = UDim2.fromOffset(600, 470)
	frame.BackgroundColor3 = COLORS.panel
	frame.Visible = false
	frame.ZIndex = 10
	corner(frame, 18)
	outline(frame, 4)

	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0, 64)
	header.BackgroundColor3 = color
	header.ZIndex = 10
	corner(header, 18)
	shade(header)
	header.Parent = frame
	label(header, {
		Position = UDim2.fromOffset(20, 10),
		Size = UDim2.new(1, -100, 0, 44),
		Text = title,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 11,
	})

	local close = chunkyButton(frame, "X", COLORS.red, UDim2.fromOffset(52, 52))
	close.Position = UDim2.new(1, -60, 0, 6)
	close.ZIndex = 12
	close.Activated:Connect(closePanels)

	local content = Instance.new("ScrollingFrame")
	content.Position = UDim2.fromOffset(16, 76)
	content.Size = UDim2.new(1, -32, 1, -90)
	content.BackgroundTransparency = 1
	content.BorderSizePixel = 0
	content.ScrollBarThickness = 8
	content.AutomaticCanvasSize = Enum.AutomaticSize.Y
	content.CanvasSize = UDim2.new()
	content.ZIndex = 10
	content.Parent = frame
	frame.Parent = root

	panels[name] = {
		Frame = frame,
		Content = content,
		Refresh = function()
			refresh(content)
		end,
	}
end

local function clearContent(content: ScrollingFrame, layout: string?)
	for _, child in content:GetChildren() do
		child:Destroy()
	end
	if layout == "grid" then
		local grid = Instance.new("UIGridLayout")
		grid.CellSize = UDim2.fromOffset(170, 190)
		grid.CellPadding = UDim2.fromOffset(12, 12)
		grid.SortOrder = Enum.SortOrder.LayoutOrder
		grid.Parent = content
	else
		local list = Instance.new("UIListLayout")
		list.Padding = UDim.new(0, 10)
		list.SortOrder = Enum.SortOrder.LayoutOrder
		list.Parent = content
	end
end

-- Linha com texto à esquerda e um botão à direita.
local function row(
	content: Instance,
	order: number,
	title: string,
	subtitle: string,
	buttonText: string?,
	buttonColor: Color3?,
	onClick: (() -> ())?
): TextButton?
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, -12, 0, 78)
	frame.BackgroundColor3 = COLORS.row
	frame.LayoutOrder = order
	frame.ZIndex = 10
	corner(frame, 12)
	label(frame, {
		Position = UDim2.fromOffset(14, 8),
		Size = UDim2.new(0.62, -14, 0, 34),
		Text = title,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 11,
	})
	label(frame, {
		Position = UDim2.fromOffset(14, 44),
		Size = UDim2.new(0.62, -14, 0, 24),
		Text = subtitle,
		TextColor3 = Color3.fromRGB(200, 210, 230),
		TextXAlignment = Enum.TextXAlignment.Left,
		StrokeThickness = 1.5,
		ZIndex = 11,
	})
	local button: TextButton? = nil
	if buttonText then
		local b = chunkyButton(frame, buttonText, buttonColor or COLORS.green, UDim2.new(0.36, 0, 0, 56))
		b.AnchorPoint = Vector2.new(1, 0.5)
		b.Position = UDim2.new(1, -10, 0.5, 0)
		b.ZIndex = 11
		for _, d in b:GetDescendants() do
			if d:IsA("GuiObject") then
				d.ZIndex = 12
			end
		end
		if onClick then
			b.Activated:Connect(onClick)
		end
		button = b
	end
	frame.Parent = content
	return button
end

local function note(content: Instance, order: number, text: string)
	label(content, {
		Size = UDim2.new(1, -12, 0, 26),
		LayoutOrder = order,
		Text = text,
		TextColor3 = Color3.fromRGB(210, 220, 240),
		StrokeThickness = 1.5,
		ZIndex = 11,
	})
end

---------------------------------------------------------------------------
-- Conteúdo de cada painel
---------------------------------------------------------------------------

local function refreshBuy(content: ScrollingFrame)
	clearContent(content)
	local level = player:GetAttribute("TreadmillLevel") or 0
	local slots = player:GetAttribute("SlotsUnlocked") or Config.StartingSlots
	if level >= Config.Treadmill.MaxLevel then
		row(
			content,
			1,
			"⚡ Esteira (máximo)",
			string.format("Nível %d • +%.2f velocidade/s", level + 1, Config.treadmillRate(level))
		)
	else
		row(
			content,
			1,
			string.format("⚡ Esteira Nv.%d → %d", level + 1, level + 2),
			string.format("+%.2f → +%.2f velocidade/s", Config.treadmillRate(level), Config.treadmillRate(level + 1)),
			Format.money(Config.treadmillCost(level)),
			COLORS.green,
			function()
				action("buy_treadmill")
				task.delay(0.3, panels.buy.Refresh)
			end
		)
	end
	local slotCost = Config.SlotUnlockCosts[slots - Config.StartingSlots + 1]
	if slotCost then
		row(
			content,
			2,
			"🏠 Novo espaço na base",
			string.format("%d de %d espaços liberados", slots, Config.SlotCount),
			Format.money(slotCost),
			COLORS.green,
			function()
				action("buy_slot")
				task.delay(0.3, panels.buy.Refresh)
			end
		)
	else
		row(content, 2, "🏠 Espaços da base", "Todos os espaços liberados!")
	end
	note(content, 3, "Treine na esteira para liberar zonas mais distantes.")
end

local function ownKaijus(): { Model }
	local list = {}
	local folder = workspace:FindFirstChild("Kaijus")
	if not folder then
		return list
	end
	for _, model in folder:GetChildren() do
		if model:GetAttribute("State") == "Slot" and model:GetAttribute("OwnerUserId") == player.UserId then
			table.insert(list, model :: Model)
		end
	end
	table.sort(list, function(a, b)
		return (a:GetAttribute("Income") or 0) > (b:GetAttribute("Income") or 0)
	end)
	return list
end

local confirmSellAll = false
local function refreshSell(content: ScrollingFrame)
	clearContent(content)
	local list = ownKaijus()
	if #list == 0 then
		note(content, 1, "Você ainda não tem kaijus na base.")
		return
	end
	local total = 0
	for i, model in list do
		local value = model:GetAttribute("SellValue") or 0
		total += value
		local uid = model:GetAttribute("KaijuUid")
		row(
			content,
			i + 1,
			model:GetAttribute("KaijuName") or model.Name,
			string.format(
				"%s • %s • %s/s",
				model:GetAttribute("Rarity") or "",
				model:GetAttribute("StageName") or "",
				Format.money(model:GetAttribute("Income") or 0)
			),
			"Vender " .. Format.money(value),
			COLORS.red,
			function()
				action("sell", uid)
				task.delay(0.3, panels.sell.Refresh)
			end
		)
	end
	row(
		content,
		1,
		"Vender todos",
		string.format("%d kaijus • %s", #list, Format.money(total)),
		if confirmSellAll then "Confirmar?" else "Vender tudo",
		COLORS.orange,
		function()
			if confirmSellAll then
				confirmSellAll = false
				action("sellall")
				task.delay(0.3, panels.sell.Refresh)
			else
				confirmSellAll = true
				panels.sell.Refresh()
				task.delay(3, function()
					confirmSellAll = false
				end)
			end
		end
	)
end

local function discoveredSet(): { [string]: boolean }
	local set = {}
	for id in string.gmatch(player:GetAttribute("Discovered") or "", "[^,]+") do
		set[id] = true
	end
	return set
end

local function refreshIndex(content: ScrollingFrame)
	clearContent(content, "grid")
	local known = discoveredSet()
	local order = 0
	for _, def in KaijuData.List do
		order += 1
		local found = known[def.Id] == true
		local rarity = Config.Rarities[def.Rarity]
		local cell = Instance.new("Frame")
		cell.BackgroundColor3 = COLORS.row
		cell.LayoutOrder = order
		cell.ZIndex = 10
		corner(cell, 12)
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 3
		stroke.Color = if found then rarity.Color else Color3.fromRGB(70, 75, 90)
		stroke.Parent = cell

		local viewport = Instance.new("ViewportFrame")
		viewport.Position = UDim2.fromOffset(8, 8)
		viewport.Size = UDim2.new(1, -16, 0, 120)
		viewport.BackgroundTransparency = 1
		viewport.ZIndex = 11
		viewport.Ambient = Color3.fromRGB(200, 200, 200)
		viewport.LightDirection = Vector3.new(-1, -1, -1)
		local model = KaijuModel.build(def, "Normal")
		for _, d in model:GetDescendants() do
			if d:IsA("ParticleEmitter") or d:IsA("PointLight") then
				d:Destroy()
			elseif d:IsA("BasePart") and not found then
				d.Color = Color3.fromRGB(15, 15, 20)
				d.Material = Enum.Material.SmoothPlastic
				d.Transparency = if d.Name == "Root" then 1 else 0
			end
		end
		model:PivotTo(CFrame.Angles(0, math.rad(200), 0))
		model.Parent = viewport
		local camera = Instance.new("Camera")
		local size = model:GetExtentsSize()
		local distance = math.max(size.X, size.Y, size.Z) * 1.7
		camera.CFrame =
			CFrame.lookAt(Vector3.new(distance * 0.5, size.Y * 0.8, -distance), Vector3.new(0, size.Y * 0.45, 0))
		camera.FieldOfView = 40
		camera.Parent = viewport
		viewport.CurrentCamera = camera
		viewport.Parent = cell

		label(cell, {
			Position = UDim2.fromOffset(6, 130),
			Size = UDim2.new(1, -12, 0, 28),
			Text = if found then def.Name else "???",
			ZIndex = 11,
		})
		label(cell, {
			Position = UDim2.fromOffset(6, 158),
			Size = UDim2.new(1, -12, 0, 22),
			Text = def.Rarity,
			TextColor3 = rarity.Color,
			StrokeThickness = 2,
			ZIndex = 11,
		})
		cell.Parent = content
	end
end

local function refreshRebirth(content: ScrollingFrame)
	clearContent(content)
	local rebirths = player:GetAttribute("Rebirths") or 0
	local cost = Config.rebirthCost(rebirths)
	local bonusNow = rebirths * Config.Rebirth.IncomeBonus * 100
	local bonusNext = (rebirths + 1) * Config.Rebirth.IncomeBonus * 100
	row(
		content,
		1,
		string.format("🔄 Renascimentos: %d", rebirths),
		string.format("Bônus de renda atual: +%d%%", bonusNow)
	)
	row(
		content,
		2,
		string.format("Próximo: +%d%% de renda", bonusNext),
		"Custa " .. Format.money(cost),
		"Renascer",
		if (player:GetAttribute("Cash") or 0) >= cost then COLORS.purple else COLORS.gray,
		function()
			action("rebirth")
			task.delay(0.3, panels.rebirth.Refresh)
		end
	)
	note(content, 3, "Zera: dinheiro, velocidade e nível da esteira.")
	note(content, 4, "Mantém: seus kaijus, espaços da base e o Índice.")
end

local function giftSecondsLeft(): number
	return math.max(0, (player:GetAttribute("GiftReadyAt") or math.huge) - os.time())
end

local function refreshGift(content: ScrollingFrame)
	clearContent(content)
	local left = giftSecondsLeft()
	local reward =
		math.max(Config.GiftMinimum, math.floor((player:GetAttribute("Income") or 0) * Config.GiftIncomeSeconds))
	if left <= 0 then
		row(
			content,
			1,
			"🎁 Presente pronto!",
			"Vale cerca de " .. Format.money(reward),
			"Abrir",
			COLORS.green,
			function()
				action("gift")
				task.delay(0.3, panels.gift.Refresh)
			end
		)
	else
		row(content, 1, "🎁 Próximo presente", "Fica pronto em " .. Format.time(left))
	end
	note(content, 2, string.format("Um presente grátis a cada %d minutos jogando.", Config.GiftInterval // 60))
end

local function refreshDaily(content: ScrollingFrame)
	clearContent(content)
	local ready = player:GetAttribute("DailyReady") == true
	local streak = player:GetAttribute("DailyStreak") or 0
	local nextDay = math.min(streak + 1, Config.DailyMaxStreak)
	local base =
		math.max(Config.DailyMinimum, math.floor((player:GetAttribute("Income") or 0) * Config.DailyIncomeSeconds))
	if ready then
		row(
			content,
			1,
			string.format("📅 Dia %d", streak + 1),
			"Recompensa: " .. Format.money(base * nextDay),
			"Resgatar",
			COLORS.green,
			function()
				action("daily")
				task.delay(0.3, panels.daily.Refresh)
			end
		)
	else
		row(
			content,
			1,
			string.format("📅 Sequência: %d dia(s)", streak),
			"Volte amanhã para a próxima recompensa!"
		)
	end
	note(content, 2, string.format("Cada dia seguido aumenta o prêmio (até %dx).", Config.DailyMaxStreak))
end

---------------------------------------------------------------------------
-- Montagem da tela
---------------------------------------------------------------------------

function HUD.start()
	local gui = Instance.new("ScreenGui")
	gui.Name = "HUD"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = player:WaitForChild("PlayerGui")
	local toast: (string, string) -> ()

	-- escala tudo conforme a altura da tela (celular fica menor)
	local scale = Instance.new("UIScale")
	scale.Parent = gui
	local function rescale()
		local camera = workspace.CurrentCamera
		local height = if camera then camera.ViewportSize.Y else 900
		scale.Scale = math.clamp(height / 1000, 0.5, 1.15)
	end
	rescale()
	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
	end

	-- topo: Comprar / Base / Vender
	local top = Instance.new("Frame")
	top.AnchorPoint = Vector2.new(0.5, 0)
	top.Position = UDim2.new(0.5, 0, 0, 12)
	top.Size = UDim2.fromOffset(740, 76)
	top.BackgroundTransparency = 1
	top.Parent = gui
	local topLayout = Instance.new("UIListLayout")
	topLayout.FillDirection = Enum.FillDirection.Horizontal
	topLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	topLayout.Padding = UDim.new(0, 20)
	topLayout.Parent = top
	chunkyButton(top, "Comprar", COLORS.blue, UDim2.fromOffset(230, 76)).Activated:Connect(function()
		togglePanel("buy")
	end)
	chunkyButton(top, "Base", COLORS.green, UDim2.fromOffset(230, 76)).Activated:Connect(function()
		closePanels()
		action("base")
	end)
	chunkyButton(top, "Vender", COLORS.red, UDim2.fromOffset(230, 76)).Activated:Connect(function()
		togglePanel("sell")
	end)

	-- esquerda: modo lento
	local slowTitle = label(gui, {
		Position = UDim2.fromOffset(28, 190),
		Size = UDim2.fromOffset(330, 32),
		Text = "Modo Lento [Q] - DESATIVADO",
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	local slowSwitch = Instance.new("TextButton")
	slowSwitch.Position = UDim2.fromOffset(30, 228)
	slowSwitch.Size = UDim2.fromOffset(104, 50)
	slowSwitch.Text = ""
	slowSwitch.BackgroundColor3 = COLORS.gray
	corner(slowSwitch, 10)
	outline(slowSwitch, 3)
	local knob = Instance.new("Frame")
	knob.Size = UDim2.fromOffset(40, 40)
	knob.Position = UDim2.fromOffset(5, 5)
	knob.BackgroundColor3 = WHITE
	corner(knob, 8)
	knob.Parent = slowSwitch
	slowSwitch.Parent = gui
	slowSwitch.Activated:Connect(function()
		action("slowmode")
	end)

	-- esquerda: ganhos subindo, dinheiro e velocidade
	local gains = Instance.new("Frame")
	gains.Position = UDim2.fromOffset(40, 300)
	gains.Size = UDim2.fromOffset(300, 170)
	gains.BackgroundTransparency = 1
	gains.Parent = gui
	local gainsLayout = Instance.new("UIListLayout")
	gainsLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	gainsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	gainsLayout.Padding = UDim.new(0, 2)
	gainsLayout.Parent = gains
	local gainOrder = 0

	label(
		gui,
		{ Position = UDim2.fromOffset(24, 480), Size = UDim2.fromOffset(76, 70), Text = "💵", StrokeThickness = 0 }
	)
	local cashLabel = label(gui, {
		Position = UDim2.fromOffset(110, 478),
		Size = UDim2.fromOffset(360, 74),
		Text = "$0",
		TextColor3 = Color3.fromRGB(110, 255, 90),
		TextXAlignment = Enum.TextXAlignment.Left,
		StrokeThickness = 4,
	})
	local cashScale = Instance.new("UIScale")
	cashScale.Parent = cashLabel
	local incomeLabel = label(gui, {
		Position = UDim2.fromOffset(112, 550),
		Size = UDim2.fromOffset(300, 28),
		Text = "+$0/s",
		TextColor3 = Color3.fromRGB(180, 255, 170),
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	label(
		gui,
		{ Position = UDim2.fromOffset(24, 590), Size = UDim2.fromOffset(76, 70), Text = "⚡", StrokeThickness = 0 }
	)
	local speedLabel = label(gui, {
		Position = UDim2.fromOffset(110, 588),
		Size = UDim2.fromOffset(360, 74),
		Text = "16",
		TextColor3 = Color3.fromRGB(255, 205, 60),
		TextXAlignment = Enum.TextXAlignment.Left,
		StrokeThickness = 4,
	})
	local nextZoneLabel = label(gui, {
		Position = UDim2.fromOffset(112, 660),
		Size = UDim2.fromOffset(360, 26),
		Text = "",
		TextColor3 = Color3.fromRGB(255, 230, 150),
		TextXAlignment = Enum.TextXAlignment.Left,
	})

	-- direita: Índice, Renascimento, Presentes
	local right = Instance.new("Frame")
	right.AnchorPoint = Vector2.new(1, 0.5)
	right.Position = UDim2.new(1, -24, 0.5, 0)
	right.Size = UDim2.fromOffset(104, 340)
	right.BackgroundTransparency = 1
	right.Parent = gui
	local rightLayout = Instance.new("UIListLayout")
	rightLayout.Padding = UDim.new(0, 14)
	rightLayout.SortOrder = Enum.SortOrder.LayoutOrder
	rightLayout.Parent = right
	iconButton(right, "📖", "Índice", COLORS.blue, 1).Activated:Connect(function()
		togglePanel("index")
	end)
	iconButton(right, "🔄", "Renascer", COLORS.purple, 2).Activated:Connect(function()
		togglePanel("rebirth")
	end)
	local giftButton = iconButton(right, "🎁", "Presente", COLORS.red, 3)
	giftButton.Activated:Connect(function()
		togglePanel("gift")
	end)
	local giftBadge = badge(giftButton)

	-- embaixo à esquerda: bônus Premium, amigos e diário
	local bottomLeft = Instance.new("Frame")
	bottomLeft.AnchorPoint = Vector2.new(0, 1)
	bottomLeft.Position = UDim2.new(0, 24, 1, -20)
	bottomLeft.Size = UDim2.fromOffset(280, 80)
	bottomLeft.BackgroundTransparency = 1
	bottomLeft.Parent = gui
	local bottomLayout = Instance.new("UIListLayout")
	bottomLayout.FillDirection = Enum.FillDirection.Horizontal
	bottomLayout.Padding = UDim.new(0, 14)
	bottomLayout.SortOrder = Enum.SortOrder.LayoutOrder
	bottomLayout.Parent = bottomLeft
	local premiumButton, premiumText = roundButton(bottomLeft, "👑", COLORS.yellow, 1)
	local friendsButton, friendsText = roundButton(bottomLeft, "👥", COLORS.blue, 2)
	local dailyButton, dailyText = roundButton(bottomLeft, "📅", COLORS.orange, 3)
	local dailyBadge = badge(dailyButton)
	premiumButton.Activated:Connect(function()
		toast(string.format("Jogadores Premium ganham +%d%% de renda.", Config.PremiumBoost * 100), "info")
	end)
	friendsButton.Activated:Connect(function()
		toast(
			string.format(
				"+%d%% de renda por amigo no servidor (até +%d%%). Chame seus amigos!",
				Config.FriendBoost * 100,
				Config.MaxFriendBoost * 100
			),
			"info"
		)
	end)
	dailyButton.Activated:Connect(function()
		togglePanel("daily")
	end)

	-- embaixo à direita: próximo evento
	local eventLabel = label(gui, {
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -24, 1, -20),
		Size = UDim2.fromOffset(300, 70),
		Text = "",
		TextColor3 = Color3.fromRGB(255, 240, 200),
		TextXAlignment = Enum.TextXAlignment.Right,
		Font = Enum.Font.FredokaOne,
	})

	-- aviso de carregando
	local carry = Instance.new("Frame")
	carry.AnchorPoint = Vector2.new(0.5, 0)
	carry.Position = UDim2.new(0.5, 0, 0, 100)
	carry.Size = UDim2.fromOffset(520, 46)
	carry.BackgroundColor3 = COLORS.orange
	carry.Visible = false
	corner(carry, 12)
	outline(carry, 3)
	shade(carry)
	carry.Parent = gui
	local carryLabel = label(carry, { Size = UDim2.new(1, -20, 1, -10), Position = UDim2.fromOffset(10, 5) })

	-- anúncio grande
	local announce = Instance.new("Frame")
	announce.AnchorPoint = Vector2.new(0.5, 0)
	announce.Position = UDim2.new(0.5, 0, 0, 160)
	announce.Size = UDim2.fromOffset(760, 64)
	announce.BackgroundColor3 = COLORS.orange
	announce.Visible = false
	corner(announce, 14)
	outline(announce, 3)
	announce.Parent = gui
	local announceLabel = label(announce, { Size = UDim2.new(1, -24, 1, -12), Position = UDim2.fromOffset(12, 6) })
	local rainbow = Instance.new("UIGradient")
	rainbow.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 90, 90)),
		ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 230, 80)),
		ColorSequenceKeypoint.new(0.66, Color3.fromRGB(90, 220, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 110, 255)),
	})
	rainbow.Parent = announceLabel

	-- notificações (em cima da hotbar)
	local toasts = Instance.new("Frame")
	toasts.AnchorPoint = Vector2.new(0.5, 1)
	toasts.Position = UDim2.new(0.5, 0, 1, -200)
	toasts.Size = UDim2.fromOffset(620, 200)
	toasts.BackgroundTransparency = 1
	toasts.Parent = gui
	local toastLayout = Instance.new("UIListLayout")
	toastLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	toastLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	toastLayout.Padding = UDim.new(0, 6)
	toastLayout.SortOrder = Enum.SortOrder.LayoutOrder
	toastLayout.Parent = toasts
	local toastOrder = 0

	-- painéis
	createPanel(gui, "buy", "🛒 Comprar", COLORS.blue, refreshBuy)
	createPanel(gui, "sell", "💰 Vender", COLORS.red, refreshSell)
	createPanel(gui, "index", "📖 Índice", COLORS.blue, refreshIndex)
	createPanel(gui, "rebirth", "🔄 Renascimento", COLORS.purple, refreshRebirth)
	createPanel(gui, "gift", "🎁 Presente", COLORS.red, refreshGift)
	createPanel(gui, "daily", "📅 Recompensa diária", COLORS.orange, refreshDaily)

	---------------------------------------------------------------------------
	-- Comportamento
	---------------------------------------------------------------------------

	toast = function(message: string, kind: string)
		toastOrder += 1
		local frame = Instance.new("Frame")
		frame.Size = UDim2.new(1, 0, 0, 38)
		frame.BackgroundColor3 = TOAST_COLORS[kind] or COLORS.blue
		frame.LayoutOrder = toastOrder
		corner(frame, 10)
		outline(frame, 2)
		label(frame, { Size = UDim2.new(1, -16, 1, -8), Position = UDim2.fromOffset(8, 4), Text = message })
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
		task.delay(3.5, function()
			if frame.Parent then
				frame:Destroy()
			end
		end)
	end

	local function gainPopup(message: string)
		gainOrder += 1
		local l = label(gains, {
			Size = UDim2.new(1, 0, 0, 34),
			LayoutOrder = gainOrder,
			Text = message,
			TextColor3 = Color3.fromRGB(120, 255, 100),
			TextXAlignment = Enum.TextXAlignment.Left,
			StrokeThickness = 3,
		})
		local items = {}
		for _, child in gains:GetChildren() do
			if child:IsA("TextLabel") then
				table.insert(items, child)
			end
		end
		table.sort(items, function(a, b)
			return a.LayoutOrder < b.LayoutOrder
		end)
		for i = 1, #items - 5 do
			items[i]:Destroy()
		end
		task.delay(2.5, function()
			if l.Parent then
				TweenService:Create(l, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
				task.wait(0.4)
				l:Destroy()
			end
		end)
	end

	local announceToken = 0
	local function showAnnouncement(message: string)
		announceToken += 1
		local token = announceToken
		announceLabel.Text = message
		announce.Visible = true
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

	local lastCash = player:GetAttribute("Cash") or 0
	local function updateCash()
		local cash = player:GetAttribute("Cash") or 0
		cashLabel.Text = Format.money(cash)
		if cash > lastCash then
			cashScale.Scale = 1.12
			TweenService:Create(cashScale, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Scale = 1 }):Play()
		end
		lastCash = cash
		if openName == "rebirth" then
			panels.rebirth.Refresh()
		end
	end
	local function updateIncome()
		incomeLabel.Text = "+" .. Format.money(player:GetAttribute("Income") or 0) .. "/s"
	end
	local function updateSpeed()
		local speed = math.floor(Config.BaseWalkSpeed + (player:GetAttribute("SpeedStat") or 0))
		speedLabel.Text = tostring(speed)
		local nextZone
		for _, zone in Config.Zones do
			if zone.RequiredSpeed > speed then
				nextZone = zone
				break
			end
		end
		nextZoneLabel.Text = if nextZone
			then string.format("Próxima zona: %s (%d)", nextZone.Name, nextZone.RequiredSpeed)
			else "Todas as zonas liberadas!"
	end
	local function updateCarry()
		local carrying = player:GetAttribute("Carrying") or ""
		carry.Visible = carrying ~= ""
		carryLabel.Text = "🦖 " .. carrying .. " — fuja até a linha das bases!"
	end
	local function updateSlowMode()
		local on = player:GetAttribute("SlowMode") == true
		slowTitle.Text = "Modo Lento [Q] - " .. (if on then "ATIVADO" else "DESATIVADO")
		slowSwitch.BackgroundColor3 = if on then COLORS.green else COLORS.gray
		knob.Position = if on then UDim2.fromOffset(59, 5) else UDim2.fromOffset(5, 5)
	end
	local function updateBoosts()
		premiumText.Text = string.format("+%d%%", math.floor((player:GetAttribute("PremiumBoost") or 0) * 100))
		friendsText.Text = string.format("+%d%%", math.floor((player:GetAttribute("FriendBoost") or 0) * 100))
	end
	local function updateDaily()
		local ready = player:GetAttribute("DailyReady") == true
		dailyBadge.Parent.Visible = ready
		dailyText.Text = if ready then "Pronto!" else "Dia " .. tostring(player:GetAttribute("DailyStreak") or 0)
	end

	for attribute, fn in
		{
			Cash = updateCash,
			Income = updateIncome,
			SpeedStat = updateSpeed,
			Carrying = updateCarry,
			SlowMode = updateSlowMode,
			PremiumBoost = updateBoosts,
			FriendBoost = updateBoosts,
			DailyReady = updateDaily,
			DailyStreak = updateDaily,
		}
	do
		player:GetAttributeChangedSignal(attribute):Connect(fn)
		fn()
	end
	for _, attribute in { "TreadmillLevel", "SlotsUnlocked" } do
		player:GetAttributeChangedSignal(attribute):Connect(function()
			if openName == "buy" then
				panels.buy.Refresh()
			end
		end)
	end
	player:GetAttributeChangedSignal("Discovered"):Connect(function()
		if openName == "index" then
			panels.index.Refresh()
		end
	end)

	-- relógios: presente, evento e painéis que mostram tempo
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc < 0.5 then
			return
		end
		acc = 0
		local giftLeft = giftSecondsLeft()
		giftBadge.Parent.Visible = giftLeft <= 0

		local now = os.time()
		local endsAt = workspace:GetAttribute("EventEndsAt") or 0
		local nextAt = workspace:GetAttribute("NextEventAt") or 0
		local name = workspace:GetAttribute("EventName") or "Evento"
		if now < endsAt then
			eventLabel.Text = string.format("🍀 %s!\nTermina em %s", name, Format.time(endsAt - now))
		elseif nextAt > now then
			eventLabel.Text = string.format("Próximo evento\n%s", Format.time(nextAt - now))
		else
			eventLabel.Text = ""
		end

		if openName == "gift" then
			panels.gift.Refresh()
		end
	end)

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.KeyCode == Enum.KeyCode.Q then
			action("slowmode")
		end
	end)

	Remotes.get("Notify").OnClientEvent:Connect(function(message: string, kind: string)
		if kind == "announce" then
			showAnnouncement(message)
		elseif kind == "cash" then
			gainPopup(message)
		else
			toast(message, kind)
		end
	end)
end

return HUD
