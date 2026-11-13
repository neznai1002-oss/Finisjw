--!nocheck
--=====================================================================
--  Eta  ·  OXIDE — SURVIVAL ISLAND
--  Визуальная реплика меню для Roblox (Luau), версия v2.8 · Eta28
--  Куда: LocalScript  →  StarterPlayer > StarterPlayerScripts
--
--  Всё визуальное: стеклянная панель, 7 вкладок, тумблеры, слайдеры,
--  превью ESP/скопа, конфиги, настройки, плавающая кнопка "η".
--  Пункты меню — фреймворк: подключайте свою логику в блоках --[[ HOOK ]].
--=====================================================================

local Players            = game:GetService("Players")
local RunService         = game:GetService("RunService")
local TweenService       = game:GetService("TweenService")
local UserInputService   = game:GetService("UserInputService")
local Lighting           = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

----------------------------------------------------------------------
-- ТЕМА
----------------------------------------------------------------------
local C = {
    BG       = Color3.fromRGB(13, 11, 24),
    PANEL    = Color3.fromRGB(22, 19, 38),
    PANEL2   = Color3.fromRGB(30, 26, 50),
    CARD     = Color3.fromRGB(34, 29, 56),
    STROKE   = Color3.fromRGB(96, 86, 140),
    TEXT     = Color3.fromRGB(236, 233, 247),
    SUB      = Color3.fromRGB(152, 146, 176),
    GOOD     = Color3.fromRGB(94, 224, 166),
    WARN     = Color3.fromRGB(255, 122, 140),
}
local ACCENT = Color3.fromRGB(178, 160, 255)
local ACCENT_DIM = Color3.fromRGB(120, 104, 190)

local accentBinds = {}      -- { {obj=Instance, prop="BackgroundColor3"} , ... }
local glassBinds  = {}      -- полупрозрачные фоны для "Прозрачность панели"

local function bindAccent(obj, prop)
    table.insert(accentBinds, { obj = obj, prop = prop })
    obj[prop] = ACCENT
end
local function setAccent(color)
    ACCENT = color
    for _, b in ipairs(accentBinds) do
        TweenService:Create(b.obj, TweenInfo.new(0.25), { [b.prop] = color }):Play()
    end
end

local TI   = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TIF  = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

----------------------------------------------------------------------
-- ХЕЛПЕРЫ
----------------------------------------------------------------------
local function new(class, props, parent)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do inst[k] = v end
    if parent then inst.Parent = parent end
    return inst
end
local function corner(r, parent)
    return new("UICorner", { CornerRadius = UDim.new(0, r) }, parent)
end
local function stroke(parent, color, thickness, transparency)
    return new("UIStroke", {
        Color = color or C.STROKE,
        Thickness = thickness or 1,
        Transparency = transparency or 0.55,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, parent)
end
local function pad(parent, t, b, l, r)
    return new("UIPadding", {
        PaddingTop = UDim.new(0, t or 0), PaddingBottom = UDim.new(0, b or 0),
        PaddingLeft = UDim.new(0, l or 0), PaddingRight = UDim.new(0, r or 0),
    }, parent)
end
local function label(parent, text, size, color, props)
    local p = {
        BackgroundTransparency = 1,
        Text = text, TextSize = size or 14, Font = Enum.Font.Gotham,
        TextColor3 = color or C.TEXT,
    }
    for k, v in pairs(props or {}) do p[k] = v end
    return new("TextLabel", p, parent)
end

local function draggable(frame, handle)
    handle = handle or frame
    local dragging, dragStart, startPos = false, nil, nil
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging, dragStart, startPos = true, input.Position, frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
end

----------------------------------------------------------------------
-- КОРЕНЬ GUI
----------------------------------------------------------------------
local gui = new("ScreenGui", {
    Name = "EtaMenu", ResetOnSpawn = false, IgnoreGuiInset = true,
    DisplayOrder = 999, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, PlayerGui)

-- затемнение фона
local dim = new("Frame", {
    Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0),
    BackgroundTransparency = 1, Visible = false,
}, gui)
local dimScale = new("UIScale", {}, dim)

-- корень меню
local root = new("Frame", {
    Name = "Root", AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.52),
    Size = UDim2.fromOffset(880, 580),
    BackgroundTransparency = 1, Visible = false,
}, gui)
local rootScale = new("UIScale", { Scale = 1 }, root)

-- адаптивный масштаб под разрешение
local function fitToViewport()
    local vp = workspace.CurrentCamera.ViewportSize
    local s = math.min(vp.X / 1000, vp.Y / 680, 1)
    dimScale.Scale = 1
    rootScale.Scale = s * (rootScale.Scale > 0 and 1 or 1)
    return s
end
fitToViewport()

----------------------------------------------------------------------
-- ВЕРХНИЙ ЭКРАННЫЙ HUD (как в видео: Eta • FPS • часы • SUPPORT)
----------------------------------------------------------------------
local hudPill = new("Frame", {
    Position = UDim2.fromOffset(16, 14), Size = UDim2.fromOffset(210, 34),
    BackgroundColor3 = C.PANEL, BackgroundTransparency = 0.25,
}, gui)
corner(17, hudPill); stroke(hudPill)
table.insert(glassBinds, hudPill)
local hudIcon = label(hudPill, "η", 18, ACCENT, {
    Position = UDim2.fromOffset(12, 0), Size = UDim2.fromOffset(22, 34),
    Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Center,
})
bindAccent(hudIcon, "TextColor3")
local hudEta = label(hudPill, "Eta", 14, C.TEXT, {
    Position = UDim2.fromOffset(38, 0), Size = UDim2.fromOffset(40, 34),
    Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left,
})
local hudDot = new("Frame", {
    Position = UDim2.fromOffset(84, 15), Size = UDim2.fromOffset(6, 6),
    BackgroundColor3 = C.GOOD, BorderSizePixel = 0,
}, hudPill)
corner(3, hudDot)
local hudFps = label(hudPill, "60 FPS", 13, C.SUB, {
    Position = UDim2.fromOffset(96, 0), Size = UDim2.fromOffset(56, 34),
    TextXAlignment = Enum.TextXAlignment.Left,
})
local hudClock = label(hudPill, "16:57", 13, C.SUB, {
    Position = UDim2.fromOffset(156, 0), Size = UDim2.fromOffset(48, 34),
    TextXAlignment = Enum.TextXAlignment.Left,
})

local support = new("Frame", {
    AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -18, 0, 12),
    Size = UDim2.fromOffset(150, 38), BackgroundTransparency = 1,
}, gui)
local supIcon = new("Frame", {
    Position = UDim2.fromOffset(96, 3), Size = UDim2.fromOffset(30, 30),
    BackgroundColor3 = C.PANEL, BackgroundTransparency = 0.2,
}, support)
corner(15, supIcon); stroke(supIcon)
label(supIcon, "η", 16, ACCENT, {
    Size = UDim2.fromScale(1, 1), Font = Enum.Font.GothamBold,
})
label(support, "SUPPORT", 15, C.TEXT, {
    Position = UDim2.fromOffset(0, 0), Size = UDim2.fromOffset(94, 36),
    Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Right,
})

