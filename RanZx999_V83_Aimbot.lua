--[[
═══════════════════════════════════════════════════════════════
  RanZx999 Hub V8.3 ULTIMATE - PERFECT EDITION
═══════════════════════════════════════════════════════════════

🔥 ULTIMATE FIXES:
✅ Dropdown BENAR-BENAR FIXED - Keliatan semua opsi!
✅ Aim Offset PERFECT - Langsung CENTER kepala
✅ Lock Mode KERAS - Ga lepas-lepas
✅ Wall Check FIXED

Created by RanZx999
GitHub: https://github.com/RanZx999
═══════════════════════════════════════════════════════════════
]]

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Stats = game:GetService("Stats")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = Workspace.CurrentCamera

--// ═══════════════════════════════════════════════════════
--// COLORS
--// ═══════════════════════════════════════════════════════
local Colors = {
    Background = Color3.fromRGB(255, 250, 252),
    Primary = Color3.fromRGB(255, 182, 193),
    Secondary = Color3.fromRGB(255, 218, 224),
    Accent = Color3.fromRGB(255, 105, 180),
    White = Color3.fromRGB(255, 255, 255),
    Text = Color3.fromRGB(80, 60, 70),
    TextLight = Color3.fromRGB(150, 120, 140),
    Border = Color3.fromRGB(255, 220, 230),
    Toggle_On = Color3.fromRGB(255, 182, 193),
    Toggle_Off = Color3.fromRGB(220, 200, 210),
    TeamColor = Color3.fromRGB(0, 255, 0),
    EnemyColor = Color3.fromRGB(255, 0, 0)
}

--// ═══════════════════════════════════════════════════════
--// CONFIG
--// ═══════════════════════════════════════════════════════
local Config = {
    Aimlock = {
        Enabled = false,
        LockMode = true,
        Smooth = 0.15,
        FOV = 200,
        Prediction = 0.125,
        AimPart = "Head",
        WallCheck = true,
        TeamCheck = true,
        AutoAim = true
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
    AutoPrediction = false,
    Walkspeed = {
        Enabled = false,
        Speed = 50
    },
    Noclip = {
        Enabled = false
    },
    OutlineTarget = true
}

--// ═══════════════════════════════════════════════════════
--// STATE
--// ═══════════════════════════════════════════════════════
local CurrentTarget = nil
local CurrentOutline = nil
local Connections = {}
local ESPObjects = {}

--// ═══════════════════════════════════════════════════════
--// UTILITY FUNCTIONS
--// ═══════════════════════════════════════════════════════
local function IsMobile()
    return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

local function isAlive(plr)
    if not plr or not plr.Character then return false end
    local hum = plr.Character:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    local be = plr.Character:FindFirstChild("BodyEffects")
    if be then
        local ko = be:FindFirstChild("K.O")
        local grabbed = be:FindFirstChild("GRABBING_CONSTRAINT")
        if (ko and ko.Value) or (grabbed and grabbed.Value) then
            return false
        end
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

local function GetClosestPlayerToCursor()
    local closestPlayer = nil
    local shortestDistance = Config.Aimlock.FOV
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and isAlive(player) and player.Character then
            if Config.Aimlock.TeamCheck and isTeammate(player) then continue end
            
            local character = player.Character
            local aimPart = character:FindFirstChild(Config.Aimlock.AimPart)
            if not aimPart then
                aimPart = character:FindFirstChild("HumanoidRootPart")
            end
            
            if aimPart then
                local screenPos, onScreen = Camera:WorldToViewportPoint(aimPart.Position)
                if onScreen then
                    if isVisible(aimPart, player) then
                        local mousePos = IsMobile() and Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2) or Vector2.new(Mouse.X, Mouse.Y)
                        local distance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                        if distance < shortestDistance then
                            shortestDistance = distance
                            closestPlayer = player
                        end
                    end
                end
            end
        end
    end
    return closestPlayer
end

local function GetPartToAim(target)
    if not target or not target.Character then return nil end
    local character = target.Character
    local part = character:FindFirstChild(Config.Aimlock.AimPart)
    if not part then
        part = character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
    end
    return part
end

