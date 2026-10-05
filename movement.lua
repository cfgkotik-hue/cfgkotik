--!nocheck
-- cfgkotik v37 — Movement (speed, fly, noclip, infinite jump, jump power, teleport)
local NS = getgenv().CFGKOTIK
if not NS then NS = {}; getgenv().CFGKOTIK = NS end

local Workspace = NS.Workspace
local UIS       = NS.UIS
local isBindActive = function(id)
    if NS.isBindActive then return NS.isBindActive(id) end
    return false
end
-- ================== SPEED ==================
do
    local saved = nil
    local trackedChar = nil

    NS.safeHeartbeat(function()
        local S = NS.Settings
        local c = NS.LP.Character
        if c ~= trackedChar then
            trackedChar = c
            saved = nil
        end
        if not c then return end

        local h = c:FindFirstChildOfClass("Humanoid")
        if not h then return end

        local on = S.SpeedHack or isBindActive("Speed")
        if on then
            if not saved then saved = h.WalkSpeed end
            if h.WalkSpeed ~= S.Speed then
                h.WalkSpeed = S.Speed
            end
        elseif saved then
            if h.WalkSpeed == S.Speed then
                h.WalkSpeed = saved
            end
            saved = nil
        end
    end)
end

-- ================== JUMP POWER ==================
NS.safeHeartbeat(function()
    local S = NS.Settings
    if not S.JumpPowerEnable then return end
    local c = NS.LP.Character
    if not c then return end
    local h = c:FindFirstChildOfClass("Humanoid")
    if not h then return end
    pcall(function()
        h.UseJumpPower = true
        h.JumpPower = S.JumpPower
    end)
end)

-- ================== INFINITE JUMP ==================
do
    local conn = nil

    NS.safeHeartbeat(function()
        local S = NS.Settings
        if S.InfiniteJump then
            if not conn then
                conn = UIS.JumpRequest:Connect(function()
                    local S2 = NS.Settings
                    if not S2.InfiniteJump then return end
                    local c = NS.LP.Character
                    if not c then return end
                    local h = c:FindFirstChildOfClass("Humanoid")
                    if not h then return end
                    pcall(function()
                        h:ChangeState(Enum.HumanoidStateType.Jumping)
                    end)
                end)
            end
        elseif conn then
            conn:Disconnect()
            conn = nil
        end
    end)
end

-- ================== NOCLIP ==================
NS.safeHeartbeat(function()
    local S = NS.Settings
    if not S.Noclip then return end
    local c = NS.LP.Character
    if not c then return end
    for _, p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") and p.CanCollide then
            p.CanCollide = false
        end
    end
end)

-- ================== FLY ==================
do
    local st = {
        on = false, hb = nil,
        att = nil, lv = nil, ao = nil,
        starting = false,
    }

    local function flyOn()
        local S = NS.Settings
        return S.Fly or isBindActive("Fly")
    end

    local function startFly()
        if st.starting then return end
        st.starting = true

        local c = NS.LP.Character
        if not c then st.starting = false; return end
        local hrp = c:FindFirstChild("HumanoidRootPart")
        if not hrp then st.starting = false; return end

        if st.lv then pcall(function() st.lv:Destroy() end) end
        if st.ao then pcall(function() st.ao:Destroy() end) end
        if st.att then pcall(function() st.att:Destroy() end) end

        local att = Instance.new("Attachment")
        att.Name = "cfgkotik_fly_att"
        att.Parent = hrp

        local lv = Instance.new("LinearVelocity")
        lv.Attachment0 = att
        lv.MaxForce = math.huge
        lv.RelativeTo = Enum.ActuatorRelativeTo.World
        lv.VectorVelocity = Vector3.zero
        lv.Parent = hrp

        local ao = Instance.new("AlignOrientation")
        ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
        ao.Attachment0 = att
        ao.MaxTorque = math.huge
        ao.Responsiveness = 200
        ao.Parent = hrp

        st.att, st.lv, st.ao = att, lv, ao

        if st.hb then st.hb:Disconnect() end
        st.hb = NS.safeHeartbeat(function()
            if not flyOn() or not st.lv or not st.lv.Parent then return end
            local cam = NS.Cam.cur or Workspace.CurrentCamera
            if not cam then return end

            local S = NS.Settings
            local cf = cam.CFrame
            local move = Vector3.zero
            local spd = S.FlySpeed or 80

            if UIS:IsKeyDown(Enum.KeyCode.W) then move = move + cf.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.S) then move = move - cf.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.A) then move = move - cf.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.D) then move = move + cf.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0,1,0) end
            if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then move = move - Vector3.new(0,1,0) end

            st.lv.VectorVelocity = move.Magnitude > 0 and move.Unit * spd or Vector3.zero
            st.ao.CFrame = cf
        end)

        st.starting = false
    end

    local function stopFly()
        if st.hb then st.hb:Disconnect(); st.hb = nil end
        if st.lv then pcall(function() st.lv:Destroy() end); st.lv = nil end
        if st.ao then pcall(function() st.ao:Destroy() end); st.ao = nil end
        if st.att then pcall(function() st.att:Destroy() end); st.att = nil end
    end

    NS.LP.CharacterAdded:Connect(function()
        if flyOn() then
            task.wait(0.2)
            st.on = false
            stopFly()
            st.on = true
            startFly()
        end
    end)

    NS.safeHeartbeat(function()
        if flyOn() and not st.on then
            st.on = true
            startFly()
        elseif not flyOn() and st.on then
            st.on = false
            stopFly()
        end
    end)
end

-- ================== TELEPORT ==================
NS.Misc = NS.Misc or {}

function NS.Misc.teleportToMouse()
    local mouse = NS.LP:GetMouse()
    if not mouse or not mouse.Hit then return end
    local c = NS.LP.Character
    if not c then return end
    local hrp = c:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    pcall(function()
        hrp.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0))
    end)
end

function NS.Misc.rejoin()
    local ok = pcall(function()
        game:GetService("TeleportService"):Teleport(game.PlaceId, NS.LP)
    end)
    if not ok then
        pcall(function()
            game:GetService("TeleportService"):TeleportToPlaceInstance(
                game.PlaceId, game.JobId, NS.LP)
        end)
    end
end

return NS
