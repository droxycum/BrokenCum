-- ============================================================
-- BrokenCum
-- SRC/ui.lua
-- Native Roblox GUI (crash-proof on Delta)
-- ============================================================
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")

local UI = {}
UI.__index = UI

local ACCENT = Color3.fromRGB(213, 179, 252)
local BG     = Color3.fromRGB(22, 22, 28)
local BG2    = Color3.fromRGB(32, 32, 40)
local TEXT   = Color3.fromRGB(235, 235, 240)

local function create(class, props, parent)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do inst[k] = v end
    inst.Parent = parent
    return inst
end

function UI.new()
    local self = setmetatable({}, UI)
    self.cfg = nil
    self.tabs = {}
    self.activeTab = nil
    self.visible = true

    -- attempt CoreGui, fallback to PlayerGui
    local ok, gui = pcall(function()
        local g = Instance.new("ScreenGui")
        g.Name = "BrokenCumUI"
        g.ResetOnSpawn = false
        g.Parent = CoreGui
        return g
    end)
    if not ok then
        gui = create("ScreenGui", { Name = "BrokenCumUI", ResetOnSpawn = false }, game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"))
    end
    self.gui = gui

    self.main = create("Frame", {
        Size = UDim2.new(0, 460, 0, 320),
        Position = UDim2.new(0, 120, 0, 120),
        BackgroundColor3 = BG,
        BorderSizePixel = 0,
        Visible = self.visible,
        Active = true
    }, self.gui)
    create("UICorner", { CornerRadius = UDim.new(0, 6) }, self.main)

    -- title / drag bar
    local topBar = create("Frame", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = BG2,
        BorderSizePixel = 0,
    }, self.main)
    create("UICorner", { CornerRadius = UDim.new(0, 6) }, topBar)
    create("TextLabel", {
        Text = "brokencum", TextColor3 = ACCENT,
        BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 16,
        Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(1, -10, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left
    }, topBar)

    -- drag logic
    local dragging, dragInput, dragStart, startPos
    topBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = self.main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    topBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            self.main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    -- tab container
    self.tabContainer = create("Frame", {
        Size = UDim2.new(1, 0, 0, 30),
        Position = UDim2.new(0, 0, 0, 30),
        BackgroundTransparency = 1,
    }, self.main)

    -- content container
    self.contentContainer = create("ScrollingFrame", {
        Size = UDim2.new(1, -20, 1, -70),
        Position = UDim2.new(0, 10, 0, 65),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = ACCENT,
    }, self.main)

    self:AddTab("Combat")
    self:AddTab("Visuals")
    self:AddTab("Movement")

    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == Enum.KeyCode.RightShift then
            self:Toggle()
        end
    end)
    return self
end

function UI:Init(cfg)
    self.cfg = cfg
end

function UI:Toggle()
    self.visible = not self.visible
    self.main.Visible = self.visible
end

function UI:AddTab(name)
    local btn = create("TextButton", {
        Text = name, TextColor3 = TEXT, BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold, TextSize = 14,
        Size = UDim2.new(0, 80, 1, 0),
        Position = UDim2.new(0, #self.tabs * 80, 0, 0),
    }, self.tabContainer)
    
    local page = create("Frame", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1, Visible = (#self.tabs == 0)
    }, self.contentContainer)
    
    self.tabs[name] = page
    if not self.activeTab then self.activeTab = name end

    btn.MouseButton1Click:Connect(function()
        for _, p in pairs(self.tabs) do p.Visible = false end
        page.Visible = true
        self.activeTab = name
    end)
end

function UI:AddToggle(tab, label, path)
    local page = self.tabs[tab]
    local item = create("Frame", { Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1 }, page)
    local btn = create("TextButton", {
        Text = label, TextColor3 = TEXT, BackgroundColor3 = BG2,
        Font = Enum.Font.Gotham, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, 0, 1, 0), AutoButtonColor = false,
    }, item)
    create("UICorner", { CornerRadius = UDim.new(0, 4) }, btn)
    create("UIPadding", { PaddingLeft = UDim.new(0, 10) }, btn)

    local function refresh(v)
        btn.TextColor3 = v and ACCENT or TEXT
    end
    refresh(self.cfg:Get(path))
    self.cfg:On(path, refresh)

    btn.MouseButton1Click:Connect(function()
        self.cfg:Set(path, not self.cfg:Get(path))
    end)
end

function UI:AddInput(tab, label, path, placeholder)
    local page = self.tabs[tab]
    local item = create("Frame", { Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1 }, page)
    create("TextLabel", { Text = label, TextColor3 = TEXT, BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 14, Size = UDim2.new(0.5, 0, 1, 0), TextXAlignment = Enum.TextXAlignment.Left }, item)
    
    local box = create("TextBox", {
        Text = "", PlaceholderText = placeholder or label, TextColor3 = ACCENT, PlaceholderColor3 = BG2,
        BackgroundColor3 = BG2, Font = Enum.Font.Gotham, TextSize = 14,
        Position = UDim2.new(0.5, 0, 0, 0), Size = UDim2.new(0.5, 0, 1, 0), ClearTextOnFocus = false
    }, item)
    create("UICorner", { CornerRadius = UDim.new(0, 4) }, box)
    
    box.FocusLost:Connect(function()
        self.cfg:Set(path, box.Text)
    end)
end

return UI.new()
