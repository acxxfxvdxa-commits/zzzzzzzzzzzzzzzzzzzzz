--[[
    ╔═══════════════════════════════════════════════════════════════╗
    ║                  FurryUI v2.0 - UI Library                      ║
    ║         Biblioteca de interface gráfica para Roblox            ║
    ╚═══════════════════════════════════════════════════════════════╝

    ► COMO USAR:

    local UI = loadstring(game:HttpGet("URL_DA_LIB"))()

    local Window = UI:CreateWindow("Nome do Script")

    local Tab = Window:NewTab("Main")

    Tab:Toggle("Auto Farm", false, function(state)
        print("Auto Farm:", state)
    end)

    Tab:Slider("Speed", 16, 500, 50, function(value)
        print("Speed:", value)
    end)

    Tab:Button("Kill All", function()
        print("Kill All ativado!")
    end)

    Tab:Dropdown("Selecionar Time", {"Inmates", "Guards", "Criminals"}, function(selected)
        print("Time:", selected)
    end)

    Tab:Textbox("Nome do Jogador", "Digite aqui...", function(text)
        print("Digitado:", text)
    end)

    Tab:Keybind("Toggle UI", Enum.KeyCode.RightShift, function()
        Window:Toggle()
    end)

    UI:Notify("Script Carregado!", "Bem-vindo ao meu script.", 3)
]]

local FurryUI = {}

-- ═════════════════════ SERVICES ═════════════════════
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

-- ═════════════════════ UTILS ═════════════════════
local function GetHUI()
    if gethui then
        return gethui()
    end
    return Player:WaitForChild("PlayerGui")
end

local function MakeDraggable(frame, handle)
    local dragging = false
    local dragStart, startPos

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

local function Tween(obj, props, duration)
    TweenService:Create(obj, TweenInfo.new(duration or 0.3, Enum.EasingStyle.Quart), props):Play()
end

-- ═════════════════════ THEME ═════════════════════
local Theme = {
    Background      = Color3.fromRGB(18, 18, 22),
    TitleBar        = Color3.fromRGB(28, 28, 35),
    Sidebar         = Color3.fromRGB(22, 22, 28),
    ElementBg       = Color3.fromRGB(32, 32, 40),
    ElementHover    = Color3.fromRGB(42, 42, 52),
    Text            = Color3.fromRGB(230, 230, 240),
    TextDim         = Color3.fromRGB(150, 150, 170),
    Accent          = Color3.fromRGB(88, 101, 242),
    AccentHover     = Color3.fromRGB(108, 121, 255),
    ToggleOn        = Color3.fromRGB(88, 101, 242),
    ToggleOff       = Color3.fromRGB(50, 50, 60),
    Success         = Color3.fromRGB(67, 181, 129),
    Warning         = Color3.fromRGB(250, 168, 26),
    Error           = Color3.fromRGB(240, 71, 71),
    Border          = Color3.fromRGB(40, 40, 50),
    SliderFill      = Color3.fromRGB(88, 101, 242),
    NotifyBg        = Color3.fromRGB(22, 22, 28),
}

-- ═════════════════════ NOTIFICATION SYSTEM ═════════════════════
local NotifyGui
local ActiveNotifs = {}

local function GetNotifyGui()
    if NotifyGui and NotifyGui.Parent then return NotifyGui end
    NotifyGui = Instance.new("ScreenGui")
    NotifyGui.Name = "FurryNotify"
    NotifyGui.ResetOnSpawn = false
    NotifyGui.IgnoreGuiInset = true
    NotifyGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    NotifyGui.Parent = GetHUI()
    return NotifyGui
end

