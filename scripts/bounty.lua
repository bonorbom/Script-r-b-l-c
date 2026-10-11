-- BON Auto Bounty (v17) - module rieng, duoc nap boi scripts/bloxfruits.lua
-- Khong chay doc lap: can _G.BON_BF do bloxfruits.lua cung cap truoc khi loadstring.
-- Tach file rieng de moi lan push nhe (Repo: bonorbom/Script-r-b-l-c).
local C = _G.BON_BF or error("[bounty] thieu _G.BON_BF - chi chay qua bloxfruits.lua")
local Settings, Module, PVP, Bounty = C.Settings, C.Module, C.PVP, C.Bounty
local Player, Players, Data, Level = C.Player, C.Players, C.Data, C.Level
local CommF, ReplicatedStorage = C.CommF, C.ReplicatedStorage
local Flight, V, SHOP_ITEMS, CURRENT_SEA = C.Flight, C.V, C.SHOP_ITEMS, C.CURRENT_SEA
local espCache, fovCircle, statusText = C.espCache, C.fovCircle, C.statusText
local setStatus, sessionAlive, getChar = C.setStatus, C.sessionAlive, C.getChar
local getSeaIslands, findIslandByName = C.getSeaIslands, C.findIslandByName
local bumpTravelGen, stopFarmForTravel = C.bumpTravelGen, C.stopFarmForTravel
local requestTravelToIsland, islandAfkLoop = C.requestTravelToIsland, C.islandAfkLoop
local startFarm, equipMelee, findToolByNames = C.startFarm, C.equipMelee, C.findToolByNames
local isMeleeTool, getMoney, priceText = C.isMeleeTool, C.getMoney, C.priceText
local fmtNum, tryBuyItem, shopBought = C.fmtNum, C.tryBuyItem, C.shopBought
local pvpApplyAim, pvpIsEnemy, pvpWallBetween = C.pvpApplyAim, C.pvpIsEnemy, C.pvpWallBetween
local pvpHideESP, pvpDestroyESP = C.pvpHideESP, C.pvpDestroyESP

-- ===== AUTO BOUNTY (v17) =====
-- Spec goc tu Bon (anh + mo ta): che do Auto PVP tu tim nguoi choi dich, bay toi va
-- danh tu dong nhu auto farm nhung danh nguoi — khac tab PVP aimbot/ESP thu cong.
--
-- XUNG DOT (spec moi 2026-10-11, thay cho co che tu tat cu): CHAN + BAO LOI.
-- Tam giac xung dot: Auto Farm <-> Auto Bounty <-> Aimbot (tay). Bat 1 module khi
-- module xung dot dang hoat dong -> KHONG cho bat, status/GUI neu ro ten module
-- dang bat, toggle tu tra ve off. Khong pha farm/travel/shop/ESP hien co.
-- (Quy tac dung cua Bon: khong tu tat module khac khi them tinh nang moi.)
--
-- DATA RESEARCH (ground truth):
-- 1. Bounty rule (wiki): KHONG nhan bounty khi target duoi 75% level cua minh
--    (max 2800 -> minh 2800 thi chi danh nguoi >= 2100). NHUNG game khong cho doc
--    lv nguoi khac (Data.Level khong replicate) -> KHONG loc level truoc duoc.
--    Quy tac moi (y Bon): danh TAT CA dich; sau 60s engage ma target khong mat
--    mau nao tu user -> coi nhu duoi 20 -> blacklist 5 phut, doi target khac.
--    PvP mo tu lv 20 (giu gate cho chinh user). Marines khong danh duoc Marines;
--    allied (ket dong minh) khong gay damage — game KHONG expose ally qua code
--    (limitation): danh khong vao mau thi target tu bi loai sau 60s.
-- 2. Chieu: phim Z/X/C/V qua VirtualInputManager:SendKeyEvent(true/false, KeyCode, false, game).
--    Cooldown KHONG doc duoc tu game -> timer tay theo so lieu wiki (BOUNTY_CD).
--    Tam danh (studs) KHONG verify duoc -> default bao thu theo nhom vu khi, cho override.
-- 3. Stun: KHONG co ten instance verify duoc -> detect gian tiep (ket vi tri khi dang bay,
--    an damage giua luc giu phim -> nha phim ao + reset) + probe ChildAdded log ten
--    instance la de Bon test game that xac nhan sau.

local VIM = nil
pcall(function() VIM = game:GetService("VirtualInputManager") end)

-- Remote cho Auto Haki (data verify 2026-10-11, nguon: github joaohemrique372-prog, scribd Long Hub)
-- Ken (Observation): RemoteEvent Remotes.CommE; bat = CommE:FireServer("Ken", true);
--   detect = CollectionService:HasTag(Character, "Ken") (server gan tag, KHONG FindFirstChild).
-- Buso (Aura): RemoteFunction Remotes.CommF_ (KHAC CommE); bat = CommF_:InvokeServer("Buso")
--   (chi 1 arg); detect = Character:FindFirstChild("HasBuso").
-- Chua verify duoc cach tat explicit -> chi bat lai khi mat, khong implement tat.
local CommE = nil
pcall(function()
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    CommE = remotes and remotes:WaitForChild("CommE", 10)
end)
local CollectionSvc = nil
pcall(function() CollectionSvc = game:GetService("CollectionService") end)

-- Cooldown tay theo wiki (giay). Tool/phim khong co trong bang -> KHONG spam blind.
local BOUNTY_CD = {
    Godhuman     = { Z = 8, X = 11, C = 17 },
    Sanguine     = { Z = 8, X = 11, C = 18 },
    ElectricClaw = { Z = 8, X = 11, C = 17 },
    Sharkman     = { Z = 7, X = 11, C = 16 },
    DragonTalon  = { Z = 7.5, X = 10, C = 17 },
    CDK          = { Z = 9, X = 14 },
    TTK          = { Z = 8, X = 13 }, -- wiki True_Triple_Katana (verify 2026-10-11)
    HallowScythe = { Z = 9, X = 13 },
    SkullGuitar  = { Z = 10, X = 14 }, -- ten that la "Skull Guitar", KHONG phai Soul Guitar
    Kabucha      = { Z = 9, X = 15 },
    Dough        = { Z = 9, X = 12.75, C = 16.5, V = 22.5 }, -- wiki Dough (so cu V=4.5 la thoi gian GIU bi nhet nham)
}

-- Chieu hold-variant (giu cang lau cang manh): [key chuan][phim] = giay giu toi da (wiki)
local BOUNTY_HOLD = {
    Godhuman     = { X = 3, C = 3 },
    ElectricClaw = { Z = 3, X = 3 },
    Sharkman     = { X = 3, C = 1.5 }, -- wiki Change History: Update 29.2 max hold 1.5s
    DragonTalon  = { Z = 3, X = 3 }, -- V2
    CDK          = { Z = 3, X = 3 },
    Dough        = { V = 4.5 }, -- slider "Giu chieu" max 3s nen V khong full duoc: xem limitation
}

-- Tam danh bao thu theo nhom vu khi (studs). Chua verify -> cho override qua slider.
local BOUNTY_RANGE = { Melee = 25, Sword = 60, Gun = 300, Fruit = 120, Default = 25 }

local BOUNTY_KEYS = { "Z", "X", "C", "V" }
local BOUNTY_PVP_MIN_LV = 20 -- PvP mo tu lv 20
-- (Bo BOUNTY_LEVEL_GAP=700 cu: rule moi la 1 chieu lv >= myLv*0.75, khong cap tren.)

-- Ten tool -> key chuan trong BOUNTY_CD (match mo, khong phan biet hoa thuong/khoang trang)
local BOUNTY_TOOL_ALIASES = {
    godhuman = "Godhuman",
    sanguine = "Sanguine",
    electricclaw = "ElectricClaw",
    sharkman = "Sharkman",
    dragontalon = "DragonTalon",
    curseddualkatana = "CDK", cdk = "CDK",
    truetriplekatana = "TTK", ttk = "TTK",
    hallowscythe = "HallowScythe",
    skullguitar = "SkullGuitar", -- KHONG phai Soul Guitar
    kabucha = "Kabucha",
    dough = "Dough", mochi = "Dough",
}

local bountyCdAt = {} -- [toolKey][phim] = tick() luc bam (timer tay)
local bountyHeldKey = nil -- phim ao dang giu (de nha khan khi tat/stun)
local bountyStillPos, bountyStillT = nil, 0 -- phat hien ket vi tri khi bay
local bountyBlacklist = {} -- [plr] = tick() het han: target tra "far"/"timeout" bi blacklist vai phut

-- PvpDisabled: chet trong PvP bi tat PvP 1 luc (Sea 1: 15 phut) -> khong danh duoc.
local function bountyPvpDisabled(plr)
    local ok, v = pcall(function() return plr and plr:GetAttribute("PvpDisabled") end)
    if ok and v then return true end
    return false
end

-- Doc level nguoi choi: Player.Data.Level (IntValue). Khong doc duoc -> nil (SKIP an toan).
local function bountyReadLevel(plr)
    local ok, lv = pcall(function()
        local d = plr:FindFirstChild("Data")
        local l = d and d:FindFirstChild("Level")
        return l and l.Value
    end)
    if ok and type(lv) == "number" then return lv end
    return nil
