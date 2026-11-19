-- ============================================================
-- BLOOD HUB — DA HOOD | V1.1
-- Arquivo único, universal, corrigido + Aimbot
-- Uso: loadstring(game:HttpGet("SUA_URL_RAW"))()
-- Toggle: RightShift
-- ============================================================

if _G.BloodHub and _G.BloodHub.Cleanup then
    pcall(_G.BloodHub.Cleanup)
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local LP = Players.LocalPlayer

local function getParent()
    if type(gethui) == "function" then
        local ok, h = pcall(gethui); if ok and h then return h end
    end
    if type(get_hidden_gui) == "function" then
        local ok, h = pcall(get_hidden_gui); if ok and h then return h end
    end
    local ok, cg = pcall(function() return game:GetService("CoreGui") end)
    if ok and cg then
        local t = Instance.new("Folder")
        local ok2 = pcall(function() t.Parent = cg end)
        t:Destroy()
        if ok2 then return cg end
    end
    return LP:WaitForChild("PlayerGui")
end

local Theme = {
    Bg  = Color3.fromRGB(18,18,18),
    Sf  = Color3.fromRGB(28,28,28),
    Ac  = Color3.fromRGB(180,20,20),
    AcB = Color3.fromRGB(220,30,30),
    Tx  = Color3.fromRGB(240,240,240),
    TxD = Color3.fromRGB(160,160,160),
    Ou  = Color3.fromRGB(50,50,50),
}

local H = {}
H.LP = LP
H.Parent = getParent()
H.Connections = {}

-- [CORRIGIDO] Estado persistente de movimento
H.WalkSpeedValue = 16
H.JumpPowerValue = 50

H.ESP = {
    enabled = false, range = 300, names = true, dist = true,
    mode = "ALL", selected = nil,
    outline = Color3.fromRGB(255,20,20), fill = Color3.fromRGB(255,0,0),
    active = {}, conns = {},
}

-- [NOVO] Estado do Aimbot
H.Aimbot = {
    enabled = false,
    target = nil,             -- jogador selecionado
    fov = 150,                -- raio em pixels (não usado p/ seleção manual, mas útil visual)
    smoothness = 0.15,        -- 0 = instantâneo, 1 = lento
    part = "Head",            -- "Head" ou "HumanoidRootPart"
    teamCheck = false,
    visibleCheck = false,
    wallCheck = true,
    active = false,           -- se está mirando agora
    conns = {},
}

function H.Track(conn)
    table.insert(H.Connections, conn)
    return conn
end

-- ========== UI HELPERS ==========
function H.Corner(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8)
    c.Parent = p
    return c
end

function H.Label(parent, text, order, color, size)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1,0,0,24)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = color or Theme.Tx
    l.TextSize = size or 14
    l.Font = Enum.Font.Gotham
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.LayoutOrder = order or 1
    l.Parent = parent
    return l
end

function H.Button(parent, text, order, color, cb)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1,0,0,34)
    b.BackgroundColor3 = color or Theme.Ac
    b.Text = text
    b.TextColor3 = Theme.Tx
    b.Font = Enum.Font.GothamBold
    b.TextSize = 12
    b.BorderSizePixel = 0
    b.LayoutOrder = order or 1
    b.Parent = parent
    H.Corner(b, 6)
    if cb then b.MouseButton1Click:Connect(cb) end
    return b
end

function H.Toggle(parent, text, default, order, cb)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1,0,0,32)
    b.BackgroundColor3 = default and Theme.Ac or Theme.Sf
    b.Text = text..": "..(default and "ON" or "OFF")
    b.TextColor3 = Theme.Tx
    b.Font = Enum.Font.Gotham
    b.TextSize = 13
    b.BorderSizePixel = 0
    b.LayoutOrder = order or 1
    b.Parent = parent
    H.Corner(b, 6)
    local s = default
    b.MouseButton1Click:Connect(function()
        s = not s
        b.BackgroundColor3 = s and Theme.Ac or Theme.Sf
        b.Text = text..": "..(s and "ON" or "OFF")
        if cb then cb(s) end
    end)
    return b
