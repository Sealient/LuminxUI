-- LuminxUI Sample Mod Template
local Mod = {}

-- The 'init' function is called when the user clicks "Enable"
-- We pass the UI Library (windowFunctions) so the mod can use your Notify system.
function Mod.init(UILib)
    UILib:Notify("Mod Status", "Test Mod has been successfully enabled!", 4, "success")
    
    -- Example Logic: A simple heartbeat message
    local isRunning = true
    task.spawn(function()
        while isRunning do
            print("[Luminx Mod] Heartbeat Active...")
            task.wait(10)
        end
    end)

    -- IMPORTANT: Return a cleanup function for when the user clicks "Disable"
    return function()
        isRunning = false
        UILib:Notify("Mod Status", "Test Mod disabled and cleaned up.", 3, "info")
    end
end

return Mod