----------------------------------------------------------------------
-- ПЛАВАЮЩАЯ КНОПКА "η"  (вращающееся кольцо + орбитальная искра)
----------------------------------------------------------------------
local floatBtn = new("Frame", {
    Name = "EtaOrb", AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.42, 0.56),
    Size = UDim2.fromOffset(96, 96), BackgroundTransparency = 1,
}, gui)
local orbHit = new("TextButton", {
    Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "",
}, floatBtn)
local orbRing = new("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(84, 84), BackgroundTransparency = 1,
}, floatBtn)
corner(42, orbRing)
local orbStroke = stroke(orbRing, ACCENT, 2, 0.15)
bindAccent(orbStroke, "Color")
local orbGrad = new("UIGradient", {
    Color = ColorSequence.new(ACCENT, Color3.fromRGB(255, 255, 255)),
    Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.9),
        NumberSequenceKeypoint.new(0.5, 0),
        NumberSequenceKeypoint.new(1, 0.9),
    }),
}, orbRing)
local orbCore = new("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(58, 58), BackgroundColor3 = C.PANEL,
    BackgroundTransparency = 0.15,
}, floatBtn)
corner(29, orbCore); stroke(orbCore)
table.insert(glassBinds, orbCore)
local orbEta = label(orbCore, "η", 30, C.TEXT, {
    Size = UDim2.fromScale(1, 1), Font = Enum.Font.GothamBold,
})
local spark = new("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(7, 7),
    BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 5,
}, floatBtn)
corner(3.5, spark)

local ringAngle, sparkAngle = 0, 0
RunService.RenderStepped:Connect(function(dt)
    ringAngle  = (ringAngle  + dt * 120) % 360
    sparkAngle = (sparkAngle + dt * 200) % 360
    orbGrad.Rotation = ringAngle
    local rad = math.rad(sparkAngle)
    local r = 42
    spark.Position = UDim2.new(0.5, math.cos(rad) * r, 0.5, math.sin(rad) * r)
    spark.BackgroundTransparency = 0.25 + 0.35 * (math.sin(rad) * 0.5 + 0.5)
end)

----------------------------------------------------------------------
-- ГЛАВНАЯ ПАНЕЛЬ (стекло)
----------------------------------------------------------------------
local panel = new("Frame", {
    Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.PANEL,
    BackgroundTransparency = 0.22, ClipsDescendants = true,
}, root)
corner(22, panel); stroke(panel, C.STROKE, 1, 0.45)
table.insert(glassBinds, panel)
new("UIGradient", {
    Color = ColorSequence.new(Color3.fromRGB(40, 34, 68), Color3.fromRGB(18, 15, 32)),
    Transparency = NumberSequence.new(0.15),
    Rotation = 115,
}, panel)
local panelGroup = new("CanvasGroup", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, panel)

-- шапка
local header = new("Frame", {
    Size = UDim2.new(1, 0, 0, 64), BackgroundTransparency = 1,
}, panelGroup)
local logoOrb = new("Frame", {
    Position = UDim2.fromOffset(22, 14), Size = UDim2.fromOffset(36, 36),
    BackgroundColor3 = C.CARD, BackgroundTransparency = 0.1,
}, header)
corner(18, logoOrb); stroke(logoOrb)
label(logoOrb, "η", 22, ACCENT, {
    Size = UDim2.fromScale(1, 1), Font = Enum.Font.GothamBold,
})
label(header, "Eta", 20, C.TEXT, {
    Position = UDim2.fromOffset(68, 10), Size = UDim2.fromOffset(120, 24),
    Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left,
})
label(header, "OXIDE · SURVIVAL ISLAND", 11, C.SUB, {
    Position = UDim2.fromOffset(68, 34), Size = UDim2.fromOffset(220, 16),
    TextXAlignment = Enum.TextXAlignment.Left,
})

local connectedPill = new("Frame", {
    AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -58, 0, 16),
    Size = UDim2.fromOffset(86, 30), BackgroundColor3 = C.CARD,
    BackgroundTransparency = 0.25,
}, header)
corner(15, connectedPill); stroke(connectedPill)
local connDot = new("Frame", {
    Position = UDim2.fromOffset(10, 12), Size = UDim2.fromOffset(6, 6),
    BackgroundColor3 = C.GOOD, BorderSizePixel = 0,
}, connectedPill)
corner(3, connDot)
label(connectedPill, "متصل", 13, C.TEXT, {
    Position = UDim2.fromOffset(20, 0), Size = UDim2.fromOffset(60, 30),
    TextXAlignment = Enum.TextXAlignment.Left,
})
local closeBtn = new("TextButton", {
    AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 16),
    Size = UDim2.fromOffset(30, 30), BackgroundColor3 = C.CARD,
    BackgroundTransparency = 0.3, AutoButtonColor = false, Text = "",
}, header)
corner(15, closeBtn); stroke(closeBtn)
label(closeBtn, "✕", 14, C.SUB, { Size = UDim2.fromScale(1, 1) })

-- подвал
label(panelGroup, "ETA · v2.8 · Eta28", 11, C.SUB, {
    Position = UDim2.new(0, 22, 1, -26), Size = UDim2.fromOffset(180, 16),
    TextXAlignment = Enum.TextXAlignment.Left,
})

draggable(root, header)

----------------------------------------------------------------------
-- БОКОВАЯ ПАНЕЛЬ (справа — RTL-стиль как в видео: вкладки справа)
----------------------------------------------------------------------
local sidebar = new("Frame", {
    AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 74),
    Size = UDim2.fromOffset(212, 440), BackgroundColor3 = C.PANEL2,
    BackgroundTransparency = 0.35,
}, panelGroup)
corner(16, sidebar); stroke(sidebar)
table.insert(glassBinds, sidebar)
local sideList = new("Frame", {
    Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
}, sidebar)
pad(sideList, 10, 10, 8, 8)
new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, sideList)

local TABS = {
    { id = "general", icon = "◫", name = "نظرة عامة"  },
    { id = "features",icon = "⚡", name = "المميزات"   },
    { id = "visuals", icon = "◉", name = "المرئيات"   },
    { id = "aim",     icon = "◎", name = "التصويب"    },
    { id = "models",  icon = "⬡", name = "النماذج"    },
    { id = "configs", icon = "▤", name = "التكوينات"  },
    { id = "settings",icon = "⚙", name = "الإعدادات"  },
}
local tabButtons, pages = {}, {}
local activeTab = "general"

local contentHost = new("Frame", {
    Position = UDim2.fromOffset(14, 74), Size = UDim2.new(1, -254, 0, 484),
    BackgroundTransparency = 1,
}, panelGroup)

local function selectTab(id)
    activeTab = id
    for tabId, btn in pairs(tabButtons) do
        local sel = tabId == id
        TweenService:Create(btn, TI, {
            BackgroundTransparency = sel and 0.1 or 1,
        }):Play()
        TweenService:Create(btn._bar, TI, {
            BackgroundTransparency = sel and 0 or 1,
        }):Play()
        TweenService:Create(btn._name, TI, { TextColor3 = sel and C.TEXT or C.SUB }):Play()
    end
    for tabId, page in pairs(pages) do
        if tabId == id then
            page.Visible = true
            page.Position = UDim2.fromOffset(0, 8)
            TweenService:Create(page, TI, {
                GroupTransparency = 0,
            }):Play()
            TweenService:Create(page, TI, { Position = UDim2.fromOffset(0, 0) }):Play()
        else
            page.Visible = false
            page.GroupTransparency = 1
        end
    end
