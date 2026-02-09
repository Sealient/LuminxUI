return {
    Title = "Super Movement",
    Version = "1.0.0",
    Description = "Increases your WalkSpeed and JumpPower while enabled.",
    Script = [[
        local Mod = {}
        local Player = game.Players.LocalPlayer
        local Character = Player.Character or Player.CharacterAdded:Wait()
        local Humanoid = Character:WaitForChild("Humanoid")

        -- Logic to run when "Enable" is clicked
        print("[Luminx]: Super Movement Enabled!")
        
        -- Store originals to reset them later
        local oldSpeed = Humanoid.WalkSpeed
        local oldJump = Humanoid.JumpPower
        
        Humanoid.WalkSpeed = 100
        Humanoid.JumpPower = 150
        Humanoid.UseJumpPower = true -- Ensures modern Roblox jump logic

        -- Logic to run when "Disable" or "Uninstall" is clicked
        Mod.Stop = function()
            if Humanoid then
                Humanoid.WalkSpeed = oldSpeed
                Humanoid.Humanoid.JumpPower = oldJump
            end
            print("[Luminx]: Super Movement Disabled and Reset.")
        end

        return Mod
    ]]
}
