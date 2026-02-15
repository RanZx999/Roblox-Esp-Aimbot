--[[
═══════════════════════════════════════════════════════════════
  RanZx999 Hub
═══════════════════════════════════════════════════════════════
KEYBINDS:
- INSERT: Toggle UI
- H: Toggle Aimbot ON/OFF
- DELETE: Destroy script
Created by RanZx999
═══════════════════════════════════════════════════════════════
]]

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = Workspace.CurrentCamera

--// MODERN COLORS
local Colors = {
    Background = Color3.fromRGB(25, 25, 30),
    Secondary = Color3.fromRGB(30, 30, 35),
    Primary = Color3.fromRGB(255, 105, 180),
    Accent = Color3.fromRGB(255, 150, 200),
    White = Color3.fromRGB(255, 255, 255),
    Text = Color3.fromRGB(230, 230, 230),
    TextDark = Color3.fromRGB(150, 150, 150),
    Toggle_On = Color3.fromRGB(255, 105, 180),
    Toggle_Off = Color3.fromRGB(60, 60, 70),
    Border = Color3.fromRGB(45, 45, 50),
    Red = Color3.fromRGB(255, 50, 80),
    Green = Color3.fromRGB(80, 255, 120)
}

--// CONFIG
local Config = {
    Aimlock = {
        Enabled = false,
        LockMode = true,
        Smooth = 0.2,
        Prediction = 0,
        AimPart = "Head",
        WallCheck = true,
        TeamCheck = true,
        AutoAim = true,
        UsePrediction = false
    },
    ESP = {
        Enabled = false,
        Boxes = true,
        Names = true,
        Distance = true,
        Health = true,
        Tracers = false,
        TeamCheck = true,
        MaxDistance = 2000
    },
    Highlight = {
        Enabled = false,
        TeamCheck = true,
        ShowTeam = false
    },
    Walkspeed = { Enabled = false, Speed = 50 },
    Noclip = { Enabled = false },
    OutlineTarget = true
}

--// STATE
local CurrentTarget = nil
local CurrentOutline = nil
local Connections = {}
local ESPObjects = {}

--// UTILITIES
local function isAlive(plr)
    if not plr or not plr.Character then return false end
    local hum = plr.Character:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    local be = plr.Character:FindFirstChild("BodyEffects")
    if be then
        local ko = be:FindFirstChild("K.O")
        local grabbed = be:FindFirstChild("GRABBING_CONSTRAINT")
        if (ko and ko.Value) or (grabbed and grabbed.Value) then return false end
    end
    return true
end

local function isTeammate(player)
    if not LocalPlayer.Team or not player.Team then return false end
    return player.Team == LocalPlayer.Team
end

local function isVisible(targetPart, player)
    if not Config.Aimlock.WallCheck then return true end
    if not targetPart or not player or not player.Character then return false end
    
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.IgnoreWater = true
    
    local origin = Camera.CFrame.Position
    local direction = targetPart.Position - origin
    local result = Workspace:Raycast(origin, direction, params)
    
    if not result then return true end
    if result.Instance:IsDescendantOf(player.Character) then return true end
    return false
end

local function getTargetPart(char)
    local partName = Config.Aimlock.AimPart
    
    if partName == "Random" then
        local parts = {"Head", "UpperTorso", "LowerTorso"}
        partName = parts[math.random(1, #parts)]
    elseif partName == "Body" then
        partName = "UpperTorso"
    end
    
    return char:FindFirstChild(partName) or char:FindFirstChild("HumanoidRootPart")
end

local function GetClosestPlayerToCursor()
    local closestPlayer = nil
    local shortestDistance = math.huge
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and isAlive(player) and player.Character then
            if Config.Aimlock.TeamCheck and isTeammate(player) then continue end
            
            local head = player.Character:FindFirstChild("Head")
            if head then
                local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
                if onScreen and isVisible(head, player) then
                    local mousePos = Vector2.new(Mouse.X, Mouse.Y)
                    local distance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    if distance < shortestDistance then
                        shortestDistance = distance
                        closestPlayer = player
                    end
                end
            end
        end
    end
    return closestPlayer
end

--// NOTIFICATION
local function Notify(msg, dur)
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "RanZx999 Hub", Text = msg, Duration = dur or 2
    })
end