end

do
    for i, tab in ipairs(TABS) do
        local btn = new("TextButton", {
            LayoutOrder = i, Size = UDim2.new(1, 0, 0, 46),
            BackgroundColor3 = C.CARD, BackgroundTransparency = 1,
            AutoButtonColor = false, Text = "",
        }, sideList)
        corner(12, btn)
        local bar = new("Frame", {
            Position = UDim2.fromOffset(0, 10), Size = UDim2.fromOffset(3, 26),
            BackgroundColor3 = ACCENT, BackgroundTransparency = 1, BorderSizePixel = 0,
        }, btn)
        corner(2, bar); bindAccent(bar, "BackgroundColor3")
        local ic = label(btn, tab.icon, 16, C.SUB, {
            Position = UDim2.fromOffset(14, 0), Size = UDim2.fromOffset(24, 46),
            TextXAlignment = Enum.TextXAlignment.Center,
        })
        local nm = label(btn, tab.name, 15, C.SUB, {
            Position = UDim2.fromOffset(46, 0), Size = UDim2.new(1, -56, 1, 0),
            TextXAlignment = Enum.TextXAlignment.Left,
        })
        btn._bar, btn._name, btn._icon = bar, nm, ic
        tabButtons[tab.id] = btn
        btn.MouseButton1Click:Connect(function() selectTab(tab.id) end)

        local page = new("CanvasGroup", {
            Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
            Visible = false, GroupTransparency = 1,
        }, contentHost)
        local list = new("Frame", {
            Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
        }, page)
        pad(list, 2, 8, 2, 8)
        new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, list)
        pages[tab.id] = page
        page._list = list
    end
end

local pageOrder = 0
local function nextOrder()
    pageOrder += 1
    return pageOrder
end

----------------------------------------------------------------------
-- КОМПОНЕНТЫ: секция / карточка / тумблер / слайдер / сегмент / кнопка
----------------------------------------------------------------------
local State = {}   -- реестр для конфигов: {get=fn,set=fn}

local function section(parent, title, sub)
    local f = new("Frame", {
        LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, sub and 44 or 28),
        BackgroundTransparency = 1,
    }, parent)
    local d = new("Frame", {
        Position = UDim2.fromOffset(2, 8), Size = UDim2.fromOffset(8, 8),
        BackgroundColor3 = ACCENT, BorderSizePixel = 0,
    }, f)
    corner(2, d); bindAccent(d, "BackgroundColor3")
    local t = label(f, title, 16, C.TEXT, {
        Position = UDim2.fromOffset(16, 2), Size = UDim2.new(1, -20, 0, 20),
        Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left,
    })
    if sub then
        label(f, sub, 12, C.SUB, {
            Position = UDim2.fromOffset(16, 22), Size = UDim2.new(1, -20, 0, 18),
            TextXAlignment = Enum.TextXAlignment.Left,
        })
    end
    return f
end

local function card(parent, height)
    local f = new("Frame", {
        LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, height or 56),
        BackgroundColor3 = C.CARD, BackgroundTransparency = 0.35,
    }, parent)
    corner(14, f); stroke(f)
    table.insert(glassBinds, f)
    return f
end

local function makeToggle(parent, text, sub, default, callback, key)
    local row = card(parent, sub and 62 or 52)
    local sw = new("Frame", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0),
        Size = UDim2.fromOffset(46, 26), BackgroundColor3 = C.PANEL2,
        BorderSizePixel = 0,
    }, row)
    corner(13, sw); stroke(sw)
    local knob = new("Frame", {
        Position = UDim2.fromOffset(3, 3), Size = UDim2.fromOffset(20, 20),
        BackgroundColor3 = C.SUB, BorderSizePixel = 0,
    }, sw)
    corner(10, knob)

    local title = label(row, text, 14, C.TEXT, {
        Position = UDim2.fromOffset(16, sub and 8 or 0), Size = UDim2.new(1, -80, 0, sub and 20 or 52),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = sub and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center,
    })
    if sub then
        label(row, sub, 11, C.SUB, {
            Position = UDim2.fromOffset(16, 32), Size = UDim2.new(1, -80, 0, 22),
            TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
        })
    end

    local value = default and true or false
    local function render(anim)
        local ti = anim and TIF or TweenInfo.new(0)
        TweenService:Create(knob, ti, {
            Position = UDim2.fromOffset(value and 23 or 3, 3),
            BackgroundColor3 = value and Color3.new(1, 1, 1) or C.SUB,
        }):Play()
        TweenService:Create(sw, ti, {
            BackgroundColor3 = value and ACCENT or C.PANEL2,
        }):Play()
    end
    local hit = new("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "" }, row)
    hit.MouseButton1Click:Connect(function()
        value = not value
        render(true)
        if callback then task.spawn(callback, value) end
    end)
    render(false)

    if key then
        table.insert(State, {
            key = key,
            get = function() return value end,
            set = function(v) value = v and true or false; render(true);
                if callback then task.spawn(callback, value) end end,
        })
    end
    return row
end

local function makeSlider(parent, text, sub, min, max, default, decimals, suffix, callback, key)
    local row = card(parent, 64)
    label(row, text, 14, C.TEXT, {
        Position = UDim2.fromOffset(16, 8), Size = UDim2.new(1, -100, 0, 20),
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    if sub then
        label(row, sub, 11, C.SUB, {
            Position = UDim2.fromOffset(16, 26), Size = UDim2.new(1, -100, 0, 16),
            TextXAlignment = Enum.TextXAlignment.Left,
        })
    end
    local valueLabel = label(row, "", 13, C.SUB, {
        AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 8),
        Size = UDim2.fromOffset(70, 18), TextXAlignment = Enum.TextXAlignment.Right,
        Font = Enum.Font.GothamBold,
    })
    local bubble = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0, 0, 0, 26),
        Size = UDim2.fromOffset(44, 22), BackgroundColor3 = ACCENT,
        BackgroundTransparency = 1, ZIndex = 3,
    }, row)
    corner(11, bubble); bindAccent(bubble, "BackgroundColor3")
    local bubbleText = label(bubble, "", 12, Color3.new(0, 0, 0), {
        Size = UDim2.fromScale(1, 1), Font = Enum.Font.GothamBold, ZIndex = 4,
        TextTransparency = 1,
    })

    local track = new("Frame", {
        Position = UDim2.fromOffset(16, 46), Size = UDim2.new(1, -32, 0, 6),
        BackgroundColor3 = C.PANEL2, BorderSizePixel = 0,
    }, row)
    corner(3, track)
    local fill = new("Frame", {
        Size = UDim2.fromScale(0, 1), BackgroundColor3 = ACCENT, BorderSizePixel = 0,
    }, track)
    corner(3, fill); bindAccent(fill, "BackgroundColor3")
    local thumb = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.fromOffset(14, 14), BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0, ZIndex = 2,
    }, track)
    corner(7, thumb)

    local value = default
    local function render(anim)
        local a = (value - min) / (max - min)
        local ti = anim and TIF or TweenInfo.new(0)
        TweenService:Create(fill, ti, { Size = UDim2.fromScale(a, 1) }):Play()
        TweenService:Create(thumb, ti, { Position = UDim2.new(a, 0, 0.5, 0) }):Play()
        local txt = string.format("%." .. (decimals or 0) .. "f", value) .. (suffix or "")
        valueLabel.Text = txt
        bubbleText.Text = txt
        bubble.Position = UDim2.new(a, 0, 0, 26)
    end
    local dragging = false
    local function updateFromX(x)
        local a = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local raw = min + (max - min) * a
        local mult = 10 ^ (decimals or 0)
        value = math.floor(raw * mult + 0.5) / mult
        render(false)
        if callback then task.spawn(callback, value) end
    end
    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            TweenService:Create(bubble, TIF, { BackgroundTransparency = 0 }):Play()
            TweenService:Create(bubbleText, TIF, { TextTransparency = 0 }):Play()
            updateFromX(input.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
            updateFromX(input.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            if dragging then
                dragging = false
                TweenService:Create(bubble, TIF, { BackgroundTransparency = 1 }):Play()
                TweenService:Create(bubbleText, TIF, { TextTransparency = 1 }):Play()
            end
        end
    end)
    render(false)

    if key then
        table.insert(State, {
            key = key,
            get = function() return value end,
            set = function(v) value = math.clamp(v, min, max); render(true);
                if callback then task.spawn(callback, value) end end,
        })
    end
    return row
end

local function makeSegment(parent, options, selected, callback, key)
    local row = card(parent, 48)
    local holder = new("Frame", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.fromOffset(#options * 84, 32), BackgroundColor3 = C.PANEL2,
        BorderSizePixel = 0,
    }, row)
    corner(10, holder); stroke(holder)
    local current = selected or 1
    local selPill = new("Frame", {
        Position = UDim2.fromOffset((current - 1) * 84 + 3, 3),
        Size = UDim2.fromOffset(78, 26), BackgroundColor3 = ACCENT, BorderSizePixel = 0,
    }, holder)
    corner(8, selPill); bindAccent(selPill, "BackgroundColor3")
    for i, opt in ipairs(options) do
        local b = new("TextButton", {
            Position = UDim2.fromOffset((i - 1) * 84, 0), Size = UDim2.fromOffset(84, 32),
            BackgroundTransparency = 1, Text = opt, Font = Enum.Font.Gotham,
            TextSize = 12, TextColor3 = C.TEXT, AutoButtonColor = false,
        }, holder)
        b.ZIndex = 3
        b.MouseButton1Click:Connect(function()
            current = i
            TweenService:Create(selPill, TI, {
                Position = UDim2.fromOffset((i - 1) * 84 + 3, 3),
            }):Play()
            if callback then task.spawn(callback, i, opt) end
        end)
    end
    if key then
        table.insert(State, {
            key = key,
            get = function() return current end,
            set = function(v) current = v end,
        })
    end
    return row
end

local function makeButton(parent, text, primary, callback)
    local b = new("TextButton", {
        LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, 42),
        BackgroundColor3 = primary and ACCENT or C.CARD,
        BackgroundTransparency = primary and 0 or 0.3,
        AutoButtonColor = false, Text = text, Font = Enum.Font.GothamBold,
        TextSize = 14, TextColor3 = primary and Color3.new(0, 0, 0) or C.TEXT,
    }, parent)
    corner(12, b); stroke(b)
    if primary then bindAccent(b, "BackgroundColor3") end
    b.MouseButton1Click:Connect(function()
        TweenService:Create(b, TIF, { Size = UDim2.new(1, -6, 0, 40) }):Play()
        task.delay(0.1, function()
            TweenService:Create(b, TIF, { Size = UDim2.new(1, 0, 0, 42) }):Play()
        end)
        if callback then task.spawn(callback) end
    end)
    return b
