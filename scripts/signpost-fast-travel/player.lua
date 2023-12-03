require("scripts.signpost-fast-travel.checks")
local ambient = require("openmw.ambient")
local async = require("openmw.async")
local core = require("openmw.core")
local nearby = require("openmw.nearby")
local self = require("openmw.self")
local storage = require("openmw.storage")
local types = require("openmw.types")
local ui = require("openmw.ui")
local util = require("openmw.util")
local I = require("openmw.interfaces")
local teleportFollowers = require("scripts.signpost-fast-travel.teleportFollowers")

local MOD_ID = "SignpostFastTravel"
local scriptVersion = 1
local L = core.l10n(MOD_ID)
local followerSettings = storage.globalSection("SettingsGlobalFollower" .. MOD_ID)
local travelSettings = storage.globalSection("SettingsGlobalTravel" .. MOD_ID)
local HALF_CELL = 4096
local AttendMeInstalled = core.contentFiles.has("AttendMe.omwscripts")
local followers = {}
local inCombat = {}
local visitedCells = {}

I.Settings.registerPage {
    key = MOD_ID,
    l10n = MOD_ID,
    name = "name",
    description = "description"
}

if AttendMeInstalled then
    print("Auto-disabling follower teleport features because Attend Me is also installed!")
end

-- Core logic
local function vec3ToStr(vec3)
    return string.format("%d_%d_%d", vec3.x, vec3.y, vec3.z)
end

local function strToVec3(str)
    local v = {}
    for s in string.gmatch(str, "([^_]+)") do table.insert(v, s) end
    return util.vector3(tonumber(v[1]), tonumber(v[2]), tonumber(v[3]))
end

local function scanCell()
    local c = self.cell

    -- Try to bail out if there's nothing to do
    if c.name == ""
        -- Special handling for Vivec city; the actual cell named "Vivec" has
        -- absolutely no good potential target points. The various "Vivec, *"
        -- cells, however, are each goldmines. Below we do further special
        -- handling to treat all of those simply as "Vivec" for internal data
        -- purposes.
        or c.name == "Vivec"
        or not c.isExterior
        or c:hasTag("QuasiExterior")
    then
        return
    end

    local count = 0
    local cellName = c.name
    local cellX = c.gridX
    local cellY = c.gridY
    local cellStr = string.format("%s_%s", cellX, cellY)
    local tries = 0

    -- Two was chosen because realistically any place with valid points will
    -- find _some_ on the first try. If by the second try there's nothing then
    -- the sensible thing is to bail out and just quit trying.
    local max_tries = 2

    -- More special handling for Vivec city; all exterior "Vivec, *" cells are "Vivec" internally
    if string.match(cellName, "Vivec, ") then
        cellName = "Vivec"
    end

    -- Retrieve stored data if there is any
    if visitedCells[cellName] == nil then
        -- Never visited, fresh data
        visitedCells[cellName] = {}
        visitedCells[cellName][cellStr] = {count=count, points = {}}
    elseif visitedCells[cellName][cellStr] then
        -- Previously visited named cell and X/Y grid
        count = visitedCells[cellName][cellStr].count
        tries = visitedCells[cellName][cellStr].tries
    else
        -- Previously visited named cell but different X/Y grid
        visitedCells[cellName][cellStr] = {count=count, points = {}}
    end

    -- Try to bail out again
    if visitedCells[cellName][cellStr].count > 0 or tries == max_tries then return end

    -- Use the player position as a starting point to search for random points from
    local navOptions = {includeFlags = nearby.NAVIGATOR_FLAGS.Walk}
    local navPos = nearby.findNearestNavMeshPosition(self.position, navOptions)

    -- Now try to find up to maxProceduralTargets points
    -- around a half cell radius and save them
    local points = {}

    -- Try to find a random walkable point above 0 (water level).
    -- Do it 100 times so we have a nice pool of good results. In Seyda Neen
    -- I can usually end up with 60-75 good, usable points out of 100.
    for _ = 1, 100 do
        local p = nearby.findRandomPointAroundCircle(navPos, HALF_CELL / 2, navOptions)
        if p.z > 0 then
            -- Only take points that are above water level..
            points[vec3ToStr(p)] = true
        end
    end

    -- Get a fresh count
    count = 0
    for _ in pairs(points) do count = count + 1 end

    -- Save the data
    visitedCells[cellName][cellStr].count = count
    visitedCells[cellName][cellStr].points = points
    visitedCells[cellName][cellStr].region = c.region
    visitedCells[cellName][cellStr].tries = tries + 1
end

