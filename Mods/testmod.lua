-- Sample test mod for LuminxUI
-- Exposes metadata used by the UI and a simple init function
local MOD = {
	name = "Sample Tet Mod",
	description = "A emo mod bundled with LuminxUI for testing the Mods tab and cards.",
	version = "0.1",
	author = "Sealient",
}

function MOD.init(window)
	-- Example: call the library notification API if available
	pcall(function()
		if window and window.Notify then
			window:Notify("Sample Test Mod", "Initialized successfully.", 3, "success")
		end
	end)
end

return MOD