end

local function makeChipRow(parent, chips, sub)
    local f = new("Frame", {
        LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, 30),
        BackgroundTransparency = 1,
    }, parent)
    local lay = new("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder,
    }, f)
    for i, chip in ipairs(chips) do
        local dotColor = chip.dot or C.GOOD
        local c = new("Frame", {
            LayoutOrder = i, Size = UDim2.fromOffset(0, 26),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundColor3 = C.CARD, BackgroundTransparency = 0.4,
        }, f)
        corner(13, c); stroke(c, C.STROKE, 1, 0.7)
        local dot = new("Frame", {
            Position = UDim2.fromOffset(10, 10), Size = UDim2.fromOffset(6, 6),
            BackgroundColor3 = dotColor, BorderSizePixel = 0,
        }, c)
        corner(3, dot)
        label(c, chip.text, 12, C.SUB, {
            Position = UDim2.fromOffset(22, 0), Size = UDim2.fromOffset(#chip.text * 7 + 14, 26),
            TextXAlignment = Enum.TextXAlignment.Left,
        })
        if sub then
            label(c, chip.sub or "", 10, C.SUB, {
                Position = UDim2.new(1, -60, 0, 0), Size = UDim2.fromOffset(54, 26),
                TextXAlignment = Enum.TextXAlignment.Right,
            })
        end
    end
    return f
end

local function spacer(parent, h)
    return new("Frame", {
        LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, h or 8),
        BackgroundTransparency = 1,
    }, parent)
end

-- скролл для длинных страниц
local function scrollify(list)
    local page = list.Parent
    local sc = new("ScrollingFrame", {
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
        BorderSizePixel = 0, ScrollBarThickness = 3,
        ScrollBarImageColor3 = ACCENT, CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
    }, page)
    list.Parent = sc
    list.Size = UDim2.new(1, -8, 0, 0)
    list.AutomaticSize = Enum.AutomaticSize.Y
    return sc
end

