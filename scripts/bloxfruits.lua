-- BON Blox Fruits Auto Farm (v9)
-- v9: them 2 muc mua do: (1) Mua thu cong trong GUI: moi mon ghi ro gia Beli/Frag,
-- chi ban remote khi du tien; (2) Auto Buy chay nen, UU TIEN chuoi Melee (vo) truoc
-- roi moi toi Haki/Ability. Mon nao con thieu Mastery/Vat lieu/Sea thi server se tu
-- choi, script ghi nhan da thu va cho 90s chu khong spam remote.
-- v8 (gom quai theo dung y Bon): gom den du so luong thi dung, khong gom them trong
-- cung 1 tran; da bring la NHA RA cho game tu tinh vat ly (bo han viec khoa WalkSpeed/
-- ghim quai moi tick); chi khi quai chay qua xa tam danh (>70 studs ngang) moi bring
-- rieng con do lai; va CHI bring khi con dang danh dung la quai cua quest hien tai.
-- v7: port nguyen flow auto-quest cua Sankeurr (open source moi nhat 10/2026):
-- script TU DEM so quai da giet (quai dung ten bien mat khoi workspace = +1 kill),
-- chi ban StartQuest dung 2 luc: doi quest (len level) hoac dem du quota 8 con.
-- Khong doc GUI quest de quyet dinh, khong AbandonQuest, khong nhan lai lien tuc
-- -> diet tan goc vong lap nhan-huy quest. GUI quest chi lam "phanh an toan" phu:
-- dang danh ma GUI quest tat thi ngung som. Ban kinh quet/gom quai nang len 200.
-- Sua theo phan hoi test cua Bon (v5):
-- 1) Bring quai khong con tinh chieu cao cua player: quai duoc keo toi gan player nhung
--    giu nguyen cao do mat dat cua no (dang dung tren khong thi ke). Chi bring 1 lan;
--    con nao di qua xa tam danh (>70 studs tinh theo chieu ngang) moi bring rieng con do lai.
-- 2) He thong check nhiem vu rieng: doc ca tieu de + mo ta + tien do (da danh x/y con)
--    tren GUI quest cua game, doi chieu voi level hien tai:
--    - Chua co quest -> nhan quest dung level (cho GUI quest xuat hien moi tinh la xong,
--      khong ban StartQuest lien tuc).
--    - Co quest dung level -> giu nguyen, khong huy/nhan lai.
--    - Len level moi ma van cam quest cu -> huy cu, nhan moi ngay, roi bay toi bai quai.
--    - Quest mat do hoan thanh (hoac du x/y con) -> nhan lai quest moi.
--    Kiem tra quai xong quest phai on dinh ~0.9s moi nha khoa muc tieu.
-- 3) Chong 2 ban script chay song song (Bon chay lai loadstring): ban moi se tat ban cu
--    va xoa GUI cu, tranh viec 2 ben tranh nhau nhan quest.
-- Ke thua tu v4: auto stat do het diem 1 lan, fly luong rieng lien tuc khong nha nhip,
-- auto Aura (Buso), UI nhe co thu nho, fast attack remote + bang toa do 3 sea tu v3.

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

-- Chong chay 2 ban script song song: ban moi chay se tat vong lap cua ban cu
_G.BON_BF_SESSION = (_G.BON_BF_SESSION or 0) + 1
local mySession = _G.BON_BF_SESSION
local function sessionAlive()
    return _G.BON_BF_SESSION == mySession
end

-- ===== Cai dat =====
local Settings = {
    Farm = false,          -- bat/tat auto farm
    BringMobs = true,      -- gom quai ve duoi chan
    BringMax = 4,          -- so quai gom toi da (2-5)
    AutoStat = false,      -- tu cong diem stat
    StatName = "Melee",    -- Melee / Defense / Sword / Gun / Demon Fruit
    AutoAura = false,      -- tu bat Aura (Buso Haki)
    AutoBuy = false,       -- tu dong mua do khi du tien (uu tien Melee truoc)
    FlySpeed = 200,        -- toc do bay 100-350 (nut -/+ tren GUI)
    HoverHeight = 25,      -- do cao dung tren dau quai
    BringRadius = 200,     -- ban kinh quet/gom quai (Bon yeu cau 200)
    AttackRate = 0.1,      -- giay giua moi don danh
    AttackRange = 55,      -- hitbox buff (tam danh)
}
Module.Settings = Settings

-- ===== Du lieu quest =====
-- {Level, Mob, QuestId, ChiSo, NPC giao quest, ToaDoNPC{x,y,z}, ToaDoQuai{x,y,z}}
-- Toa do quai Sea 1 = sau Update 30. Toa do NPC Sea 1 la ban cu (script tu quet NPC theo ten).
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