--// ═══════════════════════════════════════════════════════
--// NOTIFICATION
--// ═══════════════════════════════════════════════════════
local function Notify(message, duration)
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "RanZx999 Hub",
        Text = message,
        Duration = duration or 2
    })
end

--// ═══════════════════════════════════════════════════════
--// OUTLINE
--// ═══════════════════════════════════════════════════════
local function CreateOutline(character)
    if CurrentOutline then
        CurrentOutline:Destroy()
        CurrentOutline = nil
    end
    if not Config.OutlineTarget then return end
    local highlight = Instance.new("Highlight")
    highlight.Name = "RanZxOutline"
    highlight.Adornee = character
    highlight.FillColor = Colors.Accent
    highlight.FillTransparency = 0.5
    highlight.OutlineColor = Colors.Primary
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = character
    CurrentOutline = highlight
end

--// ═══════════════════════════════════════════════════════
--// AIMLOCK ENGINE - PERFECT AIM! 🎯
--// ═══════════════════════════════════════════════════════
local AimlockConnection = nil
local function StartAimlock()
    if AimlockConnection then AimlockConnection:Disconnect() end
    
    AimlockConnection = RunService.RenderStepped:Connect(function()
        if not Config.Aimlock.Enabled then return end
        
        -- AUTO AIM
        if Config.Aimlock.AutoAim then
            CurrentTarget = GetClosestPlayerToCursor()
            
            if CurrentTarget and CurrentTarget.Character then
                if not CurrentOutline or CurrentOutline.Adornee ~= CurrentTarget.Character then
                    CreateOutline(CurrentTarget.Character)
                end
            else
                if CurrentOutline then
                    CurrentOutline:Destroy()
                    CurrentOutline = nil
                end
            end
        end
        
        -- AIM
        if not CurrentTarget or not isAlive(CurrentTarget) then return end
        
        local targetPart = GetPartToAim(CurrentTarget)
        if not targetPart then return end
        
        local root = CurrentTarget.Character:FindFirstChild("HumanoidRootPart")
        if not root then return end
        
        if not isVisible(targetPart, CurrentTarget) then return end
        
        -- CALCULATE EXACT CENTER POSITION
        local pred = Config.Aimlock.Prediction
        local velocity = root.AssemblyLinearVelocity or root.Velocity or Vector3.zero
        
        -- AIM KE EXACT CENTER OF PART (bukan CFrame.Position yang kadang offset)
        local partCFrame = targetPart.CFrame
        local centerPos = partCFrame.Position + velocity * pred
        
        -- LOCK MODE vs SMOOTH
        if Config.Aimlock.LockMode then
            -- LOCK KERAS - INSTANT AIM!
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, centerPos)
        else
            -- SMOOTH MODE
            local currentCFrame = Camera.CFrame
            local targetCFrame = CFrame.new(Camera.CFrame.Position, centerPos)
            Camera.CFrame = currentCFrame:Lerp(targetCFrame, Config.Aimlock.Smooth)
        end
    end)
end

--// ═══════════════════════════════════════════════════════
--// ESP SYSTEM
--// ═══════════════════════════════════════════════════════
local function createESP(player)
    if player == LocalPlayer then return end
    
    local objects = {
        Box = Drawing.new("Square"),
        Name = Drawing.new("Text"),
        Distance = Drawing.new("Text"),
        HealthBarBG = Drawing.new("Square"),
        HealthBar = Drawing.new("Square"),
        Tracer = Drawing.new("Line")
    }
    
    objects.Box.Thickness = 2
    objects.Box.Filled = false
    objects.Name.Size = 14
    objects.Name.Center = true
    objects.Name.Outline = true
    objects.Name.OutlineColor = Color3.fromRGB(0, 0, 0)
    objects.Distance.Size = 12
    objects.Distance.Center = true
    objects.Distance.Outline = true
    objects.Distance.OutlineColor = Color3.fromRGB(0, 0, 0)
    objects.HealthBar.Filled = true
    objects.HealthBarBG.Filled = true
    objects.HealthBarBG.Color = Color3.fromRGB(20, 20, 20)
    
    ESPObjects[player] = objects
end

local function removeESP(player)
    if ESPObjects[player] then
        for _, obj in pairs(ESPObjects[player]) do 
            pcall(function() obj:Remove() end)
        end
        ESPObjects[player] = nil
    end
