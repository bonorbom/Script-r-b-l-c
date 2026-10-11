-- BON PVP Universal - Aimbot + ESP cho moi game (FPS / ban sung / ...)
-- Chay doc lap, khong phu thuoc Blox Fruits.
-- Lenh dan vao executor:
-- loadstring(game:HttpGet("https://raw.githubusercontent.com/bonorbom/Script-r-b-l-c/main/scripts/pvp-universal.lua"))()

-- Chay lai: dung ban cu truoc de khoi trung GUI/vong lap
pcall(function()
    if _G.BON_PVP and type(_G.BON_PVP.Stop) == "function" then
        _G.BON_PVP.Stop()
    end
end)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer

local M = {}

local PVP = {
    Aimbot = false,
    AimPOV = false,
    AimFOV = 120,       -- 10-360
    AimMode = "Smooth", -- Smooth | Lock
    AimSpeed = 25,      -- 1-100, chi dung cho Smooth
    WallCheck = true,
    ESP = false,
    ESPBox = true,
    ESPTracer = true,
    ESPHighlight = true,
    ESPInfo = true,
    Friendly = {},
}

local running = true
local function sessionAlive()
    return running and Player and Player.Parent ~= nil
end

local HasDrawing = false
pcall(function()
    local c = Drawing.new("Circle")
    c:Remove()
    HasDrawing = true
end)

local pvpCamera = workspace.CurrentCamera

local function getGuiParent()
    local ok, h = pcall(function() return gethui() end)
    if ok and h then return h end
    return Player:FindFirstChildOfClass("PlayerGui")
end

local fovCircle = nil
if HasDrawing then
    fovCircle = Drawing.new("Circle")
    fovCircle.Visible = false
    fovCircle.Thickness = 1.5
    fovCircle.Color = Color3.fromRGB(255, 255, 255)
    fovCircle.Filled = false
    fovCircle.NumSides = 64
end

local function pvpIsFriendly(plr)
    local nm = string.lower(plr.Name)
    local dn = ""
    pcall(function() dn = string.lower(plr.DisplayName or "") end)
    local uid = tostring(plr.UserId)
    for _, f in ipairs(PVP.Friendly) do
        local fl = string.lower(tostring(f))
        if nm == fl or dn == fl or uid == fl then
            return true
        end
    end
    return false
end

-- Game FFA (Team nil het): ai cung la dich tru friendly
local function pvpSameTeam(plr)
    local myTeam, hisTeam = nil, nil
    pcall(function() myTeam = Player.Team end)
    pcall(function() hisTeam = plr.Team end)
    if myTeam == nil and hisTeam == nil then
        return false -- FFA: khong coi la cung doi
    end
    return myTeam == hisTeam
end

local function pvpColor(plr)
    if pvpIsFriendly(plr) then
        return Color3.fromRGB(0, 255, 0) -- xanh la
    elseif pvpSameTeam(plr) then
        return Color3.fromRGB(0, 255, 255) -- xanh nuoc
    end
    return Color3.fromRGB(255, 0, 0) -- do
end

local function pvpIsEnemy(plr)
    if plr == Player then return false end
    if pvpIsFriendly(plr) then return false end
    return not pvpSameTeam(plr)
end

local function pvpWallBetween(targetPos, targetChar)
    local char = Player.Character
    local head = char and char:FindFirstChild("Head")
    if not head then return false end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { pvpCamera, char }
    params.IgnoreWater = true
    local res = workspace:Raycast(head.Position, targetPos - head.Position, params)
    if not res then return false end
    local m = res.Instance:FindFirstAncestorOfClass("Model")
    return m ~= targetChar
end