----------------------------------------------------------------------
-- СТРАНИЦА 1 · نظرة عامة (Обзор)
----------------------------------------------------------------------
do
    local L = pages.general._list
    section(L, "نظرة عامة", "اللوحة في لمحة، وبعض التبديلات في متناول يدك")
    local about = card(L, 96)
    label(about, "Eta جاهز", 15, C.TEXT, {
        Position = UDim2.fromOffset(16, 10), Size = UDim2.new(1, -32, 0, 20),
        Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left,
    })
    label(about,
        "كشف الجدران والتصويب التلقائي وراجحة القاتل وتحديثات اللعبة Oxide: Survival Island. تبديلات السريعة لتأصيل وعلى الذكرى السريعة فوق اللعبة.",
        12, C.SUB, {
        Position = UDim2.fromOffset(16, 32), Size = UDim2.new(1, -32, 0, 56),
        TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
    })
    makeChipRow(L, {
        { text = "داخل اللعبة",       sub = "داخل اللعبة" },
        { text = "بدون تكوين",       dot = C.SUB },
        { text = "الاختراق نشط" },
        { text = "تشغيل 00:59", dot = ACCENT_DIM },
    })

    local statusRow = new("Frame", {
        LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, 92),
        BackgroundTransparency = 1,
    }, L)
    new("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, statusRow)
    local function statCard(title, value)
        local c = new("Frame", {
            LayoutOrder = nextOrder(), Size = UDim2.new(0.333, -6, 1, 0),
            BackgroundColor3 = C.CARD, BackgroundTransparency = 0.35,
        }, statusRow)
        corner(14, c); stroke(c)
        table.insert(glassBinds, c)
        label(c, title, 12, C.SUB, {
            Position = UDim2.fromOffset(14, 12), Size = UDim2.new(1, -28, 0, 16),
            TextXAlignment = Enum.TextXAlignment.Left,
        })
        label(c, value, 22, C.TEXT, {
            Position = UDim2.fromOffset(14, 34), Size = UDim2.new(1, -28, 0, 34),
            Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left,
        })
        return c
    end
    local fpsCard = statCard("معدل الإطارات", "60")
    statCard("في الرؤية", "—")
    statCard("معدل", "4 / 8")
    _G.__etaFpsLabel = fpsCard:FindFirstChildWhichIsA("TextLabel", true)

    section(L, "الحالة")
    local qf = new("Frame", {
        LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, 96),
        BackgroundTransparency = 1,
    }, L)
    new("UIGridLayout", {
        CellSize = UDim2.new(0.25, -6, 0, 88), CellPadding = UDim2.fromOffset(8, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, qf)
    local quickDefs = {
        { "كشف الجدران", "◉", "wallhack" },
        { "التصويب التلقائي", "◎", "aimassist" },
        { "التصويب الصامت", "✦", "silentaim" },
        { "إعادة تعبئة سريعة", "↻", "fastreload" },
    }
    for i, def in ipairs(quickDefs) do
        local b = new("TextButton", {
            LayoutOrder = i, BackgroundColor3 = C.CARD, BackgroundTransparency = 0.35,
            AutoButtonColor = false, Text = "",
        }, qf)
        corner(14, b); stroke(b)
        table.insert(glassBinds, b)
        local ic = label(b, def[2], 20, ACCENT, {
            Size = UDim2.new(1, 0, 0, 44), Font = Enum.Font.GothamBold,
        })
        bindAccent(ic, "TextColor3")
        label(b, def[1], 11, C.SUB, {
            Position = UDim2.fromOffset(4, 46), Size = UDim2.new(1, -8, 0, 36),
            TextWrapped = true,
        })
        b.MouseButton1Click:Connect(function()
            TweenService:Create(b, TIF, { BackgroundTransparency = 0.1 }):Play()
            task.delay(0.35, function()
                TweenService:Create(b, TIF, { BackgroundTransparency = 0.35 }):Play()
            end)
            --[[ HOOK: def[3] — быстрый переключатель ]]
        end)
    end
    spacer(L, 4)
    scrollify(L)
end

----------------------------------------------------------------------
-- СТРАНИЦА 2 · المميزات (Возможности)
----------------------------------------------------------------------
do
    local L = pages.features._list
    section(L, "المميزات", "القتال والتحكم وجمع الموارد")
    makeToggle(L, "القتال", nil, true, nil, "combat")
    makeToggle(L, "بدون انتشار", "كل طلقة تذهب لنقطة مؤشر التصويب", true, function(v)
        --[[ HOOK: no-spread ]]
    end, "nospread")
    makeToggle(L, "بدون ارتداد", "نقطة للغة وتراجع الإطلاق", true, nil, "norecoil")
    makeToggle(L, "إعادة تعبئة سريعة", "إعادة تعبئة فورية بلا حركة", true, nil, "fastreload2")
    makeToggle(L, "إطلاق سريع", "إطلاق أسرع مما يسمح به السلاح", false, nil, "rapidfire")

    section(L, "الكاميرا")
    makeToggle(L, "FOV مخصص", "معالجة الرؤية (FOV)", false, function() end, "fovtoggle")
    makeSlider(L, "معدل الرؤية (FOV)", nil, 60, 120, 90, 0, "°", function(v)
        local cam = workspace.CurrentCamera
        if cam then cam.FieldOfView = v end
    end, "fov")
    makeToggle(L, "كاميرا حرة", "تحرك الكاميرا حول نفسها", false, nil, "freecam")
    makeSlider(L, "سرعة الحركة", nil, 1, 30, 10, 1, " و/ث", nil, "movespeed")
    makeToggle(L, "مظهر الشخص الثالث", "على عدم من الشخص الثالث", false, nil, "thirdperson")
    makeSlider(L, "المسافة", nil, 1, 10, 3, 1, " م", nil, "distance")
    makeSlider(L, "معدل الإطلاق", nil, 1, 5, 2, 1, "x", nil, "firerate")
    makeSlider(L, "الساحة", nil, 0, 30, 12, 0, "", nil, "radius")
    makeToggle(L, "جمع تلقائي", nil, false, nil, "autocollect")
    makeSegment(L, { "أرضي", "جوي", "واجهي" }, 1, nil, "model_move")
    makeSegment(L, { "وقت الفريم", "قريب", "بعيد" }, 1, nil, "frametime")
    makeToggle(L, "حجم تلقائي", nil, false, nil, "autosize")
    makeToggle(L, "إطلاق سريع", "تفعيل أسرع مما يسمح به السلاح", false, nil, "rapid2")
    scrollify(L)
end

----------------------------------------------------------------------
-- СТРАНИЦА 3 · المرئيات (Визуалы) — с превью ESP
----------------------------------------------------------------------
do
    local L = pages.visuals._list
    section(L, "المرئيات", "كشف الجدران للاعبين والحيوانات وموارد الخريط")

    local body = new("Frame", {
        LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, 300),
        BackgroundTransparency = 1,
    }, L)
    local preview = new("Frame", {
        Size = UDim2.fromOffset(330, 280), BackgroundColor3 = Color3.fromRGB(8, 8, 14),
        BackgroundTransparency = 0.1,
    }, body)
    corner(14, preview); stroke(preview)
    -- фон превью: «ночная» сцена
    new("UIGradient", {
        Color = ColorSequence.new(Color3.fromRGB(24, 18, 44), Color3.fromRGB(6, 6, 12)),
        Rotation = 90,
    }, preview)
    label(preview, "معاينة", 12, C.SUB, {
        Position = UDim2.fromOffset(10, 6), Size = UDim2.fromOffset(80, 16),
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    -- макетные «игроки»: боксы, трассеры, скелет
    local function fakePlayer(name, x, y, color, hp)
        local box = new("Frame", {
            Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(34, 70),
            BackgroundTransparency = 1,
        }, preview)
        stroke(box, color, 1, 0.1)
        local tracer = new("Frame", {
            AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 1, 0),
            Size = UDim2.fromOffset(1, 90), BackgroundColor3 = color,
            BackgroundTransparency = 0.4, BorderSizePixel = 0,
        }, box)
        local hpBar = new("Frame", {
            Position = UDim2.fromOffset(-6, 0), Size = UDim2.fromOffset(2, 70),
            BackgroundColor3 = Color3.fromRGB(40, 40, 50), BorderSizePixel = 0,
        }, box)
        local hpFill = new("Frame", {
            AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1),
            Size = UDim2.fromScale(1, hp), BackgroundColor3 = C.GOOD, BorderSizePixel = 0,
        }, hpBar)
        local skel = new("Frame", {
            AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.18),
            Size = UDim2.fromOffset(1, 40), BackgroundColor3 = color,
            BackgroundTransparency = 0.35, BorderSizePixel = 0,
        }, box)
        label(box, name, 10, color, {
            Position = UDim2.fromOffset(-8, -16), Size = UDim2.fromOffset(50, 12),
            Font = Enum.Font.GothamBold,
        })
        local hpLbl = label(box, tostring(math.floor(hp * 100)), 9, C.SUB, {
            Position = UDim2.fromOffset(38, 0), Size = UDim2.fromOffset(24, 12),
            TextXAlignment = Enum.TextXAlignment.Left,
        })
        return box
    end
    fakePlayer("Nyx", 60, 120, Color3.fromRGB(255, 120, 120), 0.7)
    fakePlayer("Raven", 140, 100, Color3.fromRGB(255, 210, 110), 0.45)
    fakePlayer("Vex", 214, 130, Color3.fromRGB(120, 200, 255), 0.9)
    fakePlayer("Rook", 262, 112, Color3.fromRGB(255, 120, 160), 0.3)

    local right = new("Frame", {
        Position = UDim2.fromOffset(346, 0), Size = UDim2.new(1, -346, 1, 0),
        BackgroundTransparency = 1,
    }, body)
    pad(right, 0, 0, 0, 0)
    new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, right)
    local orderBase = pageOrder
    pageOrder = 0
    makeToggle(right, "معاينة", nil, true, nil, "vis_preview")
    makeToggle(right, "النار", "إبراز الأعداء والغنائم على الخريط", true, nil, "vis_fire")
    makeToggle(right, "إبراز", nil, true, nil, "vis_highlight")
    makeToggle(right, "الحيوانات والغنائم على الخريط", "من حواليك أهل المحيط", true, nil, "vis_animals")
    makeToggle(right, "جزيرة الحار", nil, true, nil, "vis_hot")
    makeToggle(right, "جزيرة الحام", "من حواليك أهل المحيط", true, nil, "vis_treasure")
    makeSlider(right, "تنبيه الجزيرة", "تحويل إلى الأحمر ويستل إلى داخل لعبة الجزيرة", 0, 100, 50, 0, " م", nil, "vis_island")
    makeSlider(right, "صبابة الشبية", nil, 0, 100, 50, 0, " م", nil, "vis_radius")
    makeToggle(right, "أشباح الظهور", "أشباح في وسط وخلف المدله", false, nil, "vis_ghosts")
    pageOrder = orderBase

    section(L, "النمط الخاص")
    makeSegment(L, { "عربي", "واضح" }, 1, nil, "vis_style")
    makeButton(L, "حذف عطل", false, nil)

    section(L, "النمط الخاص · الرسم")
    makeToggle(L, "الرسم فوق اللعبة", "تشغيل الرسوم فوق اللعبة", true, nil, "vis_draw")
    makeSegment(L, { "إظهار", "الدماء", "الحيوات" }, 1, nil, "vis_players")
    makeToggle(L, "لون الفريق", "عند الارتباط اقضي لكل فريق", true, nil, "vis_teamcolor")
    makeSlider(L, "العمق", nil, 0, 100, 95, 0, "%", nil, "vis_depth")
    makeSlider(L, "سماكة الخط", nil, 0.5, 3, 1, 1, "x", nil, "vis_thick")
    makeSlider(L, "الوهج", nil, 0, 1, 0.3, 1, "x", nil, "vis_glow")
    makeSlider(L, "نموذج الهيكل", nil, 0, 1, 0.3, 1, "x", nil, "vis_skeleton")
    makeToggle(L, "اللاعبون غير المتصلين", "حيث اللاعبين المتصلين مع عدم تمكن", true, nil, "vis_offline")
    makeToggle(L, "الشكل الذرة", "رسم الفريق", false, nil, "vis_atom")
    makeToggle(L, "روباي", "تفعيل عدم التبديل", false, nil, "vis_robay")
    scrollify(L)
