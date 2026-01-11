--// ================= LOAD OBSIDIAN =================
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()

--// ================= SERVICES =================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- new Box ESP (replaces old Boxes implementation)
-- settings
local settings = {
   defaultcolor = Color3.fromRGB(255,0,0),
   teamcheck = false,
   teamcolor = true
};

-- services
local runService = game:GetService("RunService");
local players = game:GetService("Players");

-- variables
local localPlayer = players.LocalPlayer;
local camera = workspace.CurrentCamera;

-- functions
local newVector2, newColor3, newDrawing = Vector2.new, Color3.new, Drawing.new;
local tan, rad = math.tan, math.rad;
local round = function(...) local a = {}; for i,v in next, table.pack(...) do a[i] = math.round(v); end return unpack(a); end;
local wtvp = function(...) local a, b = camera.WorldToViewportPoint(camera, ...) return newVector2(a.X, a.Y), b, a.Z end;

local espCache = {};
local textESP = {} -- cache per player for text drawings

local function createTextESP(player)
    local texts = {}
    local abyss = getgenv().Abyss or {}
    local font = (typeof(abyss.Font) == "EnumItem" and abyss.Font) or Enum.Font.Code

    -- Use Abyss theme colors (do not override with team colors)
    local nameColor = abyss.NameColor or settings.defaultcolor
    local healthColor = abyss.HealthColor or Color3.fromRGB(255, 255, 255)
    local distanceColor = abyss.DistanceColor or settings.defaultcolor

    texts.Name = Drawing.new("Text")
    texts.Name.Text = player.Name
    texts.Name.Size = 16
    texts.Name.Color = nameColor
    pcall(function() texts.Name.Font = font end)
    texts.Name.Center = true
    texts.Name.Outline = true
    texts.Name.Visible = false

    texts.Health = Drawing.new("Text")
    texts.Health.Text = ""
    texts.Health.Size = 16
    texts.Health.Color = healthColor
    pcall(function() texts.Health.Font = font end)
    texts.Health.Center = true
    texts.Health.Outline = true
    texts.Health.Visible = false

    texts.Distance = Drawing.new("Text")
    texts.Distance.Text = ""
    texts.Distance.Size = 16
    texts.Distance.Color = distanceColor
    pcall(function() texts.Distance.Font = font end)
    texts.Distance.Center = true
    texts.Distance.Outline = true
    texts.Distance.Visible = false

    textESP[player] = texts
end

local function removeTextESP(player)
    if textESP[player] then
        for _, t in pairs(textESP[player]) do
            pcall(function() t:Remove() end)
        end
        textESP[player] = nil
    end
end
local function createEsp(player)
   local drawings = {};
   
   drawings.box = newDrawing("Square");
   drawings.box.Thickness = 1;
   drawings.box.Filled = false;
   drawings.box.Color = settings.defaultcolor;
   drawings.box.Visible = false;
   drawings.box.ZIndex = 2;

   drawings.boxoutline = newDrawing("Square");
   drawings.boxoutline.Thickness = 3;
   drawings.boxoutline.Filled = false;
   drawings.boxoutline.Color = newColor3();
   drawings.boxoutline.Visible = false;
   drawings.boxoutline.ZIndex = 1;

    -- left-side health bar (outline + fill)
    drawings.healthBarOutline = newDrawing("Square")
    drawings.healthBarOutline.Filled = false
    drawings.healthBarOutline.Thickness = 1
    drawings.healthBarOutline.Color = newColor3()
    drawings.healthBarOutline.Visible = false
    drawings.healthBarOutline.ZIndex = 0

    drawings.healthBar = newDrawing("Square")
    drawings.healthBar.Filled = true
    drawings.healthBar.Thickness = 0
    drawings.healthBar.Color = newColor3()
    drawings.healthBar.Visible = false
    drawings.healthBar.ZIndex = 3

   espCache[player] = drawings;
end

local function removeEsp(player)
   if rawget(espCache, player) then
       for _, drawing in next, espCache[player] do
           drawing:Remove();
       end
       espCache[player] = nil;
   end
end

