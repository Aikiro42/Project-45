function promptRestart()
  widget.setText("lblRestartToSave", "^red;Restart Game to Apply Changes.")
end

function toggleCursorBars()
	status.setStatusProperty("project45_renderBarsAtCursor", widget.getChecked("btnToggleCursorBars"))
  promptRestart()
end

function togglePerformanceMode()
	status.setStatusProperty("project45_performanceMode", widget.getChecked("btnTogglePerformanceMode"))
  promptRestart()
end

function init()
	widget.setChecked("btnToggleCursorBars", status.statusProperty("project45_renderBarsAtCursor", true))
	widget.setChecked("btnTogglePerformanceMode", status.statusProperty("project45_performanceMode", false))
end

function uninit()

end

function update(dt)

end
