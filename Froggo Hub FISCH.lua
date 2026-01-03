
-- // CONFIGURATION
local USE_WHITELIST = true
local WHITELIST_ID = 9257469606
local CORRECT_KEY = "Fisch-2382"

-- // SERVICES & VARIABLES
local Player = game.Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FroggoMenu_V1"
ScreenGui.Parent = Player:WaitForChild("PlayerGui")
ScreenGui.ResetOnSpawn = false

local Connections = {}
local discordLink = "https://discord.gg/3v3JrVv9"
local isVerified = false
local flying = false
local flySpeed = 50
local currentWalkSpeed = 16
local currentJumpPower = 50

-- // THEME COLORS
local BG_COLOR = Color3.fromRGB(30,30,30)
local TOP_COLOR = Color3.fromRGB(20,20,20)
local ACCENT = Color3.fromRGB(0,200,100)
local BTN_GREY = Color3.fromRGB(55,55,55)
local TAB_GREY = Color3.fromRGB(40,40,40)

-------------------------------------------------------------------
-- 1. UTILITIES & FEEDBACK
-------------------------------------------------------------------
local function ClickEffect(button, originalColor)
    button.BackgroundColor3 = ACCENT
    task.delay(0.3, function()
        if button and button.Parent then
            button.BackgroundColor3 = originalColor
        end
    end)
end

local function ShowNotification(msg)
    if not ScreenGui.Parent then return end
    local NF = Instance.new("Frame")
    NF.Size = UDim2.new(0,250,0,60)
    NF.Position = UDim2.new(1,20,0.5,-30)
    NF.BackgroundColor3 = Color3.fromRGB(20,20,20)
    Instance.new("UICorner",NF)
    local NT = Instance.new("TextLabel",NF)
    NT.Size = UDim2.new(1,0,1,0)
    NT.BackgroundTransparency = 1
    NT.Text = msg
    NT.TextColor3 = Color3.fromRGB(255,255,255)
    NT.Font = Enum.Font.SourceSansBold
    NT.TextScaled = true
    NF.Parent = ScreenGui
    pcall(function() NF:TweenPosition(UDim2.new(1,-270,0.5,-30),"Out","Quart",0.5,true) end)
    task.delay(3,function()
        if NF and NF.Parent then
            pcall(function() NF:TweenPosition(UDim2.new(1,20,0.5,-30),"In","Quart",0.5,true,function() NF:Destroy() end) end)
        end
    end)
end

-------------------------------------------------------------------
-- 2. MOVEMENT LOOP
-------------------------------------------------------------------
local MoveLoop = RunService.Heartbeat:Connect(function()
    if isVerified and Player.Character and Player.Character:FindFirstChild("Humanoid") then
        local hum = Player.Character.Humanoid
        hum.WalkSpeed = currentWalkSpeed
        hum.UseJumpPower = true
        hum.JumpPower = currentJumpPower
    end
end)
table.insert(Connections, MoveLoop)

-------------------------------------------------------------------
-- 3. UI MAIN HUB
-------------------------------------------------------------------
local MainMenu = Instance.new("Frame",ScreenGui)
MainMenu.Size = UDim2.new(0,450,0,320)
MainMenu.Position = UDim2.new(0.5,-225,0.5,-160)
MainMenu.BackgroundColor3 = BG_COLOR
MainMenu.Visible = false
MainMenu.Active = true
MainMenu.Draggable = true
Instance.new("UICorner",MainMenu)

local DragBar = Instance.new("Frame",MainMenu)
DragBar.Size = UDim2.new(1,0,0,35)
DragBar.BackgroundColor3 = TOP_COLOR
Instance.new("UICorner",DragBar)

local Title = Instance.new("TextLabel",DragBar)
Title.Size = UDim2.new(1,0,1,0)
Title.BackgroundTransparency = 1
Title.Text = "Froggo Menu V1"
Title.TextColor3 = ACCENT
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 20

local CloseBtn = Instance.new("TextButton",DragBar)
CloseBtn.Size = UDim2.new(0,30,0,25)
CloseBtn.Position = UDim2.new(1,-35,0,5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(180,50,50)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255,255,255)
Instance.new("UICorner",CloseBtn)

CloseBtn.MouseButton1Click:Connect(function()
    flying = false
    isVerified = false
    for _,conn in pairs(Connections) do conn:Disconnect() end
    if Player.Character and Player.Character:FindFirstChild("Humanoid") then
        Player.Character.Humanoid.WalkSpeed = 16
        Player.Character.Humanoid.JumpPower = 50
    end
    ScreenGui:Destroy()
end)

