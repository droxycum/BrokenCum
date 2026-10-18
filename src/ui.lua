-- ============================================================
-- BrokenCum
-- SRC/ui.lua
-- self-contained Drawing menu: tabs, toggles, sliders, inputs
-- ============================================================
local UserInputService = game:GetService("UserInputService")

local UI = {}
UI.__index = UI

local ACCENT = Color3.fromRGB(213, 179, 252)
local BG     = Color3.fromRGB(22, 22, 28)
local BG2    = Color3.fromRGB(32, 32, 40)
local TEXT   = Color3.fromRGB(235, 235, 240)

local function newDraw(class, props)
    local d = Drawing.new(class)
    for k, v in pairs(props or {}) do d[k] = v end
    return d
end

function UI.new()
    local self = setmetatable({}, UI)
    self.cfg = nil
    self.root = newDraw("Square", { Filled = true, Color = BG, Size = Vector2.new(460, 320),
        Position = Vector2.new(120, 120), Visible = false, ZIndex = 100 })
    self.title = newDraw("Text", { Text = "brokencum", Color = ACCENT, Size = 18,
        Font = Drawing.Fonts.Bold, Position = Vector2.new(134, 128), Visible = false, ZIndex = 101 })
    self.tabs = {}
    self.tabButtons = {}
    self.activeTab = nil
    self.dragging = false
    self.elements = {}
    self.visible = false
    return self
end

function UI:Init(cfg)
    self.cfg = cfg
    self:_bindDrag()
    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == Enum.KeyCode.RightShift then
            self:Toggle()
        end
    end)
end

function UI:_bindDrag()
    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local m = UserInputService:GetMouseLocation()
            local p = self.root.Position
            if self.visible and m.X >= p.X and m.X <= p.X + self.root.Size.X
                and m.Y >= p.Y and m.Y <= p.Y + 28 then
                self.dragging = true
                self._dragOffset = Vector2.new(m.X - p.X, m.Y - p.Y)
            end
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then self.dragging = false end
    end)
    game:GetService("RunService").RenderStepped:Connect(function()
        if self.dragging then
            local m = UserInputService:GetMouseLocation()
            local np = Vector2.new(m.X - self._dragOffset.X, m.Y - self._dragOffset.Y)
            self:_moveTo(np)
        end
    end)
end

function UI:_moveTo(pos)
    local delta = pos - self.root.Position
    self.root.Position = pos
    self.title.Position = self.title.Position + delta
    for _, el in ipairs(self.elements) do
        if el.objs then
            for _, o in ipairs(el.objs) do o.Position = o.Position + delta end
        end
    end
end

function UI:Toggle()
    self.visible = not self.visible
    self.root.Visible = self.visible
    self.title.Visible = self.visible
    for _, el in ipairs(self.elements) do self:_setElVisible(el, self.visible and el.tab == self.activeTab) end
    for _, tb in ipairs(self.tabButtons) do tb.Visible = self.visible end
end

function UI:_setElVisible(el, vis)
    if el.objs then for _, o in ipairs(el.objs) do o.Visible = vis end end
end

function UI:AddTab(name)
    local x = 134 + (#self.tabs * 90)
    local btn = newDraw("Text", { Text = name, Color = TEXT, Size = 14, Font = Drawing.Fonts.Bold,
        Position = Vector2.new(x, 156), Visible = self.visible, ZIndex = 102 })
    table.insert(self.tabButtons, btn)
    self.tabs[name] = {}
    if not self.activeTab then self.activeTab = name end

    local self_ = self
    UserInputService.InputBegan:Connect(function(input, gp)
        if gp or not self_.visible then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local m = UserInputService:GetMouseLocation()
            local p = btn.Position
            if m.X >= p.X and m.X <= p.X + 80 and m.Y >= p.Y and m.Y <= p.Y + 20 then
                self_:SwitchTab(name)
            end
        end
    end)
end

function UI:SwitchTab(name)
    self.activeTab = name
    for tabName, els in pairs(self.tabs) do
        for _, el in ipairs(els) do self:_setElVisible(el, self.visible and tabName == name) end
    end
end

function UI:_place()
    local tab = self.tabs[self.activeTab]
    local y = 186 + (#tab * 30)
    return Vector2.new(138, y)
end

function UI:AddToggle(tab, label, path)
    local pos = self:_place()
    local box = newDraw("Square", { Filled = true, Color = BG2, Size = Vector2.new(16, 16),
        Position = pos, Visible = self.visible, ZIndex = 102 })
    local txt = newDraw("Text", { Text = label, Color = TEXT, Size = 14, Font = Drawing.Fonts.Regular,
        Position = pos + Vector2.new(24, 0), Visible = self.visible, ZIndex = 102 })
    local el = { tab = tab, objs = { box, txt }, path = path }

    local function refresh(v)
        box.Color = v and ACCENT or BG2
    end
    refresh(self.cfg:Get(path))
    self.cfg:On(path, refresh)

    local self_ = self
    UserInputService.InputBegan:Connect(function(input, gp)
        if gp or not self_.visible or self_.activeTab ~= tab then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local m = UserInputService:GetMouseLocation()
            if m.X >= pos.X and m.X <= pos.X + 200 and m.Y >= pos.Y and m.Y <= pos.Y + 16 then
                self_.cfg:Set(path, not self_.cfg:Get(path))
            end
        end
    end)

    table.insert(self.tabs[tab], el)
    table.insert(self.elements, el)
    return el
end

function UI:AddSlider(tab, label, path, min, max, def)
    local pos = self:_place()
    local txt = newDraw("Text", { Text = label .. ": " .. tostring(self.cfg:Get(path) or def),
        Color = TEXT, Size = 14, Font = Drawing.Fonts.Regular,
        Position = pos, Visible = self.visible, ZIndex = 102 })
    local bar = newDraw("Square", { Filled = true, Color = BG2, Size = Vector2.new(180, 4),
        Position = pos + Vector2.new(0, 20), Visible = self.visible, ZIndex = 102 })
    local fill = newDraw("Square", { Filled = true, Color = ACCENT, Size = Vector2.new(0, 4),
        Position = pos + Vector2.new(0, 20), Visible = self.visible, ZIndex = 103 })
    local el = { tab = tab, objs = { txt, bar, fill }, path = path }

    local function refresh(v)
        txt.Text = label .. ": " .. string.format("%.0f", v)
        local pct = math.clamp((v - min) / (max - min), 0, 1)
        fill.Size = Vector2.new(180 * pct, 4)
    end
    refresh(self.cfg:Get(path) or def)
    self.cfg:On(path, refresh)

    local self_ = self
    local holding = false
    UserInputService.InputBegan:Connect(function(input, gp)
        if gp or not self_.visible or self_.activeTab ~= tab then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local m = UserInputService:GetMouseLocation()
            if m.X >= bar.Position.X and m.X <= bar.Position.X + 180
                and m.Y >= bar.Position.Y - 8 and m.Y <= bar.Position.Y + 12 then
                holding = true
            end
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then holding = false end
    end)
    game:GetService("RunService").RenderStepped:Connect(function()
        if holding then
            local m = UserInputService:GetMouseLocation()
            local pct = math.clamp((m.X - bar.Position.X) / 180, 0, 1)
            self_.cfg:Set(path, min + (max - min) * pct)
        end
    end)

    table.insert(self.tabs[tab], el)
    table.insert(self.elements, el)
    return el
end

return UI.new()
