require("scripts.signpost-fast-travel.checks")
local core = require('openmw.core')
local storage = require('openmw.storage')
local types = require('openmw.types')
local util = require('openmw.util')
local world = require('openmw.world')
local I = require("openmw.interfaces")
local signs = require("scripts.signpost-fast-travel.signs")
local MOD_ID = "SignpostFastTravel"

local followerSettings = storage.globalSection('SettingsGlobalFollower' .. MOD_ID)
local travelSettings = storage.globalSection('SettingsGlobalTravel' .. MOD_ID)

I.Settings.registerGroup {
    key = 'SettingsGlobalFollower' .. MOD_ID,
    page = MOD_ID,
    l10n = MOD_ID,
    name = "followerSettingsTitle",
    permanentStorage = false,
    settings = {
        {
            key = 'teleportFollowers',
            name = "teleportFollowers_name",
            default = true,
            renderer = 'checkbox'
        }
    }
}

I.Settings.registerGroup {
    key = 'SettingsGlobalTravel' .. MOD_ID,
    page = MOD_ID,
    l10n = MOD_ID,
    name = "travelSettingsTitle",
    permanentStorage = false,
    settings = {
        {
            key = 'timePasses',
            name = "timePasses_name",
            default = true,
            renderer = 'checkbox'
        },
        {
            key = 'goldPerUnit',
            name = "goldPerUnit_name",
            default = 5,
            renderer = 'number'
        },
        {
            key = 'showMsgs',
            name = "showMsgs_name",
            default = true,
            renderer = 'checkbox'
        }
    }
}

local function doTeleport(data)
    local cost
    local goldPerUnit = math.max(0, travelSettings:get("goldPerUnit"))
    local playerPos = data.actor.position
    local targetPos = data.pos
    -- https://wiki.openmw.org/index.php?title=Research:Trading_and_Services#Travel_costs
    local distance = (
        math.sqrt((playerPos.x - targetPos.x) * (playerPos.x - targetPos.x)
            + (playerPos.y - targetPos.y) * (playerPos.y - targetPos.y))
    )
    distance = math.ceil(distance / core.getGMST("fTravelTimeMult"))

    if goldPerUnit > 0 then
        local playerMoney = types.Player.inventory(data.actor):find("gold_001")
        if playerMoney then
            cost = math.ceil(distance * goldPerUnit)
            if playerMoney.count < cost then
                data.actor:sendEvent(
                    "momw_sft_announceTeleport",
                    {
                        cost = cost,
                        notEnoughMoney = true
                    }
                )
                return
            end
            world.mwscript.getGlobalScript("momw_sft_scriptbridge").variables.cost = cost
        else
            data.actor:sendEvent(
                "momw_sft_announceTeleport",
                { noMoney = true }
            )
            return
        end
    else
        cost = -1
    end

    if travelSettings:get("timePasses") then
        --TODO: Eventually just modify the gamehour global since that got added
        world.mwscript.getGlobalScript("momw_sft_scriptbridge").variables.distance = distance
    else
        distance = -1
    end

    if travelSettings:get("showMsgs") then
        data.actor:sendEvent(
            "momw_sft_announceTeleport",
            {
                cost = cost,
                hours = distance,
                name = data.cell.name
            }
        )
    end

    data.actor:teleport(
        data.cell.name,
        util.vector3(targetPos.x, targetPos.y, targetPos.z),
        util.transform.rotateZ(targetPos.rotZ)
    )
end

-- From AttendMe
local function followerTeleport(e)
    if followerSettings:get('teleportFollowers') then
        e.actor:teleport(e.cellName, e.position)
    end
end

-- Handoff to the engine
I.Activation.addHandlerForType(
    types.Activator,
    function(obj, actor)
        local recordId = obj.recordId
        if signs.morrowindSigns[recordId] or signs.trSigns[recordId] then
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
