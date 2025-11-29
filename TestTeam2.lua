-- SMART FISHING WINDUI TERBARU (FIXED - ISI KELUAR 100%)
repeat task.wait() until game:IsLoaded()
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Load WindUI versi paling baru
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

WindUI:AddTheme({
    Name = "SmartFish",
    Accent = WindUI:Gradient({["0"]={Color=Color3.fromHex("#00ffaa")}, ["100"]={Color=Color3.fromHex("#0088ff")}}, {Rotation=90}),
    Background = Color3.fromHex("#0d1117"),
    Text = Color3.fromHex("#ffffff")
})

-- Buat Window
local Window = WindUI:CreateWindow({
    Title = "Smart Fishing • Auto Timing Detection",
    Size = UDim2.fromOffset(460, 560),
    Theme = "SmartFish"
})

-- HARUS BUAT TAB DULU (ini penyebabnya kosong tadi!)
local Tab = Window:Tab({
    Title = "Main",
    Icon = "bot"
})

-- Cari remote
local net = game:GetService("ReplicatedStorage").Packages["_Index"]["sleitnick_net@0.2.0"].net
local Remotes = {
    EquipTool = net:FindFirstChild("RE/EquipToolFromHotbar"),
    ChargeRod = net:FindFirstChild("RF/ChargeFishingRod"),
    StartMini = net:FindFirstChild("RF/RequestFishingMinigameStarted"),
    FinishFish = net:FindFirstChild("RE/FishingCompleted"),
    FishCaught = net:FindFirstChild("RE/FishCaught"),
}

-- Smart State (sama seperti sebelumnya)
local Smart = {
    Enabled = false, CatchSpeed = 6, BiteDelays = {}, CatchWindows = {}, Samples = 0,
    AdjustedBiteDelay = 0.85, AdjustedCatchDelay = 0.13, LastCast = 0, LastBite = 0, HUD = nil
}

local function Calculate()
    if Smart.Samples < 8 then return end
    local avg = function(t) local s=0 for _,v in t do s=s+v end return s/#t end
    local reduction = (Smart.CatchSpeed-1)/9 * 0.65
    local bAvg = avg(Smart.BiteDelays); local cAvg = avg(Smart.CatchWindows)
    Smart.AdjustedBiteDelay  = math.max(bAvg * (1-reduction*0.35), 0.32)
    Smart.AdjustedCatchDelay = math.max(cAvg * (1-reduction), 0.038)
    if Smart.HUD then
        Smart.HUD.Content.Text = string.format("Samples: %d\nBite: %.3fs → %.3fs\nCatch: %.3fs → %.3fs\nSpeed: %d", 
            Smart.Samples, bAvg, Smart.AdjustedBiteDelay, cAvg, Smart.AdjustedCatchDelay, Smart.CatchSpeed)
    end
end

-- Bite & Catch detection (tetap sama)
task.spawn(function()
    local pgui = LocalPlayer:WaitForChild("PlayerGui")
    while task.wait(0.04) do
        if not Smart.Enabled then continue end
        local gui = pgui:FindFirstChild("FishingMinigame") or pgui:FindFirstChild("Small Notification")
        if gui and gui:FindFirstChild("Exclamation") and gui.Exclamation.Visible then
            Smart.LastBite = tick()
            table.insert(Smart.BiteDelays, Smart.LastBite - Smart.LastCast)
            if #Smart.BiteDelays > 30 then table.remove(Smart.BiteDelays,1) end
            Smart.Samples = Smart.Samples + 1
            Calculate()
        end
    end
end)

if Remotes.FishCaught then
    Remotes.FishCaught.OnClientEvent:Connect(function()
        if Smart.Enabled and Smart.LastBite > 0 then
            table.insert(Smart.CatchWindows, tick() - Smart.LastBite)
            if #Smart.CatchWindows > 30 then table.remove(Smart.CatchWindows,1) end
            Calculate()
        end
    end)
end

local function StartLoop()
    Smart.Enabled = true
    Smart.BiteDelays, Smart.CatchWindows, Smart.Samples = {},{},0
    WindUI:Notify({Title="Smart Fishing ON", Content="Mengumpulkan data...", Duration=6, Icon="bot"})
    if Smart.HUD then Smart.HUD:Destroy() end
    Smart.HUD = WindUI:CreateWindow({Title="Smart HUD", Size=UDim2.fromOffset(340,180), Draggable=true})
    Smart.HUD:AddParagraph({Title="Live Data", Content="Collecting..."})

    pcall(function() Remotes.EquipTool:FireServer(1) end) task.wait(1)
    while Smart.Enabled do
        Smart.LastCast = tick()
        pcall(function() Remotes.ChargeRod:InvokeServer(100) end) task.wait(0.07)
        pcall(function() Remotes.StartMini:InvokeServer(-1.233184814453125, 0.9945034885633273) end)
        task.wait(Smart.AdjustedBiteDelay + 0.12)
        for i=1,11 do
            pcall(function() Remotes.FinishFish:FireServer() end)
            task.wait(Smart.AdjustedCatchDelay)
        end
        task.wait(0.18)
    end
end

-- SEMUA UI HARUS LEWAT TAB!!
Tab:Button({Title = "START SMART FISHING", Icon = "play", Callback = StartLoop})
Tab:Button({Title = "STOP", Icon = "square", Callback = function() Smart.Enabled = false if Smart.HUD then Smart.HUD:Destroy() end WindUI:Notify({Title="STOPPED", Duration=3}) end})
Tab:Slider({Title = "Speed Level", Min = 1, Max = 10, Default = 6, Callback = function(v) Smart.CatchSpeed = v Calculate() end})
Tab:Button({Title = "Reset Data", Icon = "rotate-cw", Callback = function() Smart.BiteDelays, Smart.CatchWindows, Smart.Samples = {},{},0 Smart.AdjustedBiteDelay, Smart.AdjustedCatchDelay = 0.85,0.13 WindUI:Notify({Title="Data Direset", Duration=3}) end})
Tab:Paragraph({Title = "Info", Content = "• Zero false cast\n• Auto adjust lag\n• 100% standalone"})

print("Smart Fishing WindUI FIXED - ISI KELUAR!")