--// OUTLINE
local function CreateOutline(char)
    if CurrentOutline then CurrentOutline:Destroy() CurrentOutline = nil end
    if not Config.OutlineTarget then return end
    local h = Instance.new("Highlight")
    h.Name = "RanZxOutline"
    h.Adornee = char
    h.FillColor = Colors.Primary
    h.FillTransparency = 0.5
    h.OutlineColor = Colors.Accent
    h.OutlineTransparency = 0
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    h.Parent = char
    CurrentOutline = h
end

--// AIMLOCK - PERFECT AIM
local AimlockConnection = nil
local function StartAimlock()
    if AimlockConnection then AimlockConnection:Disconnect() end
    
    AimlockConnection = RunService.RenderStepped:Connect(function()
        if not Config.Aimlock.Enabled then return end
        
        if Config.Aimlock.AutoAim then
            CurrentTarget = GetClosestPlayerToCursor()
            if CurrentTarget and CurrentTarget.Character then
                if not CurrentOutline or CurrentOutline.Adornee ~= CurrentTarget.Character then
                    CreateOutline(CurrentTarget.Character)
                end
            else
                if CurrentOutline then CurrentOutline:Destroy() CurrentOutline = nil end
            end
        end
        
        if not CurrentTarget or not isAlive(CurrentTarget) then return end
        
        local targetPart = getTargetPart(CurrentTarget.Character)
        if not targetPart then return end
        if not isVisible(targetPart, CurrentTarget) then return end
        
        -- FIX: Aim langsung ke center tanpa offset
        local targetPos = targetPart.Position
        
        -- Optional prediction
        if Config.Aimlock.UsePrediction then
            local root = CurrentTarget.Character:FindFirstChild("HumanoidRootPart")
            if root then
                local velocity = root.AssemblyLinearVelocity or root.Velocity or Vector3.zero
                local velocityMag = velocity.Magnitude
                
                if velocityMag > 10 then
                    targetPos = targetPos + (velocity * Config.Aimlock.Prediction)
                end
            end
        end
        
        if Config.Aimlock.LockMode then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPos)
        else
            Camera.CFrame = Camera.CFrame:Lerp(
                CFrame.new(Camera.CFrame.Position, targetPos),
                Config.Aimlock.Smooth
            )
        end
    end)
end

--// ESP SYSTEM
local function createESP(player)
    if player == LocalPlayer then return end
    ESPObjects[player] = {
        Box = Drawing.new("Square"),
        Name = Drawing.new("Text"),
        Distance = Drawing.new("Text"),
        HealthBarBG = Drawing.new("Square"),
        HealthBar = Drawing.new("Square"),
        Tracer = Drawing.new("Line")
    }
    local o = ESPObjects[player]
    o.Box.Thickness = 2
    o.Box.Filled = false
    o.Name.Size = 14
    o.Name.Center = true
    o.Name.Outline = true
    o.Name.OutlineColor = Color3.fromRGB(0, 0, 0)
    o.Distance.Size = 12
    o.Distance.Center = true
    o.Distance.Outline = true
    o.Distance.OutlineColor = Color3.fromRGB(0, 0, 0)
    o.HealthBar.Filled = true
    o.HealthBarBG.Filled = true
    o.HealthBarBG.Color = Color3.fromRGB(20, 20, 20)
end

local function removeESP(player)
    if ESPObjects[player] then
        for _, obj in pairs(ESPObjects[player]) do pcall(function() obj:Remove() end) end
        ESPObjects[player] = nil
    end
end