end

----------------------------------------------------------------------
-- СТРАНИЦА 4 · التصويب (Прицел) — превью скопа
----------------------------------------------------------------------
do
    local L = pages.aim._list
    section(L, "التصويب", "التصويب التلقائي الأهداف ونقاط التصويب والإطلاق")

    local body = new("Frame", {
        LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, 300),
        BackgroundTransparency = 1,
    }, L)
    local scope = new("Frame", {
        Size = UDim2.fromOffset(280, 280), BackgroundColor3 = Color3.fromRGB(8, 8, 14),
        BackgroundTransparency = 0.1,
    }, body)
    corner(140, scope); stroke(scope)
    new("UIGradient", {
        Color = ColorSequence.new(Color3.fromRGB(22, 16, 40), Color3.fromRGB(6, 6, 12)),
        Rotation = 90,
    }, scope)
    label(scope, "معاينة", 12, C.SUB, {
        Position = UDim2.fromOffset(12, 8), Size = UDim2.fromOffset(80, 16),
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    -- перекрестие
    local cx = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(26, 1), BackgroundColor3 = C.TEXT,
        BackgroundTransparency = 0.3, BorderSizePixel = 0,
    }, scope)
    local cy = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(1, 26), BackgroundColor3 = C.TEXT,
        BackgroundTransparency = 0.3, BorderSizePixel = 0,
    }, scope)
    -- пунктирная цель
    for i = 0, 12 do
        local dot = new("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.56 + math.cos(i) * 0.10, 0.44 + math.sin(i * 1.7) * 0.12),
            Size = UDim2.fromOffset(4, 4), BackgroundColor3 = Color3.fromRGB(255, 90, 110),
            BorderSizePixel = 0,
        }, scope)
        corner(2, dot)
    end
    label(scope, "◀  Rook  ·  قدر  16  ▮▮▮▯  ▶", 11, Color3.fromRGB(255, 130, 140), {
        AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -14),
        Size = UDim2.fromOffset(230, 16),
    })
    -- пунктирный FOV-круг
    for i = 1, 40 do
        local a = i / 40 * math.pi * 2
        local dot = new("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5 + math.cos(a) * 0.38, 0.5 + math.sin(a) * 0.38),
            Size = UDim2.fromOffset(2, 2), BackgroundColor3 = ACCENT_DIM,
            BackgroundTransparency = 0.5, BorderSizePixel = 0,
        }, scope)
        corner(1, dot)
    end

    local right = new("Frame", {
        Position = UDim2.fromOffset(296, 0), Size = UDim2.new(1, -296, 1, 0),
        BackgroundTransparency = 1,
    }, body)
    new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, right)
    local orderBase = pageOrder
    pageOrder = 0
    makeToggle(right, "التصويب", "التصويب التلقائي الأهداف ونقاط التصويب", true, function(v)
        --[[ HOOK: aim assist — только в вашем собственном опыте ]]
    end, "aim_on")
    makeToggle(right, "الصويب العامة", "الميلايات تحلي بمو اقتران تبين الشاشة نابة", true, nil, "aim_fovvis")
    makeSegment(right, { "أثناء التصويب", "إطلاق", "دائما" }, 3, nil, "aim_mode")
    pageOrder = orderBase

    makeSlider(L, "محال الرؤية (FOV)", "المدى يحدد مدى نقومة دون المنادة", 10, 120, 60, 0, "°", nil, "aim_fov")
    makeSlider(L, "التنعيم", "المساعد عند ضبط مدى نقومة دون المنادة", 1, 20, 15, 1, "", nil, "aim_smooth")
    makeSlider(L, "فرصة الإصابة", "المصد، فقط لأدنى تحقيق عمدا", 0, 100, 100, 0, "%", nil, "aim_chance")
    spacer(L, 4)
    scrollify(L)
