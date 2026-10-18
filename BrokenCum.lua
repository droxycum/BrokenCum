-- language: Lua, file: BrokenCum.lua, entry point
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
silent:SetCombat(combat)   -- wire the shared lock target in

silent:Start()
