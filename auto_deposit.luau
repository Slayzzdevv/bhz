    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local TweenService = game:GetService("TweenService")
    local LocalPlayer = Players.LocalPlayer

    local Net = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Net")
    local GrabRemote = Net:WaitForChild("RE/StealService/Grab")
    local Synchronizer = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Synchronizer"))
    local SharedAnimals = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Animals"))
    local Plots = workspace:WaitForChild("Plots")

    -- Settings Persistence
local SETTINGS_FILE = "eleven_hop_settings.json"
local settings = {
    autoDeposit = true,
    autoSteal = false,
    autoHop = false,
    hopThreshold = 5 -- Millions/s
}

local function saveSettings()
    pcall(function() writefile(SETTINGS_FILE, game:GetService("HttpService"):JSONEncode(settings)) end)
end

local function loadSettings()
    if isfile(SETTINGS_FILE) then
        local s, res = pcall(function() return game:GetService("HttpService"):JSONDecode(readfile(SETTINGS_FILE)) end)
        if s and type(res) == "table" then
            for k, v in pairs(res) do settings[k] = v end
        end
    end
end

loadSettings()

    -- Global Cleanup
    if _G.ElevenCleanup then pcall(_G.ElevenCleanup) end
    local connections = {}
    local active = true
    _G.ElevenCleanup = function()
        active = false
        for _, c in ipairs(connections) do if c.Disconnect then pcall(function() c:Disconnect() end) end end
        local old = LocalPlayer.PlayerGui:FindFirstChild("ElevenHub")
        if old then old:Destroy() end
    end

    -- Find My Plot
    local function getMyPlot()
        for _, plot in ipairs(Plots:GetChildren()) do
            local channel = Synchronizer:Get(plot.Name)
            if channel and channel:Get("Owner") == LocalPlayer then return plot end
        end
        return nil
    end

    local myPlot = getMyPlot()
    while active and not myPlot do task.wait(1) myPlot = getMyPlot() end
    local deliveryHitbox = myPlot and myPlot:WaitForChild("DeliveryHitbox")

    -- States (Synced with settings)
local autoDeposit = settings.autoDeposit
local autoSteal = settings.autoSteal
local autoHop = settings.autoHop
local hopThreshold = settings.hopThreshold
local manualNoclip = false
local tempNoclip = false
local lastTarget = nil