local function updateEsp(player, esp)
   local character = player and player.Character
   if character then
       local cframe = character:GetModelCFrame()
       local position, visible, depth = wtvp(cframe.Position)

       -- prefer to only show ESP when both top and bottom of the character are on-screen
       local head = character:FindFirstChild("Head")
       local hrp = character:FindFirstChild("HumanoidRootPart")
       local humanoid = character:FindFirstChildOfClass("Humanoid")
       local topWorld = head and (head.Position + Vector3.new(0, 0.25, 0)) or (hrp and (hrp.Position + Vector3.new(0, (humanoid and humanoid.HipHeight or 2) + 1.5, 0)))
       local bottomWorld = hrp and (hrp.Position - Vector3.new(0, math.max(0.5, (humanoid and humanoid.HipHeight or 1) * 0.9), 0)) or nil
       local topVis, botVis = false, false
       if topWorld then
           local _p, _on = camera:WorldToViewportPoint(topWorld)
           topVis = _on
       end
       if bottomWorld then
           local _p2, _on2 = camera:WorldToViewportPoint(bottomWorld)
           botVis = _on2
       end

       visible = visible and topVis and botVis
       esp.box.Visible = visible
       esp.boxoutline.Visible = visible

       -- HARD hide health bar when target is not visible
       if not visible then
           -- fully remove health bar drawings to avoid stuck visuals; they will be recreated when visible again
           if esp.healthBar then pcall(function() esp.healthBar.Visible = false esp.healthBar:Remove() end) end
           if esp.healthBarOutline then pcall(function() esp.healthBarOutline.Visible = false esp.healthBarOutline:Remove() end) end
           esp.healthBar = nil
           esp.healthBarOutline = nil
           return
       end

       if cframe and visible then
           local scaleFactor = 1 / (depth * tan(rad(camera.FieldOfView / 2)) * 2) * 1000;
           local width, height = round(4 * scaleFactor, 5 * scaleFactor);
           local x, y = round(position.X, position.Y);

           esp.box.Size = newVector2(width, height);
           esp.box.Position = newVector2(round(x - width / 2, y - height / 2));
            -- color applied from global picker elsewhere; don't override here

           esp.boxoutline.Size = esp.box.Size;
           esp.boxoutline.Position = esp.box.Position;
           
                   -- Health bar (left side)
                   local humanoid = character:FindFirstChildOfClass("Humanoid")
                   local hpRatio = 0
                   if humanoid and humanoid.MaxHealth and humanoid.MaxHealth > 0 then
                       hpRatio = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
                   end

                   -- ensure health bar drawings exist (they may have been removed when off-screen)
                   if not esp.healthBarOutline then
                       pcall(function()
                           esp.healthBarOutline = newDrawing("Square")
                           esp.healthBarOutline.Filled = false
                           esp.healthBarOutline.Thickness = 1
                           esp.healthBarOutline.Color = newColor3()
                           esp.healthBarOutline.Visible = false
                           esp.healthBarOutline.ZIndex = 0
                       end)
                   end
                   if not esp.healthBar then
                       pcall(function()
                           esp.healthBar = newDrawing("Square")
                           esp.healthBar.Filled = true
                           esp.healthBar.Thickness = 0
                           esp.healthBar.Color = newColor3()
                           esp.healthBar.Visible = false
                           esp.healthBar.ZIndex = 3
                       end)
                   end

                   if esp.healthBarOutline and esp.healthBar then
                       local barWidth = math.max(3, math.floor(width * 0.12))
                       local barX = esp.box.Position.X - barWidth - 4
                       local barY = esp.box.Position.Y
                       esp.healthBarOutline.Size = newVector2(barWidth, esp.box.Size.Y)
                       esp.healthBarOutline.Position = newVector2(barX, barY)
                       esp.healthBarOutline.Visible = visible and getgenv().Abyss.HealthESP and getgenv().Abyss.Enabled

                       local fillHeight = math.max(1, math.floor(esp.box.Size.Y * hpRatio))
                       esp.healthBar.Size = newVector2(math.max(1, barWidth - 2), fillHeight)
                       esp.healthBar.Position = newVector2(barX + 1, barY + (esp.box.Size.Y - fillHeight))
                       esp.healthBar.Color = getgenv().Abyss.HealthColor or Color3.fromRGB(255, 255, 255)
                       esp.healthBar.Visible = visible and getgenv().Abyss.HealthESP and getgenv().Abyss.Enabled
                   end
       end
   else
       esp.box.Visible = false;
       esp.boxoutline.Visible = false;
       if esp.healthBar then pcall(function() esp.healthBar.Visible = false end) end
       if esp.healthBarOutline then pcall(function() esp.healthBarOutline.Visible = false end) end
   end
