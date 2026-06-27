local success, Rayfield = pcall(function()
    return loadstring(game:HttpGet('https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua'))()
end)
if not success then
    Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/shlexware/Rayfield/main/source.lua'))()
end

if not Rayfield then
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Ошибка";
        Text = "Не удалось загрузить Rayfield";
        Duration = 5
    })
    return
end

local player = game.Players.LocalPlayer
if not player then
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Ошибка";
        Text = "Игрок не загружен, перезапусти скрипт";
        Duration = 5
    })
    return
end

local Window = Rayfield:CreateWindow({
    Name = "BruhScript (beta)",
    Icon = "apple",
    LoadingTitle = "BruhScript",
    LoadingSubtitle = "beta",
    Theme = "DarkBlue",
    DisableRayfieldPrompts = true,
    DisableBuildWarnings = true,
})

local HomeTab = Window:CreateTab("Home", "home")
local VisualTab = Window:CreateTab("Visual", "palette")
local CombatTab = Window:CreateTab("Combat", "crosshair")
local SoonTab = Window:CreateTab("Soon", "clock")
local SettingsTab = Window:CreateTab("Settings", "settings")

local ts = game:GetService("TeleportService")
local http = game:GetService("HttpService")
local placeId = game.PlaceId
local runService = game:GetService("RunService")
local camera = workspace.CurrentCamera
local userInputService = game:GetService("UserInputService")

local function getServers()
    local servers = {}
    local cursor = ""
    repeat
        local url = "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?limit=100&cursor=" .. cursor
        local success, result = pcall(function() return game:HttpGet(url) end)
        if success then
            local data = http:JSONDecode(result)
            for _, server in ipairs(data.data) do
                if server.playing < server.maxPlayers then
                    table.insert(servers, server.id)
                end
            end
            cursor = data.nextPageCursor or ""
        else break end
    until cursor == "" or #servers > 0
    return servers
end

-- Home
HomeTab:CreateSlider({
    Name = "Walk Speed",
    Range = {16, 200},
    Increment = 1,
    CurrentValue = 16,
    Callback = function(v)
        local c = player.Character
        if c and c:FindFirstChild("Humanoid") then c.Humanoid.WalkSpeed = v end
    end,
})

HomeTab:CreateSlider({
    Name = "Jump Power",
    Range = {50, 300},
    Increment = 1,
    CurrentValue = 50,
    Callback = function(v)
        local c = player.Character
        if c and c:FindFirstChild("Humanoid") then c.Humanoid.JumpPower = v end
    end,
})

-- Noclip
local noclipEnabled = false
local noclipConnection = nil

local function enableNoclip()
    if noclipConnection then noclipConnection:Disconnect() end
    noclipConnection = game:GetService("RunService").Stepped:Connect(function()
        if noclipEnabled and player.Character then
            for _, part in pairs(player.Character:GetChildren()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end)
end

local function disableNoclip()
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end
    if player.Character then
        for _, part in pairs(player.Character:GetChildren()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end
end

HomeTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Callback = function(Value)
        noclipEnabled = Value
        if noclipEnabled then
            enableNoclip()
        else
            disableNoclip()
        end
    end,
})

-- ESP
local espEnabled = false
local highlights = {}
local espThread = nil

local function clearESP()
    for _, h in pairs(highlights) do
        pcall(function() h:Destroy() end)
    end
    table.clear(highlights)
end

local function updateESP()
    while espEnabled do
        for _, p in ipairs(game.Players:GetPlayers()) do
            if p ~= player and p.Character and p.Character:FindFirstChild("Head") then
                if not highlights[p] or not highlights[p].Parent then
                    local highlight = Instance.new("Highlight")
                    highlight.Name = "ESP"
                    highlight.FillColor = Color3.fromRGB(255, 0, 0)
                    highlight.FillTransparency = 0.5
                    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                    highlight.OutlineTransparency = 1
                    highlight.Adornee = p.Character
                    highlight.Parent = p.Character
                    highlights[p] = highlight
                end
            else
                if highlights[p] then
                    pcall(function() highlights[p]:Destroy() end)
                    highlights[p] = nil
                end
            end
        end
        task.wait(0.5)
    end
end

VisualTab:CreateToggle({
    Name = "ESP",
    CurrentValue = false,
    Callback = function(Value)
        espEnabled = Value
        if espEnabled then
            espThread = task.spawn(updateESP)
        else
            clearESP()
            if espThread and task.isrunning(espThread) then
                task.cancel(espThread)
                espThread = nil
            end
        end
    end,
})

