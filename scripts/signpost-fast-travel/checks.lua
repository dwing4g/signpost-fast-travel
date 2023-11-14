local core = require('openmw.core')

if core.API_REVISION < 39 then
    error('This mod requires OpenMW 0.49.0 or newer, please update.')
end

if not core.contentFiles.has("signpost-fast-travel.omwaddon") then
    error("Required plugin not found! Please be sure to load signpost-fast-travel.omwaddon")
end
