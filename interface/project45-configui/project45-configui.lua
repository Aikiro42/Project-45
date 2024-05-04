require "/scripts/project45/project45util.lua"

	
local invSettings = {
	"useAmmoCounterImages",
	-- "accurateBars",
	"reloadFlashLasers",
	"armFrameAnimations"
}

function promptRestart()
  widget.setText("lblRestartToSave", "^red;Restart Game to Apply Changes.")
end

function toggleCursorBars()
	player.setProperty("project45_renderBarsAtCursor", widget.getChecked("btnToggleCursorBars"))
  promptRestart()
end

function togglePerformanceMode()
	player.setProperty("project45_performanceMode", widget.getChecked("btnTogglePerformanceMode"))
	
	for _, setting in ipairs(invSettings) do
	
		if widget.getChecked("btnTogglePerformanceMode") then
			player.setProperty("project45_" .. setting, false)
			widget.setChecked("btn" .. project45util.capitalize(setting), false)
			widget.setFontColor("lbl" .. project45util.capitalize(setting), "gray")
		else
			widget.setFontColor("lbl" .. project45util.capitalize(setting), "white")
		end

	end

	promptRestart()
end

function toggleArmFrameAnimations()
	if not player.getProperty("project45_performanceMode") then
		player.setProperty("project45_armFrameAnimations", widget.getChecked("btnArmFrameAnimations"))
  	promptRestart()
	else
		widget.setChecked("btnArmFrameAnimations", false)
	end
end

function toggleReloadFlashLasers()
	if not player.getProperty("project45_performanceMode") then
		player.setProperty("project45_reloadFlashLasers", widget.getChecked("btnReloadFlashLasers"))
  	promptRestart()
	else
		widget.setChecked("btnReloadFlashLasers", false)
	end
end

function toggleUseAmmoCounterImages()
	if not player.getProperty("project45_performanceMode") then
		player.setProperty("project45_useAmmoCounterImages", widget.getChecked("btnUseAmmoCounterImages"))
  	promptRestart()
	else
		widget.setChecked("btnUseAmmoCounterImages", false)
	end
end

--[[
function toggleAccurateBars()
	if not player.getProperty("project45_performanceMode") then
		player.setProperty("project45_accurateBars", widget.getChecked("btnAccurateBars"))
  	promptRestart()
	else
		widget.setChecked("btnAccurateBars", false)
	end
end
--]]

function init()

	widget.setChecked("btnTogglePerformanceMode", player.getProperty("project45_performanceMode", false))
	widget.setChecked("btnToggleCursorBars", player.getProperty("project45_renderBarsAtCursor", true))

	for _, setting in ipairs(invSettings) do	
		if widget.getChecked("btnTogglePerformanceMode") then
			widget.setChecked("btn" .. project45util.capitalize(setting), false)
			widget.setFontColor("lbl" .. project45util.capitalize(setting), "gray")
		else
			widget.setChecked(
				"btn" .. project45util.capitalize(setting),
				player.getProperty("project45_" .. setting, true))
		end
	end

end

function uninit()

end

function update(dt)

end
