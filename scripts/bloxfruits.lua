-- BON Blox Fruits Auto Farm (v3)
-- Theo yeu cau cua Bon:
-- 1) Co bang toa do: biet level la tu bay toi dung dao, nhan quest tai cho, roi bay toi bai quai.
--    Sea 1 dung toa do bai quai sau Update 30 (nguon hub tao 2026-10-02) + quet NPC theo ten;
--    Sea 2/3 dung toa do NPC. Mot vai QuestId Sea 2/3 da sua theo ten chuan cong dong.
-- 2) Fast attack bang remote cua game (RegisterAttack/RegisterHit) - game nhan don ma
--    client khong can click that. Khong dung mouse1click nua. Kem buff hitbox 55 de danh xa.
-- 3) Gom quai kieu cong dong: chiem SimulationRadius + giu quai moi tick (khoa WalkSpeed,
--    tat Animator), gioi han toi da 2-5 con (mac dinh 4).
-- 4) Fly muot, khong teleport; toc do bay chinh 100-350 tren GUI; tracking khoa 1 quai
--    den khi chet hoac xong quest moi nha.

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
local IS_SEA1 = game.PlaceId == 2753915549

local Module = {}

-- ===== Cai dat =====
local Settings = {
    Farm = false,          -- bat/tat auto farm
    BringMobs = true,      -- gom quai ve duoi chan
    BringMax = 4,          -- so quai gom toi da (2-5)
    AutoStat = false,      -- tu cong diem stat
    StatName = "Melee",    -- Melee / Defense / Sword / Gun / Demon Fruit
    FlySpeed = 200,        -- toc do bay 100-350 (nut -/+ tren GUI)
    HoverHeight = 25,      -- do cao dung tren dau quai
    BringRadius = 100,     -- ban kinh gom quai
    AttackRate = 0.1,      -- giay giua moi don danh
    AttackRange = 55,      -- hitbox buff (tam danh)
}
Module.Settings = Settings

