function build(directory, config, parameters, level, seed)
  parameters = parameters or {}

  local ammoStockDescriptionFormat = root.assetJson("/configs/project45/project45_generalconfig.config:ammoStockDescriptionFormat")
  local ammoStockMaxDescriptionFormat = root.assetJson("/configs/project45/project45_generalconfig.config:ammoStockMaxDescriptionFormat")
  local ammoStockLimit = root.assetJson("/configs/project45/project45_generalconfig.config:ammoStockLimit", 300)
  
  local ammo = parameters.ammo or config.ammo or ammoStockLimit
  
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