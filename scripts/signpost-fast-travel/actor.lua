local AI = require("openmw.interfaces").AI
local core = require('openmw.core')
local self = require('openmw.self')
local common = require("scripts.signpost-fast-travel.common")

local amDead = false
local combatRegistered = false

local function deRegisterCombat()
    combatRegistered = false
    core.sendGlobalEvent('momw_sft_globalRegisterCombat', {entity = self, done = true})
end

local function onInactive()
    deRegisterCombat()
end

local function onLoad(data)
    if data then
        amDead = data.amDead
        combatRegistered = data.combatRegistered
    end
end

local function onSave()
    return {
        amDead = amDead,
        combatRegistered = combatRegistered
    }
end

local function onUpdate()
    -- Bail if I'm already dead
    if amDead then return end

    -- Am I in combat?
    local curPkg = AI.getActivePackage(self)
    if curPkg and curPkg.target and curPkg.type == "Combat" and not combatRegistered then
        if curPkg.target.recordId ~= "player" then return end
        -- The Combat AI package can be active on an actor when combat itself
        -- is not active. Try to account for that with this distance check.
        if (curPkg.target.position - self.position):length() >= common.COMBAT_END_DISTANCE then
            return
        end
        core.sendGlobalEvent('momw_sft_globalRegisterCombat', {entity = self})
        combatRegistered = true
    elseif curPkg and not curPkg.type == "Combat" and combatRegistered then
        deRegisterCombat()
    end
end

local function Died()
    amDead = true
    if combatRegistered then
        deRegisterCombat()
    end
end

local function distanceEndCombat()
    combatRegistered = false
end

return {
    engineHandlers = {
        onInactive = onInactive,
        onLoad = onLoad,
        onSave = onSave,
        onUpdate = onUpdate
    },
    eventHandlers = {
        Died = Died,
        momw_sft_distanceEndCombat = distanceEndCombat
    }
}
