--// ================= LOAD OBSIDIAN =================
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()

--// ================= SERVICES =================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

--// ================= AIMBOT STATE =================
getgenv().FroggoAimbot = {
    Enabled = false,
    ShowFOV = false,
    FOVColor = Color3.fromRGB(0, 255, 10),
    HoldToAim = true,
    TargetPart = "Head", -- Head / HumanoidRootPart / Feet
    FOV = 120,          -- optional FOV limit
    Smoothness = 1,    -- 1..5 (minimum 1), higher = slower (mapped internally)
    MaxDistance = 350, -- studs
    LockStickiness = 0.85, -- 0.5..0.95
    UseStickiness = false,
    AimDelay = 0, -- seconds
    UseAimDelay = false,
    WallCheck = false,
    LegitMode = false
}

-- hard vertical cutoff for aimbot (studs allowed below you)
local MAX_VERTICAL_DROP = 2.5

--// ================= ESP STATE =================
getgenv().FroggoESP = {
    Enabled = false,
    Color = Color3.fromRGB(0, 255, 10),
    Skeleton = false,
    SkeletonColor = Color3.fromRGB(255, 255, 255)
}

--// ================= VARIABLES =================
local Boxes = {}
local Skeletons = {}
-- head-circle feature removed
local Connections = {}
local RUNNING = true
local BOX_THICKNESS = 1
local HoldingRMB = false
local LockedAimbot = nil
local LastTargetPos = nil
local LastAimTime = 0

-- SPINBOT VARIABLES
getgenv().Spinbot = getgenv().Spinbot or {
    Enabled = false,
    Speed = 10 -- degrees per frame
}

-- ESP throttle (frames) to reduce per-frame CPU when many players
local ESP_THROTTLE = 2
local espFrameCounter = 0

-- ================= FOV CIRCLE =================
local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = false
FOVCircle.Filled = false
FOVCircle.Thickness = 1
FOVCircle.NumSides = 64
FOVCircle.Color = getgenv().FroggoAimbot.FOVColor

--// ================= WHITELIST =================
local function IsWhitelisted(player)
    if player == LocalPlayer then return true end
    if LocalPlayer.Team and player.Team == LocalPlayer.Team then return true end
    return false
end

--// ================= AIMBOT HELPERS + RENDER =================
local function GetAimPosition(player)
    local char = player.Character
    if not char then return nil end

    local part
    if getgenv().FroggoAimbot.TargetPart == "Head" then
        part = char:FindFirstChild("Head")
    elseif getgenv().FroggoAimbot.TargetPart == "Body" then
        part = char:FindFirstChild("HumanoidRootPart")
    elseif getgenv().FroggoAimbot.TargetPart == "Feet" then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then part = {Position = hrp.Position - Vector3.new(0, hrp.Size.Y/2, 0)} end
    end

    return part and part.Position
end

local function IsVisible(pos, character)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = {LocalPlayer.Character, character}

    local result = workspace:Raycast(
        Camera.CFrame.Position,
        pos - Camera.CFrame.Position,
        params
    )

    return result == nil
end

