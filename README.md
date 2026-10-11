# BON Roblox Scripts

Repo chứa script Roblox tự chế của Bon, chạy bằng loadstring từ GitHub để test nhanh trong game.

## Cách chạy

Dán 1 dòng này vào executor:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/bonorbom/Script-r-b-l-c/main/main.lua"))()
```

Loader sẽ tự tải các script trong danh sách `SCRIPTS` ở `main.lua`.

## BON PVP Universal (aimbot + ESP cho mọi game)

Bản PVP tách riêng, không phụ thuộc Blox Fruits — xài cho game bắn súng hay bất kỳ game nào:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/bonorbom/Script-r-b-l-c/main/scripts/pvp-universal.lua"))()
```

Tính năng: aimbot (Smooth/Lock, vòng FOV 10-360, wall check), ESP (box/tia/highlight/tên + khoảng cách + máu, màu theo đội, friendly màu xanh lá). Game FFA (không chia đội) thì mặc định ai cũng là địch trừ friendly.

## Thêm script mới

1. Tạo file mới trong thư mục `scripts/`, ví dụ `scripts/myscript.lua`.
2. Cuối file nhớ `return` về 1 table chứa các hàm (xem mẫu `scripts/example.lua`).
3. Thêm 1 dòng vào danh sách `SCRIPTS` trong `main.lua`:

```lua
{ name = "MyScript", path = "scripts/myscript.lua", on = true },
```

4. Chạy lại dòng loadstring ở trên — loader thêm `?t=` sau URL nên không bị dính cache bản cũ của GitHub.

## Gọi hàm sau khi load

```lua
_G.BON.Modules.Example.SetSpeed(50)
_G.BON.Modules.Example.GetInfo()
```

## Lưu ý

- Repo phải để **public** thì `game:HttpGet` mới tải được file raw (không cần token).
- Script chỉ chạy phía client qua executor; sửa trên GitHub là vào game chạy lại loadstring để test bản mới.
