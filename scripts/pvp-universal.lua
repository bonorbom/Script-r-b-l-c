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
    AimPart = "head",   -- head | chest | armL | armR | legL | legR | lol
    AimPriority = "nearest", -- nearest | farthest | lowhp | highhp | lock
    AimTarget = "enemy", -- enemy | team | friendly | npc | all
    MaxDistFoot = 10000,     -- 100-10000: dich di bo
    MaxDistVehicle = 1000,   -- 100-1000: dich dang ngoi xe
    WallCheck = true,
    ESP = false,
    ESPBox = true,
    ESPTracer = true,
    ESPHighlight = true,
    ESPInfo = true,
    ESPNPC = false,          -- ESP rieng cho NPC (mau tim)
    HitboxPlayer = 0,        -- 0 = tat, 1-100: tang hitbox nguoi choi dich
    HitboxNPC = 0,           -- 0 = tat, 1-200: tang hitbox NPC
    Friendly = {},
}

local NPC_COLOR = Color3.fromRGB(255, 0, 255) -- tim: mau ESP/aim NPC

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

-- Dong bo voi bloxfruits.lua: chi coi la cung team khi ca 2 deu co team that va trung nhau.
-- Game khong dung Roblox Teams (Team nil het) -> khong ai la cung team, tru friendly.
local function pvpSameTeam(plr)
    local same = false
    pcall(function()
        local t1, t2 = plr.Team, Player.Team
        same = (t1 ~= nil and t2 ~= nil and t1 == t2)
    end)
    return same
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

local function pvpIsTeammate(plr)
    if plr == Player then return false end
    if pvpIsFriendly(plr) then return false end
    return pvpSameTeam(plr)
end

-- ===== NPC =====
-- NPC = Model trong workspace co Humanoid + HumanoidRootPart, khong phai character cua player.
-- Danh sach refresh dinh ky (NPC spawn/chet lien tuc); vi tri doc live moi frame nen NPC di chuyen van aim chuan.
local npcList = {}

local function pvpIsPlayerChar(m)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Character == m then return true end
    end
    return false
end

local function refreshNPCs()
    local found = {}
    local ok, desc = pcall(function() return workspace:GetDescendants() end)
    if ok and desc then
        for _, d in ipairs(desc) do
            if d:IsA("Model") then
                local hum = d:FindFirstChildOfClass("Humanoid")
                local hrp = d:FindFirstChild("HumanoidRootPart")
                if hum and hrp and hum.Health > 0 and not pvpIsPlayerChar(d) then
                    table.insert(found, d)
                end
            end
        end
    end
    npcList = found
end

local function pvpNpcAimOk()
    local mode = PVP.AimTarget
    return mode == "npc" or mode == "all"
end

-- Muc tieu aim theo che do da chon (dong bo cach phan loai voi bloxfruits.lua):
-- enemy: dich (mac dinh) | team: cung team | friendly: danh sach friendly
-- npc: chi NPC | all: dich + NPC (thay ai la aim, tru cung team/friendly)
local function pvpAimTargetOk(plr)
    if plr == Player then return false end
    local mode = PVP.AimTarget
    if mode == "team" then
        return pvpIsTeammate(plr)
    elseif mode == "friendly" then
        return pvpIsFriendly(plr)
    elseif mode == "npc" then
        return false
    elseif mode == "all" then
        return pvpIsEnemy(plr)
    end
    return pvpIsEnemy(plr)
end

-- Ban do label dropdown -> key bo phan
local AIM_PART_KEYS = {
    ["Đầu"] = "head",
    ["Ngực"] = "chest",
    ["Tay trái"] = "armL",
    ["Tay phải"] = "armR",
    ["Chân trái"] = "legL",
    ["Chân phải"] = "legR",
    ["lol"] = "lol",
}

