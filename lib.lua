--[[
    🚀 PRISON LIFE CHEAT LIBRARY v3.0
    GitHub Raw: https://raw.githubusercontent.com/yourrepo/prison_life_cheat/main/lib.lua
    
    INSTRUÇÕES:
    loadstring(game:HttpGet("https://raw.githubusercontent.com/yourrepo/prison_life_cheat/main/lib.lua"))()
    
    COMANDOS NO CONSOLE:
    - PL.Toggle("AutoFire")     -- Ativa/Desativa função
    - PL.Start()                -- Inicia todas as funções
    - PL.Stop()                 -- Para todas as funções
    - PL.Config                 -- Mostra configuração atual
]]

-- ============ VERIFICAÇÃO DO JOGO ============
if game.PlaceId ~= 155615604 then
    warn("[ERROR] Jogo não suportado! Use apenas no Prison Life.")
    return
end

-- ============ CONFIGURAÇÃO ============
local Config = {
    AutoFire = false,
    AutoFireDelay = 0.08,
    SilentAim = false,
    SilentAimFOV = 150,
    ESP = false,
    ESPBoxColor = Color3.fromRGB(255, 0, 0),
    ESPLineColor = Color3.fromRGB(255, 255, 255),
    InfiniteAmmo = false,
    AutoCuff = false,
    AutoArrest = false,
    SpeedHack = false,
    SpeedMultiplier = 3,
    FlyHack = false,
    FlySpeed = 100,
    GodMode = false,
    NoClip = false,
    TeamChanger = false,
    KillAll = false,
    TriggerBot = false,
    AimbotFOV = 150,
    AimbotSmoothness = 5
}

-- ============ DECLARAÇÃO GLOBAL ============
getgenv().PL = {}
local PL = getgenv().PL

-- ============ SERVICES ============
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Teams = game:GetService("Teams")
local HttpService = game:GetService("HttpService")
local Player = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ============ REMOTES ============
local Remotes = {}
local function GetRemotes()
    local success, result = pcall(function()
        local GunRemotes = ReplicatedStorage:WaitForChild("GunRemotes", 5)
        local MainRemotes = ReplicatedStorage:WaitForChild("Remotes", 5)
        
        return {
            ShootEvent = GunRemotes:FindFirstChild("ShootEvent"),
            EquipEvent = GunRemotes:FindFirstChild("EquipEvent"),
            UnequipEvent = GunRemotes:FindFirstChild("UnequipEvent"),
            FuncReload = GunRemotes:FindFirstChild("FuncReload"),
            PlayerTased = GunRemotes:FindFirstChild("PlayerTased"),
            RequestTeamChange = MainRemotes:FindFirstChild("RequestTeamChange"),
            ArrestPlayer = MainRemotes:FindFirstChild("ArrestPlayer"),
            ClientArrested = MainRemotes:FindFirstChild("ClientArrested"),
            InteractWithItem = MainRemotes:FindFirstChild("InteractWithItem"),
            MeleeEvent = ReplicatedStorage:FindFirstChild("meleeEvent")
        }
    end)
    return success and result or nil
end

Remotes = GetRemotes()
if not Remotes or not Remotes.ShootEvent then
    warn("[ERROR] Não foi possível encontrar os remotes!")
    return
end

-- ============ VARIÁVEIS DE ESTADO ============
local State = {
    ESPObjects = {},
    FlyBodyVelocity = nil,
    FlyBodyGyro = nil,
    IsRunning = false,
    Connections = {},
    OriginalFunctions = {}
}

-- ============ FUNÇÕES AUXILIARES ============

local function GetClosestPlayer()
    local closest = nil
    local shortest = math.huge
    local mousePos = UserInputService:GetMouseLocation()
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player == Player then continue end
        if player.Team == Player.Team then continue end
        
        local char = player.Character
        if not char then continue end
        
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end
        
        local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
        if not onScreen then continue end
        
        local dist = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
        if dist < shortest and dist < Config.AimbotFOV then
            shortest = dist
            closest = player
        end
    end
    return closest
end

local function GetPlayerFromPart(part)
    if not part then return nil end
    local parent = part.Parent
    while parent do
        if parent:IsA("Model") then
            return Players:GetPlayerFromCharacter(parent)
        end
        parent = parent.Parent
    end
    return nil
end

-- ============ FUNÇÕES DO CHEAT ============