end

-- Quet + sap xep bang target: DANH TAT CA dich (khong loc level target nua vi game
-- khong cho doc lv nguoi khac), sort theo khoang cach gan nhat. Ai sau 60s engage
-- ma khong mat mau nao thi blacklist 5 phut (coi nhu duoi 20). Skip friendly/cung
-- team (pvpIsEnemy), PvpDisabled, blacklist. Refresh dinh ky + khi target chet/roi.
local function bountyRefreshTargets()
    local list = {}
    -- Debug: dem xem moi nguoi bi loai o buoc nao de Bon biet vi sao list trong
    local dbg = { total = 0, skipTeam = 0, skipPvpDis = 0, skipPerm = 0, skipBan = 0, skipChar = 0, ok = 0 }
    Bounty._scanDbg = dbg
    local myLv = bountyReadLevel(Player)
    if not myLv or myLv < BOUNTY_PVP_MIN_LV then
        dbg.myLvFail = true
        dbg.myLv = myLv
        Bounty.Targets = list
        return list
    end
    -- Don track damage cua player da roi game
    for plr, _ in pairs(Bounty._dmgTrack) do
        if not plr.Parent then
            Bounty._dmgTrack[plr] = nil
        end
    end
    local _, _, myHrp = getChar()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= Player then
            dbg.total = dbg.total + 1
            if not pvpIsEnemy(plr) then
                dbg.skipTeam = dbg.skipTeam + 1 -- cung team hoac friendly
            elseif bountyPvpDisabled(plr) then
                dbg.skipPvpDis = dbg.skipPvpDis + 1
            elseif Bounty._permBlacklist[plr] then
                dbg.skipPerm = dbg.skipPerm + 1
            else
                local bannedUntil = bountyBlacklist[plr]
                if bannedUntil and tick() < bannedUntil then
                    dbg.skipBan = dbg.skipBan + 1
                else
                    local tc = plr.Character
                    local th = tc and tc:FindFirstChildOfClass("Humanoid")
                    local tr = tc and tc:FindFirstChild("HumanoidRootPart")
                    if not (th and tr and th.Health > 0) then
                        dbg.skipChar = dbg.skipChar + 1
                    else
                        dbg.ok = dbg.ok + 1
                        local d = (myHrp and tr.Position) and (tr.Position - myHrp.Position).Magnitude or math.huge
                        table.insert(list, { plr = plr, dist = d })
                    end
                end
            end
        end
    end
    table.sort(list, function(a, b) return a.dist < b.dist end)
    Bounty.Targets = list
    return list
end

local function bountyTargetParts(plr)
    local tc = plr and plr.Character
    if not tc then return nil, nil, nil end
    local th = tc:FindFirstChildOfClass("Humanoid")
    local tr = tc:FindFirstChild("HumanoidRootPart")
    return tc, th, tr
end

local function bountyMyHP()
    local _, hum = getChar()
    if not hum or not hum.MaxHealth or hum.MaxHealth <= 0 then return 100 end
    return hum.Health / hum.MaxHealth * 100
end

local function bountySafeNeeded()
    return bountyMyHP() < Bounty.SafeHP
end

-- Theo doi damage: "Held Skill Interruption" — dang giu chieu ma an damage -> game tu
-- nha chieu -> script phai nha phim ao + khong giu tiep.
local function bountyTrackDamage()
    local _, hum = getChar()
    if not hum then return end
    if Bounty._lastHP and hum.Health < Bounty._lastHP - 1 then
        Bounty._tookDamageAt = tick()
    end
    Bounty._lastHP = hum.Health
end

local function bountyInterrupted()
    return (tick() - (Bounty._tookDamageAt or 0)) < 0.5
end

-- Anti "duoi 20" (y Bon): game khong cho doc lv nguoi khac nen khong loc truoc.
-- Sau 60s engage ma target khong mat mau nao tu user -> coi nhu duoi 20 ->
-- tra ve true de doi target + blacklist.
local function bountyTrackTargetDamage(plr, th)
    if not th then return false end
    local tr = Bounty._dmgTrack[plr]
    if not tr then
        tr = { t0 = tick(), startHP = th.Health, damaged = false }
        Bounty._dmgTrack[plr] = tr
        return false
    end
    if not tr.damaged and th.Health < tr.startHP - 1 then
        tr.damaged = true
        Bounty._didDamage[plr] = tick() -- ghi nhan de dem kill sau nay
        Bounty._dmgTrack[plr] = nil -- da gay duoc damage: xong, xoa track
        return false
    end
    if not tr.damaged and (tick() - tr.t0) > 60 then
        return true -- het 60s khong gay duoc damage
    end
    return false
end

-- Nhan dien tool dang cam -> key chuan de tra cooldown
local function bountyToolKey(tool)
    if not tool then return nil end
    local n = string.lower(tostring(tool.Name or ""):gsub("[%s%-%_]", ""))
    for alias, key in pairs(BOUNTY_TOOL_ALIASES) do
        if string.find(n, alias, 1, true) then return key end
    end
    return nil
end

-- Nhom vu khi de lay tam danh bao thu (tai dung isMeleeTool; Sword/Gun theo ToolTip)
local function bountyToolGroup(tool)
    if not tool or not tool:IsA("Tool") then return "Default" end
    if isMeleeTool(tool) then return "Melee" end
    local tt = tostring(tool.ToolTip or "")
    if tt == "Sword" then return "Sword" end
    if tt == "Gun" then return "Gun" end
    return "Fruit" -- trai ac quy / loai khac: tooltip khong phai 3 loai tren
end

local function bountyToolKnown(tkey)
    local tbl = tkey and BOUNTY_CD[tkey]
    if not tbl then return false end
    for _ in pairs(tbl) do return true end
    return false
end

local function bountySkillReady(tkey, key)
    local tbl = tkey and BOUNTY_CD[tkey]
    local cd = tbl and tbl[key]
    if not cd then return false end -- chua verify -> khong spam blind
    local m = bountyCdAt[tkey]
    local last = (m and m[key]) or 0
    return (tick() - last) >= cd
end

local function bountyMarkCd(tkey, key)
    bountyCdAt[tkey] = bountyCdAt[tkey] or {}
    bountyCdAt[tkey][key] = tick()
end

local function bountyAnySkillReady(tool)
    local tkey = bountyToolKey(tool)
    if not bountyToolKnown(tkey) then return true end -- tool la: danh M1
    for _, k in ipairs(BOUNTY_KEYS) do
        if bountySkillReady(tkey, k) then return true end
    end
    return false
end

local function bountySkillRange(tool)
    if Bounty.RangeOverride and Bounty.RangeOverride > 0 then
        return Bounty.RangeOverride
    end
    local g = bountyToolGroup(tool)
    return BOUNTY_RANGE[g] or BOUNTY_RANGE.Default
end

-- Tool dang cam tren tay; chua cam gi thi uu tien cam LAI tool vua dung
-- (Bounty._lastTool — nho truoc khi chet/roi tay, tim theo ten trong char/backpack);
-- chi fallback Melee khi khong con tool nao khac.
local function bountyEnsureTool()
    local char, hum = getChar()
    if not char or not hum then return nil end
    local equipped = char:FindFirstChildOfClass("Tool")
    if equipped then return equipped end
    local last = Bounty._lastTool
    if last then
        local lname = tostring(last.Name or "")
        if lname ~= "" then
            local backpack = Player:FindFirstChild("Backpack")
            for _, container in ipairs({ char, backpack }) do
                if container then
                    local t = container:FindFirstChild(lname)
                    if t and t:IsA("Tool") then
                        pcall(function() hum:EquipTool(t) end)
                        return t
                    end
                end
            end
        end
    end
    return equipMelee()
end

-- Auto-aim khi cast: tai dung pvpApplyAim (ton trong PVP.AimMode/AimSpeed cua user).
-- (File chua co getAimPos/PVP.AimPart rieng -> dung truc tiep Head/HRP + pvpApplyAim.)
local function bountyAimAt(plr)
    local tc = plr and plr.Character
    local aim = tc and (tc:FindFirstChild("Head") or tc:FindFirstChild("HumanoidRootPart"))
    if aim then
        pcall(pvpApplyAim, { head = aim })
    end
end

-- Bam phim ao: keydown -> giu -> keyup. Nha phim ngay neu bi ngat (damage/stun) giua hold,
-- hoac bounty bi tat giua chung. Luon co keyup -> khong ket phim.
local function bountyPressKey(key, holdSec, interruptFn)
    if not VIM then return false end
    local kc = Enum.KeyCode[key]
    if not kc then return false end
    local ok = pcall(function() VIM:SendKeyEvent(true, kc, false, game) end)
    if not ok then return false end
    bountyHeldKey = key
    local t0 = tick()
    while (tick() - t0) < (holdSec or 0) do
        task.wait(0.05)
        if not Settings.Bounty or not sessionAlive() then break end
        bountyTrackDamage() -- sample damage MOI lap: "an damage giua hold -> nha phim ao"
        if interruptFn and interruptFn() then break end -- bi damage/stun -> nha ngay
    end
    pcall(function() VIM:SendKeyEvent(false, kc, false, game) end)
    bountyHeldKey = nil
    return true
