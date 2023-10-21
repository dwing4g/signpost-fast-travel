require("scripts.signpost-fast-travel.checks")
local core = require('openmw.core')
local types = require('openmw.types')
local util = require('openmw.util')
local world = require('openmw.world')
local Activation = require('openmw.interfaces').Activation
local signs = require("scripts.signpost-fast-travel.signs")

local function doTeleport(data)
    local playerPos = data.actor.position
    local targetPos = data.pos
    -- https://wiki.openmw.org/index.php?title=Research:Trading_and_Services#Travel_costs
    local distance = (
        math.sqrt((playerPos.x - targetPos.x) * (playerPos.x - targetPos.x)
            + (playerPos.y - targetPos.y) * (playerPos.y - targetPos.y))
    )
    distance = distance / core.getGMST("fTravelTimeMult")
    world.mwscript.getGlobalScript("momw_sft_timemachine_scr").variables.distance = distance
    data.actor:sendEvent(
        "momw_sft_announceTeleport",
        {
            hours = distance,
            name = data.cell.name
        }
    )
    data.actor:teleport(
        data.cell.name,
        util.vector3(targetPos.x, targetPos.y, targetPos.z),
        util.transform.rotateZ(targetPos.rotZ)
    )
end

Activation.addHandlerForType(
    types.Activator,
    function(obj, actor)
        if signs.morrowindSigns[obj.recordId] then
            actor:sendEvent(
                "momw_sft_askForTeleport",
                { signId = obj.recordId }
            )
        end
    end
)

return { eventHandlers = { momw_sft_doTeleport = doTeleport } }
