-- ============================================================
-- BrokenCum
-- SRC/silentaim.lua
-- silent aim core — preserved from original XShot, behavior unchanged
-- ============================================================
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace  = game:GetService("Workspace")
local LocalPlayer= Players.LocalPlayer
local Camera     = Workspace.CurrentCamera

local M = {}
local cfg, ui, hook, combatRef

local function v68(v75, v76, v77)
    local v80 = (v76 - v75).Unit
    if v77 and v77 > 0 then
        local j = v77 * ((v76 - v75).Magnitude / 100)
        v80 = ((v76 + Vector3.new(
            math.random(-j * 100, j * 100) / 100,
            math.random(-j * 100, j * 100) / 100,
            math.random(-j * 100, j * 100) / 100
        )) - v75).Unit
    end
    return v80
end

function M:Init(c, u) cfg, ui = c, u end
function M:SetCombat(c) combatRef = c end

function M:Start()
    local enabled = false
    local function toggle(v) enabled = v end

    hook = hookmetamethod(game, "__namecall", newcclosure(function(...)
        local method = getnamecallmethod()
        if not enabled then return hook(...) end
        local args = {...}
        if method == "Raycast" or method == "FindPartOnRay" then
            local tgt = combatRef and combatRef:GetLockTarget()
            if tgt and not checkcaller() and args[1] ~= Camera then
                local origin = args[2] or (args[1] and args[1].Origin)
                if typeof(origin) == "Vector3" then
                    local aim = v68(origin, tgt.Position, cfg.SilentAim.Jitter)
                    args[3] = aim
                    if args[4] then args[4] = aim end
                    return hook(unpack(args))
                end
            end
        end
        return hook(...)
    end))

    cfg:On("SilentAim.Enabled", toggle)
end

function M:Unhook()
    if hook then hookmetamethod(game, "__namecall", hook); hook = nil end
end

return M