end

-- main
-- Ensure ESP defaults are defined BEFORE creating drawings
getgenv().Abyss = {
    Enabled = false,        -- Box ESP OFF by default
    NameESP = false,        -- Name ESP OFF
    HealthESP = false,      -- Health ESP OFF (renders as side bar when enabled)
    DistanceESP = false,    -- Distance ESP OFF
    TeamCheck = false,      -- Do not hide teammates by default
    FOVLock = false,        -- Do not force camera FOV by default

    NameColor = Color3.fromRGB(55, 105, 255),
    HealthColor = Color3.fromRGB(255, 255, 255),
    DistanceColor = Color3.fromRGB(30, 60, 200),
    Font = Enum.Font.Code,

    Color = Color3.fromRGB(55, 105, 255)
}

for _, player in next, players:GetPlayers() do
    if player ~= localPlayer then
         createEsp(player);
         pcall(function() createTextESP(player) end)
    end
end

players.PlayerAdded:Connect(function(player)
    createEsp(player);
    pcall(function() createTextESP(player) end)
end);

players.PlayerRemoving:Connect(function(player)
    removeEsp(player);
    removeTextESP(player);
end)

runService:BindToRenderStep("esp", Enum.RenderPriority.Camera.Value, function()
   for player, drawings in next, espCache do
        -- skip local player
        if player == LocalPlayer then continue end
        -- optional team check (hide teammates when enabled)
        if getgenv().Abyss.TeamCheck and LocalPlayer.Team and player.Team == LocalPlayer.Team then
            if drawings then
                pcall(function()
                    drawings.box.Visible = false
                    drawings.boxoutline.Visible = false
                    if drawings.healthBar then drawings.healthBar.Visible = false end
                    if drawings.healthBarOutline then drawings.healthBarOutline.Visible = false end
                end)
            end
            if textESP[player] then
                pcall(function() for _, t in pairs(textESP[player]) do t.Visible = false end end)
            end
            continue
        end

       if drawings and player ~= localPlayer then
           if getgenv().Abyss.Enabled then
               updateEsp(player, drawings)
               -- always apply color picker value regardless of teamcolor
               drawings.box.Color = getgenv().Abyss.Color
           else
               pcall(function()
                   drawings.box.Visible = false
                   drawings.boxoutline.Visible = false
                   if drawings.healthBar then drawings.healthBar.Visible = false end
                   if drawings.healthBarOutline then drawings.healthBarOutline.Visible = false end
               end)
           end
           -- update text ESP (name/health/distance)
           pcall(function()
               if player ~= LocalPlayer then
                   if textESP[player] == nil then pcall(function() createTextESP(player) end) end
                   if textESP[player] then
                       local function updateTextESP()
                           local char = player.Character
                           if not char then return end
                           local hrp = char:FindFirstChild("HumanoidRootPart")
                           local humanoid = char:FindFirstChildOfClass("Humanoid")
                           if not hrp or not humanoid then
                               for _, t in pairs(textESP[player]) do t.Visible = false end
                               return
                           end

                           local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position + Vector3.new(0, 3, 0))
                           if not onScreen then
                               for _, t in pairs(textESP[player]) do t.Visible = false end
                               return
                           end

                           local x, y = screenPos.X, screenPos.Y

                           -- Name ESP
                           if getgenv().Abyss.NameESP then
                               textESP[player].Name.Text = player.Name
                               textESP[player].Name.Position = Vector2.new(x, y - 20)
                               textESP[player].Name.Color = getgenv().Abyss.NameColor or settings.defaultcolor
                               textESP[player].Name.Visible = true
                           else
                               textESP[player].Name.Visible = false
                           end

                           -- Health ESP (rendered as side bar; do not show health text)
                           textESP[player].Health.Visible = false

                           -- Distance ESP
                           if getgenv().Abyss.DistanceESP then
                               local dist = 0
                               if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                                   dist = math.floor((hrp.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude)
                               end
                               textESP[player].Distance.Text = dist .. " studs"
                               textESP[player].Distance.Position = Vector2.new(x, y + 20)
                               textESP[player].Distance.Color = getgenv().Abyss.DistanceColor or settings.defaultcolor
                               textESP[player].Distance.Visible = true
                           else
                               textESP[player].Distance.Visible = false
                           end
                       end
                       updateTextESP()
                   end
               end
           end)
       end
   end
end)

