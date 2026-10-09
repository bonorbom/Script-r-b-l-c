-- BON Blox Fruits Auto Farm (v2)
-- Theo yeu cau cua Bon:
-- 1) Nhan quest: bay toi cho NPC giao quest roi moi nhan, xong tim mob theo quest.
-- 2) Khong teleport: chi fly muot toi quai, toc do fly chinh 100-350; tracking giu lock
--    1 con quai den khi no chet hoac xong quest/nhan quest moi moi nha.
-- 3) Auto click "ghi de": farm dang bat la script tu click lien tuc, Bon bam gi cung ke.
-- Du lieu quest/mob theo wiki Blox Fruits (Update 30). Khong hardcode toa do dao:
-- tu quet NPC/mob trong workspace nen Sea 1 rework cung khong lech bai.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")

local Player = Players.LocalPlayer

-- Chi chay trong Blox Fruits (3 sea)
local SEA_PLACES = { [2753915549] = true, [4442272183] = true, [7449423635] = true }
if not SEA_PLACES[game.PlaceId] then
    print("[BloxFruits] Khong phai Blox Fruits, bo qua.")
    return nil
end

local Module = {}

-- ===== Cai dat =====
local Settings = {
    Farm = false,          -- bat/tat auto farm
    BringMob = true,       -- gom mob ve gan minh
    AutoStat = false,      -- tu cong diem stat
    StatName = "Melee",    -- Melee / Defense / Sword / Gun / Demon Fruit
    FlySpeed = 200,        -- toc do bay 100-350 (chinh bang nut -/+ tren GUI)
    HoverHeight = 25,      -- do cao dung tren dau mob
    BringRadius = 60,      -- ban kinh gom mob
    AttackRate = 0.12,     -- giay giua moi lan click
}
Module.Settings = Settings