local typeGmstMap = {
    [types.Armor.TYPE.Boots] = "iBootsWeight",
    [types.Armor.TYPE.Cuirass] = "iCuirassWeight",
    [types.Armor.TYPE.Greaves] = "iGreavesWeight",
    [types.Armor.TYPE.Helmet] = "iHelmWeight",
    [types.Armor.TYPE.LBracer] = "iGauntletWeight",
    [types.Armor.TYPE.LGauntlet] = "iGauntletWeight",
    [types.Armor.TYPE.LPauldron] = "iPauldronWeight",
    [types.Armor.TYPE.RBracer] = "iGauntletWeight",
    [types.Armor.TYPE.RGauntlet] = "iGauntletWeight",
    [types.Armor.TYPE.RPauldron] = "iPauldronWeight",
    [types.Armor.TYPE.Shield] = "iShieldWeight"
}

local function armorKind(obj)
    local iWeight = core.getGMST(typeGmstMap[obj.type.record(obj).type])
    local epsilon = 0.0005
    local weight = obj.type.record(obj).weight
    if weight <= iWeight * core.getGMST("fLightMaxMod") + epsilon then
        return "Light"
    elseif weight <= iWeight * core.getGMST("fMedMaxMod") + epsilon then
        return "Med"
    else
        return "Heavy"
    end
end

local function asyncFootSteps(count, volume)
    local delay = .25
    local increment = .3
    local params = {volume = volume}

    local equippedFeet = types.Player.equipment(self)[types.Player.EQUIPMENT_SLOT.Boots]
    local kind
    if equippedFeet then
        kind = armorKind(equippedFeet)
    else
        kind = "Bare"
    end

    for _ = 1, count do
        async:newSimulationTimer(
            delay,
            async:registerTimerCallback(
                "momw_sft_footstep_right",
                function()
                    ambient.playSound(string.format("Foot%sLeft", kind), params)
                end
        ))
        delay = delay + increment
        async:newSimulationTimer(
            delay,
            async:registerTimerCallback(
                "momw_sft_footstep_right",
                function()
                    ambient.playSound(string.format("Foot%sRight", kind), params)
                end
        ))
        delay = delay + increment
    end
end

-- Events for the player
local function announceTeleport(data)
    -- Maybe play footstep sounds
    local vol = travelSettings:get("footstepVolume")
    if vol > 0 then asyncFootSteps(2, vol) end

    -- Bail if messages are disabled
    if not travelSettings:get("showMsgs") then return end

    local msg
    local cost = data.cost
    local hours = data.hours

    if data.notEnoughMoney then
        msg = L("notEnoughMoney")
    elseif data.noMoney then
        msg = L("noMoney")
    else
        local word = ""
        msg = L("announceWhere", {place = data.name})
        if hours > 0 then
            msg = msg .. " " ..  L("announceLength", {hours = hours})
            word = " and"
        end
        if cost > 0 then
            msg = msg .. word .. " " .. L("announceCost", {cost = cost})
        end
    end

    ui.showMessage(msg)
end