-- 1. AUTO FIRE
local function AutoFire()
    if not Config.AutoFire then return end
    
    local char = Player.Character
    if not char then return end
    
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then return end
    
    local target = nil
    if Config.SilentAim then
        target = GetClosestPlayer()
    end
    
    if target and target.Character then
        local hrp = target.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            pcall(function()
                Remotes.ShootEvent:FireServer(hrp)
            end)
        end
    else
        pcall(function()
            Remotes.ShootEvent:FireServer(nil)
        end)
    end
end

-- 2. SILENT AIM
local function SetupSilentAim()
    -- Hook da função de tiro
    for _, v in ipairs(getgc(true)) do
        if type(v) == "function" and isexecutorclosure(v) then
            local info = pcall(debug.getinfo, v)
            if info and type(info) == "table" and info.name then
                if string.find(string.lower(info.name or ""), "shoot") then
                    if not State.OriginalFunctions.Shoot then
                        State.OriginalFunctions.Shoot = v
                        hookfunction(v, function(...)
                            local args = {...}
                            if Config.SilentAim then
                                local target = GetClosestPlayer()
                                if target and target.Character then
                                    local hrp = target.Character:FindFirstChild("HumanoidRootPart")
                                    if hrp then
                                        args[2] = hrp
                                        args[3] = CFrame.new(hrp.Position)
                                    end
                                end
                            end
                            return State.OriginalFunctions.Shoot(unpack(args))
                        end)
                    end
                    break
                end
            end
        end
    end
end

-- 3. ESP (Wallhack)
local function CreateESP(player)
    if player == Player then return end
    
    local espData = {
        Player = player,
        Box = Drawing.new("Box"),
        Line = Drawing.new("Line"),
        Text = Drawing.new("Text"),
        Name = Drawing.new("Text"),
        Health = Drawing.new("Text")
    }
    
    espData.Box.Color = Config.ESPBoxColor
    espData.Box.Thickness = 2
    espData.Box.Transparency = 0.5
    espData.Box.Filled = true
    espData.Box.FillColor = Config.ESPBoxColor
    espData.Box.FillTransparency = 0.2
    
    espData.Line.Color = Config.ESPLineColor
    espData.Line.Thickness = 1
    espData.Line.Transparency = 0.5
    
    espData.Text.Color = Color3.fromRGB(255, 255, 255)
    espData.Text.Size = 12
    espData.Text.Center = true
    espData.Text.Outline = true
    espData.Text.OutlineColor = Color3.fromRGB(0, 0, 0)
    
    espData.Name.Color = Color3.fromRGB(255, 255, 0)
    espData.Name.Size = 14
    espData.Name.Center = true
    espData.Name.Outline = true
    espData.Name.OutlineColor = Color3.fromRGB(0, 0, 0)
    
    espData.Health.Color = Color3.fromRGB(0, 255, 0)
    espData.Health.Size = 10
    espData.Health.Center = true
    espData.Health.Outline = true
    espData.Health.OutlineColor = Color3.fromRGB(0, 0, 0)
    
    table.insert(State.ESPObjects, espData)
    return espData
end

local function UpdateESP()
    if not Config.ESP then
        for _, esp in ipairs(State.ESPObjects) do
            esp.Box.Visible = false
            esp.Line.Visible = false
            esp.Text.Visible = false
            esp.Name.Visible = false
            esp.Health.Visible = false
        end
        return
    end
    
    for _, esp in ipairs(State.ESPObjects) do
        local player = esp.Player
        if not player then continue end
        
        local char = player.Character
        if not char then 
            esp.Box.Visible = false
            esp.Line.Visible = false
            esp.Text.Visible = false
            esp.Name.Visible = false
            esp.Health.Visible = false
            continue 
        end
        
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end
        
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then continue end
        
        local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
        if not onScreen then
            esp.Box.Visible = false
            esp.Line.Visible = false
            esp.Text.Visible = false
            esp.Name.Visible = false
            esp.Health.Visible = false
            continue
        end
        
        local distance = (Camera.CFrame.Position - hrp.Position).Magnitude
        local size = math.clamp(150 / distance * 2, 10, 150)
        local x, y = pos.X, pos.Y
        
        local healthPercent = hum.Health / hum.MaxHealth
        local healthColor = Color3.fromRGB(
            255 * (1 - healthPercent),
            255 * healthPercent,
            0
        )
        
        -- Atualiza a caixa
        esp.Box.Position = Vector2.new(x - size/2, y - size/2)
        esp.Box.Size = Vector2.new(size, size * 1.5)
        esp.Box.Visible = true
        
        -- Atualiza a linha
        esp.Line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
        esp.Line.To = Vector2.new(x, y)
        esp.Line.Visible = true
        
        -- Atualiza os textos
        esp.Text.Position = Vector2.new(x, y + size/2 + 20)
        esp.Text.Text = string.format("%.0fm", distance / 10)
        esp.Text.Visible = true
        
        esp.Name.Position = Vector2.new(x, y - size/2 - 25)
        esp.Name.Text = player.Name
        esp.Name.Visible = true
        
        esp.Health.Position = Vector2.new(x, y + size/2 + 5)
        esp.Health.Text = string.format("%.0f%%", healthPercent * 100)
        esp.Health.Color = healthColor
        esp.Health.Visible = true
    end
