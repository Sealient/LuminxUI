-- LuminxUI Sample Mod
local Mod = {}

-- This runs when 'Enable' is clicked.
-- We pass the UI library functions so the mod can use them.
function Mod.init(UILib)
    UILib:Notify("Mod Loaded", "Sample Mod is now active!", 3, "success")
    
    local running = true
    task.spawn(function()
        while running do
            print("[Luminx] Mod is pulsing...")
            task.wait(5)
        end
    end)

    -- Return this function to handle 'Disable' logic
    return function()
        running = false
        UILib:Notify("Mod Disabled", "Cleanup finished.", 3, "info")
    end
end

return Mod
