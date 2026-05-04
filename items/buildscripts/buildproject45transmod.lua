function build(directory, config, parameters, level, seed)
  

  --[[
  local configParameter = function(keyName, defaultValue)
    if parameters[keyName] ~= nil then
      return parameters[keyName]
    elseif config[keyName] ~= nil then
      return config[keyName]
    else
      return defaultValue
    end
  end
  --]]

  config.tooltipFields.instructionLabel = " Apply on select Project 45\nweapons to transform them"

  return config, parameters
end