-- ============================================================
-- BrokenCum
-- BrokenCum.lua (Root Loader)
-- ============================================================
local BASE = "https://raw.githubusercontent.com/droxycum/BrokenCum/main/src/"

local loaded = {}
local function load(f)
    local src = game:HttpGet(BASE .. f .. ".lua")
    local fn, err = loadstring(src)
    if not fn then error("[BrokenCum] " .. f .. ": " .. tostring(err)) end
    loaded[f] = fn()
    return loaded[f]
end

local cfg = load("config")
local ui  = load("ui")
ui:Init(cfg)

-- ============================================================
-- POPULATE THE UI
-- ============================================================

-- Combat Tab
ui:AddToggle("Combat", "Silent Aim", "SilentAim.Enabled")
ui:AddToggle("Combat", "Auto Shot (Nickname)", "AutoShot.Enabled")
ui:AddInput("Combat", "Lock Name", "AutoShot.LockName", "DisplayName")
ui:AddToggle("Combat", "Triggerbot", "Triggerbot.Enabled")
ui:AddToggle("Combat", "Aim Assist", "AimAssist.Enabled")

-- Visuals Tab
ui:AddToggle("Visuals", "Name ESP (Blue)", "Visuals.NameESP.Enabled")
ui:AddToggle("Visuals", "Health Bar", "Visuals.Health.Enabled")
ui:AddToggle("Visuals", "Armor Bar", "Visuals.Armor.Enabled")
ui:AddToggle("Visuals", "Watermark", "Visuals.Watermark.Enabled")

-- Movement Tab
ui:AddToggle("Movement", "Walk Speed", "Movement.WalkSpeed.Enabled")
ui:AddToggle("Movement", "Jump Power", "Movement.JumpPower.Enabled")
ui:AddToggle("Movement", "Spiderman", "Movement.Spiderman.Enabled")

-- ============================================================
-- INITIALIZE MODULES
-- ============================================================
local esp     = load("esp")
local combat  = load("combat")
local visuals = load("visuals")
local move    = load("movement")
local silent  = load("silentaim")

esp:Init(cfg, ui)
combat:Init(cfg, ui)
visuals:Init(cfg, ui)
move:Init(cfg, ui)
silent:Init(cfg, ui)
silent:SetCombat(combat)   -- Wire the lock target into the silent aim core

silent:Start()