Connections.Aimbot = RunService.RenderStepped:Connect(function()
    -- FOV CIRCLE UPDATE
    if getgenv().FroggoAimbot.ShowFOV then
        -- keep FOV circle fixed to screen center to avoid jitter
        local fx = Camera.ViewportSize.X / 2
        local fy = Camera.ViewportSize.Y / 2
        FOVCircle.Visible = true
        FOVCircle.Position = Vector2.new(fx, fy)
        FOVCircle.Radius = getgenv().FroggoAimbot.FOV
        FOVCircle.Color = getgenv().FroggoAimbot.FOVColor
    else
        FOVCircle.Visible = false
    end

    -- sample RMB state each frame to avoid missed/late events
    HoldingRMB = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)

    if not getgenv().FroggoAimbot.Enabled then
        LockedAimbot = nil
        LastTargetPos = nil
        return
    end

    -- clear lock if local player died
    local localHum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if localHum and localHum.Health <= 0 then
        LockedAimbot = nil
        LastTargetPos = nil
        return
    end

    local targetPos = nil
    local fovLimit = getgenv().FroggoAimbot.FOV
    local fovLimit2 = fovLimit * fovLimit
    local centerX = Camera.ViewportSize.X * 0.5
    local centerY = Camera.ViewportSize.Y * 0.5

    -- Hold-to-aim locking behavior: if HoldToAim is enabled, only acquire target while holding RMB, and do not switch
    if getgenv().FroggoAimbot.HoldToAim then
        if not HoldingRMB then
            LockedAimbot = nil
            LastTargetPos = nil
            return
        end

        -- validate locked target HARD
        if LockedAimbot then
            local lpChar = LocalPlayer.Character
            local lpHRP = lpChar and lpChar:FindFirstChild("HumanoidRootPart")

            local char = LockedAimbot.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local aimP = char and GetAimPosition(LockedAimbot)

            if not lpHRP or not char or not hum or not aimP then
                LockedAimbot = nil
                LastTargetPos = nil
                return
            end

            -- HARD vertical drop check (respawn / void / fall)
            local yDiff = aimP.Y - lpHRP.Position.Y
            if yDiff < -MAX_VERTICAL_DROP then
                LockedAimbot = nil
                LastTargetPos = nil
                return
            end

            -- screen + FOV validation
            local sp, onScreen = Camera:WorldToViewportPoint(aimP)
            if not onScreen then
                LockedAimbot = nil
                LastTargetPos = nil
                return
            end

            local dx = sp.X - centerX
            local dy = sp.Y - centerY
            local useStick = getgenv().FroggoAimbot.LegitMode or getgenv().FroggoAimbot.UseStickiness
            local stick = useStick and getgenv().FroggoAimbot.LockStickiness or 1
            if (dx*dx + dy*dy) > (fovLimit2 / stick) then
                LockedAimbot = nil
                LastTargetPos = nil
                return
            end

            -- teleport / respawn snap detection
            if LastTargetPos then
                if (aimP - LastTargetPos).Magnitude > 30 then
                    LockedAimbot = nil
                    LastTargetPos = nil
                    return
                end
            end

            LastTargetPos = aimP
            targetPos = aimP
        end

        -- if we don't have a locked player yet, pick the closest-to-center valid player inside FOV
        if not LockedAimbot then
            local closestDist2 = math.huge
            local bestPlayer = nil
            local bestPos = nil
            for _, player in ipairs(Players:GetPlayers()) do
                if IsWhitelisted(player) then continue end
                local aimP = GetAimPosition(player)
                if not aimP then continue end
                -- max distance check
                local lpChar = LocalPlayer.Character
                local lpHRP = lpChar and lpChar:FindFirstChild("HumanoidRootPart")
                if lpHRP and (aimP - lpHRP.Position).Magnitude > getgenv().FroggoAimbot.MaxDistance then
                    continue
                end
                -- wall/visibility check
                if getgenv().FroggoAimbot.WallCheck and not IsVisible(aimP, player.Character) then
                    continue
                end
                -- vertical cutoff
                local lpChar = LocalPlayer.Character
                local lpHRP = lpChar and lpChar:FindFirstChild("HumanoidRootPart")
                if lpHRP and (aimP.Y - lpHRP.Position.Y) < -MAX_VERTICAL_DROP then
                    continue
                end
                local screenPos, onScreen = Camera:WorldToViewportPoint(aimP)
                if not onScreen then continue end
                -- front-only check
                local dir = (aimP - Camera.CFrame.Position)
                if dir.Magnitude == 0 then continue end
                dir = dir.Unit
                if Camera.CFrame.LookVector:Dot(dir) < 0 then
                    if getgenv().FroggoAimbot.Debug then
                        print(player.Name, "front-dot:", Camera.CFrame.LookVector:Dot(dir))
                    end
                    continue
                end
                local dx = screenPos.X - centerX
                local dy = screenPos.Y - centerY
                local dist2 = dx*dx + dy*dy
                if dist2 <= fovLimit2 and dist2 < closestDist2 then
                    closestDist2 = dist2
                    bestPlayer = player
                    bestPos = aimP
                end
            end
            if bestPlayer then
                -- ensure previous lock does not prevent acquiring this fresh target
                LockedAimbot = nil
                local useDelay = getgenv().FroggoAimbot.LegitMode or getgenv().FroggoAimbot.UseAimDelay
                if useDelay then
                    if os.clock() - LastAimTime < getgenv().FroggoAimbot.AimDelay then
                        return
                    end
                    LastAimTime = os.clock()
                end
                LockedAimbot = bestPlayer
                targetPos = bestPos
            end
        end
    else
        -- no hold-to-aim: normal behavior (can switch targets freely)
        local closestDist2 = math.huge
        local bestPlayer = nil
        local bestPos = nil
        for _, player in ipairs(Players:GetPlayers()) do
            if IsWhitelisted(player) then continue end
            local aimPos = GetAimPosition(player)
            if not aimPos then continue end
            -- max distance check
            local lpChar = LocalPlayer.Character
            local lpHRP = lpChar and lpChar:FindFirstChild("HumanoidRootPart")
            if lpHRP and (aimPos - lpHRP.Position).Magnitude > getgenv().FroggoAimbot.MaxDistance then
                continue
            end
            -- wall/visibility check
            if getgenv().FroggoAimbot.WallCheck and not IsVisible(aimPos, player.Character) then
                continue
            end
            -- vertical cutoff
            local lpChar = LocalPlayer.Character
            local lpHRP = lpChar and lpChar:FindFirstChild("HumanoidRootPart")
            if lpHRP and (aimPos.Y - lpHRP.Position.Y) < -MAX_VERTICAL_DROP then
                continue
            end
            local screenPos, onScreen = Camera:WorldToViewportPoint(aimPos)
            if not onScreen then continue end
            -- front-only check
            local dir = (aimPos - Camera.CFrame.Position)
            if dir.Magnitude == 0 then continue end
            dir = dir.Unit
            if Camera.CFrame.LookVector:Dot(dir) < 0 then
                if getgenv().FroggoAimbot.Debug then
                    print(player.Name, "front-dot:", Camera.CFrame.LookVector:Dot(dir))
                end
                continue
            end
            local dx = screenPos.X - centerX
            local dy = screenPos.Y - centerY
            local dist2 = dx*dx + dy*dy
            if dist2 <= fovLimit2 and dist2 < closestDist2 then
                closestDist2 = dist2
                bestPlayer = player
                bestPos = aimPos
            end
        end
        if bestPlayer then
            targetPos = bestPos
        end
    end

    -- when the locked target or chosen target is dead or missing, ensure we clear the lock next frame
    if LockedAimbot then
        local th = LockedAimbot.Character and LockedAimbot.Character:FindFirstChildOfClass("Humanoid")
        if not th or th.Health <= 0 then
            LockedAimbot = nil
            LastTargetPos = nil
            return
        end
    end

    if targetPos then
        local camCFrame = Camera.CFrame
        local newCFrame = CFrame.new(camCFrame.Position, targetPos)
        -- Smooth rotation: Smoothness is 1..5 (min 1). Map to lerp alpha (closer to 0 = slower)
        local s = math.clamp(getgenv().FroggoAimbot.Smoothness or 1, 1, 5)
        local alpha = math.clamp(1 - (s / 5), 0, 1)
        Camera.CFrame = camCFrame:Lerp(newCFrame, alpha)
    end