end

function H.Slider(parent, label, minV, maxV, default, order, cb)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1,0,0,50)
    f.BackgroundTransparency = 1
    f.LayoutOrder = order or 1
    f.Parent = parent

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,0,0,20)
    lbl.BackgroundTransparency = 1
    lbl.Text = label..": "..default
    lbl.TextColor3 = Theme.Tx
    lbl.TextSize = 13
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = f

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1,0,0,6)
    bar.Position = UDim2.new(0,0,0,30)
    bar.BackgroundColor3 = Theme.Sf
    bar.BorderSizePixel = 0
    bar.Parent = f
    H.Corner(bar, 3)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.fromScale((default-minV)/(maxV-minV), 1)
    fill.BackgroundColor3 = Theme.Ac
    fill.BorderSizePixel = 0
    fill.Parent = bar
    H.Corner(fill, 3)

    local drag = false
    local function upd(inp)
        local rx = math.clamp((inp.Position.X - bar.AbsolutePosition.X)/bar.AbsoluteSize.X, 0, 1)
        local v = math.floor(minV + (maxV-minV)*rx)
        fill.Size = UDim2.fromScale(rx, 1)
        lbl.Text = label..": "..v
        if cb then cb(v) end
    end
    bar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            drag = true; upd(i)
        end
    end)
    H.Track(UIS.InputChanged:Connect(function(i)
        if drag and i.UserInputType == Enum.UserInputType.MouseMovement then upd(i) end
    end))
    H.Track(UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end
    end))
    return f
end

-- ========== ESP CORE ==========
local function validChar(p)
    local c = p.Character
    if not c then return nil end
    local h = c:FindFirstChildOfClass("Humanoid")
    if not h or h.Health <= 0 then return nil end
    local r = c:FindFirstChild("HumanoidRootPart")
    if not r then return nil end
    return c, r
end

local function distTo(p)
    local mc = LP.Character
    if not mc then return math.huge end
    local mr = mc:FindFirstChild("HumanoidRootPart")
    if not mr then return math.huge end
    local _, tr = validChar(p)
    if not tr then return math.huge end
    return (mr.Position - tr.Position).Magnitude
end

local function shouldTrack(p)
    if p == LP then return false end
    if H.ESP.mode == "INDIVIDUAL" and p ~= H.ESP.selected then return false end
    if not validChar(p) then return false end
    return distTo(p) <= H.ESP.range
end

function H.AddESP(p)
    if H.ESP.active[p] then return end
    local c, r = validChar(p)
    if not c then return end

    local hl = Instance.new("Highlight")
    hl.Name = "BloodHub_HL"
    hl.Adornee = c
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.OutlineColor = H.ESP.outline
    hl.FillColor = H.ESP.fill
    hl.FillTransparency = 0.6
    hl.OutlineTransparency = 0
    hl.Parent = c

    local bb = Instance.new("BillboardGui")
    bb.Name = "BloodHub_BB"
    bb.Adornee = r
    bb.Size = UDim2.fromOffset(220,40)
    bb.StudsOffset = Vector3.new(0,2.5,0)
    bb.AlwaysOnTop = true
    bb.Parent = c

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.fromScale(1,1)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 14
    lbl.TextColor3 = Color3.new(1,1,1)
    lbl.TextStrokeTransparency = 0
    lbl.Text = ""
    lbl.Parent = bb

    H.ESP.active[p] = {hl = hl, bb = bb, lbl = lbl}
end

function H.RemoveESP(p)
    local d = H.ESP.active[p]
    if not d then return end
    pcall(function() d.hl:Destroy() end)
    pcall(function() d.bb:Destroy() end)
    H.ESP.active[p] = nil
end

local function refreshESP()
    for p in pairs(H.ESP.active) do
        if not shouldTrack(p) then H.RemoveESP(p) end
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if shouldTrack(p) and not H.ESP.active[p] then H.AddESP(p) end
    end
end

