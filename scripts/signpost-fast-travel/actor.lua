local AI = require("openmw.interfaces").AI
local core = require('openmw.core')
local self = require('openmw.self')

local combatRegistered = false

local function onLoad(data)
    if data then
        combatRegistered = data.combatRegistered
    end
end

local function onSave()
    return { combatRegistered = combatRegistered }
end

local function onUpdate()
    -- Am I still alive?
    local isDead = (self.object.type).stats.dynamic.health(self.object).current == 0
    if isDead and combatRegistered then
        core.sendGlobalEvent('momw_sft_globalRegisterCombat', {entity = self, done = true})
        combatRegistered = false
        return
    elseif isDead then
        return
    end

    -- Am I in combat?
    local curPkg = AI.getActivePackage(self)
    if curPkg and curPkg.type == "Combat" and not combatRegistered then
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
