function promptRestart()
  widget.setText("lblRestartToSave", "^red;Restart Game to Apply Changes.")
end

function toggleCursorBars()
	status.setStatusProperty("project45_renderBarsAtCursor", widget.getChecked("btnToggleCursorBars"))
  promptRestart()
end

function init()
	widget.setChecked("btnToggleCursorBars", status.statusProperty("project45_renderBarsAtCursor", true))
end

function uninit()

end

function update(dt)

end
