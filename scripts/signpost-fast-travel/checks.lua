local core = require('openmw.core')

if core.API_REVISION < 51 then
    error('This mod requires OpenMW 0.49.0 or newer, please update.')
end
