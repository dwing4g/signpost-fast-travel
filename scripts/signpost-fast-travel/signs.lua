return {
    -- grep Activator::active_sign_ Morrowind.d/Morrowind.yaml | grep -v _c_ | sort | uniq | awk -F:: '{ print $2 }' | sed "s|\":\$||g"
    morrowindSigns = {
        ["active_sign_khuul_01"] = true,
        ["active_sign_molag_mar_01"] = true,
        ["active_sign_mt_a_01"] = true,
        ["active_sign_mt_kand_01"] = true,
        ["active_sign_tel_vos_01"] = true,
        ["active_sign_vos_01"] = true,
        ["active_sign_ald-ruhnB_01"] = true,
        ["active_sign_ald-ruhnM_01"] = true,
        ["active_sign_ald-ruhn_01"] = true,
        ["active_sign_ald-ruhn_02"] = true,
        ["active_sign_aldvelothi_01"] = true,
        ["active_sign_balmora_01"] = true,
        ["active_sign_balmora_02"] = true,
        ["active_sign_buckmothB_01"] = true,
        ["active_sign_buckmothM_01"] = true,
        ["active_sign_buckmoth_01"] = true,
        ["active_sign_buckmoth_02"] = true,
        ["active_sign_cal_mine_02"] = true,
        ["active_sign_caldera_01"] = true,
        ["active_sign_caldera_02"] = true,
        ["active_sign_dagon_fel_01"] = true,
        ["active_sign_dagon_fell_01"] = true,
        ["active_sign_ebonheart_01"] = true,
        ["active_sign_ebonheart_02"] = true,
        ["active_sign_ghostgate_01"] = true,
        ["active_sign_gnaar _mok_01"] = true,
        ["active_sign_gnaar_mok_02"] = true,
        ["active_sign_gnisis_01"] = true,
        ["active_sign_guartrail_01"] = true,
        ["active_sign_hla_oad_01"] = true,
        ["active_sign_hla_oad_02"] = true,
        ["active_sign_maar_ganB_02"] = true,
        ["active_sign_maar_ganM_02"] = true,
        ["active_sign_maar_gan_01"] = true,
        ["active_sign_maar_gan_02"] = true,
        ["active_sign_moonmoth_01"] = true,
        ["active_sign_pelagiadB_01"] = true,
        ["active_sign_pelagiadM_01"] = true,
        ["active_sign_pelagiad_01"] = true,
        ["active_sign_pelagiad_02"] = true,
        ["active_sign_seydaneen_01"] = true,
        ["active_sign_seydaneen_02"] = true,
        ["active_sign_suran_01"] = true,
        ["active_sign_vivec_01"] = true,
        ["active_sign_vivec_02"] = true,

        -- Extra activators to help "find" locations
        ["ac_shrine_assarnibibi"] = true,
        ["ex_gg_gateswitch_01"] = true,
        ["ex_suran_roadmarker_01"] = true,

        -- Added by us since Mount Kand has no activators to speak of
        ["momw_sft_find_mount_kand"] = true
    },
    -- for o in (grep -i t_com_setmw_sign TR_Mainland.d/TR_Mainland.yaml | awk '{ print $2 }' | sort | uniq); echo "[\"$o\"] = true,"; end
    trSigns = {
        ["T_Com_SetMW_SignWayAegondoPo_01"] = true,
        ["T_Com_SetMW_SignWayBoeLightH_01"] = true,
        ["T_Com_SetMW_SignWayMarketStr_01"] = true,
        ["T_Com_SetMw_SignAkamoraB_01"] = true,
        ["T_Com_SetMw_SignAkamoraE_01"] = true,
        ["T_Com_SetMw_SignAkamoraM_01"] = true,
        ["T_Com_SetMw_SignAkamoraN_01"] = true,
        ["T_Com_SetMw_SignAkamora_01"] = true,
        ["T_Com_SetMw_SignWayAdurinOua_01"] = true,
        ["T_Com_SetMw_SignWayAimrah_01"] = true,
        ["T_Com_SetMw_SignWayAlmalexia_01"] = true,
        ["T_Com_SetMw_SignWayAlmalexia_02"] = true,
        ["T_Com_SetMw_SignWayAlmasthrr_01"] = true,
        ["T_Com_SetMw_SignWayAlmasthrr_02"] = true,
        ["T_Com_SetMw_SignWayAltbosara_01"] = true,
        ["T_Com_SetMw_SignWayAltbosara_02"] = true,
        ["T_Com_SetMw_SignWayAmmar_01"] = true,
        ["T_Com_SetMw_SignWayAndothren_01"] = true,
        ["T_Com_SetMw_SignWayArvud_01"] = true,
        ["T_Com_SetMw_SignWayAshamul_01"] = true,
        ["T_Com_SetMw_SignWayBalOyra_01"] = true,
        ["T_Com_SetMw_SignWayBodrem_01"] = true,
        ["T_Com_SetMw_SignWayBosmora_01"] = true,
        ["T_Com_SetMw_SignWayDHorak_01"] = true,
        ["T_Com_SetMw_SignWayDarvon_01"] = true,
        ["T_Com_SetMw_SignWayDondril_01"] = true,
        ["T_Com_SetMw_SignWayDondril_02"] = true,
        ["T_Com_SetMw_SignWayDreynimSp_01"] = true,
        ["T_Com_SetMw_SignWayDreynim_01"] = true,
        ["T_Com_SetMw_SignWayDunAkafel_01"] = true,
        ["T_Com_SetMw_SignWayEnamorDay_01"] = true,
        ["T_Com_SetMw_SignWayFelmsI_01"] = true,
        ["T_Com_SetMw_SignWayFirewatA_01"] = true,
        ["T_Com_SetMw_SignWayFirewat_01"] = true,
        ["T_Com_SetMw_SignWayFortUmber_01"] = true,
        ["T_Com_SetMw_SignWayFortWindm_01"] = true,
        ["T_Com_SetMw_SignWayFortancyl_01"] = true,
        ["T_Com_SetMw_SignWayGolmok_01"] = true,
        ["T_Com_SetMw_SignWayGorneB_01"] = true,
        ["T_Com_SetMw_SignWayHelnim_01"] = true,
        ["T_Com_SetMw_SignWayHlabulor_02"] = true,
        ["T_Com_SetMw_SignWayHlanoek_01"] = true,
        ["T_Com_SetMw_SignWayHlersis_01"] = true,
        ["T_Com_SetMw_SignWayIdvano_01"] = true,
        ["T_Com_SetMw_SignWayIndRn_01"] = true,
        ["T_Com_SetMw_SignWayKartur_01"] = true,
        ["T_Com_SetMw_SignWayKemelZe_01"] = true,
        ["T_Com_SetMw_SignWayKnockersPass"] = true,
        ["T_Com_SetMw_SignWayKogotel_01"] = true,
        ["T_Com_SetMw_SignWayKragenmar_01"] = true,
        ["T_Com_SetMw_SignWayLlothanis_01"] = true,
        ["T_Com_SetMw_SignWayLlothanis_02"] = true,
        ["T_Com_SetMw_SignWayMarog_01"] = true,
        ["T_Com_SetMw_SignWayMenaan_01"] = true,
        ["T_Com_SetMw_SignWayMeralag_01"] = true,
        ["T_Com_SetMw_SignWayNavAnd_01"] = true,
        ["T_Com_SetMw_SignWayNecrom_01"] = true,
        ["T_Com_SetMw_SignWayNecrom_02"] = true,
        ["T_Com_SetMw_SignWayOldEbonh_01"] = true,
        ["T_Com_SetMw_SignWayOldEbonh_02"] = true,
        ["T_Com_SetMw_SignWayOmaynis_01"] = true,
        ["T_Com_SetMw_SignWayOranPl_01"] = true,
        ["T_Com_SetMw_SignWayOthrensis_01"] = true,
        ["T_Com_SetMw_SignWayQuarryO_01"] = true,
        ["T_Com_SetMw_SignWayQuarryP_01"] = true,
        ["T_Com_SetMw_SignWayRanyonRuE_01"] = true,
        ["T_Com_SetMw_SignWayRanyonRu_01"] = true,
        ["T_Com_SetMw_SignWayRanyonRu_02"] = true,
        ["T_Com_SetMw_SignWayRilsoan_01"] = true,
        ["T_Com_SetMw_SignWayRoaDyr_01"] = true,
        ["T_Com_SetMw_SignWaySailen_01"] = true,
        ["T_Com_SetMw_SignWaySarvanni_01"] = true,
        ["T_Com_SetMw_SignWaySeitur_01"] = true,
        ["T_Com_SetMw_SignWaySeryn_01"] = true,
        ["T_Com_SetMw_SignWaySerynthul_01"] = true,
        ["T_Com_SetMw_SignWayTahvel_01"] = true,
        ["T_Com_SetMw_SignWayTear_01"] = true,
        ["T_Com_SetMw_SignWayTelOuadaA_01"] = true,
        ["T_Com_SetMw_SignWayTelOuada_01"] = true,
        ["T_Com_SetMw_SignWayTelmothri_01"] = true,
        ["T_Com_SetMw_SignWayTelmothri_02"] = true,
        ["T_Com_SetMw_SignWayTelmuthad_01"] = true,
        ["T_Com_SetMw_SignWayTeyn_01"] = true,
        ["T_Com_SetMw_SignWayThalothe_01"] = true,
        ["T_Com_SetMw_SignWayTheInnBet_01"] = true,
        ["T_Com_SetMw_SignWayTomarilMa_01"] = true,
        ["T_Com_SetMw_SignWayVerarchen_01"] = true,
        ["T_Com_SetMw_SignWayVhul_01"] = true,
        ["T_Com_SetMw_SignWayVhul_02"] = true,
    }
}