-- Ten part theo R15 truoc, R6 sau
local AIM_PART_NAMES = {
    head  = { "Head" },
    chest = { "UpperTorso", "Torso" },
    armL  = { "LeftUpperArm", "LeftLowerArm", "LeftHand", "Left Arm" },
    armR  = { "RightUpperArm", "RightLowerArm", "RightHand", "Right Arm" },
    legL  = { "LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "Left Leg" },
    legR  = { "RightUpperLeg", "RightLowerLeg", "RightFoot", "Right Leg" },
}

local function findCharPart(char, names)
    for _, n in ipairs(names) do
        local p = char:FindFirstChild(n)
        if p and p:IsA("BasePart") then
            return p
        end
    end
    return nil
end

-- Vi tri aim theo bo phan da chon (ho tro R6 + R15)
local function getAimPos(char, key)
    if key == "lol" then
        -- meme: aim vao giua, cho troll :))
        local base = findCharPart(char, { "LowerTorso", "Torso" })
            or char:FindFirstChild("HumanoidRootPart")
        if base then
            return base.Position + Vector3.new(0, -0.8, 0)
        end
        return nil
    end
    local part = findCharPart(char, AIM_PART_NAMES[key] or AIM_PART_NAMES.head)
    if part then
        return part.Position
    end
    local head = char:FindFirstChild("Head")
    return head and head.Position or nil
end

-- Lay model phuong tien neu player dang ngoi (gan nhu game nao lai xe cung bat ngoi)
local function getVehicle(char, hum)
    local seat = nil
    pcall(function() seat = hum and hum.SeatPart or nil end)
    if seat then
        local veh = seat:FindFirstAncestorOfClass("Model")
        if veh and veh ~= char then
            return veh
        end
    end
    return nil
end

local function pvpWallBetween(targetPos, targetChar, targetHum)
    local char = Player.Character
    local head = char and char:FindFirstChild("Head")
    if not head then return false end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local ignore = { pvpCamera, char }
    -- Dich dang ngoi tren xe: bo qua luon phuong tien (khong tinh la tuong)
    local veh = getVehicle(targetChar, targetHum)
    if veh then
        table.insert(ignore, veh)
    end
    params.FilterDescendantsInstances = ignore
    params.IgnoreWater = true
    local res = workspace:Raycast(head.Position, targetPos - head.Position, params)
    if not res then return false end
    local m = res.Instance:FindFirstAncestorOfClass("Model")
    return m ~= targetChar
end

-- ===== Uu tien aim =====
-- nearest: gan nhat | farthest: xa nhat | lowhp: yeu mau nhat
-- highhp: nhieu mau nhat | lock: khoa muc tieu gan nhat toi khi chet/mat
local AIM_PRIORITY_KEYS = {
    ["Gần nhất"] = "nearest",
    ["Xa nhất"] = "farthest",
    ["Yếu máu nhất"] = "lowhp",
    ["Nhiều máu nhất"] = "highhp",
    ["Khóa mục tiêu"] = "lock",
}

-- Ban do label dropdown -> key muc tieu aim
local AIM_TARGET_KEYS = {
    ["Địch"] = "enemy",
    ["Cùng team"] = "team",
    ["Friendly"] = "friendly",
    ["NPC"] = "npc",
    ["Tất cả"] = "all",
}

local lockedPlr = nil
local lockedNpc = nil -- model NPC dang khoa (che do lock)

-- Khoang cach 3D tu camera toi dich + gioi han theo trang thai (di bo / di xe).
-- Tra ve dist; tra ve nil neu vuot qua khoang cach cho phep -> khong aim.
local function pvpTargetDist(char, hum)
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local d = (hrp.Position - pvpCamera.CFrame.Position).Magnitude
    local veh = getVehicle(char, hum)
    local limit = veh and PVP.MaxDistVehicle or PVP.MaxDistFoot
    if d > limit then return nil end
    return d
end

-- Ung vien hop le: dich, con song, trong vung FOV, khong vuong tuong, trong khoang cach.
-- Tra ve aimPos, dist.
local function pvpCandidateOk(char, hum)
    local aimPos = getAimPos(char, PVP.AimPart)
    if not aimPos then return nil end
    local sp, onScreen = pvpCamera:WorldToViewportPoint(aimPos)
    if not onScreen then return nil end
    local vs = pvpCamera.ViewportSize
    local sd = (Vector2.new(sp.X, sp.Y) - Vector2.new(vs.X / 2, vs.Y / 2)).Magnitude
    if sd > PVP.AimFOV then return nil end
    local dist = pvpTargetDist(char, hum)
    if not dist then return nil end
    if PVP.WallCheck and pvpWallBetween(aimPos, char, hum) then return nil end
    return aimPos, dist
