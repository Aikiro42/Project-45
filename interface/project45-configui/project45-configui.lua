require "/scripts/project45/project45util.lua"

	
local invSettings = {
	"useAmmoCounterImages",
	"accurateBars",
	"noReloadFlashLasers"
}

function promptRestart()
  widget.setText("lblRestartToSave", "^red;Restart Game to Apply Changes.")
end

function toggleCursorBars()
	status.setStatusProperty("project45_renderBarsAtCursor", widget.getChecked("btnToggleCursorBars"))
  promptRestart()
end

function togglePerformanceMode()
	status.setStatusProperty("project45_performanceMode", widget.getChecked("btnTogglePerformanceMode"))
	
	for _, setting in ipairs(invSettings) do
	
		if widget.getChecked("btnTogglePerformanceMode") then
			status.setStatusProperty("project45_" .. setting, false)
			widget.setChecked("btn" .. project45util.capitalize(setting), false)
			widget.setFontColor("lbl" .. project45util.capitalize(setting), "gray")
		else
			widget.setFontColor("lbl" .. project45util.capitalize(setting), "white")
		end

	end

	promptRestart()
end

function toggleNoReloadFlashLasers()
	if not status.statusProperty("project45_performanceMode") then
		status.setStatusProperty("project45_noReloadFlashLasers", widget.getChecked("btnNoReloadFlashLasers"))
  	promptRestart()
	else
		widget.setChecked("btnNoReloadFlashLasers", false)
	end
end

function toggleUseAmmoCounterImages()
	if not status.statusProperty("project45_performanceMode") then
		status.setStatusProperty("project45_useAmmoCounterImages", widget.getChecked("btnUseAmmoCounterImages"))
  	promptRestart()
	else
		widget.setChecked("btnUseAmmoCounterImages", false)
	end
end

function toggleAccurateBars()
	if not status.statusProperty("project45_performanceMode") then
		status.setStatusProperty("project45_accurateBars", widget.getChecked("btnAccurateBars"))
  	promptRestart()
	else
		widget.setChecked("btnAccurateBars", false)
	end
end

function init()
	widget.setChecked("btnTogglePerformanceMode", status.statusProperty("project45_performanceMode", false))
	widget.setChecked("btnToggleCursorBars", status.statusProperty("project45_renderBarsAtCursor", true))

	for _, setting in ipairs(invSettings) do	
		if widget.getChecked("btnTogglePerformanceMode") then
			widget.setChecked("btn" .. project45util.capitalize(setting), false)
			widget.setFontColor("lbl" .. project45util.capitalize(setting), "gray")
		else
			widget.setChecked(
				"btn" .. project45util.capitalize(setting),
			status.statusProperty("project45_" .. setting, true))
		end
	end

end

function uninit()

end

function update(dt)

end
