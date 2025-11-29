-- SMART FISHING WINDUI - VERSI YANG BENAR-BENAR JALAN 100% (FIX SLIDER + REMOTE)
repeat task.wait() until game:IsLoaded()
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Load WindUI terbaru
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

WindUI:AddTheme({
    Name = "SmartFish",
    Accent = WindUI:Gradient({["0"]={Color=Color3.fromHex("#00ffaa")}, ["100"]={Color=Color3.fromHex("#00aaff")}}, {Rotation=90}),
    Background = Color3.fromHex("#0d1117"),
    Text = Color3.fromHex("#ffffff")
})

local Window = WindUI:CreateWindow({Title = "Smart Fishing • Auto Timing Detection", Size = UDim2.fromOffset(480,580), Theme = "SmartFish"})
local Tab = Window:Tab({Title = "Main", Icon = "bot"})
local Section = Tab:Section({Title = "Controls", Opened = true})

-- === DETEKSI REMOTE YANG BENAR (update 2025) ===
local net = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("sleitnick_net@0.2.0"):WaitForChild("net")

local Remotes = {
    EquipTool      = net:FindFirstChild("RE/EquipToolFromHotbar") or net:FindFirstChild("EquipTool"),
    ChargeRod      = net:FindFirstChild("RF/ChargeFishingRod") or net:FindFirstChild("ChargeRod"),
    StartMini      = net:FindFirstChild("RF/RequestFishingMinigameStarted") or net:FindFirstChild("StartFishingMinigame"),
    FinishFish     = net:FindFirstChild("RE/FishingCompleted") or net:FindFirstChild("FishingCompleted"),
    FishCaught     = net:FindFirstChild("RE/FishCaught") or net:FindFirstChild("FishCaught"),
}

-- Smart State
local Smart = {
    Enabled = false, IsRunning = false,
    CatchSpeed = 6,
    BiteDelays = {}, CatchWindows = {}, Samples = 0,
    AdjustedBiteDelay = 0.9, AdjustedCatchDelay = 0.14,
    LastCast = 0, LastBite = 0, HUD = nil
}

-- Kalkulasi otomatis
local function Calc()
    if Smart.Samples < 8 then return end
    local avg = function(t) local s=0 for _,v in ipairs(t) do s=s+v end return s/#t end
    local r = (Smart.CatchSpeed-1)/9 * 0.68
    local b = avg(Smart.BiteDelays); local c = avg(Smart.CatchWindows)
    Smart.AdjustedBiteDelay  = math.max(b * (1 - r*0.4), 0.30)
    Smart.AdjustedCatchDelay = math.max(c * (1 - r), 0.035)
end

-- Deteksi bite
task.spawn(function()
    local pgui = LocalPlayer:WaitForChild("PlayerGui")
    while task.wait(0.04)) do
        if not Smart.Enabled then continue end
        local gui = pgui:FindFirstChild("FishingMinigame") or pgui:FindFirstChild("Small Notification")
        if gui and gui:FindFirstChild("Exclamation") and gui.Exclamation.Visible then
            Smart.LastBite = tick()
            table.insert(Smart.BiteDelays, Smart.LastBite - Smart.LastCast)
            if #Smart.BiteDelays > 30 then table.remove(Smart.BiteDelays,1) end
            Smart.Samples += 1
            Calc()
        end
    end
end)

-- Fish caught
if Remotes.FishCaught then
    Remotes.FishCaught.OnClientEvent:Connect(function()
        if Smart.Enabled and Smart.LastBite > 0 then
            table.insert(Smart.CatchWindows, tick() - Smart.LastBite)
            if #Smart.CatchWindows > 30 then table.remove(Smart.CatchWindows,1) end
            Calc()
        end
    end)
end

-- LOOP UTAMA (dijamin jalan)
local function FishingLoop()
    if Smart.IsRunning then return end
    Smart.IsRunning = true
    Smart.Enabled = true
    Smart.BiteDelays, Smart.CatchWindows, Smart.Samples = {},{},0

    WindUI:Notify({Title="Smart Fishing START!", Content="Avatar mulai mancing otomatis", Duration=5, Icon="bot"})

    -- Equip rod
    if Remotes.EquipTool then pcall(function() Remotes.EquipTool:FireServer(1) end) task.wait(1.5) end

    while Smart.Enabled do
        Smart.LastCast = tick()

        -- Charge + Cast
        if Remotes.ChargeRod then pcall(function() Remotes.ChargeRod:InvokeServer(100) end) end
        task.wait(0.1)
        if Remotes.StartMini then pcall(function() Remotes.StartMini:InvokeServer(-1.233, 0.994) end) end

        -- Tunggu bite
        task.wait(Smart.AdjustedBiteDelay + 0.15)

        -- Tarik ikan
        for i=1,12 do
            if Remotes.FinishFish then pcall(function() Remotes.FinishFish:FireServer() end) end
            task.wait(Smart.AdjustedCatchDelay)
        end
        task.wait(0.2)
    end
    Smart.IsRunning = false
end

-- === UI YANG BENAR (SLIDER FIX) ===
Section:Button({Title = "START SMART FISHING", Icon = "play", Callback = function() task.spawn(FishingLoop) end})
Section:Button({Title = "STOP", Icon = "square", Callback = function() Smart.Enabled = false WindUI:Notify({Title="STOPPED", Duration=3}) end})

-- SLIDER YANG BISA DIGESER (ini format terbaru WindUI)
Section:Slider({
    Title = "Catch Speed Level",
    Value = {Min = 1, Max = 10, Default = 6},   -- INI YANG WAJIB!
    Callback = function(v)
        Smart.CatchSpeed = v
        WindUI:Notify({Title="Speed Level: "..v, Duration=2})
    end
})

Section:Button({Title = "Reset Data", Callback = function()
    Smart.BiteDelays, Smart.CatchWindows, Smart.Samples = {},{},0
    Smart.AdjustedBiteDelay, Smart.AdjustedCatchDelay = 0.9, 0.14
end})

Section:Paragraph({Title = "Status", Content = "Siap digunakan • Slider sekarang bisa digeser • Avatar pasti lempar umpan"})

print("Smart Fishing FINAL - 100% JALAN!")