local Content = Instance.new("Frame",MainMenu)
Content.Size = UDim2.new(0,320,1,-45)
Content.Position = UDim2.new(0,120,0,40)
Content.BackgroundTransparency = 1

local Pages = {}
local function CreatePage(name)
    local p = Instance.new("CanvasGroup",Content)
    p.Name = name
    p.Size = UDim2.new(1,0,1,0)
    p.BackgroundTransparency = 1
    p.Visible = false
    Pages[name] = p
    return p
end

local PageTp = CreatePage("Tp")
local PageCustom = CreatePage("Custom")
local PageMove = CreatePage("Movement")
local PageRods = CreatePage("Rods")
local PageMisc = CreatePage("Misc")
local PagePlayerTP = CreatePage("PlayerTP")
local PageAutoTP = CreatePage("AutoTP")

-- Scrolling container for Teleports page
local PageTpScroll = Instance.new("ScrollingFrame", PageTp)
PageTpScroll.Name = "Scroll"
PageTpScroll.Size = UDim2.new(1,0,1,0)
PageTpScroll.Position = UDim2.new(0,0,0,0)
PageTpScroll.BackgroundTransparency = 1
PageTpScroll.BorderSizePixel = 0
PageTpScroll.CanvasSize = UDim2.new(0,0,0,0)
PageTpScroll.ScrollBarThickness = 6
PageTpScroll.ScrollBarImageColor3 = ACCENT

local TpLayout = Instance.new("UIListLayout", PageTpScroll)
TpLayout.Padding = UDim.new(0, 10)

TpLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    PageTpScroll.CanvasSize = UDim2.new(
        0,
        0,
        0,
        TpLayout.AbsoluteContentSize.Y + 10
    )
end)

-- Sidebar
local Sidebar = Instance.new("Frame",MainMenu)
Sidebar.Size = UDim2.new(0,110,1,-35)
Sidebar.Position = UDim2.new(0,0,0,35)
Sidebar.BackgroundColor3 = Color3.fromRGB(25,25,25)
Instance.new("UICorner",Sidebar)

local function TabBtn(name,pos,pg)
    local b = Instance.new("TextButton",Sidebar)
    b.Size = UDim2.new(0.9,0,0,35)
    b.Position = UDim2.new(0.05,0,0,pos)
    b.BackgroundColor3 = TAB_GREY
    b.Text = name
    b.TextColor3 = Color3.fromRGB(255,255,255)
    b.TextScaled = true
    b.Font = Enum.Font.GothamBold
    Instance.new("UICorner",b)

    -- If parent is a ScrollingFrame, expand its CanvasSize to fit this button


    -- Hover effect
    b.MouseEnter:Connect(function()
        TweenService:Create(b,TweenInfo.new(0.15),{BackgroundColor3=ACCENT}):Play()
    end)
    b.MouseLeave:Connect(function()
        TweenService:Create(b,TweenInfo.new(0.15),{BackgroundColor3=TAB_GREY}):Play()
    end)

    b.MouseButton1Click:Connect(function()
        ClickEffect(b,TAB_GREY)
        for _,v in pairs(Pages) do v.Visible=false end
        pg.Visible = true
        pg.GroupTransparency=1
        TweenService:Create(pg,TweenInfo.new(0.3),{GroupTransparency=0}):Play()
    end)
end

TabBtn("Teleports",10,PageTp)
TabBtn("Custom TP",50,PageCustom)
TabBtn("Movement",90,PageMove)
TabBtn("Auto TP",130,PageAutoTP)
TabBtn("Misc",170,PageMisc)
TabBtn("Player TP",210,PagePlayerTP)

local function QuickBtn(parent,text,pos,func)
    local b = Instance.new("TextButton",parent)
    b.Size = UDim2.new(0.95,0,0,40)
    if pos then
        b.Position = UDim2.new(0,0,0,pos)
    end
    b.BackgroundColor3 = BTN_GREY
    b.Text = text
    b.TextColor3 = Color3.fromRGB(255,255,255)
    b.TextScaled = true
    b.Font = Enum.Font.GothamBold
    Instance.new("UICorner",b)

    -- Hover effect
    b.MouseEnter:Connect(function()
        TweenService:Create(b,TweenInfo.new(0.15),{BackgroundColor3=ACCENT}):Play()
    end)
    b.MouseLeave:Connect(function()
        TweenService:Create(b,TweenInfo.new(0.15),{BackgroundColor3=BTN_GREY}):Play()
    end)

    b.MouseButton1Click:Connect(function()
        -- Click pop animation
        local tween = TweenService:Create(b, TweenInfo.new(0.1), {Size=UDim2.new(0.96,0,0,38)})
        tween:Play()
        tween.Completed:Wait()
        tween = TweenService:Create(b, TweenInfo.new(0.1), {Size=UDim2.new(0.95,0,0,40)})
        tween:Play()

        -- Run function
        func()
    end)
