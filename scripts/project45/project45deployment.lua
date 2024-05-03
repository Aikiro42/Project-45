project45deployment_initOld = init
project45deployment_updateOld = update

function debugStuff()
  sb.logInfo("hello?")
  sb.logInfo(sb.printJson(self.toPrint, 1))
end

function init()
  project45deployment_initOld()
  self.debugTimer = 0
  self.toPrint = {}
  storage.clientAnimationParameters = storage.clientAnimationParameters or {}
  message.setHandler("project45AimPosition", function(messageName, isLocalEntity, aimPos)
    self.toPrint = sb.jsonMerge(self.toPrint, {
      messageName=messageName,
      isLocalEntity=isLocalEntity,
      aimPos=aimPos
    })
    self.aimPosition = aimPos
  end)
  message.setHandler("project45name", function(messageName, isLocalEntity, name)
    self.toPrint = sb.jsonMerge(self.toPrint, {
      player=name
    })
  end)
end

function update(dt)
  project45deployment_updateOld(dt)

  if self.debugTimer <= 0 then
    self.debugTimer = 1
    debugStuff()
  else
    self.debugTimer = self.debugTimer - dt
  end


end