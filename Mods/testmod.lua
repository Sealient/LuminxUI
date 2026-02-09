return {
    Title = "Flight Mod",
    Version = "1.2.0",
    Description = "Fly around the map easily.",
    Script = [[
        local Mod = {}
        local active = true
        
        -- Your main mod logic
        task.spawn(function()
            while active do
                task.wait(1)
                print("Flying...")
            end
        end)

        -- This function is called when the user clicks 'Disable'
        Mod.Stop = function()
            active = false
            print("Flight Stopped")
        end

        return Mod
    ]]
}