local function updateESP()
    for p, d in pairs(H.ESP.active) do
        local _, r = validChar(p)
        if not r then
            H.RemoveESP(p)
        else
            local dist = math.floor(distTo(p))
            local t = ""
            if H.ESP.names then t = p.Name end
            if H.ESP.dist then t = t..(t~="" and "  |  " or "")..dist.." studs" end
            d.lbl.Text = t
            d.lbl.Visible = H.ESP.names or H.ESP.dist
            d.hl.OutlineColor = H.ESP.outline
            d.hl.FillColor = H.ESP.fill
        end
    end
end

function H.StartESP()
    H.StopESP()
    table.insert(H.ESP.conns, Players.PlayerAdded:Connect(function(p)
        refreshESP()
        H.Track(p.CharacterAdded:Connect(function() task.wait(0.5); refreshESP() end))
    end))
    table.insert(H.ESP.conns, Players.PlayerRemoving:Connect(function(p) H.RemoveESP(p) end))
    table.insert(H.ESP.conns, LP.CharacterAdded:Connect(function()
        task.wait(0.5); H.ClearESP(); refreshESP()
    end))
    table.insert(H.ESP.conns, RunService.Heartbeat:Connect(function()
        if not H.ESP.enabled then return end
        refreshESP(); updateESP()
    end))
end

function H.StopESP()
    for _, c in ipairs(H.ESP.conns) do pcall(function() c:Disconnect() end) end
    H.ESP.conns = {}
end

function H.ClearESP()
    for p in pairs(H.ESP.active) do H.RemoveESP(p) end
end

-- ========== [NOVO] AIMBOT CORE ==========
-- Pega a parte do alvo conforme configuração
local function getTargetPart(p)
    local c = p.Character
    if not c then return nil end
    local h = c:FindFirstChildOfClass("Humanoid")
    if not h or h.Health <= 0 then return nil end
    return c:FindFirstChild(H.Aimbot.part) or c:FindFirstChild("HumanoidRootPart")
end

-- Verifica se o alvo está no time do jogador (se teamCheck ativo)
local function isTeammate(p)
    if not H.Aimbot.teamCheck then return false end
    return p.Team ~= nil and p.Team == LP.Team
end

-- Verifica linha de visão (sem paredes) usando Raycast
local function hasLineOfSight(targetPart)
    local cam = Workspace.CurrentCamera
    if not cam then return false end
    local origin = cam.CFrame.Position
    local dir = (targetPart.Position - origin)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {LP.Character, cam}
    local result = Workspace:Raycast(origin, dir, params)
    return result == nil or result.Instance:IsDescendantOf(targetPart.Parent)
end

-- Calcula o ponto de mira (com predição simples opcional)
local function getAimPosition(targetPart)
    return targetPart.Position
end

-- Loop principal do aimbot: só roda se enabled, target válido e botão direito pressionado
local function aimbotLoop()
    if not H.Aimbot.enabled then return end
    local target = H.Aimbot.target
    if not target or not target.Parent then return end
    if target == LP then return end
    if isTeammate(target) then return end

    local part = getTargetPart(target)
    if not part then return end

    if H.Aimbot.wallCheck and not hasLineOfSight(part) then return end

    local cam = Workspace.CurrentCamera
    if not cam then return end

    local aimPos = getAimPosition(part)
    -- Suavização: interpola entre o CFrame atual e o CFrame que mira no alvo
    local current = cam.CFrame
    local desired = CFrame.new(current.Position, aimPos)
    local smooth = math.clamp(H.Aimbot.smoothness, 0, 1)
    cam.CFrame = current:Lerp(desired, smooth)
end

function H.StartAimbot()
    H.StopAimbot()
    -- Loop no RenderStepped para máxima suavidade
    table.insert(H.Aimbot.conns, RunService.RenderStepped:Connect(function()
        if H.Aimbot.enabled and H.Aimbot.active then
            aimbotLoop()
        end
    end))

    -- Ativa/desativa com botão direito do mouse
    table.insert(H.Aimbot.conns, UIS.InputBegan:Connect(function(i, gp)
        if gp then return end
        if i.UserInputType == Enum.UserInputType.MouseButton2 then
            H.Aimbot.active = true
        end
    end))
    table.insert(H.Aimbot.conns, UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton2 then
            H.Aimbot.active = false
        end
    end))
