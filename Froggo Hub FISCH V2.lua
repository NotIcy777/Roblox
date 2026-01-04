-- // LOAD LUNA INTERFACE SUITE
local Luna = loadstring(game:HttpGet("https://raw.githubusercontent.com/Nebula-Softworks/Luna-Interface-Suite/refs/heads/master/source.lua", true))()

-- Create the main UI window
local Window = Luna:CreateWindow({
    Name = "Froggo Menu V2",
    LoadingEnabled = false,
    KeySystem = false,
})

-- Services
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

-- Movement vars
local currentWalkSpeed = 16
local flying = false
local flySpeed = 50
local autoTPRunning = false
local autoTPIndex = 1
local guiAlive = true
local flyInputConnection

-- Tabs
Window:CreateHomeTab({SupportedExecutors = {}, DiscordInvite = "1234", Icon = 2, Whitelist = true})
local MainTab = Window:CreateTab({Name = "Main"})
local TeleportsTab = Window:CreateTab({Name = "Teleports"})
local CustomTab = Window:CreateTab({Name = "Custom TP"})
local MovementTab = Window:CreateTab({Name = "Movement"})
local AutoTP_Tab = Window:CreateTab({Name = "Cosmic TP"})
local MiscTab = Window:CreateTab({Name = "Misc"})

-- Sections
MainTab:CreateSection("Main Toggles")
TeleportsTab:CreateSection("Locations")
CustomTab:CreateSection("Custom Coordinates")
MovementTab:CreateSection("Player Movement")
AutoTP_Tab:CreateSection("Cosmic Teleports")
MiscTab:CreateSection("Misc Functions")

----------------------
-- MAIN TOGGLES
----------------------
local mainToggles = {}
for _, name in ipairs({"Auto Shake","Auto Cast","Auto Finish"}) do
    mainToggles[name] = false
    MainTab:CreateToggle({
        Name = name,
        CurrentValue = false,
        Callback = function(val)
            mainToggles[name] = val
        end
    })
end

----------------------
-- TELEPORTS
----------------------
local teleportLocations = {
    ["Ancient Isles"] = CFrame.new(5869,162,419),
    ["Crystal Cove"] = CFrame.new(1374,-603,2338),
    ["Carrot Garden"] = CFrame.new(3730,-1127,-1096),
    ["Boreal Pines"] = CFrame.new(21725,134,4010),
    ["Sell"] = CFrame.new(466,150,229),
    ["Appraiser"] = CFrame.new(447,150,206),
    ["Enchant"] = CFrame.new(1310,-803,-83),
    ["Black Market"] = CFrame.new(2012,-645,2479),
    ["Daily Shop"] = CFrame.new(223,138,20),
}

for name, cf in pairs(teleportLocations) do
    TeleportsTab:CreateButton({
        Name = name,
        Callback = function()
            if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
                Player.Character.HumanoidRootPart.CFrame = cf
            end
        end
    })
end

----------------------
-- CUSTOM TP
----------------------
local customCoordsInput = ""

CustomTab:CreateInput({
    Name = "Paste Coordinates",
    PlaceholderText = "X,Y,Z or (X,Y,Z)",
    MultiLine = true,
    Callback = function(text)
        customCoordsInput = text
    end
}, "Input")

CustomTab:CreateButton({
    Name = "Teleport to Custom Coord",
    Callback = function()
        if not Player.Character or not Player.Character:FindFirstChild("HumanoidRootPart") then return end
        for line in customCoordsInput:gmatch("[^\r\n]+") do
            local nums = {}
            for n in line:gmatch("-?%d+%.?%d*") do
                table.insert(nums, tonumber(n))
            end
            if #nums == 3 then
                Player.Character.HumanoidRootPart.CFrame = CFrame.new(nums[1], nums[2], nums[3])
                break
            end
        end
    end
})

CustomTab:CreateButton({
    Name = "Get Current Pos",
    Callback = function()
        if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
            local pos = Player.Character.HumanoidRootPart.Position
            customCoordsInput = string.format("%d, %d, %d", pos.X, pos.Y, pos.Z)
        end
    end
})