end

local function bountyReleaseKeys()
    if bountyHeldKey and VIM then
        local k = bountyHeldKey
        bountyHeldKey = nil
        pcall(function() VIM:SendKeyEvent(false, Enum.KeyCode[k], false, game) end)
    end
end

-- Detect ket vi tri gian tiep (stun): co goal, chua toi (>30), nhung dung yen >2s.
-- (Khong dung velocity vi luong fly zero velocity moi frame.)
local function bountyStuckCheck(hrp, goalPos)
    if not hrp or not goalPos then return false end
    local dist = (goalPos - hrp.Position).Magnitude
    if dist < 30 then
        bountyStillPos, bountyStillT = nil, 0
        return false
    end
    local now = tick()
    if not bountyStillPos then
        bountyStillPos, bountyStillT = hrp.Position, now
        return false
    end
    if (hrp.Position - bountyStillPos).Magnitude < 3 then
        if now - bountyStillT > 2 then return true end
    else
        bountyStillPos, bountyStillT = hrp.Position, now
    end
    return false
end

-- Pause toan bo logic khi nghi stun; resume khi di chuyen lai duoc; timeout 8s chong ket.
local function bountyPauseStun(reason)
    Bounty.StunPauses = Bounty.StunPauses + 1
    bountyReleaseKeys() -- nha phim ao dang giu (Held Skill Interruption)
    setStatus("Bounty: nghi bi stun (" .. tostring(reason) .. "), tam dung...")
    local gen = Bounty.Gen
    local t0 = tick()
    while Settings.Bounty and sessionAlive() and Bounty.Gen == gen and (tick() - t0) < 8 do
        local _, _, hrp = getChar()
        if not hrp then break end
        if bountySafeNeeded() then -- mau thap giua pause -> caller (bountyWaitFly) xu ly "safe"
            bountyStillPos, bountyStillT = nil, 0
            setStatus("Bounty: mau thap giua luc pause stun -> safe")
            return "safe"
        end
        if not bountyStillPos or (hrp.Position - bountyStillPos).Magnitude > 5 then
            bountyStillPos, bountyStillT = nil, 0
            setStatus("Bounty: het stun, danh tiep")
            return true
        end
        task.wait(0.3)
    end
    bountyStillPos, bountyStillT = nil, 0
    setStatus("Bounty: timeout stun, thu tiep (chong ket)")
    return true
end

-- Bay toi pos va cho (dung cho bounty; khong dung flyGoalTo vi no doi Settings.Farm).
-- plr (optional): refresh Flight.goal theo vi tri LIVE cua target moi ~0.5s
-- (giu nguyen offset ban dau, VD +12Y) de khong bay duoi bong ma.
-- Tra ve true / false / "far" / "timeout" / "safe" (uu tien safe khi mau thap giua duong bay).
local function bountyWaitFly(pos, timeout, arriveDist, plr)
    Flight.goal = pos
    arriveDist = arriveDist or 10
    bountyStillPos, bountyStillT = nil, 0
    local gen = Bounty.Gen
    local pauseStreak = 0 -- dem pause stun lien tiep: qua 3 lan -> return "far" (khong reset timeout)
    -- Offset giu nguyen so voi target khi refresh goal (VD pos = thrp + (0,12,0))
    local goalOffset = nil
    local _, _, thrp0 = bountyTargetParts(plr)
    if thrp0 then goalOffset = pos - thrp0.Position end
    local refreshT = 0
    local t0 = tick()
    while Settings.Bounty and sessionAlive() and Bounty.Gen == gen do
        if (tick() - t0) >= (timeout or 30) then break end
        local _, hum, hrp = getChar()
        if not hrp or not hum or hum.Health <= 0 then return false end
        if bountySafeNeeded() then return "safe" end
        -- Refresh goal theo vi tri live cua target moi ~0.5s
        if plr and goalOffset and tick() - refreshT > 0.5 then
            refreshT = tick()
            local _, _, thrp = bountyTargetParts(plr)
            if thrp then
                pos = thrp.Position + goalOffset
                Flight.goal = pos
            end
        end
        if (pos - hrp.Position).Magnitude <= arriveDist then
            bountyStillPos, bountyStillT = nil, 0
            return true
        end
        if bountyStuckCheck(hrp, pos) then
            if bountyPauseStun("ket vi tri khi bay") == "safe" then return "safe" end
            pauseStreak = pauseStreak + 1
            if pauseStreak > 3 then
                setStatus("Bounty: pause stun qua 3 lan lien tiep, doi target")
                return "far"
            end
            -- KHONG reset t0 o day: pause 8s khong duoc tru hao khoi timeout (chong ket vo han)
        else
            pauseStreak = 0
        end
        task.wait(0.1)
    end
    local _, _, hrp = getChar()
    if hrp and (pos - hrp.Position).Magnitude <= arriveDist then return true end
    return "timeout"
end

-- Energy: het energy thi skill khong ra -> khong mark cooldown oan.
-- (Ten "Energy" chua verify tuyet doi -> doc qua pcall, khong doc duoc thi khong chan.)
local function bountyHasEnergy()
    local char = getChar()
    if not char then return true end
    local ok, e = pcall(function() return char:FindFirstChild("Energy") end)
    if not ok or not e then return true end
    local ok2, v = pcall(function() return e.Value end)
    if not ok2 then return true end
    return (tonumber(v) or 1) > 0
end

-- Co skill THAT nao san sang khong (khac bountyAnySkillReady: tool la -> false chu khong true)
local function bountyAnyRealSkillReady(tool)
    local tkey = bountyToolKey(tool)
    if not bountyToolKnown(tkey) then return false end
    for _, k in ipairs(BOUNTY_KEYS) do
        if bountySkillReady(tkey, k) then return true end
    end
    return false
end

-- Spam 2 chieu/dot bang tool dang cam (Z/X/C/V; giu theo slider neu la hold-variant).
-- Tra ve: true = da cast skill that; "m1only" = chi dung tool:Activate() (tool la hoac
-- het cooldown); false = khong cast duoc gi (VD het energy); "blocked" = tuong chan.
local function bountyCastVolley(plr)
    bountyAimAt(plr)
    local char = getChar()
    local tool = bountyEnsureTool()
    -- Doi tool thuc su len tay (toi da ~1s) truoc volley dau, tranh cast tay khong
    if tool and char then
        local eqT0 = tick()
        while (tick() - eqT0) < 1 do
            if not Settings.Bounty or not sessionAlive() then break end
            if char:FindFirstChildOfClass("Tool") == tool then break end
            task.wait(0.1)
        end
        tool = char:FindFirstChildOfClass("Tool") or tool
    end
    local tkey = bountyToolKey(tool)
    -- Wall check (tai dung pvpWallBetween): co tuong thi khong phi cooldown
    if PVP.WallCheck then
        local tc = plr and plr.Character
        local aim = tc and (tc:FindFirstChild("Head") or tc:FindFirstChild("HumanoidRootPart"))
        local _, _, hrp = getChar()
        if aim and hrp then
            local blocked = false
            pcall(function() blocked = pvpWallBetween(aim.Position, tc) end)
            if blocked then return "blocked" end
        end
    end
    local range = bountySkillRange(tool)
    local fired = 0
    local noEnergy = false
    if tkey and bountyToolKnown(tkey) then
        for _, k in ipairs(BOUNTY_KEYS) do
            if fired >= 2 then break end
            if bountySkillReady(tkey, k) then
                if not bountyHasEnergy() then noEnergy = true break end -- het energy: khong mark cd oan
                bountyAimAt(plr) -- aim lai truoc moi chieu
                local holdT = 0
                if BOUNTY_HOLD[tkey] and BOUNTY_HOLD[tkey][k] then
                    holdT = math.min(Bounty.HoldTime, 5)
                end
                bountyPressKey(k, holdT, bountyInterrupted)
                bountyMarkCd(tkey, k) -- tinh cooldown tu luc bam (bi ngat giua hold cung tinh)
                fired = fired + 1
                task.wait(0.2)
                -- Sau hold dai (dang CastPhase, vat ly tu do, co the roi): do lai khoang
                -- cach truoc khi cast chieu tiep; roi qua xa tam chieu thi dung volley
                if holdT > 1 then
                    local _, _, hrp2 = getChar()
                    local _, _, thrp2 = bountyTargetParts(plr)
                    if hrp2 and thrp2 and (thrp2.Position - hrp2.Position).Magnitude > range * 1.5 then
                        break
                    end
                end
            end
        end
    end
    if fired == 0 then
        if noEnergy then return false end -- het energy: M1 cung khong ra, khong spam vo ich
        -- Tool la (khong co trong bang CD): fallback danh M1 nhu farm (Activate)
        if tool then
            pcall(function() tool:Activate() end)
            return "m1only"
        end
        return false
    end
    return true
