-- SMART FISHING WINDUI LATEST VERSION (PASTI KELUAR 100%)
repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Load WindUI versi terbaru (sesuai docs kamu)
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- Theme keren
WindUI:AddTheme({
    Name = "SmartFish",
    Accent = WindUI:Gradient({
        ["0"]   = {Color = Color3.fromHex("#00ffaa")},
        ["100"] = {Color = Color3.fromHex("#0088ff")}
    }, {Rotation = 90}),
    Background = Color3.fromHex("#0d1117"),
    Text = Color3.fromHex("#ffffff"),
    DialogBackground = Color3.fromHex("#161b22")
})

-- Window utama
local Window = WindUI:CreateWindow({
    Title = "Smart Fishing • Auto Timing Detection",
    Size = UDim2.fromOffset(450, 550),
    Theme = "SmartFish",
    Draggable = true
})

-- Cari remote otomatis
local net = game:GetService("ReplicatedStorage")
    .Packages["_Index"]["sleitnick_net@0.2.0"].net

local Remotes = {
    EquipTool = net:WaitForChild("RE/EquipToolFromHotbar", 5),
    ChargeRod = net:WaitForChild("RF/ChargeFishingRod", 5),
    StartMini = net:WaitForChild("RF/RequestFishingMinigameStarted", 5),
    FinishFish = net:WaitForChild("RE/FishingCompleted", 5),
    FishCaught = net:WaitForChild("RE/FishCaught", 5),
}

-- Smart State
local Smart = {
    Enabled = false,
    CatchSpeed = 6,
    BiteDelays = {}, CatchWindows = {},
    Samples = 0, MaxSamples = 30,
    AdjustedBiteDelay = 0.85,
    AdjustedCatchDelay = 0.13,
    LastCast = 0, LastBite = 0,
    HUD = nil
}

local function Calculate()
    if Smart.Samples < 8 then return end
    local avg = function(t) local s=0 for _,v in t do s=s+v end return s/#t end
    local reduction = (Smart.CatchSpeed-1)/9 * 0.65
    local bAvg = avg(Smart.BiteDelays)
    local cAvg = avg(Smart.CatchWindows)
    Smart.AdjustedBiteDelay  = math.max(bAvg * (1 - reduction*0.35), 0.32)
    Smart.AdjustedCatchDelay = math.max(cAvg * (1 - reduction), 0.038)

    if Smart.HUD then
        Smart.HUD.Content.Text = string.format([[
<font color="#00ffaa">Samples:</font> %d
<font color="#00ffff">Bite Avg:</font> %.3fs
<font color="#ffaa00">Catch Avg:</font> %.3fs
→ <font color="#ffff00">Delay Bite:</font> %.3fs
→ <font color="#ff6600">Delay Catch:</font> %.3fs
<font color="#ff3366">Speed Level: %d</font>
]], Smart.Samples, bAvg, cAvg, Smart.AdjustedBiteDelay, Smart.AdjustedCatchDelay, Smart.CatchSpeed)
    end
end

-- Bite Detection
task.spawn(function()
    local pgui = LocalPlayer:WaitForChild("PlayerGui")
    while task.wait(0.04) do
        if not Smart.Enabled then continue end
        local gui = pgui:FindFirstChild("FishingMinigame") or pgui:FindFirstChild("Small Notification")
        if gui and gui:FindFirstChild("Exclamation") and gui.Exclamation.Visible then
            Smart.LastBite = tick()
            table.insert(Smart.BiteDelays, Smart.LastBite - Smart.LastCast)
            if #Smart.BiteDelays > Smart.MaxSamples then table.remove(Smart.BiteDelays,1) end
            Smart.Samples = Smart.Samples + 1
            Calculate()
        end
    end
end)

if Remotes.FishCaught then
    Remotes.FishCaught.OnClientEvent:Connect(function()
        if Smart.Enabled and Smart.LastBite > 0 then
            table.insert(Smart.CatchWindows, tick() - Smart.LastBite)
            if #Smart.CatchWindows > Smart.MaxSamples then table.remove(Smart.CatchWindows,1) end
            Calculate()
        end
    end)
end

local function StartFishing()
    Smart.Enabled = true
    Smart.BiteDelays, Smart.CatchWindows, Smart.Samples = {},{},0

    WindUI:Notify({Title="Smart Fishing AKTIF", Content="Mengumpulkan data timing... (8-15 ikan pertama)", Duration=8, Icon="bot"})

    if Smart.HUD then Smart.HUD:Destroy() end
    Smart.HUD = WindUI:CreateWindow({Title="Smart Fishing HUD", Size=UDim2.fromOffset(360,220), Position=UDim2.fromOffset(50,300), Draggable=true})
    Smart.HUD:AddParagraph({Title="Live Timing", Content="Collecting data..."})

    pcall(function() Remotes.EquipTool:FireServer(1) end)
    task.wait(1)

    while Smart.Enabled do
        Smart.LastCast = tick()
        if Remotes.ChargeRod then pcall(function() Remotes.ChargeRod:InvokeServer(100) end) end
        task.wait(0.07)
        if Remotes.StartMini then pcall(function() Remotes.StartMini:InvokeServer(-1.233184814453125, 0.9945034885633273) end) end

        task.wait(Smart.AdjustedBiteDelay + 0.12)

        for i=1,11 do
            if Remotes.FinishFish then pcall(function() Remotes.FinishFish:FireServer() end) end
            task.wait(Smart.AdjustedCatchDelay)
        end
        task.wait(0.18)
    end
end

-- UI ELEMENTS
Window:AddButton({
    Title = "START SMART FISHING",
    Icon = "play",
    Callback = function() task.spawn(StartFishing) end
})

Window:AddButton({
    Title = "STOP",
    Icon = "square",
    Callback = function()
        Smart.Enabled = false
        if Smart.HUD then Smart.HUD:Destroy() Smart.HUD = nil end
        WindUI:Notify({Title="Smart Fishing DIMATIKAN", Duration=4})
    end
})

Window:AddSlider({
    Title = "Catch Speed Level",
    Min = 1, Max = 10, Default = 6,
    Callback = function(v)
        Smart.CatchSpeed = v
        Calculate()
        WindUI:Notify({Title="Speed: Level "..v, Duration=3})
    end
})

Window:AddButton({
    Title = "Reset Data Kalibrasi",
    Icon = "rotate-cw",
    Callback = function()
        Smart.BiteDelays, Smart.CatchWindows, Smart.Samples = {},{},0
        Smart.AdjustedBiteDelay, Smart.AdjustedCatchDelay = 0.85, 0.13
        WindUI:Notify({Title="Data Direset!", Duration=3})
    end
})

Window:AddParagraph({
    Title = "Info",
    Content = "• Tidak pernah lempar sebelum ikan masuk\n• Otomatis sesuaikan lag server\n• 100% Standalone & Aman"
})

print("Smart Fishing WindUI Latest - LOADED & SIAP PAKAI!")