end

-------------------------------------------------------------------
-- 4. PAGE FEATURES
-------------------------------------------------------------------
-- Teleports
QuickBtn(PageTpScroll,"Ancient Isles",0,function()
    if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
        Player.Character.HumanoidRootPart.CFrame=CFrame.new(5869,162,419)
        ShowNotification("Teleported!")
    end
end)
QuickBtn(PageTpScroll,"Crystal Cove",50,function()
    if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
        Player.Character.HumanoidRootPart.CFrame=CFrame.new(1374,-603,2338)
        ShowNotification("Teleported!")
    end
end)
QuickBtn(PageTpScroll,"Carrot Garden",100,function()
    if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
        Player.Character.HumanoidRootPart.CFrame=CFrame.new(3730,-1127,-1096)
        ShowNotification("Teleported!")
    end
end)
QuickBtn(PageTpScroll,"Boreal Pines",150,function()
    if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
        Player.Character.HumanoidRootPart.CFrame=CFrame.new(21725, 134, 4010)
        ShowNotification("Teleported!")
    end
end)
QuickBtn(PageTpScroll,"Sell",200,function()
    if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
        Player.Character.HumanoidRootPart.CFrame=CFrame.new(466,150,229)
        ShowNotification("Teleported!")
    end
end)
QuickBtn(PageTpScroll,"Appraiser",250,function()
    if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
        Player.Character.HumanoidRootPart.CFrame=CFrame.new(447,150,206)
        ShowNotification("Teleported!")
    end
end)
QuickBtn(PageTpScroll,"Enchant",300,function()
    if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
        Player.Character.HumanoidRootPart.CFrame=CFrame.new(1310,-803,-83)
        ShowNotification("Teleported!")
    end
end)
QuickBtn(PageTpScroll,"Black Market",350,function()
    if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
        Player.Character.HumanoidRootPart.CFrame=CFrame.new(2012,-645,2479)
        ShowNotification("Teleported!")
    end
end)
QuickBtn(PageTpScroll,"Daily Shop",400,function()
    if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
        Player.Character.HumanoidRootPart.CFrame=CFrame.new(223,138,20)
        ShowNotification("Teleported!")
    end
end)

-- Auto TP tab scroll area and functionality
local AutoTPScroll = Instance.new("ScrollingFrame", PageAutoTP)
AutoTPScroll.Size = UDim2.new(1,0,1,0)
AutoTPScroll.Position = UDim2.new(0,0,0,0)
AutoTPScroll.BackgroundTransparency = 1
AutoTPScroll.BorderSizePixel = 0
AutoTPScroll.CanvasSize = UDim2.new(0,0,0,0)
AutoTPScroll.ScrollBarThickness = 6
AutoTPScroll.ScrollBarImageColor3 = ACCENT

local TPLayout = Instance.new("UIListLayout", AutoTPScroll)
TPLayout.Padding = UDim.new(0, 10)
TPLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    AutoTPScroll.CanvasSize = UDim2.new(0, 0, 0, TPLayout.AbsoluteContentSize.Y + 10)
end)

local FallenStarLocations = {
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

    -- Haddock Rock / Unnamed Rocks
    Vector3.new(1899, 184, -1156),
    Vector3.new(1897, 183, -1155),

    Vector3.new(2145, 186, 898),
    Vector3.new(-1572, 128, 2235),
}

local autoTPIndex = 1
local autoTPRunning = false

local function StartAutoTP()
    if autoTPRunning then return end
    autoTPRunning = true
    ShowNotification("Auto TP Started!")
    task.spawn(function()
        while autoTPIndex <= #FallenStarLocations and autoTPRunning and Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") do
            Player.Character.HumanoidRootPart.CFrame = CFrame.new(FallenStarLocations[autoTPIndex] + Vector3.new(0,3,0))
            ShowNotification("Teleported to Fallen Star #" .. autoTPIndex)
            autoTPIndex = autoTPIndex + 1
            task.wait(1)
        end
        ShowNotification("Auto TP Finished!")
        autoTPRunning = false
        autoTPIndex = 1
    end)