local function updateESP()
    if not Config.ESP.Enabled then
        for _, esp in pairs(ESPObjects) do for _, obj in pairs(esp) do obj.Visible = false end end
        return
    end
    
    for player, esp in pairs(ESPObjects) do
        if not player or not player.Parent then removeESP(player) continue end
        
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChild("Humanoid")
        
        if char and hrp and hum and hum.Health > 0 then
            if Config.ESP.TeamCheck and isTeammate(player) then
                for _, obj in pairs(esp) do obj.Visible = false end
                continue
            end
            
            local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
            local dist = (Camera.CFrame.Position - hrp.Position).Magnitude
            
            if onScreen and dist <= Config.ESP.MaxDistance then
                local color = isTeammate(player) and Colors.Green or Colors.Red
                local size = Vector2.new(2000/dist, 2500/dist)
                
                esp.Box.Visible = Config.ESP.Boxes
                esp.Box.Size = size
                esp.Box.Position = Vector2.new(screenPos.X - size.X/2, screenPos.Y - size.Y/2)
                esp.Box.Color = color
                
                esp.Name.Visible = Config.ESP.Names
                esp.Name.Text = player.Name
                esp.Name.Position = Vector2.new(screenPos.X, screenPos.Y - size.Y/2 - 15)
                esp.Name.Color = color
                
                esp.Distance.Visible = Config.ESP.Distance
                esp.Distance.Text = math.floor(dist).."m"
                esp.Distance.Position = Vector2.new(screenPos.X, screenPos.Y + size.Y/2 + 5)
                esp.Distance.Color = Color3.fromRGB(200, 200, 200)
                
                if Config.ESP.Health then
                    local hp = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                    esp.HealthBarBG.Visible = true
                    esp.HealthBarBG.Size = Vector2.new(4, size.Y)
                    esp.HealthBarBG.Position = Vector2.new(screenPos.X - size.X/2 - 6, screenPos.Y - size.Y/2)
                    esp.HealthBar.Visible = true
                    esp.HealthBar.Size = Vector2.new(4, size.Y * hp)
                    esp.HealthBar.Position = Vector2.new(screenPos.X - size.X/2 - 6, screenPos.Y + size.Y/2 - esp.HealthBar.Size.Y)
                    esp.HealthBar.Color = Color3.fromRGB(math.floor(255 * (1 - hp)), math.floor(255 * hp), 0)
                else
                    esp.HealthBarBG.Visible = false
                    esp.HealthBar.Visible = false
                end
                
                esp.Tracer.Visible = Config.ESP.Tracers
                esp.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                esp.Tracer.To = Vector2.new(screenPos.X, screenPos.Y + size.Y/2)
                esp.Tracer.Color = color
            else
                for _, obj in pairs(esp) do obj.Visible = false end
            end
        else
            for _, obj in pairs(esp) do obj.Visible = false end
        end
    end
end

--// HIGHLIGHT
local function updateHighlights()
    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local char = player.Character
        if char and Config.Highlight.Enabled then
            if Config.Highlight.TeamCheck and isTeammate(player) and not Config.Highlight.ShowTeam then
                local hl = char:FindFirstChildOfClass("Highlight")
                if hl and hl.Name == "RanZxHL" then hl:Destroy() end
                continue
            end
            local hl = char:FindFirstChildOfClass("Highlight")
            if not hl or hl.Name ~= "RanZxHL" then 
                hl = Instance.new("Highlight")
                hl.Name = "RanZxHL"
                hl.Parent = char
            end
            hl.FillColor = isTeammate(player) and Colors.Green or Colors.Red
            hl.OutlineColor = Colors.White
            hl.FillTransparency = 0.5
            hl.OutlineTransparency = 0
        elseif char then
            local hl = char:FindFirstChildOfClass("Highlight")
            if hl and hl.Name == "RanZxHL" then hl:Destroy() end
        end
    end
end

-- LOOPS
table.insert(Connections, RunService.RenderStepped:Connect(function()
    updateESP()
    updateHighlights()
end))

table.insert(Connections, RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChild("Humanoid")
        if hum and Config.Walkspeed.Enabled then hum.WalkSpeed = Config.Walkspeed.Speed end
    end
end))

table.insert(Connections, RunService.Stepped:Connect(function()
    local char = LocalPlayer.Character
    if char and Config.Noclip.Enabled then
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end
end))

--// MODERN UI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RanZx999Hub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = game:GetService("CoreGui")

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 420, 0, 60)
MainFrame.Position = UDim2.new(0.5, -210, 0, 30)
MainFrame.BackgroundColor3 = Colors.Background
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Colors.Border
MainStroke.Thickness = 1
MainStroke.Parent = MainFrame

-- Topbar
local Topbar = Instance.new("Frame")
Topbar.Name = "Topbar"
Topbar.Size = UDim2.new(1, 0, 0, 60)
Topbar.BackgroundColor3 = Colors.Secondary
Topbar.BorderSizePixel = 0
Topbar.Parent = MainFrame