----------------------
-- MOVEMENT
----------------------
MovementTab:CreateSlider({
    Name = "Walk Speed",
    Range = {16, 100},
    Increment = 1,
    CurrentValue = 16,
    Callback = function(val)
        currentWalkSpeed = val
        if Player.Character and Player.Character:FindFirstChildOfClass("Humanoid") then
            Player.Character.Humanoid.WalkSpeed = val
        end
    end
}, "Slider")

MovementTab:CreateSlider({
    Name = "Fly Speed",
    Range = {20, 200},
    Increment = 5,
    CurrentValue = 50,
    Callback = function(val)
        flySpeed = val
    end
}, "Slider")

MovementTab:CreateButton({
    Name = "Toggle Fly (F)",
    Callback = function()
        ToggleFly()
    end
})

----------------------
-- COSMIC TP
----------------------
local CosmicLocations = {
    -- Northern Expedition
    Vector3.new(19608, 172, 5340),
    Vector3.new(20312, 220, 5226),
    Vector3.new(19287, 398, 6133),
    Vector3.new(19611, 399, 5474),
    Vector3.new(19256, 416, 5780),
    Vector3.new(19896, 460, 4989),
    Vector3.new(19616, 470, 6036),
    Vector3.new(20142, 656, 5830),
    Vector3.new(20326, 722, 5719),
    Vector3.new(20057, 1045, 5755),
    Vector3.new(19829, 1050, 5486),
    Vector3.new(20007, 1138, 5379),

    -- Snowcap Island
    Vector3.new(2662, 171, 2540),
    Vector3.new(3376, 132, 2877),
    Vector3.new(2944, 151, 2469),

    -- Ancient Isle
    Vector3.new(6251, 145, 926),
    Vector3.new(5689, 164, 687),
    Vector3.new(6061, 203, 376),
    Vector3.new(5469, 142, -332),
    Vector3.new(5960, 262, 223),
    Vector3.new(6127, 386, 597),
    Vector3.new(5683, 184, -182),
    Vector3.new(6157, 273, 347),

    -- Moosewood
    Vector3.new(614, 167, 221),
    Vector3.new(447, 142, 306),

    -- Forsaken Shores
    Vector3.new(-2899, 231, 1275),
    Vector3.new(-2674, 168, 1787),
    Vector3.new(-2821, 272, 2544),
    Vector3.new(-2694, 133, 1586),

    -- Castaway Cliffs
    Vector3.new(362, 203, -1817),
    Vector3.new(449, 307, -2077),

    -- Sunstone Island
    Vector3.new(-852, 137, -1166),
    Vector3.new(-1132, 222, -1084),

    -- Statue of Sovereignty
    Vector3.new(-131, 153, -1157),

    -- Terrapin Island
    Vector3.new(78, 217, 2082),
    Vector3.new(-56, 154, 1961),

    -- Grand Reef
    Vector3.new(-3689, 143, 735),

    -- Mushgrove Swamp
    Vector3.new(2664, 134, -856),
    Vector3.new(2542, 166, -1000),

    -- Birch Cay
    Vector3.new(1775, 142, -2481),

    -- Earmark Island
    Vector3.new(1218, 154, 455),

    -- The Arch
    Vector3.new(1008, 133, -1290),

    -- Haddock Rock
    Vector3.new(1899, 184, -1156),

    -- Unnamed Rocks
    Vector3.new(1897, 183, -1155),
    Vector3.new(2145, 186, 898),
    Vector3.new(-1572, 128, 2235),
}


AutoTP_Tab:CreateButton({
    Name = "Start Cosmic TP",
    Callback = function()
        if autoTPRunning then return end
        autoTPRunning = true
        task.spawn(function()
            while autoTPRunning and autoTPIndex <= #CosmicLocations do
                if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
                    Player.Character.HumanoidRootPart.CFrame = CFrame.new(CosmicLocations[autoTPIndex]+Vector3.new(0,3,0))
                end
                autoTPIndex = autoTPIndex + 1
                task.wait(1)
            end
            autoTPRunning = false
            autoTPIndex = 1
        end)
    end
})

AutoTP_Tab:CreateButton({
    Name = "Stop Cosmic TP",
    Callback = function()
        autoTPRunning = false
        autoTPIndex = 1
    end
})