-- Doc GUI quest cua game: co dang active khong, tieu de, mo ta, tien do (da danh/can)
local function readQuestGui()
    local gui = Player:FindFirstChild("PlayerGui")
    local main = gui and gui:FindFirstChild("Main")
    local quest = main and main:FindFirstChild("Quest")
    if not quest or not quest.Visible then
        return false, "", "", nil, nil
    end
    local title, desc = "", ""
    local container = quest:FindFirstChild("Container")
    if container then
        local qt = container:FindFirstChild("QuestTitle")
        local tl = qt and qt:FindFirstChild("Title")
        if tl then title = tl.Text or "" end
        local qd = container:FindFirstChild("QuestDescription")
        local dl = qd and (qd:FindFirstChild("Description") or qd:FindFirstChild("Title"))
        if dl then desc = dl.Text or "" end
    end
    local killed, needed = nil, nil
    local both = desc .. " " .. title
    local k, n = string.match(both, "%[(%d+)/(%d+)%]")
    if not k then
        k, n = string.match(both, "(%d+)%s*/%s*(%d+)")
    end
    if k then killed, needed = tonumber(k), tonumber(n) end
    return true, title, desc, killed, needed
end

local function questActive()
    local active = readQuestGui()
    return active
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

-- ===== Fly lien tuc bang luong rieng =====
-- Logic chi can dat Flight.goal; luong fly tu bay muot theo muc tieu khong nha nhip.
local Flight = { goal = nil }

local function flyStep(goalPos, dt)
    local _, _, hrp = getChar()
    if not hrp then return true end
    local delta = goalPos - hrp.Position
    local dist = delta.Magnitude
    if dist <= 2 then return true end
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

task.spawn(function()
    while sessionAlive() do
        local dt = RunService.Heartbeat:Wait()
        if Settings.Farm then
            local _, hum, hrp = getChar()
            if hrp and hum and hum.Health > 0 then
                if Flight.goal then
                    flyStep(Flight.goal, dt)
                end
                -- Giu nhan vat khong tut xuong du da toi muc tieu
                pcall(function() hrp.AssemblyLinearVelocity = Vector3.zero end)
            end
        end
    end
end)

-- Dat muc tieu bay va cho nhan vat bay toi (logic trong luc cho van muot)
local function flyGoalTo(pos, timeout, arriveDist)
    Flight.goal = pos
    arriveDist = arriveDist or 6
    local t0 = tick()
    while Settings.Farm and sessionAlive() and (tick() - t0) < (timeout or 30) do
        local _, _, hrp = getChar()
        if not hrp then return false end
        if (pos - hrp.Position).Magnitude <= arriveDist then return true end
        task.wait(0.1)
    end
    local _, _, hrp = getChar()
    return hrp ~= nil and (pos - hrp.Position).Magnitude <= arriveDist
end

-- Bay duong dai: leo len cao truoc roi moi ha xuong, tranh xuyen dao/dia hinh
local function flyToSmart(pos, timeout)
    local _, _, hrp = getChar()
    if not hrp then return false end
    timeout = timeout or 60
    local cruise = Vector3.new(pos.X, math.max(hrp.Position.Y, pos.Y) + 150, pos.Z)
    if (cruise - hrp.Position).Magnitude > 30 then
        flyGoalTo(cruise, timeout * 0.5, 25)
    end
    return flyGoalTo(pos, timeout * 0.6, 6)
end

local function findEnemy(mobName)
    local enemies = workspace:FindFirstChild("Enemies")
    if not enemies then return nil end
    local _, _, hrp = getChar()
    local best, bestDist = nil, math.huge
    for _, e in ipairs(enemies:GetChildren()) do
        local hum = e:FindFirstChildOfClass("Humanoid")
        local root = e:FindFirstChild("HumanoidRootPart")
        if hum and root and hum.Health > 0 and string.lower(e.Name) == string.lower(mobName) then
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

-- ===== Auto stat: co diem la do het vao stat da chon =====
local function spendStats()
    if not Settings.AutoStat then return end
    local points = Data:FindFirstChild("Points")
    if points and points.Value > 0 then
        local amt = points.Value
        pcall(function() CommF:InvokeServer("AddPoint", Settings.StatName, amt) end)
    end
end