end

local function updateESP()
    if not Config.ESP.Enabled then
        for _, esp in pairs(ESPObjects) do
            for _, obj in pairs(esp) do obj.Visible = false end
        end
        return
    end
    
    for player, esp in pairs(ESPObjects) do
        if not player or not player.Parent then
            removeESP(player)
            continue
        end
        
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
                local color = isTeammate(player) and Colors.TeamColor or Colors.EnemyColor
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
                    local healthPercent = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                    
                    esp.HealthBarBG.Visible = true
                    esp.HealthBarBG.Size = Vector2.new(4, size.Y)
                    esp.HealthBarBG.Position = Vector2.new(screenPos.X - size.X/2 - 6, screenPos.Y - size.Y/2)
                    
                    esp.HealthBar.Visible = true
                    esp.HealthBar.Size = Vector2.new(4, size.Y * healthPercent)
                    esp.HealthBar.Position = Vector2.new(screenPos.X - size.X/2 - 6, screenPos.Y + size.Y/2 - esp.HealthBar.Size.Y)
                    esp.HealthBar.Color = Color3.fromRGB(
                        math.floor(255 * (1 - healthPercent)),
                        math.floor(255 * healthPercent),
                        0
                    )
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

--// ═══════════════════════════════════════════════════════
--// HIGHLIGHT
--// ═══════════════════════════════════════════════════════
local function updateHighlights()
    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        
        local char = player.Character
        if char and Config.Highlight.Enabled then
            if Config.Highlight.TeamCheck and isTeammate(player) then
                if not Config.Highlight.ShowTeam then
                    local hl = char:FindFirstChildOfClass("Highlight")
                    if hl and hl.Name == "RanZxHL" then hl:Destroy() end
                    continue
                end
            end
            
            local hl = char:FindFirstChildOfClass("Highlight")
            if not hl or hl.Name ~= "RanZxHL" then 
                hl = Instance.new("Highlight")
                hl.Name = "RanZxHL"
                hl.Parent = char
            end
            hl.FillColor = isTeammate(player) and Colors.TeamColor or Colors.EnemyColor
            hl.OutlineColor = Color3.new(1, 1, 1)
            hl.FillTransparency = 0.5
            hl.OutlineTransparency = 0
        elseif char then
            local hl = char:FindFirstChildOfClass("Highlight")
            if hl and hl.Name == "RanZxHL" then hl:Destroy() end
        end
    end
end

table.insert(Connections, RunService.RenderStepped:Connect(function()
    updateESP()
    updateHighlights()
end))

--// ═══════════════════════════════════════════════════════
--// AUTO PREDICTION & MISC
--// ═══════════════════════════════════════════════════════
local function getAutoPred()
    local ping = Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
    if ping < 20 then return 0.11
    elseif ping < 30 then return 0.115
    elseif ping < 40 then return 0.12
    elseif ping < 50 then return 0.125
    elseif ping < 60 then return 0.13
    elseif ping < 70 then return 0.135
    elseif ping < 80 then return 0.14
    elseif ping < 90 then return 0.145
    elseif ping < 100 then return 0.15
    else return 0.16 end
end

table.insert(Connections, RunService.Heartbeat:Connect(function()
    if Config.AutoPrediction then
        Config.Aimlock.Prediction = getAutoPred()
    end
    
    local character = LocalPlayer.Character
    if character then
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid and Config.Walkspeed.Enabled then
            humanoid.WalkSpeed = Config.Walkspeed.Speed
        end
    end
end))

table.insert(Connections, RunService.Stepped:Connect(function()
    local character = LocalPlayer.Character
    if character and Config.Noclip.Enabled then
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end))

--// ═══════════════════════════════════════════════════════
--// GUI
--// ═══════════════════════════════════════════════════════
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RanZx999Hub"
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game:GetService("CoreGui")

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 340, 0, 50)
MainFrame.Position = UDim2.new(0.5, -170, 0, 20)
MainFrame.BackgroundColor3 = Colors.Background
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 14)
MainCorner.Parent = MainFrame