end

-- 4. INFINITE AMMO
local function SetupInfiniteAmmo()
    for _, v in ipairs(getgc(true)) do
        if type(v) == "function" then
            local info = pcall(debug.getinfo, v)
            if info and type(info) == "table" and info.name then
                local name = string.lower(info.name or "")
                if string.find(name, "ammo") or string.find(name, "changeammo") then
                    if isexecutorclosure(v) then
                        hookfunction(v, function(...)
                            if Config.InfiniteAmmo then
                                return 999, 999
                            end
                            return v(...)
                        end)
                        break
                    end
                end
            end
        end
    end
end

-- 5. AUTO CUFF
local function AutoCuff()
    if not Config.AutoCuff then return end
    
    local char = Player.Character
    if not char then return end
    
    local myHrp = char:FindFirstChild("HumanoidRootPart")
    if not myHrp then return end
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player == Player then continue end
        
        local targetChar = player.Character
        if not targetChar then continue end
        
        local targetHrp = targetChar:FindFirstChild("HumanoidRootPart")
        if not targetHrp then continue end
        
        local dist = (myHrp.Position - targetHrp.Position).Magnitude
        if dist < 15 then
            pcall(function()
                local tool = char:FindFirstChild("Handcuffs")
                if tool then
                    local cuffEvent = tool:FindFirstChild("CuffEvent")
                    if cuffEvent then
                        cuffEvent:FireServer("Cuff", targetChar)
                    end
                end
            end)
        end
    end
end

-- 6. AUTO ARREST
local function AutoArrest()
    if not Config.AutoArrest then return end
    
    local char = Player.Character
    if not char then return end
    
    local myHrp = char:FindFirstChild("HumanoidRootPart")
    if not myHrp then return end
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player == Player then continue end
        if player.Team == Player.Team then continue end
        
        local targetChar = player.Character
        if not targetChar then continue end
        
        local targetHrp = targetChar:FindFirstChild("HumanoidRootPart")
        if not targetHrp then continue end
        
        local dist = (myHrp.Position - targetHrp.Position).Magnitude
        if dist < 20 then
            pcall(function()
                Remotes.ArrestPlayer:InvokeServer(player)
            end)
        end
    end
end

-- 7. SPEED HACK
local function SetupSpeedHack()
    local char = Player.Character
    if not char then return end
    
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    
    if Config.SpeedHack then
        hum.WalkSpeed = 16 * Config.SpeedMultiplier
    else
        hum.WalkSpeed = 16
    end
end

-- 8. FLY HACK
local function SetupFlyHack()
    local char = Player.Character
    if not char then return end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    if not Config.FlyHack then
        if State.FlyBodyVelocity then
            State.FlyBodyVelocity:Destroy()
            State.FlyBodyVelocity = nil
        end
        if State.FlyBodyGyro then
            State.FlyBodyGyro:Destroy()
            State.FlyBodyGyro = nil
        end
        return
    end
    
    if not State.FlyBodyVelocity then
        State.FlyBodyVelocity = Instance.new("BodyVelocity")
        State.FlyBodyVelocity.MaxForce = Vector3.new(100000, 100000, 100000)
        State.FlyBodyVelocity.Parent = hrp
        
        State.FlyBodyGyro = Instance.new("BodyGyro")
        State.FlyBodyGyro.MaxTorque = Vector3.new(400000, 400000, 400000)
        State.FlyBodyGyro.Parent = hrp
    end
    
    local moveVector = Vector3.new(0, 0, 0)
    local cameraCF = Camera.CFrame
    
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then
        moveVector = moveVector + cameraCF.LookVector * Vector3.new(1, 0, 1)
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then
        moveVector = moveVector - cameraCF.LookVector * Vector3.new(1, 0, 1)
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then
        moveVector = moveVector - cameraCF.RightVector * Vector3.new(1, 0, 1)
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then
        moveVector = moveVector + cameraCF.RightVector * Vector3.new(1, 0, 1)
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
        moveVector = moveVector + Vector3.new(0, 1, 0)
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        moveVector = moveVector - Vector3.new(0, 1, 0)
    end
    
    if moveVector.Magnitude > 0 then
        moveVector = moveVector.Unit * Config.FlySpeed
    end
    
    State.FlyBodyVelocity.Velocity = moveVector
    State.FlyBodyGyro.CFrame = CFrame.new(hrp.Position, hrp.Position + cameraCF.LookVector)
