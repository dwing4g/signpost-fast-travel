require("scripts.signpost-fast-travel.common")
local core = require('openmw.core')
local storage = require('openmw.storage')
local types = require('openmw.types')
local util = require('openmw.util')
local world = require('openmw.world')
local I = require("openmw.interfaces")
local MOD_ID = "SignpostFastTravel"

local followerSettings = storage.globalSection('SettingsGlobalFollower' .. MOD_ID)
local travelSettings = storage.globalSection('SettingsGlobalTravel' .. MOD_ID)

local haveOmwaddon = core.contentFiles.has("signpost-fast-travel.omwaddon")
if not haveOmwaddon then
	print("WARNING: The gold cost feature is disabled because 'signpost-fast-travel.omwaddon' is not enabled!")
end

-- Signs that should be ignored because they don't represent a valid location
local blackList = {
    -- Vanilla Morrowind
    ["active_sign_guartrail_01"] = true,
    -- Tamriel Rebuilt
    ["t_com_setmw_signwaydunakafel_01"] = true,
    ["t_com_setmw_signwaymarketstr_01"] = true,
}

-- Known "naughty" sign names that aren't exact matches to an exterior cell
local naughtyList = {
    -- Vanilla Morrowind
    ["Ald-ruhn (back road)"] = "Ald-ruhn",
    ["Ald-ruhn (main road)"] = "Ald-ruhn",
    ["Ald'ruhn"] = "Ald-ruhn",
    ["Buckmoth Fort (back road)"] = "Buckmoth Legion Fort",
    ["Buckmoth Fort (main road)"] = "Buckmoth Legion Fort",
    ["Maar gan (back road)"] = "Maar gan",
    ["Maar gan (main road)"] = "Maar gan",
    ["Pelagiad (back road)"] = "Pelagiad",
    ["Pelagiad (main road)"] = "Pelagiad",
    -- Tamriel Rebuilt
    ["Akamora (back road)"] = "Akamora",
    ["Firewatch via Aranyon Pass"] = "Firewatch",
    ["Tel Ouada via Aranyon Pass"] = "Tel Ouada",
    ["Ildrim (main road)"] = "Ildrim"
}

-- Internal list of usable signpost IDs, to be populated soon
local signs = {}

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
            description = "teleportFollowers_desc",
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
            description = "timePasses_desc",
            default = true,
            renderer = 'checkbox'
        },
        {
            key = 'goldPerUnit',
            name = "goldPerUnit_name",
            description = "goldPerUnit_desc",
            default = 5,
            renderer = 'number',
            min = 0,
        },
        {
            key = 'travelWhenCombat',
            name = "travelWhenCombat_name",
            description = "travelWhenCombat_desc",
            default = false,
            renderer = 'checkbox'
        },
        {
            key = 'showMsgs',
            name = "showMsgs_name",
            default = true,
            renderer = 'checkbox'
        },
        {
            key = "footstepVolume",
            name = "footstepVolume_name",
            description = "footstepVolume_desc",
            default = .1,
            renderer = "number",
            min = 0,
            max = 1
        },
        {
            key = 'menuCostsToken',
            name = "menuCostsToken_name",
            description = "menuCostsToken_desc",
            default = true,
            renderer = 'checkbox'
        },
        {
            key = 'menuShowUsage',
            name = "menuShowUsage_name",
            default = true,
            renderer = 'checkbox'
        },
        {
            key = 'scanInterval',
            name = "scanInterval_name",
            description = "scanInterval_desc",
            default = 2,
            renderer = 'number',
            max = 10,
            min = 1,
        },
        {
            key = 'initialDelay',
            name = "initialDelay_name",
            description = "initialDelay_desc",
            default = 120,
            renderer = 'number',
            max = 240,
            min = 1,
        },
        {
            key = 'maxPointsPerCell',
            name = "maxPointsPerCell_name",
            description = "maxPointsPerCell_desc",
            default = 100,
            renderer = 'number',
            max = 500,
            min = 1,
        },
        {
            key = 'maxTriesPerCell',
            name = "maxTriesPerCell_name",
            description = "maxTriesPerCell_desc",
            default = 10,
            renderer = 'number',
            max = 50,
            min = 1,
        }
    }
}

