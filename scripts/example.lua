-- Script mau - copy file nay de viet script moi
-- Module tra ve 1 bang (table), loader se luu vao _G.BON.Modules.Example

local Players = game:GetService("Players")
local player = Players.LocalPlayer

local Example = {}

function Example.GetInfo()
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    return {
        Name = player.Name,
        DisplayName = player.DisplayName,
        WalkSpeed = hum and hum.WalkSpeed or nil,
    }
end

function Example.SetSpeed(speed)
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.WalkSpeed = speed
        print("[Example] WalkSpeed -> " .. tostring(speed))
    else
        warn("[Example] Chua co nhan vat")
    end
end

print("[Example] Da load, player: " .. player.Name)

return Example