end

-- Chon ung vien theo che do uu tien (khong tinh che do lock).
-- Tra ve { pos, plr, npc }: plr = Player, npc = Model NPC (1 trong 2).
local function pvpPickCandidate(mode)
    local best, bestScore, bestPos, bestNpc = nil, nil, nil, nil
    local function consider(score, plr, npc, aimPos)
        if bestScore == nil or score < bestScore then
            best, bestScore, bestPos = plr, score, aimPos
            bestNpc = npc
        end
    end
    for _, plr in ipairs(Players:GetPlayers()) do
        if pvpAimTargetOk(plr) then
            local char = plr.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local aimPos, dist = pvpCandidateOk(char, hum)
                if aimPos then
                    local score
                    if mode == "farthest" then
                        score = -dist
                    elseif mode == "lowhp" then
                        score = hum.Health
                    elseif mode == "highhp" then
                        score = -hum.Health
                    else
                        score = dist -- nearest
                    end
                    consider(score, plr, nil, aimPos)
                end
            end
        end
    end
    -- NPC: doc vi tri live moi lan pick nen NPC di chuyen van aim chuan
    if pvpNpcAimOk() then
        for _, npc in ipairs(npcList) do
            if npc and npc.Parent then
                local hum = npc:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    local aimPos, dist = pvpCandidateOk(npc, hum)
                    if aimPos then
                        local score
                        if mode == "farthest" then
                            score = -dist
                        elseif mode == "lowhp" then
                            score = hum.Health
                        elseif mode == "highhp" then
                            score = -hum.Health
                        else
                            score = dist -- nearest
                        end
                        consider(score, nil, npc, aimPos)
                    end
                end
            end
        end
    end
    if best or bestNpc then return { pos = bestPos, plr = best, npc = bestNpc } end
    return nil
end

-- Khoa muc tieu con hop le khong: roi game / het dich / chet / vuot khoang cach -> mat lock.
local function pvpLockValid(plr)
    if not plr or not plr.Parent then return false end
    if not pvpAimTargetOk(plr) then return false end
    local char = plr.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    if pvpTargetDist(char, hum) == nil then return false end
    return true
end

-- Lock NPC: mat lock khi NPC bi xoa / chet / doi che do aim / vuot khoang cach.
-- Vi tri doc live moi frame nen NPC di chuyen van giu lock chuan.
local function pvpLockValidNpc(npc)
    if not npc or not npc.Parent then return false end
    if not pvpNpcAimOk() then return false end
    local hum = npc:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    if pvpTargetDist(npc, hum) == nil then return false end
    return true
end

local function pvpGetTarget()
    -- Che do khoa: giu nguyen muc tieu cho toi khi chet / mat / vuot khoang cach.
    if PVP.AimPriority == "lock" then
        if not pvpLockValid(lockedPlr) then lockedPlr = nil end
        if not pvpLockValidNpc(lockedNpc) then lockedNpc = nil end
        if not lockedPlr and not lockedNpc then
            local pick = pvpPickCandidate("nearest")
            if pick then
                lockedPlr, lockedNpc = pick.plr, pick.npc
            end
        end
        local char = nil
        if lockedPlr then
            char = lockedPlr.Character
        elseif lockedNpc then
            char = lockedNpc
        end
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            local aimPos = getAimPos(char, PVP.AimPart)
            if aimPos then
                local _, onScreen = pvpCamera:WorldToViewportPoint(aimPos)
                if onScreen and ((not PVP.WallCheck) or (not pvpWallBetween(aimPos, char, hum))) then
                    return { pos = aimPos }
                end
            end
        end
        return nil
    end
    local pick = pvpPickCandidate(PVP.AimPriority)
    if pick then return { pos = pick.pos } end
    return nil
