debug = {}

function debug.timedPrint(text, dtAccumulator, prefix)
    if dtAccumulator >= 1 then
        sb.logInfo((prefix or "") .. text)
        return 0
    end
    return dtAccumulator
end

function print(text, prefix)
    sb.logInfo((prefix or "[PROJECT 45] ") .. text)
    return 0
end