end

-- Cast 1 chieu duy nhat (dung cho mode Du kich).
-- Tra ve: true = da cast skill that; "m1only" = chi Activate(); false = khong cast duoc;
-- "blocked" = tuong chan (wall check nhu ban Basic).
local function bountyCastSingle(plr)
    bountyAimAt(plr)
    local tool = bountyEnsureTool()
    local tkey = bountyToolKey(tool)
    -- Wall check (tai dung pvpWallBetween) nhu ban Basic: co tuong thi khong phi cooldown
    if PVP.WallCheck then
        local tc = plr and plr.Character
        local aim = tc and (tc:FindFirstChild("Head") or tc:FindFirstChild("HumanoidRootPart"))
        local _, _, hrp = getChar()
        if aim and hrp then
            local blocked = false
            pcall(function() blocked = pvpWallBetween(aim.Position, tc) end)
            if blocked then return "blocked" end
        end
    end
    if tkey and bountyToolKnown(tkey) then
        for _, k in ipairs(BOUNTY_KEYS) do
            if bountySkillReady(tkey, k) then
                if not bountyHasEnergy() then return false end -- het energy: khong mark cd oan
                bountyAimAt(plr)
                local holdT = 0
                if BOUNTY_HOLD[tkey] and BOUNTY_HOLD[tkey][k] then
                    holdT = math.min(Bounty.HoldTime, 5)
                end
                bountyPressKey(k, holdT, bountyInterrupted)
                bountyMarkCd(tkey, k)
                return true
            end
        end
        return false
    end
    if tool then
        pcall(function() tool:Activate() end)
        return "m1only"
    end
    return false
end

-- Safe: mau < nguong -> bay smooth len cao hon target ~SafeHeight, BAM theo do cao
-- target thay doi, dung chung toc do bay travel. Thoat khi hoi tren nguong + 5%.
local function bountyDoSafe(plr)
    bountyReleaseKeys()
    Bounty.CastPhase = false
    setStatus("Bounty: SAFE - mau thap, bay len cao!")
    local gen = Bounty.Gen
    local t0 = tick()
    while Settings.Bounty and sessionAlive() and Bounty.Gen == gen and (tick() - t0) < 40 do
        local _, hum, hrp = getChar()
        if not hum or not hrp or hum.Health <= 0 then return end
        if bountyMyHP() >= Bounty.SafeHP + 5 then
            setStatus("Bounty: hoi mau xong, danh tiep")
            return
        end
        local _, _, thrp = bountyTargetParts(plr)
        local tx, ty, tz = hrp.Position.X, hrp.Position.Y, hrp.Position.Z
        if thrp then
            tx, ty, tz = thrp.Position.X, thrp.Position.Y, thrp.Position.Z
        end
        Flight.goal = Vector3.new(tx, ty + Bounty.SafeHeight, tz) -- bam do cao target
        task.wait(0.2)
    end
end

-- Mode Basic (legit): bay toi -> ap sat -> TAT fly (tha vat ly) -> aim + spam 2 chieu ->
-- bay len doi 1s -> bo xuong danh chieu KHAC -> het cooldown thi len do cao cho doi hoi.
local function bountyEngageBasic(tgt)
    local plr = tgt.plr
    local gen = Bounty.Gen
    local t0 = tick()
    local blockedCount = 0
    while Settings.Bounty and sessionAlive() and Bounty.Gen == gen and (tick() - t0) < 120 do -- moi target toi da 120s
        bountyTrackDamage()
        local char, hum, hrp = getChar()
        local _, th, thrp = bountyTargetParts(plr)
        if not plr.Parent or not th or not thrp or th.Health <= 0 then return "dead" end
        if not char or not hum or not hrp or hum.Health <= 0 then return "me-dead" end
        if bountySafeNeeded() then return "safe" end
        if bountyTrackTargetDamage(plr, th) then
            setStatus("Bounty: " .. tostring(plr.Name) .. " 60s khong mat mau (coi nhu duoi 20), doi target...")
            return "nodamage"
        end

        local tool = bountyEnsureTool()
        local range = bountySkillRange(tool)
        -- Truoc khi cast: ngoai tam chieu thi AP SAT 1 LAN roi spam luon, khong can lai lien tuc
        if (thrp.Position - hrp.Position).Magnitude > range then
            Bounty.CastPhase = false
            setStatus("Bounty: ap sat " .. tostring(tgt.plr.Name))
            local res = bountyWaitFly(thrp.Position + Vector3.new(0, 12, 0), 25, math.min(range * 0.7, 25), plr)
            if res == "safe" then return "safe" end
            if res ~= true then return "far" end -- khong toi duoc -> doi target khac
        end

        -- TAT fly, tha cho game tinh vat ly
        Bounty.CastPhase = true
        Flight.goal = nil
        task.wait(0.2) -- de nhan vat on dinh truoc khi cast
        local okCast, fired = pcall(bountyCastVolley, plr)
        Bounty.CastPhase = false
        if not okCast then
            setStatus("Bounty: cast loi nhe, thu lai")
            task.wait(0.5)
        elseif fired == "blocked" then
            blockedCount = blockedCount + 1
            if blockedCount >= 3 then return "far" end -- doi goc mai khong duoc -> doi target
            -- Nhay sang ben canh lay goc khac
            local _, _, hrp2 = getChar()
            local _, _, thrp2 = bountyTargetParts(plr)
            if hrp2 and thrp2 then
                local side = Vector3.new(-(thrp2.Position.Z - hrp2.Position.Z), 0, (thrp2.Position.X - hrp2.Position.X))
                if side.Magnitude > 0 then
                    Flight.goal = hrp2.Position + side.Unit * 40 + Vector3.new(0, 20, 0)
                    task.wait(1)
                end
            end
        elseif fired == "m1only" then
            blockedCount = 0
            local curTool = bountyEnsureTool()
            if not bountyToolKnown(bountyToolKey(curTool)) then
                -- Tool khong co skill verify duoc: M1 la option duy nhat, giu hanh vi cu
                local _, _, hrp3 = getChar()
                if hrp3 then Flight.goal = hrp3.Position + Vector3.new(0, 45, 0) end
                task.wait(1)
            else
                -- Khong skill THAT nao duoc cast (het cooldown): KHONG M1-spam sat mat
                -- (tranh rule "No Reward, Suspicious Kill" cua game) -> bay len WaitHeight
                -- doi skill that hoi roi moi bo xuong danh tiep
                setStatus("Bounty: het skill that, bay len cho hoi chieu...")
                local wt0 = tick()
                local ready = false
                while Settings.Bounty and sessionAlive() and Bounty.Gen == gen and (tick() - wt0) < 30 do
                    bountyTrackDamage()
                    if bountySafeNeeded() then return "safe" end
                    local _, _, thrp2 = bountyTargetParts(plr)
                    if not thrp2 then return "dead" end
                    Flight.goal = thrp2.Position + Vector3.new(0, Bounty.WaitHeight, 0)
                    if bountyAnyRealSkillReady(bountyEnsureTool()) then ready = true break end
                    task.wait(0.3)
                end
                Flight.goal = nil
                if not ready then return "timeout" end
            end
        elseif fired then
            blockedCount = 0
            -- Bay len cao doi 1s roi bo xuong ap sat danh chieu KHAC chua cooldown
            local _, _, hrp3 = getChar()
            if hrp3 then Flight.goal = hrp3.Position + Vector3.new(0, 45, 0) end
            task.wait(1)
        else
            blockedCount = 0
            -- Tat ca chieu dang cooldown: bay len do cao cho doi hoi roi xuong spam
            setStatus("Bounty: cho hoi chieu...")
            local wt0 = tick()
            local ready = false
            while Settings.Bounty and sessionAlive() and Bounty.Gen == gen and (tick() - wt0) < 30 do
                bountyTrackDamage()
                if bountySafeNeeded() then return "safe" end
                local _, _, thrp2 = bountyTargetParts(plr)
                if not thrp2 then return "dead" end
                Flight.goal = thrp2.Position + Vector3.new(0, Bounty.WaitHeight, 0)
                if bountyAnySkillReady(bountyEnsureTool()) then ready = true break end
                task.wait(0.3)
            end
            Flight.goal = nil
            if not ready then return "timeout" end
        end
    end
    return "timeout"
end

