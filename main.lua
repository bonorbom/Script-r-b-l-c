-- BON Loader - nap cac script tu GitHub ve chay trong Roblox
-- Lenh dan vao executor:
-- loadstring(game:HttpGet("https://raw.githubusercontent.com/bonorbom/Script-r-b-l-c/main/main.lua"))()

local BASE = "https://raw.githubusercontent.com/bonorbom/Script-r-b-l-c/main/"

_G.BON = _G.BON or {}
_G.BON.Modules = _G.BON.Modules or {}

local function loadModule(name, path)
    -- Chay lai loadstring: dung module cu truoc (neu co) de khoi trung GUI/vong lap
    local old = _G.BON.Modules[name]
    if old and type(old.Stop) == "function" then pcall(old.Stop) end

    local ok, result = pcall(function()
        -- them ?t= de ne cache cua GitHub raw, sua code la test lai duoc ngay
        local url = BASE .. path .. "?t=" .. tostring(math.floor(tick()))
        local src = game:HttpGet(url)
        local fn = loadstring(src)
        assert(fn, "compile fail: " .. path)
        return fn()
    end)
    if ok then
        _G.BON.Modules[name] = result
        print("[BON] OK: " .. name)
    else
        warn("[BON] FAIL: " .. name .. " - " .. tostring(result))
    end
end

-- Danh sach script: on = true/false de bat tat
local SCRIPTS = {
    { name = "Example", path = "scripts/example.lua", on = true },
    { name = "BloxFruits", path = "scripts/bloxfruits.lua", on = true },
}

for _, s in ipairs(SCRIPTS) do
    if s.on then
        loadModule(s.name, s.path)
    end
end

print("[BON] Loader xong. Goi ham qua: _G.BON.Modules.<TenModule>")