-- ===== Auto Aura (Buso Haki) =====
local auraLastFire = 0
local auraBuyTried = false
local function maintainAura()
    if not Settings.AutoAura then return end
    local char = Player.Character
    if not char then return end
    if char:FindFirstChild("HasBuso") then return end
    if tick() - auraLastFire < 4 then return end
    auraLastFire = tick()
    -- Chua mua thi mua 1 lan khi du 25.000 Beli (da co roi thi server tu bo qua)
    local beli = Data:FindFirstChild("Beli")
    if not auraBuyTried and beli and beli.Value >= 25000 then
        auraBuyTried = true
        pcall(function() CommF:InvokeServer("BuyHaki", "Buso") end)
        task.wait(0.3)
    end
    -- Bat aura (remote nay la nut gac nhu phim J: chi goi khi chua co HasBuso)
    pcall(function() CommF:InvokeServer("Buso") end)
end

-- ===== Mua do: Haki/Ability + Fighting Styles (Melee) =====
-- Gia/remote doi chieu Blox Fruits Wiki + cac shop remote cong dong (10/2026).
-- "args" la tham so ban thang vao CommF_ giong nut Mua trong cac shop hub.
local SHOP_ITEMS = {
    -- Haki / Ability (mua thu cong o day; Auto Buy chi mua sau khi xong Melee)
    { name = "Geppo", display = "Geppo (Air Jump)", group = "Ability", beli = 10000, frag = 0, args = { "BuyHaki", "Geppo" } },
    { name = "Buso", display = "Buso Haki (Aura)", group = "Ability", beli = 25000, frag = 0, args = { "BuyHaki", "Buso" } },
    { name = "Soru", display = "Soru (Flash Step)", group = "Ability", beli = 100000, frag = 0, args = { "BuyHaki", "Soru" } },
    { name = "Instinct", display = "Haki Quan Sat (Instinct)", group = "Ability", beli = 750000, frag = 0, minLevel = 300, note = "can Lv 300 + da danh Saber Expert", args = { "KenTalk", "Buy" } },

    -- Chuoi Melee theo thu tu tien hoa. order nho = cap thap, Auto Buy khong mua lui xuong cap thap hon vo dang dung.
    { name = "DarkStep", display = "Dark Step", group = "Melee", order = 1, beli = 150000, frag = 0, args = { "BuyBlackLeg" }, tools = { "Dark Step" } },
    { name = "Electric", display = "Electric", group = "Melee", order = 2, beli = 500000, frag = 0, args = { "BuyElectro" }, tools = { "Electric", "Electro" } },
    { name = "WaterKungFu", display = "Water Kung Fu", group = "Melee", order = 3, beli = 750000, frag = 0, args = { "BuyFishmanKarate" }, tools = { "Water Kung Fu", "Fishman Karate" } },
    { name = "DragonBreath", display = "Dragon Breath", group = "Melee", order = 4, beli = 0, frag = 1500, args = { "BlackbeardReward", "DragonClaw", "2" }, tools = { "Dragon Breath", "Dragon Claw" } },
    { name = "Superhuman", display = "Superhuman", group = "Melee", order = 5, beli = 3000000, frag = 0, note = "can 300 Mastery: Dark Step/Electric/Water/Dragon Breath", args = { "BuySuperhuman" }, tools = { "Superhuman" } },
    { name = "DeathStep", display = "Death Step", group = "Melee", order = 6, beli = 2500000, frag = 5000, note = "can 400 Mastery Dark Step", args = { "BuyDeathStep" }, tools = { "Death Step" } },
    { name = "SharkmanKarate", display = "Sharkman Karate", group = "Melee", order = 7, beli = 2500000, frag = 5000, note = "can 400 Mastery Water Kung Fu + Water Key", args = { "BuySharkmanKarate" }, tools = { "Sharkman Karate" } },
    { name = "ElectricClaw", display = "Electric Claw", group = "Melee", order = 8, beli = 3000000, frag = 5000, note = "can 400 Mastery Electric + lam quest Previous Hero", args = { "BuyElectricClaw" }, tools = { "Electric Claw" } },
    { name = "DragonTalon", display = "Dragon Talon", group = "Melee", order = 9, beli = 3000000, frag = 5000, note = "can 400 Mastery Dragon Breath + Fire Essence", args = { "BuyDragonTalon" }, tools = { "Dragon Talon" } },
    { name = "Godhuman", display = "Godhuman", group = "Melee", order = 10, beli = 5000000, frag = 5000, note = "can 400 Mastery 5 vo truoc + vat lieu", args = { "BuyGodhuman" }, tools = { "Godhuman", "God Human" } },
    { name = "SanguineArt", display = "Sanguine Art", group = "Melee", order = 11, beli = 5000000, frag = 5000, note = "can vat lieu + Leviathan Heart (Sea 3)", args = { "BuySanguineArt" }, tools = { "Sanguine Art" } },
}
Module.ShopItems = SHOP_ITEMS