-- ===== Du lieu quest: Level, Mob, QuestId, ChiSo, NPC giao quest =====
-- Bo qua quest boss. QuestId la ten remote StartQuest cua game.
local QUESTS = {
    -- Sea 1
    {0, "Bandit", "BanditQuest1", 1, "Bandit Quest Giver"},
    {10, "Monkey", "JungleQuest", 1, "Adventurer"},
    {15, "Gorilla", "JungleQuest", 2, "Adventurer"},
    {30, "Pirate", "BuggyQuest1", 1, "Pirate Adventurer"},
    {40, "Brute", "BuggyQuest1", 2, "Pirate Adventurer"},
    {60, "Desert Bandit", "DesertQuest", 1, "Desert Adventurer"},
    {75, "Desert Officer", "DesertQuest", 2, "Desert Adventurer"},
    {90, "Snow Bandit", "SnowQuest", 1, "Villager"},
    {100, "Snowman", "SnowQuest", 2, "Villager"},
    {120, "Chief Petty Officer", "MarineQuest2", 1, "Marine"},
    {150, "Sky Bandit", "SkyQuest", 1, "Sky Adventurer"},
    {175, "Dark Master", "SkyQuest", 2, "Sky Adventurer"},
    {190, "Prisoner", "PrisonQuest", 1, "Jail Keeper"},
    {210, "Dangerous Prisoner", "PrisonQuest", 2, "Jail Keeper"},
    {250, "Toga Warrior", "ColosseumQuest", 1, "Colosseum Quest Giver"},
    {275, "Gladiator", "ColosseumQuest", 2, "Colosseum Quest Giver"},
    {300, "Military Soldier", "MagmaQuest", 1, "The Mayor"},
    {325, "Military Spy", "MagmaQuest", 2, "The Mayor"},
    {375, "Fishman Warrior", "FishmanQuest", 1, "King Neptune"},
    {400, "Fishman Commando", "FishmanQuest", 2, "King Neptune"},
    {450, "God's Guard", "SkyQuest2", 1, "Mole"},
    {475, "Shanda", "SkyQuest2", 2, "Mole"},
    {525, "Royal Squad", "SkyQuest2", 3, "Sky Quest Giver 2"},
    {550, "Royal Soldier", "SkyQuest2", 4, "Sky Quest Giver 2"},
    {625, "Galley Pirate", "FountainQuest", 1, "Freezeburg Quest Giver"},
    {650, "Galley Captain", "FountainQuest", 2, "Freezeburg Quest Giver"},
    -- Sea 2
    {700, "Raider", "Area1Quest", 1, "Area 1 Quest Giver"},
    {725, "Mercenary", "Area1Quest", 2, "Area 1 Quest Giver"},
    {775, "Swan Pirate", "Area2Quest", 1, "Area 2 Quest Giver"},
    {800, "Factory Staff", "Area2Quest", 2, "Area 2 Quest Giver"},
    {875, "Marine Lieutenant", "GreenZoneQuest", 1, "Marine Quest Giver"},
    {900, "Marine Captain", "GreenZoneQuest", 2, "Marine Quest Giver"},
    {950, "Zombie", "GraveyardQuest", 1, "Graveyard Quest Giver"},
    {975, "Vampire", "GraveyardQuest", 2, "Graveyard Quest Giver"},
    {1000, "Snow Trooper", "SnowMountainQuest", 1, "Snow Quest Giver"},
    {1050, "Winter Warrior", "SnowMountainQuest", 2, "Snow Quest Giver"},
    {1100, "Lab Subordinate", "IceQuest", 1, "Ice Quest Giver"},
    {1125, "Horned Warrior", "IceQuest", 2, "Ice Quest Giver"},
    {1175, "Magma Ninja", "FireQuest", 1, "Fire Quest Giver"},
    {1200, "Lava Pirate", "FireQuest", 2, "Fire Quest Giver"},
    {1250, "Ship Deckhand", "ShipQuest1", 1, "Rear Crew Quest Giver"},
    {1275, "Ship Engineer", "ShipQuest1", 2, "Rear Crew Quest Giver"},
    {1300, "Ship Steward", "ShipQuest2", 1, "Front Crew Quest Giver"},
    {1325, "Ship Officer", "ShipQuest2", 2, "Front Crew Quest Giver"},
    {1350, "Arctic Warrior", "IceCastleQuest", 1, "Frost Quest Giver"},
    {1375, "Snow Lurker", "IceCastleQuest", 2, "Frost Quest Giver"},
    {1425, "Sea Soldier", "ForgottenIslandQuest", 1, "Forgotten Quest Giver"},
    {1450, "Water Fighter", "ForgottenIslandQuest", 2, "Forgotten Quest Giver"},
    -- Sea 3
    {1500, "Pirate Millionaire", "PortTownQuest", 1, "Pirate Port Quest Giver"},
    {1525, "Pistol Billionaire", "PortTownQuest", 2, "Pirate Port Quest Giver"},
    {1575, "Dragon Crew Warrior", "DragonCrewQuest", 1, "Dragon Crew Quest Giver"},
    {1600, "Dragon Crew Archer", "DragonCrewQuest", 2, "Dragon Crew Quest Giver"},
    {1625, "Hydra Enforcer", "HydraTownQuest", 1, "Hydra Town Quest Giver"},
    {1650, "Venomous Assailant", "HydraTownQuest", 2, "Hydra Town Quest Giver"},
    {1700, "Marine Commodore", "GreatTreeQuest", 1, "Marine Tree Quest Giver"},
    {1725, "Marine Rear Admiral", "GreatTreeQuest", 2, "Marine Tree Quest Giver"},
    {1775, "Fishman Raider", "FloatingTurtleQuest", 1, "Turtle Adventure Quest Giver"},
    {1800, "Fishman Captain", "FloatingTurtleQuest", 2, "Turtle Adventure Quest Giver"},
    {1825, "Forest Pirate", "DeepForestQuest", 1, "Deep Forest Quest Giver"},
    {1850, "Mythological Pirate", "DeepForestQuest", 2, "Deep Forest Quest Giver"},
    {1900, "Jungle Pirate", "DeepForestQuest2", 1, "Deep Forest Area 2 Quest Giver"},
    {1925, "Musketeer Pirate", "DeepForestQuest2", 2, "Deep Forest Area 2 Quest Giver"},
    {1975, "Reborn Skeleton", "HauntedCastleQuest1", 1, "Haunted Castle Quest Giver 1"},
    {2000, "Living Zombie", "HauntedCastleQuest1", 2, "Haunted Castle Quest Giver 1"},
    {2025, "Demonic Soul", "HauntedCastleQuest2", 1, "Haunted Castle Quest Giver 2"},
    {2050, "Possessed Mummy", "HauntedCastleQuest2", 2, "Haunted Castle Quest Giver 2"},
    {2075, "Peanut Scout", "PeanutQuest", 1, "Peanut Quest Giver"},
    {2100, "Peanut President", "PeanutQuest", 2, "Peanut Quest Giver"},
    {2125, "Ice Cream Chef", "IceCreamQuest", 1, "Ice Cream Quest Giver"},
    {2150, "Ice Cream Commander", "IceCreamQuest", 2, "Ice Cream Quest Giver"},
    {2200, "Cookie Crafter", "CakeQuest1", 1, "Cake Quest Giver 1"},
    {2225, "Cake Guard", "CakeQuest1", 2, "Cake Quest Giver 1"},
    {2250, "Baking Staff", "CakeQuest2", 1, "Cake Quest Giver 2"},
    {2275, "Head Baker", "CakeQuest2", 2, "Cake Quest Giver 2"},
    {2300, "Cocoa Warrior", "ChocolateQuest1", 1, "Chocolate Quest Giver 1"},
    {2325, "Chocolate Bar Battler", "ChocolateQuest1", 2, "Chocolate Quest Giver 1"},
    {2350, "Sweet Thief", "ChocolateQuest2", 1, "Chocolate Quest Giver 2"},
    {2375, "Candy Rebel", "ChocolateQuest2", 2, "Chocolate Quest Giver 2"},
    {2400, "Candy Pirate", "CandyQuest", 1, "Candy Cane Quest Giver"},
    {2425, "Snow Demon", "CandyQuest", 2, "Candy Cane Quest Giver"},
    {2450, "Isle Outlaw", "TikiQuest1", 1, "Tiki Quest Giver 1"},
    {2475, "Island Boy", "TikiQuest1", 2, "Tiki Quest Giver 1"},
    {2500, "Sun-kissed Warrior", "TikiQuest2", 1, "Tiki Quest Giver 2"},
    {2525, "Isle Champion", "TikiQuest2", 2, "Tiki Quest Giver 2"},
    {2550, "Serpent Hunter", "TikiQuest3", 1, "Tiki Quest Giver 3"},
    {2575, "Skull Slayer", "TikiQuest3", 2, "Tiki Quest Giver 3"},
    {2600, "Reef Bandit", "SubmergedQuest1", 1, "Submerged Quest Giver 1"},
    {2625, "Coral Pirate", "SubmergedQuest1", 2, "Submerged Quest Giver 1"},
    {2650, "Sea Chanter", "SubmergedQuest2", 1, "Submerged Quest Giver 2"},
    {2675, "High Disciple", "SubmergedQuest3", 1, "Submerged Quest Giver 3"},
    {2700, "Grand Devotee", "SubmergedQuest3", 2, "Submerged Quest Giver 3"},
}