local TopbarCorner = Instance.new("UICorner")
TopbarCorner.CornerRadius = UDim.new(0, 12)
TopbarCorner.Parent = Topbar

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, -120, 1, 0)
Title.Position = UDim2.new(0, 20, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "🎯 RanZx999 Hub"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18
Title.TextColor3 = Colors.Primary
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Topbar

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Name = "Status"
StatusLabel.Size = UDim2.new(0, 60, 0, 20)
StatusLabel.Position = UDim2.new(1, -140, 0.5, -10)
StatusLabel.BackgroundColor3 = Colors.Toggle_Off
StatusLabel.Text = "OFF"
StatusLabel.Font = Enum.Font.GothamBold
StatusLabel.TextSize = 11
StatusLabel.TextColor3 = Colors.White
StatusLabel.Parent = Topbar

local StatusCorner = Instance.new("UICorner")
StatusCorner.CornerRadius = UDim.new(0, 6)
StatusCorner.Parent = StatusLabel

local ArrowButton = Instance.new("TextButton")
ArrowButton.Name = "ArrowButton"
ArrowButton.Size = UDim2.new(0, 50, 0, 50)
ArrowButton.Position = UDim2.new(1, -55, 0.5, -25)
ArrowButton.BackgroundColor3 = Colors.Primary
ArrowButton.BorderSizePixel = 0
ArrowButton.Text = "▼"
ArrowButton.Font = Enum.Font.GothamBold
ArrowButton.TextSize = 20
ArrowButton.TextColor3 = Colors.White
ArrowButton.AutoButtonColor = false
ArrowButton.Parent = Topbar

local ArrowCorner = Instance.new("UICorner")
ArrowCorner.CornerRadius = UDim.new(0, 10)
ArrowCorner.Parent = ArrowButton

-- Tab Container
local TabContainer = Instance.new("Frame")
TabContainer.Name = "TabContainer"
TabContainer.Size = UDim2.new(1, 0, 0, 40)
TabContainer.Position = UDim2.new(0, 0, 0, 65)
TabContainer.BackgroundColor3 = Colors.Secondary
TabContainer.BorderSizePixel = 0
TabContainer.Parent = MainFrame

local TabLayout = Instance.new("UIListLayout")
TabLayout.FillDirection = Enum.FillDirection.Horizontal
TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabLayout.Padding = UDim.new(0, 2)
TabLayout.Parent = TabContainer

-- Content Frame
local ContentFrame = Instance.new("ScrollingFrame")
ContentFrame.Name = "ContentFrame"
ContentFrame.Size = UDim2.new(1, -10, 0, 420)
ContentFrame.Position = UDim2.new(0, 5, 0, 110)
ContentFrame.BackgroundTransparency = 1
ContentFrame.BorderSizePixel = 0
ContentFrame.ScrollBarThickness = 5
ContentFrame.ScrollBarImageColor3 = Colors.Primary
ContentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ContentFrame.Parent = MainFrame

local ContentLayout = Instance.new("UIListLayout")
ContentLayout.Padding = UDim.new(0, 8)
ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
ContentLayout.Parent = ContentFrame

ContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    ContentFrame.CanvasSize = UDim2.new(0, 0, 0, ContentLayout.AbsoluteContentSize.Y + 10)
end)

--// UI FUNCTIONS
local function CreateTab(name)
    local btn = Instance.new("TextButton")
    btn.Name = name.."Tab"
    btn.Size = UDim2.new(0.33, -2, 1, 0)
    btn.BackgroundColor3 = Colors.Background
    btn.BorderSizePixel = 0
    btn.Text = name
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.TextColor3 = Colors.Text
    btn.AutoButtonColor = false
    btn.Parent = TabContainer
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn
    
    return btn
end

local AimbotTab = CreateTab("Aimbot")
local ESPTab = CreateTab("ESP")
local MiscTab = CreateTab("Misc")