local function pvpGetTarget()
    local best, bestD = nil, PVP.AimFOV
    local vs = pvpCamera.ViewportSize
    local center = Vector2.new(vs.X / 2, vs.Y / 2)
    for _, plr in ipairs(Players:GetPlayers()) do
        if pvpIsEnemy(plr) then
            local char = plr.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local head = char and char:FindFirstChild("Head")
            if hum and head and hum.Health > 0 then
                local sp, onScreen = pvpCamera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                    if d <= PVP.AimFOV and d < bestD then
                        if (not PVP.WallCheck) or (not pvpWallBetween(head.Position, char)) then
                            best, bestD = { head = head }, d
                        end
                    end
                end
            end
        end
    end
    return best
end

local function pvpApplyAim(target)
    if not target or not target.head then return end
    local camPos = pvpCamera.CFrame.Position
    local goal = CFrame.new(camPos, target.head.Position)
    if PVP.AimMode == "Lock" then
        pvpCamera.CFrame = goal
    else
        local t = math.clamp(PVP.AimSpeed / 100, 0.02, 1)
        pvpCamera.CFrame = pvpCamera.CFrame:Lerp(goal, t)
    end
end

local espCache = {}

local function pvpGetESP(plr)
    local e = espCache[plr]
    if e then return e end
    e = {}
    if HasDrawing then
        e.box = Drawing.new("Square")
        e.box.Visible = false
        e.box.Thickness = 1.5
        e.box.Filled = false
        e.tracer = Drawing.new("Line")
        e.tracer.Visible = false
        e.tracer.Thickness = 1
        e.text = Drawing.new("Text")
        e.text.Visible = false
        e.text.Size = 13
        e.text.Center = true
        e.text.Outline = true
    end
    e.hl = Instance.new("Highlight")
    e.hl.FillTransparency = 0.65
    e.hl.OutlineTransparency = 0
    e.hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    e.hl.Enabled = false
    espCache[plr] = e
    return e
end

local function pvpHideESP(e)
    if e.box then e.box.Visible = false end
    if e.tracer then e.tracer.Visible = false end
    if e.text then e.text.Visible = false end
    if e.hl then e.hl.Enabled = false end
end

local function pvpDestroyESP(e)
    if e.box then pcall(function() e.box:Remove() end) end
    if e.tracer then pcall(function() e.tracer:Remove() end) end
    if e.text then pcall(function() e.text:Remove() end) end
    if e.hl then pcall(function() e.hl:Destroy() end) end
end

local function pvpUpdateESP()
    local vs = pvpCamera.ViewportSize
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= Player then
            local e = pvpGetESP(plr)
            local char = plr.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local head = char and char:FindFirstChild("Head")
            local alive = hum and hrp and head and hum.Health > 0
            local color = pvpColor(plr)
            if PVP.ESPHighlight and alive then
                e.hl.Adornee = char
                e.hl.FillColor = color
                e.hl.OutlineColor = color
                if not e.hl.Parent then
                    e.hl.Parent = getGuiParent()
                end
                e.hl.Enabled = true
            else
                e.hl.Enabled = false
            end
            if HasDrawing and alive then
                local tv, tOn = pvpCamera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.8, 0))
                local bv, bOn = pvpCamera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
                local rv, rOn = pvpCamera:WorldToViewportPoint(hrp.Position)
                local onScreen = tOn and bOn and rOn
                if e.box then
                    if PVP.ESPBox and onScreen then
                        local h = math.max(math.abs(tv.Y - bv.Y), 4)
                        local w = h * 0.55
                        e.box.Visible = true
                        e.box.Size = Vector2.new(w, h)
                        e.box.Position = Vector2.new(tv.X - w / 2, tv.Y)
                        e.box.Color = color
                    else
                        e.box.Visible = false
                    end
                end
                if e.tracer then
                    if PVP.ESPTracer and onScreen then
                        e.tracer.Visible = true
                        e.tracer.From = Vector2.new(vs.X / 2, vs.Y)
                        e.tracer.To = Vector2.new(rv.X, rv.Y)
                        e.tracer.Color = color
                    else
                        e.tracer.Visible = false
                    end
                end
                if e.text then
                    if PVP.ESPInfo and onScreen then
                        local dist = math.floor((hrp.Position - pvpCamera.CFrame.Position).Magnitude)
                        local hp = math.floor(hum.Health)
                        local nm = plr.DisplayName
                        if nm == "" or not nm then nm = plr.Name end
                        e.text.Visible = true
                        e.text.Text = nm .. " | " .. dist .. "m | " .. hp .. " HP"
                        e.text.Position = Vector2.new(tv.X, tv.Y - 16)
                        e.text.Color = color
                    else
                        e.text.Visible = false
                    end
                end
            elseif HasDrawing then
                if e.box then e.box.Visible = false end
                if e.tracer then e.tracer.Visible = false end
                if e.text then e.text.Visible = false end
            end
        end
    end
    for plr, e in pairs(espCache) do
        if not plr.Parent then
            pvpDestroyESP(e)
            espCache[plr] = nil
        end
    end
