require("scripts.signpost-fast-travel.checks")
local core = require('openmw.core')
local nearby = require('openmw.nearby')
local self = require('openmw.self')
local storage = require('openmw.storage')
local ui = require('openmw.ui')
local I = require("openmw.interfaces")

local signs = require("scripts.signpost-fast-travel.signs")
local targets = require("scripts.signpost-fast-travel.targets")
local teleportFollowers = require('scripts.signpost-fast-travel.teleportFollowers')

local MOD_ID = "SignpostFastTravel"
local interfaceVersion = 1
local L = core.l10n(MOD_ID)
local followerSettings = storage.globalSection('SettingsGlobalFollower' .. MOD_ID)
local travelSettings = storage.globalSection('SettingsGlobalTravel' .. MOD_ID)
local REVEAL_DISTANCE = 4096 -- Half a cell

local AttendMeInstalled = core.contentFiles.has("AttendMe.omwscripts")
local followers = {}
local foundCount = 0
local foundMax = 45
if core.contentFiles.has("TR_Mainland.esm") then
    foundMax = foundMax + 89
end
local foundSigns = {}
local foundTargets = {}
local foundAllSigns = false

I.Settings.registerPage {
    key = MOD_ID,
    l10n = MOD_ID,
    name = 'name',
    description = 'description'
}

-- Core logic
local function findSignposts()
    if foundAllSigns then return end
    if foundCount == foundMax then foundAllSigns = true end
    for _, thing in pairs(nearby.activators) do
        local recId = thing.recordId
        if (signs.morrowindSigns[recId] or signs.trSigns[recId])
            and (self.position - thing.position):length() < REVEAL_DISTANCE then
            local res = nearby.castRay(
                self.position,
                thing.position,
                { collisionType = nearby.COLLISION_TYPE.AnyPhysical }
            )
            if res.hitObject and res.hitObject.name == self.name and not foundSigns[thing.id] then
                local cell = thing.cell
                local targetKey = string.format("%sx%s", cell.gridX, cell.gridY)
                if not foundTargets[targetKey] then
                    --TODO: Search the cell for potential random points and store them
                    --TODO: Check nearby doors against the pathgrid, falling back to just pathgrid maybe
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
    local msg
    local cost = data.cost
    local hours = data.hours
    local hasCost = cost > 0
    local timePasses = hours > 0

    if data.notEnoughMoney then
        msg = L("notEnoughMoney")
    elseif data.noMoney then
        msg = L("noMoney")
    else
        local parts = 1
        local word = ""
        if hasCost or timePasses then parts = 2 end
        msg = L("announceWhere", { parts = parts, place = data.name })
        if timePasses then
            msg = msg .. " " ..  L("announceLength", { hours = hours })
            word = " and"
        end
        if hasCost then
            msg = msg .. word .. " " .. L("announceCost", { cost = cost })
        end
    end

    if travelSettings:get("showMsgs") then
        ui.showMessage(msg)
    end
end

local function askForTeleport(data)
    local target = targets[data.signId]
    if target then
        local targetCell = target.cell
        local targetName = targetCell.name
        if foundTargets[string.format("%sx%s", targetCell.x, targetCell.y)] then
            if targetCell.x == self.cell.gridX and targetCell.y == self.cell.gridY then
                -- No need to travel
                if travelSettings:get("showMsgs") then
                    --TODO: Some targets have very close by signs that should count as "there"
                    ui.showMessage(L("youreThere", { name = targetName }))
                end
                return
            end
            core.sendGlobalEvent(
                "momw_sft_doTeleport",
                {
                    actor = self,
                    cell = targetCell,
                    pos = target.pos
                }
            )
        else
            if travelSettings:get("showMsgs") then
                ui.showMessage(L("notBeen", { name = targetName }))
            end
        end
    end
end

-- From AttendMe
local function followerAway(e)
    teleportFollowers.followerAway(e.actor)
end

local function followerStatus(e)
    local index
    for i, follower in ipairs(followers) do
        if follower == e.actor then
            index = i
            break
        end
    end
    if e.status and not index then
        table.insert(followers, e.actor)
    end
    if not e.status and index then
        table.remove(followers, index)
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
end

-- Engine handlers
local function onLoad(data)
    followers = data.followers
    foundAllSigns = data.foundAllSigns
    foundSigns = data.foundSigns
    foundTargets = data.foundTargets
end

local function onSave()
    return {
        followers = followers,
        foundAllSigns = foundAllSigns,
        foundSigns = foundSigns,
        foundTargets = foundTargets
    }
end

local function onUpdate()
    findSignposts()
    if not AttendMeInstalled and followerSettings:get("teleportFollowers") then
        teleportFollowers.update(followers)
    end
end

-- Handoff to the engine
return {
    engineHandlers = {
        onLoad = onLoad,
        onSave = onSave,
        onUpdate = onUpdate
    },
    eventHandlers = {
        momw_sft_announceTeleport = announceTeleport,
        momw_sft_askForTeleport = askForTeleport,
        momw_sft_followerAway = followerAway,
        momw_sft_followerStatus = followerStatus
    },
    interfaceName = MOD_ID,
    interface = {
        version = interfaceVersion,
        findAll = findAll,
        forgetAll = forgetAll,
        p = p
    }
}