local MainBorder = Instance.new("UIStroke")
MainBorder.Color = Colors.Border
MainBorder.Thickness = 2
MainBorder.Transparency = 0.3
MainBorder.Parent = MainFrame

local Topbar = Instance.new("Frame")
Topbar.Size = UDim2.new(1, 0, 0, 50)
Topbar.BackgroundColor3 = Colors.White
Topbar.BorderSizePixel = 0
Topbar.Parent = MainFrame

local TopbarCorner = Instance.new("UICorner")
TopbarCorner.CornerRadius = UDim.new(0, 14)
TopbarCorner.Parent = Topbar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -90, 1, 0)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "🎯 RanZx999 V8.3"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.TextColor3 = Colors.Primary
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Topbar

local ArrowButton = Instance.new("TextButton")
ArrowButton.Size = UDim2.new(0, 40, 0, 40)
ArrowButton.Position = UDim2.new(1, -45, 0.5, -20)
ArrowButton.BackgroundColor3 = Colors.Primary
ArrowButton.BorderSizePixel = 0
ArrowButton.Text = "▼"
ArrowButton.Font = Enum.Font.GothamBold
ArrowButton.TextSize = 18
ArrowButton.TextColor3 = Colors.White
ArrowButton.AutoButtonColor = false
ArrowButton.Parent = Topbar

local ArrowCorner = Instance.new("UICorner")
ArrowCorner.CornerRadius = UDim.new(0, 10)
ArrowCorner.Parent = ArrowButton

local TabContainer = Instance.new("Frame")
TabContainer.Size = UDim2.new(1, 0, 0, 35)
TabContainer.Position = UDim2.new(0, 0, 0, 55)
TabContainer.BackgroundColor3 = Colors.Secondary
TabContainer.BorderSizePixel = 0
TabContainer.Parent = MainFrame

local TabLayout = Instance.new("UIListLayout")
TabLayout.FillDirection = Enum.FillDirection.Horizontal
TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabLayout.Parent = TabContainer

local ContentFrame = Instance.new("ScrollingFrame")
ContentFrame.Size = UDim2.new(1, -10, 0, 350)
ContentFrame.Position = UDim2.new(0, 5, 0, 95)
ContentFrame.BackgroundTransparency = 1
ContentFrame.BorderSizePixel = 0
ContentFrame.ScrollBarThickness = 4
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

--// ═══════════════════════════════════════════════════════
--// UI FUNCTIONS
--// ═══════════════════════════════════════════════════════
local function CreateTab(name)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.33, -2, 1, 0)
    btn.BackgroundColor3 = Colors.White
    btn.BorderSizePixel = 0
    btn.Text = name
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.TextColor3 = Colors.Text
    btn.AutoButtonColor = false
    btn.Parent = TabContainer
    return btn
end

local AimbotTab = CreateTab("Aimbot")
local ESPTab = CreateTab("ESP")
local MiscTab = CreateTab("Misc")

local function SwitchTab(tabName)
    AimbotTab.BackgroundColor3 = tabName == "Aimbot" and Colors.Primary or Colors.White
    ESPTab.BackgroundColor3 = tabName == "ESP" and Colors.Primary or Colors.White
    MiscTab.BackgroundColor3 = tabName == "Misc" and Colors.Primary or Colors.White
    
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
    frame.Size = UDim2.new(1, 0, 0, 30)
    frame.BackgroundColor3 = Colors.White
    frame.BorderSizePixel = 0
    frame.Parent = ContentFrame
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = frame
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -55, 1, 0)
    label.Position = UDim2.new(0, 8, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.TextColor3 = Colors.Text
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 40, 0, 18)
    button.Position = UDim2.new(1, -45, 0.5, -9)
    button.BackgroundColor3 = default and Colors.Toggle_On or Colors.Toggle_Off
    button.BorderSizePixel = 0
    button.Text = ""
    button.AutoButtonColor = false
    button.Parent = frame
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(1, 0)
    buttonCorner.Parent = button
    
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = default and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
    knob.BackgroundColor3 = Colors.White
    knob.BorderSizePixel = 0
    knob.Parent = button
    
    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob
    
    local enabled = default
    button.MouseButton1Click:Connect(function()
        enabled = not enabled
        TweenService:Create(button, TweenInfo.new(0.2), {
            BackgroundColor3 = enabled and Colors.Toggle_On or Colors.Toggle_Off
        }):Play()
        TweenService:Create(knob, TweenInfo.new(0.2), {
            Position = enabled and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
        }):Play()
        if callback then callback(enabled) end
    end)