end

local pvpConn = RunService.RenderStepped:Connect(function()
    if not sessionAlive() then return end
    pvpCamera = workspace.CurrentCamera or pvpCamera
    if fovCircle then
        local show = PVP.AimPOV
        fovCircle.Visible = show
        if show then
            local vs = pvpCamera.ViewportSize
            fovCircle.Position = Vector2.new(vs.X / 2, vs.Y / 2)
            fovCircle.Radius = PVP.AimFOV
        end
    end
    if PVP.Aimbot then
        local okT, target = pcall(pvpGetTarget)
        if okT and target then
            pcall(pvpApplyAim, target)
        end
    end
    if PVP.ESP then
        pcall(pvpUpdateESP)
    else
        for _, e in pairs(espCache) do
            pvpHideESP(e)
        end
    end
end)

-- ===== GUI Rayfield =====
local RayfieldLib = nil
local function loadRayfield()
    if RayfieldLib then return RayfieldLib end
    local urls = {
        "https://sirius.menu/rayfield",
        "https://raw.githubusercontent.com/shlexware/Rayfield/main/source",
    }
    for _, url in ipairs(urls) do
        local ok, lib = pcall(function()
            return loadstring(game:HttpGet(url))()
        end)
        if ok and lib then
            RayfieldLib = lib
            return lib
        end
    end
    return nil
end

local statusLabel = nil
local function setStatus(t)
    if statusLabel then
        pcall(function() statusLabel:Set(t) end)
    end
    print("[BON PVP] " .. tostring(t))
end

