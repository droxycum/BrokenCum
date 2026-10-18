-- ============================================================
-- BrokenCum
-- SRC/visuals.lua
-- watermark + FOV indicators (silent aim, aim assist, triggerbot)
-- ============================================================
local RunService = game:GetService("RunService")
local Workspace  = game:GetService("Workspace")
local Camera     = Workspace.CurrentCamera

local Visuals = {}
Visuals.__index = Visuals

local cfg, ui

local function newDraw(class, props)
    local d = Drawing.new(class)
    for k, v in pairs(props or {}) do d[k] = v end
    return d
end

local ACCENT = Color3.fromRGB(213, 179, 252)

function Visuals.new() return setmetatable({}, Visuals) end

function Visuals:Init(c, u)
    cfg, ui = c, u

    -- watermark
    local wm = newDraw("Text", {
        Text = "brokencum", Color = ACCENT, Size = 16,
        Font = Drawing.Fonts.Bold, Outline = true,
        Position = Vector2.new(20, Camera.ViewportSize.Y - 30), Visible = true,
    })

    -- FOV shapes
    local saFov   = newDraw("Circle", { Thickness = 1, Filled = false, Color = ACCENT, Visible = false })
    local saBox   = newDraw("Square", { Thickness = 1, Filled = false, Color = ACCENT, Visible = false })
    local aaCircle= newDraw("Circle", { Thickness = 1, Filled = false, Color = Color3.fromRGB(60,130,255), Visible = false })
    local aaBox   = newDraw("Square", { Thickness = 1, Filled = false, Color = Color3.fromRGB(60,130,255), Visible = false })
    local tbBox   = newDraw("Square", { Thickness = 1, Filled = false, Color = Color3.fromRGB(255,120,0), Visible = false })

    RunService.RenderStepped:Connect(function()
        local vp = Camera.ViewportSize
        local center = Vector2.new(vp.X/2, vp.Y/2)

        -- watermark position by config
        local pos = cfg:Get("Visuals.Watermark.Position") or "Bottom"
        local wmOn = cfg:Get("Visuals.Watermark.Enabled")
        wm.Visible = wmOn
        wm.Text = "brokencum"
        if pos == "Bottom" then wm.Position = Vector2.new(20, vp.Y - 30)
        elseif pos == "Top" then wm.Position = Vector2.new(20, 10)
        elseif pos == "Left" then wm.Position = Vector2.new(10, vp.Y/2)
        elseif pos == "Right" then wm.Position = Vector2.new(vp.X - 120, vp.Y/2) end

        -- silent aim FOV
        local saShow = cfg:Get("SilentAim.FOV.Show")
        local saMode = cfg:Get("SilentAim.FOV.Mode")
        saFov.Visible = false; saBox.Visible = false
        if saShow and saMode == "2D Box" then
            local x, y = cfg:Get("SilentAim.FOV.X") or 5, cfg:Get("SilentAim.FOV.Y") or 5
            saBox.Size = Vector2.new(x*20, y*20)
            saBox.Position = center - saBox.Size/2
            saBox.Visible = true
        elseif saShow then
            saFov.Position = center
            saFov.Radius = (cfg:Get("SilentAim.FOV.X") or 5) * 20
            saFov.Visible = true
        end

        -- aim assist FOV
        local aaShow = cfg:Get("AimAssist.FOV.Show")
        local aaMode = cfg:Get("AimAssist.FOV.Mode")
        aaCircle.Visible = false; aaBox.Visible = false
        if aaShow then
            if aaMode == "2D Circle" then
                aaCircle.Position = center
                aaCircle.Radius = cfg:Get("AimAssist.FOV.Radius") or 100
                aaCircle.Visible = true
            elseif aaMode == "2D Box" then
                local x, y = cfg:Get("AimAssist.FOV.X") or 5, cfg:Get("AimAssist.FOV.Y") or 5
                aaBox.Size = Vector2.new(x*20, y*20)
                aaBox.Position = center - aaBox.Size/2
                aaBox.Visible = true
            end
        end

        -- triggerbot FOV
        local tbShow = cfg:Get("Triggerbot.FOV.Show")
        tbBox.Visible = false
        if tbShow and cfg:Get("Triggerbot.FOV.Mode") == "2D Box" then
            local x, y = cfg:Get("Triggerbot.FOV.X") or 5, cfg:Get("Triggerbot.FOV.Y") or 5
            tbBox.Size = Vector2.new(x*20, y*20)
            tbBox.Position = center - tbBox.Size/2
            tbBox.Visible = true
        end
    end)
end

return Visuals.new()