-- Skeleton ESP
local skeletonEnabled = false
local skeletonDrawings = {}
local skeletonThread = nil

local connections = {
    {"Head", "UpperTorso"},
    {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"},
    {"LeftUpperArm", "LeftLowerArm"},
    {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"},
    {"RightUpperArm", "RightLowerArm"},
    {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"},
    {"LeftUpperLeg", "LeftLowerLeg"},
    {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"},
    {"RightUpperLeg", "RightLowerLeg"},
    {"RightLowerLeg", "RightFoot"},
}

local function clearSkeleton()
    for _, drawings in pairs(skeletonDrawings) do
        for _, d in pairs(drawings) do
            pcall(function() d.Visible = false; d:Remove() end)
        end
    end
    table.clear(skeletonDrawings)
end

local function hideAllSkeletonLines()
    for _, drawings in pairs(skeletonDrawings) do
        for _, d in pairs(drawings) do
            pcall(function() d.Visible = false end)
        end
    end
end

local function updateSkeleton()
    while skeletonEnabled do
        for _, p in ipairs(game.Players:GetPlayers()) do
            if p ~= player and p.Character then
                if not skeletonDrawings[p] then
                    skeletonDrawings[p] = {}
                end
                local char = p.Character
                for _, conn in ipairs(connections) do
                    local partA = char:FindFirstChild(conn[1])
                    local partB = char:FindFirstChild(conn[2])
                    if partA and partB then
                        if not skeletonDrawings[p][conn[1] .. conn[2]] then
                            local line = Drawing.new("Line")
                            line.Color = Color3.fromRGB(255, 255, 255)
                            line.Thickness = 2
                            line.Transparency = 1
                            line.Visible = false
                            skeletonDrawings[p][conn[1] .. conn[2]] = line
                        end
                        local line = skeletonDrawings[p][conn[1] .. conn[2]]
                        local posA, onScreenA = camera:WorldToViewportPoint(partA.Position)
                        local posB, onScreenB = camera:WorldToViewportPoint(partB.Position)
                        if onScreenA and onScreenB then
                            line.From = Vector2.new(posA.X, posA.Y)
                            line.To = Vector2.new(posB.X, posB.Y)
                            line.Visible = true
                        else
                            line.Visible = false
                        end
                    end
                end
            end
        end
        runService.RenderStepped:Wait()
    end
    hideAllSkeletonLines()
end

VisualTab:CreateToggle({
    Name = "Skeleton ESP",
    CurrentValue = false,
    Callback = function(Value)
        skeletonEnabled = Value
        if skeletonEnabled then
            skeletonThread = task.spawn(updateSkeleton)
        else
            if skeletonThread and task.isrunning(skeletonThread) then
                task.cancel(skeletonThread)
                skeletonThread = nil
            end
            clearSkeleton()
        end
    end,
})

-- Combat
local aimAssistEnabled = false
local aimAssistThread = nil
local aimPart = "Head"
local aimSmoothness = 0.3
local aimFOV = 200
local aimWallCheck = false
local fovCircle = nil
local fovCircleVisible = false

local function createFOVCircle()
    if fovCircle then fovCircle:Destroy() end
    fovCircle = Drawing.new("Circle")
    fovCircle.Color = Color3.fromRGB(255, 255, 255)
    fovCircle.Thickness = 1.5
    fovCircle.Transparency = 0.7
    fovCircle.Visible = false
    fovCircle.Filled = false
    fovCircle.Radius = aimFOV
    fovCircle.Position = camera.ViewportSize / 2
end

local function updateFOVCircle()
    if fovCircle and fovCircleVisible then
        fovCircle.Radius = aimFOV
        fovCircle.Position = camera.ViewportSize / 2
    end
end

local function isVisible(targetPart)
    local origin = camera.CFrame.Position
    local direction = (targetPart.Position - origin).unit * 500
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {player.Character}
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    local result = workspace:Raycast(origin, direction, rayParams)
    if result and result.Instance then
        if result.Instance:IsDescendantOf(targetPart.Parent) then
            return true
        end
        return false
    end
    return true
end

local function getClosestPlayerInFOV()
    local closest = nil
    local shortestDist = aimFOV
    local center = camera.ViewportSize / 2
    for _, p in ipairs(game.Players:GetPlayers()) do
        if p ~= player and p.Character and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
            local part = p.Character:FindFirstChild(aimPart)
            if part then
                if aimWallCheck and not isVisible(part) then continue end
                local pos, onScreen = camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local screenPos = Vector2.new(pos.X, pos.Y)
                    local dist = (screenPos - center).Magnitude
                    if dist < shortestDist then
                        shortestDist = dist
                        closest = p
                    end
                end
            end
        end
    end
    return closest
end

local function aimAssistLoop()
    while aimAssistEnabled do
        updateFOVCircle()
        local target = getClosestPlayerInFOV()
        if target and target.Character then
            local part = target.Character:FindFirstChild(aimPart)
            if part then
                local camPos = camera.CFrame.Position
                local targetPos = part.Position
                local newLook = CFrame.lookAt(camPos, targetPos)
                camera.CFrame = camera.CFrame:Lerp(newLook, aimSmoothness)
            end
        end
        runService.RenderStepped:Wait()
    end
end

CombatTab:CreateToggle({
    Name = "Aim Assist",
    CurrentValue = false,
    Callback = function(Value)
        aimAssistEnabled = Value
        if aimAssistEnabled then
            createFOVCircle()
            fovCircle.Visible = true
            fovCircleVisible = true
            aimAssistThread = task.spawn(aimAssistLoop)
        else
            fovCircleVisible = false
            if fovCircle then
                fovCircle.Visible = false
                fovCircle:Destroy()
                fovCircle = nil
            end
            if aimAssistThread and task.isrunning(aimAssistThread) then
                task.cancel(aimAssistThread)
                aimAssistThread = nil
            end
        end
    end,
})

CombatTab:CreateToggle({
    Name = "Wall Check",
    CurrentValue = false,
    Callback = function(Value)
        aimWallCheck = Value
    end,
})

CombatTab:CreateToggle({
    Name = "Show FOV Circle",
    CurrentValue = false,
    Callback = function(Value)
        fovCircleVisible = Value
        if fovCircle then
            fovCircle.Visible = Value
        end
    end,
})

CombatTab:CreateDropdown({
    Name = "Aim Part",
    Options = {"Head", "HumanoidRootPart", "UpperTorso"},
    CurrentOption = "Head",
    Callback = function(Option)
        aimPart = Option
    end,
})

CombatTab:CreateSlider({
    Name = "Smoothness",
    Range = {0.1, 1},
    Increment = 0.01,
    CurrentValue = 0.3,
    Callback = function(v)
        aimSmoothness = v
    end,
})

CombatTab:CreateSlider({
    Name = "FOV",
    Range = {50, 500},
    Increment = 1,
    CurrentValue = 200,
    Callback = function(v)
        aimFOV = v
    end,
})

-- Soon
SoonTab:CreateButton({ Name = "Infinite Yield", Callback = function()
    loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()
end })

-- Очистка при выходе игрока
game.Players.PlayerRemoving:Connect(function(p)
    if highlights[p] then
        pcall(function() highlights[p]:Destroy() end)
        highlights[p] = nil
    end
    if skeletonDrawings[p] then
        for _, d in pairs(skeletonDrawings[p]) do
            pcall(function() d.Visible = false; d:Remove() end)
        end
        skeletonDrawings[p] = nil
    end
end)

-- Settings
SettingsTab:CreateButton({ Name = "Rejoin", Callback = function()
    ts:Teleport(placeId, player)
end })

SettingsTab:CreateButton({ Name = "Server Hop", Callback = function()
    local s = getServers()
    if #s > 0 then
        ts:TeleportToPlaceInstance(placeId, s[math.random(1, #s)], player)
    else
        ts:Teleport(placeId, player)
    end
end })

SettingsTab:CreateButton({ Name = "Destroy UI", Callback = function()
    espEnabled = false
    skeletonEnabled = false
    aimAssistEnabled = false
    fovCircleVisible = false
    if fovCircle then fovCircle:Destroy(); fovCircle = nil end
    if espThread and task.isrunning(espThread) then task.cancel(espThread) end
    if skeletonThread and task.isrunning(skeletonThread) then task.cancel(skeletonThread) end
    if aimAssistThread and task.isrunning(aimAssistThread) then task.cancel(aimAssistThread) end
    clearESP()
    clearSkeleton()
    Rayfield:Destroy()
end })
