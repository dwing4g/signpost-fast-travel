require("scripts.signpost-fast-travel.checks")
local ambient = require("openmw.ambient")
local async = require("openmw.async")
local core = require("openmw.core")
local input = require("openmw.input")
local nearby = require("openmw.nearby")
local self = require("openmw.self")
local storage = require("openmw.storage")
local time = require("openmw_aux.time")
local types = require("openmw.types")
local ui = require("openmw.ui")
local util = require("openmw.util")
-- local aux_util = require("openmw_aux.util")
local I = require("openmw.interfaces")
local teleportFollowers = require("scripts.signpost-fast-travel.teleportFollowers")
local sftUI = require("scripts.signpost-fast-travel.ui")

local MOD_ID = "SignpostFastTravel"
local scriptVersion = 2
local L = core.l10n(MOD_ID)
local followerSettings = storage.globalSection("SettingsGlobalFollower" .. MOD_ID)
local travelSettings = storage.globalSection("SettingsGlobalTravel" .. MOD_ID)
local HALF_CELL = 4096
local AttendMeInstalled = core.contentFiles.has("AttendMe.omwscripts")
local followers = {}
local inCombat = {}
local visitedCells = {}
local travelMenu
local chargenDone = false
local chargenChecked = false

I.Settings.registerPage {
    key = MOD_ID,
    l10n = MOD_ID,
    name = "name",
    description = "description"
}

if AttendMeInstalled then
    print(L("attendMeInstalled"))
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
    -- print(aux_util.deepToString(visitedCells, 4))
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

    -- Don't try to generate points if the player is underwater; this would
    -- cause the 2 attempts we allow to be misspent on bunk origin points.
    -- Also, the player's feet should be on the ground too.
    if self.position.z < 1 or not types.Player.isOnGround(self) then return end

    local count = 0
    local cellName = c.name
    local cellX = c.gridX
    local cellY = c.gridY
    local cellStr = string.format("%s_%s", cellX, cellY)
    local tries = 0
    local points = {}

    -- More special handling for Vivec city; all exterior "Vivec, *" cells are "Vivec" internally
    if string.match(cellName, "Vivec, ") then
        cellName = "Vivec"
    end

    -- Retrieve stored data if there is any
    if visitedCells[cellName] == nil then
        -- Never visited, fresh data
        visitedCells[cellName] = {}
        visitedCells[cellName][cellStr] = {count=count, points = {}}
    elseif visitedCells[cellName][cellStr] ~= nil then
        -- Previously visited named cell and X/Y grid
        count = visitedCells[cellName][cellStr].count
        points = visitedCells[cellName][cellStr].points
        tries = visitedCells[cellName][cellStr].tries
    else
        -- Previously visited named cell but different X/Y grid
        visitedCells[cellName][cellStr] = {count=count, points = {}}
    end

    -- Try to bail out again
    if visitedCells[cellName][cellStr].count >= travelSettings:get("maxPointsPerCell")
        or tries >= travelSettings:get("maxTriesPerCell")
    then
        return
    end

    -- Use the player position as a starting point to search for random points from
    local navOptions = {includeFlags = nearby.NAVIGATOR_FLAGS.Walk}
    local navPos = nearby.findNearestNavMeshPosition(self.position, navOptions)

    -- Try to find a random walkable point above 0 (water level).
    local newCount = 0 + count
    for _ = 1, travelSettings:get("maxPointsPerCell") - count do
        local p = nearby.findRandomPointAroundCircle(navPos, HALF_CELL / 2, navOptions)
        if p.z > 0 then
            -- Only take points that are above water level..
            points[vec3ToStr(p)] = true
            newCount = newCount + 1
        end
    end

    -- Save the data
    visitedCells[cellName][cellStr].count = newCount
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

    if data.token and travelSettings:get("menuCostsToken") and data.hours > 1 then
        msg = msg .. ", " .. L("consumeToken")
    end

    -- Clean up
    if travelMenu then
        travelMenu:closeMenu()
        travelMenu = nil
    end

    ui.showMessage(msg)
end