end

local function CreateSlider(text, min, max, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 40)
    frame.BackgroundColor3 = Colors.White
    frame.BorderSizePixel = 0
    frame.Parent = ContentFrame
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = frame
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.7, 0, 0, 18)
    label.Position = UDim2.new(0, 8, 0, 4)
    label.BackgroundTransparency = 1
    label.Text = text
    label.Font = Enum.Font.Gotham
    label.TextSize = 11
    label.TextColor3 = Colors.Text
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0.3, -8, 0, 18)
    valueLabel.Position = UDim2.new(0.7, 0, 0, 4)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(default)
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextSize = 11
    valueLabel.TextColor3 = Colors.Accent
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = frame
    
    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -16, 0, 3)
    track.Position = UDim2.new(0, 8, 1, -10)
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
    knob.Size = UDim2.new(0, 12, 0, 12)
    knob.Position = UDim2.new((default - min) / (max - min), -6, 0.5, -6)
    knob.BackgroundColor3 = Colors.Accent
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
        value = math.floor(value * 1000 + 0.5) / 1000
        
        valueLabel.Text = tostring(value)
        fill.Size = UDim2.new(percent, 0, 1, 0)
        knob.Position = UDim2.new(percent, -6, 0.5, -6)
        if callback then callback(value) end
    end
    
    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            update(input)
        end
    end)
    
    track.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            update(input)
        end
    end)
end

-- DROPDOWN ULTIMATE FIX! 🔥
local function CreateDropdown(text, options, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 35) -- Lebih tinggi
    frame.BackgroundColor3 = Colors.White
    frame.BorderSizePixel = 0
    frame.Parent = ContentFrame
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = frame
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.35, 0, 1, 0)
    label.Position = UDim2.new(0, 8, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.Font = Enum.Font.Gotham
    label.TextSize = 11
    label.TextColor3 = Colors.Text
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0.65, -12, 0, 26) -- Lebih tinggi
    button.Position = UDim2.new(0.35, 4, 0.5, -13)
    button.BackgroundColor3 = Colors.Secondary
    button.BorderSizePixel = 0
    button.Text = default
    button.Font = Enum.Font.GothamBold
    button.TextSize = 11
    button.TextColor3 = Colors.Text
    button.AutoButtonColor = false
    button.ClipsDescendants = false
    button.Parent = frame
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 5)
    btnCorner.Parent = button
    
    -- CREATE DROPDOWN OUTSIDE OF SCROLLFRAME!
    local dropdownContainer = Instance.new("Frame")
    dropdownContainer.Size = UDim2.new(0, button.AbsoluteSize.X, 0, #options * 28)
    dropdownContainer.Position = UDim2.new(0, button.AbsolutePosition.X - MainFrame.AbsolutePosition.X, 0, button.AbsolutePosition.Y - MainFrame.AbsolutePosition.Y + 30)
    dropdownContainer.BackgroundColor3 = Colors.White
    dropdownContainer.BorderSizePixel = 0
    dropdownContainer.Visible = false
    dropdownContainer.ZIndex = 1000 -- SUPER HIGH!
    dropdownContainer.Parent = MainFrame -- Parent ke MainFrame, bukan ContentFrame!
    
    local dropCorner = Instance.new("UICorner")
    dropCorner.CornerRadius = UDim.new(0, 5)
    dropCorner.Parent = dropdownContainer
    
    local dropStroke = Instance.new("UIStroke")
    dropStroke.Color = Colors.Accent
    dropStroke.Thickness = 2
    dropStroke.Parent = dropdownContainer
    
    local dropLayout = Instance.new("UIListLayout")
    dropLayout.SortOrder = Enum.SortOrder.LayoutOrder
    dropLayout.Parent = dropdownContainer
    
    for i, option in ipairs(options) do
        local optBtn = Instance.new("TextButton")
        optBtn.Size = UDim2.new(1, 0, 0, 28)
        optBtn.BackgroundColor3 = Colors.White
        optBtn.BorderSizePixel = 0
        optBtn.Text = option
        optBtn.Font = Enum.Font.Gotham
        optBtn.TextSize = 11
        optBtn.TextColor3 = Colors.Text
        optBtn.AutoButtonColor = false
        optBtn.ZIndex = 1001
        optBtn.Parent = dropdownContainer
        
        if i < #options then
            local divider = Instance.new("Frame")
            divider.Size = UDim2.new(1, -10, 0, 1)
            divider.Position = UDim2.new(0, 5, 1, -1)
            divider.BackgroundColor3 = Colors.Border
            divider.BorderSizePixel = 0
            divider.ZIndex = 1001
            divider.Parent = optBtn
        end
        
        optBtn.MouseButton1Click:Connect(function()
            button.Text = option
            dropdownContainer.Visible = false
            if callback then callback(option) end
        end)
        
        optBtn.MouseEnter:Connect(function()
            optBtn.BackgroundColor3 = Colors.Primary
        end)
        
        optBtn.MouseLeave:Connect(function()
            optBtn.BackgroundColor3 = Colors.White
        end)
    end
    
    button.MouseButton1Click:Connect(function()
        dropdownContainer.Visible = not dropdownContainer.Visible
        -- Update position setiap kali dibuka
        dropdownContainer.Position = UDim2.new(0, button.AbsolutePosition.X - MainFrame.AbsolutePosition.X, 0, button.AbsolutePosition.Y - MainFrame.AbsolutePosition.Y + 30)
    end)
    
    -- Close dropdown ketika klik di luar
    ScreenGui.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if not dropdownContainer:IsAncestorOf(game:GetService("Players").LocalPlayer:GetMouse().Target) and
               game:GetService("Players").LocalPlayer:GetMouse().Target ~= button then
                dropdownContainer.Visible = false
            end
        end
    end)