local function SwitchTab(tabName)
    AimbotTab.BackgroundColor3 = tabName == "Aimbot" and Colors.Primary or Colors.Background
    ESPTab.BackgroundColor3 = tabName == "ESP" and Colors.Primary or Colors.Background
    MiscTab.BackgroundColor3 = tabName == "Misc" and Colors.Primary or Colors.Background
    
    for _, child in pairs(ContentFrame:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    
    if tabName == "Aimbot" then CreateAimbotTab()
    elseif tabName == "ESP" then CreateESPTab()
    elseif tabName == "Misc" then CreateMiscTab() end
end

AimbotTab.MouseButton1Click:Connect(function() SwitchTab("Aimbot") end)
ESPTab.MouseButton1Click:Connect(function() SwitchTab("ESP") end)
MiscTab.MouseButton1Click:Connect(function() SwitchTab("Misc") end)

local function CreateToggle(text, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 38)
    frame.BackgroundColor3 = Colors.Secondary
    frame.BorderSizePixel = 0
    frame.Parent = ContentFrame
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -65, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextColor3 = Colors.Text
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 48, 0, 24)
    button.Position = UDim2.new(1, -56, 0.5, -12)
    button.BackgroundColor3 = default and Colors.Toggle_On or Colors.Toggle_Off
    button.BorderSizePixel = 0
    button.Text = ""
    button.AutoButtonColor = false
    button.Parent = frame
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(1, 0)
    buttonCorner.Parent = button
    
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 18, 0, 18)
    knob.Position = default and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
    knob.BackgroundColor3 = Colors.White
    knob.BorderSizePixel = 0
    knob.Parent = button
    
    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob
    
    local enabled = default
    
    -- Function to update toggle visuals
    local function updateToggle(state)
        enabled = state
        TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = state and Colors.Toggle_On or Colors.Toggle_Off}):Play()
        TweenService:Create(knob, TweenInfo.new(0.2), {Position = state and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)}):Play()
    end
    
    button.MouseButton1Click:Connect(function()
        enabled = not enabled
        updateToggle(enabled)
        if callback then callback(enabled) end
    end)
    
    -- Return update function so it can be called externally
    return updateToggle
end

local function CreateSlider(text, min, max, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 50)
    frame.BackgroundColor3 = Colors.Secondary
    frame.BorderSizePixel = 0
    frame.Parent = ContentFrame
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.7, 0, 0, 22)
    label.Position = UDim2.new(0, 12, 0, 6)
    label.BackgroundTransparency = 1
    label.Text = text
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.TextColor3 = Colors.Text
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0.3, -12, 0, 22)
    valueLabel.Position = UDim2.new(0.7, 0, 0, 6)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(default)
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextSize = 13
    valueLabel.TextColor3 = Colors.Primary
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = frame
    
    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -24, 0, 4)
    track.Position = UDim2.new(0, 12, 1, -14)
    track.BackgroundColor3 = Colors.Border
    track.BorderSizePixel = 0
    track.Parent = frame
    
    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(1, 0)
    trackCorner.Parent = track
    
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Colors.Primary
    fill.BorderSizePixel = 0
    fill.Parent = track
    
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = fill
    
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = UDim2.new((default - min) / (max - min), -7, 0.5, -7)
    knob.BackgroundColor3 = Colors.White
    knob.BorderSizePixel = 0
    knob.Parent = track
    
    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob
    
    local dragging = false
    local function update(input)
        local trackSize = track.AbsoluteSize.X
        local mousePos = input.Position.X - track.AbsolutePosition.X
        local percent = math.clamp(mousePos / trackSize, 0, 1)
        local value = min + (max - min) * percent
        value = math.floor(value * 100 + 0.5) / 100
        valueLabel.Text = tostring(value)
        fill.Size = UDim2.new(percent, 0, 1, 0)
        knob.Position = UDim2.new(percent, -7, 0.5, -7)
        if callback then callback(value) end
    end
    
    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            update(input)
        end
    end)
    
    track.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            update(input)
        end
    end)
end

local function CreateButtonDropdown(text, options, default, callback)
    local currentIndex = 1
    for i, opt in ipairs(options) do
        if opt == default then currentIndex = i break end
    end
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 38)
    frame.BackgroundColor3 = Colors.Secondary
    frame.BorderSizePixel = 0
    frame.Parent = ContentFrame
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.35, 0, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.TextColor3 = Colors.Text
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0.65, -18, 0, 28)
    button.Position = UDim2.new(0.35, 6, 0.5, -14)
    button.BackgroundColor3 = Colors.Primary
    button.BorderSizePixel = 0
    button.Text = "< " .. options[currentIndex] .. " >"
    button.Font = Enum.Font.GothamBold
    button.TextSize = 12
    button.TextColor3 = Colors.White
    button.AutoButtonColor = false
    button.Parent = frame
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = button
    
    button.MouseButton1Click:Connect(function()
        currentIndex = currentIndex + 1
        if currentIndex > #options then currentIndex = 1 end
        button.Text = "< " .. options[currentIndex] .. " >"
        if callback then callback(options[currentIndex]) end
    end)
end

