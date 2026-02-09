return {
    Title = "Test Mod",
    Version = "1.1.0", -- Bump this to test the update button!
    Description = "Now with Disable and Update support.",
    Script = [[
        local mod = {}
        print("Mod Started")
        
        mod.Stop = function()
            print("Mod Stopped and Cleaned Up")
        end
        
        return mod
    ]]
}