function FurryUI:Notify(title, message, duration, ntype)
    duration = duration or 3
    ntype = ntype or "info"

    local colors = {
        info = Theme.Accent,
        success = Theme.Success,
        warn = Theme.Warning,
        error = Theme.Error
    }
    local color = colors[ntype] or colors.info

    local gui = GetNotifyGui()
    local offset = 10 + (#ActiveNotifs * 85)

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 280, 0, 75)
    frame.Position = UDim2.new(1, 300, 0, offset)
    frame.BackgroundColor3 = Theme.NotifyBg
    frame.BorderSizePixel = 0
    frame.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color = color
    stroke.Thickness = 1.5
    stroke.Transparency = 0.4
    stroke.Parent = frame

    local topBar = Instance.new("Frame")
    topBar.Size = UDim2.new(1, 0, 0, 3)
    topBar.BackgroundColor3 = color
    topBar.BorderSizePixel = 0
    topBar.Parent = frame

    local topCorner = Instance.new("UICorner")
    topCorner.CornerRadius = UDim.new(0, 8)
    topCorner.Parent = topBar

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -20, 0, 22)
    titleLabel.Position = UDim2.new(0, 10, 0, 8)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = color
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 15
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = frame

    local msgLabel = Instance.new("TextLabel")
    msgLabel.Size = UDim2.new(1, -20, 1, -32)
    msgLabel.Position = UDim2.new(0, 10, 0, 28)
    msgLabel.BackgroundTransparency = 1
    msgLabel.Text = message
    msgLabel.TextColor3 = Theme.Text
    msgLabel.Font = Enum.Font.Gotham
    msgLabel.TextSize = 13
    msgLabel.TextWrapped = true
    msgLabel.TextXAlignment = Enum.TextXAlignment.Left
    msgLabel.TextYAlignment = Enum.TextYAlignment.Top
    msgLabel.Parent = frame

    local progress = Instance.new("Frame")
    progress.Size = UDim2.new(1, 0, 0, 2)
    progress.Position = UDim2.new(0, 0, 1, -2)
    progress.BackgroundColor3 = color
    progress.BorderSizePixel = 0
    progress.Parent = frame

    table.insert(ActiveNotifs, frame)

    -- Animação de entrada
    Tween(frame, {Position = UDim2.new(1, -300, 0, offset)}, 0.4)
    Tween(progress, {Size = UDim2.new(0, 0, 0, 2)}, duration)

    -- Remover após duração
    task.delay(duration, function()
        Tween(frame, {Position = UDim2.new(1, 300, 0, offset), BackgroundTransparency = 1}, 0.35)
        task.wait(0.35)
        frame:Destroy()

        for i, f in ipairs(ActiveNotifs) do
            if f == frame then
                table.remove(ActiveNotifs, i)
                break
            end
        end

        -- Reorganizar
        for i, f in ipairs(ActiveNotifs) do
            if f and f.Parent then
                Tween(f, {Position = UDim2.new(1, -300, 0, 10 + (i-1) * 85)}, 0.3)
            end
        end
    end)
end