-- ===== Du lieu quest =====
-- {Level, Mob, QuestId, ChiSo, NPC giao quest, ToaDoNPC{x,y,z}, ToaDoQuai{x,y,z}}
-- Toa do quai Sea 1 = sau Update 30. Toa do NPC Sea 1 la ban cu (chi tham khao vi script quet ten NPC).
local QUESTS = {
    -- ===== SEA 1 =====
    {0, "Bandit", "BanditQuest1", 1, "Bandit Quest Giver", {1060.9, 16.5, 1547.8}, {1038.6, 41.3, 1576.5}},
    {10, "Monkey", "JungleQuest", 1, "Adventurer", {-1601.7, 36.9, 153.4}, {-1866.3, 29.9, 21.6}},
    {15, "Gorilla", "JungleQuest", 2, "Adventurer", {-1601.7, 36.9, 153.4}, {-1266.6, 14.5, -462.0}},
    {30, "Pirate", "BuggyQuest1", 1, "Pirate Adventurer", {-1140.2, 4.8, 3827.4}, {-981.0, 30.4, 3966.8}},
    {40, "Brute", "BuggyQuest1", 2, "Pirate Adventurer", {-1140.2, 4.8, 3827.4}, {-1085.9, 28.1, 4342.7}},
    {60, "Desert Bandit", "DesertQuest", 1, "Desert Adventurer", {896.5, 6.4, 4390.1}, {999.9, 7.6, 4490.3}},
    {75, "Desert Officer", "DesertQuest", 2, "Desert Adventurer", {896.5, 6.4, 4390.1}, {1523.8, 15.3, 4095.4}},
    {90, "Snow Bandit", "SnowQuest", 1, "Villager", {1386.8, 87.3, -1298.4}, {1519.5, 78.0, -1510.9}},
    {100, "Snowman", "SnowQuest", 2, "Villager", {1386.8, 87.3, -1298.4}, {1121.5, 98.2, -1669.0}},
    {120, "Chief Petty Officer", "MarineQuest2", 1, "Marine", {-5035.5, 28.7, 4324.2}, {-4763.7, 13.4, 4288.8}},
    {150, "Sky Bandit", "SkyQuest", 1, "Sky Adventurer", {-4842.1, 717.7, -2623.0}, {-4973.7, 280.7, -1119.4}},
    {175, "Dark Master", "SkyQuest", 2, "Sky Adventurer", {-4842.1, 717.7, -2623.0}, {-5283.2, 505.1, -221.0}},
    {190, "Prisoner", "PrisonerQuest", 1, "Jail Keeper", {5310.6, 0.4, 474.9}, {5278.6, 7.1, 391.6}},
    {210, "Dangerous Prisoner", "PrisonerQuest", 2, "Jail Keeper", {5310.6, 0.4, 474.9}, {5058.3, 9.1, 900.9}},
    {250, "Toga Warrior", "ColosseumQuest", 1, "Colosseum Quest Giver", {-1577.8, 7.4, -2984.5}, {-1973.1, 9.0, -2744.9}},
    {275, "Gladiator", "ColosseumQuest", 2, "Colosseum Quest Giver", {-1577.8, 7.4, -2984.5}, {-1161.9, 11.6, -3097.2}},
    {300, "Military Soldier", "MagmaQuest", 1, "The Mayor", {-5316.1, 12.3, 8517.0}, {-5623.8, 17.0, 8314.1}},
    {325, "Military Spy", "MagmaQuest", 2, "The Mayor", {-5316.1, 12.3, 8517.0}, {-5952.5, 76.9, 8742.4}},
    {375, "Fishman Warrior", "FishmanQuest", 1, "King Neptune", {61122.7, 18.5, 1569.4}, {60736.8, 23.8, 1396.3}},
    {400, "Fishman Commando", "FishmanQuest", 2, "King Neptune", {61122.7, 18.5, 1569.4}, {61808.1, 24.6, 1328.6}},
    {450, "God's Guard", "SkyExp1Quest", 1, "Mole", {-4721.9, 845.3, -1953.8}, {-4082.9, 1087.3, -414.1}},
    {475, "Shanda", "SkyExp1Quest", 2, "Mole", {-4721.9, 845.3, -1953.8}, {-6040.2, 5468.0, 1734.2}},
    {525, "Royal Squad", "SkyExp2Quest", 1, "Sky Quest Giver 2", {-7903.4, 5636.0, -1410.9}, {-6706.9, 5551.4, 1155.4}},
    {550, "Royal Soldier", "SkyExp2Quest", 2, "Sky Quest Giver 2", {-7903.4, 5636.0, -1410.9}, {-7138.5, 5541.1, 1050.8}},
    {625, "Galley Pirate", "FountainQuest", 1, "Freezeburg Quest Giver", {5258.3, 38.5, 4050.0}, {5430.4, 78.0, 3953.6}},
    {650, "Galley Captain", "FountainQuest", 2, "Freezeburg Quest Giver", {5258.3, 38.5, 4050.0}, {5409.5, 77.7, 4687.0}},
    -- ===== SEA 2 =====
    {700, "Raider", "Area1Quest", 1, "Area 1 Quest Giver", {-427.7, 73.0, 1835.9}, {-612.4, 40.0, 2557.4}},
    {725, "Mercenary", "Area1Quest", 2, "Area 1 Quest Giver", {-427.7, 73.0, 1835.9}, {-1135.9, 72.9, 1248.3}},
    {775, "Swan Pirate", "Area2Quest", 1, "Area 2 Quest Giver", {635.6, 73.1, 917.8}, {1067.0, 72.8, 1080.9}},
    {800, "Factory Staff", "Area2Quest", 2, "Area 2 Quest Giver", {635.6, 73.1, 917.8}, {386.1, 72.8, 91.8}},
    {875, "Marine Lieutenant", "MarineQuest3", 1, "Marine Quest Giver", {-2441.0, 73.0, -3217.7}, {-2583.9, 71.0, -3039.6}},
    {900, "Marine Captain", "MarineQuest3", 2, "Marine Quest Giver", {-2441.0, 73.0, -3217.7}, {-2103.9, 73.0, -3259.3}},
    {950, "Zombie", "ZombieQuest", 1, "Graveyard Quest Giver", {-5494.3, 48.5, -794.6}, {-5615.0, 49.3, -938.5}},
    {975, "Vampire", "ZombieQuest", 2, "Graveyard Quest Giver", {-5494.3, 48.5, -794.6}, {-6132.4, 9.0, -1466.2}},
    {1000, "Snow Trooper", "SnowMountainQuest", 1, "Snow Quest Giver", {607.1, 401.4, -5370.6}, {484.3, 400.8, -5472.4}},
    {1050, "Winter Warrior", "SnowMountainQuest", 2, "Snow Quest Giver", {607.1, 401.4, -5370.6}, {1226.3, 428.8, -5216.0}},
    {1100, "Lab Subordinate", "IceSideQuest", 1, "Ice Quest Giver", {-6061.8, 15.9, -4902.0}, {-5998.3, 90.0, -4386.5}},
    {1125, "Horned Warrior", "IceSideQuest", 2, "Ice Quest Giver", {-6061.8, 15.9, -4902.0}, {-6540.0, 29.2, -5718.0}},
    {1175, "Magma Ninja", "FireSideQuest", 1, "Fire Quest Giver", {-5429.0, 16.0, -5298.0}, {-5711.4, 47.4, -5658.5}},
    {1200, "Lava Pirate", "FireSideQuest", 2, "Fire Quest Giver", {-5429.0, 16.0, -5298.0}, {-5111.3, 32.2, -5115.9}},
    {1250, "Ship Deckhand", "ShipQuest1", 1, "Rear Crew Quest Giver", {1040.3, 125.1, 32911.0}, {1157.3, 125.6, 32930.1}},
    {1275, "Ship Engineer", "ShipQuest1", 2, "Rear Crew Quest Giver", {1040.3, 125.1, 32911.0}, {834.8, 43.7, 32720.9}},
    {1300, "Ship Steward", "ShipQuest2", 1, "Front Crew Quest Giver", {971.4, 125.1, 33245.5}, {801.4, 125.8, 33505.2}},
    {1325, "Ship Officer", "ShipQuest2", 2, "Front Crew Quest Giver", {971.4, 125.1, 33245.5}, {694.5, 179.9, 33112.6}},
    {1350, "Arctic Warrior", "FrostQuest", 1, "Frost Quest Giver", {5668.1, 28.2, -6484.6}, {6271.3, 27.6, -6151.5}},
    {1375, "Snow Lurker", "FrostQuest", 2, "Frost Quest Giver", {5668.1, 28.2, -6484.6}, {5524.2, 27.6, -6583.8}},
    {1425, "Sea Soldier", "ForgottenQuest", 1, "Forgotten Quest Giver", {-3054.6, 236.9, -10147.8}, {-2550.9, 28.5, -9840.0}},
    {1450, "Water Fighter", "ForgottenQuest", 2, "Forgotten Quest Giver", {-3054.6, 236.9, -10147.8}, {-3331.7, 239.1, -10553.4}},
    -- ===== SEA 3 =====
    {1500, "Pirate Millionaire", "PiratePortQuest", 1, "Pirate Port Quest Giver", {-289.6, 43.8, 5580.1}, {-232.9, 57.0, 5757.8}},
    {1525, "Pistol Billionaire", "PiratePortQuest", 2, "Pirate Port Quest Giver", {-289.6, 43.8, 5580.1}, {-54.8, 83.8, 5947.8}},
    {1575, "Dragon Crew Warrior", "DragonCrewQuest", 1, "Dragon Crew Quest Giver", {6735.1, 127.0, -711.1}, {7217.8, 56.6, -680.8}},
    {1600, "Dragon Crew Archer", "DragonCrewQuest", 2, "Dragon Crew Quest Giver", {6735.1, 127.0, -711.1}, {6831.1, 441.8, 446.6}},
    {1625, "Hydra Enforcer", "VenomCrewQuest", 1, "Hydra Town Quest Giver", {5214.3, 1003.5, 759.5}, {5195.6, 1089.2, 617.9}},
    {1650, "Venomous Assailant", "VenomCrewQuest", 2, "Hydra Town Quest Giver", {5214.3, 1003.5, 759.5}, {5195.6, 1089.2, 617.9}},
    {1700, "Marine Commodore", "MarineTreeIsland", 1, "Marine Tree Quest Giver", {2180.0, 28.7, -6740.1}, {2577.3, 75.6, -7739.9}},
    {1725, "Marine Rear Admiral", "MarineTreeIsland", 2, "Marine Tree Quest Giver", {2180.0, 28.7, -6740.1}, {3920.1, 146.2, -7175.2}},
    {1775, "Fishman Raider", "DeepForestIsland3", 1, "Turtle Adventure Quest Giver", {-10582.8, 331.8, -8757.7}, {-10223.1, 332.6, -8482.5}},
    {1800, "Fishman Captain", "DeepForestIsland3", 2, "Turtle Adventure Quest Giver", {-10582.8, 331.8, -8757.7}, {-10736.7, 331.8, -8807.6}},
    {1825, "Forest Pirate", "DeepForestIsland", 1, "Deep Forest Quest Giver", {-13232.7, 332.4, -7626.5}, {-13105.5, 332.2, -7705.8}},
    {1850, "Mythological Pirate", "DeepForestIsland", 2, "Deep Forest Quest Giver", {-13232.7, 332.4, -7626.5}, {-13221.0, 519.1, -6689.0}},
    {1900, "Jungle Pirate", "DeepForestIsland2", 1, "Deep Forest Area 2 Quest Giver", {-12682.1, 390.9, -9902.1}, {-12321.3, 331.4, -10669.3}},
    {1925, "Musketeer Pirate", "DeepForestIsland2", 2, "Deep Forest Area 2 Quest Giver", {-12682.1, 390.9, -9902.1}, {-13556.1, 391.4, -9735.9}},
    {1975, "Reborn Skeleton", "HauntedQuest1", 1, "Haunted Castle Quest Giver 1", {-9480.8, 142.1, 5566.4}, {-8710.1, 141.0, 6112.9}},
    {2000, "Living Zombie", "HauntedQuest1", 2, "Haunted Castle Quest Giver 1", {-9480.8, 142.1, 5566.4}, {-10170.9, 141.2, 6159.6}},
    {2025, "Demonic Soul", "HauntedQuest2", 1, "Haunted Castle Quest Giver 2", {-9517.0, 178.0, 6078.5}, {-9712.0, 204.7, 6193.3}},
    {2050, "Possessed Mummy", "HauntedQuest2", 2, "Haunted Castle Quest Giver 2", {-9517.0, 178.0, 6078.5}, {-9399.6, 12.2, 6118.8}},
    {2075, "Peanut Scout", "NutsIslandQuest", 1, "Peanut Quest Giver", {-2105.5, 37.2, -10195.5}, {-1924.0, 37.3, -10199.7}},
    {2100, "Peanut President", "NutsIslandQuest", 2, "Peanut Quest Giver", {-2105.5, 37.2, -10195.5}, {-1993.4, 37.2, -10682.9}},
    {2125, "Ice Cream Chef", "IceCreamIslandQuest", 1, "Ice Cream Quest Giver", {-819.4, 64.9, -10967.3}, {-502.4, 64.6, -10873.8}},
    {2150, "Ice Cream Commander", "IceCreamIslandQuest", 2, "Ice Cream Quest Giver", {-819.4, 64.9, -10967.3}, {-366.8, 64.7, -11094.4}},
    {2200, "Cookie Crafter", "CakeQuest1", 1, "Cake Quest Giver 1", {-2022.3, 36.9, -12031.0}, {-2321.7, 36.7, -12216.8}},
    {2225, "Cake Guard", "CakeQuest1", 2, "Cake Quest Giver 1", {-2022.3, 36.9, -12031.0}, {-1418.1, 36.7, -12255.7}},
    {2250, "Baking Staff", "CakeQuest2", 1, "Cake Quest Giver 2", {-1928.3, 37.7, -12840.6}, {-1774.1, 34.7, -12850.5}},
    {2275, "Head Baker", "CakeQuest2", 2, "Cake Quest Giver 2", {-1928.3, 37.7, -12840.6}, {-2389.2, 51.0, -13018.3}},
    {2300, "Cocoa Warrior", "ChocQuest1", 1, "Chocolate Quest Giver 1", {231.8, 23.9, -12200.3}, {-128.7, 26.2, -12249.8}},
    {2325, "Chocolate Bar Battler", "ChocQuest1", 2, "Chocolate Quest Giver 1", {231.8, 23.9, -12200.3}, {598.8, 25.6, -12395.1}},
    {2350, "Sweet Thief", "ChocQuest2", 1, "Chocolate Quest Giver 2", {151.2, 23.9, -12774.6}, {-77.6, 25.6, -12765.6}},
    {2375, "Candy Rebel", "ChocQuest2", 2, "Chocolate Quest Giver 2", {151.2, 23.9, -12774.6}, {166.8, 25.6, -13035.3}},
    {2400, "Candy Pirate", "CandyQuest1", 1, "Candy Cane Quest Giver", {-1149.3, 13.6, -14445.6}, {-1226.8, 36.3, -14777.6}},
    {2425, "Snow Demon", "CandyQuest1", 2, "Candy Cane Quest Giver", {-1149.3, 13.6, -14445.6}, {-936.2, 14.0, -14552.5}},
    {2450, "Isle Outlaw", "TikiQuest1", 1, "Tiki Quest Giver 1", {-16548.8, 55.6, -172.8}, {-16351.8, 23.5, -282.5}},
    {2475, "Island Boy", "TikiQuest1", 2, "Tiki Quest Giver 1", {-16548.8, 55.6, -172.8}, {-16736.2, 22.2, -131.7}},
    {2500, "Sun-kissed Warrior", "TikiQuest2", 1, "Tiki Quest Giver 2", {-16541.0, 54.8, 1051.5}, {-16413.5, 56.7, 1054.4}},
    {2525, "Isle Champion", "TikiQuest2", 2, "Tiki Quest Giver 2", {-16541.0, 54.8, 1051.5}, {-16735.7, 23.3, 1110.6}},
    {2550, "Serpent Hunter", "TikiQuest3", 1, "Tiki Quest Giver 3", {-16665.2, 104.6, 1579.7}, {-16536.0, 106.9, 1347.1}},
    {2575, "Skull Slayer", "TikiQuest3", 2, "Tiki Quest Giver 3", {-16665.2, 104.6, 1579.7}, {-16829.4, 193.2, 1753.4}},
    {2600, "Reef Bandit", "SubmergedQuest1", 1, "Submerged Quest Giver 1", {10882.3, -2086.3, 10034.2}, {10899.9, -2145.2, 9279.3}},
    {2625, "Coral Pirate", "SubmergedQuest1", 2, "Submerged Quest Giver 1", {10882.3, -2086.3, 10034.2}, {10703.7, -2087.3, 9255.4}},
    {2650, "Sea Chanter", "SubmergedQuest2", 1, "Submerged Quest Giver 2", {10882.3, -2086.3, 10034.2}, {10680.1, -2056.7, 9933.9}},
    {2675, "High Disciple", "SubmergedQuest3", 1, "Submerged Quest Giver 3", {9636.5, -1992.2, 9609.5}, {9828.1, -1940.9, 9693.1}},
    {2700, "Grand Devotee", "SubmergedQuest3", 1, "Submerged Quest Giver 3", {9636.5, -1992.2, 9609.5}, {9559.2, -1994.4, 9798.7}},
}

