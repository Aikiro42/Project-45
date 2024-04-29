function build(directory, config, parameters, level, seed)
  parameters = parameters or {}

  local ammoStockDescriptionFormat = root.assetJson("/configs/project45/project45_general.config:ammoStockDescriptionFormat")
  local ammoStockMaxDescriptionFormat = root.assetJson("/configs/project45/project45_general.config:ammoStockMaxDescriptionFormat")
  local ammoStockLimit = root.assetJson("/configs/project45/project45_general.config:ammoStockLimit", 300)
  
  local ammo = parameters.ammo or config.ammo
  if not ammo then
    sb.logInfo("fuck you")
    config.ammo = ammoStockLimit/2
    ammo = config.ammo
  end
  
  if ammo < ammoStockLimit then
    parameters.description = string.format(
      ammoStockDescriptionFormat,
      ammo,
      ammoStockLimit
    )
  else
    parameters.shortdescription = config.shortdescription .. " ^yellow;^reset;"
    parameters.description = string.format(
      ammoStockMaxDescriptionFormat,
      ammo
    )
  end

  local priceMult = parameters.pricePerAmmo or config.pricePerAmmo or 1
  parameters.price = priceMult * ammo
  
  return config, parameters
end