local function randomFromPoints(p)
    return p[math.random(#p)]
end

local function askForTeleport(data)
    local currentCell = self.cell.name
    local targetCell = data.signTarget

    -- Already there; no travel needed
    -- Special handling for Vivec city
    if currentCell ~= "Vivec" and currentCell == targetCell then
        if travelSettings:get("showMsgs") then
            ui.showMessage(L("youreThere", {name = targetCell}))
        end
        return
    end

    local points = {}
    local target = visitedCells[targetCell]

    -- Not been there part one
    if not target then
        if travelSettings:get("showMsgs") then
            ui.showMessage(L("notBeen", {name = targetCell}))
        end
        return
    end

    -- Gather all points
    for _, info in pairs(target) do
        for point, _ in pairs(info.points) do
            table.insert(points, point)
        end
    end

    -- Not been there part two (maybe been there but we have no points)
    if not points then
        if travelSettings:get("showMsgs") then
            ui.showMessage(L("notBeen", {name = targetCell}))
        end
        return
    end

    -- But are we in combat?
    for _, actor in pairs(nearby.actors) do
        if inCombat[actor.id] then
            if travelSettings:get("showMsgs") then
                ui.showMessage(L("inCombat"))
            end
            return
        end
    end

    -- Do the travel
    -- https://wiki.openmw.org/index.php?title=Research:Trading_and_Services#Travel_costs
    local pos = strToVec3(randomFromPoints(points))
    local distance = (
        math.sqrt((self.position.x - pos.x) * (self.position.x - pos.x)
            + (self.position.y - pos.y) * (self.position.y - pos.y))
    )
    distance = math.ceil(distance / core.getGMST("fTravelTimeMult"))
    core.sendGlobalEvent(
        "momw_sft_doTeleport",
        {
            actor = self,
            cell = targetCell,
            distance = distance,
            pos = pos
        }
    )
end

local function registerCombat(data)
    if data.done then
        inCombat[data.entity.id] = nil
    else
        inCombat[data.entity.id] = true
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
local function forget(name)
    -- Make the player "forget" all targets a named cell.
    -- Use it from the console like this:
    -- luap <ENTER>
    -- I.SignpostFastTravel.Forget("Some Name") <ENTER>
    if visitedCells[name] then
        visitedCells[name] = nil
        local m = "You've forgotten all travel points for " .. name
        if travelSettings:get("showMsgs") then
            ui.showMessage(m)
        end
        print(m)
    else
        local m = "No travel points for " .. name
        if travelSettings:get("showMsgs") then
            ui.showMessage(m)
        end
        print(m)
    end
end

local function forgetAll()
    -- Make the player "forget" all targets in all cells.
    -- Use it from the console like this:
    -- luap <ENTER>
    -- I.SignpostFastTravel.ForgetAll() <ENTER>
    visitedCells = {}
    local m = "All travel points have been forgotten!"
    if travelSettings:get("showMsgs") then
        ui.showMessage(m)
    end
    print(m)
end

local function getPoint(name)
    -- Get a random point in the given named location.
    -- Use it in another mod like this:
    -- local balmoraRandPoint = I.SignpostFastTravel.GetPoint("Balmora")
    -- if balmoraRandPoint then
    --   ... do stuff
    local points = {}
    if visitedCells[name] then
        for _, data in pairs(visitedCells[name]) do
            for point, _ in pairs(data.points) do
                table.insert(points, point)
            end
        end
    end
    if #points > 0 then
        return strToVec3(randomFromPoints(points))
    end
end

local function p()
    -- This function is for seeing what targets are found throughout the
    -- game so that any missing travel points can be created as needed.
    -- Use it from the console like this:
    -- luap <ENTER>
    -- I.SignpostFastTravel.P() <ENTER>
    -- Results are printed to the console (F10)
    for name, cells in pairs(visitedCells) do
        print(string.format("==== Points for %s:", name))
        for _, data in pairs(cells) do
            for point, _ in pairs(data.points) do
                print(strToVec3(point))
            end
        end
    end
    print("===================")
end

local function showPoints(name)
    -- List generated travel points for the given named location.
    -- Use it from the console like this:
    -- luap <ENTER>
    -- I.SignpostFastTravel.ShowPoints("Some Name") <ENTER>
    -- Results are printed to the console (F10)
    if visitedCells[name] then
        print(string.format("==== Points for %s:", name))
        for _, data in pairs(visitedCells[name]) do
            for point, _ in pairs(data.points) do
                print(strToVec3(point))
            end
        end
        print("===================")
    else
        local m = "No travel points for " .. name
        if travelSettings:get("showMsgs") then
            ui.showMessage(m)
        end
        print(m)
    end
end

local function travelTo(name)
    -- Travel to a random point in the given named location.
    -- Use it from the console like this:
    -- luap <ENTER>
    -- I.SignpostFastTravel.TravelTo("Some Name") <ENTER>
    local points = {}
    if visitedCells[name] then
        for _, data in pairs(visitedCells[name]) do
            for point, _ in pairs(data.points) do
                table.insert(points, point)
            end
        end
    end

    if #points > 0 then
        local randPoint = strToVec3(randomFromPoints(points))
        core.sendGlobalEvent(
            "momw_sft_justTeleport",
            {
                actor = self,
                cellName = name,
                targetPos = randPoint
            }
        )
        local m = string.format("Console traveled to %s @ %s ", name, randPoint)
        if travelSettings:get("showMsgs") then
            ui.showMessage(m)
        end
        print(m)
    else
        local m = "No travel points for " .. name
        if travelSettings:get("showMsgs") then
            ui.showMessage(m)
        end
        print(m)
    end
end

-- Engine handlers
local function onLoad(data)
    followers = data.followers
    inCombat = data.inCombat
    visitedCells = data.visitedCells or {}
end

local function onSave()
    return {
        followers = followers,
        inCombat = inCombat,
        scriptVersion = scriptVersion,
        visitedCells = visitedCells
    }
end

local function onUpdate()
    scanCell()
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
        momw_sft_followerStatus = followerStatus,
        momw_sft_playerRegisterCombat = registerCombat
    },
    interfaceName = MOD_ID,
    interface = {
        version = 2,
        Forget = forget,
        ForgetAll = forgetAll,
        GetPoint = getPoint,
        P = p,
        ShowPoints = showPoints,
        TravelTo = travelTo
    }
}