-- ===== Tien ich =====
local CommF = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")
local Data = Player:WaitForChild("Data")
local Level = Data:WaitForChild("Level")

-- Remote fast attack (co the khong co neu game doi cau truc -> script tu fallback)
local NetFolder = ReplicatedStorage:WaitForChild("Modules", 10) and ReplicatedStorage.Modules:WaitForChild("Net", 10)
local RegisterAttack = NetFolder and NetFolder:WaitForChild("RE/RegisterAttack", 5)
local RegisterHit = NetFolder and NetFolder:WaitForChild("RE/RegisterHit", 5)

local function V(t)
    return Vector3.new(t[1], t[2], t[3])
end

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

-- Quest dang active tren GUI game (nil = chua co quest)
local function currentQuestText()
    local gui = Player:FindFirstChild("PlayerGui")
    local main = gui and gui:FindFirstChild("Main")
    local quest = main and main:FindFirstChild("Quest")
    if not quest or not quest.Visible then return nil end
    local titleObj = quest:FindFirstChild("Container") and quest.Container:FindFirstChild("QuestTitle")
        and quest.Container.QuestTitle:FindFirstChild("Title")
    if titleObj and titleObj.Text ~= "" then return titleObj.Text end
    return nil
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

-- Chiem quyen vat ly quai quanh minh (de gom quai khong bi server giat lai)
local function claimSimulation()
    if sethiddenproperty then
        pcall(function()
            sethiddenproperty(Player, "SimulationRadius", math.huge)
        end)
    end