-- Mode Du kich (theo anh Bon gui): ap sat -> chieu 1 -> bay cheo 45° len truoc mat ->
-- quay lai ap sat -> chieu -> bay cheo 45° huong nguoc lai, lap orbit.
local function bountyEngageGuerilla(tgt)
    local plr = tgt.plr
    local gen = Bounty.Gen
    local t0 = tick()
    local dirSign = 1
    while Settings.Bounty and sessionAlive() and Bounty.Gen == gen and (tick() - t0) < 120 do -- moi target toi da 120s
        bountyTrackDamage()
        local char, hum, hrp = getChar()
        local _, th, thrp = bountyTargetParts(plr)
        if not plr.Parent or not th or not thrp or th.Health <= 0 then return "dead" end
        if not char or not hum or not hrp or hum.Health <= 0 then return "me-dead" end
        if bountySafeNeeded() then return "safe" end
        if bountyTrackTargetDamage(plr, th) then
            setStatus("Bounty: " .. tostring(plr.Name) .. " 60s khong mat mau (coi nhu duoi 20), doi target...")
            return "nodamage"
        end

        -- Ap sat
        Bounty.CastPhase = false
        setStatus("Bounty [Du kich]: ap sat " .. tostring(tgt.plr.Name))
        local res = bountyWaitFly(thrp.Position + Vector3.new(0, 10, 0), 20, 15, plr)
        if res == "safe" then return "safe" end
        if res ~= true then return "far" end

        -- Chieu 1 (auto-aim + cast)
        Bounty.CastPhase = true
        Flight.goal = nil
        task.wait(0.15)
        local okCast, cres = pcall(bountyCastSingle, plr)
        Bounty.CastPhase = false
        if okCast and cres == "blocked" then
            -- Tuong chan: bo qua cast vong nay, orbit ke tiep se dua sang goc khac
            setStatus("Bounty [Du kich]: tuong chan, doi goc...")
        end

        -- Bay cheo 45° len truoc mat target, doi huong moi vong (orbit).
        -- HUONG 45° TINH THEO HUONG NHIN CUA TARGET (thrp2.CFrame.LookVector),
        -- khong phai huong nhin cua minh — Bon xac nhan y do nay.
        local _, _, hrp2 = getChar()
        local _, _, thrp2 = bountyTargetParts(plr)
        if hrp2 and thrp2 then
            local look = thrp2.CFrame.LookVector
            local flat = Vector3.new(look.X, 0, look.Z)
            if flat.Magnitude < 0.1 then flat = Vector3.new(0, 0, 1) end
            flat = flat.Unit
            local side = Vector3.new(-flat.Z, 0, flat.X) * dirSign
            -- 45°: ngang ~42 (30 tien + 30 ben), cao 42
            Flight.goal = hrp2.Position + flat * 30 + side * 30 + Vector3.new(0, 42, 0)
            task.wait(1.2)
        end
        dirSign = -dirSign
    end
    return "timeout"
end

-- Vong lap bounty chinh: chon target dau bang (level gan nhat) -> engage -> safe/dead/timeout
-- thi refresh bang ngay. Moi vong co timeout, pcall, khong ket co (Gen).
local function bountyLoop()
    if Bounty.Running then return end
    Bounty.Running = true
    local gen = Bounty.Gen
    local refreshT = 0
    while Settings.Bounty and sessionAlive() and Bounty.Gen == gen do
        local ok, err = pcall(function()
            local char, hum, hrp = getChar()
            if not char or not hum or not hrp or hum.Health <= 0 then
                setStatus("Bounty: cho nhan vat hoi sinh...")
                Flight.goal = nil
                Bounty._lastHP = nil
                task.wait(1)
                return
            end
            bountyTrackDamage()
            bountyMaintainHaki() -- tu bat lai Ken/Buso moi ~5s (neu toggle Auto Haki bat)

            if tick() - refreshT > 3 or #Bounty.Targets == 0 then
                bountyRefreshTargets()
                refreshT = tick()
            end
            local tgt = Bounty.Targets[1]
            if not tgt then
                local myLv = bountyReadLevel(Player) or 0
                if myLv < BOUNTY_PVP_MIN_LV then
                    setStatus("Bounty: can lv 20+ moi PVP (hien tai lv " .. tostring(myLv) .. ")")
                else
                    setStatus("Bounty: khong thay dich xung quanh")
                end
                Flight.goal = nil
                task.wait(2)
                return
            end

            -- Nho tool dang cam de equip lai sau khi chet/roi tay (uu tien hon Melee)
            local eqNow = char:FindFirstChildOfClass("Tool")
            if eqNow then Bounty._lastTool = eqNow end

            -- PvP bi tat sau khi chet (Sea 1: 15 phut) -> khong engage vo ich.
            -- KHONG tu bat PvP (khong co cach hop le) — chi setStatus canh bao va doi.
            local okAttr, pvpOff = pcall(function() return Player:GetAttribute("PvpDisabled") end)
            if okAttr and pvpOff then
                setStatus("Bounty: PvP dang tat sau khi chet (15 phut Sea 1), cho PvP mo lai...")
                Flight.goal = nil
                task.wait(5)
                return
            end

            local nm = tostring(tgt.plr.DisplayName ~= "" and tgt.plr.DisplayName or tgt.plr.Name)
            setStatus("Bounty [" .. Bounty.Mode .. "]: danh " .. nm .. " (cach " .. math.floor(tgt.dist or 0) .. "m)")
            Bounty._currentTarget = tgt.plr -- nho de xac dinh killer neu minh chet
            local res
            if Bounty.Mode == "Du kích" then
                res = bountyEngageGuerilla(tgt)
            else
                res = bountyEngageBasic(tgt)
            end
            if res == "safe" then
                bountyDoSafe(tgt.plr)
            elseif res == "dead" then
                -- Dem kill: chi tinh khi minh co gay damage cho no trong 30s qua
                -- (chac chan kill cua minh, khong phai thang khac kill ho).
                -- Kill 1 nguoi >= 3 lan -> nghi 1 tieng, doi nguoi khac.
                local lastHit = Bounty._didDamage[tgt.plr]
                Bounty._didDamage[tgt.plr] = nil
                if lastHit and (tick() - lastHit) < 30 then
                    local n = (Bounty._killCount[tgt.plr] or 0) + 1
                    Bounty._killCount[tgt.plr] = n
                    if n >= 3 then
                        bountyBlacklist[tgt.plr] = tick() + 3600
                        setStatus("Bounty: da kill " .. nm .. " 3 lan -> tha, doi nguoi khac")
                    else
                        setStatus("Bounty: da kill " .. nm .. " (" .. n .. "/3)")
                    end
                end
                Bounty._currentTarget = nil
            elseif res == "me-dead" then
                -- Bi giet: DAM BAO tay no giet moi blacklist vinh vien:
                -- dang engage no + minh an damage trong 5s qua + no con song
                -- (chet khi dang solo voi no thi 99% la no giet).
                local killer = Bounty._currentTarget
                local recentDmg = (tick() - (Bounty._tookDamageAt or 0)) < 5
                if killer and killer.Parent and recentDmg then
                    local _, kh = bountyTargetParts(killer)
                    if kh and kh.Health > 0 then
                        Bounty._permBlacklist[killer] = true
                        Bounty._dmgTrack[killer] = nil
                        setStatus("Bounty: bi " .. tostring(killer.Name) .. " giet -> blacklist vinh vien")
                    end
                end
                Bounty._currentTarget = nil
                task.wait(2)
            elseif res == "nodamage" then
                -- 60s khong gay duoc damage: coi nhu duoi 20, blacklist 5 phut
                bountyBlacklist[tgt.plr] = tick() + 300
                Bounty._dmgTrack[tgt.plr] = nil
                Bounty._currentTarget = nil
            elseif res == "far" or res == "timeout" then
                bountyBlacklist[tgt.plr] = tick() + 180 -- blacklist 3 phut roi thu lai
                Bounty._currentTarget = nil
            end
            refreshT = 0 -- dead/far/timeout -> refresh bang ngay de doi target
        end)
        if not ok then
            setStatus("Bounty: loi nhe, thu lai (" .. tostring(err) .. ")")
            task.wait(1)
        end
        task.wait(0.1)
    end
    Flight.goal = nil
    Bounty.CastPhase = false
    Bounty.Running = false
end

local function bountyStart()
    Bounty.Gen = Bounty.Gen + 1 -- tang + bat co TRUOC khi check Running: chong race
    Settings.Bounty = true      -- (bat lai nhanh khi vong cu chua kip thoat)
    local myGen = Bounty.Gen
    if Bounty.Running then
        -- Race respawn (tat->bat nhanh khi vong cu chua kip thoat): cho vong cu
        -- ha co Running (toi da ~2s). Neu Gen lai doi (co toggle moi hon) thi
        -- ngung cho — vong moi nhat tu lo spawn, khong cho vo han / spawn trung.
        local t0 = tick()
        while Bounty.Running and Bounty.Gen == myGen and tick() - t0 < 2 do
            task.wait(0.05)
        end
    end
    Bounty.Enabled = true
    Bounty.StunPauses = 0
    bountyCdAt = {}
    bountyStillPos, bountyStillT = nil, 0
    -- Hook stun probe cho character hien tai (tranh bo lo stun khi bat giua chung;
    -- ham tu skip neu da hook char nay, CharacterAdded hook cho cac lan respawn sau)
    pcall(bountyHookStunProbe)
    task.spawn(bountyLoop) -- bountyLoop tu guard "if Bounty.Running then return end"
end

-- Don dep: nha phim ao, ha fly, ha co — khong de ket co khi tat giua chung.
local function bountyCleanup()
    bountyReleaseKeys()
    Flight.goal = nil
    Bounty.CastPhase = false
    Bounty.Targets = {}
    Bounty._lastHP = nil
    Bounty._lastTool = nil
    bountyStillPos, bountyStillT = nil, 0
