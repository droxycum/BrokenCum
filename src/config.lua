-- ============================================================
-- BrokenCum
-- SRC/config.lua
-- settings engine: defaults + change events + save/load
-- ============================================================
local Config = {}
Config.__index = Config

local DEFAULTS = {
    Targeting = { Mode = "Select", Keybind = "C" },
    ModDetector = { Enabled = false, Action = "Kick" },
    Keybinds = {
        ["Aim Assist"] = "C", Triggerbot = "V", ["Name ESP"] = "T",
        WalkSpeed = "X", Velocity = "B", ["Jump Power"] = "J",
        ["Auto Reset"] = "K", ["Panic Ground"] = "G",
    },
    Checks = {
        Visible = true, Knock = true, KO = true,
        Crew = true, SelfKnock = true, Forcefield = true,
    },
    SilentAim = {
        Enabled = false, RageMode = false, Jitter = 0,
        Hitbox = "Head", PointScale = 0.7,
        Future = { Enabled = false, Lure = false, X = 0, Y = 0, Z = 0 },
        FOV = { Show = false, Mode = "2D Box", X = 5, Y = 5, Z = 5 },
    },
    AimAssist = {
        Enabled = true, Mode = "Toggle", Hitbox = "Head",
        FirstPerson = true, ThirdPerson = false,
        SmoothX = 0.1, SmoothY = 0.1,
        Curve = false, CurveIntensity = 0,
        Easing = "Linear", EasingDir = "InOut",
        FOV = { Show = false, Mode = "2D Circle", Radius = 100, X = 5, Y = 5, Z = 5 },
    },
    Triggerbot = {
        Enabled = true, Range = 300, Activation = "Hold",
        Detection = "Hitbox", InputSim = false,
        CPS = { Enabled = false, Value = 15 },
        InitialDelay = { Enabled = false, Min = 30, Max = 65 },
        SequentialDelay = { Enabled = false, Min = 20, Max = 50 },
        ToolSwitchDelay = { Enabled = false, Min = 80, Max = 150 },
        FOV = { Show = false, Mode = "2D Box", X = 5, Y = 5, Z = 5 },
    },
    Visuals = {
        NameESP = {
            Enabled = true,
            NormalColor = Color3.fromRGB(60, 130, 255),
            TargetColor = Color3.fromRGB(213, 179, 252),
            TextSize = 10, Font = "GothamBold",
        },
        Health = { Enabled = false, Position = "Bottom", Mode = "Current Target" },
        Armor = { Enabled = false, Position = "Bottom", Mode = "Current Target" },
        Watermark = { Enabled = true, Position = "Bottom", Label = "brokencum" },
    },
    Extras = {
        SpreadReduction = {
            Enabled = true,
            DoubleSG = { Mode = "Random", Fixed = 0.8, Min = 0.7, Max = 0.9 },
            TacticalShotgun = { Mode = "Random", Fixed = 0.8, Min = 0.7, Max = 0.9 },
        },
    },
    Movement = {
        WalkSpeed = { Enabled = false, Value = 250 },
        Velocity = { Enabled = false, Value = 250, Lerp = 1 },
        Spiderman = { Enabled = false, Mode = "Double", JumpPower = 50, KnifeJumpPower = 65 },
        JumpPower = { Enabled = false, Value = 250, NoCooldown = true },
    },
    Utilities = {
        AutoReset = { Enabled = false, Delay = 0 },
        PanicGround = { Enabled = false },
    },
    Misc = {
        AvatarSpoofer = { Enabled = false, Target = "", Skinny = true },
        Headless = false, Korblox = false,
        SkinChanger = { Enabled = false, Revolver = "Red Hot", DoubleSG = "Red Hot", TacticalShotgun = "Red Hot", Knife = "" },
    },
    AutoShot = { Enabled = false, LockName = "" },
}

local function merge(dst, src)
    for k, v in pairs(src) do
        if type(v) == "table" and type(dst[k]) == "table" then merge(dst[k], v)
        else dst[k] = v end
    end
    return dst
end

local function deepcopy(t)
    local o = {}
    for k, v in pairs(t) do o[k] = type(v) == "table" and deepcopy(v) or v end
    return o
end

local SAVE_PATH = "BrokenCum/config.json"

function Config.new()
    local self = setmetatable({}, Config)
    self.data = deepcopy(DEFAULTS)
    self._events = {}
    return self
end

function Config:Get(path)
    local node = self.data
    for key in path:gmatch("[^%.]+") do
        if type(node) ~= "table" then return nil end
        node = node[key]
    end
    return node
end

function Config:Set(path, value)
    local keys = {}
    for k in path:gmatch("[^%.]+") do keys[#keys + 1] = k end
    local node = self.data
    for i = 1, #keys - 1 do
        node = node[keys[i]]
        if type(node) ~= "table" then return end
    end
    node[keys[#keys]] = value
    self:_fire(path, value)
end

function Config:On(path, fn)
    self._events[path] = self._events[path] or {}
    table.insert(self._events[path], fn)
end

function Config:_fire(path, value)
    local list = self._events[path]
    if list then for _, fn in ipairs(list) do pcall(fn, value) end end
end

function Config:Save()
    if writefile then
        writefile(SAVE_PATH, game:GetService("HttpService"):JSONEncode(self.data))
    end
end

function Config:Load()
    if isfile and isfile(SAVE_PATH) then
        local ok, decoded = pcall(function()
            return game:GetService("HttpService"):JSONDecode(readfile(SAVE_PATH))
        end)
        if ok and type(decoded) == "table" then merge(self.data, decoded) end
    end
end

return Config.new()