end

-- ===== Fly muot (khong teleport) =====
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

local function flyTo(goalPos, timeout)
    local t0 = tick()
    while Settings.Farm and (tick() - t0) < (timeout or 25) do
        if flyStep(goalPos, RunService.Heartbeat:Wait()) then
            return true
        end
    end
    return false
end

-- Bay duong dai: leo len cao truoc roi moi ha xuong, tranh xuyen dao/dia hinh
local function flyToSmart(goalPos, timeout)
    local _, _, hrp = getChar()
    if not hrp then return false end
    timeout = timeout or 60
    local cruise = Vector3.new(goalPos.X, math.max(hrp.Position.Y, goalPos.Y) + 150, goalPos.Z)
    if (cruise - hrp.Position).Magnitude > 30 then
        flyTo(cruise, timeout * 0.6)
    end
    return flyTo(goalPos, timeout * 0.6)
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

-- ===== Fast attack =====
-- Buff hitbox qua CombatFramework controller (neu executor co getupvalues)
local buffedController = nil
local function buffHitbox()
    if buffedController then
        local ok = pcall(function()
            buffedController.hitboxMagnitude = Settings.AttackRange
            buffedController.timeToNextAttack = 0
        end)
        if ok then return end
        buffedController = nil
    end
    local getuv = getupvalues or (debug and debug.getupvalues)
    if not getuv then return end
    pcall(function()
        local ps = Player:FindFirstChild("PlayerScripts")
        local module = ps and ps:FindFirstChild("CombatFramework")
        if not module then return end
        local ups = getuv(require(module))
        local lib = ups and ups[2]
        if lib and lib.activeController and lib.activeController.timeToNextAttack ~= nil then
            buffedController = lib.activeController
            buffedController.hitboxMagnitude = Settings.AttackRange
        end
    end)