end

-- 9. GOD MODE
local function SetupGodMode()
    local char = Player.Character
    if not char then return end
    
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    
    if Config.GodMode then
        hum.MaxHealth = 9999
        hum.Health = 9999
    else
        hum.MaxHealth = 100
        hum.Health = 100
    end
end

-- 10. NO CLIP
local function SetupNoClip()
    local char = Player.Character
    if not char then return end
    
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = not Config.NoClip
        end
    end
end

-- 11. TEAM CHANGER
local function ChangeTeam()
    if not Config.TeamChanger then return end
    
    local teams = Teams:GetChildren()
    local currentTeam = Player.Team
    
    for _, team in ipairs(teams) do
        if team ~= currentTeam and team:IsA("Team") then
            pcall(function()
                Remotes.RequestTeamChange:InvokeServer(team)
                print("[Team Changer] Mudou para: " .. team.Name)
            end)
            break
        end
    end
end

-- 12. KILL ALL
local function KillAll()
    if not Config.KillAll then return end
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player == Player then continue end
        
        local char = player.Character
        if not char then continue end
        
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end
        
        for i = 1, 3 do
            pcall(function()
                Remotes.ShootEvent:FireServer(hrp)
            end)
            task.wait(0.05)
        end
    end
    
    Config.KillAll = false
end

-- 13. TRIGGER BOT
local function SetupTriggerBot()
    hookmetamethod(getmetatable(Player:GetMouse()), "__index", function(self, key)
        if key == "Target" and Config.TriggerBot then
            local target = rawget(self, key)
            if target then
                local player = GetPlayerFromPart(target)
                if player and player ~= Player and player.Team ~= Player.Team then
                    task.spawn(function()
                        local char = player.Character
                        if char then
                            local hrp = char:FindFirstChild("HumanoidRootPart")
                            if hrp then
                                Remotes.ShootEvent:FireServer(hrp)
                            end
                        end
                    end)
                end
            end
            return target
        end
        return rawget(self, key)
    end)
end

-- ============ SISTEMA DE LOOP ============

local function MainLoop()
    -- ESP
    UpdateESP()
    
    -- Fly Hack
    if Config.FlyHack then
        SetupFlyHack()
    end
    
    -- Auto Fire
    if Config.AutoFire then
        AutoFire()
    end
    
    -- Auto Cuff
    if Config.AutoCuff then
        AutoCuff()
    end
    
    -- Auto Arrest
    if Config.AutoArrest then
        AutoArrest()
    end
    
    -- God Mode
    if Config.GodMode then
        SetupGodMode()
    end
    
    -- No Clip
    if Config.NoClip then
        SetupNoClip()
    end
    
    -- Speed Hack
    if Config.SpeedHack then
        SetupSpeedHack()
    end
end

-- ============ INICIALIZAÇÃO ============

local function Initialize()
    if State.IsRunning then return end
    
    -- Criar ESP para todos os jogadores
    for _, player in ipairs(Players:GetPlayers()) do
        CreateESP(player)
    end
    
    Players.PlayerAdded:Connect(function(player)
        CreateESP(player)
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        for i, esp in ipairs(State.ESPObjects) do
            if esp.Player == player then
                esp.Box.Visible = false
                esp.Line.Visible = false
                esp.Text.Visible = false
                esp.Name.Visible = false
                esp.Health.Visible = false
                table.remove(State.ESPObjects, i)
                break
            end
        end
    end)
    
    -- Inicia o loop principal
    State.Connections.MainLoop = RunService.Heartbeat:Connect(MainLoop)
    
    -- Configurações iniciais
    SetupSilentAim()
    SetupInfiniteAmmo()
    SetupTriggerBot()
    
    State.IsRunning = true
    print("[PL] ✅ Prison Life Cheat Library inicializada!")
    print("[PL] 📌 Use PL.Toggle('Nome') para ativar/desativar funções")
    print("[PL] 📌 Use PL.Start() para iniciar tudo")
    print("[PL] 📌 Use PL.Stop() para parar tudo")
