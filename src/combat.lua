-- ============================================================
-- BrokenCum
-- SRC/combat.lua
-- target scan + nickname lock + autoshot + aim assist + triggerbot
-- feeds silentaim's GetLockTarget()
-- ============================================================
local Players       = game:GetService("Players")
local RunService    = game:GetService("RunService")
local Workspace     = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera

local Combat = {}
Combat.__index = Combat

local cfg, ui
local lockTarget = nil      -- BasePart of locked player
local lockPlayer = nil
local currentTarget = nil   -- aim-assist target part

local function getHum(char) return char and char:FindFirstChildOfClass("Humanoid") end

local function isCrew(plr)
    -- adjust if game exposes a crew/team system; default: same team
    return plr.Team ~= nil and plr.Team == LocalPlayer.Team
end

local function hasForcefield(char)
    return char and char:FindFirstChildOfClass("ForceField") ~= nil
end

local function isVisible(part, origin)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { LocalPlayer.Character, part.Parent }
    local ray = Workspace:Raycast(origin, (part.Position - origin), params)
    return ray == nil
end

local function hitboxPart(char, mode)
    if not char then return nil end
    if mode == "Head" then return char:FindFirstChild("Head") end
    if mode == "UpperTorso" then return char:FindFirstChild("UpperTorso") end
    if mode == "HumanoidRootPart" then return char:FindFirstChild("HumanoidRootPart") end
    -- closest part / point fallback
    return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
end

local function passesChecks(plr, char, hum)
    if plr == LocalPlayer then return false end
    if not (char and hum and hum.Health > 0) then return false end
    if cfg:Get("Checks.Knock") and hum.PlatformStand then return false end
    if cfg:Get("Checks.KO") and hum.Health <= 0 then return false end
    if cfg:Get("Checks.Crew") and isCrew(plr) then return false end
    if cfg:Get("Checks.Forcefield") and hasForcefield(char) then return false end
    return true
end

function Combat.new() return setmetatable({}, Combat) end

function Combat:Init(c, u)
    cfg, ui = c, u
    RunService.RenderStepped:Connect(function() self:_scan() end)
    RunService.Heartbeat:Connect(function() self:_autoshot() end)
    RunService.RenderStepped:Connect(function() self:_aimAssist() end)
    RunService.Heartbeat:Connect(function() self:_triggerbot() end)
end

-- returns the silentaim-facing lock target
function Combat:GetLockTarget()
    if cfg:Get("AutoShot.LockName") ~= "" and lockTarget then
        return lockTarget
    end
    if cfg:Get("SilentAim.Enabled") then return currentTarget end
    return nil
end

function Combat:_scan()
    local viewport = Camera.ViewportSize
    local center = Vector2.new(viewport.X / 2, viewport.Y / 2)

    -- nickname lock resolution
    local lockName = cfg:Get("AutoShot.LockName")
    lockTarget, lockPlayer = nil, nil
    if lockName and lockName ~= "" then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.DisplayName:lower() == lockName:lower() then
                local char = plr.Character
                local hum = getHum(char)
                if passesChecks(plr, char, hum) then
                    lockPlayer = plr
                    lockTarget = hitboxPart(char, cfg:Get("SilentAim.Hitbox"))
                end
                break
            end
        end
    end

    -- nearest-in-FOV for silent aim / aim assist
    local best, bestDist = nil, math.huge
    local fovR = cfg:Get("AimAssist.FOV.Radius") or 100
    for _, plr in ipairs(Players:GetPlayers()) do
        local char = plr.Character
        local hum = getHum(char)
        if passesChecks(plr, char, hum) then
            local part = hitboxPart(char, cfg:Get("SilentAim.Hitbox"))
            if part then
                local sp, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                    if d < bestDist and d <= fovR then
                        if not cfg:Get("Checks.Visible") or isVisible(part, Camera.CFrame.Position) then
                            best, bestDist = part, d
                        end
                    end
                end
            end
        end
    end
    currentTarget = best
end

-- ---- autoshot: fire held tool the instant the nickname lock is live ----
local lastShot = 0
local function fireTool()
    local char = LocalPlayer.Character
    local tool = char and char:FindFirstChildOfClass("Tool")
    if tool then tool:Activate() end
end

function Combat:_autoshot()
    if not cfg:Get("AutoShot.Enabled") then return end
    if not (lockPlayer and lockTarget) then return end
    if cfg:Get("Checks.SelfKnock") and LocalPlayer.Character then
        local myHum = getHum(LocalPlayer.Character)
        if myHum and myHum.PlatformStand then return end
    end
    local sp, onScreen = Camera:WorldToViewportPoint(lockTarget.Position)
    if not onScreen then return end
    local cps = cfg:Get("Triggerbot.CPS")
    local rate = (cfg:Get("Triggerbot.CPS.Enabled") and cfg:Get("Triggerbot.CPS.Value") or 20)
    local now = tick()
    if now - lastShot >= 1 / rate then
        fireTool()
        lastShot = now
    end
end

-- ---- aim assist: nudge camera toward target ----
function Combat:_aimAssist()
    if not cfg:Get("AimAssist.Enabled") or not currentTarget then return end
    local mode = cfg:Get("AimAssist.Mode")
    local active = mode == "Always"
    if mode == "Toggle" then active = UserInputService:IsKeyDown(Enum.KeyCode[cfg:Get("Targeting.Keybind")] or Enum.KeyCode.C) end
    if not active then return end

    local fp = cfg:Get("AimAssist.FirstPerson")
    local tp = cfg:Get("AimAssist.ThirdPerson")
    local dist = (Camera.CFrame.Position - currentTarget.Position).Magnitude
    local firstPerson = dist < 1.5
    if firstPerson and not fp then return end
    if (not firstPerson) and not tp then return end

    local targetCF = CFrame.new(Camera.CFrame.Position, currentTarget.Position)
    local sx = cfg:Get("AimAssist.SmoothX") or 0.1
    local sy = cfg:Get("AimAssist.SmoothY") or 0.1
    local alpha = math.clamp((sx + sy) / 2, 0.01, 1)
    Camera.CFrame = Camera.CFrame:Lerp(targetCF, alpha)
end

-- ---- triggerbot: auto-fire when crosshair sits on a valid target ----
local lastTrig = 0
function Combat:_triggerbot()
    if not cfg:Get("Triggerbot.Enabled") then return end
    local tgt = currentTarget or lockTarget
    if not tgt then return end

    local mode = cfg:Get("Triggerbot.Activation")
    local active = mode == "Always"
    if mode == "Hold" then active = UserInputService:IsKeyDown(Enum.KeyCode[cfg:Get("Keybinds.Triggerbot")] or Enum.KeyCode.V) end
    if mode == "Toggle" then active = true end
    if not active then return end

    local range = cfg:Get("Triggerbot.Range") or 300
    if (Camera.CFrame.Position - tgt.Position).Magnitude > range then return end

    local cps = cfg:Get("Triggerbot.CPS.Enabled") and cfg:Get("Triggerbot.CPS.Value") or 15
    local now = tick()
    if now - lastTrig >= 1 / cps then
        fireTool()
        lastTrig = now
    end
end

return Combat.new()