end

-- Danh bang remote: game nhan don, client khong can click that
local function remoteAttack(targets)
    if not RegisterAttack or not RegisterHit or #targets == 0 then return false end
    local ok = pcall(function()
        RegisterAttack:FireServer(0)
        local pairsList = {}
        for _, t in ipairs(targets) do
            table.insert(pairsList, { t.model, t.part })
        end
        RegisterHit:FireServer(targets[1].part, pairsList)
    end)
    return ok
end

-- ===== Gom quai =====
-- Lay danh sach quai cung loai gan minh (gan nhat truoc), toi da BringMax con
local function collectMobs(mobName, hrp, includeEnemy)
    local list = {}
    local seen = {}
    local enemies = workspace:FindFirstChild("Enemies")
    if enemies then
        for _, e in ipairs(enemies:GetChildren()) do
            local h = e:FindFirstChildOfClass("Humanoid")
            local r = e:FindFirstChild("HumanoidRootPart")
            if h and r and h.Health > 0 and string.find(e.Name, mobName, 1, true) then
                local d = (r.Position - hrp.Position).Magnitude
                if d <= Settings.BringRadius then
                    table.insert(list, { model = e, hum = h, root = r, dist = d })
                    seen[e] = true
                end
            end
        end
    end
    table.sort(list, function(a, b) return a.dist < b.dist end)
    -- Con dang khoa muc tieu luon duoc giu du o xa hon ban kinh gom
    if includeEnemy and not seen[includeEnemy] then
        local h = includeEnemy:FindFirstChildOfClass("Humanoid")
        local r = includeEnemy:FindFirstChild("HumanoidRootPart")
        if h and r and h.Health > 0 then
            table.insert(list, 1, { model = includeEnemy, hum = h, root = r, dist = 0 })
        end
    end
    while #list > Settings.BringMax do table.remove(list) end
    return list