local function getDistance(src, dst)
    -- https://wiki.openmw.org/index.php?title=Research:Trading_and_Services#Travel_costs
    local d = math.sqrt((src.x - dst.x) * (src.x - dst.x)
        + (src.y - dst.y) * (src.y - dst.y))
    return math.ceil(d / core.getGMST("fTravelTimeMult"))
end

local function doTeleport(data)
    local cost
    local goldPerUnit = math.max(0, travelSettings:get("goldPerUnit"))
    local actorPos = data.actor.position
    local targetPos = data.pos
    local distance = getDistance(actorPos, targetPos)

    if distance > 1 then
        if haveOmwaddon and goldPerUnit > 0 then
            local playerMoney = types.Player.inventory(data.actor):find("gold_001")
            if playerMoney then
                cost = math.ceil(distance * goldPerUnit)
                if playerMoney.count < cost then
                    data.actor:sendEvent("momw_sft_announceTeleport", {cost = cost, notEnoughMoney = true})
                    return
                end
                playerMoney:remove(cost)
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
            --TODO: Timescale
            world.mwscript.getGlobalVariables(data.actor).gamehour = world.mwscript.getGlobalVariables(data.actor).gamehour + distance
        else
            distance = -1
        end
    else
        -- Very short trips are a free ride
        cost = -1
        distance = -1
    end

    if haveOmwaddon
        and data.token
        and travelSettings:get("menuCostsToken")
        and distance > 1
    then
        -- Consume one Travel Token if we can
        data.actor.type.inventory(data.actor):find("momw_sft_travel_token"):remove(1)
    end

    if travelSettings:get("showMsgs") then
        data.actor:sendEvent(
            "momw_sft_announceTeleport",
            {
                cost = cost,
                hours = distance,
                name = data.cell,
                token = data.token
            }
        )
    end

    data.actor:teleport(
        data.cell,
        util.vector3(targetPos.x, targetPos.y, targetPos.z),
        data.actor.rotation
    )
end

local function justTeleport(data)
    data.actor:teleport(
        data.cellName,
        util.vector3(data.targetPos.x, data.targetPos.y, data.targetPos.z),
        data.actor.rotation
    )
end

local function registerCombat(data)
    world.players[1]:sendEvent("momw_sft_playerRegisterCombat", {done=data.done, entity=data.entity})
end


-- From AttendMe
local function followerTeleport(e)
    if followerSettings:get('teleportFollowers') then
        local stat, err = pcall(function()
                e.actor:teleport(e.cellName, e.position)
        end)
        -- if not stat then
        --     print("WARNING: couldn't teleport the follower because they were already gone or teleported")
        --     print(err)
        -- end
    end
end

-- Interface
local function registerIds(idsTable, ids, quiet)
    if ids then
        for _, id in pairs(ids) do
            if blackList[id] then
                print(string.format("WARNING: Skipping blacklisted ID %s", id))
            else
                if not quiet then
                    print(string.format("Adding object via interface: %s", id))
                end
                idsTable[string.lower(id)] = true
            end
        end
    end
end