--// TAB CONTENTS
function CreateAimbotTab()
    -- Store the update function globally
    _G.AimbotToggleUpdate = CreateToggle("🎯 Enable Aimbot", Config.Aimlock.Enabled, function(val)
        Config.Aimlock.Enabled = val
        if val then
            StartAimlock()
            StatusLabel.BackgroundColor3 = Colors.Toggle_On
            StatusLabel.Text = "ON"
            Notify("🎯 Aimbot " .. (Config.Aimlock.LockMode and "LOCK" or "SMOOTH"), 2)
        else
            if AimlockConnection then AimlockConnection:Disconnect() end
            CurrentTarget = nil
            if CurrentOutline then CurrentOutline:Destroy() CurrentOutline = nil end
            StatusLabel.BackgroundColor3 = Colors.Toggle_Off
            StatusLabel.Text = "OFF"
            Notify("🎯 Aimbot OFF", 2)
        end
    end)
    
    -- Add keybind hint label
    local keybindHint = Instance.new("Frame")
    keybindHint.Size = UDim2.new(1, 0, 0, 30)
    keybindHint.BackgroundColor3 = Color3.fromRGB(255, 105, 180)
    keybindHint.BackgroundTransparency = 0.9
    keybindHint.BorderSizePixel = 0
    keybindHint.Parent = ContentFrame
    
    local hintCorner = Instance.new("UICorner")
    hintCorner.CornerRadius = UDim.new(0, 8)
    hintCorner.Parent = keybindHint
    
    local hintLabel = Instance.new("TextLabel")
    hintLabel.Size = UDim2.new(1, -20, 1, 0)
    hintLabel.Position = UDim2.new(0, 10, 0, 0)
    hintLabel.BackgroundTransparency = 1
    hintLabel.Text = "💡 Tip: Press H to quick toggle aimbot"
    hintLabel.Font = Enum.Font.GothamBold
    hintLabel.TextSize = 11
    hintLabel.TextColor3 = Colors.Primary
    hintLabel.TextXAlignment = Enum.TextXAlignment.Center
    hintLabel.Parent = keybindHint
    
    CreateToggle("🔒 LOCK Mode (Instant)", Config.Aimlock.LockMode, function(val)
        Config.Aimlock.LockMode = val
        Notify(val and "🔒 LOCK MODE!" or "🌊 SMOOTH MODE", 2)
    end)
    
    CreateToggle("🤖 Auto Target", Config.Aimlock.AutoAim, function(val)
        Config.Aimlock.AutoAim = val
    end)
    
    CreateButtonDropdown("Aim Part", {"Head", "Body", "Random"}, Config.Aimlock.AimPart, function(val)
        Config.Aimlock.AimPart = val
        Notify("Targeting: " .. val, 1.5)
    end)
    
    CreateToggle("⚡ Use Prediction", Config.Aimlock.UsePrediction, function(val)
        Config.Aimlock.UsePrediction = val
        Notify(val and "⚡ Prediction ON" or "🎯 Direct Aim", 2)
    end)
    
    CreateSlider("Smoothness", 0.05, 0.5, Config.Aimlock.Smooth, function(val)
        Config.Aimlock.Smooth = val
    end)
    
    CreateSlider("Prediction Value", 0, 0.3, Config.Aimlock.Prediction, function(val)
        Config.Aimlock.Prediction = val
    end)
    
    CreateToggle("✅ Wall Check", Config.Aimlock.WallCheck, function(val)
        Config.Aimlock.WallCheck = val
    end)
    
    CreateToggle("✅ Team Check", Config.Aimlock.TeamCheck, function(val)
        Config.Aimlock.TeamCheck = val
    end)
    
    CreateToggle("✨ Target Outline", Config.OutlineTarget, function(val)
        Config.OutlineTarget = val
    end)
end

function CreateESPTab()
    CreateToggle("🔍 Enable ESP", Config.ESP.Enabled, function(val)
        Config.ESP.Enabled = val
        if val then
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer then createESP(p) end
            end
        end
    end)
    CreateToggle("📦 Boxes", Config.ESP.Boxes, function(val) Config.ESP.Boxes = val end)
    CreateToggle("👤 Names", Config.ESP.Names, function(val) Config.ESP.Names = val end)
    CreateToggle("📏 Distance", Config.ESP.Distance, function(val) Config.ESP.Distance = val end)
    CreateToggle("❤️ Health Bar", Config.ESP.Health, function(val) Config.ESP.Health = val end)
    CreateToggle("📍 Tracers", Config.ESP.Tracers, function(val) Config.ESP.Tracers = val end)
    CreateToggle("✅ Team Check", Config.ESP.TeamCheck, function(val) Config.ESP.TeamCheck = val end)
    CreateSlider("Max Distance", 500, 5000, Config.ESP.MaxDistance, function(val) Config.ESP.MaxDistance = val end)
    CreateToggle("✨ Highlight ESP", Config.Highlight.Enabled, function(val) Config.Highlight.Enabled = val end)
    CreateToggle("✅ HL Team Check", Config.Highlight.TeamCheck, function(val) Config.Highlight.TeamCheck = val end)
    CreateToggle("👥 Show Team HL", Config.Highlight.ShowTeam, function(val) Config.Highlight.ShowTeam = val end)