--// ================= AIMBOT STATE =================
getgenv().AbyssAimbot = {
    Enabled = false,
    ShowFOV = false,
    FOVColor = Color3.fromRGB(55, 105, 255),
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
    TeamCheck = true, -- exclude teammates by default
    LegitMode = false
}

-- hard vertical cutoff for aimbot (studs allowed below you)
local MAX_VERTICAL_DROP = 2.5
local DEFAULT_FOV = 70 -- typical Roblox default FOV used for scaling FOV circle

-- ESP state is defined earlier above player creation; avoid reassigning here.

--// ================= VARIABLES =================
-- head-circle feature removed
local Connections = {}
local RUNNING = true
-- BOX_THICKNESS removed (new ESP uses its own thickness)
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

-- Full Bright Variables
local FullBrightEnabled = false
local OriginalLighting = {}


-- ================= FOV CIRCLE =================
local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = false
FOVCircle.Filled = false
FOVCircle.Thickness = 1
FOVCircle.NumSides = 64
FOVCircle.Color = getgenv().AbyssAimbot.FOVColor

--// ================= WHITELIST =================
local function IsWhitelisted(player)
    if player == LocalPlayer then return true end
    -- respect aimbot team check setting: when enabled, treat teammates as whitelisted
    local aimbot = getgenv().AbyssAimbot or {}
    if aimbot.TeamCheck then
        if LocalPlayer.Team and player.Team == LocalPlayer.Team then return true end
    end
    return false
end