local function randomFromPoints(p)
    return p[math.random(#p)]
end

local function playerInCombat()
    if travelSettings:get("travelWhenCombat") then return end
    for _, actor in pairs(nearby.actors) do
        if inCombat[actor.id] then
            if travelSettings:get("showMsgs") then
                ui.showMessage(L("inCombat"))
            end
            return true
        end
    end
    return false
end

local function askForTeleport(data)
    -- Should we do the travel UI?
    if #types.Player.inventory(self):findAll("momw_sft_travel_token") > 0
        or not travelSettings:get("menuCostsToken")
    then
        if playerInCombat() then return end
        travelMenu = sftUI.travelMenu(visitedCells)
        return
    end

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
    if playerInCombat() then return end

    -- Do the travel
    core.sendGlobalEvent(
        "momw_sft_doTeleport",
        {
            actor = self,
            cell = targetCell,
            pos = strToVec3(randomFromPoints(points))
        }
    )
end

local function registerCombat(data)
    if data.done then
        inCombat[data.entity.id] = nil
    else
        inCombat[data.entity.id] = data.entity
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
        local m = L("forgetFor") .. " " .. name
        if travelSettings:get("showMsgs") then
            ui.showMessage(m)
        end
        print(m)
    else
        local m = L("noneFor") .. " " .. name
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
    local m = L("forgetAll")
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
        print(string.format("==== " .. L("pointsFor") .. " %s:", name))
        for _, data in pairs(cells) do
            for point, _ in pairs(data.points) do
                print(strToVec3(point))
            end
        end
    end
    print("===================")
end

local function showInCombat()
    if next(inCombat) == nil then
        print("The player is not currently in combat")
        return
    end
    print("The player is in combat with the following actors:")
    for _, actor in pairs(inCombat) do
        print(actor)
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
        print(string.format("==== " .. L("pointsFor") .. " %s:", name))
        for _, data in pairs(visitedCells[name]) do
            for point, _ in pairs(data.points) do
                print(strToVec3(point))
            end
        end
        print("===================")
    else
        local m = L("noneFor") .. " " .. name
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
        local m = string.format(L("consoleTravel") .. " %s @ %s ", name, randPoint)
        if travelSettings:get("showMsgs") then
            ui.showMessage(m)
        end
        print(m)
    else
        local m = L("noneFor") .. " " .. name
        if travelSettings:get("showMsgs") then
            ui.showMessage(m)
        end
        print(m)
    end
end

-- Engine handlers
local function onControllerButtonPress(id)
    if travelMenu then
        if id == input.CONTROLLER_BUTTON.DPadUp then
            travelMenu:moveUp()
        elseif id == input.CONTROLLER_BUTTON.DPadLeft then
            travelMenu:movePrev()
        elseif id == input.CONTROLLER_BUTTON.DPadDown then
            travelMenu:moveDown()
        elseif id == input.CONTROLLER_BUTTON.DPadRight then
            travelMenu:moveNext()
        elseif id == input.CONTROLLER_BUTTON.A then
            travelMenu:choose()
        elseif id == input.CONTROLLER_BUTTON.Start or id == input.CONTROLLER_BUTTON.B then
            travelMenu:closeMenu()
            travelMenu = nil
        end
    end
end

local function onKeyPress(k)
    if travelMenu then
        if k.code == input.KEY.W or k.code == input.KEY.UpArrow then
            travelMenu:moveUp()
        elseif k.code == input.KEY.A or k.code == input.KEY.LeftArrow then
            travelMenu:movePrev()
        elseif k.code == input.KEY.S or k.code == input.KEY.DownArrow then
            travelMenu:moveDown()
        elseif k.code == input.KEY.D or k.code == input.KEY.RightArrow then
            travelMenu:moveNext()
        elseif k.code == input.KEY.E or k.code == input.KEY.Enter then
            travelMenu:choose()
        elseif k.code == input.KEY.Escape or k.code == input.KEY.Q then
            travelMenu:closeMenu()
            travelMenu = nil
        end
    end
end

local function onLoad(data)
    chargenDone = data.chargenDone or false
    chargenChecked = data.chargenChecked or false
    followers = data.followers
    inCombat = data.inCombat or {}
    visitedCells = data.visitedCells or {}
end

local function onSave()
    return {
        chargenChecked = chargenChecked,
        chargenDone = chargenDone,
        followers = followers,
        inCombat = inCombat,
        scriptVersion = scriptVersion,
        visitedCells = visitedCells
    }
end

local function beginScanningCallback()
	return async:registerTimerCallback(
        "beginScanning",
        function()
            chargenDone = true
    end)
end
local bscb = beginScanningCallback()

local function chargenCheck()
    -- Has the player been instructed to see Caius yet?
	if types.Player.quests(self)["A1_1_FindSpymaster"].stage >= 1 and not chargenChecked then
        chargenChecked = true
        async:newSimulationTimer(travelSettings:get("initialDelay"), bscb)
    end
end

local function runScan()
	return time.runRepeatedly(
        function()
            if not chargenDone then
                chargenCheck()
                return
            end
            scanCell()
            if not AttendMeInstalled and followerSettings:get("teleportFollowers") then
                teleportFollowers.update(followers)
            end
        end,
        travelSettings:get("scanInterval")
    )
end
local stopScan = runScan()

local function restartScan(_, key)
	if key == "scanInterval" then
        stopScan()
        stopScan = runScan()
    end
end
travelSettings:subscribe(async:callback(restartScan))

local function UiModeChanged(data)
    if not data.newMode and travelMenu then
        travelMenu:closeMenu()
        travelMenu = nil
    end
end

-- Handoff to the engine
return {
    engineHandlers = {
        onControllerButtonPress = onControllerButtonPress,
        onKeyPress = onKeyPress,
        onLoad = onLoad,
        onSave = onSave
    },
    eventHandlers = {
        momw_sft_announceTeleport = announceTeleport,
        momw_sft_askForTeleport = askForTeleport,
        momw_sft_followerAway = followerAway,
        momw_sft_followerStatus = followerStatus,
        momw_sft_playerRegisterCombat = registerCombat,
        UiModeChanged = UiModeChanged
    },
    interfaceName = MOD_ID,
    interface = {
        version = 2,
        Forget = forget,
        ForgetAll = forgetAll,
        GetPoint = getPoint,
        P = p,
        ShowInCombat = showInCombat,
        ShowPoints = showPoints,
        TravelTo = travelTo
    }
}