-- Server Hop Function
local function serverHop()
    local HttpService = game:GetService("HttpService")
    local TeleportService = game:GetService("TeleportService")
    local PlaceId = game.PlaceId
    
    local servers = {}
    local url = "https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
    local response = game:HttpGet(url)
    local data = HttpService:JSONDecode(response)
    
    for _, server in ipairs(data.data) do
        if server.playing < server.maxPlayers and server.id ~= game.JobId then
            table.insert(servers, server.id)
        end
    end
    
    if #servers > 0 then
        TeleportService:TeleportToPlaceInstance(PlaceId, servers[math.random(1, #servers)], LocalPlayer)
    end
end

-- Find Best Gen on Server
local function getBestGenOnServer()
    local bestVal, bestObj, bestPlot = -1, nil, nil
    for _, plot in ipairs(Plots:GetChildren()) do
        local channel = Synchronizer:Get(plot.Name)
        if channel and channel:Get("Owner") ~= LocalPlayer then
            for _, child in ipairs(plot:GetChildren()) do
                if child:IsA("Model") and child.PrimaryPart then
                    local s, g = pcall(function() return SharedAnimals:GetGeneration(child.Name, child:GetAttribute("Mutation"), (child:GetAttribute("Traits") or ""):split(",")) end)
                    if s and g > bestVal then
                        bestVal, bestObj, bestPlot = g, child, plot
                    end
                end
            end
        end
    end
    return bestVal, bestObj, bestPlot
end

    -- UI Implementation
    local sg = Instance.new("ScreenGui")
    sg.Name = "ElevenHub"
    sg.ResetOnSpawn = false
    sg.Parent = LocalPlayer:WaitForChild("PlayerGui")

    local main = Instance.new("Frame")
    main.Name = "MainFrame"
    main.Size = UDim2.new(0, 210, 0, 340) -- Increased height
    main.Position = UDim2.new(0.5, -105, 0.5, -170)
    main.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
    main.BackgroundTransparency = 0.1
    main.BorderSizePixel = 0
    main.Parent = sg
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)
    local stroke = Instance.new("UIStroke", main)
    stroke.Color = Color3.fromRGB(255, 0, 120)
    stroke.Thickness = 2.5

    local title = Instance.new("TextLabel")
    title.Text = "ELEVEN HUB"
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundTransparency = 1
    title.TextColor3 = Color3.new(1, 1, 1)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.Parent = main

    local function createBtn(text, startState, pos, color, isToggle, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.9, 0, 0, 30)
        btn.Position = pos
        btn.BackgroundColor3 = color
        btn.Text = isToggle and (text .. ": " .. (startState and "ON" or "OFF")) or text
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.Font = Enum.Font.GothamMedium
        btn.TextSize = 11
        btn.Parent = main
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
        
        if isToggle then
            local state = startState
            btn.MouseButton1Click:Connect(function()
                state = not state
                btn.Text = text .. ": " .. (state and "ON" or "OFF")
                btn.BackgroundColor3 = state and Color3.fromRGB(0, 150, 80) or Color3.fromRGB(40, 40, 50)
                callback(state)
            end)
        else
            btn.MouseButton1Click:Connect(callback)
        end
        return btn
    end

createBtn("INSTA TP", autoDeposit, UDim2.new(0.05, 0, 0.14, 0), autoDeposit and Color3.fromRGB(0, 150, 80) or Color3.fromRGB(40, 40, 50), true, function(s) settings.autoDeposit = s autoDeposit = s saveSettings() end)
createBtn("INSTANT STEAL", autoSteal, UDim2.new(0.05, 0, 0.24, 0), autoSteal and Color3.fromRGB(0, 150, 80) or Color3.fromRGB(40, 40, 50), true, function(s) settings.autoSteal = s autoSteal = s saveSettings() end)
createBtn("AUTO SERVER HOP", autoHop, UDim2.new(0.05, 0, 0.34, 0), autoHop and Color3.fromRGB(0, 150, 80) or Color3.fromRGB(40, 40, 50), true, function(s) settings.autoHop = s autoHop = s saveSettings() end)

-- Threshold Input
local thresholdBox = Instance.new("TextBox")
thresholdBox.Size = UDim2.new(0.9, 0, 0, 30)
thresholdBox.Position = UDim2.new(0.05, 0, 0.44, 0)
thresholdBox.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
thresholdBox.Text = "SEUIL: " .. hopThreshold .. "M"
thresholdBox.PlaceholderText = "Threshold (e.g. 10)"
thresholdBox.TextColor3 = Color3.new(1, 1, 1)
thresholdBox.Font = Enum.Font.GothamMedium
thresholdBox.TextSize = 11
thresholdBox.Parent = main
Instance.new("UICorner", thresholdBox).CornerRadius = UDim.new(0, 6)

thresholdBox.FocusLost:Connect(function(enter)
    local val = tonumber(thresholdBox.Text:match("%d+%.?%d*"))
    if val then
        hopThreshold = val
        settings.hopThreshold = val
        thresholdBox.Text = "SEUIL: " .. val .. "M"
        saveSettings()
    else
        thresholdBox.Text = "SEUIL: " .. hopThreshold .. "M"
    end
end)

createBtn("NOCLIP", false, UDim2.new(0.05, 0, 0.54, 0), Color3.fromRGB(40, 40, 50), true, function(s) manualNoclip = s end)
createBtn("TP NEXT BEST", false, UDim2.new(0.05, 0, 0.64, 0), Color3.fromRGB(120, 0, 180), false, function()
    local _, bestObj = getBestGenOnServer()
    if bestObj then
        lastTarget = bestObj
        tempNoclip = true
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.CFrame = bestObj.PrimaryPart.CFrame + Vector3.new(0, 3, 0) end
        task.delay(1.5, function() if active then tempNoclip = false end end)
    end
end)

    local cr = Instance.new("TextLabel", main)
    cr.Size = UDim2.new(1, 0, 0, 50)
    cr.Position = UDim2.new(0, 0, 1, -50)
    cr.BackgroundTransparency = 1
    cr.Text = "slayzdevv (Owner)\nBexta dev | Hugo dev"
    cr.TextColor3 = Color3.fromRGB(150, 150, 150)
    cr.TextSize = 10

    -- Mobile Draggable logic
    local dragging, dragStart, startPos
    main.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging, dragStart, startPos = true, input.Position, main.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function() dragging = false end)

    -- Core Logic
    table.insert(connections, RunService.Stepped:Connect(function()
        if not active then return end
        if manualNoclip or tempNoclip then
            local char = LocalPlayer.Character
            if char then for _, part in ipairs(char:GetDescendants()) do if part:IsA("BasePart") then part.CanCollide = false end end end
        end
    end))

    -- Instant Steal Loop (Heartbeat)
    table.insert(connections, RunService.Heartbeat:Connect(function()
        if not active then return end
        if autoSteal and not LocalPlayer:GetAttribute("Stealing") then
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                for _, plot in ipairs(Plots:GetChildren()) do
                    local channel = Synchronizer:Get(plot.Name)
                    if channel and channel:Get("Owner") ~= LocalPlayer then
                        local podiums = plot:FindFirstChild("AnimalPodiums")
                        if podiums then
                            for _, podium in ipairs(podiums:GetChildren()) do
                                local vpos = podium:FindFirstChild("Base") and podium.Base.Spawn.Position or (podium.PrimaryPart and podium.PrimaryPart.Position or podium.WorldPosition)
                                if (hrp.Position - vpos).Magnitude < 15 then
                                    for _, child in ipairs(podium:GetChildren()) do
                                        if child:IsA("Model") and child.PrimaryPart then GrabRemote:FireServer(child) end
                                    end
                                    local prompt = podium:FindFirstChildWhichIsA("ProximityPrompt", true)
                                    if prompt and prompt.Enabled then fireproximityprompt(prompt) end
                                end
                            end
                        end
                    end
                end
            end
        end
    end))

    -- Auto Deposit Logic
    local isProcessing = false
    table.insert(connections, LocalPlayer:GetAttributeChangedSignal("Stealing"):Connect(function()
        if not autoDeposit or not active then return end
        if LocalPlayer:GetAttribute("Stealing") then
            if isProcessing or not deliveryHitbox then return end
            isProcessing = true
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                tempNoclip = true
                task.wait(0.1)
                hrp.CFrame = deliveryHitbox.CFrame + Vector3.new(0, 3, 0)
                task.delay(1.5, function() if active then tempNoclip = false end end)
            end
        else
            isProcessing = false
            tempNoclip = false
        end
    end))

-- Server Hop & Auto Farmer Loop
task.spawn(function()
    while active and task.wait(3) do
        if autoHop then
            local bestVal, bestObj, _ = getBestGenOnServer()
            if bestVal < (hopThreshold * 1000000) then
                print("[Eleven Hub] No good brainrots found (" .. bestVal .. " < " .. hopThreshold .. "M). Hopping...")
                serverHop()
                task.wait(10) -- Prevent double hop
            else
                -- If we are not stealing and not near the best, TP to it
                if not LocalPlayer:GetAttribute("Stealing") then
                    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if hrp and bestObj and bestObj.PrimaryPart and (hrp.Position - bestObj.PrimaryPart.Position).Magnitude > 20 then
                        print("[Eleven Hub] Found high-value brainrot (" .. bestVal .. "). Teleporting...")
                        tempNoclip = true
                        hrp.CFrame = bestObj.PrimaryPart.CFrame + Vector3.new(0, 3, 0)
                        task.delay(1.5, function() tempNoclip = false end)
                    end
                end
            end
        end
    end
end)

    -- Anti-Stuck Loop
    task.spawn(function()
        while active and task.wait(1.5) do
            if autoDeposit and LocalPlayer:GetAttribute("Stealing") and deliveryHitbox then
                local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp and (hrp.Position - deliveryHitbox.Position).Magnitude > 15 then 
                    tempNoclip = true
                    hrp.CFrame = deliveryHitbox.CFrame + Vector3.new(0, 3, 0)
                    task.delay(1.5, function() if active then tempNoclip = false end end)
                end
            end
        end
    end)

    print("[Eleven Hub] Injected. Settings loaded.")
