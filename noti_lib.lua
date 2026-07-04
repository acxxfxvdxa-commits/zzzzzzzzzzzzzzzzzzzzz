local Notify = {}

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer

local GUI

local function CreateGui()

	if GUI then
		return GUI
	end

	GUI = Instance.new("ScreenGui")
	GUI.Name = "NotifyLibrary"
	GUI.ResetOnSpawn = false
	GUI.IgnoreGuiInset = true
	GUI.Parent = Player.PlayerGui

	return GUI

end

local function HexToColor(hex)

	hex = hex:gsub("#","")

	if #hex ~= 6 then
		return Color3.fromRGB(7,25,54)
	end

	return Color3.fromRGB(
		tonumber(hex:sub(1,2),16),
		tonumber(hex:sub(3,4),16),
		tonumber(hex:sub(5,6),16)
	)

end

local function Rainbow()

	return Color3.fromHSV((tick()*0.15)%1,1,1)

end

function Notify:New(config)

	config = config or {}

	local Duration = config["duraçao da notificaçao"] or 3
	local Message = config["mensagem predefinido"] or "Notificação"

	local Type = string.lower(config["tipo de mensagem"] or "info")
	local Position = string.lower(config["local de exibiçao da notificaçao"] or "lado direito")

	local RainbowBackground = config["rainbow"] or false

	local BackgroundColor = HexToColor(config["color"] or "#071936")

	local BorderEnabled = config["bordas"] or false
	local BorderColor = HexToColor(config["bordas color"] or "#17253d")

	local RainbowBorder = config["bordas em rainbow"] or false

	local Gui = CreateGui()

	local Frame = Instance.new("Frame")
	Frame.Size = UDim2.new(0,320,0,70)
	Frame.BackgroundColor3 = BackgroundColor
	Frame.BorderSizePixel = 0
	Frame.AnchorPoint = Vector2.new(.5,.5)
	Frame.Parent = Gui

	local Stroke

	if BorderEnabled then

		Stroke = Instance.new("UIStroke")
		Stroke.Parent = Frame
		Stroke.Thickness = 2
		Stroke.Color = BorderColor

	end

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0,10)
	Corner.Parent = Frame

	local Title = Instance.new("TextLabel")
	Title.Size = UDim2.new(1,-20,0,22)
	Title.Position = UDim2.new(0,10,0,6)
	Title.BackgroundTransparency = 1
	Title.Font = Enum.Font.GothamBold
	Title.TextSize = 18
	Title.TextXAlignment = Enum.TextXAlignment.Left
	Title.TextColor3 = Color3.new(1,1,1)
	Title.Parent = Frame

	local Colors = {
		info = Color3.fromRGB(80,180,255),
		alerta = Color3.fromRGB(255,210,0),
		erro = Color3.fromRGB(255,80,80)
	}

	Title.Text = Type:upper()
	Title.TextColor3 = Colors[Type] or Colors.info

	local Text = Instance.new("TextLabel")
	Text.Size = UDim2.new(1,-20,1,-30)
	Text.Position = UDim2.new(0,10,0,25)
	Text.BackgroundTransparency = 1
	Text.Font = Enum.Font.Gotham
	Text.TextWrapped = true
	Text.TextXAlignment = Enum.TextXAlignment.Left
	Text.TextYAlignment = Enum.TextYAlignment.Top
	Text.TextSize = 16
	Text.TextColor3 = Color3.new(1,1,1)
	Text.Text = Message
	Text.Parent = Frame

	if Position == "cima" then

		Frame.Position = UDim2.new(.5,0,-.2,0)

	elseif Position == "lado esquerdo" then

		Frame.AnchorPoint = Vector2.new(0,1)
		Frame.Position = UDim2.new(0.02,0,1.2,0)

	else

		Frame.AnchorPoint = Vector2.new(1,1)
		Frame.Position = UDim2.new(.98,0,1.2,0)

	end

	local Target

	if Position == "cima" then

		Target = UDim2.new(.5,0,0.08,0)

	elseif Position == "lado esquerdo" then

		Target = UDim2.new(0.02,0,.97,0)

	else

		Target = UDim2.new(.98,0,.97,0)

	end

	TweenService:Create(
		Frame,
		TweenInfo.new(.35,Enum.EasingStyle.Quart),
		{
			Position = Target
		}
	):Play()

	local Connection

	if RainbowBackground or RainbowBorder then

		Connection = RunService.RenderStepped:Connect(function()

			local Color = Rainbow()

			if RainbowBackground then
				Frame.BackgroundColor3 = Color
			end

			if RainbowBorder and Stroke then
				Stroke.Color = Color
			end

		end)

	end

	task.wait(Duration)

	if Connection then
		Connection:Disconnect()
	end

	local EndPos

	if Position == "cima" then
		EndPos = UDim2.new(.5,0,-.2,0)
	elseif Position == "lado esquerdo" then
		EndPos = UDim2.new(0.02,0,1.2,0)
	else
		EndPos = UDim2.new(.98,0,1.2,0)
	end

	local Tween = TweenService:Create(
		Frame,
		TweenInfo.new(.35,Enum.EasingStyle.Quart),
		{
			Position = EndPos,
			BackgroundTransparency = 1
		}
	)

	Tween:Play()
	Tween.Completed:Wait()

	Frame:Destroy()

end

function Notify:Info(message, config)

    config = config or {}

    config["mensagem predefinido"] = message
    config["tipo de mensagem"] = "info"

    self:New(config)

end

function Notify:Warn(message, config)

    config = config or {}

    config["mensagem predefinido"] = message
    config["tipo de mensagem"] = "alerta"

    self:New(config)

end

function Notify:Error(message, config)

    config = config or {}

    config["mensagem predefinido"] = message
    config["tipo de mensagem"] = "erro"

    self:New(config)

end

return Notify
