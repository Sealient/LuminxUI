-- Sample Mod for LuminxUI
local Mod = {}

function Mod.init(UILib)
    -- This runs when 'Enable' is clicked
    UILib:Notify("Mod Loaded", "Sample Test Mod is now active!", 3, "success")
    
    -- Example: Mods can create their own logic here
    local running = true
    task.spawn(function()
        while running do
            print("Mod is heartbeat pulsing...")
            task.wait(5)
        end
    end)

    -- Return a cleanup function (This runs when 'Disable' is clicked)
    return function()
        running = false
        UILib:Notify("Mod Disabled", "Cleanup successful.", 3, "info")
    end
end

return Mod
