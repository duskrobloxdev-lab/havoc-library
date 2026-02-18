--By Dusk


local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local Players          = game:GetService("Players")
local LocalPlayer      = Players.LocalPlayer

local Maid = {}
Maid.__index = Maid

function Maid.new()
    return setmetatable({ _tasks = {} }, Maid)
end

function Maid:Add(task)
    table.insert(self._tasks, task)
    return task
end

function Maid:Clean()
    for _, task in ipairs(self._tasks) do
        if typeof(task) == "RBXScriptConnection" then
            pcall(function() task:Disconnect() end)
        elseif typeof(task) == "Instance" then
            pcall(function() task:Destroy() end)
        elseif type(task) == "function" then
            pcall(task)
        end
    end
    self._tasks = {}
end

local Theme = {
    BackgroundRoot   = Color3.fromHex("0D0F14"),
    PrimarySurface   = Color3.fromHex("141821"),
    SecondarySurface = Color3.fromHex("1A1F2B"),
    Stroke           = Color3.fromHex("232938"),
    Accent           = Color3.fromHex("7B5CFF"),
    AccentHover      = Color3.fromHex("947BFF"),
    Error            = Color3.fromHex("FF4D4D"),
    Success          = Color3.fromHex("4DFF88"),
    TextPrimary      = Color3.fromHex("E6E6EB"),
    TextSecondary    = Color3.fromHex("8A8FA8"),
    TextDisabled     = Color3.fromHex("4A5068"),
    ToggleOff        = Color3.fromHex("2A3042"),
    ToggleKnob       = Color3.fromHex("E6E6EB"),
    Shadow           = Color3.fromHex("000000"),
    InputBg          = Color3.fromHex("0F1118"),

    RadiusMain   = UDim.new(0, 12),
    RadiusButton = UDim.new(0, 8),
    RadiusToggle = UDim.new(0, 100),
    RadiusCard   = UDim.new(0, 10),
    RadiusSmall  = UDim.new(0, 6),

    WindowW  = 620,
    WindowH  = 420,
    SidebarW = 170,
    TopbarH  = 45,

    FontBold = Enum.Font.GothamBold,
    FontSemi = Enum.Font.GothamSemibold,
    FontReg  = Enum.Font.Gotham,
}

local Tween = {}

function Tween.Play(inst, props, t, style, dir)
    local ok, tw = pcall(function()
        return TweenService:Create(
            inst,
            TweenInfo.new(t or 0.15, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out),
            props
        )
    end)
    if ok and tw then tw:Play() return tw end
end

local Util = {}

function Util.Corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = radius or Theme.RadiusCard
    c.Parent = parent
    return c
end