----------------------
-- MISC BUTTONS
----------------------
MiscTab:CreateButton({
    Name = "Respawn",
    Callback = function()
        if Player.Character and Player.Character:FindFirstChild("Humanoid") then
            Player.Character.Humanoid.Health = 0
        end
    end
})

MiscTab:CreateButton({
    Name = "Server Hop",
    Callback = function()
        local servers = nil
        local placeID = game.PlaceId
        local url = ("https://games.roblox.com/v1/games/%d/servers/Public?limit=100"):format(placeID)
        local success, body = pcall(function() return game:HttpGet(url) end)
        if success then
            local decoded = HttpService:JSONDecode(body)
            servers = decoded.data
        end
        if servers then
            for _, s in pairs(servers) do
                if tostring(s.id) ~= tostring(game.JobId) then
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, Player)
                    break
                end
            end
        end
    end
})

MiscTab:CreateButton({
    Name = "Rejoin Server",
    Callback = function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Player)
    end
})

MiscTab:CreateButton({
    Name = "Copy Discord Link",
    Callback = function()
        if setclipboard then pcall(setclipboard, "https://discord.gg/3v3JrVv9") end
    end
})

MiscTab:CreateButton({
    Name = "Delete GUI",
    Callback = function()
        flying = false
        autoTPRunning = false
        autoTPIndex = 1
        if Player.Character then
            local root = Player.Character:FindFirstChild("HumanoidRootPart")
            local hum = Player.Character:FindFirstChildOfClass("Humanoid")
            if root then
                local bv = root:FindFirstChild("FlyBV")
                if bv then bv:Destroy() end
                local bg = root:FindFirstChild("FlyBG")
                if bg then bg:Destroy() end
            end
            if hum then hum.PlatformStand=false end
        end
        guiAlive = false

        if flyInputConnection then
            flyInputConnection:Disconnect()
            flyInputConnection = nil
        end
        pcall(function() Luna:Destroy() end)
    end
})

----------------------
-- FLY FUNCTION
----------------------
function ToggleFly()
    if not guiAlive then return end
    local char = Player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if flying then
        flying = false
        if hum then hum.PlatformStand=false end
        if root then
            local bv=root:FindFirstChild("FlyBV")
            if bv then bv:Destroy() end
            local bg=root:FindFirstChild("FlyBG")
            if bg then bg:Destroy() end
        end
        return
    end
    if root and hum then
        flying=true
        local bv=Instance.new("BodyVelocity",root)
        bv.Name="FlyBV"
        bv.MaxForce=Vector3.new(math.huge,math.huge,math.huge)
        bv.Velocity=Vector3.zero
        local bg=Instance.new("BodyGyro",root)
        bg.Name="FlyBG"
        bg.MaxTorque=Vector3.new(math.huge,math.huge,math.huge)
        bg.P=9e4
        hum.PlatformStand=true
        task.spawn(function()
            while flying and char.Parent and root.Parent do
                local cam=workspace.CurrentCamera
                local dir=Vector3.zero
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir=dir+cam.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir=dir-cam.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir=dir-cam.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir=dir+cam.CFrame.RightVector end
                bv.Velocity=dir*flySpeed
                bg.CFrame=cam.CFrame
                RunService.RenderStepped:Wait()
            end
            if bv then bv:Destroy() end
            if bg then bg:Destroy() end
            if hum and hum.Parent then hum.PlatformStand=false end
        end)
    end
end

-- Toggle fly with F key
flyInputConnection = UserInputService.InputBegan:Connect(function(i, gp)
    if gp or not guiAlive then return end
    if i.KeyCode == Enum.KeyCode.F then
        ToggleFly()
    end
end)

----------------------
-- WalkSpeed persistence
----------------------
RunService.RenderStepped:Connect(function()
    if Player.Character and Player.Character:FindFirstChildOfClass("Humanoid") then
        local hum = Player.Character:FindFirstChildOfClass("Humanoid")
        if hum.WalkSpeed ~= currentWalkSpeed then
            hum.WalkSpeed = currentWalkSpeed
        end
    end
end)