end)

--// ================= BOX FUNCTIONS =================
local function CreateBox(player)
    if Boxes[player] then return end
    local box = Drawing.new("Square")
    box.Filled = false
    box.Thickness = BOX_THICKNESS
    box.Visible = false
    Boxes[player] = box
end

local function RemoveBox(player)
    local box = Boxes[player]
    if box then
        box:Remove()
        Boxes[player] = nil
    end
end

local function CreateSkeleton(player)
    if Skeletons[player] then return end
    local lines = {}
    -- list of bone segments (pairs). endpoints are names or list of fallback names
    local bones = {
        { {"Head"}, {"UpperTorso", "Torso"} },
        { {"UpperTorso", "Torso"}, {"LowerTorso", "Torso"} },
        { {"UpperTorso", "Torso"}, {"LeftUpperArm" , "Left Arm", "LeftArm"} },
        { {"LeftUpperArm" , "Left Arm", "LeftArm"}, {"LeftLowerArm", "Left Forearm", "LeftForearm"} },
        { {"LeftLowerArm", "Left Forearm", "LeftForearm"}, {"LeftHand", "Left Hand"} },
        { {"UpperTorso", "Torso"}, {"RightUpperArm", "Right Arm", "RightArm"} },
        { {"RightUpperArm", "Right Arm", "RightArm"}, {"RightLowerArm", "Right Forearm", "RightForearm"} },
        { {"RightLowerArm", "Right Forearm", "RightForearm"}, {"RightHand", "Right Hand"} },
        { {"LowerTorso", "Torso"}, {"LeftUpperLeg", "Left Leg", "LeftUpperLeg"} },
        { {"LeftUpperLeg", "Left Leg", "LeftUpperLeg"}, {"LeftLowerLeg", "Left Leg 2", "LeftLowerLeg"} },
        { {"LeftLowerLeg", "Left Leg 2", "LeftLowerLeg"}, {"LeftFoot", "Left Foot"} },
        { {"LowerTorso", "Torso"}, {"RightUpperLeg", "Right Leg", "RightUpperLeg"} },
        { {"RightUpperLeg", "Right Leg", "RightUpperLeg"}, {"RightLowerLeg", "Right Leg 2", "RightLowerLeg"} },
        { {"RightLowerLeg", "Right Leg 2", "RightLowerLeg"}, {"RightFoot", "Right Foot"} }
    }
    for i = 1, #bones do
        local l = Drawing.new("Line")
        l.Visible = false
        l.Thickness = 1
        l.Color = getgenv().FroggoESP.SkeletonColor
        table.insert(lines, l)
    end
    Skeletons[player] = {lines = lines, bones = bones}