end

function H.StopAimbot()
    for _, c in ipairs(H.Aimbot.conns) do pcall(function() c:Disconnect() end) end
    H.Aimbot.conns = {}
    H.Aimbot.active = false
end

function H.Cleanup()
    for _, c in ipairs(H.Connections) do pcall(function() c:Disconnect() end) end
    H.Connections = {}
    H.StopESP()
    H.ClearESP()
    H.StopAimbot()
    if H.Gui then pcall(function() H.Gui:Destroy() end) end
    if H.Loading then pcall(function() H.Loading:Destroy() end) end
    _G.BloodHub = nil
end

-- ========== LOADING SCREEN ==========
local loading = Instance.new("ScreenGui")
loading.Name = "BloodHub_Loading"
loading.ResetOnSpawn = false
loading.IgnoreGuiInset = true
loading.Parent = H.Parent
H.Loading = loading

local lbg = Instance.new("Frame")
lbg.Size = UDim2.fromScale(1,1)
lbg.BackgroundColor3 = Color3.new(0,0,0)
lbg.BorderSizePixel = 0
lbg.Parent = loading

local lt = Instance.new("TextLabel")
lt.Size = UDim2.fromScale(1,0.2)
lt.Position = UDim2.fromScale(0,0.3)
lt.BackgroundTransparency = 1
lt.Text = "BLOOD HUB"
lt.TextColor3 = Theme.AcB
lt.TextScaled = true
lt.Font = Enum.Font.GothamBlack
lt.Parent = lbg

local ls = Instance.new("TextLabel")
ls.Size = UDim2.fromScale(0.6,0.06)
ls.Position = UDim2.fromScale(0.2,0.52)
ls.BackgroundTransparency = 1
ls.Text = "INITIALIZING"
ls.TextColor3 = Theme.TxD
ls.TextScaled = true
ls.Font = Enum.Font.Gotham
ls.Parent = lbg

local lbar = Instance.new("Frame")
lbar.Size = UDim2.fromScale(0.5,0.012)
lbar.Position = UDim2.fromScale(0.25,0.62)
lbar.BackgroundColor3 = Color3.fromRGB(40,40,40)
lbar.BorderSizePixel = 0
lbar.Parent = lbg
H.Corner(lbar, 4)

local lfill = Instance.new("Frame")
lfill.Size = UDim2.fromScale(0,1)
lfill.BackgroundColor3 = Theme.AcB
lfill.BorderSizePixel = 0
lfill.Parent = lbar
H.Corner(lfill, 4)

TweenService:Create(lfill, TweenInfo.new(2.2, Enum.EasingStyle.Quad), {Size = UDim2.fromScale(1,1)}):Play()