-- ═════════════════════ WINDOW SYSTEM ═════════════════════
function FurryUI:CreateWindow(title)
    title = title or "FurryUI"

    local Window = {}
    Window.Tabs = {}
    Window.CurrentTab = nil
    Window.Visible = true

    -- ScreenGui
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "FurryUI_" .. tostring(math.random(10000, 99999))
    ScreenGui.ResetOnSpawn = false
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = GetHUI()
    Window.ScreenGui = ScreenGui

    -- Main Frame
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 500, 0, 350)
    MainFrame.Position = UDim2.new(0.5, -250, 0.5, -175)
    MainFrame.BackgroundColor3 = Theme.Background
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = true
    MainFrame.Parent = ScreenGui

    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 10)
    MainCorner.Parent = MainFrame

    local MainStroke = Instance.new("UIStroke")
    MainStroke.Color = Theme.Border
    MainStroke.Thickness = 1
    MainStroke.Transparency = 0.6
    MainStroke.Parent = MainFrame

    -- Shadow
    local Shadow = Instance.new("ImageLabel")
    Shadow.Name = "Shadow"
    Shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    Shadow.Position = UDim2.new(0.5, 0, 0.5, 0)
    Shadow.Size = UDim2.new(1, 50, 1, 50)
    Shadow.BackgroundTransparency = 1
    Shadow.Image = "rbxassetid://5554236805"
    Shadow.ImageColor3 = Color3.new(0, 0, 0)
    Shadow.ImageTransparency = 0.65
    Shadow.ScaleType = Enum.ScaleType.Slice
    Shadow.SliceCenter = Rect.new(23, 23, 277, 277)
    Shadow.ZIndex = -1
    Shadow.Parent = MainFrame

    -- Title Bar
    local TitleBar = Instance.new("Frame")
    TitleBar.Name = "TitleBar"
    TitleBar.Size = UDim2.new(1, 0, 0, 38)
    TitleBar.BackgroundColor3 = Theme.TitleBar
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = MainFrame

    local TitleCorner = Instance.new("UICorner")
    TitleCorner.CornerRadius = UDim.new(0, 10)
    TitleCorner.Parent = TitleBar

    local TitleFix = Instance.new("Frame")
    TitleFix.Size = UDim2.new(1, 0, 0, 12)
    TitleFix.Position = UDim2.new(0, 0, 1, -12)
    TitleFix.BackgroundColor3 = Theme.TitleBar
    TitleFix.BorderSizePixel = 0
    TitleFix.Parent = TitleBar

    -- Title Text
    local TitleText = Instance.new("TextLabel")
    TitleText.Size = UDim2.new(1, -100, 1, 0)
    TitleText.Position = UDim2.new(0, 15, 0, 0)
    TitleText.BackgroundTransparency = 1
    TitleText.Text = title
    TitleText.TextColor3 = Theme.Text
    TitleText.Font = Enum.Font.GothamBold
    TitleText.TextSize = 16
    TitleText.TextXAlignment = Enum.TextXAlignment.Left
    TitleText.Parent = TitleBar

    -- Minimize Button
    local MinBtn = Instance.new("TextButton")
    MinBtn.Size = UDim2.new(0, 32, 0, 32)
    MinBtn.Position = UDim2.new(1, -68, 0, 3)
    MinBtn.BackgroundTransparency = 1
    MinBtn.Text = "−"
    MinBtn.TextColor3 = Theme.TextDim
    MinBtn.Font = Enum.Font.GothamBold
    MinBtn.TextSize = 20
    MinBtn.Parent = TitleBar

    -- Close Button
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 32, 0, 32)
    CloseBtn.Position = UDim2.new(1, -36, 0, 3)
    CloseBtn.BackgroundTransparency = 1
    CloseBtn.Text = "×"
    CloseBtn.TextColor3 = Theme.Error
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.TextSize = 22
    CloseBtn.Parent = TitleBar

    -- Sidebar
    local Sidebar = Instance.new("Frame")
    Sidebar.Name = "Sidebar"
    Sidebar.Size = UDim2.new(0, 130, 1, -38)
    Sidebar.Position = UDim2.new(0, 0, 0, 38)
    Sidebar.BackgroundColor3 = Theme.Sidebar
    Sidebar.BorderSizePixel = 0
    Sidebar.Parent = MainFrame

    local SidebarList = Instance.new("UIListLayout")
    SidebarList.SortOrder = Enum.SortOrder.LayoutOrder
    SidebarList.Padding = UDim.new(0, 3)
    SidebarList.Parent = Sidebar

    local SidebarPadding = Instance.new("UIPadding")
    SidebarPadding.PaddingTop = UDim.new(0, 8)
    SidebarPadding.PaddingLeft = UDim.new(0, 8)
    SidebarPadding.PaddingRight = UDim.new(0, 8)
    SidebarPadding.Parent = Sidebar

    -- Content Frame
    local ContentFrame = Instance.new("Frame")
    ContentFrame.Name = "ContentFrame"
    ContentFrame.Size = UDim2.new(1, -130, 1, -38)
    ContentFrame.Position = UDim2.new(0, 130, 0, 38)
    ContentFrame.BackgroundTransparency = 1
    ContentFrame.Parent = MainFrame

    -- Dragging
    MakeDraggable(MainFrame, TitleBar)

    -- Minimize
    local Minimized = false
    MinBtn.MouseButton1Click:Connect(function()
        Minimized = not Minimized
        if Minimized then
            Tween(MainFrame, {Size = UDim2.new(0, 500, 0, 38)}, 0.3)
            MinBtn.Text = "+"
        else
            Tween(MainFrame, {Size = UDim2.new(0, 500, 0, 350)}, 0.3)
            MinBtn.Text = "−"
        end
    end)

    -- Close
    CloseBtn.MouseButton1Click:Connect(function()
        Tween(MainFrame, {Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0)}, 0.3)
        task.wait(0.3)
        ScreenGui:Destroy()
    end)

    -- Toggle visibility
    function Window:Toggle()
        Window.Visible = not Window.Visible
        MainFrame.Visible = Window.Visible
    end

    function Window:Destroy()
        ScreenGui:Destroy()
    end

    -- ═════════════════════ TAB SYSTEM ═════════════════════
    function Window:NewTab(name, icon)
        local Tab = {}
        Tab.Name = name

        -- Tab Button
        local TabBtn = Instance.new("TextButton")
        TabBtn.Name = name .. "Tab"
        TabBtn.Size = UDim2.new(1, 0, 0, 32)
        TabBtn.BackgroundColor3 = Theme.ElementBg
        TabBtn.BorderSizePixel = 0
        TabBtn.Text = (icon or "") .. " " .. name
        TabBtn.TextColor3 = Theme.TextDim
        TabBtn.Font = Enum.Font.GothamBold
        TabBtn.TextSize = 12
        TabBtn.Parent = Sidebar

        local TabBtnCorner = Instance.new("UICorner")
        TabBtnCorner.CornerRadius = UDim.new(0, 6)
        TabBtnCorner.Parent = TabBtn

        -- Tab Content
        local TabContent = Instance.new("ScrollingFrame")
        TabContent.Name = name .. "Content"
        TabContent.Size = UDim2.new(1, -10, 1, -10)
        TabContent.Position = UDim2.new(0, 5, 0, 5)
        TabContent.BackgroundTransparency = 1
        TabContent.ScrollBarThickness = 3
        TabContent.ScrollBarImageColor3 = Theme.Accent
        TabContent.CanvasSize = UDim2.new(0, 0, 0, 0)
        TabContent.Visible = false
        TabContent.Parent = ContentFrame

        local ContentList = Instance.new("UIListLayout")
        ContentList.SortOrder = Enum.SortOrder.LayoutOrder
        ContentList.Padding = UDim.new(0, 6)
        ContentList.Parent = TabContent

        local ContentPadding = Instance.new("UIPadding")
        ContentPadding.PaddingTop = UDim.new(0, 5)
        ContentPadding.PaddingLeft = UDim.new(0, 5)
        ContentPadding.PaddingRight = UDim.new(0, 5)
        ContentPadding.Parent = TabContent

        -- Auto canvas size
        ContentList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            TabContent.CanvasSize = UDim2.new(0, 0, 0, ContentList.AbsoluteContentSize.Y + 10)
        end)

        -- Select tab
        local function SelectTab()
            if Window.CurrentTab then
                Window.CurrentTab.Button.TextColor3 = Theme.TextDim
                Window.CurrentTab.Button.BackgroundColor3 = Theme.ElementBg
                Window.CurrentTab.Content.Visible = false
            end
            Window.CurrentTab = Tab
            TabBtn.TextColor3 = Theme.Text
            TabBtn.BackgroundColor3 = Theme.Accent
            TabContent.Visible = true
        end

        TabBtn.MouseButton1Click:Connect(SelectTab)
        TabBtn.MouseEnter:Connect(function()
            if Window.CurrentTab ~= Tab then
                Tween(TabBtn, {BackgroundColor3 = Theme.ElementHover}, 0.15)
            end
        end)
        TabBtn.MouseLeave:Connect(function()
            if Window.CurrentTab ~= Tab then
                Tween(TabBtn, {BackgroundColor3 = Theme.ElementBg}, 0.15)
            end
        end)

        Tab.Button = TabBtn
        Tab.Content = TabContent

        if #Window.Tabs == 0 then
            SelectTab()
        end

        table.insert(Window.Tabs, Tab)

        -- ═════════════════════ ELEMENTS ═════════════════════

        -- TOGGLE
        function Tab:Toggle(text, default, callback)
            callback = callback or function() end
            default = default or false

            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, 0, 0, 36)
            frame.BackgroundColor3 = Theme.ElementBg
            frame.BorderSizePixel = 0
            frame.Parent = TabContent

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 6)
            corner.Parent = frame

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(0.65, -10, 1, 0)
            label.Position = UDim2.new(0, 12, 0, 0)
            label.BackgroundTransparency = 1
            label.Text = text
            label.TextColor3 = Theme.Text
            label.Font = Enum.Font.Gotham
            label.TextSize = 13
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = frame

            local toggleBtn = Instance.new("TextButton")
            toggleBtn.Size = UDim2.new(0, 44, 0, 22)
            toggleBtn.Position = UDim2.new(1, -56, 0.5, -11)
            toggleBtn.BackgroundColor3 = default and Theme.ToggleOn or Theme.ToggleOff
            toggleBtn.BorderSizePixel = 0
            toggleBtn.Text = default and "ON" or "OFF"
            toggleBtn.TextColor3 = Color3.new(1, 1, 1)
            toggleBtn.Font = Enum.Font.GothamBold
            toggleBtn.TextSize = 10
            toggleBtn.Parent = frame

            local toggleCorner = Instance.new("UICorner")
            toggleCorner.CornerRadius = UDim.new(0, 11)
            toggleCorner.Parent = toggleBtn

            local enabled = default

            toggleBtn.MouseButton1Click:Connect(function()
                enabled = not enabled
                Tween(toggleBtn, {BackgroundColor3 = enabled and Theme.ToggleOn or Theme.ToggleOff}, 0.2)
                toggleBtn.Text = enabled and "ON" or "OFF"
                callback(enabled)
            end)

            callback(default)
            return frame
        end

        -- SLIDER
        function Tab:Slider(text, min, max, default, callback)
            callback = callback or function() end
            min = min or 0
            max = max or 100
            default = default or min

            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, 0, 0, 50)
            frame.BackgroundColor3 = Theme.ElementBg
            frame.BorderSizePixel = 0
            frame.Parent = TabContent

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 6)
            corner.Parent = frame

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(0.5, -10, 0, 20)
            label.Position = UDim2.new(0, 12, 0, 5)
            label.BackgroundTransparency = 1
            label.Text = text
            label.TextColor3 = Theme.Text
            label.Font = Enum.Font.Gotham
            label.TextSize = 13
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = frame

            local valueLabel = Instance.new("TextLabel")
            valueLabel.Size = UDim2.new(0.5, -10, 0, 20)
            valueLabel.Position = UDim2.new(0.5, 0, 0, 5)
            valueLabel.BackgroundTransparency = 1
            valueLabel.Text = tostring(default)
            valueLabel.TextColor3 = Theme.Accent
            valueLabel.Font = Enum.Font.GothamBold
            valueLabel.TextSize = 13
            valueLabel.TextXAlignment = Enum.TextXAlignment.Right
            valueLabel.Parent = frame

            local bar = Instance.new("Frame")
            bar.Size = UDim2.new(1, -24, 0, 5)
            bar.Position = UDim2.new(0, 12, 0, 32)
            bar.BackgroundColor3 = Theme.ToggleOff
            bar.BorderSizePixel = 0
            bar.Parent = frame

            local barCorner = Instance.new("UICorner")
            barCorner.CornerRadius = UDim.new(0, 3)
            barCorner.Parent = bar

            local fill = Instance.new("Frame")
            fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
            fill.BackgroundColor3 = Theme.SliderFill
            fill.BorderSizePixel = 0
            fill.Parent = bar

            local fillCorner = Instance.new("UICorner")
            fillCorner.CornerRadius = UDim.new(0, 3)
            fillCorner.Parent = fill

            local knob = Instance.new("Frame")
            knob.Size = UDim2.new(0, 12, 0, 12)
            knob.Position = UDim2.new((default - min) / (max - min), -6, 0.5, -6)
            knob.BackgroundColor3 = Color3.new(1, 1, 1)
            knob.BorderSizePixel = 0
            knob.Parent = bar

            local knobCorner = Instance.new("UICorner")
            knobCorner.CornerRadius = UDim.new(1, 0)
            knobCorner.Parent = knob

            local dragging = false

            local function Update(input)
                local pos = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
                local value = math.floor(min + (max - min) * pos)
                valueLabel.Text = tostring(value)
                fill.Size = UDim2.new(pos, 0, 1, 0)
                knob.Position = UDim2.new(pos, -6, 0.5, -6)
                callback(value)
            end

            bar.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                    Update(input)
                end
            end)

            UserInputService.InputChanged:Connect(function(input)
                if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    Update(input)
                end
            end)

            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                end
            end)

            callback(default)
            return frame
        end

        -- BUTTON
        function Tab:Button(text, callback)
            callback = callback or function() end

            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, 0, 0, 36)
            frame.BackgroundColor3 = Theme.Accent
            frame.BorderSizePixel = 0
            frame.Parent = TabContent

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 6)
            corner.Parent = frame

            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 1, 0)
            btn.BackgroundTransparency = 1
            btn.Text = text
            btn.TextColor3 = Color3.new(1, 1, 1)
            btn.Font = Enum.Font.GothamBold
            btn.TextSize = 13
            btn.Parent = frame

            btn.MouseButton1Click:Connect(function()
                Tween(frame, {BackgroundColor3 = Theme.AccentHover}, 0.1)
                task.wait(0.1)
                Tween(frame, {BackgroundColor3 = Theme.Accent}, 0.1)
                callback()
            end)

            btn.MouseEnter:Connect(function()
                Tween(frame, {BackgroundColor3 = Theme.AccentHover}, 0.2)
            end)

            btn.MouseLeave:Connect(function()
                Tween(frame, {BackgroundColor3 = Theme.Accent}, 0.2)
            end)

            return frame
        end

        -- DROPDOWN
        function Tab:Dropdown(text, options, callback)
            callback = callback or function() end
            options = options or {}

            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, 0, 0, 36)
            frame.BackgroundColor3 = Theme.ElementBg
            frame.BorderSizePixel = 0
            frame.ClipsDescendants = true
            frame.Parent = TabContent

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 6)
            corner.Parent = frame

            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, 36)
            btn.BackgroundTransparency = 1
            btn.Text = ""
            btn.Parent = frame

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(0.6, -10, 0, 36)
            label.Position = UDim2.new(0, 12, 0, 0)
            label.BackgroundTransparency = 1
            label.Text = text
            label.TextColor3 = Theme.Text
            label.Font = Enum.Font.Gotham
            label.TextSize = 13
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = frame

            local selected = Instance.new("TextLabel")
            selected.Size = UDim2.new(0.4, -30, 0, 36)
            selected.Position = UDim2.new(0.6, 0, 0, 0)
            selected.BackgroundTransparency = 1
            selected.Text = options[1] or "Select..."
            selected.TextColor3 = Theme.Accent
            selected.Font = Enum.Font.GothamBold
            selected.TextSize = 12
            selected.TextXAlignment = Enum.TextXAlignment.Right
            selected.Parent = frame

            local arrow = Instance.new("TextLabel")
            arrow.Size = UDim2.new(0, 20, 0, 36)
            arrow.Position = UDim2.new(1, -25, 0, 0)
            arrow.BackgroundTransparency = 1
            arrow.Text = "▼"
            arrow.TextColor3 = Theme.TextDim
            arrow.Font = Enum.Font.GothamBold
            arrow.TextSize = 10
            arrow.Parent = frame

            local optionsFrame = Instance.new("Frame")
            optionsFrame.Size = UDim2.new(1, -16, 0, #options * 28)
            optionsFrame.Position = UDim2.new(0, 8, 0, 36)
            optionsFrame.BackgroundColor3 = Theme.ElementHover
            optionsFrame.BorderSizePixel = 0
            optionsFrame.Visible = false
            optionsFrame.Parent = frame

            local optionsCorner = Instance.new("UICorner")
            optionsCorner.CornerRadius = UDim.new(0, 4)
            optionsCorner.Parent = optionsFrame

            local optionsList = Instance.new("UIListLayout")
            optionsList.SortOrder = Enum.SortOrder.LayoutOrder
            optionsList.Parent = optionsFrame

            for _, option in ipairs(options) do
                local optBtn = Instance.new("TextButton")
                optBtn.Size = UDim2.new(1, 0, 0, 28)
                optBtn.BackgroundTransparency = 1
                optBtn.Text = option
                optBtn.TextColor3 = Theme.Text
                optBtn.Font = Enum.Font.Gotham
                optBtn.TextSize = 12
                optBtn.Parent = optionsFrame

                optBtn.MouseButton1Click:Connect(function()
                    selected.Text = option
                    callback(option)
                    Tween(frame, {Size = UDim2.new(1, 0, 0, 36)}, 0.2)
                    optionsFrame.Visible = false
                    arrow.Text = "▼"
                end)

                optBtn.MouseEnter:Connect(function()
                    Tween(optBtn, {BackgroundTransparency = 0.85}, 0.1)
                end)
                optBtn.MouseLeave:Connect(function()
                    Tween(optBtn, {BackgroundTransparency = 1}, 0.1)
                end)
            end

            local opened = false
            btn.MouseButton1Click:Connect(function()
                opened = not opened
                if opened then
                    Tween(frame, {Size = UDim2.new(1, 0, 0, 36 + optionsFrame.Size.Y.Offset + 5)}, 0.2)
                    optionsFrame.Visible = true
                    arrow.Text = "▲"
                else
                    Tween(frame, {Size = UDim2.new(1, 0, 0, 36)}, 0.2)
                    task.wait(0.2)
                    optionsFrame.Visible = false
                    arrow.Text = "▼"
                end
            end)

            return frame
        end

        -- TEXTBOX
        function Tab:Textbox(text, placeholder, callback)
            callback = callback or function() end

            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, 0, 0, 60)
            frame.BackgroundColor3 = Theme.ElementBg
            frame.BorderSizePixel = 0
            frame.Parent = TabContent

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 6)
            corner.Parent = frame

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -20, 0, 20)
            label.Position = UDim2.new(0, 10, 0, 5)
            label.BackgroundTransparency = 1
            label.Text = text
            label.TextColor3 = Theme.Text
            label.Font = Enum.Font.Gotham
            label.TextSize = 13
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = frame

            local textbox = Instance.new("TextBox")
            textbox.Size = UDim2.new(1, -20, 0, 26)
            textbox.Position = UDim2.new(0, 10, 0, 28)
            textbox.BackgroundColor3 = Theme.Background
            textbox.BorderSizePixel = 0
            textbox.PlaceholderText = placeholder or "Digite aqui..."
            textbox.PlaceholderColor3 = Theme.TextDim
            textbox.Text = ""
            textbox.TextColor3 = Theme.Text
            textbox.Font = Enum.Font.Gotham
            textbox.TextSize = 12
            textbox.ClearTextOnFocus = false
            textbox.Parent = frame

            local textCorner = Instance.new("UICorner")
            textCorner.CornerRadius = UDim.new(0, 4)
            textCorner.Parent = textbox

            textbox.FocusLost:Connect(function(enterPressed)
                if enterPressed then
                    callback(textbox.Text)
                end
            end)

            return frame
        end

        -- KEYBIND
        function Tab:Keybind(text, defaultKey, callback)
            callback = callback or function() end
            defaultKey = defaultKey or Enum.KeyCode.Unknown

            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, 0, 0, 36)
            frame.BackgroundColor3 = Theme.ElementBg
            frame.BorderSizePixel = 0
            frame.Parent = TabContent

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 6)
            corner.Parent = frame

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(0.6, -10, 1, 0)
            label.Position = UDim2.new(0, 12, 0, 0)
            label.BackgroundTransparency = 1
            label.Text = text
            label.TextColor3 = Theme.Text
            label.Font = Enum.Font.Gotham
            label.TextSize = 13
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = frame

            local keyBtn = Instance.new("TextButton")
            keyBtn.Size = UDim2.new(0, 80, 0, 24)
            keyBtn.Position = UDim2.new(1, -92, 0.5, -12)
            keyBtn.BackgroundColor3 = Theme.Background
            keyBtn.BorderSizePixel = 0
            keyBtn.Text = defaultKey.Name
            keyBtn.TextColor3 = Theme.Accent
            keyBtn.Font = Enum.Font.GothamBold
            keyBtn.TextSize = 11
            keyBtn.Parent = frame

            local keyCorner = Instance.new("UICorner")
            keyCorner.CornerRadius = UDim.new(0, 4)
            keyCorner.Parent = keyBtn

            local listening = false

            keyBtn.MouseButton1Click:Connect(function()
                listening = true
                keyBtn.Text = "..."
            end)

            UserInputService.InputBegan:Connect(function(input, gameProcessed)
                if listening and input.UserInputType == Enum.UserInputType.Keyboard then
                    listening = false
                    keyBtn.Text = input.KeyCode.Name
                    callback(input.KeyCode)
                elseif not gameProcessed and input.KeyCode == defaultKey then
                    callback(defaultKey)
                end
            end)

            return frame
        end

        -- LABEL
        function Tab:Label(text)
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, 0, 0, 22)
            frame.BackgroundTransparency = 1
            frame.Parent = TabContent

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -10, 1, 0)
            label.Position = UDim2.new(0, 5, 0, 0)
            label.BackgroundTransparency = 1
            label.Text = text
            label.TextColor3 = Theme.TextDim
            label.Font = Enum.Font.GothamBold
            label.TextSize = 12
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = frame

            return frame
        end

        -- SEPARATOR
        function Tab:Separator()
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, -10, 0, 1)
            frame.Position = UDim2.new(0, 5, 0, 0)
            frame.BackgroundColor3 = Theme.Border
            frame.BorderSizePixel = 0
            frame.Parent = TabContent
            return frame
        end

        return Tab
    end

    -- Keybind global para toggle
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.RightShift then
            Window:Toggle()
        end
    end)

    return Window
end

-- ═════════════════════ EXPORT ═════════════════════
getgenv().FurryUI = FurryUI
return FurryUI