--// ================= AIMBOT HELPERS + RENDER =================
local function GetAimPosition(player)
    local char = player.Character
    if not char then return nil end

    local part
    if getgenv().AbyssAimbot.TargetPart == "Head" then
        part = char:FindFirstChild("Head")
    elseif getgenv().AbyssAimbot.TargetPart == "Body" then
        part = char:FindFirstChild("HumanoidRootPart")
    elseif getgenv().AbyssAimbot.TargetPart == "Feet" then
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
    if getgenv().AbyssAimbot.ShowFOV then
        local viewport = Camera.ViewportSize
        local fx, fy = viewport.X / 2, viewport.Y / 2
        FOVCircle.Visible = true
        FOVCircle.Position = Vector2.new(fx, fy)

        -- Dynamically scale FOV circle based on current camera FOV
        local camFOV = Camera.FieldOfView
        local fovScale = camFOV / DEFAULT_FOV
        FOVCircle.Radius = getgenv().AbyssAimbot.FOV * fovScale
        FOVCircle.Color = getgenv().AbyssAimbot.FOVColor
    else
        FOVCircle.Visible = false
    end

    -- sample RMB state each frame to avoid missed/late events
    HoldingRMB = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)

    if not getgenv().AbyssAimbot.Enabled then
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
    local fovLimit = getgenv().AbyssAimbot.FOV
    local fovLimit2 = fovLimit * fovLimit
    local centerX = Camera.ViewportSize.X * 0.5
    local centerY = Camera.ViewportSize.Y * 0.5

    -- Hold-to-aim locking behavior: if HoldToAim is enabled, only acquire target while holding RMB, and do not switch
    if getgenv().AbyssAimbot.HoldToAim then
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

            -- HARD wall check while locked
            if getgenv().AbyssAimbot.WallCheck then
                if not IsVisible(aimP, LockedAimbot.Character) then
                    LockedAimbot = nil
                    LastTargetPos = nil
                    return
                end
            end

            -- HARD vertical drop check (respawn / void / fall) -- DISABLED
            -- local yDiff = aimP.Y - lpHRP.Position.Y
            -- if yDiff < -MAX_VERTICAL_DROP then
            --     LockedAimbot = nil
            --     LastTargetPos = nil
            --     return
            -- end

            -- screen + FOV validation
            local sp, onScreen = Camera:WorldToViewportPoint(aimP)
            if not onScreen then
                LockedAimbot = nil
                LastTargetPos = nil
                return
            end

            local dx = sp.X - centerX
            local dy = sp.Y - centerY
            local useStick = getgenv().AbyssAimbot.LegitMode or getgenv().AbyssAimbot.UseStickiness
            local stick = useStick and getgenv().AbyssAimbot.LockStickiness or 1
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
                if lpHRP and (aimP - lpHRP.Position).Magnitude > getgenv().AbyssAimbot.MaxDistance then
                    continue
                end
                -- wall/visibility check
                if getgenv().AbyssAimbot.WallCheck and not IsVisible(aimP, player.Character) then
                    continue
                end
                -- vertical cutoff -- DISABLED
                -- local lpChar = LocalPlayer.Character
                -- local lpHRP = lpChar and lpChar:FindFirstChild("HumanoidRootPart")
                -- if lpHRP and (aimP.Y - lpHRP.Position.Y) < -MAX_VERTICAL_DROP then
                --     continue
                -- end
                local screenPos, onScreen = Camera:WorldToViewportPoint(aimP)
                if not onScreen then continue end
                -- front-only check
                local dir = (aimP - Camera.CFrame.Position)
                if dir.Magnitude == 0 then continue end
                dir = dir.Unit
                if Camera.CFrame.LookVector:Dot(dir) < 0 then
                    if getgenv().AbyssAimbot.Debug then
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
                local useDelay = getgenv().AbyssAimbot.LegitMode or getgenv().AbyssAimbot.UseAimDelay
                if useDelay then
                    if os.clock() - LastAimTime < getgenv().AbyssAimbot.AimDelay then
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
            if lpHRP and (aimPos - lpHRP.Position).Magnitude > getgenv().AbyssAimbot.MaxDistance then
                continue
            end
            -- wall/visibility check
            if getgenv().AbyssAimbot.WallCheck and not IsVisible(aimPos, player.Character) then
                continue
            end
                -- vertical cutoff -- DISABLED
                -- local lpChar = LocalPlayer.Character
                -- local lpHRP = lpChar and lpChar:FindFirstChild("HumanoidRootPart")
                -- if lpHRP and (aimPos.Y - lpHRP.Position.Y) < -MAX_VERTICAL_DROP then
                --     continue
                -- end
            local screenPos, onScreen = Camera:WorldToViewportPoint(aimPos)
            if not onScreen then continue end
            -- front-only check
            local dir = (aimPos - Camera.CFrame.Position)
            if dir.Magnitude == 0 then continue end
            dir = dir.Unit
            if Camera.CFrame.LookVector:Dot(dir) < 0 then
                if getgenv().AbyssAimbot.Debug then
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
        local s = math.clamp(getgenv().AbyssAimbot.Smoothness or 1, 1, 5)

        -- Smoothness behavior:
        -- 1 = instant
        -- 5 = very smooth
        local alpha
        if s == 1 then
            alpha = 1
        else
            alpha = 1 / (s * 6) -- legit smooth curve
        end

        Camera.CFrame = camCFrame:Lerp(newCFrame, alpha)
    end
end)

--// ================= BOX FUNCTIONS =================


-- head-circle feature removed

-- Legacy per-frame ESP cleanup loop removed; `runService:BindToRenderStep("esp", ...)` controls ESP visibility now.

--// ================= PLAYER JOIN / LEAVE =================
-- PlayerAdded handling for boxes removed (new ESP creates cache on PlayerAdded)

-- PlayerRemoving handler: no skeleton cleanup needed

