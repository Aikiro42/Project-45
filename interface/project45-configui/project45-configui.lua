function promptRestart()
  widget.setText("lblRestartToSave", "^red;Restart Game to Apply Changes.")
end

function toggleCursorBars()
	status.setStatusProperty("project45_renderBarsAtCursor", widget.getChecked("btnToggleCursorBars"))
  promptRestart()
end

function togglePerformanceMode()
	status.setStatusProperty("project45_performanceMode", widget.getChecked("btnTogglePerformanceMode"))
	
	if widget.getChecked("btnTogglePerformanceMode") then
		status.setStatusProperty("project45_useAmmoCounterImages", false)
		widget.setChecked("btnUseAmmoCounterImages", false)
		widget.setFontColor("lblUseAmmoCounterImages", "gray")
	else
		widget.setFontColor("lblUseAmmoCounterImages", "white")
	end

	promptRestart()
end

function toggleUseAmmoCounterImages()
	if not status.statusProperty("project45_performanceMode") then
		status.setStatusProperty("project45_useAmmoCounterImages", widget.getChecked("btnUseAmmoCounterImages"))
  	promptRestart()
	else
		widget.setChecked("btnUseAmmoCounterImages", false)
	end
end

function init()
	widget.setChecked("btnToggleCursorBars", status.statusProperty("project45_renderBarsAtCursor", true))
	widget.setChecked("btnTogglePerformanceMode", status.statusProperty("project45_performanceMode", false))
	widget.setChecked("btnUseAmmoCounterImages", status.statusProperty("project45_useAmmoCounterImages", true))
end

function uninit()

end

function update(dt)

end