end

local function StopAutoTP()
    if autoTPRunning then
        autoTPRunning = false
        ShowNotification("Auto TP Stopped!")
        autoTPIndex = 1
    end
end

QuickBtn(AutoTPScroll, "Start Auto TP", 0, StartAutoTP)
QuickBtn(AutoTPScroll, "Stop Auto TP", 50, StopAutoTP)

-------------------------------------------------------------------
-- Clipboard utilities for Custom TP
-------------------------------------------------------------------
local function CopyCurrentPos()
    local char = Player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local p = root.Position
    local text = string.format("%d, %d, %d",
        math.floor(p.X),
        math.floor(p.Y),
        math.floor(p.Z)
    )

    if setclipboard then
        pcall(function() setclipboard(text) end)
        ShowNotification("Position copied!")
        return
    end

    -- Fallback: populate inputs (if present) and show a small modal so user can manually copy
    if InX then InX.Text = tostring(math.floor(p.X)) end
    if InY then InY.Text = tostring(math.floor(p.Y)) end
    if InZ then InZ.Text = tostring(math.floor(p.Z)) end

    local modal = Instance.new("Frame", ScreenGui)
    modal.Size = UDim2.new(0,320,0,90)
    modal.Position = UDim2.new(0.5,-160,0.5,-45)
    modal.BackgroundColor3 = BG_COLOR
    modal.Name = "ClipboardFallbackCopy"
    Instance.new("UICorner", modal)

    local tb = Instance.new("TextBox", modal)
    tb.Size = UDim2.new(1,-20,0,40)
    tb.Position = UDim2.new(0,10,0,10)
    tb.BackgroundColor3 = Color3.fromRGB(45,45,45)
    tb.TextColor3 = Color3.fromRGB(255,255,255)
    tb.TextScaled = true
    tb.ClearTextOnFocus = false
    tb.Text = text
    Instance.new("UICorner", tb)

    local close = Instance.new("TextButton", modal)
    close.Size = UDim2.new(0.5,-10,0,26)
    close.Position = UDim2.new(0.5,5,0,52)
    close.BackgroundColor3 = ACCENT
    close.TextColor3 = Color3.new(1,1,1)
    close.Text = "Close"
    Instance.new("UICorner", close)
    close.MouseButton1Click:Connect(function() if modal and modal.Parent then modal:Destroy() end end)

    ShowNotification("Clipboard unsupported — manually copy the shown coords")
end