--// ================= UI & TABS =================
local Window = Library:CreateWindow({
    Title = "Abyss",
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
        getgenv().AbyssAimbot.Enabled = state
    end
})

-- Target part dropdown
AimGroup:AddDropdown("AimTargetPart", {
    Values = {"Head", "Body", "Feet"},
    Default = 1,
    Multi = false,
    Text = "Aim Part",
    Callback = function(selected)
        getgenv().AbyssAimbot.TargetPart = selected
    end
})

-- Smoothness slider
AimGroup:AddSlider("AimSmooth", {
    Text = "Smoothness",
    Min = 1,
    Max = 5,
    Default = getgenv().AbyssAimbot.Smoothness,
    Increment = 1,
    Callback = function(value)
        getgenv().AbyssAimbot.Smoothness = math.max(1, math.floor(value))
    end
})

-- FOV slider (optional visual only)
AimGroup:AddSlider("AimFOV", {
    Text = "Max FOV (screen distance)",
    Min = 10,
    Max = 300,
    Default = getgenv().AbyssAimbot.FOV,
    Increment = 1,
    Callback = function(value)
        getgenv().AbyssAimbot.FOV = value
    end
})

local FOVToggle = AimGroup:AddToggle("ShowFOVCircle", {
    Text = "Show FOV Circle",
    Default = false,
    Callback = function(state)
        getgenv().AbyssAimbot.ShowFOV = state
    end
})

FOVToggle:AddColorPicker("FOVCircleColor", {
    Title = "FOV Circle Color",
    Default = getgenv().AbyssAimbot.FOVColor,
    Transparency = 0,
    Callback = function(color)
        getgenv().AbyssAimbot.FOVColor = color
    end
})

-- Hold-to-aim toggle (keeps behavior on by default)
AimGroup:AddToggle("HoldToAim", {
    Text = "Hold RMB to Aim",
    Default = getgenv().AbyssAimbot.HoldToAim,
    Callback = function(state)
        getgenv().AbyssAimbot.HoldToAim = state
    end
})

-- Max aim distance
AimGroup:AddSlider("AimDistance", {
    Text = "Max Aim Distance",
    Min = 50,
    Max = 1000,
    Default = getgenv().AbyssAimbot.MaxDistance,
    Increment = 10,
    Callback = function(v)
        getgenv().AbyssAimbot.MaxDistance = v
    end
})

-- Lock stickiness
AimGroup:AddSlider("AimStick", {
    Text = "Lock Stickiness",
    -- use integer percentage (50..95) to avoid decimal slider bugs
    Min = 50,
    Max = 100,
    Default = math.floor((getgenv().AbyssAimbot.LockStickiness or 0.85) * 100),
    Increment = 1,
    Callback = function(v)
        getgenv().AbyssAimbot.LockStickiness = (v or 50) / 100
    end
})

-- Aim delay
AimGroup:AddSlider("AimDelay", {
    -- use milliseconds (0..500) as integer to avoid decimal slider issues
    Text = "Aim Delay (ms)",
    Min = 0,
    Max = 500,
    Default = math.floor((getgenv().AbyssAimbot.AimDelay or 0) * 1000),
    Increment = 1,
    Callback = function(v)
        getgenv().AbyssAimbot.AimDelay = (v or 0) / 1000
    end
})

-- Wall check toggle
AimGroup:AddToggle("WallCheck", {
    Text = "Visibility Check",
    Default = getgenv().AbyssAimbot.WallCheck,
    Callback = function(v)
        getgenv().AbyssAimbot.WallCheck = v
    end
})

-- Aimbot Team Check toggle (exclude teammates)
AimGroup:AddToggle("AimbotTeamCheck", {
    Text = "Team Check",
    Default = getgenv().AbyssAimbot.TeamCheck,
    Callback = function(state)
        getgenv().AbyssAimbot.TeamCheck = state
    end
})

-- Use stickiness toggle
AimGroup:AddToggle("UseStickiness", {
    Text = "Sticky Lock",
    Default = getgenv().AbyssAimbot.UseStickiness,
    Callback = function(v)
        getgenv().AbyssAimbot.UseStickiness = v
    end
})