end

-- ============ EXPORTAÇÃO ============

PL.Config = Config
PL.State = State
PL.Remotes = Remotes

PL.Toggle = function(name)
    if Config[name] ~= nil then
        Config[name] = not Config[name]
        print(string.format("[PL] 🔄 %s: %s", name, Config[name] and "ON" or "OFF"))
        
        -- Ações específicas para ativação imediata
        if name == "KillAll" and Config.KillAll then
            KillAll()
        elseif name == "TeamChanger" and Config.TeamChanger then
            ChangeTeam()
        end
        return true
    else
        warn("[PL] ⚠️ Função '" .. name .. "' não encontrada!")
        return false
    end
end

PL.Start = function()
    Initialize()
end

PL.Stop = function()
    if not State.IsRunning then return end
    
    -- Desconecta todos os loops
    for _, connection in pairs(State.Connections) do
        if connection and connection.Disconnect then
            connection:Disconnect()
        end
    end
    State.Connections = {}
    
    -- Limpa ESP
    for _, esp in ipairs(State.ESPObjects) do
        esp.Box.Visible = false
        esp.Line.Visible = false
        esp.Text.Visible = false
        esp.Name.Visible = false
        esp.Health.Visible = false
    end
    
    -- Remove fly
    if State.FlyBodyVelocity then
        State.FlyBodyVelocity:Destroy()
        State.FlyBodyVelocity = nil
    end
    if State.FlyBodyGyro then
        State.FlyBodyGyro:Destroy()
        State.FlyBodyGyro = nil
    end
    
    State.IsRunning = false
    print("[PL] ⏹️ Cheat parado!")
end