end

-- Giu bam quai o diem gom duoi chan minh (goi moi khung hinh)
local function holdMobs(list, gatherPos)
    for _, item in ipairs(list) do
        pcall(function() item.root.AssemblyLinearVelocity = Vector3.zero end)
        item.root.CanCollide = false
        local flat = Vector3.new(gatherPos.X - item.root.Position.X, 0, gatherPos.Z - item.root.Position.Z)
        if flat.Magnitude > 1 then
            item.root.CFrame = CFrame.new(gatherPos, gatherPos + flat)
        else
            item.root.CFrame = CFrame.new(gatherPos)
        end
    end
end

-- Khoa "do di chuyen" cua quai (goi dinh ky): dung chan, tat animation di bo
local function freezeMobs(list)
    for _, item in ipairs(list) do
        pcall(function()
            item.hum.WalkSpeed = 0
            item.hum.JumpPower = 0
            local anim = item.hum:FindFirstChildOfClass("Animator")
            if anim then anim:Destroy() end
            item.hum:ChangeState(Enum.HumanoidStateType.StrafingNoPhysics)
            item.hum:ChangeState(Enum.HumanoidStateType.PlatformStanding)
        end)
    end
end

-- ===== Nhan quest: bay toi dao truoc =====
local function tryStartQuest(q, idx)
    pcall(function() CommF:InvokeServer("StartQuest", q[3], idx) end)
    task.wait(0.7)
    return questMatchesMob(currentQuestText(), q[2])