function Util.Stroke(parent, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color           = color or Theme.Stroke
    s.Thickness       = thickness or 1
    s.Transparency    = transparency or 0.55
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent          = parent
    return s
end

function Util.Frame(props, parent)
    local f = Instance.new("Frame")
    f.BorderSizePixel = 0
    for k, v in pairs(props or {}) do
        f[k] = v
    end
    if parent then f.Parent = parent end
    return f
end

function Util.Label(parent, text, size, color, font, xAlign)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.BorderSizePixel        = 0
    l.Text                   = text or ""
    l.TextSize               = size or 13
    l.TextColor3             = color or Theme.TextPrimary
    l.Font                   = font or Theme.FontReg
    l.TextXAlignment         = xAlign or Enum.TextXAlignment.Left
    l.TextTruncate           = Enum.TextTruncate.AtEnd
    l.Parent                 = parent
    return l
end

function Util.Shadow(parent, offset)
    local s = Util.Frame({
        Name                   = "_Shadow",
        Size                   = UDim2.new(1, 6, 1, 6),
        Position               = UDim2.new(0, -3, 0, offset or 3),
        BackgroundColor3       = Theme.Shadow,
        BackgroundTransparency = 0.68,
        ZIndex                 = (parent.ZIndex or 1) - 1,
    }, parent)
    Util.Corner(s, Theme.RadiusMain)
    return s
end

function Util.FixedCorner(frame)
    local fix = Util.Frame({
        Size             = UDim2.new(1, 0, 0, 12),
        Position         = UDim2.new(0, 0, 1, -12),
        BackgroundColor3 = frame.BackgroundColor3,
        ZIndex           = frame.ZIndex,
    }, frame)
    return fix
end

local Window = {}
Window.__index = Window

function Window.new(config)
    local self      = setmetatable({}, Window)
    self._maid      = Maid.new()
    self._tabs      = {}
    self._activeTab = nil
    self._visible   = true
    self._minimized = false

    local title    = config.Title   or "Dusk"
    local version  = config.Version or "v1.0"
    local keybind  = config.Keybind or Enum.KeyCode.RightShift

    local gui = Instance.new("ScreenGui")
    gui.Name           = "DuskUI"
    gui.ResetOnSpawn   = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.IgnoreGuiInset = true
    gui.Parent         = LocalPlayer.PlayerGui
    self._maid:Add(gui)
    self._gui = gui

    local shadow = Util.Frame({
        Name                   = "_Shadow",
        Size                   = UDim2.new(0, Theme.WindowW + 8, 0, Theme.WindowH + 8),
        Position               = UDim2.new(0.5, -(Theme.WindowW / 2) - 4, 0.5, -(Theme.WindowH / 2) + 4),
        BackgroundColor3       = Theme.Shadow,
        BackgroundTransparency = 0.65,
        ZIndex                 = 1,
    }, gui)
    Util.Corner(shadow, Theme.RadiusMain)

    local main = Util.Frame({
        Name             = "Main",
        Size             = UDim2.new(0, Theme.WindowW, 0, Theme.WindowH),
        Position         = UDim2.new(0.5, -(Theme.WindowW / 2), 0.5, -(Theme.WindowH / 2)),
        BackgroundColor3 = Theme.BackgroundRoot,
        ZIndex           = 2,
    }, gui)
    Util.Corner(main, Theme.RadiusMain)
    Util.Stroke(main)
    self._main   = main
    self._shadow = shadow

    main.Size = UDim2.new(0, Theme.WindowW, 0, 0)
    main.BackgroundTransparency = 1
    Tween.Play(main, { Size = UDim2.new(0, Theme.WindowW, 0, Theme.WindowH), BackgroundTransparency = 0 }, 0.22)

    local topbar = Util.Frame({
        Name             = "Topbar",
        Size             = UDim2.new(1, 0, 0, Theme.TopbarH),
        BackgroundColor3 = Theme.PrimarySurface,
        ZIndex           = 3,
    }, main)
    Util.Corner(topbar, Theme.RadiusMain)
    Util.FixedCorner(topbar)
    Util.Frame({
        Size             = UDim2.new(1, 0, 0, 1),
        Position         = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = Theme.Stroke,
        BackgroundTransparency = 0.4,
        ZIndex           = 4,
    }, topbar)

    local titleLbl = Util.Label(topbar, title, 15, Theme.TextPrimary, Theme.FontBold)
    titleLbl.Size     = UDim2.new(0, 220, 0, 20)
    titleLbl.Position = UDim2.new(0, 16, 0, 7)
    titleLbl.ZIndex   = 4

    local versionLbl = Util.Label(topbar, version, 11, Theme.TextSecondary, Theme.FontReg)
    versionLbl.Size     = UDim2.new(0, 220, 0, 14)
    versionLbl.Position = UDim2.new(0, 16, 0, 26)
    versionLbl.ZIndex   = 4

    local function makeTopBtn(offsetX, text, hoverColor)
        local btn = Instance.new("TextButton")
        btn.Size             = UDim2.new(0, 26, 0, 26)
        btn.Position         = UDim2.new(1, offsetX, 0.5, -13)
        btn.BackgroundColor3 = Color3.fromHex("232938")
        btn.BorderSizePixel  = 0
        btn.Text             = text
        btn.TextColor3       = Theme.TextSecondary
        btn.TextSize         = 12
        btn.Font             = Theme.FontSemi
        btn.ZIndex           = 5
        btn.AutoButtonColor  = false
        btn.Parent           = topbar
        Util.Corner(btn, Theme.RadiusSmall)
        btn.MouseEnter:Connect(function()
            Tween.Play(btn, { BackgroundColor3 = hoverColor, TextColor3 = Theme.TextPrimary }, 0.10)
        end)
        btn.MouseLeave:Connect(function()
            Tween.Play(btn, { BackgroundColor3 = Color3.fromHex("232938"), TextColor3 = Theme.TextSecondary }, 0.10)
        end)
        return btn
    end

    local closeBtn = makeTopBtn(-36, "✕", Theme.Error)
    local minBtn   = makeTopBtn(-68, "–", Color3.fromHex("4A5068"))

    closeBtn.MouseButton1Click:Connect(function() self:Destroy() end)
    minBtn.MouseButton1Click:Connect(function() self:Minimize() end)

    local sidebar = Util.Frame({
        Name             = "Sidebar",
        Size             = UDim2.new(0, Theme.SidebarW, 1, -Theme.TopbarH),
        Position         = UDim2.new(0, 0, 0, Theme.TopbarH),
        BackgroundColor3 = Theme.SecondarySurface,
        ZIndex           = 3,
    }, main)
    Util.Corner(sidebar, Theme.RadiusMain)
    Util.Frame({
        Size             = UDim2.new(0, 12, 1, 0),
        Position         = UDim2.new(1, -12, 0, 0),
        BackgroundColor3 = Theme.SecondarySurface,
        ZIndex           = 3,
    }, sidebar)
    Util.Frame({
        Size             = UDim2.new(0, 1, 1, 0),
        Position         = UDim2.new(1, -1, 0, 0),
        BackgroundColor3 = Theme.Stroke,
        BackgroundTransparency = 0.4,
        ZIndex           = 4,
    }, sidebar)
    Util.Frame({
        Size             = UDim2.new(1, 0, 0, 12),
        Position         = UDim2.new(0, 0, 1, -12),
        BackgroundColor3 = Theme.SecondarySurface,
        ZIndex           = 3,
    }, sidebar)

    local sidebarList = Instance.new("UIListLayout")
    sidebarList.SortOrder = Enum.SortOrder.LayoutOrder
    sidebarList.Padding   = UDim.new(0, 3)
    sidebarList.Parent    = sidebar

    local sidebarPad = Instance.new("UIPadding")
    sidebarPad.PaddingTop   = UDim.new(0, 10)
    sidebarPad.PaddingLeft  = UDim.new(0, 8)
    sidebarPad.PaddingRight = UDim.new(0, 8)
    sidebarPad.Parent       = sidebar

    local searchBox = Instance.new("TextBox")
    searchBox.Name                  = "Search"
    searchBox.Size                  = UDim2.new(1, -16, 0, 28)
    searchBox.Position              = UDim2.new(0, 8, 0, 52)
    searchBox.BackgroundColor3      = Theme.InputBg
    searchBox.BorderSizePixel       = 0
    searchBox.PlaceholderText       = "🔍  Search..."
    searchBox.PlaceholderColor3     = Theme.TextDisabled
    searchBox.Text                  = ""
    searchBox.TextColor3            = Theme.TextPrimary
    searchBox.TextSize              = 12
    searchBox.Font                  = Theme.FontReg
    searchBox.ClearTextOnFocus      = false
    searchBox.ZIndex                = 5
    searchBox.Parent                = main
    Util.Corner(searchBox, Theme.RadiusSmall)
    Util.Stroke(searchBox)

    local content = Util.Frame({
        Name             = "Content",
        Size             = UDim2.new(1, -Theme.SidebarW, 1, -Theme.TopbarH),
        Position         = UDim2.new(0, Theme.SidebarW, 0, Theme.TopbarH),
        BackgroundColor3 = Theme.BackgroundRoot,
        ZIndex           = 3,
    }, main)
    Util.Corner(content, Theme.RadiusMain)

    self._sidebar     = sidebar
    self._content     = content
    self._searchBox   = searchBox
    self._shadow      = shadow

    local dragging, dragStart, startMain, startShadow = false, nil, nil, nil
    topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging    = true
            dragStart   = input.Position
            startMain   = main.Position
            startShadow = shadow.Position
        end
    end)
    topbar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    self._maid:Add(UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local d = input.Position - dragStart
            main.Position   = UDim2.new(startMain.X.Scale,   startMain.X.Offset   + d.X, startMain.Y.Scale,   startMain.Y.Offset   + d.Y)
            shadow.Position = UDim2.new(startShadow.X.Scale, startShadow.X.Offset + d.X, startShadow.Y.Scale, startShadow.Y.Offset + d.Y)
        end
    end))

    self._maid:Add(UserInputService.InputBegan:Connect(function(input, gpe)
        if not gpe and input.KeyCode == keybind then
            self:Toggle()
        end
    end))

    self._maid:Add(searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        self:_filterSearch(searchBox.Text)
    end))

    return self
end

function Window:_filterSearch(query)
    local q = query:lower()
    if self._activeTab then
        local scroll = self._activeTab.Scroll
        for _, child in ipairs(scroll:GetChildren()) do
            if child:IsA("Frame") or child:IsA("TextButton") then
                if q == "" then
                    child.Visible = true
                else
                    local name = child.Name:lower()
                    child.Visible = string.find(name, q, 1, true) ~= nil
                end
            end
        end
    end
end

function Window:Toggle()
    self._visible = not self._visible
    if self._visible then
        self._main.Visible = true
        self._shadow.Visible = true
        Tween.Play(self._main, { BackgroundTransparency = 0 }, 0.15)
    else
        Tween.Play(self._main, { BackgroundTransparency = 1 }, 0.15)
        task.delay(0.16, function()
            if not self._visible then
                self._main.Visible   = false
                self._shadow.Visible = false
            end
        end)
    end
end

function Window:Minimize()
    self._minimized = not self._minimized
    local targetH = self._minimized and Theme.TopbarH or Theme.WindowH
    Tween.Play(self._main, { Size = UDim2.new(0, Theme.WindowW, 0, targetH) }, 0.18)
    self._content.Visible = not self._minimized
    self._sidebar.Visible = not self._minimized
    self._searchBox.Visible = not self._minimized
    self._shadow.Visible = not self._minimized
end

function Window:Destroy()
    self._maid:Clean()
end

