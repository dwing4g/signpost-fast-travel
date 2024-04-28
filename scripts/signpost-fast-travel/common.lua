local core = require("openmw.core")
if core.API_REVISION < 51 then
    error(core.l10n("SignpostFastTravel")("needNewerOpenMW"))
end

return {COMBAT_END_DISTANCE = 7800}
