require("scripts.signpost-fast-travel.checks")
local core = require('openmw.core')
local nearby = require('openmw.nearby')
local self = require('openmw.self')
local ui = require('openmw.ui')
local signs = require("scripts.signpost-fast-travel.signs")
local targets = require("scripts.signpost-fast-travel.targets")

local MOD_ID = "SignpostFastTravel"
local interfaceVersion = 1
local foundCount = 0
local foundMax = 45
if core.contentFiles.has("TR_Mainland.esm") then
    foundMax = foundMax + 89
end
local foundSigns = {}
local foundTargets = {}
local foundAllSigns = false

--TODO: Localize strings

-- Core logic
local function findSignposts()
    if foundAllSigns then return end
    if foundCount >= foundMax then foundAllSigns = true end
    for _, thing in pairs(nearby.activators) do
        local recId = thing.recordId
        --TODO: check for TR signs
        if signs.morrowindSigns[recId] or signs.trSigns[recId] then
            local res = nearby.castRay(
                self.position,
                thing.position,
                {
                    collisionType = nearby.COLLISION_TYPE.AnyPhysical,
                    radius = 1
                }
            )
            if res.hitObject and res.hitObject.name == self.name and not foundSigns[thing.id] then
                local cell = thing.cell
                local targetKey = string.format("%sx%s", cell.gridX, cell.gridY)
                if not foundTargets[targetKey] then
                    foundTargets[targetKey] = cell.name or "No Name"
                    foundCount = foundCount + 1
                end
                foundSigns[thing.id] = targetKey
            end
        end
    end
end

-- Events for the player
local function announceTeleport(data)
	ui.showMessage(string.format("Traveling to %s took %.0f hours", data.name, data.hours))
end

local function askForTeleport(data)
    local targetCell = targets[data.signId].cell
    local targetName = targetCell.name
    if foundTargets[string.format("%sx%s", targetCell.x, targetCell.y)] then
        if targetCell.x == self.cell.gridX and targetCell.y == self.cell.gridY then
            -- No need to travel
            ui.showMessage(string.format("You're in %s", targetName))
            return
        end
        core.sendGlobalEvent(
            "momw_sft_doTeleport",
            {
                actor = self,
                cell = targetCell,
                pos = targets[data.signId].pos
            }
        )
    else
        ui.showMessage(string.format("You haven't been to %s yet", targetName))
    end
end

-- Interface functions
local function findAll()
	-- For testing purposes only! Give the player all targets.
    -- Use it from the console like this:
    -- luap <ENTER>
    -- I.SignpostFastTravel.findAll() <ENTER>
    for _, target in pairs(targets) do
        local targetKey = string.format("%sx%s", target.cell.x, target.cell.y)
        foundTargets[targetKey] = target.cell.name or "No Name"
    end
    foundCount = foundMax
end
findAll()
local function forgetAll()
	-- For testing purposes only! Make the player "forget" all targets
    -- Use it from the console like this:
    -- luap <ENTER>
    -- I.SignpostFastTravel.forgetAll() <ENTER>
    foundTargets = {}
    foundCount = 0
end

local function p()
    -- This function is for seeing what targets are found throughout the
    -- game so that any missing travel points can be created as needed.
    -- Use it from the console like this:
    -- luap <ENTER>
    -- I.SignpostFastTravel.p() <ENTER>
    -- Results are printed to the console (F10)
    for target, name in pairs(foundTargets) do
        print(string.format("%s: %s", target, name))
    end
    foundCount = foundMax
end

-- Engine handlers
local function onLoad(data)
    foundAllSigns = data.foundAllSigns
	foundSigns = data.foundSigns
    foundTargets = data.foundTargets
end

local function onSave()
	return {
        foundAllSigns = foundAllSigns,
        foundSigns = foundSigns,
        foundTargets = foundTargets,
    }
end

local function onUpddate() findSignposts() end

-- Handoff to the engine
return {
    engineHandlers = {
        onLoad = onLoad,
        onSave = onSave,
        onUpdate = onUpddate
    },
    eventHandlers = {
        momw_sft_announceTeleport = announceTeleport,
        momw_sft_askForTeleport = askForTeleport
    },
    interfaceName = MOD_ID,
    interface = {
        version = interfaceVersion,
        findAll = findAll,
        forgetAll = forgetAll,
        p = p
    }
}