end

local function pvpApplyAim(target)
    if not target or not target.pos then return end
    local camPos = pvpCamera.CFrame.Position
    local goal = CFrame.new(camPos, target.pos)
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
    -- Highlight rieng cho phuong tien khi dich dang ngoi (lai xe)
    e.vhl = Instance.new("Highlight")
    e.vhl.FillTransparency = 0.7
    e.vhl.OutlineTransparency = 0
    e.vhl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    e.vhl.Enabled = false
    espCache[plr] = e
    return e
end

local function pvpHideESP(e)
    if e.box then e.box.Visible = false end
    if e.tracer then e.tracer.Visible = false end
    if e.text then e.text.Visible = false end
    if e.hl then e.hl.Enabled = false end
    if e.vhl then e.vhl.Enabled = false end
end

local function pvpDestroyESP(e)
    if e.box then pcall(function() e.box:Remove() end) end
    if e.tracer then pcall(function() e.tracer:Remove() end) end
    if e.text then pcall(function() e.text:Remove() end) end
    if e.hl then pcall(function() e.hl:Destroy() end) end
    if e.vhl then pcall(function() e.vhl:Destroy() end) end
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
            -- Highlight phuong tien khi dich dang ngoi (lai xe)
            local veh = alive and getVehicle(char, hum) or nil
            if PVP.ESPHighlight and veh then
                e.vhl.Adornee = veh
                e.vhl.FillColor = color
                e.vhl.OutlineColor = color
                if not e.vhl.Parent then
                    e.vhl.Parent = getGuiParent()
                end
                e.vhl.Enabled = true
            else
                e.vhl.Enabled = false
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

-- ===== Hitbox (tang hitbox dich + NPC, slider rieng) =====
-- Luu kich thuoc goc de tra lai khi tat; chay dinh ky 0.5s.
local hitboxSaved = {} -- [BasePart] = { Size, Transparency, CanCollide }

local function pvpHitboxSet(hrp, size)
    if not hrp then return end
    if not hrp.Parent then
        hitboxSaved[hrp] = nil -- part da bi xoa: bo record luu
        return
    end
    if size and size > 0 then
        if not hitboxSaved[hrp] then
            local ok, sz, tr, cc = pcall(function()
                return hrp.Size, hrp.Transparency, hrp.CanCollide
            end)
            if ok then
                hitboxSaved[hrp] = { Size = sz, Transparency = tr, CanCollide = cc }
            else
                return
            end
        end
        pcall(function()
            hrp.Size = Vector3.new(size, size, size)
            hrp.Transparency = 0.6
            hrp.CanCollide = false
        end)
    elseif hitboxSaved[hrp] then
        local o = hitboxSaved[hrp]
        hitboxSaved[hrp] = nil
        pcall(function()
            hrp.Size = o.Size
            hrp.Transparency = o.Transparency
            hrp.CanCollide = o.CanCollide
        end)
    end
end

local function pvpRestoreAllHitbox()
    for hrp, _ in pairs(hitboxSaved) do
        pvpHitboxSet(hrp, 0)
    end
end

local function pvpUpdateHitbox()
    local want = {}
    if PVP.HitboxPlayer > 0 then
        for _, plr in ipairs(Players:GetPlayers()) do
            if pvpIsEnemy(plr) then
                local char = plr.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then want[hrp] = PVP.HitboxPlayer end
            end
        end
    end
    if PVP.HitboxNPC > 0 then
        for _, npc in ipairs(npcList) do
            if npc and npc.Parent then
                local hrp = npc:FindFirstChild("HumanoidRootPart")
                if hrp then want[hrp] = PVP.HitboxNPC end
            end
        end
    end
    for hrp, s in pairs(want) do
        pvpHitboxSet(hrp, s)
    end
    for hrp, _ in pairs(hitboxSaved) do
        if not want[hrp] then
            pvpHitboxSet(hrp, 0)
        end
    end
end

-- ===== ESP NPC (mau tim) =====
local npcEspCache = {}