-- ===== Tien ich =====
local CommF = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")
local Data = Player:WaitForChild("Data")
local Level = Data:WaitForChild("Level")

local function getChar()
    local char = Player.Character
    if not char then return nil, nil, nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    return char, hum, hrp
end

local function getQuestForLevel(lv)
    local best = QUESTS[1]
    for _, q in ipairs(QUESTS) do
        if lv >= q[1] then best = q else break end
    end
    return best
end

-- Quest dang active tren GUI game (tra ve tieu de quest, nil = chua co quest)
local function currentQuestText()
    local gui = Player:FindFirstChild("PlayerGui")
    local main = gui and gui:FindFirstChild("Main")
    local quest = main and main:FindFirstChild("Quest")
    if not quest or not quest.Visible then return nil end
    local titleObj = quest:FindFirstChild("Container") and quest.Container:FindFirstChild("QuestTitle")
        and quest.Container.QuestTitle:FindFirstChild("Title")
    if titleObj then return titleObj.Text end
    return ""
end

local function questMatchesMob(text, mobName)
    if not text then return false end
    local needle = string.lower((string.gsub(mobName, "s$", "")))
    return string.find(string.lower(text), needle, 1, true) ~= nil
end

local statusText = "San sang"
local function setStatus(s)
    statusText = s
    if Module._statusLabel then
        Module._statusLabel.Text = "Trang thai: " .. s
    end
end

-- ===== Fly muot (khong teleport) =====
-- Di chuyen 1 buoc ve phia goal theo toc do FlySpeed; tra ve true neu da toi noi.
local function flyStep(goalPos, dt)
    local _, _, hrp = getChar()
    if not hrp then return true end
    local delta = goalPos - hrp.Position
    local dist = delta.Magnitude
    if dist <= 4 then return true end
    local step = math.min(dist, Settings.FlySpeed * dt)
    local newPos = hrp.Position + delta.Unit * step
    pcall(function() hrp.AssemblyLinearVelocity = Vector3.zero end)
    local flat = Vector3.new(goalPos.X - newPos.X, 0, goalPos.Z - newPos.Z)
    if flat.Magnitude > 1 then
        hrp.CFrame = CFrame.new(newPos, newPos + flat)
    else
        hrp.CFrame = CFrame.new(newPos) * (hrp.CFrame - hrp.CFrame.Position)
    end
    return false