end

-- ===== Auto Haki (Ken + Buso) cho Auto Bounty =====
-- Chi chay khi toggle Auto Haki BAT va Auto Bounty dang chay. Moi ~5s kiem tra 1 lan:
-- chua bat thi bat lai. Buso la remote dang toggle -> CHI goi khi chua co HasBuso
-- (goi thua se TAT nham). Ken khong co cach tat explicit nen chi bat lai khi mat tag.
local function bountyHasKen()
    local char = Player.Character
    if not char or not CollectionSvc then return false end
    local ok, has = pcall(function() return CollectionSvc:HasTag(char, "Ken") end)
    return ok and has == true
end

local function bountyHasBuso()
    local char = Player.Character
    return char and char:FindFirstChild("HasBuso") ~= nil
end

local hakiLastCheck = 0
local function bountyMaintainHaki()
    if not Bounty.AutoHaki then return end
    if not Settings.Bounty or not Bounty.Running then return end
    if tick() - hakiLastCheck < 5 then return end
    hakiLastCheck = tick()
    if not Player.Character then return end
    if not bountyHasKen() and CommE then
        pcall(function() CommE:FireServer("Ken", true) end)
    end
    if not bountyHasBuso() then
        pcall(function() CommF:InvokeServer("Buso") end)
    end
end

-- Probe stun: hook Character.ChildAdded, log ten instance la xuat hien khi bi stun de
-- Bon test game that xac nhan sau (hien tai chua co ten instance stun nao verify duoc).
-- CHUA KIEM CHUNG TRONG GAME: neu luong fly (zero velocity moi frame) lan ca stun thi
-- doi dieu kien detect sang "khoang cach toi goal khong giam" thay vi dung yen tuyet doi.
local function bountyHookStunProbe()
    local char = Player.Character
    if not char or Bounty._probeChar == char then return end
    Bounty._probeChar = char
    pcall(function()
        char.ChildAdded:Connect(function(inst)
            if not Settings.Bounty then return end
            print("[Bounty][stun-probe] ChildAdded: " .. tostring(inst and inst.Name) ..
                " (" .. tostring(inst and inst.ClassName) .. ")")
        end)
    end)
end

Player.CharacterAdded:Connect(function()
    task.wait(1)
    if Settings.Bounty then bountyHookStunProbe() end
end)