local function getMoney()
    local b = Data:FindFirstChild("Beli")
    local f = Data:FindFirstChild("Fragments")
    return (b and b.Value) or 0, (f and f.Value) or 0
end

local function fmtNum(n)
    local s = tostring(math.floor(tonumber(n) or 0))
    return (s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""))
end

local function priceText(item)
    if (item.beli or 0) > 0 and (item.frag or 0) > 0 then
        return fmtNum(item.beli) .. " Beli + " .. fmtNum(item.frag) .. " Frag"
    elseif (item.frag or 0) > 0 then
        return fmtNum(item.frag) .. " Frag"
    end
    return fmtNum(item.beli or 0) .. " Beli"
end

local function findToolByNames(names)
    if not names then return nil end
    local wanted = {}
    for _, n in ipairs(names) do wanted[string.lower(n)] = true end
    local char = Player.Character
    local backpack = Player:FindFirstChild("Backpack")
    for _, container in ipairs({ char, backpack }) do
        if container then
            for _, t in ipairs(container:GetChildren()) do
                if t:IsA("Tool") and wanted[string.lower(t.Name)] then return t end
            end
        end
    end
    return nil
end

-- Cap cua vo dang co (de Auto Buy khong mua lui xuong vo yeu hon vo dang dung)
local function currentMeleeOrder()
    local best = 0
    local char = Player.Character
    local backpack = Player:FindFirstChild("Backpack")
    for _, item in ipairs(SHOP_ITEMS) do
        if item.group == "Melee" and item.tools then
            for _, container in ipairs({ char, backpack }) do
                if container then
                    for _, t in ipairs(container:GetChildren()) do
                        if t:IsA("Tool") then
                            for _, n in ipairs(item.tools) do
                                if string.lower(t.Name) == string.lower(n) and item.order > best then
                                    best = item.order
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return best
end

local shopBought = {}    -- mon da mua thanh cong trong phien nay
local shopAttemptAt = {} -- lan cuoi ban remote mua (chong spam khi thieu dieu kien)
local unpackArgs = table.unpack or unpack

-- Mua 1 mon. manual=true: Bon bam nut, du tien la ban ngay.
-- Tra ve: true = da mua, "sent" = da ban remote (cho ket qua), false = chua mua.
local function tryBuyItem(item, manual)
    local beli, frag = getMoney()
    if (item.beli or 0) > beli or (item.frag or 0) > frag then
        setStatus("Chua du tien mua " .. item.display .. ": can " .. priceText(item) .. " (dang co " .. fmtNum(beli) .. " Beli, " .. fmtNum(frag) .. " Frag)")
        return false
    end
    if item.minLevel and Level.Value < item.minLevel then
        setStatus(item.display .. " can Lv " .. tostring(item.minLevel) .. "+ (" .. (item.note or "") .. ")")
        return false
    end
    if item.group == "Melee" and findToolByNames(item.tools) then
        shopBought[item.name] = true
        setStatus("Dang co vo: " .. item.display)
        return true
    end
    if not manual and shopAttemptAt[item.name] and (tick() - shopAttemptAt[item.name]) < 90 then
        return false -- moi thu gan day ma chua xong: kha nang thieu Mastery/Vat lieu/Sea, cho 90s
    end
    shopAttemptAt[item.name] = tick()
    setStatus("Dang mua " .. item.display .. " (" .. priceText(item) .. ")...")
    local ok = pcall(function()
        return CommF:InvokeServer(unpackArgs(item.args))
    end)
    task.wait(0.7)
    local beli2, frag2 = getMoney()
    if (ok and (beli2 < beli or frag2 < frag)) or findToolByNames(item.tools) then
        shopBought[item.name] = true
        setStatus("Da mua: " .. item.display)
        return true
    end
    setStatus("Da gui mua " .. item.display .. ". Neu chua nhan thi con thieu dieu kien: " .. (item.note or "kiem tra lai tien/Sea"))
    return "sent"
end

-- Auto Buy kieu Kaitun: uu tien het chuoi Melee truoc, xong moi toi Haki/Ability.
local autoBuyLast = 0
local function autoBuyStep()
    if not Settings.AutoBuy then return end
    if tick() - autoBuyLast < 5 then return end
    autoBuyLast = tick()

    local curOrder = currentMeleeOrder()
    for _, item in ipairs(SHOP_ITEMS) do
        if item.group == "Melee" and not shopBought[item.name] then
            if item.order and curOrder > 0 and item.order <= curOrder then
                shopBought[item.name] = true -- dang dung vo cap cao hon: khong mua lui
            else
                local beli, frag = getMoney()
                if (item.beli or 0) <= beli and (item.frag or 0) <= frag then
                    if tryBuyItem(item, false) then return end -- chi mua 1 mon moi luot
                end
            end
        end
    end
    for _, item in ipairs(SHOP_ITEMS) do
        if item.group == "Ability" and not shopBought[item.name] then
            local beli, frag = getMoney()
            if (item.beli or 0) <= beli and (item.frag or 0) <= frag then
                if tryBuyItem(item, false) then return end
            end
        end
    end
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
            if h and r and h.Health > 0 and string.lower(e.Name) == string.lower(mobName) then
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

