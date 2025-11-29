-- ================================================
-- SMART FISHING STANDALONE (100% INDEPENDEN)
-- Bisa di-execute sendiri, tidak butuh script lain
-- ================================================

repeat task.wait() until game:IsLoaded()
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

-- Load WindUI (otomatis)
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/download/main/main.lua"))()

WindUI:AddTheme({
    Name = "SmartFish",
    Accent = WindUI:Gradient({["0"] = {Color = Color3.fromHex("#00ffaa")}, ["100"] = {Color = Color3.fromHex("#0088ff")}}, {Rotation = 90}),
    Background = Color3.fromHex("#0a0e17"),
    Text = Color3.fromHex("#ffffff"),
    Dialog = Color3.fromHex("#111827"),
})

local Window = WindUI:CreateWindow({
    Title = "Smart Fishing • Auto Timing Detection",
    Icon = "bot",
    Size = UDim2.fromOffset(420, 520),
    Transparent = true,
    Theme = "SmartFish",
    KeySystem = false,
    HideSearchBar = true,
})

-- Remotes detection (otomatis cari)
local net = ReplicatedStorage:WaitForChild("Packages")
    :WaitForChild("_Index")
    :WaitForChild("sleitnick_net@0.2.0")
    :WaitForChild("net")

local Remotes = {
    EquipTool = net:FindFirstChild("RE/EquipToolFromHotbar"),
    ChargeRod = net:FindFirstChild("RF/ChargeFishingRod"),
    StartMini = net:FindFirstChild("RF/RequestFishingMinigameStarted"),
    FinishFish = net:FindFirstChild("RE/FishingCompleted"),
    FishCaught = net:FindFirstChild("RE/FishCaught"),
}

-- Smart State
local Smart = {
    Enabled = false,
    CatchSpeed = 6,
    BiteDelays = {},
    CatchWindows = {},
    LastCast = 0,
    LastBite = 0,
    Samples = 0,
    MaxSamples = 30,
    AdjustedBiteDelay = 0.85,
    AdjustedCatchDelay = 0.13,
    IsRunning = false,
    HUD = nil,
}

