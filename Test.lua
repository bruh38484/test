local function updateSkeleton()
    while skeletonEnabled do
        for _, p in ipairs(game.Players:GetPlayers()) do
            if p ~= player and p.Character then
                if not skeletonDrawings[p] then skeletonDrawings[p] = {} end
                local char = p.Character
                for _, conn in ipairs(connections) do
                    local partA = char:FindFirstChild(conn[1])
                    local partB = char:FindFirstChild(conn[2])
                    if partA and partB then
                        local key = conn[1] .. conn[2]
                        if not skeletonDrawings[p][key] then
                            local line = Drawing.new("Line")
                            line.Color = Color3.fromRGB(255, 255, 255)
                            line.Thickness = 2
                            line.Transparency = 1
                            line.Visible = false
                            skeletonDrawings[p][key] = line
                        end
                        local line = skeletonDrawings[p][key]
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
local function startFlying()
    if flyConnection then flyConnection:Disconnect() end
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    local bv = Instance.new("BodyVelocity")
    bv.Velocity = Vector3.new(0, 0, 0)
    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bv.Parent = hrp

    local bg = Instance.new("BodyGyro")
    bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    bg.CFrame = camera.CFrame
    bg.Parent = hrp

    hum.PlatformStand = true

    flyConnection = runService.RenderStepped:Connect(function()
        if flyEnabled and player.Character and hrp.Parent then
            local md = hum.MoveDirection
            local cf = camera.CFrame
            local vel = Vector3.new(0, 0, 0)
            if md.Magnitude > 0 then
                vel = cf:VectorToWorldSpace(Vector3.new(md.X, 0, md.Z).Unit) * flySpeed
                vel = Vector3.new(vel.X, cf.LookVector.Y * flySpeed, vel.Z)
            else
                vel = Vector3.new(0, 0, 0)
            end
            bv.Velocity = vel
            bg.CFrame = cf
        else
            bv:Destroy()
            bg:Destroy()
            if hum then hum.PlatformStand = false end
            if flyConnection then flyConnection:Disconnect(); flyConnection = nil end
        end
    end)
end