local function pvpGetNpcESP(npc)
    local e = npcEspCache[npc]
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
    npcEspCache[npc] = e
    return e
end

local function pvpUpdateNpcESP()
    local vs = pvpCamera.ViewportSize
    local seen = {}
    for _, npc in ipairs(npcList) do
        if npc and npc.Parent then
            local hum = npc:FindFirstChildOfClass("Humanoid")
            local hrp = npc:FindFirstChild("HumanoidRootPart")
            local head = npc:FindFirstChild("Head")
            local alive = hum and hrp and hum.Health > 0
            if alive then
                seen[npc] = true
                local e = pvpGetNpcESP(npc)
                if PVP.ESPHighlight then
                    e.hl.Adornee = npc
                    e.hl.FillColor = NPC_COLOR
                    e.hl.OutlineColor = NPC_COLOR
                    if not e.hl.Parent then
                        e.hl.Parent = getGuiParent()
                    end
                    e.hl.Enabled = true
                else
                    e.hl.Enabled = false
                end
                if HasDrawing then
                    local topPos = head and (head.Position + Vector3.new(0, 0.8, 0))
                        or (hrp.Position + Vector3.new(0, 2.5, 0))
                    local tv, tOn = pvpCamera:WorldToViewportPoint(topPos)
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
                            e.box.Color = NPC_COLOR
                        else
                            e.box.Visible = false
                        end
                    end
                    if e.tracer then
                        if PVP.ESPTracer and onScreen then
                            e.tracer.Visible = true
                            e.tracer.From = Vector2.new(vs.X / 2, vs.Y)
                            e.tracer.To = Vector2.new(rv.X, rv.Y)
                            e.tracer.Color = NPC_COLOR
                        else
                            e.tracer.Visible = false
                        end
                    end
                    if e.text then
                        if PVP.ESPInfo and onScreen then
                            local dist = math.floor((hrp.Position - pvpCamera.CFrame.Position).Magnitude)
                            local hp = math.floor(hum.Health)
                            e.text.Visible = true
                            e.text.Text = tostring(npc.Name) .. " | " .. dist .. "m | " .. hp .. " HP"
                            e.text.Position = Vector2.new(tv.X, tv.Y - 16)
                            e.text.Color = NPC_COLOR
                        else
                            e.text.Visible = false
                        end
                    end
                end
            end
        end
    end
    for npc, e in pairs(npcEspCache) do
        if not seen[npc] then
            pvpDestroyESP(e)
            npcEspCache[npc] = nil
        end
    end
end

