-- ============================================================
-- BrokenCum
-- SRC/movement.lua
-- walkspeed, velocity+lerp, spiderman, jump power, auto reset, panic
-- ============================================================
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

local Move = {}
Move.__index = Move
local cfg, ui

local function getHum()
    local char = LocalPlayer.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function getHRP()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

function Move.new() return setmetatable({}, Move) end

function Move:Init(c, u)
    cfg, ui = c, u

    -- walk speed
    RunService.Heartbeat:Connect(function()
        local hum = getHum()
        if not hum then return end
        if cfg:Get("Movement.WalkSpeed.Enabled") then
            hum.WalkSpeed = cfg:Get("Movement.WalkSpeed.Value")
        end
        if cfg:Get("Movement.JumpPower.Enabled") then
            hum.JumpPower = cfg:Get("Movement.JumpPower.Value")
            hum.UseJumpPower = true
            if cfg:Get("Movement.JumpPower.NoCooldown") then
                hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
            end
        end
    end)

    -- velocity (with lerp)
    RunService.Heartbeat:Connect(function()
        local hrp = getHRP()
        if not hrp then return end
        if cfg:Get("Movement.Velocity.Enabled") then
            local v = cfg:Get("Movement.Velocity.Value")
            local lerp = cfg:Get("Movement.Velocity.Lerp") or 1
            local target = Vector3.new(v, 0, v)
            hrp.Velocity = hrp.Velocity:Lerp(target, lerp)
        end
    end)

    -- spiderman wall jump
    self._lastJump = 0
    RunService.Heartbeat:Connect(function()
        if not cfg:Get("Movement.Spiderman.Enabled") then return end
        local char = LocalPlayer.Character
        local hum = getHum()
        local hrp = getHRP()
        if not (char and hum and hrp) then return end
        if hum.FloorMaterial ~= Enum.Material.Air then return end
        local params = RaycastParams.new()
        params.FilterDescendantsInstances = { char }
        local hit = workspace:Raycast(hrp.Position, hrp.CFrame.LookVector * 3, params)
        if hit and tick() - self._lastJump > 0.2 then
            local power = cfg:Get("Movement.Spiderman.JumpPower") or 50
            hrp.Velocity = hrp.Velocity + hit.Normal * power
            self._lastJump = tick()
        end
    end)

    -- auto reset
    RunService.Heartbeat:Connect(function()
        if cfg:Get("Utilities.AutoReset.Enabled") then
            local hum = getHum()
            if hum then task.delay(cfg:Get("Utilities.AutoReset.Delay") or 0, function()
                if hum and hum.Parent then hum.Health = 0 end
            end) end
        end
    end)

    -- panic ground (keybind)
    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        local panicKey = cfg:Get("Keybinds.Panic Ground") or "G"
        if input.KeyCode == Enum.KeyCode[panicKey] and cfg:Get("Utilities.PanicGround.Enabled") then
            local hrp = getHRP()
            if hrp then hrp.CFrame = CFrame.new(hrp.Position + Vector3.new(0, 3, 0)) end
        end
    end)
end

return Move.new()
