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
	widget.setText("lblGuide", "Changes where the charge, reload, and jam bars are rendered.\n\nIf this setting is unticked, the bars are rendered near the player.")
	player.setProperty("project45_renderBarsAtCursor", widget.getChecked("btnToggleCursorBars"))
  promptRestart()
end

function togglePerformanceMode()
	widget.setText("lblGuide", "Disables some VFX and particle spawns, like screenshake and bullet casings. Also changes how some UI elements are rendered.\n\nTicking this forces some settings to turn off.")
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
	widget.setText("lblGuide", "If unticked, arms always point forward and don't animate.\n\nUseful when using the guns with other races with different arm sprites; disabling arm frame animations will make the arms look a little less weird while wielding the gun.")
	if not player.getProperty("project45_performanceMode") then
		player.setProperty("project45_armFrameAnimations", widget.getChecked("btnArmFrameAnimations"))
  	promptRestart()
	else
		widget.setChecked("btnArmFrameAnimations", false)
	end
end

function toggleReloadFlashLasers()
	widget.setText("lblGuide", "If ticked, flashlights and lasers remain active even through reloads.\n\nIf reloading a Pistol with a flashlight or laser gives you a bit of nausea, it is recommended to turn this setting off.")
	if not player.getProperty("project45_performanceMode") then
		player.setProperty("project45_reloadFlashLasers", widget.getChecked("btnReloadFlashLasers"))
  	promptRestart()
	else
		widget.setChecked("btnReloadFlashLasers", false)
	end
end

function toggleUseAmmoCounterImages()
	widget.setText("lblGuide", "If ticked, the 'empty' and 'reloading' UI indicators are animated.\n\nOtherwise, they are shown as 'E' and 'R', respectively.")
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
	local challengeVal = widget.getSliderValue("sldChallengeScaling") or 0
	widget.setText("lblDamageScaling", "Damage Scaling: " .. sliderVal .."%")
	widget.setText("lblGuide", "Weapon damage scales with the Power provided by armor by " .. sliderVal .. "%.\n\ne.g. If your weapon deals ^#ea9931;10 damage^reset;, and you're wearing the ^#96cbe7;Seeker's set (400% power)^reset;,\n\nyou will deal ^#d93a3a;" .. 10 * (1 + (sliderVal/100 * 3)) * ((100 - challengeVal)/100) .. " damage^reset;.")

	local newValue = (widget.getSliderValue("sldDamageScaling") or 0)/100
	local oldValue = player.getProperty("project45_damageScaling", 0)
	if newValue ~= oldValue then
		player.setProperty("project45_damageScaling", newValue)
  	promptRestart()
	end
end

function updateChallengeScaling()
	local sliderVal = widget.getSliderValue("sldChallengeScaling") or 0
	local damageScalingVal = widget.getSliderValue("sldDamageScaling") or 0
	widget.setText("lblChallengeScaling", "Challenge Scaling: " .. sliderVal .."%")
	widget.setText("lblGuide", "Too much damage? This setting decreases it by  " .. sliderVal .. "% (".. (100 - sliderVal) / 100 .."x).\n\ne.g. If your weapon deals ^#ea9931;10 damage^reset;, and you're wearing the ^#96cbe7;Seeker's set (400% power)^reset;,\n\nyou will deal ^#d93a3a;" .. 10 * (1 + (damageScalingVal/100 * 3)) * ((100 - sliderVal)/100) .. " damage^reset;.\n\n^#b2e89d;There's a mod that rewards playing with at least 20% Challenge Scaling.")

	local newValue = (widget.getSliderValue("sldChallengeScaling") or 0)/100
	local oldValue = player.getProperty("project45_challengeScaling", 0)
	if newValue ~= oldValue then
		player.setProperty("project45_challengeScaling", newValue)
  	promptRestart()
	end
end

function init()
	
	widget.setText("lblGuide", "^#838383;Modify a setting to see what it does.^reset;")

	-- sldDamageScaling
	widget.setSliderRange("sldDamageScaling", 0, 100)
	local sldDamageScalingVal = math.floor(player.getProperty("project45_damageScaling", 0)*100)
	widget.setSliderValue("sldDamageScaling", sldDamageScalingVal)
	widget.setText("lblDamageScaling", "Damage Scaling: " .. sldDamageScalingVal .."%")

	widget.setSliderRange("sldChallengeScaling", 0, 99)
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