end

local function RemoveSkeleton(player)
    local sk = Skeletons[player]
    if sk then
        for _, l in ipairs(sk.lines) do
            pcall(function() l:Remove() end)
        end
        Skeletons[player] = nil
    end
end

-- head-circle feature removed

--// ================= ESP RENDER LOOP =================
Connections.ESP = RunService.RenderStepped:Connect(function()
    if not RUNNING then return end

    espFrameCounter = espFrameCounter + 1
    if (espFrameCounter % ESP_THROTTLE) ~= 0 then return end

    -- cleanup leftover drawings for players who've left
    local _currentPlayers = Players:GetPlayers()
    local _playerSet = {}
    for _, _p in ipairs(_currentPlayers) do _playerSet[_p] = true end
    for p, _ in pairs(Skeletons) do
        if not _playerSet[p] then
            RemoveSkeleton(p)
        end
    end
    for p, _ in pairs(Boxes) do
        if not _playerSet[p] then
            RemoveBox(p)
        end
    end

    for _, player in ipairs(_currentPlayers) do
        if IsWhitelisted(player) then
            RemoveBox(player)
            RemoveSkeleton(player)
            continue
        end

        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")

        -- if HRP isn't on screen, remove visuals and skip this player
        if hrp then
            local hrp2D, hrpOnScreen = Camera:WorldToViewportPoint(hrp.Position)
            if not hrpOnScreen then
                RemoveSkeleton(player)
                RemoveBox(player)
                continue
            end
        end

        if not char or not hrp or not humanoid then
            RemoveBox(player)
            RemoveSkeleton(player)
            continue
        end

        -- Stable top/bottom calculation: prefer using the Head part when present
        local head = char:FindFirstChild("Head")
        local topWorld = head and (head.Position + Vector3.new(0, 0.25, 0)) or (hrp.Position + Vector3.new(0, humanoid.HipHeight + 1.5, 0))
        local bottomWorld = hrp.Position - Vector3.new(0, math.max(0.5, humanoid.HipHeight * 0.9), 0)

        local top2D, topVis = Camera:WorldToViewportPoint(topWorld)
        local bot2D, botVis = Camera:WorldToViewportPoint(bottomWorld)

        if not (topVis and botVis) then
            RemoveBox(player)
            RemoveSkeleton(player)
            continue
        end

        -- BOX drawing (independent toggle)
        if getgenv().FroggoESP.Enabled then
            if not Boxes[player] then CreateBox(player) end
            local box = Boxes[player]
            local height = math.abs(top2D.Y - bot2D.Y)
            local width = height / 2
            local centerX = top2D.X
            local centerY = (top2D.Y + bot2D.Y) / 2
            box.Size = Vector2.new(width, height)
            box.Position = Vector2.new(centerX - width / 2, centerY - height / 2)
            box.Color = getgenv().FroggoESP.Color
            box.Visible = true
        else
            RemoveBox(player)
        end

        -- SKELETON drawing (independent toggle)
        if getgenv().FroggoESP.Skeleton then
            if not Skeletons[player] then CreateSkeleton(player) end
            local sk = Skeletons[player]
            local function getPartPos(names)
                for _, n in ipairs(names) do
                    local p = char:FindFirstChild(n)
                    if p then return p.Position end
                end
                return nil
            end
            for i, pair in ipairs(sk.bones) do
                local aNames = pair[1]
                local bNames = pair[2]
                local aPos = getPartPos(aNames)
                local bPos = getPartPos(bNames)
                local line = sk.lines[i]
                -- reset line every frame to avoid Drawing API sticking
                pcall(function()
                    line.From = Vector2.new(0, 0)
                    line.To = Vector2.new(0, 0)
                    line.Visible = false
                end)

                if not (aPos and bPos) then
                    continue
                end

                local a2, aVis = Camera:WorldToViewportPoint(aPos)
                local b2, bVis = Camera:WorldToViewportPoint(bPos)

                -- strict: if either endpoint is offscreen, skip drawing
                if not (aVis and bVis) then
                    continue
                end

                line.From = Vector2.new(a2.X, a2.Y)
                line.To = Vector2.new(b2.X, b2.Y)
                line.Color = getgenv().FroggoESP.SkeletonColor
                line.Visible = true
            end
        else
            RemoveSkeleton(player)
        end

        -- head-circle feature removed
    end
end)