function Window:Notify(title, message, duration, ntype)
    duration = duration or 4
    ntype    = ntype    or "info"
    local color = ntype == "success" and Theme.Success
               or ntype == "error"   and Theme.Error
               or Theme.Accent

    local holder = self._gui:FindFirstChild("_Notifs") or (function()
        local f = Util.Frame({
            Name                   = "_Notifs",
            Size                   = UDim2.new(0, 300, 1, 0),
            Position               = UDim2.new(1, -316, 0, 0),
            BackgroundTransparency = 1,
            ZIndex                 = 99,
        }, self._gui)
        local nl = Instance.new("UIListLayout")
        nl.SortOrder         = Enum.SortOrder.LayoutOrder
        nl.VerticalAlignment = Enum.VerticalAlignment.Bottom
        nl.Padding           = UDim.new(0, 6)
        nl.Parent            = f
        local np = Instance.new("UIPadding")
        np.PaddingBottom = UDim.new(0, 16)
        np.Parent        = f
        return f
    end)()

    local card = Util.Frame({
        Name                   = "_Notif",
        Size                   = UDim2.new(1, 0, 0, 70),
        BackgroundColor3       = Theme.PrimarySurface,
        BackgroundTransparency = 1,
        ZIndex                 = 100,
    }, holder)
    Util.Corner(card, Theme.RadiusCard)
    Util.Stroke(card)

    local accent = Util.Frame({
        Size             = UDim2.new(0, 3, 0.65, 0),
        Position         = UDim2.new(0, 10, 0.175, 0),
        BackgroundColor3 = color,
        ZIndex           = 101,
    }, card)
    Util.Corner(accent, UDim.new(0, 4))

    local tl = Util.Label(card, title, 13, Theme.TextPrimary, Theme.FontSemi)
    tl.Size     = UDim2.new(1, -32, 0, 18)
    tl.Position = UDim2.new(0, 22, 0, 12)
    tl.ZIndex   = 101

    local ml = Util.Label(card, message, 12, Theme.TextSecondary, Theme.FontReg)
    ml.Size        = UDim2.new(1, -32, 0, 30)
    ml.Position    = UDim2.new(0, 22, 0, 30)
    ml.ZIndex      = 101
    ml.TextWrapped = true

    local prog = Util.Frame({
        Size             = UDim2.new(1, 0, 0, 2),
        Position         = UDim2.new(0, 0, 1, -2),
        BackgroundColor3 = color,
        ZIndex           = 101,
    }, card)
    Util.Corner(prog, UDim.new(0, 2))

    Tween.Play(card, { BackgroundTransparency = 0 }, 0.18)
    Tween.Play(prog, { Size = UDim2.new(0, 0, 0, 2) }, duration, Enum.EasingStyle.Linear)

    task.delay(duration, function()
        Tween.Play(card, { BackgroundTransparency = 1 }, 0.18)
        task.wait(0.2)
        card:Destroy()
    end)
end