end

local function ensureQuest()
    local q = getQuestForLevel(Level.Value)
    local mobName = q[2]
    if questMatchesMob(currentQuestText(), mobName) then
        return q
    end
    if currentQuestText() then
        setStatus("Huy quest cu...")
        pcall(function() CommF:InvokeServer("AbandonQuest") end)
        task.wait(0.6)
    end

    -- 1) Bay toi dao: Sea 1 dung toa do bai quai (sau rework), Sea 2/3 dung toa do NPC
    local anchor = IS_SEA1 and V(q[7]) or V(q[6])
    local _, _, hrp = getChar()
    if hrp and (anchor - hrp.Position).Magnitude > 60 then
        setStatus("Bay toi dao nhan quest (" .. mobName .. ")...")
        flyToSmart(anchor + Vector3.new(0, 10, 0), 90)
    end

    -- 2) Neu thay NPC trong workspace thi bay lai gan NPC
    local giverPos = findGiverPos(q[5])
    if giverPos then
        local _, _, root = getChar()
        if root and (giverPos - root.Position).Magnitude > 15 then
            flyTo(giverPos + Vector3.new(0, 5, 0), 12)
        end
    end

    -- 3) Nhan quest; sai chi so thi tu thu lai chi so con lai
    setStatus("Nhan quest: " .. mobName)
    local idx = q[4]
    if not tryStartQuest(q, idx) then
        local other = idx == 1 and 2 or 1
        pcall(function() CommF:InvokeServer("AbandonQuest") end)
        task.wait(0.4)
        if tryStartQuest(q, other) then
            q[4] = other -- tu sua lai cho lan sau
        else
            setStatus("Chua nhan duoc quest, van farm quai: " .. mobName)
            task.wait(0.5)
        end
    end
    return q
end

-- ===== Danh 1 con quai: fly tracking + gom + fast attack =====
local function fightMob(enemy, mobName)
    local tool = equipMelee()
    local hadQuest = currentQuestText() ~= nil
    local atkAcc, slowAcc = 0, 0
    while Settings.Farm do
        local dt = RunService.Heartbeat:Wait()
        local eHum = enemy:FindFirstChildOfClass("Humanoid")
        local eRoot = enemy:FindFirstChild("HumanoidRootPart")
        local char, hum, hrp = getChar()
        if not eHum or not eRoot or eHum.Health <= 0 or not enemy.Parent then break end
        if not char or not hum or not hrp or hum.Health <= 0 then break end

        -- Fly tracking: bam sat tren dau quai, khong nha giua chung
        flyStep(eRoot.Position + Vector3.new(0, Settings.HoverHeight, 0), dt)

        -- Gom quai (toi da BringMax con) ve duoi chan minh va giu chat
        local mobs = { { model = enemy, hum = eHum, root = eRoot, dist = 0 } }
        if Settings.BringMobs then
            mobs = collectMobs(mobName, hrp, enemy)
            local gatherPos = hrp.Position + Vector3.new(0, -Settings.HoverHeight + 3, 0)
            holdMobs(mobs, gatherPos)
        end

        atkAcc = atkAcc + dt
        slowAcc = slowAcc + dt
        if slowAcc >= 0.25 then
            slowAcc = 0
            claimSimulation()
            buffHitbox()
            if Settings.BringMobs then freezeMobs(mobs) end
            if hadQuest and currentQuestText() == nil then break end -- xong quest -> nha lock
        end

        if atkAcc >= Settings.AttackRate then
            atkAcc = 0
            -- Danh tat ca quai dang gom (trong tam ~90 studs) bang remote
            local targets = {}
            for _, m in ipairs(mobs) do
                if (m.root.Position - hrp.Position).Magnitude <= 90 then
                    local part = m.model:FindFirstChild("Head") or m.root
                    table.insert(targets, { model = m.model, part = part })
                end
            end
            if #targets == 0 then
                local part = enemy:FindFirstChild("Head") or eRoot
                targets = { { model = enemy, part = part } }
            end
            if not remoteAttack(targets) then
                -- Fallback: khong co remote thi spam Activate cua vu khi
                if tool and tool.Parent ~= char then tool = nil end
                if not tool then tool = equipMelee() end
                if tool then pcall(function() tool:Activate() end) end
            else
                -- Van Activate nhe de animation/don phu (chuan cac hub dang lam)
                if tool and tool.Parent == char then
                    pcall(function() tool:Activate() end)
                elseif not tool then
                    tool = equipMelee()
                end
            end
        end
    end