end

-- Bay muot toi 1 diem co dinh, dung khi Farm tat hoac het timeout (giay)
local function flyTo(goalPos, timeout)
    local t0 = tick()
    while Settings.Farm and (tick() - t0) < (timeout or 25) do
        if flyStep(goalPos, RunService.Heartbeat:Wait()) then
            return true
        end
    end
    return false
end

local function findEnemy(mobName)
    local enemies = workspace:FindFirstChild("Enemies")
    if not enemies then return nil end
    local _, _, hrp = getChar()
    local best, bestDist = nil, math.huge
    for _, e in ipairs(enemies:GetChildren()) do
        local hum = e:FindFirstChildOfClass("Humanoid")
        local root = e:FindFirstChild("HumanoidRootPart")
        if hum and root and hum.Health > 0 and string.find(e.Name, mobName, 1, true) then
            local d = hrp and (root.Position - hrp.Position).Magnitude or 0
            if d < bestDist then best, bestDist = e, d end
        end
    end
    return best
end

local function findGiverPos(giverName)
    local npcs = workspace:FindFirstChild("NPCs")
    if not npcs then return nil end
    for _, n in ipairs(npcs:GetChildren()) do
        if string.find(n.Name, giverName, 1, true) then
            local root = n:FindFirstChild("HumanoidRootPart") or n:FindFirstChild("Head")
            if root then return root.Position end
        end
    end
    return nil
end

local function equipMelee()
    local char, hum = getChar()
    if not char or not hum then return nil end
    local equipped = char:FindFirstChildOfClass("Tool")
    if equipped then return equipped end
    local backpack = Player:FindFirstChild("Backpack")
    if not backpack then return nil end
    local fallback = nil
    for _, t in ipairs(backpack:GetChildren()) do
        if t:IsA("Tool") then
            if t.ToolTip == "Melee" or t.ToolTip == "Sword" then
                hum:EquipTool(t)
                return t
            end
            fallback = fallback or t
        end
    end
    if fallback then hum:EquipTool(fallback) end
    return fallback
end

-- ===== Nhan quest: bay toi cho NPC truoc =====
local function ensureQuest()
    local q = getQuestForLevel(Level.Value)
    local mobName = q[2]
    local cur = currentQuestText()
    if questMatchesMob(cur, mobName) then
        return q
    end
    if cur then
        setStatus("Huy quest cu...")
        pcall(function() CommF:InvokeServer("AbandonQuest") end)
        task.wait(0.6)
    end
    -- Bay toi cho nhan nhiem vu (neu thay NPC trong workspace)
    local giverPos = findGiverPos(q[5])
    if giverPos then
        setStatus("Bay toi cho nhan quest (" .. mobName .. ")...")
        flyTo(giverPos + Vector3.new(0, 6, 0), 25)
    else
        setStatus("Chua thay NPC, nhan quest tu xa: " .. mobName)
    end
    pcall(function() CommF:InvokeServer("StartQuest", q[3], q[4]) end)
    task.wait(0.6)
    return q
end

