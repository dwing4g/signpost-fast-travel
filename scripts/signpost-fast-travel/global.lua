require("scripts.signpost-fast-travel.checks")
local async = require('openmw.async')
local core = require('openmw.core')
local types = require('openmw.types')
local util = require('openmw.util')
local world = require('openmw.world')
local Activation = require('openmw.interfaces').Activation
local signs = require("scripts.signpost-fast-travel.signs")

local function doTeleport(data)
    local playerPos = data.actor.position
    local targetPos = data.pos
    local timeMachine = world.createObject("momw_sft_timemachine")

    -- https://wiki.openmw.org/index.php?title=Research:Trading_and_Services#Travel_costs
    local distance = (
        math.sqrt((playerPos.x - targetPos.x) * (playerPos.x - targetPos.x)
            + (playerPos.y - targetPos.y) * (playerPos.y - targetPos.y))
    )
    distance = distance / core.getGMST("fTravelTimeMult")
    local gameHour = core.getGameTime() / 60 / 60 - 24 / 24 % 24
    gameHour = gameHour + distance
    timeMachine:teleport(data.actor.cell, data.actor.position)

    -- A one frame delay is needed before things that are created can be used
    async:newUnsavableSimulationTimer(
        0.1,
        function()
            world.mwscript.getLocalScript(timeMachine).variables.newHour = gameHour
            timeMachine:remove(1)

            --TODO: Teleport followers; attendme does this
            --TODO: Random chance to stop midway and spawn enemies
            data.actor:teleport(
                data.cell.name,
                util.vector3(targetPos.x, targetPos.y, targetPos.z),
                data.actor.rotation--TODO: set a fixed rotation for each target!
            )
        end
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