task.delay(2.7, function()
    local tw = TweenService:Create(lbg, TweenInfo.new(0.5), {BackgroundTransparency = 1})
    for _, v in ipairs(lbg:GetDescendants()) do
        if v:IsA("TextLabel") then
            TweenService:Create(v, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
        elseif v:IsA("Frame") then
            TweenService:Create(v, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
        end
    end
    tw:Play()
    tw.Completed:Wait()
    loading:Destroy()

    -- ========== MAIN UI ==========
    local gui = Instance.new("ScreenGui")
    gui.Name = "BloodHub_Main"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.Parent = H.Parent
    H.Gui = gui

    local main = Instance.new("Frame")
    main.Size = UDim2.fromOffset(720,490)
    main.Position = UDim2.new(0.5,-360,0.5,-245)
    main.BackgroundColor3 = Theme.Bg
    main.BorderSizePixel = 0
    main.Active = true
    main.Parent = gui
    H.Corner(main, 12)
    H.Main = main

    local header = Instance.new("Frame")
    header.Size = UDim2.new(1,0,0,42)
    header.BackgroundColor3 = Theme.Sf
    header.BorderSizePixel = 0
    header.Parent = main
    H.Corner(header, 12)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1,-100,1,0)
    title.Position = UDim2.new(0,16,0,0)
    title.BackgroundTransparency = 1
    title.Text = "BLOOD HUB"
    title.TextColor3 = Theme.AcB
    title.TextSize = 18
    title.Font = Enum.Font.GothamBlack
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header

    local close = Instance.new("TextButton")
    close.Size = UDim2.fromOffset(28,28)
    close.Position = UDim2.new(1,-36,0.5,-14)
    close.BackgroundColor3 = Theme.Ac
    close.Text = "X"
    close.TextColor3 = Theme.Tx
    close.Font = Enum.Font.GothamBold
    close.TextSize = 14
    close.BorderSizePixel = 0
    close.Parent = header
    H.Corner(close, 6)

    local isOpen = true
    local function setOpen(s)
        isOpen = s
        if s then
            main.Visible = true
            main.Size = UDim2.fromOffset(0,0)
            TweenService:Create(main, TweenInfo.new(0.25, Enum.EasingStyle.Back), {Size = UDim2.fromOffset(720,490)}):Play()
        else
            local t = TweenService:Create(main, TweenInfo.new(0.2), {Size = UDim2.fromOffset(0,0)})
            t:Play()
            t.Completed:Wait()
            main.Visible = false
        end
    end
    H.SetOpen = setOpen
    close.MouseButton1Click:Connect(function() setOpen(false) end)

    local tabBar = Instance.new("Frame")
    tabBar.Size = UDim2.new(1,0,0,36)
    tabBar.Position = UDim2.new(0,0,0,42)
    tabBar.BackgroundColor3 = Theme.Sf
    tabBar.BorderSizePixel = 0
    tabBar.Parent = main

    local tl = Instance.new("UIListLayout")
    tl.FillDirection = Enum.FillDirection.Horizontal
    tl.Padding = UDim.new(0,2)
    tl.Parent = tabBar

    local tabs = {"PLAYER","VISUALS","AIMBOT","MISC","SETTINGS"}
    local tabBtns = {}
    local frames = {}

    for i, name in ipairs(tabs) do
        local b = Instance.new("TextButton")
        b.Size = UDim2.fromOffset(120,36)
        b.BackgroundColor3 = (i==1) and Theme.Ac or Theme.Sf
        b.Text = name
        b.TextColor3 = Theme.Tx
        b.Font = Enum.Font.GothamBold
        b.TextSize = 12
        b.BorderSizePixel = 0
        b.Parent = tabBar
        tabBtns[name] = b

        local c = Instance.new("ScrollingFrame")
        c.Size = UDim2.new(1,-24,1,-110)
        c.Position = UDim2.new(0,12,0,90)
        c.BackgroundColor3 = Theme.Bg
        c.BorderSizePixel = 0
        c.ScrollBarThickness = 3
        c.Visible = (i==1)
        c.Parent = main
        frames[name] = c

        local l = Instance.new("UIListLayout")
        l.Padding = UDim.new(0,8)
        l.SortOrder = Enum.SortOrder.LayoutOrder
        l.Parent = c

        b.MouseButton1Click:Connect(function()
            for _, x in pairs(tabBtns) do x.BackgroundColor3 = Theme.Sf end
            for _, x in pairs(frames) do x.Visible = false end
            b.BackgroundColor3 = Theme.Ac
            c.Visible = true
        end)
    end

    local drag, dStart, sPos = false, nil, nil
    header.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            drag = true; dStart = i.Position; sPos = main.Position
            H.Track(i.Changed:Connect(function()
                if i.UserInputState == Enum.UserInputState.End then drag = false end
            end))
        end
    end)
    H.Track(UIS.InputChanged:Connect(function(i)
        if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - dStart
            main.Position = UDim2.new(sPos.X.Scale, sPos.X.Offset + d.X, sPos.Y.Scale, sPos.Y.Offset + d.Y)
        end
    end))

    H.Track(UIS.InputBegan:Connect(function(i, gp)
        if gp then return end
        if i.KeyCode == Enum.KeyCode.RightShift then
            setOpen(not isOpen)
        end
    end))

    -- PLAYER TAB
    local pt = frames["PLAYER"]
    H.Label(pt, "PLAYER INFORMATION", 1, Theme.AcB, 15)
    local nameL = H.Label(pt, "Name: "..LP.Name, 2)
    local healthL = H.Label(pt, "Health: -", 3)
    task.spawn(function()
        while nameL.Parent do
            task.wait(0.5)
            local c = LP.Character
            local h = c and c:FindFirstChildOfClass("Humanoid")
            healthL.Text = "Health: "..(h and math.floor(h.Health) or "N/A")
        end
    end)

    -- [CORRIGIDO] Sliders só armazenam valor; loop reaplica
    H.Slider(pt, "WalkSpeed", 16, 200, 16, 4, function(v)
        H.WalkSpeedValue = v
    end)
    H.Slider(pt, "JumpPower", 50, 200, 50, 5, function(v)
        H.JumpPowerValue = v
    end)
    H.Button(pt, "RESET CHARACTER", 6, Theme.Ac, function()
        local c = LP.Character; local h = c and c:FindFirstChildOfClass("Humanoid")
        if h then h.Health = 0 end
    end)

    -- [CORRIGIDO] Loop de reaplicação de WalkSpeed / JumpPower
    task.spawn(function()
        while true do
            task.wait(0.1)
            local c = LP.Character
            local h = c and c:FindFirstChildOfClass("Humanoid")
            if h then
                if math.abs(h.WalkSpeed - H.WalkSpeedValue) > 0.5 then
                    h.WalkSpeed = H.WalkSpeedValue
                end
                if h.UseJumpPower ~= true then
                    h.UseJumpPower = true
                end
                if math.abs(h.JumpPower - H.JumpPowerValue) > 0.5 then
                    h.JumpPower = H.JumpPowerValue
                end
            end
        end
    end)

    -- [CORRIGIDO] Reaplicar após respawn
    H.Track(LP.CharacterAdded:Connect(function(char)
        task.wait(0.5)
        local h = char:FindFirstChildOfClass("Humanoid")
        if h then
            h.WalkSpeed = H.WalkSpeedValue
            h.UseJumpPower = true
            h.JumpPower = H.JumpPowerValue
        end
    end))

    -- VISUALS TAB
    local vt = frames["VISUALS"]
    H.Label(vt, "BLOOD ESP", 1, Theme.AcB, 15)
    H.Toggle(vt, "Enable ESP", false, 2, function(s)
        H.ESP.enabled = s
        if s then H.StartESP() else H.ClearESP() end
    end)
    H.Toggle(vt, "Show Names", true, 3, function(s) H.ESP.names = s end)
    H.Toggle(vt, "Show Distances", true, 4, function(s) H.ESP.dist = s end)
    H.Slider(vt, "Range", 50, 1000, 300, 5, function(v) H.ESP.range = v end)

    H.Label(vt, "SELECTION MODE", 6, Theme.TxD, 12)
    local mf = Instance.new("Frame")
    mf.Size = UDim2.new(1,0,0,34)
    mf.BackgroundTransparency = 1
    mf.LayoutOrder = 7
    mf.Parent = vt

    local allB = Instance.new("TextButton")
    allB.Size = UDim2.new(0.48,0,1,0)
    allB.BackgroundColor3 = Theme.Ac
    allB.Text = "ALL"
    allB.TextColor3 = Theme.Tx
    allB.Font = Enum.Font.GothamBold
    allB.TextSize = 12
    allB.BorderSizePixel = 0
    allB.Parent = mf
    H.Corner(allB, 6)

    local indB = Instance.new("TextButton")
    indB.Size = UDim2.new(0.48,0,1,0)
    indB.Position = UDim2.new(0.52,0,0,0)
    indB.BackgroundColor3 = Theme.Sf
    indB.Text = "INDIVIDUAL"
    indB.TextColor3 = Theme.Tx
    indB.Font = Enum.Font.GothamBold
    indB.TextSize = 12
    indB.BorderSizePixel = 0
    indB.Parent = mf
    H.Corner(indB, 6)

    local listF = Instance.new("ScrollingFrame")
    listF.Size = UDim2.new(1,0,0,160)
    listF.BackgroundColor3 = Theme.Sf
    listF.BorderSizePixel = 0
    listF.ScrollBarThickness = 3
    listF.Visible = false
    listF.LayoutOrder = 8
    listF.Parent = vt
    H.Corner(listF, 6)
    local ll = Instance.new("UIListLayout")
    ll.Padding = UDim.new(0,2)
    ll.Parent = listF

    local function refreshList()
        for _, c in ipairs(listF:GetChildren()) do
            if c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end
        end
        local list = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP then
                local c = p.Character
                local h = c and c:FindFirstChildOfClass("Humanoid")
                if h and h.Health > 0 then table.insert(list, p) end
            end
        end
        if #list == 0 then
            local e = Instance.new("TextLabel")
            e.Size = UDim2.new(1,0,0,30)
            e.BackgroundTransparency = 1
            e.Text = "Nenhum jogador disponível"
            e.TextColor3 = Theme.TxD
            e.TextSize = 12
            e.Font = Enum.Font.Gotham
            e.Parent = listF
            return
        end
        for _, p in ipairs(list) do
            local b = Instance.new("TextButton")
            b.Size = UDim2.new(1,-6,0,28)
            b.BackgroundColor3 = Theme.Bg
            b.Text = "  "..p.Name
            b.TextColor3 = Theme.Tx
            b.TextSize = 12
            b.Font = Enum.Font.Gotham
            b.TextXAlignment = Enum.TextXAlignment.Left
            b.BorderSizePixel = 0
            b.Parent = listF
            H.Corner(b, 4)
            b.MouseButton1Click:Connect(function()
                H.ESP.selected = p
            end)
        end
    end

    H.Track(Players.PlayerAdded:Connect(function() task.wait(0.5); refreshList() end))
    H.Track(Players.PlayerRemoving:Connect(function()
        task.wait(0.2)
        H.ESP.selected = nil
        if H.Aimbot.target and not H.Aimbot.target.Parent then H.Aimbot.target = nil end
        refreshList()
    end))

    allB.MouseButton1Click:Connect(function()
        H.ESP.mode = "ALL"
        allB.BackgroundColor3 = Theme.Ac
        indB.BackgroundColor3 = Theme.Sf
        listF.Visible = false
    end)
    indB.MouseButton1Click:Connect(function()
        H.ESP.mode = "INDIVIDUAL"
        allB.BackgroundColor3 = Theme.Sf
        indB.BackgroundColor3 = Theme.Ac
        listF.Visible = true
        refreshList()
    end)

    H.Label(vt, "COLORS", 9, Theme.TxD, 12)
    local cf = Instance.new("Frame")
    cf.Size = UDim2.new(1,0,0,34)
    cf.BackgroundTransparency = 1
    cf.LayoutOrder = 10
    cf.Parent = vt

    local function colorBtn(text, pos, col)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0.31,0,1,0)
        b.Position = UDim2.new(pos,0,0,0)
        b.BackgroundColor3 = col
        b.Text = text
        b.TextColor3 = Color3.new(1,1,1)
        b.Font = Enum.Font.GothamBold
        b.TextSize = 11
        b.BorderSizePixel = 0
        b.Parent = cf
        H.Corner(b, 6)
        b.MouseButton1Click:Connect(function()
            H.ESP.outline = col
            H.ESP.fill = col
        end)
        return b
    end
    colorBtn("RED", 0, Color3.fromRGB(255,20,20))
    colorBtn("BLUE", 0.345, Color3.fromRGB(30,100,255))
    colorBtn("GREEN", 0.69, Color3.fromRGB(30,220,100))

   
