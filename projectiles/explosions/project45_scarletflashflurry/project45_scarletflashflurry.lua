local dmgListener
function init()
    local actionOnSpawn = config.getParameter("actionOnSpawn", {nil})
    for _, action in ipairs(actionOnSpawn) do
        projectile.processAction(action) 
    end
end

function update(dt)
    
end