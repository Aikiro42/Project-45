function init()
  animator.setAnimationState("shield", "activating")
  animator.playSound("activate")
end

function update()
  mcontroller.controlModifiers({
    speedModifier = 0.5,
    airJumpModifier = 0.5,
    runningSuppressed = true
  })
end

function uninit()
  animator.stopAllSounds("activate")
  status.addEphemeralEffect("project45armadilloeffectend")
end