if core.contentFiles.has("Morrowind.esm") then
    print("Registering support for Morrowind.esm")
    registerIds(
        signs,
        {
            "active_sign_ald-ruhnB_01",
            "active_sign_ald-ruhnM_01",
            "active_sign_ald-ruhn_01",
            "active_sign_ald-ruhn_02",
            "active_sign_aldvelothi_01",
            "active_sign_balmora_01",
            "active_sign_balmora_02",
            "active_sign_buckmothB_01",
            "active_sign_buckmothM_01",
            "active_sign_buckmoth_01",
            "active_sign_buckmoth_02",
            "active_sign_cal_mine_02",
            "active_sign_caldera_01",
            "active_sign_caldera_02",
            "active_sign_dagon_fel_01",
            "active_sign_dagon_fell_01",
            "active_sign_ebonheart_01",
            "active_sign_ebonheart_02",
            "active_sign_ghostgate_01",
            "active_sign_gnaar _mok_01",
            "active_sign_gnaar_mok_02",
            "active_sign_gnisis_01",
            "active_sign_hla_oad_01",
            "active_sign_hla_oad_02",
            "active_sign_khuul_01",
            "active_sign_maar_ganB_02",
            "active_sign_maar_ganM_02",
            "active_sign_maar_gan_01",
            "active_sign_maar_gan_02",
            "active_sign_molag_mar_01",
            "active_sign_moonmoth_01",
            "active_sign_mt_a_01",
            "active_sign_mt_kand_01",
            "active_sign_pelagiadB_01",
            "active_sign_pelagiadM_01",
            "active_sign_pelagiad_01",
            "active_sign_pelagiad_02",
            "active_sign_seydaneen_01",
            "active_sign_seydaneen_02",
            "active_sign_suran_01",
            "active_sign_tel_vos_01",
            "active_sign_vivec_01",
            "active_sign_vivec_02",
            "active_sign_vos_01"
        },
        true
    )
end

if core.contentFiles.has("Tamriel_Data.esm") then
    print("Registering support for Tamriel_Data.esm")
    registerIds(
        signs,
        {
            "t_com_setmw_signwayaegondopo_01",
            "t_com_setmw_signwayboelighth_01",
            "t_com_setmw_signakamorab_01",
            "t_com_setmw_signakamorae_01",
            "t_com_setmw_signakamoram_01",
            "t_com_setmw_signakamoran_01",
            "t_com_setmw_signakamora_01",
            "t_com_setmw_signwayadurinoua_01",
            "t_com_setmw_signwayaimrah_01",
            "t_com_setmw_signwayalmalexia_01",
            "t_com_setmw_signwayalmalexia_02",
            "t_com_setmw_signwayalmasthrr_01",
            "t_com_setmw_signwayalmasthrr_02",
            "t_com_setmw_signwayaltbosara_01",
            "t_com_setmw_signwayaltbosara_02",
            "t_com_setmw_signwayammar_01",
            "t_com_setmw_signwayandothren_01",
            "t_com_setmw_signwayandrethis_01",
            "t_com_setmw_signwayarvud_01",
            "t_com_setmw_signwayashamul_01",
            "t_com_setmw_signwaybaloyra_01",
            "t_com_setmw_signwaybodrem_01",
            "t_com_setmw_signwaybosmora_01",
            "t_com_setmw_signwaydhorak_01",
            "t_com_setmw_signwaydarvon_01",
            "t_com_setmw_signwaydondril_01",
            "t_com_setmw_signwaydondril_02",
            "t_com_setmw_signwaydreynimsp_01",
            "t_com_setmw_signwaydreynim_01",
            "t_com_setmw_signwayenamorday_01",
            "t_com_setmw_signwayfelmsi_01",
            "t_com_setmw_signwayfirewata_01",
            "t_com_setmw_signwayfirewat_01",
            "t_com_setmw_signwayfortumber_01",
            "t_com_setmw_signwayfortwindm_01",
            "t_com_setmw_signwayfortancyl_01",
            "t_com_setmw_signwaygolmok_01",
            "t_com_setmw_signwaygorneb_01",
            "t_com_setmw_signwayhelnim_01",
            "t_com_setmw_signwayhlabulor_02",
            "t_com_setmw_signwayhlanoek_01",
            "t_com_setmw_signwayhlersis_01",
            "t_com_setmw_signwayidathren_01",
            "t_com_setmw_signwayidvano_01",
            "t_com_setmw_signwayindrn_01",
            "t_com_setmw_signwaykemelze_01",
            "t_com_setmw_signwayknockerspass",
            "t_com_setmw_signwaykogotel_01",
            "t_com_setmw_signwaykragenmar_01",
            "t_com_setmw_signwayllothanis_01",
            "t_com_setmw_signwayllothanis_02",
            "t_com_setmw_signwaymarog_01",
            "t_com_setmw_signwaymenaan_01",
            "t_com_setmw_signwaymeralag_01",
            "t_com_setmw_signwaynarsis_01",
            "t_com_setmw_signwaynavand_01",
            "t_com_setmw_signwaynecrom_01",
            "t_com_setmw_signwaynecrom_02",
            "t_com_setmw_signwayoldebonh_01",
            "t_com_setmw_signwayoldebonh_02",
            "t_com_setmw_signwayomaynis_01",
            "t_com_setmw_signwayoranpl_01",
            "t_com_setmw_signwayothmura_01",
            "t_com_setmw_signwayothrensis_01",
            "t_com_setmw_signwayquarryo_01",
            "t_com_setmw_signwayquarryp_01",
            "t_com_setmw_signwayranyonrue_01",
            "t_com_setmw_signwayranyonru_01",
            "t_com_setmw_signwayranyonru_02",
            "t_com_setmw_signwayrilsoan_01",
            "t_com_setmw_signwayroadyr_01",
            "t_com_setmw_signwaysailen_01",
            "t_com_setmw_signwaysarvanni_01",
            "t_com_setmw_signwayseitur_01",
            "t_com_setmw_signwayserynthul_01",
            "t_com_setmw_signwaytahvel_01",
            "t_com_setmw_signwaytear_01",
            "t_com_setmw_signwaytelouadaa_01",
            "t_com_setmw_signwaytelouada_01",
            "t_com_setmw_signwaytelmothri_01",
            "t_com_setmw_signwaytelmothri_02",
            "t_com_setmw_signwaytelmuthad_01",
            "t_com_setmw_signwayteyn_01",
            "t_com_setmw_signwaythalothe_01",
            "t_com_setmw_signwaytheinnbet_01",
            "t_com_setmw_signwaytomarilma_01",
            "t_com_setmw_signwayudhlerin_01",
            "t_com_setmw_signwayverarchen_01",
            "t_com_setmw_signwayvhul_01",
            "t_com_setmw_signwayvhul_02"
        },
        true
    )