local npcRefreshT, hitboxT = 0, 0
local pvpConn = RunService.RenderStepped:Connect(function(dt)
    if not sessionAlive() then return end
    pvpCamera = workspace.CurrentCamera or pvpCamera
    -- Refresh danh sach NPC dinh ky (NPC spawn/chet lien tuc)
    npcRefreshT = npcRefreshT + (dt or 0.016)
    if npcRefreshT >= 2 then
        npcRefreshT = 0
        pcall(refreshNPCs)
    end
    -- Cap nhat hitbox dinh ky
    hitboxT = hitboxT + (dt or 0.016)
    if hitboxT >= 0.5 then
        hitboxT = 0
        pcall(pvpUpdateHitbox)
    end
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
    if PVP.ESPNPC then
        pcall(pvpUpdateNpcESP)
    else
        for _, e in pairs(npcEspCache) do
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
    MainTab:CreateDropdown({
        Name = "Bo phan aim",
        Options = { "Đầu", "Ngực", "Tay trái", "Tay phải", "Chân trái", "Chân phải", "lol" },
        CurrentOption = { "Đầu" },
        MultipleOptions = false,
        Flag = "PvpAimPart",
        Callback = function(v)
            local label = (type(v) == "table" and v[1]) or v
            PVP.AimPart = AIM_PART_KEYS[label] or "head"
            setStatus("Aim vao: " .. tostring(label))
        end,
    })

    MainTab:CreateDropdown({
        Name = "Ưu tiên aim",
        Options = { "Gần nhất", "Xa nhất", "Yếu máu nhất", "Nhiều máu nhất", "Khóa mục tiêu" },
        CurrentOption = { "Gần nhất" },
        MultipleOptions = false,
        Flag = "PvpAimPriority",
        Callback = function(v)
            local label = (type(v) == "table" and v[1]) or v
            PVP.AimPriority = AIM_PRIORITY_KEYS[label] or "nearest"
            if PVP.AimPriority ~= "lock" then lockedPlr = nil lockedNpc = nil end
            setStatus("Ưu tiên aim: " .. tostring(label))
        end,
    })
    MainTab:CreateDropdown({
        Name = "Mục tiêu aim",
        Options = { "Địch", "Cùng team", "Friendly", "NPC", "Tất cả" },
        CurrentOption = { "Địch" },
        MultipleOptions = false,
        Flag = "PvpAimTarget",
        Callback = function(v)
            local label = (type(v) == "table" and v[1]) or v
            PVP.AimTarget = AIM_TARGET_KEYS[label] or "enemy"
            lockedPlr = nil
            lockedNpc = nil
            setStatus("Mục tiêu aim: " .. tostring(label))
        end,
    })
    MainTab:CreateSlider({
        Name = "Khoảng cách tối đa (đi bộ)",
        Range = { 100, 10000 },
        Increment = 100,
        CurrentValue = PVP.MaxDistFoot,
        Flag = "PvpMaxDistFoot",
        Callback = function(v)
            PVP.MaxDistFoot = math.floor(v)
            setStatus("Aim đi bộ tối đa: " .. PVP.MaxDistFoot .. "m")
        end,
    })
    MainTab:CreateSlider({
        Name = "Khoảng cách tối đa (đi xe)",
        Range = { 100, 1000 },
        Increment = 50,
        CurrentValue = PVP.MaxDistVehicle,
        Flag = "PvpMaxDistVehicle",
        Callback = function(v)
            PVP.MaxDistVehicle = math.floor(v)
            setStatus("Aim đi xe tối đa: " .. PVP.MaxDistVehicle .. "m")
        end,
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

    MainTab:CreateSection("NPC (mau tim)")
    MainTab:CreateToggle({
        Name = "ESP NPC",
        CurrentValue = PVP.ESPNPC,
        Flag = "PvpESPNPC",
        Callback = function(v)
            PVP.ESPNPC = v
            setStatus(v and "ESP NPC BAT" or "ESP NPC TAT")
        end,
    })
    MainTab:CreateLabel("Muc tieu aim: chon NPC / Tat ca o dropdown tren.")

    MainTab:CreateSection("Hitbox (0 = tat)")
    MainTab:CreateSlider({
        Name = "Hitbox nguoi choi dich",
        Range = { 0, 100 },
        Increment = 1,
        CurrentValue = PVP.HitboxPlayer,
        Flag = "PvpHitboxPlayer",
        Callback = function(v)
            PVP.HitboxPlayer = math.floor(v)
            setStatus("Hitbox nguoi choi: " .. PVP.HitboxPlayer)
        end,
    })
    MainTab:CreateSlider({
        Name = "Hitbox NPC",
        Range = { 0, 200 },
        Increment = 1,
        CurrentValue = PVP.HitboxNPC,
        Flag = "PvpHitboxNPC",
        Callback = function(v)
            PVP.HitboxNPC = math.floor(v)
            setStatus("Hitbox NPC: " .. PVP.HitboxNPC)
        end,
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
    lockedPlr = nil
    lockedNpc = nil
    PVP.Aimbot = false
    PVP.AimPOV = false
    PVP.ESP = false
    PVP.ESPNPC = false
    PVP.HitboxPlayer = 0
    PVP.HitboxNPC = 0
    pcall(pvpRestoreAllHitbox)
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
    for _, e in pairs(npcEspCache) do
        pvpDestroyESP(e)
    end
    npcEspCache = {}
    npcList = {}
    statusLabel = nil
    M._window = nil
end

_G.BON_PVP = M
print("[BON PVP] San sang. Bat Aimbot/ESP tren Rayfield.")
return M
