--========================================================--
-- HugoScripts | Ultimate UGC Beginner Hub                 --
-- Built natively for PlaceId: 90625015569871              --
-- Using Native Remotes & Game Files                       --
--========================================================--

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remote")

--=================== UI VARIABLES =======================--
local HugoHub = Instance.new("ScreenGui")
HugoHub.Name = "HugoScripts_UGC_V2"
HugoHub.ResetOnSpawn = false

local success, err = pcall(function() HugoHub.Parent = CoreGui end)
if not success then HugoHub.Parent = player:WaitForChild("PlayerGui") end

-- Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 600, 0, 400)
MainFrame.Position = UDim2.new(0.5, -300, 0.5, -200)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = HugoHub
MainFrame.Active = true
MainFrame.Draggable = true

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = MainFrame

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(45, 45, 55)
UIStroke.Thickness = 2
UIStroke.Parent = MainFrame

-- Sidebar
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 150, 1, 0)
Sidebar.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainFrame

local SidebarCorner = Instance.new("UICorner")
SidebarCorner.CornerRadius = UDim.new(0, 10)
SidebarCorner.Parent = Sidebar

local SidebarLayout = Instance.new("UIListLayout")
SidebarLayout.Padding = UDim.new(0, 5)
SidebarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
SidebarLayout.Parent = Sidebar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 50)
Title.BackgroundTransparency = 1
Title.Text = "HugoScripts"
Title.TextColor3 = Color3.fromRGB(255, 60, 60)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 20
Title.Parent = Sidebar

-- Content Container
local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -160, 1, -20)
Content.Position = UDim2.new(0, 155, 0, 10)
Content.BackgroundTransparency = 1
Content.Parent = MainFrame

local Tabs = {}
local function cTab(name, isDefault)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.9, 0, 0, 35)
    btn.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(180, 180, 180)
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 14
    btn.Parent = Sidebar

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = btn

    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 2
    page.Visible = false
    page.Parent = Content

    local pl = Instance.new("UIListLayout")
    pl.Padding = UDim.new(0, 10)
    pl.HorizontalAlignment = Enum.HorizontalAlignment.Center
    pl.Parent = page

    Tabs[name] = {Btn = btn, Page = page}

    btn.MouseButton1Click:Connect(function()
        for i, t in pairs(Tabs) do
            t.Page.Visible = false
            t.Btn.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
            t.Btn.TextColor3 = Color3.fromRGB(180, 180, 180)
        end
        page.Visible = true
        btn.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    end)

    if isDefault then
        page.Visible = true
        btn.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    end
    return page
end

local function cOpt(page, text, callback, isToggle)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.95, 0, 0, 40)
    btn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    btn.Text = "  " .. text
    btn.TextColor3 = Color3.fromRGB(220, 220, 220)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 14
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Parent = page

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = btn

    local active = false
    btn.MouseButton1Click:Connect(function()
        if isToggle then
            active = not active
            btn.BackgroundColor3 = active and Color3.fromRGB(255, 60, 60) or Color3.fromRGB(25, 25, 30)
            btn.TextColor3 = active and Color3.fromRGB(255,255,255) or Color3.fromRGB(220, 220, 220)
            callback(active)
        else
            callback()
        end
    end)
end

--=================== TABS =======================--
local MainTab = cTab("Automation ⚡", true)
local CombatTab = cTab("Combat ⚔️", false)
local VisualTab = cTab("World 👁️", false)
local MiscTab   = cTab("Misc ⚙️", false)

--=================== STATE =======================--
local s = {
    AutoQuest = false,
    AutoGacha = false,
    AutoReward = false,
    WalkSpeed = 16,
    JumpPower = 50,
    InfJump = true, -- Always on per user preference
    Noclip = false,
    AntiAFK = true,
    AntiRagdoll = true, -- Always on
}

--=================== AUTOMATION ===================--
cOpt(MainTab, "Auto Claim Quests", function(v) s.AutoQuest = v end, true)
cOpt(MainTab, "Auto Claim Online Rewards", function(v) s.AutoReward = v end, true)
cOpt(MainTab, "Fast Auto Gacha", function(v) s.AutoGacha = v end, true)

-- Native Remote Exploits
task.spawn(function()
    while task.wait(1) do
        if s.AutoQuest then
            pcall(function() remotes.QuestService.ClaimReward:InvokeServer(1) end) -- Claim first available
        end
        if s.AutoReward then
            pcall(function() remotes.Rewards.OnlineRewardClaim:InvokeServer() end)
        end
        if s.AutoGacha then
            pcall(function() remotes.GachaService.Gacha:InvokeServer(1) end) -- Single pull
        end
        if s.AntiAFK then
            pcall(function() remotes.Any.AFK:FireServer(false) end)
        end
    end
end)

--=================== COMBAT =====================--
cOpt(CombatTab, "Insta Respawn", function()
    remotes.GameService.Respawn:FireServer()
end, false)

cOpt(CombatTab, "Accept Team Invites", function(v)
    s.AutoTeam = v
end, true)

-- Team hook
remotes.TeamService.InviteNotify.OnClientEvent:Connect(function(from)
    if s.AutoTeam then
        remotes.TeamService.Accept:InvokeServer(from)
    end
end)

--=================== WORLD ======================--
cOpt(VisualTab, "Fullbright", function(v)
    s.Fullbright = v
    if not v then
        Lighting.Ambient = Color3.fromRGB(127, 127, 127)
    end
end, true)

cOpt(VisualTab, "No Shadows", function(v)
    Lighting.GlobalShadows = not v
end, true)

--=================== MISC =======================--
cOpt(MiscTab, "Noclip", function(v) s.Noclip = v end, true)
cOpt(MiscTab, "Rejoin Server", function()
    game:GetService("TeleportService"):Teleport(game.PlaceId, player)
end, false)

cOpt(MiscTab, "Destroy Menu", function() HugoHub:Destroy() end, false)

--=================== ENGINE / PERMANENT =================--
-- Infinite Jump (BodyVelocity)
UserInputService.JumpRequest:Connect(function()
    if s.InfJump and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        local bv = Instance.new("BodyVelocity")
        bv.Velocity = Vector3.new(0, 55, 0)
        bv.MaxForce = Vector3.new(0, 99999, 0)
        bv.Parent = player.Character.HumanoidRootPart
        task.wait(0.1)
        bv:Destroy()
    end
end)

-- Main Loop
RunService.Heartbeat:Connect(function()
    local char = player.Character
    if char then
        -- Anti-Ragdoll
        local r = char:FindFirstChild("RagdollClient")
        if r then r.Disabled = true end

        -- Noclip
        if s.Noclip then
            for _, v in ipairs(char:GetDescendants()) do
                if v:IsA("BasePart") then v.CanCollide = false end
            end
        end

        -- Fullbright
        if s.Fullbright then
            Lighting.Ambient = Color3.new(1, 1, 1)
        end
    end
end)

print("[HugoScripts] Full Hub V2 Loaded (Native Remotes)")