-- ===== Danh 1 con quai: fly tracking + auto click ghi de =====
-- Giu lock con nay den khi: no chet, quest xong, minh chet, hoac tat Farm.
local function fightMob(enemy, mobName)
    local tool = equipMelee()
    local hadQuest = currentQuestText() ~= nil
    local clickAcc, questAcc = 0, 0
    while Settings.Farm do
        local dt = RunService.Heartbeat:Wait()
        local eHum = enemy:FindFirstChildOfClass("Humanoid")
        local eRoot = enemy:FindFirstChild("HumanoidRootPart")
        local char, hum, hrp = getChar()
        if not eHum or not eRoot or eHum.Health <= 0 or not enemy.Parent then break end
        if not char or not hum or not hrp or hum.Health <= 0 then break end

        -- Fly tracking: bam sat tren dau quai, khong nha giua chung
        flyStep(eRoot.Position + Vector3.new(0, Settings.HoverHeight, 0), dt)

        clickAcc = clickAcc + dt
        if clickAcc >= Settings.AttackRate then
            clickAcc = 0
            -- Gom mob cung loai o gan ve duoi chan minh
            if Settings.BringMob then
                local enemies = workspace:FindFirstChild("Enemies")
                if enemies then
                    for _, e in ipairs(enemies:GetChildren()) do
                        local h = e:FindFirstChildOfClass("Humanoid")
                        local r = e:FindFirstChild("HumanoidRootPart")
                        if h and r and h.Health > 0 and string.find(e.Name, mobName, 1, true) then
                            if (r.Position - hrp.Position).Magnitude <= Settings.BringRadius then
                                r.CFrame = CFrame.new(hrp.Position + Vector3.new(0, -Settings.HoverHeight + 3, 0))
                                r.CanCollide = false
                            end
                        end
                    end
                end
            end
            -- Auto click ghi de: cu click lien tuc, Bon co bam gi khac cung khong dung
            if tool and tool.Parent ~= char then tool = nil end
            if not tool then tool = equipMelee() end
            if tool then pcall(function() tool:Activate() end) end
            if mouse1click then pcall(mouse1click) end
        end

        -- Kiem tra quest xong (moi ~0.3s): xong la nha lock, ve nhan quest moi
        questAcc = questAcc + dt
        if questAcc >= 0.3 then
            questAcc = 0
            if hadQuest and currentQuestText() == nil then break end
        end
    end
end

-- ===== Vong lap farm chinh =====
local function farmLoop()
    while Settings.Farm do
        local ok, err = pcall(function()
            local char, hum, hrp = getChar()
            if not char or not hum or not hrp or hum.Health <= 0 then
                setStatus("Cho nhan vat hoi sinh...")
                task.wait(1)
                return
            end

            local q = ensureQuest()
            if not Settings.Farm then return end

            -- Tu cong stat
            if Settings.AutoStat then
                local points = Data:FindFirstChild("Points")
                if points and points.Value > 0 then
                    pcall(function() CommF:InvokeServer("AddPoint", Settings.StatName, 1) end)
                end
            end

            local enemy = findEnemy(q[2])
            if not enemy then
                setStatus("Tim bai " .. q[2] .. "...")
                local giverPos = findGiverPos(q[5])
                if giverPos then flyTo(giverPos + Vector3.new(0, 8, 0), 10) end
                task.wait(0.7)
                return
            end

            setStatus("Dang danh: " .. q[2])
            fightMob(enemy, q[2])
        end)
        if not ok then
            setStatus("Loi nhe, thu lai: " .. tostring(err))
            task.wait(1)
        end
        task.wait(0.1)
    end
    setStatus("Da tat farm")
end

-- Noclip khi farm (tranh ket tuong/san)
RunService.Stepped:Connect(function()
    if not Settings.Farm then return end
    local char = Player.Character
    if char then
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end
end)

-- Anti AFK
Player.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    task.wait(0.5)
    VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
end)