end

function CreateMiscTab()
    CreateToggle("⚡ Walkspeed", Config.Walkspeed.Enabled, function(val)
        Config.Walkspeed.Enabled = val
    end)
    CreateSlider("Speed", 16, 300, Config.Walkspeed.Speed, function(val)
        Config.Walkspeed.Speed = val
    end)
    CreateToggle("👻 Noclip", Config.Noclip.Enabled, function(val)
        Config.Noclip.Enabled = val
    end)
end

SwitchTab("Aimbot")

--// KEYBINDS
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    
    -- Toggle UI
    if input.KeyCode == Enum.KeyCode.Insert then
        MainFrame.Visible = not MainFrame.Visible
    end
    
    -- Toggle Aimbot (H key)
    if input.KeyCode == Enum.KeyCode.H then
        Config.Aimlock.Enabled = not Config.Aimlock.Enabled
        
        -- Update toggle UI if it exists
        if _G.AimbotToggleUpdate then
            _G.AimbotToggleUpdate(Config.Aimlock.Enabled)
        end
        
        if Config.Aimlock.Enabled then
            StartAimlock()
            StatusLabel.BackgroundColor3 = Colors.Toggle_On
            StatusLabel.Text = "ON"
            Notify("🎯 Aimbot ON [H]", 2)
        else
            if AimlockConnection then AimlockConnection:Disconnect() end
            CurrentTarget = nil
            if CurrentOutline then CurrentOutline:Destroy() CurrentOutline = nil end
            StatusLabel.BackgroundColor3 = Colors.Toggle_Off
            StatusLabel.Text = "OFF"
            Notify("🎯 Aimbot OFF [H]", 2)
        end
    end
    
    -- Destroy script
    if input.KeyCode == Enum.KeyCode.Delete then
        for _, conn in pairs(Connections) do conn:Disconnect() end
        for player, _ in pairs(ESPObjects) do removeESP(player) end
        if AimlockConnection then AimlockConnection:Disconnect() end
        if CurrentOutline then CurrentOutline:Destroy() end
        ScreenGui:Destroy()
        Notify("Script Destroyed!", 2)
    end
end)

--// EXPAND/COLLAPSE
local IsExpanded = false
ArrowButton.MouseButton1Click:Connect(function()
    IsExpanded = not IsExpanded
    TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {
        Size = UDim2.new(0, 420, 0, IsExpanded and 540 or 60)
    }):Play()
    TweenService:Create(ArrowButton, TweenInfo.new(0.2), {Rotation = IsExpanded and 180 or 0}):Play()
    ArrowButton.Text = IsExpanded and "▲" or "▼"
end)

--// DRAGGING
local dragging, dragInput, dragStart, startPos = false
Topbar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
Topbar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and input == dragInput then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

--// EVENTS
Players.PlayerAdded:Connect(createESP)
Players.PlayerRemoving:Connect(function(player)
    removeESP(player)
    if CurrentTarget == player then CurrentTarget = nil end
end)
for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer then createESP(p) end end

wait(1)
Notify("🎯 RanZx999 Hub Loaded!", 3)
Notify("✅ Press H to toggle aimbot!", 2)
print("═══════════════════════════════════════════════════════")
print("🎯 RanZx999 Hub - NO ERROR VERSION!")
print("✅ AIM PERFECT - No side offset!")
print("✅ STATUS SYNC - Toggle and label synced!")
print("✅ NO FILE ERROR - No writefile/readfile!")
print("✅ KEYBINDS:")
print("   - INSERT: Toggle UI")
print("   - H: Toggle Aimbot")
print("   - DELETE: Destroy Script")
print("═══════════════════════════════════════════════════════")