local function buildGui()
    local lib = loadRayfield()
    if not lib then
        warn("[BON PVP] Khong tai duoc Rayfield")
        return nil
    end
    local Window = lib:CreateWindow({
        Name = "BON PVP Universal",
        LoadingTitle = "BON PVP",
        LoadingSubtitle = "Aimbot + ESP moi game",
        ConfigurationSaving = { Enabled = false },
        KeySystem = false,
    })

    local MainTab = Window:CreateTab("PVP", 4483362458)
    MainTab:CreateSection("Trang thai")
    statusLabel = MainTab:CreateLabel("San sang")
    if not HasDrawing then
        MainTab:CreateLabel("Canh bao: executor khong co Drawing API - ESP hinh se khong hien (chi co Highlight).")
    end

    MainTab:CreateSection("Aimbot")
    MainTab:CreateToggle({
        Name = "Aimbot",
        CurrentValue = PVP.Aimbot,
        Flag = "PvpAimbot",
        Callback = function(v)
            PVP.Aimbot = v
            setStatus(v and "Aimbot BAT" or "Aimbot TAT")
        end,
    })
    MainTab:CreateToggle({
        Name = "POV Visual (vong vung aim)",
        CurrentValue = PVP.AimPOV,
        Flag = "PvpAimPOV",
        Callback = function(v) PVP.AimPOV = v end,
    })
    MainTab:CreateSlider({
        Name = "FOV (vung aim)",
        Range = { 10, 360 },
        Increment = 10,
        CurrentValue = PVP.AimFOV,
        Flag = "PvpAimFOV",
        Callback = function(v) PVP.AimFOV = math.floor(v) end,
    })
    MainTab:CreateDropdown({
        Name = "Che do aim",
        Options = { "Smooth", "Lock" },
        CurrentOption = { "Smooth" },
        MultipleOptions = false,
        Flag = "PvpAimMode",
        Callback = function(v)
            PVP.AimMode = (type(v) == "table" and v[1]) or v
        end,
    })
    MainTab:CreateSlider({
        Name = "Toc do Smooth",
        Range = { 1, 100 },
        Increment = 1,
        CurrentValue = PVP.AimSpeed,
        Flag = "PvpAimSpeed",
        Callback = function(v) PVP.AimSpeed = math.floor(v) end,
    })
    MainTab:CreateToggle({
        Name = "Wall Check (co tuong thi khong aim)",
        CurrentValue = PVP.WallCheck,
        Flag = "PvpWallCheck",
        Callback = function(v) PVP.WallCheck = v end,
    })

    MainTab:CreateSection("ESP")
    MainTab:CreateToggle({
        Name = "ESP",
        CurrentValue = PVP.ESP,
        Flag = "PvpESP",
        Callback = function(v)
            PVP.ESP = v
            setStatus(v and "ESP BAT" or "ESP TAT")
        end,
    })
    MainTab:CreateToggle({
        Name = "ESP Box (hitbox)",
        CurrentValue = PVP.ESPBox,
        Flag = "PvpESPBox",
        Callback = function(v) PVP.ESPBox = v end,
    })
    MainTab:CreateToggle({
        Name = "ESP Tia",
        CurrentValue = PVP.ESPTracer,
        Flag = "PvpESPTracer",
        Callback = function(v) PVP.ESPTracer = v end,
    })
    MainTab:CreateToggle({
        Name = "ESP Highlight",
        CurrentValue = PVP.ESPHighlight,
        Flag = "PvpESPHighlight",
        Callback = function(v) PVP.ESPHighlight = v end,
    })
    MainTab:CreateToggle({
        Name = "ESP Ten / khoang cach / mau",
        CurrentValue = PVP.ESPInfo,
        Flag = "PvpESPInfo",
        Callback = function(v) PVP.ESPInfo = v end,
    })

    MainTab:CreateSection("Friendly (hien mau xanh la)")
    local friendlyLabel = MainTab:CreateLabel("Danh sach: (trong)")
    local function refreshFriendlyLabel()
        if #PVP.Friendly == 0 then
            friendlyLabel:Set("Danh sach: (trong)")
        else
            friendlyLabel:Set("Danh sach: " .. table.concat(PVP.Friendly, ", "))
        end
    end
    MainTab:CreateInput({
        Name = "Them Friendly",
        PlaceholderText = "Nhap ten / DisplayName / UserId roi Enter",
        RemoveTextAfterFocusLost = true,
        Callback = function(text)
            text = tostring(text or ""):gsub("^%s+", ""):gsub("%s+$", "")
            if text ~= "" then
                table.insert(PVP.Friendly, text)
                refreshFriendlyLabel()
                setStatus("Da them friendly " .. text)
            end
        end,
    })
    MainTab:CreateButton({
        Name = "Xoa het Friendly",
        Callback = function()
            PVP.Friendly = {}
            refreshFriendlyLabel()
            setStatus("Da xoa het friendly")
        end,
    })
    return Window
end

M._window = buildGui()

function M.Stop()
    running = false
    PVP.Aimbot = false
    PVP.AimPOV = false
    PVP.ESP = false
    if pvpConn then
        pcall(function() pvpConn:Disconnect() end)
    end
    if fovCircle then
        pcall(function() fovCircle:Remove() end)
        fovCircle = nil
    end
    for _, e in pairs(espCache) do
        pvpDestroyESP(e)
    end
    espCache = {}
    statusLabel = nil
    M._window = nil
end

_G.BON_PVP = M
print("[BON PVP] San sang. Bat Aimbot/ESP tren Rayfield.")
return M