-- Bring quai: chi bring 1 lan, giu nguyen cao do cua quai (khong tinh chieu cao player).
-- Con nao di qua xa tam danh theo chieu ngang moi bring rieng con do lai.
local broughtMobs = setmetatable({}, { __mode = "k" })

local function bringMobTo(item, hrp, slot)
    local offX = math.sin(slot * 2.3) * 4
    local offZ = math.cos(slot * 2.3) * 4
    local dest = Vector3.new(hrp.Position.X + offX, item.root.Position.Y, hrp.Position.Z + offZ)
    pcall(function() item.root.AssemblyLinearVelocity = Vector3.zero end)
    item.root.CanCollide = false
    local look = Vector3.new(hrp.Position.X, item.root.Position.Y, hrp.Position.Z)
    if (look - dest).Magnitude > 0.5 then
        item.root.CFrame = CFrame.new(dest, look)
    else
        item.root.CFrame = CFrame.new(dest)
    end
    broughtMobs[item.model] = true
end

-- Gom theo dung y Bon: du so luong thi dung gom trong tran do; da bring la nha ra
-- cho game tu tinh vat ly; chi bring lai rieng con nao chay qua xa tam danh.
local function bringPass(list, lockedEnemy, hrp, fightState)
    for i, item in ipairs(list) do
        if item.model ~= lockedEnemy then
            if broughtMobs[item.model] then
                local flat = Vector3.new(item.root.Position.X - hrp.Position.X, 0, item.root.Position.Z - hrp.Position.Z)
                if flat.Magnitude > 70 then
                    bringMobTo(item, hrp, i)
                end
            elseif fightState.count < Settings.BringMax then
                bringMobTo(item, hrp, i)
                fightState.count = fightState.count + 1
            end
        end
    end
end

-- ===== Auto-quest port theo Sankeurr (10/2026): tu dem kill, khong doc GUI de quyet dinh =====
local KILL_QUOTA = 8 -- so quai can giet moi vong quest (mac dinh chuan cong dong)

local QuestFlow = {
    key = nil,   -- "QuestId|ChiSo|Mob" cua quest dang chay
    kills = 0,   -- so quai da giet trong vong quest nay (script tu dem)
    alive = {},  -- tap quai dung ten dang song o tick truoc
}

local function questKey(q)
    return q[3] .. "|" .. tostring(q[4]) .. "|" .. q[2]
end

-- Dem kill: quai dung ten (khop 100%) bien mat khoi tap dang song = +1 kill
local function trackKills(mobName)
    local enemies = workspace:FindFirstChild("Enemies")
    local now = {}
    if enemies then
        for _, e in ipairs(enemies:GetChildren()) do
            local h = e:FindFirstChildOfClass("Humanoid")
            if h and h.Health > 0 and string.lower(e.Name) == string.lower(mobName) then
                now[e] = true
            end
        end
    end
    for e in pairs(QuestFlow.alive) do
        if not now[e] then
            QuestFlow.kills = QuestFlow.kills + 1
        end
    end
    QuestFlow.alive = now
end

local function ensureQuest()
    local q = getQuestForLevel(Level.Value)
    local key = questKey(q)

    if key ~= QuestFlow.key then
        -- Quest moi (len level / moi bat farm): bay toi dao roi moi StartQuest.
        -- Khong can AbandonQuest: nhan quest moi la server tu de len quest cu.
        local anchor = IS_SEA1 and V(q[7]) or V(q[6])
        local _, _, hrp = getChar()
        if hrp and (anchor - hrp.Position).Magnitude > 60 then
            setStatus("Bay toi dao nhan quest (" .. q[2] .. ")...")
            flyToSmart(anchor + Vector3.new(0, 10, 0), 90)
        end
        local giverPos = findGiverPos(q[5])
        if giverPos then
            local _, _, root = getChar()
            if root and (giverPos - root.Position).Magnitude > 15 then
                flyGoalTo(giverPos + Vector3.new(0, 5, 0), 10, 15)
            end
        end
        setStatus("Nhan quest: " .. q[2])
        pcall(function() CommF:InvokeServer("StartQuest", q[3], q[4]) end)
        QuestFlow.key = key
        QuestFlow.kills = 0
        QuestFlow.alive = {}
        trackKills(q[2]) -- chot tap quai dang song lam moc dem
        task.wait(0.5)
    elseif QuestFlow.kills >= KILL_QUOTA then
        -- Du quota: nhan lai quest ngay tai cho, khong bay ve NPC, khong huy
        setStatus("Nhan lai quest: " .. q[2])
        pcall(function() CommF:InvokeServer("StartQuest", q[3], q[4]) end)
        QuestFlow.kills = 0
        QuestFlow.alive = {}
        trackKills(q[2])
        task.wait(0.5)
    end
    return q