end

--// ═══════════════════════════════════════════════════════
--// TAB CONTENTS
--// ═══════════════════════════════════════════════════════
function CreateAimbotTab()
    CreateToggle("🎯 Enable Aimbot", false, function(val)
        Config.Aimlock.Enabled = val
        if val then
            StartAimlock()
            Notify("🎯 Aimbot ON - " .. (Config.Aimlock.LockMode and "LOCK MODE" or "SMOOTH MODE"), 2)
        else
            if AimlockConnection then AimlockConnection:Disconnect() end
            CurrentTarget = nil
            if CurrentOutline then CurrentOutline:Destroy() CurrentOutline = nil end
            Notify("🎯 Aimbot OFF", 2)
        end
    end)
    
    CreateToggle("🔒 LOCK Mode", true, function(val)
        Config.Aimlock.LockMode = val
        Notify(val and "🔒 LOCK MODE!" or "🌊 SMOOTH MODE", 2)
    end)
    
    CreateToggle("🤖 Auto Aim", true, function(val)
        Config.Aimlock.AutoAim = val
    end)
    
    CreateDropdown("Aim Part", {"Head", "UpperTorso", "LowerTorso", "HumanoidRootPart"}, "Head", function(val)
        Config.Aimlock.AimPart = val
        Notify("Aim: " .. val, 1.5)
    end)
    
    CreateSlider("Smoothness", 0.05, 0.5, 0.15, function(val)
        Config.Aimlock.Smooth = val
    end)
    
    CreateSlider("Prediction", 0, 0.3, 0.125, function(val)
        Config.Aimlock.Prediction = val
    end)
    
    CreateSlider("FOV", 50, 400, 200, function(val)
        Config.Aimlock.FOV = val
    end)
    
    CreateToggle("✅ Wall Check", true, function(val)
        Config.Aimlock.WallCheck = val
    end)
    
    CreateToggle("✅ Team Check", true, function(val)
        Config.Aimlock.TeamCheck = val
    end)
    
    CreateToggle("✨ Outline", true, function(val)
        Config.OutlineTarget = val
    end)
    
    CreateToggle("📡 Auto Pred", false, function(val)
        Config.AutoPrediction = val
    end)
end

