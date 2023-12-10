require("scripts.signpost-fast-travel.checks")
local AI = require("openmw.interfaces").AI
local core = require('openmw.core')
local self = require('openmw.self')

local amDead = false
local combatRegistered = false

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
    if amDead then return end
    -- Am I still alive?
    local isDead = (self.object.type).isDead(self.object)
    if isDead and combatRegistered then
        core.sendGlobalEvent('momw_sft_globalRegisterCombat', {entity = self, done = true})
        combatRegistered = false
        return
    elseif isDead then
        -- One last attempt at signalling that I am dead.
        core.sendGlobalEvent('momw_sft_globalRegisterCombat', {entity = self, done = true})
        amDead = true
        return
    end

    -- Am I in combat?
    local curPkg = AI.getActivePackage(self)
    if curPkg and curPkg.type == "Combat" and not combatRegistered then
        if curPkg.target.recordId ~= "player" then return end
        core.sendGlobalEvent('momw_sft_globalRegisterCombat', {entity = self})
        combatRegistered = true
    elseif curPkg and not curPkg.type == "Combat" and combatRegistered then
        core.sendGlobalEvent('momw_sft_globalRegisterCombat', {entity = self, done = true})
        combatRegistered = false
    end
end

return {
    engineHandlers = {
        onLoad = onLoad,
        onSave = onSave,
        onUpdate = onUpdate
    }
}