end

-- ===== Danh 1 con quai: khoa muc tieu, gom bay, fast attack =====
local function fightMob(enemy, mobName)
    local tool = equipMelee()
    local hadQuest = questActive()
    local atkAcc, slowAcc = 0, 0
    local nilStreak = 0
    local fightState = { count = 0 } -- so quai da bring trong tran nay (du la dung gom)
    while Settings.Farm and sessionAlive() do
        local dt = task.wait(0.05)
        local eHum = enemy:FindFirstChildOfClass("Humanoid")
        local eRoot = enemy:FindFirstChild("HumanoidRootPart")
        local char, hum, hrp = getChar()
        if not eHum or not eRoot or eHum.Health <= 0 or not enemy.Parent then break end
        if not char or not hum or not hrp or hum.Health <= 0 then break end

        -- Khoa muc tieu: luong fly bam sat tren dau con quai nay den khi no chet/bien mat
        Flight.goal = eRoot.Position + Vector3.new(0, Settings.HoverHeight, 0)

        -- Gom quai (toi da BringMax con): bring 1 lan toi gan player, giu cao do mat dat
        local mobs = { { model = enemy, hum = eHum, root = eRoot, dist = 0 } }
        if Settings.BringMobs then
            mobs = collectMobs(mobName, hrp, enemy)
        end

        atkAcc = atkAcc + dt
        slowAcc = slowAcc + dt
        if slowAcc >= 0.3 then
            slowAcc = 0
            claimSimulation()
            buffHitbox()
            spendStats()
            maintainAura()
            -- Chi bring khi con dang danh dung la quai cua quest hien tai
            if Settings.BringMobs and getQuestForLevel(Level.Value)[2] == mobName then
                bringPass(mobs, enemy, hrp, fightState)
            end
            -- Tu dem kill theo dung ten quai (chuan Sankeurr)
            trackKills(mobName)
            -- Len level moi giua tran: nha khoa de doi quest moi ngay
            if QuestFlow.key and questKey(getQuestForLevel(Level.Value)) ~= QuestFlow.key then break end
            if QuestFlow.key and QuestFlow.kills >= KILL_QUOTA then break end
            -- Phanh an toan (muon cua GGEZ): GUI quest tat giua tran = game da tra xong quest
            local activeNow, _, _, killed, needed = readQuestGui()
            if activeNow then
                nilStreak = 0
                if killed and needed then
                    setStatus("Dang danh: " .. mobName .. " (" .. tostring(killed) .. "/" .. tostring(needed) .. ")")
                end
            else
                nilStreak = nilStreak + 1
                if hadQuest and nilStreak >= 2 then
                    QuestFlow.kills = KILL_QUOTA -- ep vong sau nhan lai quest ngay
                    break
                end
            end
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
    while Settings.Farm and sessionAlive() do
        local ok, err = pcall(function()
            local char, hum, hrp = getChar()
            if not char or not hum or not hrp or hum.Health <= 0 then
                setStatus("Cho nhan vat hoi sinh...")
                task.wait(1)
                return
            end

            local q = ensureQuest()
            if not Settings.Farm then return end

            spendStats()
            maintainAura()

            local enemy = findEnemy(q[2])
            if not enemy then
                -- Chua thay quai: tiep tuc bay ve phia bai quai va quet tiep,
                -- con quai nao xuat hien la bay thang toi con do (khong dung yen 1 cho)
                setStatus("Tim quai " .. q[2] .. "...")
                Flight.goal = V(q[7]) + Vector3.new(0, 20, 0)
                task.wait(0.6)
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
    Flight.goal = nil
    setStatus("Da tat farm")
end

local function startFarm()
    if Module._farmRunning then return end
    Module._farmRunning = true
    task.spawn(function()
        farmLoop()
        Module._farmRunning = false
    end)
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

-- Auto Buy chay nen doc lap (ke ca khi Auto Farm dang tat)
task.spawn(function()
    while sessionAlive() do
        if Settings.AutoBuy then
            pcall(autoBuyStep)
        end
        task.wait(1)
    end
end)

-- ===== GUI nhe cho dien thoai (co thu nho) =====
local function buildGui()
    local gui = Instance.new("ScreenGui")
    gui.Name = "BON_BloxFruits"
    gui.ResetOnSpawn = false

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 236, 0, 520)
    frame.Position = UDim2.new(0, 10, 0, 90)
    frame.BackgroundColor3 = Color3.fromRGB(24, 26, 32)
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -70, 0, 32)
    title.Position = UDim2.new(0, 10, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "BON - Blox Fruits v9"
    title.TextColor3 = Color3.fromRGB(103, 232, 249)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 13
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = frame

    local body = Instance.new("Frame")
    body.Name = "Body"
    body.Size = UDim2.new(1, 0, 0, 452)
    body.Position = UDim2.new(0, 0, 0, 34)
    body.BackgroundTransparency = 1
    body.Parent = frame

    local function headerBtn(x, txt)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, 28, 0, 28)
        b.Position = UDim2.new(1, x, 0, 2)
        b.BackgroundColor3 = Color3.fromRGB(45, 48, 58)
        b.Text = txt
        b.TextColor3 = Color3.fromRGB(230, 230, 230)
        b.Font = Enum.Font.GothamBold
        b.TextSize = 13
        b.Parent = frame
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 6)
        c.Parent = b
        return b
    end

    local minimized = false
    local minBtn = headerBtn(-64, "-")
    minBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        body.Visible = not minimized
        frame.Size = minimized and UDim2.new(0, 236, 0, 34) or UDim2.new(0, 236, 0, 520)
        minBtn.Text = minimized and "+" or "-"
    end)

    local closeBtn = headerBtn(-32, "X")
    closeBtn.MouseButton1Click:Connect(function()
        Module.Stop()
    end)

    local function makeToggle(y, label, get, set)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -20, 0, 38)
        btn.Position = UDim2.new(0, 10, 0, y)
        btn.BackgroundColor3 = Color3.fromRGB(38, 41, 50)
        btn.TextColor3 = Color3.fromRGB(230, 230, 230)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 13
        btn.Parent = body
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

    makeToggle(4, "Auto Farm", function() return Settings.Farm end, function(v)
        Settings.Farm = v
        if v then
            startFarm()
        else
            Flight.goal = nil
        end
    end)
    makeToggle(46, "Gom Mob", function() return Settings.BringMobs end, function(v) Settings.BringMobs = v end)
    makeToggle(88, "Tu Cong Stat", function() return Settings.AutoStat end, function(v) Settings.AutoStat = v end)
    makeToggle(130, "Auto Aura (Buso)", function() return Settings.AutoAura end, function(v) Settings.AutoAura = v end)

    local statBtn = Instance.new("TextButton")
    statBtn.Size = UDim2.new(1, -20, 0, 38)
    statBtn.Position = UDim2.new(0, 10, 0, 172)
    statBtn.BackgroundColor3 = Color3.fromRGB(38, 41, 50)
    statBtn.TextColor3 = Color3.fromRGB(230, 230, 230)
    statBtn.Font = Enum.Font.Gotham
    statBtn.TextSize = 13
    statBtn.Parent = body
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
        lbl.Parent = body

        local val = Instance.new("TextLabel")
        val.Size = UDim2.new(0, 44, 0, 34)
        val.Position = UDim2.new(0, 148, 0, y)
        val.BackgroundTransparency = 1
        val.Text = getText()
        val.TextColor3 = Color3.fromRGB(103, 232, 249)
        val.Font = Enum.Font.GothamBold
        val.TextSize = 14
        val.Parent = body

        local function stepBtn(x, txt, delta)
            local b = Instance.new("TextButton")
            b.Size = UDim2.new(0, 34, 0, 34)
            b.Position = UDim2.new(0, x, 0, y)
            b.BackgroundColor3 = Color3.fromRGB(38, 41, 50)
            b.Text = txt
            b.TextColor3 = Color3.fromRGB(230, 230, 230)
            b.Font = Enum.Font.GothamBold
            b.TextSize = 16
            b.Parent = body
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

    makeStepper(214, "Toc do bay", function() return tostring(Settings.FlySpeed) end, function(d)
        Settings.FlySpeed = math.clamp(Settings.FlySpeed + d * 25, 100, 350)
    end)
    makeStepper(252, "Gom toi da", function() return tostring(Settings.BringMax) end, function(d)
        Settings.BringMax = math.clamp(Settings.BringMax + d, 2, 5)
    end)

    makeToggle(290, "Auto Buy (uu tien Melee)", function() return Settings.AutoBuy end, function(v) Settings.AutoBuy = v end)

    -- Muc mua thu cong: cuon danh sach, moi nut ghi gia. Du tien moi ban remote.
    local moneyLabel = Instance.new("TextLabel")
    moneyLabel.Size = UDim2.new(1, -20, 0, 18)
    moneyLabel.Position = UDim2.new(0, 10, 0, 332)
    moneyLabel.BackgroundTransparency = 1
    moneyLabel.Text = "MUA THU CONG: dang tai tien..."
    moneyLabel.TextColor3 = Color3.fromRGB(160, 165, 175)
    moneyLabel.Font = Enum.Font.Gotham
    moneyLabel.TextSize = 10
    moneyLabel.TextXAlignment = Enum.TextXAlignment.Left
    moneyLabel.Parent = body

    local shopList = Instance.new("ScrollingFrame")
    shopList.Name = "ShopList"
    shopList.Size = UDim2.new(1, -20, 0, 96)
    shopList.Position = UDim2.new(0, 10, 0, 352)
    shopList.BackgroundColor3 = Color3.fromRGB(30, 33, 40)
    shopList.BorderSizePixel = 0
    shopList.ScrollBarThickness = 4
    shopList.CanvasSize = UDim2.new(0, 0, 0, #SHOP_ITEMS * 38 + 4)
    shopList.Parent = body
    local shopCorner = Instance.new("UICorner")
    shopCorner.CornerRadius = UDim.new(0, 6)
    shopCorner.Parent = shopList

    local shopRefreshers = {}
    for idx, item in ipairs(SHOP_ITEMS) do
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1, -8, 0, 34)
        b.Position = UDim2.new(0, 4, 0, 4 + (idx - 1) * 38)
        b.BackgroundColor3 = Color3.fromRGB(38, 41, 50)
        b.TextColor3 = Color3.fromRGB(230, 230, 230)
        b.Font = Enum.Font.Gotham
        b.TextSize = 10
        b.TextXAlignment = Enum.TextXAlignment.Left
        b.Parent = shopList
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 6)
        c.Parent = b
        local function refresh()
            local beli, frag = getMoney()
            local affordable = (item.beli or 0) <= beli and (item.frag or 0) <= frag
            local owned = shopBought[item.name] or (item.tools and findToolByNames(item.tools) ~= nil)
            if owned then
                b.Text = "  Da co: " .. item.display
                b.BackgroundColor3 = Color3.fromRGB(21, 94, 117)
            else
                b.Text = "  Mua " .. item.display .. " | " .. priceText(item)
                b.BackgroundColor3 = affordable and Color3.fromRGB(20, 83, 45) or Color3.fromRGB(38, 41, 50)
            end
        end
        table.insert(shopRefreshers, refresh)
        b.MouseButton1Click:Connect(function()
            tryBuyItem(item, true)
            refresh()
        end)
        refresh()
    end

    local function refreshShop()
        local beli, frag = getMoney()
        moneyLabel.Text = "MUA THU CONG | Beli: " .. fmtNum(beli) .. " | Frag: " .. fmtNum(frag)
        for _, fn in ipairs(shopRefreshers) do pcall(fn) end
    end
    refreshShop()

    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, -20, 0, 26)
    status.Position = UDim2.new(0, 10, 0, 456)
    status.BackgroundTransparency = 1
    status.Text = "Trang thai: San sang"
    status.TextColor3 = Color3.fromRGB(160, 165, 175)
    status.Font = Enum.Font.Gotham
    status.TextSize = 11
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.Parent = body
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
    -- Xoa GUI cua ban script cu (neu Bon vua chay lai loadstring)
    local oldGui = parentGui:FindFirstChild("BON_BloxFruits")
    if oldGui then oldGui:Destroy() end
    gui.Parent = parentGui
    task.spawn(function()
        while sessionAlive() and frame.Parent do
            refreshShop()
            task.wait(2)
        end
    end)
    return gui
end

function Module.Start()
    if Module._gui then return end
    Module._gui = buildGui()
    print("[BloxFruits] Da tai GUI v9. Level hien tai: " .. tostring(Level.Value))
end

function Module.Stop()
    Settings.Farm = false
    Flight.goal = nil
    if Module._gui then
        Module._gui:Destroy()
        Module._gui = nil
    end
end

Module.Start()
print("[BloxFruits] San sang (v9). Bam 'Auto Farm: BAT' tren GUI de farm. Level: " .. tostring(Level.Value))

return Module