--// ================= PLAYER JOIN / LEAVE =================
Connections.Join = Players.PlayerAdded:Connect(function(player)
    if not IsWhitelisted(player) then
        CreateBox(player)
    end
end)

Connections.Leave = Players.PlayerRemoving:Connect(function(player)
    RemoveBox(player)
    RemoveSkeleton(player)
end)

--// ================= UI & TABS =================
local Window = Library:CreateWindow({
    Title = "🐸 Froggo ESP",
    Center = true,
    AutoShow = true
})

-- AIMBOT TAB FIRST
local AimTab = Window:AddTab("Aimbot", "target")
local AimGroup = AimTab:AddLeftGroupbox("Settings")

-- Toggle
AimGroup:AddToggle("AimBotToggle", {
    Text = "Enable Aimbot",
    Default = false,
    Callback = function(state)
        getgenv().FroggoAimbot.Enabled = state
    end
})

-- Target part dropdown
AimGroup:AddDropdown("AimTargetPart", {
    Values = {"Head", "Body", "Feet"},
    Default = 1,
    Multi = false,
    Text = "Aim Part",
    Callback = function(selected)
        getgenv().FroggoAimbot.TargetPart = selected
    end
})

-- Smoothness slider
AimGroup:AddSlider("AimSmooth", {
    Text = "Smoothness",
    Min = 1,
    Max = 5,
    Default = getgenv().FroggoAimbot.Smoothness,
    Increment = 1,
    Callback = function(value)
        getgenv().FroggoAimbot.Smoothness = math.max(1, math.floor(value))
    end
})

-- FOV slider (optional visual only)
AimGroup:AddSlider("AimFOV", {
    Text = "Max FOV (screen distance)",
    Min = 10,
    Max = 300,
    Default = getgenv().FroggoAimbot.FOV,
    Increment = 1,
    Callback = function(value)
        getgenv().FroggoAimbot.FOV = value
    end
})

local FOVToggle = AimGroup:AddToggle("ShowFOVCircle", {
    Text = "Show FOV Circle",
    Default = false,
    Callback = function(state)
        getgenv().FroggoAimbot.ShowFOV = state
    end
})

FOVToggle:AddColorPicker("FOVCircleColor", {
    Title = "FOV Circle Color",
    Default = getgenv().FroggoAimbot.FOVColor,
    Transparency = 0,
    Callback = function(color)
        getgenv().FroggoAimbot.FOVColor = color
    end
})

-- Hold-to-aim toggle (keeps behavior on by default)
AimGroup:AddToggle("HoldToAim", {
    Text = "Hold RMB to Aim",
    Default = getgenv().FroggoAimbot.HoldToAim,
    Callback = function(state)
        getgenv().FroggoAimbot.HoldToAim = state
    end
})

-- Max aim distance
AimGroup:AddSlider("AimDistance", {
    Text = "Max Aim Distance",
    Min = 50,
    Max = 1000,
    Default = getgenv().FroggoAimbot.MaxDistance,
    Increment = 10,
    Callback = function(v)
        getgenv().FroggoAimbot.MaxDistance = v
    end
})

