require("scripts.signpost-fast-travel.checks")
local core = require('openmw.core')
local storage = require('openmw.storage')
local types = require('openmw.types')
local util = require('openmw.util')
local world = require('openmw.world')
local I = require("openmw.interfaces")
local signs = require("scripts.signpost-fast-travel.signs")
local MOD_ID = "SignpostFastTravel"

local settings = storage.globalSection('SettingsGlobal' .. MOD_ID)

if not core.contentFiles.has("AttendMe.omwscripts") then
    I.Settings.registerGroup {
        key = 'SettingsGlobal' .. MOD_ID,
        page = MOD_ID,
        l10n = MOD_ID,
        name = "settingsTitle",
        permanentStorage = false,
        settings = {
            {
                key = 'teleportFollowers',
                name = "teleportFollowers_name",
                default = true,
                renderer = 'checkbox',
            }
        }
    }
end

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

-- From AttendMe
local function followerTeleport(e)
    if settings:get('teleportFollowers') then
        e.actor:teleport(e.cellName, e.position)
    end
end

I.Activation.addHandlerForType(
    types.Activator,
    function(obj, actor)
        local recordId = obj.recordId
        if signs.morrowindSigns[recordId] then
            actor:sendEvent(
                "momw_sft_askForTeleport",
                { signId = recordId }
            )
        end
    end
)

return {
    eventHandlers = {
        momw_sft_doTeleport = doTeleport,
        momw_sft_followerTeleport = followerTeleport
    }
}