end

-- ===== Vong lap farm chinh =====
local function farmLoop()
    claimSimulation()
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
                -- Bay thang toi bai quai theo toa do roi quet lai
                setStatus("Bay toi bai " .. q[2] .. "...")
                flyToSmart(V(q[7]) + Vector3.new(0, 15, 0), 90)
                task.wait(1)
                enemy = findEnemy(q[2])
                if not enemy then
                    setStatus("Chua thay quai " .. q[2] .. ", cho tai map...")
                    task.wait(1.5)
                    return
                end
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
    frame.Size = UDim2.new(0, 240, 0, 350)
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
    title.Text = "BON - Blox Fruits v3"
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
        btn.Size = UDim2.new(1, -20, 0, 38)
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

    makeToggle(40, "Auto Farm", function() return Settings.Farm end, function(v)
        Settings.Farm = v
        if v then task.spawn(farmLoop) end
    end)
    makeToggle(84, "Gom Mob", function() return Settings.BringMobs end, function(v) Settings.BringMobs = v end)
    makeToggle(128, "Tu Cong Stat", function() return Settings.AutoStat end, function(v) Settings.AutoStat = v end)

    local statBtn = Instance.new("TextButton")
    statBtn.Size = UDim2.new(1, -20, 0, 38)
    statBtn.Position = UDim2.new(0, 10, 0, 172)
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

    -- Dong chinh so: nhan | - gia tri +
    local function makeStepper(y, label, getText, onDelta)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0, 96, 0, 34)
        lbl.Position = UDim2.new(0, 10, 0, y)
        lbl.BackgroundTransparency = 1
        lbl.Text = label
        lbl.TextColor3 = Color3.fromRGB(230, 230, 230)
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 12
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = frame

        local val = Instance.new("TextLabel")
        val.Size = UDim2.new(0, 44, 0, 34)
        val.Position = UDim2.new(0, 148, 0, y)
        val.BackgroundTransparency = 1
        val.Text = getText()
        val.TextColor3 = Color3.fromRGB(103, 232, 249)
        val.Font = Enum.Font.GothamBold
        val.TextSize = 14
        val.Parent = frame

        local function stepBtn(x, txt, delta)
            local b = Instance.new("TextButton")
            b.Size = UDim2.new(0, 34, 0, 34)
            b.Position = UDim2.new(0, x, 0, y)
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
                onDelta(delta)
                val.Text = getText()
            end)
        end
        stepBtn(110, "-", -1)
        stepBtn(196, "+", 1)
    end

    makeStepper(216, "Toc do bay", function() return tostring(Settings.FlySpeed) end, function(d)
        Settings.FlySpeed = math.clamp(Settings.FlySpeed + d * 25, 100, 350)
    end)
    makeStepper(256, "Gom toi da", function() return tostring(Settings.BringMax) end, function(d)
        Settings.BringMax = math.clamp(Settings.BringMax + d, 2, 5)
    end)

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
    print("[BloxFruits] Da tai GUI v3. Level hien tai: " .. tostring(Level.Value))
end

function Module.Stop()
    Settings.Farm = false
    if Module._gui then
        Module._gui:Destroy()
        Module._gui = nil
    end
end

Module.Start()
print("[BloxFruits] San sang (v3). Bam 'Auto Farm: BAT' tren GUI de farm. Level: " .. tostring(Level.Value))

return Module