-- ===== GUI nho cho dien thoai =====
local function buildGui()
    local gui = Instance.new("ScreenGui")
    gui.Name = "BON_BloxFruits"
    gui.ResetOnSpawn = false

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 240, 0, 302)
    frame.Position = UDim2.new(0, 10, 0, 90)
    frame.BackgroundColor3 = Color3.fromRGB(24, 26, 32)
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -40, 0, 32)
    title.Position = UDim2.new(0, 10, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "BON - Blox Fruits v2"
    title.TextColor3 = Color3.fromRGB(103, 232, 249)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = frame

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -34, 0, 2)
    closeBtn.BackgroundColor3 = Color3.fromRGB(45, 48, 58)
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.fromRGB(230, 230, 230)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 13
    closeBtn.Parent = frame
    local cc = Instance.new("UICorner")
    cc.CornerRadius = UDim.new(0, 6)
    cc.Parent = closeBtn
    closeBtn.MouseButton1Click:Connect(function()
        Settings.Farm = false
        gui:Destroy()
    end)

    local function makeToggle(y, label, get, set)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -20, 0, 40)
        btn.Position = UDim2.new(0, 10, 0, y)
        btn.BackgroundColor3 = Color3.fromRGB(38, 41, 50)
        btn.TextColor3 = Color3.fromRGB(230, 230, 230)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 13
        btn.Parent = frame
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 6)
        c.Parent = btn
        local function refresh()
            btn.Text = label .. ": " .. (get() and "BAT" or "TAT")
            btn.BackgroundColor3 = get() and Color3.fromRGB(14, 116, 144) or Color3.fromRGB(38, 41, 50)
        end
        btn.MouseButton1Click:Connect(function()
            set(not get())
            refresh()
        end)
        refresh()
        return btn
    end

    makeToggle(42, "Auto Farm", function() return Settings.Farm end, function(v)
        Settings.Farm = v
        if v then task.spawn(farmLoop) end
    end)
    makeToggle(90, "Gom Mob", function() return Settings.BringMob end, function(v) Settings.BringMob = v end)
    makeToggle(138, "Tu Cong Stat", function() return Settings.AutoStat end, function(v) Settings.AutoStat = v end)

    local statBtn = Instance.new("TextButton")
    statBtn.Size = UDim2.new(1, -20, 0, 40)
    statBtn.Position = UDim2.new(0, 10, 0, 186)
    statBtn.BackgroundColor3 = Color3.fromRGB(38, 41, 50)
    statBtn.TextColor3 = Color3.fromRGB(230, 230, 230)
    statBtn.Font = Enum.Font.Gotham
    statBtn.TextSize = 13
    statBtn.Parent = frame
    local sc = Instance.new("UICorner")
    sc.CornerRadius = UDim.new(0, 6)
    sc.Parent = statBtn
    local statList = { "Melee", "Defense", "Sword", "Gun", "Demon Fruit" }
    local statIdx = 1
    statBtn.Text = "Stat: Melee (cham de doi)"
    statBtn.MouseButton1Click:Connect(function()
        statIdx = statIdx % #statList + 1
        Settings.StatName = statList[statIdx]
        statBtn.Text = "Stat: " .. Settings.StatName .. " (cham de doi)"
    end)

    -- Toc do bay: nut - / + (100-350)
    local speedLabel = Instance.new("TextLabel")
    speedLabel.Size = UDim2.new(0, 96, 0, 36)
    speedLabel.Position = UDim2.new(0, 10, 0, 234)
    speedLabel.BackgroundTransparency = 1
    speedLabel.Text = "Toc do bay"
    speedLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
    speedLabel.Font = Enum.Font.Gotham
    speedLabel.TextSize = 13
    speedLabel.TextXAlignment = Enum.TextXAlignment.Left
    speedLabel.Parent = frame

    local speedValue = Instance.new("TextLabel")
    speedValue.Size = UDim2.new(0, 44, 0, 36)
    speedValue.Position = UDim2.new(0, 148, 0, 234)
    speedValue.BackgroundTransparency = 1
    speedValue.Text = "200"
    speedValue.TextColor3 = Color3.fromRGB(103, 232, 249)
    speedValue.Font = Enum.Font.GothamBold
    speedValue.TextSize = 14
    speedValue.Parent = frame

    local function speedBtn(x, txt, delta)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, 36, 0, 36)
        b.Position = UDim2.new(0, x, 0, 234)
        b.BackgroundColor3 = Color3.fromRGB(38, 41, 50)
        b.Text = txt
        b.TextColor3 = Color3.fromRGB(230, 230, 230)
        b.Font = Enum.Font.GothamBold
        b.TextSize = 16
        b.Parent = frame
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 6)
        c.Parent = b
        b.MouseButton1Click:Connect(function()
            Settings.FlySpeed = math.clamp(Settings.FlySpeed + delta, 100, 350)
            speedValue.Text = tostring(Settings.FlySpeed)
        end)
    end
    speedBtn(110, "-", -25)
    speedBtn(196, "+", 25)

    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, -20, 0, 26)
    status.Position = UDim2.new(0, 10, 1, -30)
    status.BackgroundTransparency = 1
    status.Text = "Trang thai: San sang"
    status.TextColor3 = Color3.fromRGB(160, 165, 175)
    status.Font = Enum.Font.Gotham
    status.TextSize = 11
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.Parent = frame
    Module._statusLabel = status

    -- Keo tha bang cam ung/chuot
    local dragging, dragStart, startPos = false, nil, nil
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)
    frame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    frame.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    local parentGui = (gethui and gethui()) or Player:WaitForChild("PlayerGui")
    gui.Parent = parentGui
    return gui
end

function Module.Start()
    if Module._gui then return end
    Module._gui = buildGui()
    print("[BloxFruits] Da tai GUI v2. Level hien tai: " .. tostring(Level.Value))
end

function Module.Stop()
    Settings.Farm = false
    if Module._gui then
        Module._gui:Destroy()
        Module._gui = nil
    end
end

Module.Start()
print("[BloxFruits] San sang (v2). Bam 'Auto Farm: BAT' tren GUI de farm. Level: " .. tostring(Level.Value))

return Module