local function PasteCoords()
    if getclipboard then
        local ok, text = pcall(function() return getclipboard() end)

            if not ok or not text then
                ShowNotification("Clipboard empty or inaccessible")
                return
            end

        local nums = {}
        for n in text:gmatch("-?%d+") do
            table.insert(nums, n)
        end

        if #nums < 3 then
            ShowNotification("Invalid clipboard format")
            return
        end

        if InX then InX.Text = nums[1] end
        if InY then InY.Text = nums[2] end
        if InZ then InZ.Text = nums[3] end
        ShowNotification("Coords pasted!")
        return
    end

    -- Fallback: prompt user to paste into a modal TextBox
    local modal = Instance.new("Frame", ScreenGui)
    modal.Size = UDim2.new(0,360,0,120)
    modal.Position = UDim2.new(0.5,-180,0.5,-60)
    modal.BackgroundColor3 = BG_COLOR
    modal.Name = "ClipboardFallbackPaste"
    Instance.new("UICorner", modal)

    local prompt = Instance.new("TextLabel", modal)
    prompt.Size = UDim2.new(1,-20,0,24)
    prompt.Position = UDim2.new(0,10,0,8)
    prompt.BackgroundTransparency = 1
    prompt.TextColor3 = Color3.fromRGB(200,200,200)
    prompt.TextScaled = true
    prompt.Text = "Paste coords (e.g. 510, 150, 263)"

    local tb = Instance.new("TextBox", modal)
    tb.Size = UDim2.new(1,-20,0,36)
    tb.Position = UDim2.new(0,10,0,36)
    tb.BackgroundColor3 = Color3.fromRGB(45,45,45)
    tb.TextColor3 = Color3.fromRGB(255,255,255)
    tb.Text = ""
    tb.TextScaled = true
    tb.ClearTextOnFocus = false
    Instance.new("UICorner", tb)

    local okBtn = Instance.new("TextButton", modal)
    okBtn.Size = UDim2.new(0.45,-10,0,26)
    okBtn.Position = UDim2.new(0.05,0,1,-34)
    okBtn.BackgroundColor3 = ACCENT
    okBtn.TextColor3 = Color3.new(1,1,1)
    okBtn.Text = "OK"
    Instance.new("UICorner", okBtn)

    local cancelBtn = Instance.new("TextButton", modal)
    cancelBtn.Size = UDim2.new(0.45,-10,0,26)
    cancelBtn.Position = UDim2.new(0.5,5,1,-34)
    cancelBtn.BackgroundColor3 = Color3.fromRGB(180,50,50)
    cancelBtn.TextColor3 = Color3.new(1,1,1)
    cancelBtn.Text = "Cancel"
    Instance.new("UICorner", cancelBtn)

    local function parseAndApply(text)
        local nums = {}
        for n in text:gmatch("-?%d+") do table.insert(nums, n) end
        if #nums < 3 then
            ShowNotification("Invalid format")
            return false
        end
        ShowNotification("Parsed "..tostring(#nums).." numbers")
        ShowNotification("First parsed: "..tostring(nums[1]))
        if InX then InX.Text = tostring(nums[1]) end
        if InY then InY.Text = tostring(nums[2]) end
        if InZ then InZ.Text = tostring(nums[3]) end
        ShowNotification("Coords pasted!")
        return true
    end

    okBtn.MouseButton1Click:Connect(function()
        if parseAndApply(tb.Text) then if modal and modal.Parent then modal:Destroy() end end
    end)
    cancelBtn.MouseButton1Click:Connect(function() if modal and modal.Parent then modal:Destroy() end end)
end

-- Custom TP
local function CreateLabeledInput(labelName,pos)
    local container=Instance.new("Frame",PageCustom)
    container.Size=UDim2.new(0.28,0,0,55)
    container.Position=pos
    container.BackgroundTransparency=1
    local lbl=Instance.new("TextLabel",container)
    lbl.Size=UDim2.new(1,0,0.4,0)
    lbl.Text=labelName
    lbl.TextColor3=Color3.fromRGB(200,200,200)
    lbl.BackgroundTransparency=1
    lbl.TextScaled=true
    local box=Instance.new("TextBox",container)
    box.Size=UDim2.new(1,0,0.6,0)
    box.Position=UDim2.new(0,0,0.4,0)
    box.BackgroundColor3=Color3.fromRGB(45,45,45)
    box.Text=""
    box.TextColor3=Color3.fromRGB(255,255,255)
    box.TextScaled=true
    Instance.new("UICorner",box)
    -- expose globals so earlier-defined functions can access these boxes
    if labelName:match("^X") then InX = box end
    if labelName:match("^Y") then InY = box end
    if labelName:match("^Z") then InZ = box end
    return box
end

local InX=CreateLabeledInput("X Coord",UDim2.new(0.05,0,0.05,0))
local InY=CreateLabeledInput("Y Coord",UDim2.new(0.36,0,0.05,0))
local InZ=CreateLabeledInput("Z Coord",UDim2.new(0.67,0,0.05,0))

QuickBtn(PageCustom,"Teleport to Coords",70,function()
    local x,y,z = tonumber(InX.Text), tonumber(InY.Text), tonumber(InZ.Text)
    if x and y and z and Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
        Player.Character.HumanoidRootPart.CFrame = CFrame.new(x,y,z)
        ShowNotification("Teleported!")
    end
end)

QuickBtn(PageCustom,"Get Current Pos",120,function()
    if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
        local p=Player.Character.HumanoidRootPart.Position
        InX.Text=tostring(math.floor(p.X))
        InY.Text=tostring(math.floor(p.Y))
        InZ.Text=tostring(math.floor(p.Z))
    end
end)

QuickBtn(PageCustom,"Copy Current Pos",170,CopyCurrentPos)
QuickBtn(PageCustom,"Paste Coords",220,PasteCoords)

-- Movement Sliders (linearly mapped)
local function CreateSlider(parent,name,minVal,maxVal,displayStart,pos,callback)
    local label=Instance.new("TextLabel",parent)
    label.Size=UDim2.new(1,0,0,20)
    label.Position=pos
    label.Text=name..": "..displayStart
    label.TextColor3=Color3.fromRGB(255,255,255)
    label.BackgroundTransparency=1
    label.TextScaled=true

    local back=Instance.new("Frame",parent)
    back.Size=UDim2.new(0.8,0,0,8)
    back.Position=pos+UDim2.new(0.1,0,0.08,0)
    back.BackgroundColor3=Color3.fromRGB(50,50,50)
    Instance.new("UICorner",back)

    local btn=Instance.new("TextButton",back)
    btn.Size=UDim2.new(0,16,2,0)
    btn.Position=UDim2.new(0,0,-0.5,0)
    btn.BackgroundColor3=ACCENT
    btn.Text=""
    Instance.new("UICorner",btn)

    local dragging=false
    btn.MouseButton1Down:Connect(function() dragging=true end)
    local iEnd = UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
    end)
    table.insert(Connections,iEnd)

    local dUpdate = RunService.RenderStepped:Connect(function()
        if dragging then
            local mousePos=UserInputService:GetMouseLocation().X
            local rel=math.clamp((mousePos-back.AbsolutePosition.X)/back.AbsoluteSize.X,0,1)
            btn.Position=UDim2.new(rel,-8,-0.5,0)
            local val=minVal+(rel*(maxVal-minVal))
            callback(val,rel,label)
        end
    end)
    table.insert(Connections,dUpdate)
end

-- Map 1.0–2.4 to actual WalkSpeed (16–38.4)
CreateSlider(PageMove,"Walk Speed",16,38.4,"1.0",UDim2.new(0,0,0.1,0),function(val,rel,lbl)
    currentWalkSpeed=val
    lbl.Text=string.format("Walk Speed: %.2f",1+rel*1.4)
end)

-- Map 1.0–1.8 to actual JumpPower (50–90)
CreateSlider(PageMove,"Jump Power",50,90,"1.0",UDim2.new(0,0,0.35,0),function(val,rel,lbl)
    currentJumpPower=val
    lbl.Text=string.format("Jump Power: %.2f",1+rel*0.8)
end)

-------------------------------------------------------------------
-- ROD SECTION
-------------------------------------------------------------------
-------------------------------------------------------------------
-- Gear Section (client-sided add to inventory)
-------------------------------------------------------------------
local clientEquipped = {}

local GearInput = Instance.new("TextBox", PageRods)
GearInput.Size = UDim2.new(0.9, 0, 0, 30)
GearInput.Position = UDim2.new(0.05, 0, 0.05, 0)
GearInput.PlaceholderText = "Gear ID (e.g. 12345678)"
GearInput.TextScaled = true
GearInput.BackgroundColor3 = Color3.fromRGB(45,45,45)
GearInput.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", GearInput)

local EquipList = Instance.new("ScrollingFrame", PageRods)
EquipList.Size = UDim2.new(0.9, 0, 0, 160)
EquipList.Position = UDim2.new(0.05, 0, 0.18, 0)
EquipList.CanvasSize = UDim2.new(0,0,0,0)
EquipList.ScrollBarThickness = 6
EquipList.BackgroundTransparency = 1

local EquipLayout = Instance.new("UIListLayout", EquipList)
EquipLayout.Padding = UDim.new(0,6)

local function refreshEquippedUI()
    for _,v in pairs(EquipList:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
    for i,inst in ipairs(clientEquipped) do
        local btn = Instance.new("TextButton", EquipList)
        btn.Size = UDim2.new(1, -6, 0, 35)
        btn.Position = UDim2.new(0,3,0,(i-1)*40)
        btn.Text = (inst.Name or "Added Gear")
        btn.TextScaled = true
        btn.BackgroundColor3 = BTN_GREY
        Instance.new("UICorner", btn)
    end
    task.wait()
    EquipList.CanvasSize = UDim2.new(0,0,0,EquipLayout.AbsoluteContentSize.Y + 5)
end

local function addGearById(id)
    local idnum = tonumber(tostring(id):match("%d+"))
    if not idnum then
        ShowNotification("Invalid gear id")
        return
    end

    local ok, objs = pcall(function()
        return game:GetObjects("rbxassetid://" .. idnum)
    end)

    if not ok or not objs or #objs == 0 then
        ShowNotification("Failed to load asset")
        return
    end

    local backpack = Player:FindFirstChildOfClass("Backpack") or Player:FindFirstChild("Backpack") or Player:WaitForChild("Backpack")
    local added = {}

    for _,obj in ipairs(objs) do
        -- top-level tool
        if obj:IsA("Tool") then
            local t = obj:Clone()
            pcall(function() t.Parent = backpack end)
            table.insert(added, t)
        end
        -- descendants that are tools
        for _,inst in ipairs(obj:GetDescendants()) do
            if inst:IsA("Tool") then
                local t = inst:Clone()
                pcall(function() t.Parent = backpack end)
                table.insert(added, t)
            end
        end
    end

    if #added == 0 then
        ShowNotification("No tools found in provided asset")
        return
    end

    for _,v in ipairs(added) do table.insert(clientEquipped, v) end
    refreshEquippedUI()
    ShowNotification("Added gear to inventory (client-sided)")
end

local function removeAllGears()
    for _,v in ipairs(clientEquipped) do
        if v and v.Parent then
            pcall(function() v:Destroy() end)
        end
    end
    clientEquipped = {}
    refreshEquippedUI()
    ShowNotification("Removed client-added gears")
end

QuickBtn(PageRods, "Add Gear", 70, function()
    addGearById(GearInput.Text)
end)
QuickBtn(PageRods, "Remove Gears", 120, removeAllGears)

refreshEquippedUI()


-- Fly (error-safe)
local function ToggleFly()
    if not isVerified or not ScreenGui.Parent then return end
    local char=Player.Character
    if not char then return end
    local root=char:FindFirstChild("HumanoidRootPart")
    local hum=char:FindFirstChildOfClass("Humanoid")
    if flying then
        flying=false
        ShowNotification("Fly Disabled (F)")
        return
    end
    if root and hum then
        flying=true
        ShowNotification("Fly Enabled (F)")
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

QuickBtn(PageMisc,"Toggle Fly (F)",0,ToggleFly)
QuickBtn(PageMisc,"Respawn",50,function()
    if Player.Character and Player.Character:FindFirstChild("Humanoid") then
        Player.Character.Humanoid.Health=0
    end
end)
QuickBtn(PageMisc,"Copy Discord",100,function()
    setclipboard(discordLink)
    ShowNotification("Discord Copied!")
end)

-------------------------------------------------------------------
-- Server hop / Rejoin features
-------------------------------------------------------------------
local PLACE_ID = 16732694052

local function fetchServers()
    local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(PLACE_ID)
    local body
    local ok, res = pcall(function() return game:HttpGet(url) end)
    if ok and res then body = res end
    if not body then
        ok, res = pcall(function()
            if syn and syn.request then return syn.request({Url = url, Method = 'GET'}).Body end
            if http and http.request then return http.request({Url = url, Method = 'GET'}).Body end
            return nil
        end)
        if ok then body = res end
    end
    if not body then return nil end
    local decoded = nil
    pcall(function() decoded = HttpService:JSONDecode(body) end)
    if not decoded then return nil end
    return decoded.data
end

local function ServerHop()
    if not isVerified or not ScreenGui.Parent then return end
    local servers = fetchServers()
    if not servers then ShowNotification("Failed to fetch servers") return end
    local current = tostring(game.JobId)
    local target = nil
    for _,s in ipairs(servers) do
        if s.id and tostring(s.id) ~= current and s.playing and s.maxPlayers and s.playing < s.maxPlayers then
            target = s.id
            break
        end
    end
    if target then
        ShowNotification("Hopping to another server...")
        TeleportService:TeleportToPlaceInstance(PLACE_ID, target, Player)
    else
        ShowNotification("No suitable server found.")
    end
end

local function RejoinServer()
    if not isVerified or not ScreenGui.Parent then return end
    ShowNotification("Rejoining current server...")
    TeleportService:TeleportToPlaceInstance(PLACE_ID, game.JobId, Player)
end

QuickBtn(PageMisc,"Server Hop",150,ServerHop)
QuickBtn(PageMisc,"Rejoin Server",200,RejoinServer)

-------------------------------------------------------------------
-- Player TP
-------------------------------------------------------------------
local ScrollFrame = Instance.new("ScrollingFrame",PagePlayerTP)
ScrollFrame.Size = UDim2.new(1,0,1,0)
ScrollFrame.CanvasSize = UDim2.new(0,0,0,0)
ScrollFrame.ScrollBarThickness=6
local UIListLayout = Instance.new("UIListLayout",ScrollFrame)
UIListLayout.SortOrder=Enum.SortOrder.LayoutOrder
UIListLayout.Padding=UDim.new(0,5)

local function RefreshPlayerTP()
    if not ScrollFrame or not ScrollFrame.Parent then return end
    for _,v in pairs(ScrollFrame:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
    local yPos=0
    for _,plr in pairs(Players:GetPlayers()) do
        if plr ~= Player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local btn = Instance.new("TextButton",ScrollFrame)
            btn.Size = UDim2.new(1,-10,0,35)
            btn.Position = UDim2.new(0,5,0,yPos)
            btn.Text = plr.Name
            btn.TextColor3 = Color3.fromRGB(255,255,255)
            btn.BackgroundColor3 = BTN_GREY
            btn.TextScaled = true
            Instance.new("UICorner",btn)
            btn.MouseButton1Click:Connect(function()
                if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                    Player.Character.HumanoidRootPart.CFrame=plr.Character.HumanoidRootPart.CFrame + Vector3.new(0,3,0)
                    ShowNotification("Teleported to "..plr.Name)
                end
            end)
            yPos = yPos + 40
        end
    end
    ScrollFrame.CanvasSize = UDim2.new(0,0,0,yPos)
end

Players.PlayerAdded:Connect(RefreshPlayerTP)
Players.PlayerRemoving:Connect(RefreshPlayerTP)
RefreshPlayerTP()

-------------------------------------------------------------------
-- 5. STARTUP & KEY SYSTEM
-------------------------------------------------------------------
local KeyFrame = Instance.new("Frame",ScreenGui)
KeyFrame.Size=UDim2.new(0,300,0,160)
KeyFrame.Position=UDim2.new(0.5,-150,0.5,-80)
KeyFrame.BackgroundColor3=BG_COLOR
KeyFrame.Visible=false
Instance.new("UICorner",KeyFrame)

local KeyInput = Instance.new("TextBox",KeyFrame)
KeyInput.Size=UDim2.new(0.8,0,0,35)
KeyInput.Position=UDim2.new(0.1,0,0.35,0)
KeyInput.BackgroundColor3=Color3.fromRGB(45,45,45)
KeyInput.PlaceholderText="Key..."
KeyInput.Text=""
KeyInput.TextColor3=Color3.fromRGB(255,255,255)
KeyInput.TextScaled=true
Instance.new("UICorner",KeyInput)

local KeyBtn = Instance.new("TextButton",KeyFrame)
KeyBtn.Size=UDim2.new(0.8,0,0,40)
KeyBtn.Position=UDim2.new(0.1,0,0.65,0)
KeyBtn.BackgroundColor3=ACCENT
KeyBtn.Text="Verify"
KeyBtn.TextColor3=Color3.fromRGB(255,255,255)
KeyBtn.TextScaled=true
Instance.new("UICorner",KeyBtn)

local function UnlockHub()
    local LIcon = Instance.new("ImageLabel",ScreenGui)
    LIcon.Size=UDim2.new(0,80,0,80)
    LIcon.Position=UDim2.new(0.5,-40,0.5,-40)
    LIcon.Image="rbxassetid://6031097225"
    LIcon.ImageColor3=ACCENT
    LIcon.BackgroundTransparency=1
    TweenService:Create(LIcon,TweenInfo.new(1,Enum.EasingStyle.Linear,Enum.EasingDirection.InOut,-1),{Rotation=360}):Play()
    task.wait(2)
    LIcon:Destroy()
    isVerified=true
    MainMenu.Visible=true
    PageTp.Visible=true
    PageTp.GroupTransparency=0
    ShowNotification("Press [K] to Toggle Menu")
end

if USE_WHITELIST and Player.UserId==WHITELIST_ID then
    UnlockHub()
else
    KeyFrame.Visible=true
end

KeyBtn.MouseButton1Click:Connect(function()
    if KeyInput.Text==CORRECT_KEY then
        KeyFrame:Destroy()
        UnlockHub()
    else
        KeyBtn.BackgroundColor3=Color3.fromRGB(180,50,50)
        KeyBtn.Text="Invalid!"
        task.wait(1)
        KeyBtn.BackgroundColor3=ACCENT
        KeyBtn.Text="Verify"
    end
end)

local MainInput=UserInputService.InputBegan:Connect(function(i,g)
    if g or not isVerified or not ScreenGui.Parent then return end
    if i.KeyCode==Enum.KeyCode.K then MainMenu.Visible = not MainMenu.Visible end
    if i.KeyCode==Enum.KeyCode.F then ToggleFly() end
end)
table.insert(Connections,MainInput)
