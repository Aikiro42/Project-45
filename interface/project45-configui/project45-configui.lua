---@diagnostic disable: lowercase-global
require "/scripts/project45/project45util.lua"

	
local invSettings = {
	"useAmmoCounterImages",
	-- "accurateBars",
	"reloadFlashLasers",
	"armFrameAnimations"
}

function promptRestart()
	-- If this function is ever called, then players have the ability to set the mod's settings
	player.setProperty("project45_canSetSettings", true)
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

function updateDamageScaling()
	local sliderVal = widget.getSliderValue("sldDamageScaling") or 0
	widget.setText("lblDamageScaling", "Damage Scaling: " .. sliderVal .."%")

	local newValue = (widget.getSliderValue("sldDamageScaling") or 0)/100
	local oldValue = player.getProperty("project45_damageScaling", 0)
	if newValue ~= oldValue then
		player.setProperty("project45_damageScaling", newValue)
  	promptRestart()
	end
end

function updateChallengeScaling()
	local sliderVal = widget.getSliderValue("sldChallengeScaling") or 0
	widget.setText("lblChallengeScaling", "Challenge Scaling: " .. sliderVal .."%")

	local newValue = (widget.getSliderValue("sldChallengeScaling") or 0)/100
	local oldValue = player.getProperty("project45_challengeScaling", 0)
	if newValue ~= oldValue then
		player.setProperty("project45_challengeScaling", newValue)
  	promptRestart()
	end
end

function init()
	
	-- sldDamageScaling
	widget.setSliderRange("sldDamageScaling", 0, 100)
	local sldDamageScalingVal = math.floor(player.getProperty("project45_damageScaling", 0)*100)
	widget.setSliderValue("sldDamageScaling", sldDamageScalingVal)
	widget.setText("lblDamageScaling", "Damage Scaling: " .. sldDamageScalingVal .."%")

	widget.setSliderRange("sldChallengeScaling", 0, 90)
	local sldChallengeScalingVal = math.floor(player.getProperty("project45_challengeScaling", 0)*100)
	widget.setSliderValue("sldChallengeScaling", sldChallengeScalingVal)
	widget.setText("lblChallengeScaling", "Challenge Scaling: " .. sldChallengeScalingVal .."%")

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