-- Lock stickiness
AimGroup:AddSlider("AimStick", {
    Text = "Lock Stickiness",
    -- use integer percentage (50..95) to avoid decimal slider bugs
    Min = 50,
    Max = 95,
    Default = math.floor((getgenv().FroggoAimbot.LockStickiness or 0.85) * 100),
    Increment = 1,
    Callback = function(v)
        getgenv().FroggoAimbot.LockStickiness = (v or 50) / 100
    end
})

-- Aim delay
AimGroup:AddSlider("AimDelay", {
    -- use milliseconds (0..500) as integer to avoid decimal slider issues
    Text = "Aim Delay (ms)",
    Min = 0,
    Max = 500,
    Default = math.floor((getgenv().FroggoAimbot.AimDelay or 0) * 1000),
    Increment = 1,
    Callback = function(v)
        getgenv().FroggoAimbot.AimDelay = (v or 0) / 1000
    end
})

-- Wall check toggle
AimGroup:AddToggle("WallCheck", {
    Text = "Visibility Check",
    Default = getgenv().FroggoAimbot.WallCheck,
    Callback = function(v)
        getgenv().FroggoAimbot.WallCheck = v
    end
})

-- Use stickiness toggle
AimGroup:AddToggle("UseStickiness", {
    Text = "Sticky Lock",
    Default = getgenv().FroggoAimbot.UseStickiness,
    Callback = function(v)
        getgenv().FroggoAimbot.UseStickiness = v
    end
})

-- Use aim delay toggle
AimGroup:AddToggle("UseAimDelay", {
    Text = "Aim Delay",
    Default = getgenv().FroggoAimbot.UseAimDelay,
    Callback = function(v)
        getgenv().FroggoAimbot.UseAimDelay = v
    end
})

-- Legit/master mode toggle
AimGroup:AddToggle("LegitMode", {
    Text = "Legit Mode (master)",
    Default = getgenv().FroggoAimbot.LegitMode,
    Callback = function(v)
        getgenv().FroggoAimbot.LegitMode = v
    end
})

-- ESP TAB AFTER
local Tab = Window:AddTab("ESP", "eye")
local Visuals = Tab:AddLeftGroupbox("Visuals")

-- MISC TAB
local MiscTab = Window:AddTab("Misc", "gear")
local MiscGroup = MiscTab:AddLeftGroupbox("Misc")

-- Teleport chase state
local TeleportChaseEnabled = false
local ChaseTarget = nil
local TELEPORT_INTERVAL = 0.5