-- Text hien thi bang target tren GUI (kem debug khi list trong)
local function bountyTargetLabelText()
    if #Bounty.Targets == 0 then
        local d = Bounty._scanDbg
        if d then
            local myTeamName = "?"
            pcall(function()
                local tm = Player.Team
                myTeamName = tm and tm.Name or "?"
            end)
            local s = "Danh sach target: (trong)\nQuet: tong " .. d.total
                .. " | cung team/fr " .. d.skipTeam
                .. " | pvp tat " .. d.skipPvpDis
                .. " | perm " .. d.skipPerm
                .. " | ban " .. d.skipBan
                .. " | chet " .. d.skipChar
                .. "\nTeam minh: " .. myTeamName
            if d.myLvFail then
                s = s .. " | LOI: khong doc duoc lv minh (" .. tostring(d.myLv) .. ")"
            end
            return s
        end
        return "Danh sach target: (trong)"
    end
    local lines = { "Danh sach target (" .. #Bounty.Targets .. "):" }
    for i = 1, math.min(#Bounty.Targets, 8) do
        local t = Bounty.Targets[i]
        local nm = tostring(t.plr.DisplayName ~= "" and t.plr.DisplayName or t.plr.Name)
        table.insert(lines, i .. ". " .. nm .. " (" .. math.floor(t.dist or 0) .. "m)")
    end
    return table.concat(lines, "\n")
end

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
            local src = game:HttpGet(url)
            local fn = loadstring(src)
            assert(fn, "Rayfield compile fail")
            return fn()
        end)
        if ok and lib then
            RayfieldLib = lib
            return lib
        end
    end
    warn("[BloxFruits] Khong tai duoc Rayfield UI (executor/ket noi chan HttpGet).")
    return nil
end

local function buildGui()
    local lib = loadRayfield()
    if not lib then return nil end

    local Window = lib:CreateWindow({
        Name = "BON - Blox Fruits v17",
        LoadingTitle = "BON Blox Fruits",
        LoadingSubtitle = "Rayfield UI",
        ConfigurationSaving = {
            Enabled = false,
        },
        Discord = {
            Enabled = false,
            Invite = "noinvitelink",
            RememberJoins = true,
        },
        KeySystem = false,
    })
    Module._rayfield = lib
    Module._window = Window

    -- ===== Tab Farm =====
    local FarmTab = Window:CreateTab("Farm", 4483362458)
    FarmTab:CreateSection("Trang thai")
    local statusLabel = FarmTab:CreateLabel("Trang thai: " .. statusText)
    Module._statusLabel = statusLabel

    FarmTab:CreateSection("Auto Farm")
    local farmToggle = FarmTab:CreateToggle({
        Name = "Auto Farm",
        CurrentValue = Settings.Farm,
        Flag = "BON_AutoFarm",
        Callback = function(v)
            -- CHAN + BAO LOI (spec moi, thay cho tu tat): tam giac xung dot
            -- Auto Farm <-> Auto Bounty <-> Aimbot. Bat module nay khi module kia
            -- dang chay -> KHONG cho bat, neu ten module dang chay, toggle ve off.
            if v and Settings.Bounty then
                setStatus("Không bật được Auto Farm vì Auto Bounty đang bật")
                pcall(function() farmToggle:Set(false) end)
                Settings.Farm = false
                return
            end
            if v and PVP.Aimbot then
                setStatus("Không bật được Auto Farm vì Aimbot đang bật")
                pcall(function() farmToggle:Set(false) end)
                Settings.Farm = false
                return
            end
            if v and Settings.TravelMove then
                setStatus("Dang di chuyen, khong bat Auto Farm cung luc")
                pcall(function() farmToggle:Set(false) end)
                Settings.Farm = false
                return
            end
            if v and Settings.IslandAFK then
                -- Khong de AFK va farm chay song song (AFK se giet farm va keo ve dao cu)
                Settings.IslandAFK = false
                pcall(function()
                    if Module._afkToggle then
                        Module._afkToggle:Set(false)
                    end
                end)
                setStatus("Da tat Treo dao de bat Auto Farm")
            end
            local wasOn = Settings.Farm
            Settings.Farm = v
            if v then
                startFarm()
            elseif wasOn then
                -- Tat that (khong phai bi chan) moi don dep Flight.goal:
                -- Set(false) tu nhanh bi chan goi lai callback(false) voi wasOn=false
                Flight.goal = nil
            end
        end,
    })
    Module._farmToggle = farmToggle
    FarmTab:CreateToggle({
        Name = "Gom Mob",
        CurrentValue = Settings.BringMobs,
        Flag = "BON_BringMobs",
        Callback = function(v) Settings.BringMobs = v end,
    })
    FarmTab:CreateToggle({
        Name = "Tu Cong Stat",
        CurrentValue = Settings.AutoStat,
        Flag = "BON_AutoStat",
        Callback = function(v) Settings.AutoStat = v end,
    })
    FarmTab:CreateToggle({
        Name = "Auto Aura (Buso)",
        CurrentValue = Settings.AutoAura,
        Flag = "BON_AutoAura",
        Callback = function(v) Settings.AutoAura = v end,
    })

    local statList = { "Melee", "Defense", "Sword", "Gun", "Demon Fruit" }
    FarmTab:CreateDropdown({
        Name = "Stat tu cong",
        Options = statList,
        CurrentOption = { Settings.StatName },
        MultipleOptions = false,
        Flag = "BON_StatName",
        Callback = function(option)
            local v = type(option) == "table" and option[1] or option
            if v then Settings.StatName = v end
        end,
    })
    FarmTab:CreateSlider({
        Name = "Toc do bay",
        Range = { 100, 350 },
        Increment = 25,
        Suffix = "studs/s",
        CurrentValue = Settings.FlySpeed,
        Flag = "BON_FlySpeed",
        Callback = function(v) Settings.FlySpeed = v end,
    })
    FarmTab:CreateSlider({
        Name = "Gom toi da",
        Range = { 2, 5 },
        Increment = 1,
        Suffix = "con",
        CurrentValue = Settings.BringMax,
        Flag = "BON_BringMax",
        Callback = function(v) Settings.BringMax = v end,
    })

    -- ===== Tab Di Chuyen =====
    local TravelTab = Window:CreateTab("Di Chuyen", 4483362458)
    TravelTab:CreateSection("Sea hien tai")
    TravelTab:CreateLabel("Dang o Sea " .. CURRENT_SEA .. " (PlaceId " .. game.PlaceId .. ")")
    TravelTab:CreateLabel("Bat di chuyen se TU TAT Auto Farm de tranh 2 module danh nhau.")

    local seaIslands = getSeaIslands()
    local islandNames = {}
    for _, is in ipairs(seaIslands) do
        table.insert(islandNames, is.name)
    end
    if #islandNames > 0 and not findIslandByName(Settings.SelectedIsland) then
        Settings.SelectedIsland = islandNames[1]
    end
    TravelTab:CreateSection("Chon dao")
    if #islandNames == 0 then
        TravelTab:CreateLabel("Khong co du lieu dao cho Sea nay.")
    else
        TravelTab:CreateDropdown({
            Name = "Chon dao (chon la bay toi)",
            Options = islandNames,
            CurrentOption = { Settings.SelectedIsland },
            MultipleOptions = false,
            Flag = "BON_SelectedIsland",
            Callback = function(option)
                local v = type(option) == "table" and option[1] or option
                if not v then return end
                Settings.SelectedIsland = v
                if Settings.IslandAFK then
                    bumpTravelGen() -- huy chuyen cu, vong AFK sau lay dao moi
                    setStatus("Doi dao treo: " .. v)
                else
                    requestTravelToIsland(findIslandByName(v), false)
                end
            end,
        })
        TravelTab:CreateButton({
            Name = "Bay toi dao (1 lan)",
            Callback = function()
                requestTravelToIsland(findIslandByName(Settings.SelectedIsland), false)
            end,
        })
    end

    TravelTab:CreateSection("Toc do")
    TravelTab:CreateSlider({
        Name = "Toc do bay (di chuyen)",
        Range = { 100, 350 },
        Increment = 25,
        Suffix = "studs/s",
        CurrentValue = Settings.TravelSpeed,
        Flag = "BON_TravelSpeed",
        Callback = function(v) Settings.TravelSpeed = v end,
    })
    TravelTab:CreateButton({
        Name = "Dung di chuyen (huy chuyen dang chay)",
        Callback = function()
            bumpTravelGen() -- huy moi chuyen di chuyen dang chay
            Settings.TravelMove = false
            Settings.IslandAFK = false
            pcall(function()
                if Module._afkToggle then
                    Module._afkToggle:Set(false)
                end
            end)
            if Module._farmTravel then
                -- Dang farm-travel ma an dung -> tat luon farm keo farmLoop goi lai
                Settings.Farm = false
                pcall(function()
                    if Module._farmToggle then
                        Module._farmToggle:Set(false)
                    end
                end)
            end
            Flight.goal = nil
            Module._farmTravel = false
            setStatus("Da dung di chuyen")
        end,
    })

    TravelTab:CreateSection("Bypass teleporter")
    TravelTab:CreateLabel("Dich toi dao -> reset chet -> game nhan spawn o dao.")
    local afkToggle = TravelTab:CreateToggle({
        Name = "Treo dao (bypass)",
        CurrentValue = Settings.IslandAFK,
        Flag = "BON_IslandAFK",
        Callback = function(v)
            -- Guard 2 chieu (spec): Auto Bounty dang bat -> CHAN + BAO LOI neu ten module
            if v and Settings.Bounty then
                setStatus("Không bật được Treo dao vì Auto Bounty đang bật")
                pcall(function() afkToggle:Set(false) end)
                Settings.IslandAFK = false
                return
            end
            if v then
                local island = findIslandByName(Settings.SelectedIsland)
                if not island then
                    setStatus("Chua chon dao")
                    pcall(function() afkToggle:Set(false) end)
                    Settings.IslandAFK = false
                    return
                end
                Settings.IslandAFK = true
                stopFarmForTravel("Treo dao: " .. island.name .. " (da tat Auto Farm)")
                islandAfkLoop()
            else
                Settings.IslandAFK = false
            end
        end,
    })
    Module._afkToggle = afkToggle
    TravelTab:CreateButton({
        Name = "Bypass tele 1 lan",
        Callback = function()
            requestTravelToIsland(findIslandByName(Settings.SelectedIsland), true)
        end,
    })

    -- ===== Tab Mua Do =====
    local ShopTab = Window:CreateTab("Mua Do", 4483362458)
    ShopTab:CreateSection("Auto Buy")
    ShopTab:CreateToggle({
        Name = "Auto Buy (uu tien Melee)",
        CurrentValue = Settings.AutoBuy,
        Flag = "BON_AutoBuy",
        Callback = function(v) Settings.AutoBuy = v end,
    })
    local moneyLabel = ShopTab:CreateLabel("Tien: dang tai...")

    local shopButtons = {}
    local function refreshShopButtons()
        local beli, frag = getMoney()
        pcall(function()
            moneyLabel:Set("Beli: " .. fmtNum(beli) .. " | Frag: " .. fmtNum(frag) .. " - cham nut duoi de mua thu cong")
        end)
        for _, entry in ipairs(shopButtons) do
            local item = entry.item
            local owned = shopBought[item.name] or (item.tools and findToolByNames(item.tools) ~= nil)
            pcall(function()
                entry.button:Set(owned and ("Da co: " .. item.display) or ("Mua " .. item.display .. " | " .. priceText(item)))
            end)
        end
    end

    for idx, item in ipairs(SHOP_ITEMS) do
        if idx == 1 then ShopTab:CreateSection("Haki / Ability") end
        if idx == 5 then ShopTab:CreateSection("Vo (Melee) - tu thap toi cao") end
        local button = ShopTab:CreateButton({
            Name = "Mua " .. item.display .. " | " .. priceText(item),
            Callback = function()
                tryBuyItem(item, true)
                refreshShopButtons()
            end,
        })
        table.insert(shopButtons, { item = item, button = button })
    end
    ShopTab:CreateButton({
        Name = "Lam moi tien/gia",
        Callback = function() refreshShopButtons() end,
    })
    refreshShopButtons()

    task.spawn(function()
        while sessionAlive() and Module._window == Window do
            refreshShopButtons()
            task.wait(2)
        end
    end)

    local PvpTab = Window:CreateTab("PVP", 4483362458)
    PvpTab:CreateSection("Aimbot")
    PvpTab:CreateLabel("Farm / Bounty / Aimbot chan nhau: bat module nay khi module kia dang chay se bi tu choi.")
    local aimbotToggle = PvpTab:CreateToggle({
        Name = "Aimbot",
        CurrentValue = PVP.Aimbot,
        Flag = "PvpAimbot",
        Callback = function(v)
            -- CHAN + BAO LOI (spec moi, thay cho label canh bao cu): tam giac xung dot
            -- Auto Farm <-> Auto Bounty <-> Aimbot.
            if v and Settings.Bounty then
                setStatus("Không bật được Aimbot vì Auto Bounty đang bật")
                pcall(function() aimbotToggle:Set(false) end)
                PVP.Aimbot = false
                return
            end
            if v and Settings.Farm then
                setStatus("Không bật được Aimbot vì Auto Farm đang bật")
                pcall(function() aimbotToggle:Set(false) end)
                PVP.Aimbot = false
                return
            end
            local wasOn = PVP.Aimbot
            PVP.Aimbot = v
            -- Tat that moi doi status: Set(false) tu nhanh bi chan goi lai
            -- callback(false) voi wasOn=false -> giu nguyen thong bao loi chan
            if v then
                setStatus("PVP: Aimbot BAT")
            elseif wasOn then
                setStatus("PVP: Aimbot TAT")
            end
        end,
    })
    Module._pvpAimToggle = aimbotToggle
    PvpTab:CreateToggle({
        Name = "POV Visual (vong vung aim)",
        CurrentValue = PVP.AimPOV,
        Flag = "PvpAimPOV",
        Callback = function(v) PVP.AimPOV = v end,
    })
    PvpTab:CreateSlider({
        Name = "FOV (vung aim)",
        Range = { 10, 360 },
        Increment = 10,
        CurrentValue = PVP.AimFOV,
        Flag = "PvpAimFOV",
        Callback = function(v) PVP.AimFOV = math.floor(v) end,
    })
    PvpTab:CreateDropdown({
        Name = "Che do aim",
        Options = { "Smooth", "Lock" },
        CurrentOption = { "Smooth" },
        MultipleOptions = false,
        Flag = "PvpAimMode",
        Callback = function(v)
            PVP.AimMode = (type(v) == "table" and v[1]) or v
        end,
    })
    PvpTab:CreateSlider({
        Name = "Toc do Smooth",
        Range = { 1, 100 },
        Increment = 1,
        CurrentValue = PVP.AimSpeed,
        Flag = "PvpAimSpeed",
        Callback = function(v) PVP.AimSpeed = math.floor(v) end,
    })
    PvpTab:CreateToggle({
        Name = "Wall Check (co tuong thi khong aim)",
        CurrentValue = PVP.WallCheck,
        Flag = "PvpWallCheck",
        Callback = function(v) PVP.WallCheck = v end,
    })

    PvpTab:CreateSection("ESP")
    PvpTab:CreateToggle({
        Name = "ESP",
        CurrentValue = PVP.ESP,
        Flag = "PvpESP",
        Callback = function(v)
            PVP.ESP = v
            setStatus(v and "PVP: ESP BAT" or "PVP: ESP TAT")
        end,
    })
    PvpTab:CreateToggle({
        Name = "ESP Box (hitbox)",
        CurrentValue = PVP.ESPBox,
        Flag = "PvpESPBox",
        Callback = function(v) PVP.ESPBox = v end,
    })
    PvpTab:CreateToggle({
        Name = "ESP Tia",
        CurrentValue = PVP.ESPTracer,
        Flag = "PvpESPTracer",
        Callback = function(v) PVP.ESPTracer = v end,
    })
    PvpTab:CreateToggle({
        Name = "ESP Highlight",
        CurrentValue = PVP.ESPHighlight,
        Flag = "PvpESPHighlight",
        Callback = function(v) PVP.ESPHighlight = v end,
    })
    PvpTab:CreateToggle({
        Name = "ESP Ten / khoang cach / mau",
        CurrentValue = PVP.ESPInfo,
        Flag = "PvpESPInfo",
        Callback = function(v) PVP.ESPInfo = v end,
    })

    PvpTab:CreateSection("Friendly (hien mau xanh la)")
    local friendlyLabel = PvpTab:CreateLabel("Danh sach: (trong)")
    local function refreshFriendlyLabel()
        if #PVP.Friendly == 0 then
            friendlyLabel:Set("Danh sach: (trong)")
        else
            friendlyLabel:Set("Danh sach: " .. table.concat(PVP.Friendly, ", "))
        end
    end
    PvpTab:CreateInput({
        Name = "Them Friendly",
        PlaceholderText = "Nhap ten / DisplayName / UserId roi Enter",
        RemoveTextAfterFocusLost = true,
        Callback = function(text)
            text = tostring(text or ""):gsub("^%s+", ""):gsub("%s+$", "")
            if text ~= "" then
                table.insert(PVP.Friendly, text)
                refreshFriendlyLabel()
                setStatus("PVP: da them friendly " .. text)
            end
        end,
    })
    PvpTab:CreateButton({
        Name = "Xoa het Friendly",
        Callback = function()
            PVP.Friendly = {}
            refreshFriendlyLabel()
            setStatus("PVP: da xoa het friendly")
        end,
    })

    -- ===== Auto Bounty (v17) =====
    PvpTab:CreateSection("Auto Bounty")
    PvpTab:CreateLabel("Chan xung dot: dang bat Farm/Aimbot/Di chuyen thi khong bat duoc Bounty (va nguoc lai).")
    PvpTab:CreateLabel("Bounty rule: chi danh lv>=20 va lv>=75% lv minh (khong cap tren). Ally/Marines khong detect duoc.")
    local bountyToggle = PvpTab:CreateToggle({
        Name = "Auto Bounty",
        CurrentValue = false,
        Flag = "BountyEnabled",
        Callback = function(v)
            if v then
                -- CHAN + BAO LOI (spec moi 2026-10-11, thay cho co che tu tat cu):
                -- bat khi module xung dot dang hoat dong -> KHONG cho bat, neu ten
                -- module dang bat, toggle tu tra ve off.
                if Settings.Farm then
                    setStatus("Không bật được Auto Bounty vì Auto Farm đang bật")
                    pcall(function() bountyToggle:Set(false) end)
                    return
                end
                if PVP.Aimbot then
                    setStatus("Không bật được Auto Bounty vì Aimbot đang bật")
                    pcall(function() bountyToggle:Set(false) end)
                    return
                end
                -- Di chuyen / Treo dao cung chiem Flight.goal -> chan luon, khong tat ngam
                if Settings.TravelMove then
                    setStatus("Không bật được Auto Bounty vì Di chuyển đang bật")
                    pcall(function() bountyToggle:Set(false) end)
                    return
                end
                if Settings.IslandAFK then
                    setStatus("Không bật được Auto Bounty vì Treo dao đang bật")
                    pcall(function() bountyToggle:Set(false) end)
                    return
                end
                setStatus("Bounty: BAT")
                bountyStart()
            else
                local wasOn = Settings.Bounty
                Settings.Bounty = false
                Bounty.Enabled = false
                Bounty.Gen = Bounty.Gen + 1 -- huy vong bounty dang chay, chong ket co
                -- Chi don dep khi module THUC SU dang bat: neu vua bi chan
                -- (wasOn == false) thi khong duoc don Flight.goal / release key
                -- cua module khac dang chay (travel/farm), tranh tac dung phu.
                if wasOn then
                    bountyCleanup()
                    setStatus("Bounty: TAT")
                end
            end
        end,
    })
    Module._bountyToggle = bountyToggle
    PvpTab:CreateToggle({
        Name = "Auto Haki (Ken + Buso)",
        CurrentValue = false,
        Flag = "BountyAutoHaki",
        Callback = function(v)
            Bounty.AutoHaki = v
            setStatus(v and "Bounty: Auto Haki BAT (Ken + Buso)" or "Bounty: Auto Haki TAT")
        end,
    })
    PvpTab:CreateDropdown({
        Name = "Mode",
        Options = { "Basic (legit)", "Du kích" },
        CurrentOption = { Bounty.Mode },
        MultipleOptions = false,
        Flag = "BountyMode",
        Callback = function(option)
            local v = type(option) == "table" and option[1] or option
            if v then
                Bounty.Mode = v
                setStatus("Bounty mode: " .. v)
            end
        end,
    })
    PvpTab:CreateSlider({
        Name = "HP an toan %",
        Range = { 10, 50 },
        Increment = 1,
        Suffix = "%",
        CurrentValue = Bounty.SafeHP,
        Flag = "BountySafeHP",
        Callback = function(v) Bounty.SafeHP = math.floor(v) end,
    })
    PvpTab:CreateSlider({
        Name = "Do cao safe",
        Range = { 1000, 5000 },
        Increment = 100,
        Suffix = "studs",
        CurrentValue = Bounty.SafeHeight,
        Flag = "BountySafeHeight",
        Callback = function(v) Bounty.SafeHeight = math.floor(v) end,
    })
    PvpTab:CreateSlider({
        Name = "Do cao cho hoi chieu",
        Range = { 10, 500 },
        Increment = 10,
        Suffix = "studs",
        CurrentValue = Bounty.WaitHeight,
        Flag = "BountyWaitHeight",
        Callback = function(v) Bounty.WaitHeight = math.floor(v) end,
    })
    PvpTab:CreateSlider({
        Name = "Giu chieu",
        Range = { 0, 3 },
        Increment = 0.1,
        Suffix = "s",
        CurrentValue = Bounty.HoldTime,
        Flag = "BountyHoldTime",
        Callback = function(v) Bounty.HoldTime = v end,
    })
    PvpTab:CreateSlider({
        Name = "Tam chieu (0 = tu dong)",
        Range = { 0, 1000 },
        Increment = 10,
        Suffix = "studs",
        CurrentValue = Bounty.RangeOverride,
        Flag = "BountyRangeOverride",
        Callback = function(v) Bounty.RangeOverride = math.floor(v) end,
    })
    local bountyTargetLabel = PvpTab:CreateLabel("Danh sach target: (trong)")
    Module._bountyTargetLabel = bountyTargetLabel
    task.spawn(function()
        while sessionAlive() and Module._window == Window do
            pcall(function()
                if Module._bountyTargetLabel then
                    Module._bountyTargetLabel:Set(bountyTargetLabelText())
                end
            end)
            task.wait(2)
        end
    end)

    pcall(function()
        lib:Notify({
            Title = "BON Blox Fruits v17",
            Content = "Da tai Rayfield UI. Farm: tab Farm; di chuyen: tab Di Chuyen; PVP: tab PVP (co Auto Bounty).",
            Duration = 5,
            Image = 4483362458,
        })
    end)
    return Window
end

function Module.Start()
    if Module._gui then return end
    Module._gui = buildGui()
    print("[BloxFruits] Da tai GUI v17 (Rayfield). Level hien tai: " .. tostring(Level.Value))
end

function Module.Stop()
    Settings.Farm = false
    Settings.AutoBuy = false
    Settings.IslandAFK = false
    Settings.TravelMove = false
    Flight.goal = nil
    -- Don dep Auto Bounty: ha co, nha phim ao, huy vong chay, reset toggle UI
    Settings.Bounty = false
    Bounty.Enabled = false
    Bounty.AutoHaki = false
    Bounty.Gen = Bounty.Gen + 1
    bountyCleanup()
    pcall(function()
        if Module._bountyToggle then Module._bountyToggle:Set(false) end
    end)
    PVP.Aimbot = false
    PVP.AimPOV = false
    PVP.ESP = false
    if fovCircle then
        pcall(function() fovCircle.Visible = false end)
    end
    for _, e in pairs(espCache) do
        pvpHideESP(e)
        pvpDestroyESP(e)
    end
    Module._statusLabel = nil
    Module._farmToggle = nil
    Module._pvpAimToggle = nil
    Module._bountyToggle = nil
    Module._bountyTargetLabel = nil
    Module._islandAfkRunning = false
    if Module._rayfield then
        pcall(function() Module._rayfield:Destroy() end)
        Module._rayfield = nil
    end
    Module._window = nil
    Module._gui = nil
end

Module.Start()
print("[BloxFruits] San sang (v17). Bat 'Auto Farm' tren Rayfield de farm. Level: " .. tostring(Level.Value))

return Module