function CreateESPTab()
    CreateToggle("🔍 Enable ESP", false, function(val)
        Config.ESP.Enabled = val
        if val then
            for _, p in pairs(Players:GetPlayers()) do 
                if p ~= LocalPlayer then createESP(p) end
            end
        end
    end)
    
    CreateToggle("📦 Boxes", true, function(val) Config.ESP.Boxes = val end)
    CreateToggle("👤 Names", true, function(val) Config.ESP.Names = val end)
    CreateToggle("📏 Distance", true, function(val) Config.ESP.Distance = val end)
    CreateToggle("❤️ Health", true, function(val) Config.ESP.Health = val end)
    CreateToggle("📍 Tracers", false, function(val) Config.ESP.Tracers = val end)
    CreateToggle("✅ Team Check", true, function(val) Config.ESP.TeamCheck = val end)
    
    CreateSlider("Max Distance", 500, 5000, 2000, function(val)
        Config.ESP.MaxDistance = val
    end)
    
    CreateToggle("✨ Highlight", false, function(val) Config.Highlight.Enabled = val end)
    CreateToggle("✅ HL Team", true, function(val) Config.Highlight.TeamCheck = val end)
    CreateToggle("👥 Show Team", false, function(val) Config.Highlight.ShowTeam = val end)
end

function CreateMiscTab()
    CreateToggle("⚡ Walkspeed", false, function(val)
        Config.Walkspeed.Enabled = val
    end)
    
    CreateSlider("Speed", 16, 300, 50, function(val)
        Config.Walkspeed.Speed = val
    end)
    
    CreateToggle("👻 Noclip", false, function(val)
        Config.Noclip.Enabled = val
    end)
end

SwitchTab("Aimbot")

--// ═══════════════════════════════════════════════════════
--// KEYBINDS
--// ═══════════════════════════════════════════════════════
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    
    if input.KeyCode == Enum.KeyCode.Insert then
        MainFrame.Visible = not MainFrame.Visible
    end
    
    if input.KeyCode == Enum.KeyCode.Delete then
        for _, conn in pairs(Connections) do conn:Disconnect() end
        for player, _ in pairs(ESPObjects) do removeESP(player) end
        if CurrentOutline then CurrentOutline:Destroy() end
        ScreenGui:Destroy()
        Notify("Destroyed!", 2)
    end
end)

--// ═══════════════════════════════════════════════════════
--// EXPAND/COLLAPSE
--// ═══════════════════════════════════════════════════════
local IsExpanded = false
ArrowButton.MouseButton1Click:Connect(function()
    IsExpanded = not IsExpanded
    TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {
        Size = UDim2.new(0, 340, 0, IsExpanded and 485 or 50)
    }):Play()
    TweenService:Create(ArrowButton, TweenInfo.new(0.2), {
        Rotation = IsExpanded and 180 or 0
    }):Play()
    ArrowButton.Text = IsExpanded and "▲" or "▼"
end)

--// ═══════════════════════════════════════════════════════
--// DRAGGING
--// ═══════════════════════════════════════════════════════
local dragging, dragInput, dragStart, startPos = false

Topbar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

Topbar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input == dragInput then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

--// ═══════════════════════════════════════════════════════
--// EVENTS
--// ═══════════════════════════════════════════════════════
Players.PlayerAdded:Connect(createESP)
Players.PlayerRemoving:Connect(function(player)
    removeESP(player)
    if CurrentTarget == player then CurrentTarget = nil end
end)

for _, p in pairs(Players:GetPlayers()) do 
    if p ~= LocalPlayer then createESP(p) end
end

--// ═══════════════════════════════════════════════════════
--// LOAD
--// ═══════════════════════════════════════════════════════
wait(1)
Notify("🎯 RanZx999 V8.3 ULTIMATE!", 3)
Notify("Perfect Lock & Dropdown! 🔥", 2)

print("═══════════════════════════════════════════════════════")
print("🎯 RanZx999 V8.3 ULTIMATE - PERFECT EDITION")
print("═══════════════════════════════════════════════════════")
print("✅ DROPDOWN FIXED - Keliatan semua!")
print("✅ AIM OFFSET FIXED - Exact center!")
print("✅ LOCK MODE - Keras banget!")
print("═══════════════════════════════════════════════════════")