function Window:AddTab(name, icon)
    local tabId = #self._tabs + 1

    local tabFrame = Util.Frame({
        Name                   = "Tab_" .. name,
        Size                   = UDim2.new(1, 0, 0, 34),
        BackgroundColor3       = Theme.SecondarySurface,
        BackgroundTransparency = 1,
        ZIndex                 = 4,
        LayoutOrder            = tabId,
    }, self._sidebar)
    Util.Corner(tabFrame, Theme.RadiusCard)

    local indicator = Util.Frame({
        Size                   = UDim2.new(0, 3, 0.55, 0),
        Position               = UDim2.new(0, 0, 0.225, 0),
        BackgroundColor3       = Theme.Accent,
        BackgroundTransparency = 1,
        ZIndex                 = 5,
    }, tabFrame)
    Util.Corner(indicator, UDim.new(0, 4))

    if icon then
        local iconLbl = Util.Label(tabFrame, icon, 14, Theme.TextSecondary, Theme.FontReg)
        iconLbl.Size           = UDim2.new(0, 22, 1, 0)
        iconLbl.Position       = UDim2.new(0, 10, 0, 0)
        iconLbl.ZIndex         = 5
        iconLbl.TextXAlignment = Enum.TextXAlignment.Center
    end

    local nameLbl = Util.Label(tabFrame, name, 13, Theme.TextSecondary, Theme.FontSemi)
    nameLbl.Size     = UDim2.new(1, icon and -38 or -18, 1, 0)
    nameLbl.Position = UDim2.new(0, icon and 36 or 10, 0, 0)
    nameLbl.ZIndex   = 5

    local page = Util.Frame({
        Name                   = "Page_" .. name,
        Size                   = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Visible                = false,
        ZIndex                 = 4,
    }, self._content)

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size                 = UDim2.new(1, -8, 1, -8)
    scroll.Position             = UDim2.new(0, 4, 0, 4)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel      = 0
    scroll.ScrollBarThickness   = 3
    scroll.ScrollBarImageColor3 = Theme.Stroke
    scroll.CanvasSize           = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize  = Enum.AutomaticSize.Y
    scroll.ZIndex               = 5
    scroll.Parent               = page

    local list = Instance.new("UIListLayout")
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Padding   = UDim.new(0, 5)
    list.Parent    = scroll

    local pad = Instance.new("UIPadding")
    pad.PaddingTop    = UDim.new(0, 8)
    pad.PaddingLeft   = UDim.new(0, 10)
    pad.PaddingRight  = UDim.new(0, 10)
    pad.PaddingBottom = UDim.new(0, 8)
    pad.Parent        = scroll

    local tabData = {
        Frame     = tabFrame,
        Page      = page,
        Scroll    = scroll,
        Indicator = indicator,
        NameLabel = nameLbl,
        Id        = tabId,
    }
    table.insert(self._tabs, tabData)

    local function activate()
        if self._activeTab then
            local prev = self._activeTab
            prev.Page.Visible = false
            Tween.Play(prev.Indicator, { BackgroundTransparency = 1 }, 0.15)
            Tween.Play(prev.NameLabel, { TextColor3 = Theme.TextSecondary }, 0.15)
            Tween.Play(prev.Frame, { BackgroundTransparency = 1 }, 0.15)
        end
        self._activeTab    = tabData
        page.Visible       = true
        self._searchBox.Text = ""
        Tween.Play(indicator, { BackgroundTransparency = 0 }, 0.15)
        Tween.Play(nameLbl, { TextColor3 = Theme.TextPrimary }, 0.15)
        Tween.Play(tabFrame, { BackgroundTransparency = 0.86 }, 0.15)
    end

    tabFrame.MouseEnter:Connect(function()
        if self._activeTab ~= tabData then
            Tween.Play(tabFrame, { BackgroundTransparency = 0.92 }, 0.10)
        end
    end)
    tabFrame.MouseLeave:Connect(function()
        if self._activeTab ~= tabData then
            Tween.Play(tabFrame, { BackgroundTransparency = 1 }, 0.10)
        end
    end)

    local btn = Instance.new("TextButton")
    btn.Size                   = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text                   = ""
    btn.ZIndex                 = 6
    btn.Parent                 = tabFrame
    btn.MouseButton1Click:Connect(activate)

    if tabId == 1 then activate() end

    local Section    = {}
    Section.__index  = Section
    Section._scroll  = scroll
    Section._maid    = self._maid
    Section._window  = self

    function Section:AddSectionHeader(text)
        local header = Util.Frame({
            Name             = "Header_" .. text,
            Size             = UDim2.new(1, 0, 0, 26),
            BackgroundTransparency = 1,
            ZIndex           = 6,
        }, self._scroll)

        local line = Util.Frame({
            Size             = UDim2.new(1, 0, 0, 1),
            Position         = UDim2.new(0, 0, 0.5, 0),
            BackgroundColor3 = Theme.Stroke,
            BackgroundTransparency = 0.3,
            ZIndex           = 7,
        }, header)

        local bg = Util.Frame({
            Size             = UDim2.new(0, 0, 1, 0),
            Position         = UDim2.new(0, 0, 0, 0),
            BackgroundColor3 = Theme.BackgroundRoot,
            ZIndex           = 8,
            AutomaticSize    = Enum.AutomaticSize.X,
        }, header)

        local lbl = Util.Label(bg, text, 11, Theme.Accent, Theme.FontSemi)
        lbl.Size     = UDim2.new(0, 0, 1, 0)
        lbl.AutomaticSize = Enum.AutomaticSize.X
        lbl.ZIndex   = 9

        local pad = Instance.new("UIPadding")
        pad.PaddingRight = UDim.new(0, 8)
        pad.Parent       = bg

        return header
    end

    function Section:AddToggle(label, default, callback, description)
        local state = default or false
        local rowH  = description and 50 or 38

        local row = Util.Frame({
            Name             = "Toggle_" .. label,
            Size             = UDim2.new(1, 0, 0, rowH),
            BackgroundColor3 = Theme.SecondarySurface,
            ZIndex           = 6,
        }, self._scroll)
        Util.Corner(row, Theme.RadiusCard)

        local lbl = Util.Label(row, label, 13, Theme.TextPrimary, Theme.FontSemi)
        lbl.Size     = UDim2.new(1, -64, 0, 18)
        lbl.Position = UDim2.new(0, 12, 0, description and 9 or 10)
        lbl.ZIndex   = 7

        if description then
            local desc = Util.Label(row, description, 11, Theme.TextSecondary, Theme.FontReg)
            desc.Size     = UDim2.new(1, -64, 0, 14)
            desc.Position = UDim2.new(0, 12, 0, 28)
            desc.ZIndex   = 7
        end

        local track = Util.Frame({
            Size             = UDim2.new(0, 38, 0, 20),
            Position         = UDim2.new(1, -50, 0.5, -10),
            BackgroundColor3 = state and Theme.Accent or Theme.ToggleOff,
            ZIndex           = 7,
        }, row)
        Util.Corner(track, Theme.RadiusToggle)

        local knob = Util.Frame({
            Size             = UDim2.new(0, 14, 0, 14),
            Position         = state and UDim2.new(0, 21, 0.5, -7) or UDim2.new(0, 3, 0.5, -7),
            BackgroundColor3 = Theme.ToggleKnob,
            ZIndex           = 8,
        }, track)
        Util.Corner(knob, Theme.RadiusToggle)

        local glow = Util.Frame({
            Size                   = UDim2.new(1, 10, 1, 10),
            Position               = UDim2.new(0, -5, 0, -5),
            BackgroundColor3       = Theme.Accent,
            BackgroundTransparency = state and 0.80 or 1,
            ZIndex                 = 6,
        }, track)
        Util.Corner(glow, Theme.RadiusToggle)

        local function set(val, silent)
            state = val
            Tween.Play(track, { BackgroundColor3 = val and Theme.Accent or Theme.ToggleOff }, 0.12)
            Tween.Play(knob,  { Position = val and UDim2.new(0, 21, 0.5, -7) or UDim2.new(0, 3, 0.5, -7) }, 0.12)
            Tween.Play(glow,  { BackgroundTransparency = val and 0.80 or 1 }, 0.12)
            if not silent and callback then callback(val) end
        end

        local btn = Instance.new("TextButton")
        btn.Size                   = UDim2.new(1, 0, 1, 0)
        btn.BackgroundTransparency = 1
        btn.Text                   = ""
        btn.ZIndex                 = 9
        btn.Parent                 = row
        btn.MouseButton1Click:Connect(function() set(not state) end)

        row.MouseEnter:Connect(function()
            Tween.Play(row, { BackgroundColor3 = Color3.fromHex("1F2535") }, 0.10)
        end)
        row.MouseLeave:Connect(function()
            Tween.Play(row, { BackgroundColor3 = Theme.SecondarySurface }, 0.10)
        end)

        return { Set = set, Get = function() return state end, Row = row }
    end

    function Section:AddButton(label, callback, description)
        local rowH = description and 50 or 36

        local btn = Instance.new("TextButton")
        btn.Name             = "Btn_" .. label
        btn.Size             = UDim2.new(1, 0, 0, rowH)
        btn.BackgroundColor3 = Theme.SecondarySurface
        btn.BorderSizePixel  = 0
        btn.Text             = ""
        btn.AutoButtonColor  = false
        btn.ZIndex           = 6
        btn.Parent           = self._scroll
        Util.Corner(btn, Theme.RadiusCard)
        Util.Stroke(btn)

        local lbl = Util.Label(btn, label, 13, Theme.TextPrimary, Theme.FontSemi, Enum.TextXAlignment.Center)
        lbl.Size     = UDim2.new(1, 0, description and 0 or 1, description and 20 or 0)
        lbl.Position = description and UDim2.new(0, 0, 0, 9) or UDim2.new(0, 0, 0, 0)
        lbl.ZIndex   = 7

        if description then
            local desc = Util.Label(btn, description, 11, Theme.TextSecondary, Theme.FontReg, Enum.TextXAlignment.Center)
            desc.Size     = UDim2.new(1, 0, 0, 14)
            desc.Position = UDim2.new(0, 0, 0, 28)
            desc.ZIndex   = 7
        end

        btn.MouseEnter:Connect(function()
            Tween.Play(btn, { BackgroundColor3 = Color3.fromHex("1F2535") }, 0.10)
        end)
        btn.MouseLeave:Connect(function()
            Tween.Play(btn, { BackgroundColor3 = Theme.SecondarySurface }, 0.10)
        end)
        btn.MouseButton1Down:Connect(function()
            Tween.Play(btn, { Size = UDim2.new(0.975, 0, 0, rowH - 2) }, 0.08)
        end)
        btn.MouseButton1Up:Connect(function()
            Tween.Play(btn, { Size = UDim2.new(1, 0, 0, rowH) }, 0.10)
        end)
        btn.MouseButton1Click:Connect(function()
            if callback then callback() end
        end)

        return btn
    end

    function Section:AddSlider(label, min, max, default, step, callback)
        if type(step) == "function" then callback = step; step = nil end
        step  = step or 0
        local value = math.clamp(default or min, min, max)

        local row = Util.Frame({
            Name             = "Slider_" .. label,
            Size             = UDim2.new(1, 0, 0, 52),
            BackgroundColor3 = Theme.SecondarySurface,
            ZIndex           = 6,
        }, self._scroll)
        Util.Corner(row, Theme.RadiusCard)

        local lbl = Util.Label(row, label, 13, Theme.TextPrimary, Theme.FontSemi)
        lbl.Size     = UDim2.new(1, -70, 0, 18)
        lbl.Position = UDim2.new(0, 12, 0, 8)
        lbl.ZIndex   = 7

        local function fmt(v)
            if step > 0 then
                return tostring(math.round(v / step) * step)
            end
            return tostring(math.round(v * 100) / 100)
        end

        local valLbl = Util.Label(row, fmt(value), 12, Theme.Accent, Theme.FontSemi, Enum.TextXAlignment.Right)
        valLbl.Size     = UDim2.new(0, 58, 0, 18)
        valLbl.Position = UDim2.new(1, -68, 0, 8)
        valLbl.ZIndex   = 7

        local track = Util.Frame({
            Size             = UDim2.new(1, -24, 0, 4),
            Position         = UDim2.new(0, 12, 0, 34),
            BackgroundColor3 = Theme.ToggleOff,
            ZIndex           = 7,
        }, row)
        Util.Corner(track, UDim.new(0, 4))

        local fill = Util.Frame({
            Size             = UDim2.new((value - min) / (max - min), 0, 1, 0),
            BackgroundColor3 = Theme.Accent,
            ZIndex           = 8,
        }, track)
        Util.Corner(fill, UDim.new(0, 4))

        local handle = Util.Frame({
            Size             = UDim2.new(0, 12, 0, 12),
            Position         = UDim2.new((value - min) / (max - min), -6, 0.5, -6),
            BackgroundColor3 = Theme.ToggleKnob,
            ZIndex           = 9,
        }, track)
        Util.Corner(handle, Theme.RadiusToggle)

        local dragging = false

        local function updateFromX(x)
            local ax    = track.AbsolutePosition.X
            local aw    = track.AbsoluteSize.X
            local pct   = math.clamp((x - ax) / aw, 0, 1)
            local raw   = min + (max - min) * pct
            value       = step > 0 and (math.round(raw / step) * step) or raw
            value       = math.clamp(value, min, max)
            local fpct  = (value - min) / (max - min)
            fill.Size       = UDim2.new(fpct, 0, 1, 0)
            handle.Position = UDim2.new(fpct, -6, 0.5, -6)
            valLbl.Text     = fmt(value)
            if callback then callback(value) end
        end

        self._maid:Add(handle.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
        end))
        self._maid:Add(track.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                updateFromX(i.Position.X)
            end
        end))
        self._maid:Add(UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
        end))
        self._maid:Add(RunService.Heartbeat:Connect(function()
            if dragging then
                updateFromX(UserInputService:GetMouseLocation().X)
            end
        end))

        row.MouseEnter:Connect(function()
            Tween.Play(row, { BackgroundColor3 = Color3.fromHex("1F2535") }, 0.10)
        end)
        row.MouseLeave:Connect(function()
            Tween.Play(row, { BackgroundColor3 = Theme.SecondarySurface }, 0.10)
        end)

        return {
            Set = function(v)
                value = math.clamp(v, min, max)
                local pct = (value - min) / (max - min)
                fill.Size       = UDim2.new(pct, 0, 1, 0)
                handle.Position = UDim2.new(pct, -6, 0.5, -6)
                valLbl.Text     = fmt(value)
            end,
            Get = function() return value end,
        }
    end

    function Section:AddInput(label, placeholder, default, callback)
        local row = Util.Frame({
            Name             = "Input_" .. label,
            Size             = UDim2.new(1, 0, 0, 50),
            BackgroundColor3 = Theme.SecondarySurface,
            ZIndex           = 6,
        }, self._scroll)
        Util.Corner(row, Theme.RadiusCard)

        local lbl = Util.Label(row, label, 13, Theme.TextPrimary, Theme.FontSemi)
        lbl.Size     = UDim2.new(1, -24, 0, 16)
        lbl.Position = UDim2.new(0, 12, 0, 8)
        lbl.ZIndex   = 7

        local box = Instance.new("TextBox")
        box.Size                  = UDim2.new(1, -24, 0, 20)
        box.Position              = UDim2.new(0, 12, 0, 26)
        box.BackgroundColor3      = Theme.InputBg
        box.BorderSizePixel       = 0
        box.PlaceholderText       = placeholder or ""
        box.PlaceholderColor3     = Theme.TextDisabled
        box.Text                  = default or ""
        box.TextColor3            = Theme.TextPrimary
        box.TextSize              = 12
        box.Font                  = Theme.FontReg
        box.ClearTextOnFocus      = false
        box.TextXAlignment        = Enum.TextXAlignment.Left
        box.ZIndex                = 7
        box.Parent                = row
        Util.Corner(box, UDim.new(0, 4))
        Util.Stroke(box)

        local bp = Instance.new("UIPadding")
        bp.PaddingLeft = UDim.new(0, 8)
        bp.Parent      = box

        self._maid:Add(box.FocusLost:Connect(function(enter)
            if enter and callback then callback(box.Text) end
        end))

        box.Focused:Connect(function()
            Tween.Play(box, { BackgroundColor3 = Color3.fromHex("141821") }, 0.10)
        end)
        box.FocusLost:Connect(function()
            Tween.Play(box, { BackgroundColor3 = Theme.InputBg }, 0.10)
        end)

        row.MouseEnter:Connect(function()
            Tween.Play(row, { BackgroundColor3 = Color3.fromHex("1F2535") }, 0.10)
        end)
        row.MouseLeave:Connect(function()
            Tween.Play(row, { BackgroundColor3 = Theme.SecondarySurface }, 0.10)
        end)

        return {
            Get = function() return box.Text end,
            Set = function(v) box.Text = v end,
        }
    end

    function Section:AddDropdown(label, options, default, callback)
        local selected = default or (options[1] and options[1] or "")
        local open     = false
        local toggling = false
        local targetH  = math.min(#options * 30 + 8, 150)

        local wrapper = Util.Frame({
            Name             = "DD_" .. label,
            Size             = UDim2.new(1, 0, 0, 38),
            BackgroundTransparency = 1,
            ClipsDescendants = false,
            ZIndex           = 6,
        }, self._scroll)

        local row = Util.Frame({
            Size             = UDim2.new(1, 0, 0, 38),
            BackgroundColor3 = Theme.SecondarySurface,
            ZIndex           = 6,
        }, wrapper)
        Util.Corner(row, Theme.RadiusCard)
        Util.Stroke(row)

        local lbl = Util.Label(row, label, 13, Theme.TextSecondary, Theme.FontReg)
        lbl.Size     = UDim2.new(0.45, -12, 1, 0)
        lbl.Position = UDim2.new(0, 12, 0, 0)
        lbl.ZIndex   = 7

        local selLbl = Util.Label(row, selected, 13, Theme.TextPrimary, Theme.FontSemi, Enum.TextXAlignment.Right)
        selLbl.Size     = UDim2.new(0.55, -38, 1, 0)
        selLbl.Position = UDim2.new(0.45, 0, 0, 0)
        selLbl.ZIndex   = 7

        local arrow = Util.Label(row, "▾", 12, Theme.TextSecondary, Theme.FontReg, Enum.TextXAlignment.Center)
        arrow.Size     = UDim2.new(0, 24, 1, 0)
        arrow.Position = UDim2.new(1, -28, 0, 0)
        arrow.ZIndex   = 7

        local dropdown = Util.Frame({
            Size             = UDim2.new(1, 0, 0, 0),
            Position         = UDim2.new(0, 0, 0, 42),
            BackgroundColor3 = Theme.PrimarySurface,
            ClipsDescendants = true,
            ZIndex           = 10,
            Visible          = false,
        }, wrapper)
        Util.Corner(dropdown, Theme.RadiusCard)
        Util.Stroke(dropdown)

        local itemLayout = Instance.new("UIListLayout")
        itemLayout.SortOrder = Enum.SortOrder.LayoutOrder
        itemLayout.Parent    = dropdown

        local itemPad = Instance.new("UIPadding")
        itemPad.PaddingTop    = UDim.new(0, 4)
        itemPad.PaddingBottom = UDim.new(0, 4)
        itemPad.Parent        = dropdown

        local itemButtons = {}

        for i, opt in ipairs(options) do
            local isSelected = opt == selected
            local item = Instance.new("TextButton")
            item.Name             = "Item_" .. opt
            item.Size             = UDim2.new(1, 0, 0, 30)
            item.BackgroundColor3 = isSelected and Color3.fromHex("221E40") or Theme.PrimarySurface
            item.BackgroundTransparency = isSelected and 0 or 1
            item.BorderSizePixel  = 0
            item.Text             = opt
            item.TextColor3       = isSelected and Theme.Accent or Theme.TextPrimary
            item.TextSize         = 13
            item.Font             = Theme.FontReg
            item.TextXAlignment   = Enum.TextXAlignment.Left
            item.AutoButtonColor  = false
            item.ZIndex           = 11
            item.LayoutOrder      = i
            item.Parent           = dropdown
            local ip = Instance.new("UIPadding")
            ip.PaddingLeft = UDim.new(0, 12)
            ip.Parent      = item
            table.insert(itemButtons, item)

            item.MouseEnter:Connect(function()
                if opt ~= selected then
                    Tween.Play(item, { BackgroundTransparency = 0.9, BackgroundColor3 = Color3.fromHex("1F2535") }, 0.10)
                end
            end)
            item.MouseLeave:Connect(function()
                if opt ~= selected then
                    Tween.Play(item, { BackgroundTransparency = 1 }, 0.10)
                end
            end)
            item.MouseButton1Click:Connect(function()
                for _, b in ipairs(itemButtons) do
                    Tween.Play(b, { BackgroundTransparency = 1, TextColor3 = Theme.TextPrimary }, 0.10)
                    b.BackgroundColor3 = Theme.PrimarySurface
                end
                selected = opt
                selLbl.Text     = opt
                item.BackgroundColor3       = Color3.fromHex("221E40")
                item.BackgroundTransparency = 0
                item.TextColor3             = Theme.Accent
                if callback then callback(selected) end
            end)
        end

        local btn = Instance.new("TextButton")
        btn.Size                   = UDim2.new(1, 0, 1, 0)
        btn.BackgroundTransparency = 1
        btn.Text                   = ""
        btn.ZIndex                 = 8
        btn.Parent                 = row
        btn.MouseButton1Click:Connect(function()
            if toggling then return end
            toggling = true
            open     = not open
            dropdown.Visible = true
            local tw = Tween.Play(dropdown, { Size = open and UDim2.new(1, 0, 0, targetH) or UDim2.new(1, 0, 0, 0) }, 0.15)
            if tw then
                tw.Completed:Connect(function()
                    if not open then dropdown.Visible = false end
                    toggling = false
                end)
            else
                toggling = false
            end
        end)

        row.MouseEnter:Connect(function()
            Tween.Play(row, { BackgroundColor3 = Color3.fromHex("1F2535") }, 0.10)
        end)
        row.MouseLeave:Connect(function()
            Tween.Play(row, { BackgroundColor3 = Theme.SecondarySurface }, 0.10)
        end)

        return {
            Set = function(v) selected = v; selLbl.Text = v end,
            Get = function() return selected end,
        }
    end

    function Section:AddMultiDropdown(label, options, defaults, callback)
        local selected = {}
        for _, v in ipairs(defaults or {}) do selected[v] = true end
        local open     = false
        local toggling = false
        local targetH  = math.min(#options * 30 + 8, 150)

        local function getSelectedText()
            local t = {}
            for _, opt in ipairs(options) do
                if selected[opt] then table.insert(t, opt) end
            end
            return #t == 0 and "None" or table.concat(t, ", ")
        end

        local wrapper = Util.Frame({
            Name             = "MDD_" .. label,
            Size             = UDim2.new(1, 0, 0, 38),
            BackgroundTransparency = 1,
            ClipsDescendants = false,
            ZIndex           = 6,
        }, self._scroll)

        local row = Util.Frame({
            Size             = UDim2.new(1, 0, 0, 38),
            BackgroundColor3 = Theme.SecondarySurface,
            ZIndex           = 6,
        }, wrapper)
        Util.Corner(row, Theme.RadiusCard)
        Util.Stroke(row)

        local lbl = Util.Label(row, label, 13, Theme.TextSecondary, Theme.FontReg)
        lbl.Size     = UDim2.new(0.4, -12, 1, 0)
        lbl.Position = UDim2.new(0, 12, 0, 0)
        lbl.ZIndex   = 7

        local selLbl = Util.Label(row, getSelectedText(), 12, Theme.TextPrimary, Theme.FontReg, Enum.TextXAlignment.Right)
        selLbl.Size     = UDim2.new(0.6, -38, 1, 0)
        selLbl.Position = UDim2.new(0.4, 0, 0, 0)
        selLbl.ZIndex   = 7
        selLbl.TextTruncate = Enum.TextTruncate.AtEnd

        local arrow = Util.Label(row, "▾", 12, Theme.TextSecondary, Theme.FontReg, Enum.TextXAlignment.Center)
        arrow.Size     = UDim2.new(0, 24, 1, 0)
        arrow.Position = UDim2.new(1, -28, 0, 0)
        arrow.ZIndex   = 7

        local dropdown = Util.Frame({
            Size             = UDim2.new(1, 0, 0, 0),
            Position         = UDim2.new(0, 0, 0, 42),
            BackgroundColor3 = Theme.PrimarySurface,
            ClipsDescendants = true,
            ZIndex           = 10,
            Visible          = false,
        }, wrapper)
        Util.Corner(dropdown, Theme.RadiusCard)
        Util.Stroke(dropdown)

        local itemLayout = Instance.new("UIListLayout")
        itemLayout.SortOrder = Enum.SortOrder.LayoutOrder
        itemLayout.Parent    = dropdown

        local itemPad = Instance.new("UIPadding")
        itemPad.PaddingTop    = UDim.new(0, 4)
        itemPad.PaddingBottom = UDim.new(0, 4)
        itemPad.Parent        = dropdown

        for i, opt in ipairs(options) do
            local isOn = selected[opt] or false

            local item = Util.Frame({
                Name             = "Item_" .. opt,
                Size             = UDim2.new(1, 0, 0, 30),
                BackgroundColor3 = isOn and Color3.fromHex("221E40") or Theme.PrimarySurface,
                BackgroundTransparency = isOn and 0 or 1,
                ZIndex           = 11,
                LayoutOrder      = i,
            }, dropdown)

            local chk = Util.Frame({
                Size             = UDim2.new(0, 14, 0, 14),
                Position         = UDim2.new(0, 10, 0.5, -7),
                BackgroundColor3 = isOn and Theme.Accent or Theme.ToggleOff,
                ZIndex           = 12,
            }, item)
            Util.Corner(chk, UDim.new(0, 4))

            if isOn then
                local tick = Util.Label(chk, "✓", 10, Theme.TextPrimary, Theme.FontBold, Enum.TextXAlignment.Center)
                tick.Size   = UDim2.new(1, 0, 1, 0)
                tick.ZIndex = 13
            end

            local optLbl = Util.Label(item, opt, 13, isOn and Theme.Accent or Theme.TextPrimary, Theme.FontReg)
            optLbl.Size     = UDim2.new(1, -36, 1, 0)
            optLbl.Position = UDim2.new(0, 32, 0, 0)
            optLbl.ZIndex   = 12

            local ibtn = Instance.new("TextButton")
            ibtn.Size                   = UDim2.new(1, 0, 1, 0)
            ibtn.BackgroundTransparency = 1
            ibtn.Text                   = ""
            ibtn.ZIndex                 = 13
            ibtn.Parent                 = item

            ibtn.MouseButton1Click:Connect(function()
                selected[opt] = not selected[opt]
                local on = selected[opt]
                Tween.Play(item, { BackgroundTransparency = on and 0 or 1, BackgroundColor3 = on and Color3.fromHex("221E40") or Theme.PrimarySurface }, 0.10)
                Tween.Play(chk,  { BackgroundColor3 = on and Theme.Accent or Theme.ToggleOff }, 0.10)
                Tween.Play(optLbl, { TextColor3 = on and Theme.Accent or Theme.TextPrimary }, 0.10)
                selLbl.Text = getSelectedText()
                local result = {}
                for k, v in pairs(selected) do if v then table.insert(result, k) end end
                if callback then callback(result) end
            end)

            item.MouseEnter:Connect(function()
                if not selected[opt] then
                    Tween.Play(item, { BackgroundTransparency = 0.9, BackgroundColor3 = Color3.fromHex("1F2535") }, 0.10)
                end
            end)
            item.MouseLeave:Connect(function()
                if not selected[opt] then
                    Tween.Play(item, { BackgroundTransparency = 1 }, 0.10)
                end
            end)
        end

        local btn = Instance.new("TextButton")
        btn.Size                   = UDim2.new(1, 0, 1, 0)
        btn.BackgroundTransparency = 1
        btn.Text                   = ""
        btn.ZIndex                 = 8
        btn.Parent                 = row
        btn.MouseButton1Click:Connect(function()
            if toggling then return end
            toggling = true
            open     = not open
            dropdown.Visible = true
            local tw = Tween.Play(dropdown, { Size = open and UDim2.new(1, 0, 0, targetH) or UDim2.new(1, 0, 0, 0) }, 0.15)
            if tw then
                tw.Completed:Connect(function()
                    if not open then dropdown.Visible = false end
                    toggling = false
                end)
            else
                toggling = false
            end
        end)

        row.MouseEnter:Connect(function()
            Tween.Play(row, { BackgroundColor3 = Color3.fromHex("1F2535") }, 0.10)
        end)
        row.MouseLeave:Connect(function()
            Tween.Play(row, { BackgroundColor3 = Theme.SecondarySurface }, 0.10)
        end)

        return {
            Get = function()
                local r = {}
                for k, v in pairs(selected) do if v then table.insert(r, k) end end
                return r
            end,
            Set = function(t)
                selected = {}
                for _, v in ipairs(t) do selected[v] = true end
                selLbl.Text = getSelectedText()
            end,
        }
    end

    function Section:AddColorPicker(label, default, callback)
        local h, s, v = Color3.toHSV(default or Color3.fromRGB(123, 92, 255))
        local currentColor = Color3.fromHSV(h, s, v)
        local open = false
        local panel = nil

        local row = Util.Frame({
            Name             = "CP_" .. label,
            Size             = UDim2.new(1, 0, 0, 38),
            BackgroundColor3 = Theme.SecondarySurface,
            ZIndex           = 6,
        }, self._scroll)
        Util.Corner(row, Theme.RadiusCard)

        local lbl = Util.Label(row, label, 13, Theme.TextPrimary, Theme.FontSemi)
        lbl.Size     = UDim2.new(1, -60, 1, 0)
        lbl.Position = UDim2.new(0, 12, 0, 0)
        lbl.ZIndex   = 7

        local preview = Util.Frame({
            Size             = UDim2.new(0, 24, 0, 24),
            Position         = UDim2.new(1, -36, 0.5, -12),
            BackgroundColor3 = currentColor,
            ZIndex           = 7,
        }, row)
        Util.Corner(preview, UDim.new(0, 6))
        Util.Stroke(preview)

        local maid = self._maid

        local function applyColor()
            currentColor = Color3.fromHSV(h, s, v)
            preview.BackgroundColor3 = currentColor
            if callback then callback(currentColor) end
        end

        local function buildPanel()
            if panel then panel:Destroy() end

            panel = Util.Frame({
                Name             = "CPPanel",
                Size             = UDim2.new(1, 0, 0, 168),
                Position         = UDim2.new(0, 0, 1, 4),
                BackgroundColor3 = Theme.PrimarySurface,
                ZIndex           = 14,
            }, row)
            Util.Corner(panel, Theme.RadiusCard)
            Util.Stroke(panel)

            local svBox = Instance.new("ImageLabel")
            svBox.Name             = "SVBox"
            svBox.Size             = UDim2.new(1, -24, 0, 108)
            svBox.Position         = UDim2.new(0, 12, 0, 10)
            svBox.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
            svBox.BorderSizePixel  = 0
            svBox.Image            = "rbxassetid://4155801252"
            svBox.ZIndex           = 15
            svBox.Parent           = panel
            Util.Corner(svBox, UDim.new(0, 6))

            local svHandle = Util.Frame({
                Size             = UDim2.new(0, 10, 0, 10),
                Position         = UDim2.new(s, -5, 1 - v, -5),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                ZIndex           = 16,
            }, svBox)
            Util.Corner(svHandle, Theme.RadiusToggle)
            Util.Stroke(svHandle, Color3.fromRGB(0, 0, 0), 1.5, 0)

            local hueTrack = Util.Frame({
                Size             = UDim2.new(1, -24, 0, 12),
                Position         = UDim2.new(0, 12, 0, 126),
                ZIndex           = 15,
            }, panel)
            Util.Corner(hueTrack, UDim.new(0, 6))

            local hueGrad = Instance.new("UIGradient")
            hueGrad.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0,    Color3.fromHSV(0,    1, 1)),
                ColorSequenceKeypoint.new(0.16, Color3.fromHSV(0.16, 1, 1)),
                ColorSequenceKeypoint.new(0.33, Color3.fromHSV(0.33, 1, 1)),
                ColorSequenceKeypoint.new(0.50, Color3.fromHSV(0.50, 1, 1)),
                ColorSequenceKeypoint.new(0.66, Color3.fromHSV(0.66, 1, 1)),
                ColorSequenceKeypoint.new(0.83, Color3.fromHSV(0.83, 1, 1)),
                ColorSequenceKeypoint.new(1,    Color3.fromHSV(1,    1, 1)),
            })
            hueGrad.Parent = hueTrack

            local hueHandle = Util.Frame({
                Size             = UDim2.new(0, 8, 1, 4),
                Position         = UDim2.new(h, -4, 0, -2),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                ZIndex           = 16,
            }, hueTrack)
            Util.Corner(hueHandle, UDim.new(0, 4))
            Util.Stroke(hueHandle, Color3.fromRGB(0, 0, 0), 1.5, 0)

            local hexBox = Instance.new("TextBox")
            hexBox.Size             = UDim2.new(1, -24, 0, 22)
            hexBox.Position         = UDim2.new(0, 12, 0, 146)
            hexBox.BackgroundColor3 = Theme.InputBg
            hexBox.BorderSizePixel  = 0
            hexBox.Text             = "#" .. currentColor:ToHex():upper()
            hexBox.TextColor3       = Theme.TextPrimary
            hexBox.TextSize         = 12
            hexBox.Font             = Theme.FontReg
            hexBox.ClearTextOnFocus = false
            hexBox.ZIndex           = 15
            hexBox.Parent           = panel
            Util.Corner(hexBox, UDim.new(0, 4))
            Util.Stroke(hexBox)

            local function updateVisuals()
                currentColor             = Color3.fromHSV(h, s, v)
                preview.BackgroundColor3 = currentColor
                svBox.BackgroundColor3   = Color3.fromHSV(h, 1, 1)
                svHandle.Position        = UDim2.new(s, -5, 1 - v, -5)
                hueHandle.Position       = UDim2.new(h, -4, 0, -2)
                hexBox.Text              = "#" .. currentColor:ToHex():upper()
                if callback then callback(currentColor) end
            end

            local dragSV, dragHue = false, false

            maid:Add(svBox.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then dragSV = true end
            end))
            maid:Add(hueTrack.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then dragHue = true end
            end))
            maid:Add(UserInputService.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragSV  = false
                    dragHue = false
                end
            end))
            maid:Add(RunService.Heartbeat:Connect(function()
                local mouse = UserInputService:GetMouseLocation()
                if dragSV then
                    local ax, ay = svBox.AbsolutePosition.X, svBox.AbsolutePosition.Y
                    local aw, ah = svBox.AbsoluteSize.X, svBox.AbsoluteSize.Y
                    s = math.clamp((mouse.X - ax) / aw, 0, 1)
                    v = 1 - math.clamp((mouse.Y - ay) / ah, 0, 1)
                    updateVisuals()
                elseif dragHue then
                    local ax, aw = hueTrack.AbsolutePosition.X, hueTrack.AbsoluteSize.X
                    h = math.clamp((mouse.X - ax) / aw, 0, 1)
                    updateVisuals()
                end
            end))

            maid:Add(hexBox.FocusLost:Connect(function()
                local txt = hexBox.Text:gsub("#", ""):upper()
                if #txt == 6 then
                    local ok, c = pcall(Color3.fromHex, txt)
                    if ok then
                        h, s, v = Color3.toHSV(c)
                        updateVisuals()
                    end
                end
            end))
        end

        local btn = Instance.new("TextButton")
        btn.Size                   = UDim2.new(1, 0, 1, 0)
        btn.BackgroundTransparency = 1
        btn.Text                   = ""
        btn.ZIndex                 = 8
        btn.Parent                 = row
        btn.MouseButton1Click:Connect(function()
            open = not open
            if open then
                buildPanel()
            else
                if panel then panel:Destroy(); panel = nil end
            end
        end)

        row.MouseEnter:Connect(function()
            Tween.Play(row, { BackgroundColor3 = Color3.fromHex("1F2535") }, 0.10)
        end)
        row.MouseLeave:Connect(function()
            Tween.Play(row, { BackgroundColor3 = Theme.SecondarySurface }, 0.10)
        end)

        return {
            Get = function() return currentColor end,
            Set = function(c)
                currentColor = c
                h, s, v = Color3.toHSV(c)
                preview.BackgroundColor3 = c
            end,
        }
    end

    function Section:AddKeybind(label, default, callback)
        local key     = default or Enum.KeyCode.Unknown
        local binding = false

        local row = Util.Frame({
            Name             = "KB_" .. label,
            Size             = UDim2.new(1, 0, 0, 38),
            BackgroundColor3 = Theme.SecondarySurface,
            ZIndex           = 6,
        }, self._scroll)
        Util.Corner(row, Theme.RadiusCard)

        local lbl = Util.Label(row, label, 13, Theme.TextPrimary, Theme.FontSemi)
        lbl.Size     = UDim2.new(1, -114, 1, 0)
        lbl.Position = UDim2.new(0, 12, 0, 0)
        lbl.ZIndex   = 7

        local keyBtn = Instance.new("TextButton")
        keyBtn.Size             = UDim2.new(0, 92, 0, 24)
        keyBtn.Position         = UDim2.new(1, -104, 0.5, -12)
        keyBtn.BackgroundColor3 = Theme.InputBg
        keyBtn.BorderSizePixel  = 0
        keyBtn.Text             = key.Name
        keyBtn.TextColor3       = Theme.Accent
        keyBtn.TextSize         = 12
        keyBtn.Font             = Theme.FontSemi
        keyBtn.AutoButtonColor  = false
        keyBtn.ZIndex           = 7
        keyBtn.Parent           = row
        Util.Corner(keyBtn, UDim.new(0, 6))
        Util.Stroke(keyBtn)

        keyBtn.MouseButton1Click:Connect(function()
            binding           = true
            keyBtn.Text       = "..."
            keyBtn.TextColor3 = Theme.TextSecondary
        end)

        self._maid:Add(UserInputService.InputBegan:Connect(function(input, gpe)
            if binding and not gpe and input.UserInputType == Enum.UserInputType.Keyboard then
                key               = input.KeyCode
                binding           = false
                keyBtn.Text       = key.Name
                keyBtn.TextColor3 = Theme.Accent
                if callback then callback(key) end
            end
        end))

        row.MouseEnter:Connect(function()
            Tween.Play(row, { BackgroundColor3 = Color3.fromHex("1F2535") }, 0.10)
        end)
        row.MouseLeave:Connect(function()
            Tween.Play(row, { BackgroundColor3 = Theme.SecondarySurface }, 0.10)
        end)

        return {
            Get = function() return key end,
            Set = function(k) key = k; keyBtn.Text = k.Name end,
        }
    end

    function Section:AddLabel(text, color)
        local lbl = Util.Label(self._scroll, text, 12, color or Theme.TextSecondary, Theme.FontReg)
        lbl.Name   = "Label_" .. text
        lbl.Size   = UDim2.new(1, 0, 0, 18)
        lbl.ZIndex = 6
        return { Set = function(t) lbl.Text = t end, Get = function() return lbl.Text end }
    end

    function Section:AddSeparator()
        local sep = Util.Frame({
            Name             = "_Sep",
            Size             = UDim2.new(1, 0, 0, 1),
            BackgroundColor3 = Theme.Stroke,
            BackgroundTransparency = 0.3,
            ZIndex           = 6,
        }, self._scroll)
        return sep
    end

    return Section
end

local DuskLib = {}

function DuskLib:CreateWindow(config)
    local win = Window.new(config or {})

    local API    = {}
    API.__index  = API

    function API:AddTab(name, icon)
        return win:AddTab(name, icon)
    end

    function API:Notify(title, message, duration, ntype)
        win:Notify(title, message, duration, ntype)
    end

    function API:Toggle()
        win:Toggle()
    end

    function API:Minimize()
        win:Minimize()
    end

    function API:Destroy()
        win:Destroy()
    end

    return setmetatable({}, API)
end

return DuskLib