end

----------------------------------------------------------------------
-- СТРАНИЦА 5 · النماذج (Модели · VRM)
----------------------------------------------------------------------
do
    local L = pages.models._list
    section(L, "النماذج", "مدمج VRM لمظهر الشخص الثالث · أنت وحدك تابعا")

    local c = card(L, 150)
    local plus = new("Frame", {
        Position = UDim2.fromOffset(16, 16), Size = UDim2.fromOffset(110, 92),
        BackgroundColor3 = C.PANEL2, BackgroundTransparency = 0.2,
    }, c)
    corner(12, plus); stroke(plus)
    label(plus, "?", 40, C.SUB, {
        Size = UDim2.fromScale(1, 1), Font = Enum.Font.GothamBold,
    })
    label(c, "قيد الإرتداء", 14, C.TEXT, {
        Position = UDim2.fromOffset(142, 18), Size = UDim2.fromOffset(140, 20),
        Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left,
    })
    label(c, "بلا نموذج", 13, C.SUB, {
        Position = UDim2.fromOffset(142, 40), Size = UDim2.fromOffset(140, 18),
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    makeToggle(L, "نموذج مخصص", "اختيار منفرد؟ يرسم النموذج للحصول على ملف يساعد", false, nil, "vrm_custom")
    local btnRow = new("Frame", {
        LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, 48),
        BackgroundTransparency = 1,
    }, L)
    new("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, btnRow)
    local function inlineBtn(text, primary)
        local b = new("TextButton", {
            LayoutOrder = nextOrder(), Size = UDim2.new(0.5, -4, 1, 0),
            BackgroundColor3 = primary and ACCENT or C.CARD,
            BackgroundTransparency = primary and 0 or 0.3,
            AutoButtonColor = false, Text = text, Font = Enum.Font.GothamBold,
            TextSize = 13, TextColor3 = primary and Color3.new(0, 0, 0) or C.TEXT,
        }, btnRow)
        corner(12, b); stroke(b)
        if primary then bindAccent(b, "BackgroundColor3") end
        return b
    end
    inlineBtn("إعادة تحميل ⟳", false)
    inlineBtn("معاينة ◉", true)
    makeSegment(L, { "المكتبة", "الملف", "التعيين" }, 1, nil, "model_src")
    makeButton(L, "فتح", true, nil)
    scrollify(L)
end

----------------------------------------------------------------------
-- СТРАНИЦА 6 · التكوينات (Конфиги)
----------------------------------------------------------------------
do
    local L = pages.configs._list
    section(L, "التكوينات", "حفظ الإعدادات الكاملة والتعديل بينها ومشاركتها")

    local saved = {}
    local c = card(L, 92)
    local plusBtn = new("TextButton", {
        Position = UDim2.fromOffset(16, 18), Size = UDim2.fromOffset(56, 56),
        BackgroundColor3 = ACCENT, AutoButtonColor = false, Text = "+",
        Font = Enum.Font.GothamBold, TextSize = 26, TextColor3 = Color3.new(0, 0, 0),
    }, c)
    corner(14, plusBtn); bindAccent(plusBtn, "BackgroundColor3")
    label(c, "تكوين غير محفوظ", 15, C.TEXT, {
        Position = UDim2.fromOffset(86, 20), Size = UDim2.new(1, -180, 0, 20),
        Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left,
    })
    label(c, "1 تعديل غير الافتراضي · ليس لغير الافتراضي · ليس رفضاً · كوبر 2024", 11, C.SUB, {
        Position = UDim2.fromOffset(86, 42), Size = UDim2.new(1, -180, 0, 18),
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    local countLbl = label(c, "عدد محفوظ 0", 12, C.SUB, {
        AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 20),
        Size = UDim2.fromOffset(90, 18), TextXAlignment = Enum.TextXAlignment.Right,
    })

    local btnRow = new("Frame", {
        LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, 48),
        BackgroundTransparency = 1,
    }, L)
    new("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, btnRow)
    local function cfgBtn(text, primary, cb)
        local b = new("TextButton", {
            LayoutOrder = nextOrder(), Size = UDim2.new(0.333, -6, 1, 0),
            BackgroundColor3 = primary and ACCENT or C.CARD,
            BackgroundTransparency = primary and 0 or 0.3,
            AutoButtonColor = false, Text = text, Font = Enum.Font.GothamBold,
            TextSize = 13, TextColor3 = primary and Color3.new(0, 0, 0) or C.TEXT,
        }, btnRow)
        corner(12, b); stroke(b)
        if primary then bindAccent(b, "BackgroundColor3") end
        b.MouseButton1Click:Connect(cb)
        return b
    end

    local listCard = card(L, 170)
    label(listCard, "المكتبة", 14, C.SUB, {
        Position = UDim2.fromOffset(16, 10), Size = UDim2.fromOffset(120, 18),
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    local listHolder = new("Frame", {
        Position = UDim2.fromOffset(12, 34), Size = UDim2.new(1, -24, 1, -46),
        BackgroundColor3 = C.PANEL2, BackgroundTransparency = 0.3,
    }, listCard)
    corner(10, listHolder)
    local listLayout = new("UIListLayout", {
        Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder,
    }, listHolder)
    pad(listHolder, 6, 6, 6, 6)

    local function snapshot()
        local data = {}
        for _, s in ipairs(State) do data[s.key] = s.get() end
        return data
    end
    local function apply(data)
        for _, s in ipairs(State) do
            if data[s.key] ~= nil then s.set(data[s.key]) end
        end
    end
    local function refreshList()
        for _, ch in ipairs(listHolder:GetChildren()) do
            if ch:IsA("TextButton") then ch:Destroy() end
        end
        for i, cfg in ipairs(saved) do
            local item = new("TextButton", {
                LayoutOrder = i, Size = UDim2.new(1, 0, 0, 34),
                BackgroundColor3 = C.CARD, BackgroundTransparency = 0.3,
                AutoButtonColor = false, Text = "📁  " .. cfg.name,
                Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = C.TEXT,
            }, listHolder)
            corner(8, item)
            item.MouseButton1Click:Connect(function() apply(cfg.data) end)
        end
        countLbl.Text = "عدد محفوظ " .. #saved
    end
    cfgBtn("حفظ", true, function()
        table.insert(saved, { name = "تكوين " .. (#saved + 1), data = snapshot() })
        refreshList()
    end)
    cfgBtn("تراجع ⟳", false, function() refreshList() end)
    cfgBtn("الافتراضي ✕", false, function()
        for _, s in ipairs(State) do
            -- мягкий сброс: булевы выкл, числа — по умолчанию 0/среднее
            local v = s.get()
            if type(v) == "boolean" then s.set(false)
            elseif type(v) == "number" then s.set(v) end
        end
    end)
    scrollify(L)
end

----------------------------------------------------------------------
-- СТРАНИЦА 7 · الإعدادات (Настройки)
----------------------------------------------------------------------
do
    local L = pages.settings._list
    section(L, "الإعدادات", "مظهر القائمة واللغة والتكوينات")

    section(L, "المظهر")
    local swRow = new("Frame", {
        LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, 44),
        BackgroundTransparency = 1,
    }, L)
    new("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, swRow)
    local swatches = {
        Color3.fromRGB(178, 160, 255), Color3.fromRGB(120, 220, 220),
        Color3.fromRGB(255, 190, 110), Color3.fromRGB(255, 140, 190),
        Color3.fromRGB(110, 170, 255), Color3.fromRGB(240, 240, 245),
    }
    for i, col in ipairs(swatches) do
        local s = new("TextButton", {
            LayoutOrder = i, Size = UDim2.fromOffset(32, 32),
            BackgroundColor3 = col, AutoButtonColor = false, Text = "",
        }, swRow)
        corner(16, s); stroke(s, Color3.new(1, 1, 1), 1, 0.6)
        s.MouseButton1Click:Connect(function() setAccent(col) end)
    end

    section(L, "اللغة")
    local langRow = new("Frame", {
        LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, 110),
        BackgroundTransparency = 1,
    }, L)
    new("UIGridLayout", {
        CellSize = UDim2.new(0.333, -6, 0, 32), CellPadding = UDim2.fromOffset(6, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, langRow)
    for i, lang in ipairs({ "النظام", "English", "Русский", "Türkçe", "فارسی", "العربية", "中文", "日本?", "???" }) do
        local b = new("TextButton", {
            LayoutOrder = i, BackgroundColor3 = i == 1 and ACCENT or C.CARD,
            BackgroundTransparency = i == 1 and 0 or 0.35,
            AutoButtonColor = false, Text = lang, Font = Enum.Font.Gotham,
            TextSize = 12, TextColor3 = i == 1 and Color3.new(0, 0, 0) or C.TEXT,
        }, langRow)
        corner(8, b); stroke(b)
    end

    makeSlider(L, "عتامة اللوحة", "ضبط التعتيم على اللوحة عند التشغيل", 40, 100, 88, 0, "%", function(v)
        local t = 1 - v / 100
        for _, obj in ipairs(glassBinds) do
            if obj and obj.Parent then
                local base = (obj == dim) and 0.45 or 0.25
                obj.BackgroundTransparency = math.clamp(base + (t - 0.75) * 0.6, 0.02, 0.9)
            end
        end
    end, "ui_opacity")

    makeSlider(L, "حجم الواجهة", nil, 0.7, 1.4, 1, 2, "x", function(v)
        local base = fitToViewport()
        rootScale.Scale = base * v
    end, "ui_scale")

    makeSegment(L, { "حيوي", "عادي", "هادئ" }, 2, function(i)
        local styles = {
            TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            TweenInfo.new(0.45, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
        }
        TI, TIF = styles[i], styles[i]
    end, "ui_motion")

    makeToggle(L, "حساسات الأجزاء", "حساسات قائمة على حركة الفأرة", true, nil, "ui_partsense")
    makeSlider(L, "كثافة الجسيمات", nil, 0, 100, 60, 0, "%", nil, "ui_particles")
    makeToggle(L, "أثر النص", "حساسات ضد النص القائم", true, nil, "ui_texttrace")
    makeToggle(L, "تأثير الفر", "حساسات ضد التمرير عند تبديل", true, nil, "ui_hoverfx")

    local about = card(L, 92)
    local aOrb = new("Frame", {
        Position = UDim2.fromOffset(16, 22), Size = UDim2.fromOffset(48, 48),
        BackgroundColor3 = C.PANEL2, BackgroundTransparency = 0.2,
    }, about)
    corner(24, aOrb); stroke(aOrb)
    label(aOrb, "η", 26, ACCENT, {
        Size = UDim2.fromScale(1, 1), Font = Enum.Font.GothamBold,
    })
    label(about, "Eta", 16, C.TEXT, {
        Position = UDim2.fromOffset(76, 16), Size = UDim2.fromOffset(100, 20),
        Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left,
    })
    label(about,
        "كشف الجدران والتصويب التلقائي وراجحة القاتل وتحديث اللعبة Oxide: Survival Island.",
        11, C.SUB, {
        Position = UDim2.fromOffset(76, 38), Size = UDim2.new(1, -92, 0, 44),
        TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
    })
    label(about, "حول", 12, C.SUB, {
        AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 16),
        Size = UDim2.fromOffset(60, 16),
    })
    scrollify(L)
end

----------------------------------------------------------------------
-- ОТКРЫТИЕ / ЗАКРЫТИЕ / МИНИМИЗАЦИЯ
----------------------------------------------------------------------
local menuOpen = false
local minimized = false

local function setMenuOpen(open)
    menuOpen = open
    if open then
        root.Visible = true
        dim.Visible = true
        rootScale.Scale = (fitToViewport()) * 0.92
        panelGroup.GroupTransparency = 1
        TweenService:Create(dim, TI, { BackgroundTransparency = 0.45 }):Play()
        TweenService:Create(rootScale, TI, { Scale = fitToViewport() * 1 }):Play()
        TweenService:Create(panelGroup, TI, { GroupTransparency = 0 }):Play()
        selectTab(activeTab)
        TweenService:Create(floatBtn, TI, { Position = UDim2.fromScale(0.085, 0.5) }):Play()
    else
        TweenService:Create(dim, TI, { BackgroundTransparency = 1 }):Play()
        TweenService:Create(rootScale, TI, { Scale = fitToViewport() * 0.92 }):Play()
        TweenService:Create(panelGroup, TI, { GroupTransparency = 1 }):Play()
        TweenService:Create(floatBtn, TI, { Position = UDim2.fromScale(0.42, 0.56) }):Play()
        task.delay(0.26, function()
            if not menuOpen then root.Visible = false; dim.Visible = false end
        end)
    end
end

orbHit.MouseButton1Click:Connect(function() setMenuOpen(not menuOpen) end)
closeBtn.MouseButton1Click:Connect(function() setMenuOpen(false) end)
connectedPill.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        minimized = not minimized
        TweenService:Create(contentHost, TI, {
            Size = minimized and UDim2.new(1, -254, 0, 0) or UDim2.new(1, -254, 0, 484),
        }):Play()
        TweenService:Create(sidebar, TI, {
            Size = minimized and UDim2.fromOffset(212, 0) or UDim2.fromOffset(212, 440),
        }):Play()
    end
end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.Insert or input.KeyCode == Enum.KeyCode.RightControl then
        setMenuOpen(not menuOpen)
    end
end)

workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
    if menuOpen then rootScale.Scale = fitToViewport() end
end)

----------------------------------------------------------------------
-- FPS / ЧАСЫ (живые)
----------------------------------------------------------------------
local frames, lastTick = 0, os.clock()
RunService.RenderStepped:Connect(function()
    frames += 1
    local now = os.clock()
    if now - lastTick >= 1 then
        hudFps.Text = tostring(frames) .. " FPS"
        local fpsVal = frames
        local statLbl = _G.__etaFpsLabel
        if statLbl and statLbl:IsA("TextLabel") and statLbl.TextSize == 22 then
            statLbl.Text = tostring(fpsVal)
        end
        frames, lastTick = 0, now
    end
    hudClock.Text = os.date("%H:%M")
end)

selectTab("general")
setMenuOpen(true)

print("[Eta] v2.8 · Eta28 — меню загружено. Insert / RightControl — скрыть·показать.")
