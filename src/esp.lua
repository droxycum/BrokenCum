-- ============================================================
-- BrokenCum
-- SRC/esp.lua
-- DisplayName tags (blue), target-color swap, health/armor bars
-- ============================================================
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace  = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera

local ESP = {}
ESP.__index = ESP

local fontMap = {
    GothamBold = Drawing.Fonts.Bold,
    Gotham = Drawing.Fonts.Regular,
    SourceSansBold = Drawing.Fonts.Bold,
    Code = Drawing.Fonts.Code,
}

local function newDraw(class, props)
    local d = Drawing.new(class)
    for k, v in pairs(props or {}) do d[k] = v end
    return d
end

local tags   = {}   -- [player] = { name = Text, health = Square(back) + Square(fill), armor = ... }
local cfg, ui

local function getHead(char)
    return char:FindFirstChild("Head")
end

local function getHumanoid(char)
    return char:FindFirstChildOfClass("Humanoid")
end

local function ensure(plr)
    if tags[plr] then return tags[plr] end
    local t = {
        name   = newDraw("Text", { Size = 10, Center = true, Outline = true, Visible = false }),
        hpBack = newDraw("Square", { Filled = true, Visible = false, Thickness = 0 }),
        hpFill = newDraw("Square", { Filled = true, Visible = false, Thickness = 0 }),
        arBack = newDraw("Square", { Filled = true, Visible = false, Thickness = 0 }),
        arFill = newDraw("Square", { Filled = true, Visible = false, Thickness = 0 }),
    }
    tags[plr] = t
    return t
end

local function healthColor(frac)
    if frac > 0.66 then return Color3.fromRGB(0, 255, 100) end
    if frac > 0.33 then return Color3.fromRGB(180, 255, 0) end
    return Color3.fromRGB(255, 120, 0)
end

local function armorColor(frac)
    if frac > 0.66 then return Color3.fromRGB(0, 200, 255) end
    if frac > 0.33 then return Color3.fromRGB(0, 150, 255) end
    return Color3.fromRGB(0, 100, 255)
end

-- lock name comes from AutoShot; we read cfg to color-swap
local function isLocked(plr)
    local lock = cfg:Get("AutoShot.LockName")
    return lock and lock ~= "" and plr.DisplayName:lower() == lock:lower()
end

local function hideAll(t)
    for _, d in pairs(t) do if type(d) == "table" then hideAll(d) else d.Visible = false end end
end

function ESP.new()
    return setmetatable({}, ESP)
end

function ESP:Init(c, u)
    cfg, ui = c, u
    RunService.RenderStepped:Connect(function() self:_tick() end)
    Players.PlayerRemoving:Connect(function(plr)
        if tags[plr] then hideAll(tags[plr]); tags[plr] = nil end
    end)
end

function ESP:_tick()
    local nameOn   = cfg:Get("Visuals.NameESP.Enabled")
    local hpOn     = cfg:Get("Visuals.Health.Enabled")
    local arOn     = cfg:Get("Visuals.Armor.Enabled")
    local normalC  = cfg:Get("Visuals.NameESP.NormalColor")
    local targetC  = cfg:Get("Visuals.NameESP.TargetColor")
    local size     = cfg:Get("Visuals.NameESP.TextSize")
    local font     = fontMap[cfg:Get("Visuals.NameESP.Font")] or Drawing.Fonts.Bold

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer then goto skip end
        local char = plr.Character
        local head = char and getHead(char)
        local hum  = char and getHumanoid(char)
        if not (head and hum) then
            if tags[plr] then hideAll(tags[plr]) end
            goto skip
        end

        local pos, onScreen = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 1.5, 0))
        local t = ensure(plr)
        if not onScreen or hum.Health <= 0 then
            hideAll(t)
            goto skip
        end

        -- DisplayName tag
        if nameOn then
            t.name.Text = plr.DisplayName
            t.name.Size = size
            t.name.Font = font
            t.name.Color = isLocked(plr) and targetC or normalC
            t.name.Position = Vector2.new(pos.X, pos.Y)
            t.name.Visible = true
        else
            t.name.Visible = false
        end

        -- health / armor bars
        local baseY = pos.Y + 14
        if hpOn then
            local frac = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
            local w = 50
            t.hpBack.Position = Vector2.new(pos.X - w/2, baseY)
            t.hpBack.Size = Vector2.new(w, 4)
            t.hpBack.Color = Color3.fromRGB(20, 20, 25)
            t.hpBack.Visible = true
            t.hpFill.Position = Vector2.new(pos.X - w/2, baseY)
            t.hpFill.Size = Vector2.new(w * frac, 4)
            t.hpFill.Color = healthColor(frac)
            t.hpFill.Visible = true
            baseY = baseY + 6
        else
            t.hpBack.Visible = false; t.hpFill.Visible = false
        end

        if arOn then
            local armorVal = hum:GetAttribute("Armor") or hum:FindFirstChild("Armor")
            local armorFrac = 0
            if type(armorVal) == "number" then armorFrac = math.clamp(armorVal / 100, 0, 1)
            elseif typeof(armorVal) == "Instance" and armorVal:IsA("NumberValue") then armorFrac = math.clamp(armorVal.Value / 100, 0, 1) end
            local w = 50
            t.arBack.Position = Vector2.new(pos.X - w/2, baseY)
            t.arBack.Size = Vector2.new(w, 4)
            t.arBack.Color = Color3.fromRGB(20, 20, 25)
            t.arBack.Visible = true
            t.arFill.Position = Vector2.new(pos.X - w/2, baseY)
            t.arFill.Size = Vector2.new(w * armorFrac, 4)
            t.arFill.Color = armorColor(armorFrac)
            t.arFill.Visible = true
        else
            t.arBack.Visible = false; t.arFill.Visible = false
        end

        ::skip::
    end
end

return ESP.new()