PL.Status = function()
    print("[PL] 📊 Status:")
    print("[PL] Running: " .. tostring(State.IsRunning))
    print("[PL] ESP Objects: " .. #State.ESPObjects)
    print("[PL] Configurações:")
    for key, value in pairs(Config) do
        if type(value) == "boolean" then
            print(string.format("  %s: %s", key, value and "ON" or "OFF"))
        end
    end
end

PL.Help = function()
    print([[
[PL] 📖 COMANDOS DISPONÍVEIS:
    
    PL.Toggle("Nome")     - Ativa/Desativa função
    PL.Start()           - Inicia todas as funções
    PL.Stop()            - Para todas as funções
    PL.Status()          - Mostra status atual
    PL.Config            - Mostra configuração
    
    FUNÇÕES DISPONÍVEIS:
    AutoFire, SilentAim, ESP, InfiniteAmmo,
    AutoCuff, AutoArrest, SpeedHack, FlyHack,
    GodMode, NoClip, TeamChanger, KillAll, TriggerBot
    
    KEYBINDS:
    F1 - Abrir/Fechar GUI
    WASD + Space/Ctrl - Fly Hack
    
    EXAMPLE:
    PL.Toggle("AutoFire")
    PL.Start()
]])
end

-- ============ GUI ============

local function CreateGUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "PL_Cheat"
    screenGui.Parent = gethui()
    screenGui.ResetOnSpawn = false
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 350, 0, 480)
    mainFrame.Position = UDim2.new(0.5, -175, 0.5, -240)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
    mainFrame.BackgroundTransparency = 0.15
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    
    -- Título
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 35)
    titleBar.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    titleBar.BackgroundTransparency = 0.2
    titleBar.Parent = mainFrame
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -40, 1, 0)
    title.Position = UDim2.new(0, 10, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "⚡ PRISON LIFE v3.0"
    title.TextColor3 = Color3.fromRGB(255, 200, 50)
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.Parent = titleBar
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 35, 1, 0)
    closeBtn.Position = UDim2.new(1, -35, 0, 0)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(255, 50, 50)
    closeBtn.TextScaled = true
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = titleBar
    closeBtn.MouseButton1Click:Connect(function()
        mainFrame.Visible = not mainFrame.Visible
    end)
    
    -- Scroll
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -10, 1, -45)
    scroll.Position = UDim2.new(0, 5, 0, 40)
    scroll.BackgroundTransparency = 1
    scroll.CanvasSize = UDim2.new(0, 0, 0, 600)
    scroll.ScrollBarThickness = 3
    scroll.Parent = mainFrame
    
    local function CreateToggle(parent, text, y)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, -20, 0, 30)
        frame.Position = UDim2.new(0, 10, 0, y)
        frame.BackgroundTransparency = 1
        frame.Parent = parent
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0.7, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = Color3.fromRGB(220, 220, 220)
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Font = Enum.Font.Gotham
        label.TextSize = 13
        label.Parent = frame
        
        local toggle = Instance.new("TextButton")
        toggle.Size = UDim2.new(0, 55, 0, 23)
        toggle.Position = UDim2.new(0.8, 0, 0, 3)
        toggle.BackgroundColor3 = Color3.fromRGB(60, 60, 75)
        toggle.Text = "OFF"
        toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
        toggle.Font = Enum.Font.GothamBold
        toggle.TextSize = 11
        toggle.Parent = frame
        
        local function UpdateToggle()
            local key = string.gsub(text, " ", "")
            if Config[key] then
                toggle.BackgroundColor3 = Color3.fromRGB(0, 200, 50)
                toggle.Text = "ON"
            else
                toggle.BackgroundColor3 = Color3.fromRGB(60, 60, 75)
                toggle.Text = "OFF"
            end
        end
        
        toggle.MouseButton1Click:Connect(function()
            local key = string.gsub(text, " ", "")
            PL.Toggle(key)
            UpdateToggle()
        end)
        
        UpdateToggle()
        return toggle
    end
    
    local function CreateButton(parent, text, y, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -20, 0, 30)
        btn.Position = UDim2.new(0, 10, 0, y)
        btn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 13
        btn.Parent = parent
        btn.MouseButton1Click:Connect(callback)
        return btn
    end
    
    local toggles = {
        "AutoFire", "SilentAim", "ESP", "InfiniteAmmo",
        "AutoCuff", "AutoArrest", "SpeedHack", "FlyHack",
        "GodMode", "NoClip", "TeamChanger", "KillAll", "TriggerBot"
    }
    
    local yPos = 5
    for i, toggle in ipairs(toggles) do
        CreateToggle(scroll, toggle, yPos)
        yPos = yPos + 35
    end
    
    -- Botões de ação
    CreateButton(scroll, "▶ START", yPos, function()
        PL.Start()
    end)
    yPos = yPos + 35
    
    CreateButton(scroll, "⏹ STOP", yPos, function()
        PL.Stop()
    end)
    yPos = yPos + 35
    
    CreateButton(scroll, "📊 STATUS", yPos, function()
        PL.Status()
    end)
    yPos = yPos + 35
    
    -- Botão de ajuda
    local helpBtn = Instance.new("TextButton")
    helpBtn.Size = UDim2.new(1, -20, 0, 25)
    helpBtn.Position = UDim2.new(0, 10, 0, yPos + 10)
    helpBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    helpBtn.Text = "📖 HELP - Comandos no Console"
    helpBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    helpBtn.Font = Enum.Font.Gotham
    helpBtn.TextSize = 11
    helpBtn.Parent = scroll
    helpBtn.MouseButton1Click:Connect(function()
        PL.Help()
    end)
    
    return screenGui
end

-- ============ KEYBINDS ============

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.F1 then
        if GUI and GUI.MainFrame then
            GUI.MainFrame.Visible = not GUI.MainFrame.Visible
        end
    end
end)

-- ============ INICIALIZAÇÃO AUTOMÁTICA ============

print([[
╔═══════════════════════════════════════╗
║   🚀 PRISON LIFE CHEAT v3.0          ║
║   📌 Comandos disponíveis:            ║
║   • PL.Toggle("Nome")                 ║
║   • PL.Start() / PL.Stop()            ║
║   • PL.Status() / PL.Help()           ║
║   • Pressione F1 para abrir a GUI     ║
╚═══════════════════════════════════════╝
]])

-- Cria GUI
local GUI = CreateGUI()

-- Inicializa automaticamente
PL.Start()

-- Exporta para o console
print("[PL] ✅ Library carregada! Use PL.Help() para ajuda.")

-- Retorna a library
return PL