local function findNextEnemy(afterPlayer)
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        if not p.Character then continue end
        local hrp = p.Character:FindFirstChild("HumanoidRootPart")
        local hum = p.Character:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum or hum.Health <= 0 then continue end
        if LocalPlayer.Team and p.Team == LocalPlayer.Team then continue end
        table.insert(list, p)
    end
    if #list == 0 then return nil end
    if not afterPlayer then return list[1] end
    for i, p in ipairs(list) do
        if p == afterPlayer then
            return list[(i % #list) + 1]
        end
    end
    return list[1]
end

local function startChase()
    if Connections.Chase then return end
    TeleportChaseEnabled = true
    ChaseTarget = findNextEnemy(nil)
    Connections.Chase = RunService.RenderStepped:Connect(function()
        if not TeleportChaseEnabled then return end
        if not LocalPlayer.Character then return end
        local lpHRP = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not lpHRP then return end

        if not ChaseTarget or not ChaseTarget.Character then
            ChaseTarget = findNextEnemy(ChaseTarget)
            return
        end

        local targetHum = ChaseTarget.Character:FindFirstChildOfClass("Humanoid")
        local targetHRP = ChaseTarget.Character:FindFirstChild("HumanoidRootPart")
        if not targetHum or not targetHRP or targetHum.Health <= 0 then
            ChaseTarget = findNextEnemy(ChaseTarget)
            return
        end

        pcall(function()
            -- stick INSIDE enemy
            lpHRP.CFrame = targetHRP.CFrame
            lpHRP.Velocity = Vector3.zero
            lpHRP.AssemblyLinearVelocity = Vector3.zero
        end)

        -- auto-switch aggressively if target died
        if targetHum and targetHum.Health <= 0 then
            ChaseTarget = findNextEnemy(ChaseTarget)
        end
    end)
end

local function stopChase()
    TeleportChaseEnabled = false
    ChaseTarget = nil
    if Connections.Chase then
        Connections.Chase:Disconnect()
        Connections.Chase = nil
    end
    Connections._teleTimer = nil
end

MiscGroup:AddToggle("TeleportChase", {
    Text = "Teleport Chase Enemies",
    Default = false,
    Callback = function(state)
        if state then startChase() else stopChase() end
    end
})

-- SPINBOT UI
local SpinbotToggle = MiscGroup:AddToggle("Spinbot", {
    Text = "Enable Spinbot",
    Default = getgenv().Spinbot.Enabled,
    Callback = function(state)
        getgenv().Spinbot.Enabled = state
    end
})

local SpinbotSpeed = MiscGroup:AddSlider("SpinbotSpeed", {
    Text = "Spin Speed",
    Min = 1,
    Max = 50,
    Default = getgenv().Spinbot.Speed,
    Increment = 1,
    Callback = function(value)
        getgenv().Spinbot.Speed = value
    end
})

-- Spinbot RenderStepped: rotate local player's HumanoidRootPart
Connections.Spinbot = RunService.RenderStepped:Connect(function()
    if not getgenv().Spinbot.Enabled then return end
    if not LocalPlayer.Character then return end
    local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    pcall(function()
        local cf = hrp.CFrame
        hrp.CFrame = cf * CFrame.Angles(0, math.rad(getgenv().Spinbot.Speed), 0)
    end)
end)

MiscGroup:AddButton({
    Text = "Close Menu",
    Func = function()
        RUNNING = false

        for _, box in pairs(Boxes) do
            box:Remove()
        end
        if FOVCircle then FOVCircle:Remove() end
        for _, sk in pairs(Skeletons) do
            for _, l in ipairs(sk.lines) do
                pcall(function() l:Remove() end)
            end
        end

        Boxes = {}

        -- stop teleport chase if active
        if Connections.Chase then
            stopChase()
        end

        for k, c in pairs(Connections) do
            if typeof(c) == "RBXScriptConnection" then
                pcall(function() c:Disconnect() end)
            end
            Connections[k] = nil
        end

        Library:Unload()
    end
})

-- TOGGLE (REQUIRED FOR COLOR PICKER)
local ESPToggle = Visuals:AddToggle("BoxESP", {
    Text = "Box ESP",
    Default = false,
    Callback = function(state)
        getgenv().FroggoESP.Enabled = state
    end
})

-- COLOR PICKER (CORRECT USAGE)
ESPToggle:AddColorPicker("ESPColor", {
    Title = "ESP Color",
    Default = getgenv().FroggoESP.Color,
    Transparency = 0,
    Callback = function(color)
        getgenv().FroggoESP.Color = color
    end
})

-- SKELETON ESP TOGGLE + COLOR
local SkeletonToggle = Visuals:AddToggle("SkeletonESP", {
    Text = "Skeleton ESP",
    Default = false,
    Callback = function(state)
        getgenv().FroggoESP.Skeleton = state
    end
})

SkeletonToggle:AddColorPicker("SkeletonColor", {
    Title = "Skeleton Color",
    Default = getgenv().FroggoESP.SkeletonColor,
    Transparency = 0,
    Callback = function(color)
        getgenv().FroggoESP.SkeletonColor = color
    end
})

-- HEAD CIRCLE TOGGLE + COLOR
-- head-circle UI removed

-- Max distance slider
-- (Max distance slider removed)

-- MENU CONTROLS (stay with ESP tab)
-- menu moved to Misc tab (clean placement)

--// ================= MENU TOGGLE KEY =================
local MenuVisible = true

Connections.MenuToggle = UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.RightControl then
        MenuVisible = not MenuVisible
        if MenuVisible then
            Window:Show()
        else
            Window:Hide()
        end
    end
end)

-- RMB hold detection for HoldToAim
Connections.InputBegan = UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        HoldingRMB = true
    end
end)

Connections.InputEnded = UserInputService.InputEnded:Connect(function(input, gp)
    if gp then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        HoldingRMB = false
    end
end)

-- ensure chase stops on unload
local oldDelete = nil

--// ================= HARD STOP KEY =================
Connections.Stop = UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.K then
        RUNNING = false
        for _, box in pairs(Boxes) do box:Remove() end
        if FOVCircle then FOVCircle:Remove() end
        for _, sk in pairs(Skeletons) do
            for _, l in ipairs(sk.lines) do pcall(function() l:Remove() end) end
        end
        -- head-circle visuals removed
        Boxes = {}
    end
end)
