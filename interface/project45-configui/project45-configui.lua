function toggleCursorBars()
	status.setStatusProperty("renderBarsAtCursor", widget.getChecked("btnToggleCursorBars"))
end

function init()
	widget.setChecked("btnToggleCursorBars", status.statusProperty("project45_renderBarsAtCursor", true))
end

function uninit()

end

function update(dt)

end