-- Calculation
local function Calculate()
    if Smart.Samples < 8 then return end
    local avg = function(t) local s=0 for _,v in t do s=s+v end return s/#t end
    local std = function(t,m) local s=0 for _,v in t do s=s+(v-m)^2 end return math.sqrt(s/#t) end

    local bAvg = avg(Smart.BiteDelays)
    local cAvg = avg(Smart.CatchWindows)
    local bStd = std(Smart.BiteDelays, bAvg)
    local cStd = std(Smart.CatchWindows, cAvg)

    local reduction = (Smart.CatchSpeed-1)/9 * 0.65
    Smart.AdjustedBiteDelay  = math.max(bAvg * (1 - reduction*0.35) + bStd*0.6, 0.32)
    Smart.AdjustedCatchDelay = math.max(cAvg * (1 - reduction) + cStd*0.7, 0.038)

    if Smart.HUD then
        Smart.HUD.Content.Text = string.format([[
<font color="#00ffaa">Samples:</font> <font color="#ffffff">%d</font>
<font color="#00ffff">Bite Avg:</font> <font color="#ffaa00">%.3fs</font>
<font color="#ff00ff">Catch Avg:</font> <font color="#ffaa00">%.3fs</font>
→ <font color="#ffff00">Bite Delay:</font> %.3fs
→ <font color="#ff6600">Catch Delay:</font> %.3fs
<font color="#ff3366">Speed Level: %d</font>
]], Smart.Samples, bAvg, cAvg, Smart.AdjustedBiteDelay, Smart.AdjustedCatchDelay, Smart.CatchSpeed)
    end
end

-- Bite Detection
local biteDetected = false
task.spawn(function()
    local pgui = LocalPlayer:WaitForChild("PlayerGui")
    while task.wait(0.04) do
        if not Smart.Enabled then biteDetected = false continue end
        local gui = pgui:FindFirstChild("FishingMinigame") or pgui:FindFirstChild("Small Notification")
        if gui and not biteDetected then
            local ind = gui:FindFirstChild("Exclamation") or gui:FindFirstChild("BiteIndicator")
            if ind and (ind.Visible or ind.ImageTransparency < 1) then
                biteDetected = true
                Smart.LastBite = tick()
                table.insert(Smart.BiteDelays, Smart.LastBite - Smart.LastCast)
                if #Smart.BiteDelays > Smart.MaxSamples then table.remove(Smart.BiteDelays,1) end
                Smart.Samples = Smart.Samples + 1
                Calculate()
            end
        end
    end
end)

-- Fish Caught Hook
if Remotes.FishCaught then
    Remotes.FishCaught.OnClientEvent:Connect(function()
        if Smart.Enabled and Smart.LastBite > 0 then
            local win = tick() - Smart.LastBite
            table.insert(Smart.CatchWindows, win)
            if #Smart.CatchWindows > Smart.MaxSamples then table.remove(Smart.CatchWindows,1) end
            Calculate()
        end
        biteDetected = false
    end)
end

-- Main Loop
local function Loop()
    if Smart.IsRunning then return end
    Smart.IsRunning = true
    if Remotes.EquipTool then pcall(function() Remotes.EquipTool:FireServer(1) end) task.wait(1) end

    while Smart.Enabled do
        Smart.LastCast = tick()
        biteDetected = false

        if Remotes.ChargeRod then pcall(function() Remotes.ChargeRod:InvokeServer(100) end) end
        task.wait(0.07)
        if Remotes.StartMini then pcall(function() Remotes.StartMini:InvokeServer(-1.233184814453125, 0.9945034885633273) end) end

        local waited = 0
        while not biteDetected and waited < 5 do
            task.wait(0.03)
            waited = waited + 0.03
            if waited >= Smart.AdjustedBiteDelay then break end
        end

        if biteDetected or waited >= Smart.AdjustedBiteDelay then
            for i=1,10 do
                if Remotes.FinishFish then pcall(function() Remotes.FinishFish:FireServer() end) end
                task.wait(Smart.AdjustedCatchDelay/9)
            end
        end
        task.wait(0.15)
    end
    Smart.IsRunning = false
end

-- UI
Window:AddButton({
    Title = "START SMART FISHING",
    Callback = function()
        Smart.Enabled = true
        Smart.BiteDelays, Smart.CatchWindows, Smart.Samples = {},{},0
        WindUI:Notify({Title="Smart Fishing ON", Content="Mengumpulkan data... (8-15 ikan pertama)", Duration=8, Icon="bot"})
        task.spawn(Loop)
        task.wait(0.5)
        if Smart.HUD then Smart.HUD:Destroy() end
        Smart.HUD = WindUI:CreateWindow({Title="Smart Fishing HUD", Size=UDim2.fromOffset(340,200), Draggable=true})
        Smart.HUD:AddParagraph({Title="Live Timing", Content="Collecting data..."})
    end
})

Window:AddButton({
    Title = "STOP SMART FISHING",
    Callback = function()
        Smart.Enabled = false
        if Smart.HUD then Smart.HUD:Destroy() Smart.HUD=nil end
        WindUI:Notify({Title="Smart Fishing OFF", Duration=4})
    end
})

Window:AddSlider({
    Title = "Catch Speed (1-10)",
    Min = 1, Max = 10, Default = 6,
    Callback = function(v)
        Smart.CatchSpeed = v
        Calculate()
    end
})

Window:AddButton({
    Title = "Reset Data",
    Callback = function()
        Smart.BiteDelays, Smart.CatchWindows, Smart.Samples = {},{},0
        Smart.AdjustedBiteDelay, Smart.AdjustedCatchDelay = 0.85, 0.13
        WindUI:Notify({Title="Data Direset", Duration=3})
    end
})

Window:AddParagraph({
    Title = "Info",
    Content = "• Tidak pernah lempar sebelum ikan masuk\n• Otomatis sesuaikan lag server\n• 100% independen"
})

print("Smart Fishing Standalone Loaded!")