-- Use aim delay toggle
AimGroup:AddToggle("UseAimDelay", {
    Text = "Aim Delay",
    Default = getgenv().AbyssAimbot.UseAimDelay,
    Callback = function(v)
        getgenv().AbyssAimbot.UseAimDelay = v
    end
})

-- Legit/master mode toggle
AimGroup:AddToggle("LegitMode", {
    Text = "Legit Mode (master)",
    Default = getgenv().AbyssAimbot.LegitMode,
    Callback = function(v)
        getgenv().AbyssAimbot.LegitMode = v
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

-- Camera FOV slider in Misc tab
local CameraFOVSlider = MiscGroup:AddSlider("CameraFOV", {
    Text = "Camera FOV",
    Min = 60,
    Max = 120,
    Default = workspace.CurrentCamera.FieldOfView,
    Increment = 1,
    Callback = function(value)
        -- only apply the slider value to the actual Camera when the FOV lock is enabled
        if getgenv().Abyss and getgenv().Abyss.FOVLock then
            pcall(function()
                workspace.CurrentCamera.FieldOfView = value
            end)
        end
    end
})

-- Toggle to lock/unlock camera FOV enforcement
MiscGroup:AddToggle("LockCameraFOV", {
    Text = "Lock Camera FOV",
    Default = getgenv().Abyss.FOVLock,
    Callback = function(state)
        getgenv().Abyss.FOVLock = state
        -- when enabling the lock, immediately apply the slider's value to the camera
        if state then
            pcall(function()
                workspace.CurrentCamera.FieldOfView = CameraFOVSlider.Value
            end)
        end
    end
})


    MiscGroup:AddToggle("FullBright", {
        Text = "Full Bright",
        Default = false,
        Callback = function(state)
            local Lighting = game:GetService("Lighting")
            if state then
                -- Store original lighting values
                OriginalLighting.Brightness = Lighting.Brightness
                OriginalLighting.ClockTime = Lighting.ClockTime
                OriginalLighting.Ambient = Lighting.Ambient
                OriginalLighting.OutdoorAmbient = Lighting.OutdoorAmbient
                OriginalLighting.FogEnd = Lighting.FogEnd

                -- Apply full bright settings
                Lighting.Brightness = 2
                Lighting.ClockTime = 14 -- midday
                Lighting.Ambient = Color3.fromRGB(255, 255, 255)
                Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
                Lighting.FogEnd = 100000 -- effectively no fog

                FullBrightEnabled = true
            else
                -- Restore original lighting values
                if next(OriginalLighting) then
                    Lighting.Brightness = OriginalLighting.Brightness or Lighting.Brightness
                    Lighting.ClockTime = OriginalLighting.ClockTime or Lighting.ClockTime
                    Lighting.Ambient = OriginalLighting.Ambient or Lighting.Ambient
                    Lighting.OutdoorAmbient = OriginalLighting.OutdoorAmbient or Lighting.OutdoorAmbient
                    Lighting.FogEnd = OriginalLighting.FogEnd or Lighting.FogEnd
                end
                FullBrightEnabled = false
            end
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

-- FORCE CAMERA FOV to slider value each frame to prevent zoom effects
Connections.FOVLock = RunService.RenderStepped:Connect(function()
    -- Only enforce camera FOV when the FOV lock toggle is enabled
    if not (getgenv().Abyss and getgenv().Abyss.FOVLock) then return end
    if Camera and Camera.FieldOfView ~= CameraFOVSlider.Value then
        Camera.FieldOfView = CameraFOVSlider.Value
    end
end)

-- Third-person updater (robust)


MiscGroup:AddButton({
    Text = "Close Menu",
    Func = function()
        RUNNING = false

        -- Disable third-person before disconnecting
        getgenv().ThirdPersonEnabled = false

        -- Disconnect all connections safely
        for k, c in pairs(Connections) do
            if typeof(c) == "RBXScriptConnection" then
                pcall(function() c:Disconnect() end)
            end
            Connections[k] = nil
        end

        -- Disable all ESP
        getgenv().Abyss.Enabled = false

        -- Remove all ESP drawings
        for player, drawings in pairs(espCache) do
            for _, drawing in pairs(drawings) do
                pcall(function()
                    drawing.Visible = false
                    drawing:Remove()
                end)
            end
        end
        espCache = {}

        -- Remove text ESP drawings as well
        for player, texts in pairs(textESP) do
            for _, t in pairs(texts) do
                pcall(function()
                    t.Visible = false
                    t:Remove()
                end)
            end
        end
        textESP = {}

        -- no skeletons to remove (feature disabled)

        -- Remove FOV circle
        if FOVCircle then
            pcall(function() FOVCircle.Visible = false end)
            pcall(function() FOVCircle:Remove() end)
        end

        -- Stop chase
        pcall(stopChase)

        -- Restore default camera
        if LocalPlayer.Character then
            local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                Camera.CameraSubject = humanoid
                Camera.CameraType = Enum.CameraType.Custom
            end
        end

        -- Unload UI
        Library:Unload()
    end
})

-- Box ESP toggle
local BoxToggle = Visuals:AddToggle("BoxESP", {
    Text = "Box ESP",
    Default = false,
    Callback = function(state)
        getgenv().Abyss.Enabled = state
    end
})

-- Box ESP color picker
BoxToggle:AddColorPicker("BoxColor", {
    Title = "Box Color",
    Default = getgenv().Abyss.Color,
    Transparency = 0,
    Callback = function(color)
        getgenv().Abyss.Color = color
    end
})

-- HEAD CIRCLE TOGGLE + COLOR
-- head-circle UI removed

-- Name ESP toggle
local NameToggle = Visuals:AddToggle("NameESP", {
    Text = "Name ESP",
    Default = getgenv().Abyss.NameESP,
    Callback = function(state)
        getgenv().Abyss.NameESP = state
    end
})

NameToggle:AddColorPicker("NameColor", {
    Title = "Name Color",
    Default = getgenv().Abyss.NameColor,
    Callback = function(color)
        getgenv().Abyss.NameColor = color
    end
})

-- Health ESP toggle
local HealthToggle = Visuals:AddToggle("HealthESP", {
    Text = "Health ESP",
    Default = getgenv().Abyss.HealthESP,
    Callback = function(state)
        getgenv().Abyss.HealthESP = state
    end
})

HealthToggle:AddColorPicker("HealthColor", {
    Title = "Health Color",
    Default = getgenv().Abyss.HealthColor,
    Callback = function(color)
        getgenv().Abyss.HealthColor = color
    end
})

-- Distance ESP toggle
local DistanceToggle = Visuals:AddToggle("DistanceESP", {
    Text = "Distance ESP",
    Default = getgenv().Abyss.DistanceESP,
    Callback = function(state)
        getgenv().Abyss.DistanceESP = state
    end
})

DistanceToggle:AddColorPicker("DistanceColor", {
    Title = "Distance Color",
    Default = getgenv().Abyss.DistanceColor,
    Callback = function(color)
        getgenv().Abyss.DistanceColor = color
    end
})

-- Team check toggle: hide teammates when enabled
local TeamCheckToggle = Visuals:AddToggle("TeamCheck", {
    Text = "Team Check",
    Default = getgenv().Abyss.TeamCheck,
    Callback = function(state)
        getgenv().Abyss.TeamCheck = state
    end
})

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

        -- Disconnect all connections first
        for k, c in pairs(Connections) do
            if typeof(c) == "RBXScriptConnection" then
                pcall(function() c:Disconnect() end)
            end
            Connections[k] = nil
        end

        -- Hide and remove drawings safely
        if FOVCircle then
            pcall(function() FOVCircle.Visible = false end)
            pcall(function() FOVCircle:Remove() end)
        end
        for player, drawings in pairs(espCache) do
            for _, drawing in pairs(drawings) do
                pcall(function() drawing.Visible = false end)
                pcall(function() drawing:Remove() end)
            end
        end
        espCache = {}
        -- remove text ESP drawings too
        for player, texts in pairs(textESP) do
            for _, t in pairs(texts) do
                pcall(function() t.Visible = false end)
                pcall(function() t:Remove() end)
            end
        end
        textESP = {}
    end
end)