end

if core.contentFiles.has("Sky_Main.esm") then
    print("Registering support for Sky_Main.esm")
    registerIds(
        signs,
        {
            "T_Com_SetSky_SignWayBeorinh_01",
            "T_Com_SetSky_SignWayDragonst_01",
            "T_Com_SetSky_SignWayFalkirst_01",
            "T_Com_SetSky_SignWayHaafing_01",
            "T_Com_SetSky_SignWayKarthg_01",
            "T_Com_SetSky_SignWayKarthw_01",
            "T_Com_SetSky_SignWayLainalt_01",
            "T_Com_SetSky_SignWayMarkarth_01"        },
        true
    )
end

-- Handoff to the engine
I.Activation.addHandlerForType(
    types.Activator,
    function(obj, actor)
        local recordId = obj.recordId
        if blackList[recordId] then return end
        if signs[recordId] then
            local name = types.Activator.record(obj).name
            if naughtyList[name] then
                name = naughtyList[name]
            end
            actor:sendEvent("momw_sft_askForTeleport", {signTarget = name})
        end
    end
)

return {
    eventHandlers = {
        momw_sft_doTeleport = doTeleport,
        momw_sft_justTeleport = justTeleport,
        momw_sft_followerTeleport = followerTeleport,
        momw_sft_globalRegisterCombat = registerCombat
    },
    interfaceName = MOD_ID,
    interface = {
        RegisterSigns = registerIds,
        version = 1
    }
}
