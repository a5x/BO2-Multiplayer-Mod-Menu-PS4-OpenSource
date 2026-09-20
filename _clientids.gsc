/*
    Unlock Menu - standalone for Black Ops II (PS4 port)
    Replaces: maps/mp/gametypes/_clientids.gsc
    Compile + inject with BO2 PS4 Tool (GSC Compiler -> Compile & Inject),
    target maps/mp/gametypes/_clientids.gsc. Inject in the lobby, then start the match.

    No Jiggy, no other menu needed. Every player gets the menu (so a joined
    retail console can unlock its own account without being host).

    Controls:  R1 + SQUARE  open / close        (frag + use)
               D-Pad Up/Dn  scroll             (action slot 1 / 2)
               Square       select             (use)
               CIRCLE       back / close       (stance)
*/

init()
{
    level.um_open_hint = true;

    level.achievements = array(
        "SP_COMPLETE_ANGOLA", "SP_COMPLETE_MONSOON", "SP_COMPLETE_AFGHANISTAN",
        "SP_COMPLETE_NICARAGUA", "SP_COMPLETE_PAKISTAN", "SP_COMPLETE_KARMA",
        "SP_COMPLETE_PANAMA", "SP_COMPLETE_YEMEN", "SP_COMPLETE_BLACKOUT",
        "SP_COMPLETE_LA", "SP_COMPLETE_HAITI", "SP_VETERAN_PAST",
        "SP_VETERAN_FUTURE", "SP_ONE_CHALLENGE", "SP_ALL_CHALLENGES_IN_LEVEL",
        "SP_ALL_CHALLENGES_IN_GAME", "SP_RTS_DOCKSIDE", "SP_RTS_AFGHANISTAN",
        "SP_RTS_DRONE", "SP_RTS_CARRIER", "SP_RTS_PAKISTAN", "SP_RTS_SOCOTRA",
        "SP_STORY_MASON_LIVES", "SP_STORY_HARPER_FACE", "SP_STORY_FARID_DUEL",
        "SP_STORY_OBAMA_SURVIVES", "SP_STORY_LINK_CIA", "SP_STORY_HARPER_LIVES",
        "SP_STORY_MENENDEZ_CAPTURED", "SP_MISC_ALL_INTEL", "SP_STORY_CHLOE_LIVES",
        "SP_STORY_99PERCENT", "SP_MISC_WEAPONS", "SP_BACK_TO_FUTURE",
        "SP_MISC_10K_SCORE_ALL", "MP_MISC_1", "MP_MISC_2", "MP_MISC_3",
        "MP_MISC_4", "MP_MISC_5", "ZM_DONT_FIRE_UNTIL_YOU_SEE",
        "ZM_THE_LIGHTS_OF_THEIR_EYES", "ZM_DANCE_ON_MY_GRAVE",
        "ZM_STANDARD_EQUIPMENT_MAY_VARY", "ZM_YOU_HAVE_NO_POWER_OVER_ME",
        "ZM_I_DONT_THINK_THEY_EXIST", "ZM_FUEL_EFFICIENT", "ZM_HAPPY_HOUR",
        "ZM_TRANSIT_SIDEQUEST", "ZM_UNDEAD_MANS_PARTY_BUS",
        "ZM_DLC1_HIGHRISE_SIDEQUEST", "ZM_DLC1_VERTIGONER",
        "ZM_DLC1_I_SEE_LIVE_PEOPLE", "ZM_DLC1_SLIPPERY_WHEN_UNDEAD",
        "ZM_DLC1_FACING_THE_DRAGON", "ZM_DLC1_IM_MY_OWN_BEST_FRIEND",
        "ZM_DLC1_MAD_WITHOUT_POWER", "ZM_DLC1_POLYARMORY", "ZM_DLC1_SHAFTED",
        "ZM_DLC1_MONKEY_SEE_MONKEY_DOOM", "ZM_DLC2_PRISON_SIDEQUEST",
        "ZM_DLC2_FEED_THE_BEAST", "ZM_DLC2_MAKING_THE_ROUNDS",
        "ZM_DLC2_ACID_DRIP", "ZM_DLC2_FULL_LOCKDOWN", "ZM_DLC2_A_BURST_OF_FLAVOR",
        "ZM_DLC2_PARANORMAL_PROGRESS", "ZM_DLC2_GG_BRIDGE",
        "ZM_DLC2_TRAPPED_IN_TIME", "ZM_DLC2_POP_GOES_THE_WEASEL",
        "ZM_DLC3_WHEN_THE_REVOLUTION_COMES", "ZM_DLC3_FSIRT_AGAINST_THE_WALL",
        "ZM_DLC3_MAZED_AND_CONFUSED", "ZM_DLC3_REVISIONIST_HISTORIAN",
        "ZM_DLC3_AWAKEN_THE_GAZEBO", "ZM_DLC3_CANDYGRAM",
        "ZM_DLC3_DEATH_FROM_BELOW", "ZM_DLC3_IM_YOUR_HUCKLEBERRY",
        "ZM_DLC3_ECTOPLASMIC_RESIDUE", "ZM_DLC3_BURIED_SIDEQUEST",
        "ZM_DLC4_TOMB_SIDEQUEST",
        "ZM_DLC4_ALL_YOUR_BASE",
        "ZM_DLC4_PLAYING_WITH_POWER",
        "ZM_DLC4_OVERACHIEVER",
        "ZM_DLC4_NOT_A_GOLD_DIGGER",
        "ZM_DLC4_KUNG_FU_GRIP",
        "ZM_DLC4_IM_ON_A_TANK",
        "ZM_DLC4_SAVING_THE_DAY_ALL_DAY",
        "ZM_DLC4_MASTER_OF_DISGUISE",
        "ZM_DLC4_MASTER_WIZARD"
);
    level thread um_rankedmode();
    level thread um_onplayerconnect();
}

um_onplayerconnect()
{
    for (;;)
    {
        level waittill("connected", player);
        player thread um_onplayerspawned();
    }
}

um_onplayerspawned()
{
    self endon("disconnect");
    for (;;)
    {
        self waittill("spawned_player");

        // Keep player controls enabled during the BO2 spawn countdown.
        // This also allows the custom menu input thread to receive controller input.
        self freezeControls(false);

        if (isdefined(self.um_started))
            continue;
        self.um_started = true;
        self thread um_start();
    }
}

um_start()
{
    self endon("disconnect");
    self.um_open = false;
    self.um_cur = "main";
    self.um_cursor = 0;
    self.um_scroll = 0;
    self.um_busy = undefined;
    self um_buildmenus();
    self iprintln("^2Unlock Menu ^7loaded - press ^5R1 + SQUARE ^7to open");
    self thread um_controls_hud();
    self thread um_monitor();
    self thread um_cleanup();
}

um_cleanup()
{
    self waittill("disconnect");
    self um_destroy();
}

// ================================================================= menu data
um_addmenu(name, parent, title)
{
    self.um_text[name] = [];
    self.um_func[name] = [];
    self.um_a[name] = [];
    self.um_b[name] = [];
    self.um_parent[name] = parent;
    self.um_title[name] = title;
}

um_add(menu, text, func, a, b)
{
    i = self.um_text[menu].size;
    self.um_text[menu][i] = text;
    self.um_func[menu][i] = func;
    self.um_a[menu][i] = a;
    self.um_b[menu][i] = b;
}

um_sub(menu, text, sub)
{
    self um_add(menu, text, ::um_gosub, sub, undefined);
}

um_gosub(a, b)
{
    if (!isdefined(a))
        return;

    self.um_cur = a;
    self.um_cursor = 0;
    self.um_scroll = 0;

    if (a == "medalnum")
    {
        self.um_medal_digits = [];
        self.um_medal_digits[0] = 0;
        self.um_medal_digits[1] = 0;
        self.um_medal_digits[2] = 0;
        self.um_medal_digits[3] = 0;
        self.um_medal_digits[4] = 0;
        self.um_medal_digits[5] = 0;
        self.um_medal_digits[6] = 1;
        self.um_medal_digits[7] = 3;
        self.um_medal_digits[8] = 3;
        self.um_medal_digits[9] = 7;
        self.um_medal_digit_cursor = 6;
    }

    if (a == "gamemodenum")
    {
        self.um_medal_digits = [];
        self.um_medal_digits[0] = 0;
        self.um_medal_digits[1] = 0;
        self.um_medal_digits[2] = 0;
        self.um_medal_digits[3] = 0;
        self.um_medal_digits[4] = 6;
        self.um_medal_digits[5] = 6;
        self.um_medal_digits[6] = 7;
        self.um_medal_digits[7] = 6;
        self.um_medal_digits[8] = 6;
        self.um_medal_digits[9] = 7;
        self.um_medal_digit_cursor = 4;
    }

    self um_draw();
}

um_back(a, b)
{
    p = self.um_parent[self.um_cur];
    if (!isdefined(p))
    {
        self um_close();
        return;
    }
    self.um_cur = p;
    self.um_cursor = 0;
    self.um_scroll = 0;
    self um_draw();
}

// ================================================================= menu layout
um_buildmenus()
{
    self um_addmenu("main", undefined, "Unlock Menu V3.5");
    self um_addmenu("rank", "main", "^5Rank & Prestige");
    self um_addmenu("prest", "rank", "^5Choose Prestige - SAVE DONT WORK");
    self um_addmenu("lvl", "rank", "^5Choose Level");
    self um_addmenu("accountstats", "main", "^5Account Stats");
    self um_addmenu("readthis", "accountstats", "^5READ THIS!");
    self um_addmenu("stats", "accountstats", "^5Modify Account Stats");
    self um_addmenu("statsnum", "stats", "^5Select Number Stats");
    self um_addmenu("weap", "accountstats", "^5Modify Weapons Stats");
    self um_addmenu("weaponnum", "weap", "^5Select Number Stats");
    self um_addmenu("medal", "accountstats", "^5Modify Medals Stats");
    self um_addmenu("medalnum", "medal", "^5Select Number Stats");
    self um_addmenu("gamemode", "accountstats", "^6Game Modes");
    self um_addmenu("gamemodenum", "gamemode", "^5Select Number Stats");
    self um_addmenu("equipnum", "accountstats", "^5Select Number Stats");
    self um_addmenu("streaknum", "accountstats", "^5Select Number Stats");
    self um_addmenu("accountunlocks", "main", "^5Account Unlocks");
    self um_addmenu("camo", "accountunlocks", "^5Unlock Camos");
    self um_addmenu("save", "main", "^3Save / Profile");
    self um_addmenu("credits", "main", "^5Credits");

    self um_sub("main", "Rank & Prestige", "rank");
    self um_sub("main", "Account Stats", "accountstats");
    self um_sub("main", "Account Unlocks", "accountunlocks");
    self um_sub("main", "Save / Profile", "save");
    self um_sub("main", "Credits", "credits");
    self um_add("main", "Close", ::um_closeopt, undefined, undefined);

    // ---- account stats
    self um_sub("accountstats", "^5Modify Account Stats", "stats");
    self um_sub("accountstats", "^5Modify Weapons Stats", "weap");
    self um_sub("accountstats", "^5Modify Medals Stats", "medal");
    self um_sub("accountstats", "^6Game Modes", "gamemode");
    self um_add("accountstats", "^6Modify Equipments", ::um_open_equipment_editor, "everything", 667667);
    self um_add("accountstats", "^6Modify Scorestreaks", ::um_open_scorestreak_editor, "everything", 667667);
    self um_add("accountstats", "^6MAX ALL WEAPON RANK", ::um_maxweaponrank, undefined, undefined);
    self um_sub("accountstats", "^5READ THIS!", "readthis");
    self um_add("accountstats", "^1Back", ::um_back, undefined, undefined);

    // ---- account stats info
    self um_add("readthis", "PLEASE BE RANK 55 and unlocked all weapons", ::um_readthis_nop, undefined, undefined);
    self um_add("readthis", "Equipments and scorestreaks for full stats edit", ::um_readthis_nop, undefined, undefined);
    self um_add("readthis", "^1Back", ::um_back, undefined, undefined);

    // ---- Game Modes stats
    self um_sub("gamemode", "^6Modify Game Modes Stats", "gamemodenum");
    self um_add("gamemode", "^1Back", ::um_back, undefined, undefined);

    // ---- account unlocks
    self um_sub("accountunlocks", "^5Unlock Camos", "camo");
    self um_add("accountunlocks", "^2UNLOCK ALL", ::um_unlockall, undefined, undefined);
    self um_add("accountunlocks", "^2Unlock PSN Trophies 100 per cent", ::um_unlock_achievements, undefined, undefined);
    self um_add("accountunlocks", "^1Back", ::um_back, undefined, undefined);

    // ---- credits
    self um_add("credits", "Menu base by Medo", ::um_creditnoop, undefined, undefined);
    self um_add("credits", "Unlock camo code @nicop6281", ::um_creditnoop, undefined, undefined);
    self um_add("credits", "Rank UP FIX @jlzerty", ::um_creditnoop, undefined, undefined);
    self um_add("credits", "Stats Medals FIX @jlzerty", ::um_creditnoop, undefined, undefined);
    self um_add("credits", "Equipments stats by @jlzerty", ::um_creditnoop, undefined, undefined);
    self um_add("credits", "Scorestreaks stats by @jlzerty", ::um_creditnoop, undefined, undefined);
    self um_add("credits", "Game Modes stats by @jlzerty", ::um_creditnoop, undefined, undefined);
    self um_add("credits", "PSN Trophies code by jiggymenu, whiteshadow bo3 plat unlock code", ::um_creditnoop, undefined, undefined);
    self um_add("credits", "UNLOCK ALL code from Abyss Project", ::um_creditnoop, undefined, undefined);
    self um_add("credits", "UNLOCK ALL FIX for old acc @jlzerty", ::um_creditnoop, undefined, undefined);
    self um_add("credits", "^1Back", ::um_back, undefined, undefined);

    // ---- rank
    self um_add("rank", "^2UP RANK", ::um_uprank, undefined, undefined);
    self um_sub("rank", "^5Choose Prestige - SAVE DONT WORK", "prest");
    self um_add("rank", "^3Save & End Game ^7(keep changes)", ::um_saveend, undefined, undefined);
    self um_add("rank", "^1Back", ::um_back, undefined, undefined);

    // ---- prestige
    for (p = 0; p <= 15; p++)
    {
        if (p == 15)
            self um_add("prest", "Prestige Master (15)", ::um_prestige, p, undefined);
        else
            self um_add("prest", "Prestige " + p, ::um_prestige, p, undefined);
    }
    self um_add("prest", "^1Back", ::um_back, undefined, undefined);

    self um_add("lvl", "Level 1", ::um_level, 1, undefined);
    for (l = 5; l <= 55; l += 5)
        self um_add("lvl", "Level " + l, ::um_level, l, undefined);
    self um_add("lvl", "^1Back", ::um_back, undefined, undefined);

    // ---- stats
    self um_add("stats", "^1Kills", ::um_open_accountstats_editor, "kills", 667667);
    self um_add("stats", "^2Wins", ::um_open_accountstats_editor, "wins", 667667);
    self um_add("stats", "^1Deaths", ::um_open_accountstats_editor, "deaths", 67);
    self um_add("stats", "^1Losses", ::um_open_accountstats_editor, "losses", 67);
    self um_add("stats", "^3Assists", ::um_open_accountstats_editor, "assists", 667667);
    self um_add("stats", "^3Score", ::um_open_accountstats_editor, "score", 667667667);
    self um_add("stats", "^1Headshots", ::um_open_accountstats_editor, "headshots", 667667);
    self um_add("stats", "Time Played +7 days", ::um_pstat, "time_played_total", 604800);
    self um_add("stats", "Time Played +30 days", ::um_pstat, "time_played_total", 2592000);
    self um_add("stats", "^1Back", ::um_back, undefined, undefined);
    self um_add("statsnum", "^1Back", ::um_back, undefined, undefined);

    // ---- equipment stats
    self um_add("equip", "^2ALL Equipments: everything", ::um_open_equipment_editor, "everything", 667667);
    self um_add("equip", "Satchel Charge: Used", ::um_open_equipment_editor, "satchel_used", 667667);
    self um_add("equip", "Satchel Charge: Kills", ::um_open_equipment_editor, "satchel_kills", 667667);
    self um_add("equip", "Frag Grenade: Used", ::um_open_equipment_editor, "frag_used", 667667);
    self um_add("equip", "Frag Grenade: Kills", ::um_open_equipment_editor, "frag_kills", 667667);
    self um_add("equip", "Hatchet: Used", ::um_open_equipment_editor, "hatchet_used", 667667);
    self um_add("equip", "Hatchet: Kills", ::um_open_equipment_editor, "hatchet_kills", 667667);
    self um_add("equip", "Sticky Grenade: Used", ::um_open_equipment_editor, "sticky_used", 667667);
    self um_add("equip", "Sticky Grenade: Kills", ::um_open_equipment_editor, "sticky_kills", 667667);
    self um_add("equip", "Bouncing Betty: Used", ::um_open_equipment_editor, "betty_used", 667667);
    self um_add("equip", "Bouncing Betty: Kills", ::um_open_equipment_editor, "betty_kills", 667667);
    self um_add("equip", "Claymore: Used", ::um_open_equipment_editor, "claymore_used", 667667);
    self um_add("equip", "Claymore: Kills", ::um_open_equipment_editor, "claymore_kills", 667667);
    self um_add("equip", "Willy Pete: Used", ::um_open_equipment_editor, "willy_used", 667667);
    self um_add("equip", "Concussion: Used", ::um_open_equipment_editor, "concussion_used", 667667);
    self um_add("equip", "EMP Grenade: Used", ::um_open_equipment_editor, "emp_used", 667667);
    self um_add("equip", "Sensor Grenade: Used", ::um_open_equipment_editor, "sensor_used", 667667);
    self um_add("equip", "Flash Grenade: Used", ::um_open_equipment_editor, "flash_used", 667667);
    self um_add("equip", "Proximity: Used", ::um_open_equipment_editor, "proximity_used", 667667);
    self um_add("equip", "PDA Hack: Used", ::um_open_equipment_editor, "pda_used", 667667);
    self um_add("equip", "Tactical Insertion: Used", ::um_open_equipment_editor, "tac_insert_used", 667667);
    self um_add("equip", "Trophy System: Used", ::um_open_equipment_editor, "trophy_used", 667667);
    self um_add("equip", "Capture objective in smoke", ::um_open_equipment_editor, "capture_smoke", 667667);
    self um_add("equip", "Kill concussed enemy", ::um_open_equipment_editor, "kill_concussed", 667667);
    self um_add("equip", "Destroy equipment with EMP", ::um_open_equipment_editor, "destroy_emp", 667667);
    self um_add("equip", "Kill enemy revealed by Sensor", ::um_open_equipment_editor, "kill_sensor", 667667);
    self um_add("equip", "Kill flashed enemy", ::um_open_equipment_editor, "kill_flashed", 667667);
    self um_add("equip", "Kill shocked enemy", ::um_open_equipment_editor, "kill_shocked", 667667);
    self um_add("equip", "Hack enemy target", ::um_open_equipment_editor, "hack_target", 667667);
    self um_add("equip", "Kill after Tac Insert", ::um_open_equipment_editor, "kill_tac_insert", 667667);
    self um_add("equip", "Destroy explosive with Trophy", ::um_open_equipment_editor, "destroy_trophy", 667667);
    self um_add("equip", "^1Back", ::um_back, undefined, undefined);
    self um_add("equipnum", "^1Back", ::um_back, undefined, undefined);

    // ---- scorestreak stats
    self um_add("streak", "^2ALL Scorestreaks: everything", ::um_open_scorestreak_editor, "everything", 667667);
    self um_add("streak", "UAV: Used", ::um_open_scorestreak_editor, "radar_used", 667667);
    self um_add("streak", "UAV: Assists", ::um_open_scorestreak_editor, "radar_assists", 667667);
    self um_add("streak", "Dragonfire: Used", ::um_open_scorestreak_editor, "dragonfire_used", 667667);
    self um_add("streak", "Dragonfire: Kills", ::um_open_scorestreak_editor, "dragonfire_kills", 667667);
    self um_add("streak", "Hunter Killer: Used", ::um_open_scorestreak_editor, "hunter_used", 667667);
    self um_add("streak", "Hunter Killer: Kills", ::um_open_scorestreak_editor, "hunter_kills", 667667);
    self um_add("streak", "RC-XD: Used", ::um_open_scorestreak_editor, "rcxd_used", 667667);
    self um_add("streak", "RC-XD: Kills", ::um_open_scorestreak_editor, "rcxd_kills", 667667);
    self um_add("streak", "Lightning Strike: Used", ::um_open_scorestreak_editor, "lightning_used", 667667);
    self um_add("streak", "Lightning Strike: Kills", ::um_open_scorestreak_editor, "lightning_kills", 667667);
    self um_add("streak", "Hunter Killer Drone: Used", ::um_open_scorestreak_editor, "missile_drone_used", 667667);
    self um_add("streak", "Hunter Killer Drone: Kills", ::um_open_scorestreak_editor, "missile_drone_kills", 667667);
    self um_add("streak", "Lodestar: Used", ::um_open_scorestreak_editor, "lodestar_used", 667667);
    self um_add("streak", "Lodestar: Kills", ::um_open_scorestreak_editor, "lodestar_kills", 667667);
    self um_add("streak", "Hellstorm Missile: Used", ::um_open_scorestreak_editor, "hellstorm_used", 667667);
    self um_add("streak", "Hellstorm Missile: Kills", ::um_open_scorestreak_editor, "hellstorm_kills", 667667);
    self um_add("streak", "EMP Systems: Used", ::um_open_scorestreak_editor, "emp_streak_used", 667667);
    self um_add("streak", "EMP Systems: Assists", ::um_open_scorestreak_editor, "emp_streak_assists", 667667);
    self um_add("streak", "Warthog: Used", ::um_open_scorestreak_editor, "warthog_used", 667667);
    self um_add("streak", "Warthog: Kills", ::um_open_scorestreak_editor, "warthog_kills", 667667);
    self um_add("streak", "K9 Unit: Used", ::um_open_scorestreak_editor, "dogs_used", 667667);
    self um_add("streak", "K9 Unit: Kills", ::um_open_scorestreak_editor, "dogs_kills", 667667);
    self um_add("streak", "Care Package: Used", ::um_open_scorestreak_editor, "supplydrop_used", 667667);
    self um_add("streak", "Care Package: Kills", ::um_open_scorestreak_editor, "supplydrop_kills", 667667);
    self um_add("streak", "VTOL Warship: Used", ::um_open_scorestreak_editor, "vtol_used", 667667);
    self um_add("streak", "VTOL Warship: Kills", ::um_open_scorestreak_editor, "vtol_kills", 667667);
    self um_add("streak", "Sentry Gun: Used", ::um_open_scorestreak_editor, "sentry_used", 667667);
    self um_add("streak", "Sentry Gun: Kills", ::um_open_scorestreak_editor, "sentry_kills", 667667);
    self um_add("streak", "Guardian: Used", ::um_open_scorestreak_editor, "guardian_used", 667667);
    self um_add("streak", "Guardian: Kills", ::um_open_scorestreak_editor, "guardian_kills", 667667);
    self um_add("streak", "Swarm: Used", ::um_open_scorestreak_editor, "swarm_used", 667667);
    self um_add("streak", "Swarm: Kills", ::um_open_scorestreak_editor, "swarm_kills", 667667);
    self um_add("streak", "A.G.R.: Used", ::um_open_scorestreak_editor, "agr_used", 667667);
    self um_add("streak", "A.G.R.: Kills", ::um_open_scorestreak_editor, "agr_kills", 667667);
    self um_add("streak", "Counter-UAV: Used", ::um_open_scorestreak_editor, "counter_used", 667667);
    self um_add("streak", "Counter-UAV: Assists", ::um_open_scorestreak_editor, "counter_assists", 667667);
    self um_add("streak", "Death Machine: Used", ::um_open_scorestreak_editor, "death_machine_used", 667667);
    self um_add("streak", "Death Machine: Kills", ::um_open_scorestreak_editor, "death_machine_kills", 667667);
    self um_add("streak", "War Machine: Used", ::um_open_scorestreak_editor, "war_machine_used", 667667);
    self um_add("streak", "War Machine: Kills", ::um_open_scorestreak_editor, "war_machine_kills", 667667);
    self um_add("streak", "Stealth Chopper: Used", ::um_open_scorestreak_editor, "stealth_used", 667667);
    self um_add("streak", "Stealth Chopper: Kills", ::um_open_scorestreak_editor, "stealth_kills", 667667);
    self um_add("streak", "Orbital VSAT: Used", ::um_open_scorestreak_editor, "vsat_used", 667667);
    self um_add("streak", "Orbital VSAT: Assists", ::um_open_scorestreak_editor, "vsat_assists", 667667);
    self um_add("streak", "Escort Drone: Used", ::um_open_scorestreak_editor, "escort_used", 667667);
    self um_add("streak", "Escort Drone: Kills", ::um_open_scorestreak_editor, "escort_kills", 667667);
    self um_add("streak", "^1Back", ::um_back, undefined, undefined);
    self um_add("streaknum", "^1Back", ::um_back, undefined, undefined);

    // ---- weapon stats (all 41 weapons)
    self um_add("weap", "^2ALL weapons: everything", ::um_open_weapon_editor, "everything", 667667);
    self um_add("weap", "ALL weapons: kills", ::um_open_weapon_editor, "kills_all", 1000000);
    self um_add("weap", "ALL weapons: headshots", ::um_open_weapon_editor, "headshots_all", 1000000);
    self um_add("weap", "ALL weapons: hits", ::um_open_weapon_editor, "hits_all", 1000000);
    self um_add("weap", "ALL weapons: shots", ::um_open_weapon_editor, "shots_all", 1000000);
    self um_add("weap", "ALL weapons: kills", ::um_open_weapon_editor, "kills_all", 100000);
    self um_add("weap", "Current weapon: kills", ::um_open_weapon_editor, "kills_current", 1000000);
    self um_add("weap", "Current weapon: headshots", ::um_open_weapon_editor, "headshots_current", 1000000);
    self um_add("weap", "^1Back", ::um_back, undefined, undefined);

    // ---- camos (camo challenges are weapon stats, so big weapon stats complete them)
    self um_add("camo", "^2All weapons", ::um_camos, "all", undefined);
    self um_add("camo", "Assault Rifles", ::um_camos, "ar", undefined);
    self um_add("camo", "SMGs", ::um_camos, "smg", undefined);
    self um_add("camo", "LMGs", ::um_camos, "lmg", undefined);
    self um_add("camo", "Snipers", ::um_camos, "sniper", undefined);
    self um_add("camo", "Shotguns", ::um_camos, "sg", undefined);
    self um_add("camo", "Pistols", ::um_camos, "pistol", undefined);
    self um_add("camo", "Launchers & Specials", ::um_camos, "other", undefined);
    self um_add("camo", "^1Back", ::um_back, undefined, undefined);

    // ---- medals
    self um_sub("medal", "^2Other Medals", "medalnum");
    self um_add("medalnum", "^1Back", ::um_back, undefined, undefined);
    self um_add("medal", "^1Back", ::um_back, undefined, undefined);

    // ---- save / profile
    self um_add("save", "^3Save & End Game", ::um_saveend, undefined, undefined);
    self um_add("save", "^5Check saved profile", ::um_verify, undefined, undefined);
    self um_add("save", "Re-apply Ranked Mode", ::um_rankedopt, undefined, undefined);
    self um_add("save", "^1Back", ::um_back, undefined, undefined);

    // ---- everyone
    self um_add("all", "^2EVERYTHING (all players)", ::um_forall, "everything", undefined);
    self um_add("all", "Prestige Master + 55 (all)", ::um_forall, "master", undefined);
    self um_add("all", "Kills +1,000,000 (all)", ::um_forall, "kills", undefined);
    self um_add("all", "Wins +1,000,000 (all)", ::um_forall, "wins", undefined);
    self um_add("all", "ALL weapons 1M (all)", ::um_forall, "weapons", undefined);
    self um_add("all", "Camos - all weapons (all)", ::um_forall, "camos", undefined);
    self um_add("all", "All medals (all)", ::um_forall, "medals", undefined);
    self um_add("all", "^1Back", ::um_back, undefined, undefined);
}

// ================================================================= input
um_monitor()
{
    self endon("disconnect");
    for (;;)
    {
        if (!self.um_open)
        {
            if (self fragbuttonpressed() && self usebuttonpressed())
            {
                self um_openmenu();
                wait 0.4;
            }
            wait 0.05;
            continue;
        }

        if (self.um_cur == "medalnum" || self.um_cur == "gamemodenum" || self.um_cur == "weaponnum" || self.um_cur == "statsnum" || self.um_cur == "equipnum" || self.um_cur == "streaknum")
        {
            if (self actionslotthreebuttonpressed())
            {
                self.um_medal_digit_cursor--;
                if (self.um_medal_digit_cursor < 0)
                    self.um_medal_digit_cursor = 9;
                self um_draw();
                wait 0.18;
            }
            else if (self actionslotfourbuttonpressed())
            {
                self.um_medal_digit_cursor++;
                if (self.um_medal_digit_cursor > 9)
                    self.um_medal_digit_cursor = 0;
                self um_draw();
                wait 0.18;
            }
            else if (self actionslotonebuttonpressed())
            {
                self um_medal_digit_change(1);
                self um_draw();
                wait 0.18;
            }
            else if (self actionslottwobuttonpressed())
            {
                self um_medal_digit_change(-1);
                self um_draw();
                wait 0.18;
            }
            else if (self usebuttonpressed())
            {
                if (self.um_cur == "gamemodenum")
                    self thread um_apply_gamemodestats_editor();
                else if (self.um_cur == "weaponnum")
                    self thread um_apply_weaponstats_editor();
                else if (self.um_cur == "statsnum")
                    self thread um_apply_accountstats_editor();
                else if (self.um_cur == "equipnum")
                    self thread um_apply_equipment_editor();
                else if (self.um_cur == "streaknum")
                    self thread um_apply_scorestreak_editor();
                else
                    self thread um_apply_othermedals();
                wait 0.3;
            }
            else if (self stancebuttonpressed())
            {
                self um_back();
                wait 0.3;
            }

            wait 0.05;
            continue;
        }

        if (self actionslotonebuttonpressed())
        {
            self.um_cursor--;
            self um_fixcursor();
            self um_draw();
            wait 0.18;
        }
        else if (self actionslottwobuttonpressed())
        {
            self.um_cursor++;
            self um_fixcursor();
            self um_draw();
            wait 0.18;
        }
        else if (self usebuttonpressed())
        {
            self um_select();
            wait 0.3;
        }
        else if (self stancebuttonpressed())
        {
            self um_back();
            wait 0.3;
        }
        wait 0.05;
    }
}

um_fixcursor()
{
    n = self.um_text[self.um_cur].size;
    if (self.um_cursor < 0)
        self.um_cursor = n - 1;
    if (self.um_cursor >= n)
        self.um_cursor = 0;
    if (self.um_cursor < self.um_scroll)
        self.um_scroll = self.um_cursor;
    if (self.um_cursor > self.um_scroll + 8)
        self.um_scroll = self.um_cursor - 8;
}

um_select()
{
    m = self.um_cur;
    i = self.um_cursor;
    if (i < 0 || i >= self.um_func[m].size)
        return;
    f = self.um_func[m][i];
    if (!isdefined(f))
        return;
    self thread [[f]](self.um_a[m][i], self.um_b[m][i]);
}

um_openmenu()
{
    self.um_open = true;
    self.um_cur = "main";
    self.um_cursor = 0;
    self.um_scroll = 0;
    self um_draw();
}

um_close()
{
    self.um_open = false;
    self um_destroy();
}

um_closeopt(a, b)
{
    self um_close();
}

// ================================================================= permanent controls HUD
um_controls_hud()
{
    self endon("disconnect");

    self.um_controls_bg = newclienthudelem(self);
    self.um_controls_bg.x = 48;
    self.um_controls_bg.y = 300;
    self.um_controls_bg.alignx = "left";
    self.um_controls_bg.aligny = "top";
    self.um_controls_bg.horzalign = "user_left";
    self.um_controls_bg.vertalign = "user_top";
    self.um_controls_bg setshader("white", 226, 88);
    self.um_controls_bg.color = (0.035, 0.035, 0.04);
    self.um_controls_bg.alpha = 0.94;
    self.um_controls_bg.sort = 999;
    self.um_controls_bg.foreground = true;
    self.um_controls_bg.hidewheninmenu = false;

    self.um_controls_sep = newclienthudelem(self);
    self.um_controls_sep.x = 58;
    self.um_controls_sep.y = 313;
    self.um_controls_sep.alignx = "left";
    self.um_controls_sep.aligny = "top";
    self.um_controls_sep.horzalign = "user_left";
    self.um_controls_sep.vertalign = "user_top";
    self.um_controls_sep setshader("white", 206, 1);
    self.um_controls_sep.color = (1, 1, 1);
    self.um_controls_sep.alpha = 0.45;
    self.um_controls_sep.sort = 1001;
    self.um_controls_sep.foreground = true;
    self.um_controls_sep.hidewheninmenu = false;

    self.um_controls_title = self um_newtext(306, 1.05);
    self.um_controls_title.x = 161;
    self.um_controls_title.alignx = "center";
    self.um_controls_title.color = (1, 1, 1);
    self.um_controls_title settext("CONTROLS");
    self.um_controls_title.sort = 1002;
    self.um_controls_title.hidewheninmenu = false;

    self.um_controls_text = [];

    self.um_controls_text[0] = self um_newtext(318, 1.05);
    self.um_controls_text[0] settext("[{+frag}] + [{+usereload}] Open Menu");

    self.um_controls_text[1] = self um_newtext(337, 1.05);
    self.um_controls_text[1] settext("UP [{+actionslot 1}] / DOWN [{+actionslot 2}]");

    self.um_controls_text[2] = self um_newtext(356, 1.05);
    self.um_controls_text[2] settext(" [{+usereload}]  SELECT");

    self.um_controls_text[3] = self um_newtext(375, 1.05);
    self.um_controls_text[3] settext("[{+stance}]  BACK");

    for (i = 0; i < self.um_controls_text.size; i++)
    {
        self.um_controls_text[i].color = (0.88, 0.88, 0.88);
        self.um_controls_text[i].sort = 1002;
        self.um_controls_text[i].hidewheninmenu = false;
    }
}

// ================================================================= drawing
um_destroy()
{
    self notify("um_rainbow_stop");
    if (isdefined(self.um_bg))
        self.um_bg destroy();
    if (isdefined(self.um_panel))
        self.um_panel destroy();
    if (isdefined(self.um_sel))
        self.um_sel destroy();
    if (isdefined(self.um_ttl))
        self.um_ttl destroy();
    if (isdefined(self.um_sep))
        self.um_sep destroy();
    if (isdefined(self.um_line))
    {
        for (i = 0; i < self.um_line.size; i++)
        {
            if (isdefined(self.um_line[i]))
                self.um_line[i] destroy();
        }
    }
    self.um_bg = undefined;
    self.um_panel = undefined;
    self.um_sel = undefined;
    self.um_ttl = undefined;
    self.um_sep = undefined;
    self.um_line = [];
}

um_newtext(y, scale)
{
    e = newclienthudelem(self);
    e.x = 58;
    e.y = y;
    e.alignx = "left";
    e.aligny = "top";
    e.horzalign = "user_left";
    e.vertalign = "user_top";
    e.fontscale = scale;
    e.alpha = 1;
    e.sort = 1000;
    e.foreground = true;
    e.hidewheninmenu = true;
    return e;
}

um_rainbow_title()
{
    self endon("disconnect");
    self endon("um_rainbow_stop");

    // Smooth rainbow cycle for the centered menu title.
    for (;;)
    {
        // Red -> Yellow
        for (t = 0; t <= 1; t += 0.025)
        {
            self.um_ttl.color = (1, t, 0);
            wait 0.025;
        }

        // Yellow -> Green
        for (t = 1; t >= 0; t -= 0.025)
        {
            self.um_ttl.color = (t, 1, 0);
            wait 0.025;
        }

        // Green -> Cyan
        for (t = 0; t <= 1; t += 0.025)
        {
            self.um_ttl.color = (0, 1, t);
            wait 0.025;
        }

        // Cyan -> Blue
        for (t = 1; t >= 0; t -= 0.025)
        {
            self.um_ttl.color = (0, t, 1);
            wait 0.025;
        }

        // Blue -> Magenta
        for (t = 0; t <= 1; t += 0.025)
        {
            self.um_ttl.color = (t, 0, 1);
            wait 0.025;
        }

        // Magenta -> Red
        for (t = 1; t >= 0; t -= 0.025)
        {
            self.um_ttl.color = (1, 0, t);
            wait 0.025;
        }
    }
}

um_draw_medal_editor()
{
    if (!isdefined(self.um_medal_digits))
        return;

    info = self um_newtext(145, 1.35);
    info.x = 161;
    info.alignx = "center";
    info.color = (1, 1, 1);
    if (self.um_cur == "gamemodenum")
        info settext("GAME MODE STATS VALUE");
    else if (self.um_cur == "weaponnum")
        info settext("WEAPON STATS VALUE");
    else if (self.um_cur == "statsnum")
        info settext("ACCOUNT STATS VALUE");
    else if (self.um_cur == "equipnum")
        info settext("EQUIPMENT STATS VALUE");
    else if (self.um_cur == "streaknum")
        info settext("SCORESTREAK STATS VALUE");
    else
        info settext("MEDAL STATS VALUE");
    info.sort = 1002;
    self.um_line[self.um_line.size] = info;

    for (i = 0; i < 10; i++)
    {
        e = self um_newtext(167, 1.65);
        e.x = 76 + (i * 19);
        e.alignx = "center";

        if (i == self.um_medal_digit_cursor)
            e.color = (0.35, 0.9, 1);
        else
            e.color = (0.88, 0.88, 0.88);

        e settext("" + self.um_medal_digits[i]);
        e.sort = 1002;
        self.um_line[self.um_line.size] = e;
    }

    self.um_sel = newclienthudelem(self);
    self.um_sel.x = 66 + (self.um_medal_digit_cursor * 19);
    self.um_sel.y = 165;
    self.um_sel.alignx = "left";
    self.um_sel.aligny = "top";
    self.um_sel.horzalign = "user_left";
    self.um_sel.vertalign = "user_top";
    self.um_sel setshader("white", 20, 28);
    self.um_sel.color = (1, 1, 1);
    self.um_sel.alpha = 0.12;
    self.um_sel.sort = 1001;
    self.um_sel.foreground = true;
    self.um_sel.hidewheninmenu = true;

    max_text = self um_newtext(208, 1.35);
    max_text.x = 161;
    max_text.alignx = "center";
    max_text.color = (1, 1, 1);
    max_text settext("MAX: 1,000,000,000\nVALIDATE [{+usereload}]    [{+stance}]  BACK");
    max_text.sort = 1002;
    self.um_line[self.um_line.size] = max_text;

    controls_left = self um_newtext(231, 0.88);
    controls_left.x = 161;
    controls_left.alignx = "center";
    controls_left.color = (0.72, 0.72, 0.72);
    controls_left settext("[{+actionslot 3}] / [{+actionslot 4}]  MOVE DIGIT");
    controls_left.sort = 1002;
    self.um_line[self.um_line.size] = controls_left;

    controls_value = self um_newtext(248, 0.88);
    controls_value.x = 161;
    controls_value.alignx = "center";
    controls_value.color = (0.72, 0.72, 0.72);
    controls_value settext("[{+actionslot 1}] / [{+actionslot 2}]  CHANGE VALUE");
    controls_value.sort = 1002;
    self.um_line[self.um_line.size] = controls_value;

}

um_draw()
{
    self um_destroy();
    if (!self.um_open)
        return;

    // ---- compact modern panel: white border + dark grey inner panel
    self.um_bg = newclienthudelem(self);
    self.um_bg.x = 48;
    self.um_bg.y = 92;
    self.um_bg.alignx = "left";
    self.um_bg.aligny = "top";
    self.um_bg.horzalign = "user_left";
    self.um_bg.vertalign = "user_top";
    self.um_bg setshader("white", 226, 204);
    self.um_bg.color = (1, 1, 1);
    self.um_bg.alpha = 0.92;
    self.um_bg.sort = 999;
    self.um_bg.foreground = true;
    self.um_bg.hidewheninmenu = true;

    self.um_panel = newclienthudelem(self);
    self.um_panel.x = 50;
    self.um_panel.y = 94;
    self.um_panel.alignx = "left";
    self.um_panel.aligny = "top";
    self.um_panel.horzalign = "user_left";
    self.um_panel.vertalign = "user_top";
    self.um_panel setshader("white", 222, 200);
    self.um_panel.color = (0.035, 0.035, 0.04);
    self.um_panel.alpha = 0.94;
    self.um_panel.sort = 1000;
    self.um_panel.foreground = true;
    self.um_panel.hidewheninmenu = true;

    self.um_ttl = self um_newtext(104, 1.35);
    self.um_ttl.x = 161;
    self.um_ttl.alignx = "center";
    self.um_ttl.color = (1, 1, 1);
    self.um_ttl settext(self.um_title[self.um_cur]);
    self.um_ttl.sort = 1002;
    if (self.um_cur == "main")
        self thread um_rainbow_title();

    self.um_sep = newclienthudelem(self);
    self.um_sep.x = 58;
    self.um_sep.y = 128;
    self.um_sep.alignx = "left";
    self.um_sep.aligny = "top";
    self.um_sep.horzalign = "user_left";
    self.um_sep.vertalign = "user_top";
    self.um_sep setshader("white", 206, 1);
    self.um_sep.color = (1, 1, 1);
    self.um_sep.alpha = 0.45;
    self.um_sep.sort = 1001;
    self.um_sep.foreground = true;
    self.um_sep.hidewheninmenu = true;

    self.um_line = [];

    if (self.um_cur == "medalnum" || self.um_cur == "gamemodenum" || self.um_cur == "weaponnum" || self.um_cur == "statsnum" || self.um_cur == "equipnum" || self.um_cur == "streaknum")
    {
        self um_draw_medal_editor();
        return;
    }

    n = self.um_text[self.um_cur].size;
    y = 137;
    visible = 9;
    if (n < visible)
        visible = n;

    // ---- selected row: subtle white block, cyan text, no icons
    selrow = self.um_cursor - self.um_scroll;
    if (selrow >= 0 && selrow < visible)
    {
        self.um_sel = newclienthudelem(self);
        self.um_sel.x = 56;
        self.um_sel.y = y + (selrow * 17) - 1;
        self.um_sel.alignx = "left";
        self.um_sel.aligny = "top";
        self.um_sel.horzalign = "user_left";
        self.um_sel.vertalign = "user_top";
        self.um_sel setshader("white", 210, 17);
        self.um_sel.color = (1, 1, 1);
        self.um_sel.alpha = 0.14;
        self.um_sel.sort = 1001;
        self.um_sel.foreground = true;
        self.um_sel.hidewheninmenu = true;
    }

    for (i = self.um_scroll; i < n && i < self.um_scroll + visible; i++)
    {
        e = self um_newtext(y, 1.05);
        if (i == self.um_cursor)
        {
            if (self.um_cur == "main")
                e.color = (1, 1, 1);
            else
                e.color = (0.35, 0.9, 1);
            e settext(self.um_text[self.um_cur][i]);
        }
        else
        {
            e.color = (0.88, 0.88, 0.88);
            e settext(self.um_text[self.um_cur][i]);
        }
        e.sort = 1002;
        self.um_line[self.um_line.size] = e;
        y += 17;
    }
}

// ================================================================= info page
um_readthis_nop(a, b)
{
    self um_draw();
}

// ================================================================= actions
// ================================================================= achievements
um_giveachievement_wrapper(achievement)
{
    if (!isdefined(achievement))
        return;

    self giveAchievement(achievement);
}

um_unlock_achievements(a, b)
{
    self endon("disconnect");

    if (!isdefined(level.achievements))
    {
        self iprintln("^1Achievement list not loaded");
        return;
    }

    self iprintlnbold("^5Unlocking Achievements ^7- Please Wait");

    foreach (achievement in level.achievements)
    {
        self um_giveachievement_wrapper(achievement);
        wait .1;
    }

    self iprintlnbold("^2Achievements Unlocked!");
}

um_creditnoop(a, b)
{
    return;
}

um_master(a, b)
{
    self thread um_setandsave(15, 54);
}

um_master_noend(a, b)
{
    self um_setrank(15, 54);
    self iprintlnbold("^2Prestige Master ^7+ ^2Level 55 ^1(not saved - end the game yourself)");
}

um_level(a, b)
{
    if (!isdefined(a))
        return;
    r = a - 1;
    if (r < 0)
        r = 0;
    if (r > 54)
        r = 54;
    self um_setrank(self um_currentprestige(), r);
    self iprintlnbold("^2Level ^7" + (r + 1));
}

um_levelstep(a, b)
{
    if (!isdefined(a))
        return;
    self um_level(self um_currentrank() + 1 + a, undefined);
}

um_uprank(a, b)
{
    self addRankXpValue("contract", 50000);
    self iprintln("^2+50,000 XP");
}

um_prestige(a, b)
{
    if (!isdefined(a) || a < 0 || a > 15)
        return;

    r = self.pers["rank"];
    if (!isdefined(r))
        r = 0;

    self setrank(r, a);
    self iprintlnbold("^2Prestige ^7" + a);
}

um_prestigenow()
{
    p = self.pers["prestige"];
    if (!isdefined(p))
        p = 0;
    return p;
}



um_prestige_noend(a, b)
{
    if (!isdefined(a) || a < 0 || a > 15)
        return;
    self um_setrank(a, self um_currentrank());
    self iprintlnbold("^2Prestige ^7" + a + " ^1(not ended)");
}

um_currentprestige()
{
    p = self getdstat("playerstatslist", "plevel", "StatValue");
    if (!isdefined(p))
        p = 0;
    if (p < 0)
        p = 0;
    if (p > 15)
        p = 15;
    return p;
}

um_currentrank()
{
    r = self getdstat("playerstatslist", "rank", "StatValue");
    if (!isdefined(r))
        r = 0;
    if (r < 0)
        r = 0;
    if (r > 54)
        r = 54;
    return r;
}

// THE important one: setRank() is session only, setDStat() writes the profile.
// These are the exact stats the game's own _rank::updaterank() writes.
um_setrank(prestige, rankid)
{
    if (!isdefined(prestige) || !isdefined(rankid))
        return;
    if (rankid < 0)
        rankid = 0;
    if (rankid > 54)
        rankid = 54;
    if (prestige < 0)
        prestige = 0;
    if (prestige > 15)
        prestige = 15;

    minxp = maps\mp\gametypes\_rank::getrankinfominxp(rankid);
    maxxp = maps\mp\gametypes\_rank::getrankinfomaxxp(rankid);
    xp = maxxp - 1;
    if (rankid == 54)
        xp = maxxp;

    // NOTE: "plevel" (prestige) is deliberately NOT written here.
    // A host-side plevel write desyncs a remote client -> "Failure to communicate
    // with host". Rank and XP are accepted, prestige is not. Get to 55 + max XP
    // and press Prestige in the Barracks on your own console instead.
    self setdstat("playerstatslist", "rank", "StatValue", rankid);
    self setdstat("playerstatslist", "rankxp", "StatValue", xp);
    self setdstat("playerstatslist", "minxp", "StatValue", minxp);
    self setdstat("playerstatslist", "maxxp", "StatValue", maxxp);
    self setdstat("playerstatslist", "lastxp", "StatValue", xp);

    self.pers["rankxp"] = xp;
    self.pers["rank"] = rankid;
}

// read the profile back so you can see what actually stuck
um_verify(a, b)
{
    p = self getdstat("playerstatslist", "plevel", "StatValue");
    r = self getdstat("playerstatslist", "rank", "StatValue");
    x = self getdstat("playerstatslist", "rankxp", "StatValue");
    if (!isdefined(p)) p = -1;
    if (!isdefined(r)) r = -1;
    if (!isdefined(x)) x = -1;
    self iprintlnbold("^2profile: ^7prestige " + p + "  rank " + r + "  xp " + x);
}

um_pstat(a, b)
{
    if (!isdefined(a) || !isdefined(b))
        return;
    self addplayerstat(a, b);
    self iprintln("^2" + a + " ^7+" + b);
}

um_gstat(a, b)
{
    if (!isdefined(a) || !isdefined(b))
        return;
    self addgametypestat(a, b);
    self iprintln("^2" + a + " ^7+" + b);
}

um_wstat(a, b)
{
    if (!isdefined(a) || !isdefined(b))
        return;
    w = self getcurrentweapon();
    if (!isdefined(w) || w == "none")
    {
        self iprintln("^1Hold a weapon first");
        return;
    }
    self addweaponstat(w, a, b);
    self iprintln("^2" + w + " " + a + " ^7+" + b);
}

um_allmedals(a, b)
{
    self um_medaltable(3, a);
}

um_medal_digit_change(delta)
{
    if (!isdefined(self.um_medal_digits))
        return;

    i = self.um_medal_digit_cursor;

    if (i == 0)
    {
        if (delta > 0 && self.um_medal_digits[0] == 0)
            self.um_medal_digits[0] = 1;
        else if (delta < 0 && self.um_medal_digits[0] == 1)
            self.um_medal_digits[0] = 0;

        if (self.um_medal_digits[0] == 1)
        {
            for (j = 1; j < 10; j++)
                self.um_medal_digits[j] = 0;
        }

        return;
    }

    if (self.um_medal_digits[0] == 1)
        return;

    self.um_medal_digits[i] += delta;

    if (self.um_medal_digits[i] > 9)
        self.um_medal_digits[i] = 0;

    if (self.um_medal_digits[i] < 0)
        self.um_medal_digits[i] = 9;
}

um_open_accountstats_editor(a, b)
{
    if (!isdefined(a) || !isdefined(b))
        return;

    self.um_accountstats_editor_action = a;
    self.um_accountstats_editor_default = b;
    self.um_cur = "statsnum";
    self.um_cursor = 0;
    self.um_scroll = 0;

    self um_set_number_digits(b);
    self um_draw();
}

um_apply_accountstats_editor()
{
    self endon("disconnect");

    stat_value = self um_medal_editor_value();

    if (!isdefined(self.um_accountstats_editor_action))
        return;

    // Close the Select Number Stats page first.
    self um_back();

    self iprintlnbold("^3APPLY ^7" + stat_value + " ^3WAIT...");
    wait 0.8;

    self thread um_pstat(self.um_accountstats_editor_action, stat_value);
}

um_open_weapon_editor(a, b)
{
    if (!isdefined(a) || !isdefined(b))
        return;

    self.um_weapon_editor_action = a;
    self.um_weapon_editor_default = b;
    self.um_cur = "weaponnum";
    self.um_cursor = 0;
    self.um_scroll = 0;

    self um_set_number_digits(b);
    self um_draw();
}

um_apply_weaponstats_editor()
{
    self endon("disconnect");

    stat_value = self um_medal_editor_value();

    if (!isdefined(self.um_weapon_editor_action))
        return;

    // Close the Select Number Stats page first.
    self um_back();

    self iprintlnbold("^3APPLY ^7" + stat_value + " ^3WAIT...");
    wait 0.8;

    action = self.um_weapon_editor_action;
    if (action == "everything")
        self um_allweapons("everything", stat_value);
    else if (action == "kills_all")
        self um_allweapons("kills", stat_value);
    else if (action == "headshots_all")
        self um_allweapons("headshots", stat_value);
    else if (action == "hits_all")
        self um_allweapons("hits", stat_value);
    else if (action == "shots_all")
        self um_allweapons("shots", stat_value);
    else if (action == "kills_current")
        self um_wstat("kills", stat_value);
    else if (action == "headshots_current")
        self um_wstat("headshots", stat_value);
}

um_open_equipment_editor(a, b)
{
    if (!isdefined(a) || !isdefined(b))
        return;

    self.um_equipment_editor_action = a;
    self.um_equipment_editor_default = b;
    self.um_cur = "equipnum";
    self.um_cursor = 0;
    self.um_scroll = 0;

    self um_set_number_digits(b);
    self um_draw();
}

um_open_scorestreak_editor(a, b)
{
    if (!isdefined(a) || !isdefined(b))
        return;

    self.um_scorestreak_editor_action = a;
    self.um_scorestreak_editor_default = b;
    self.um_cur = "streaknum";
    self.um_cursor = 0;
    self.um_scroll = 0;

    self um_set_number_digits(b);
    self um_draw();
}

um_apply_equipment_editor()
{
    self endon("disconnect");

    stat_value = self um_medal_editor_value();

    if (!isdefined(self.um_equipment_editor_action))
        return;

    self um_back();

    self iprintlnbold("^3APPLY ^7" + stat_value + " ^3WAIT...");
    wait 0.8;

    // Use the original working equipment routine directly.
    if (self.um_equipment_editor_action == "everything")
        self um_allequipment(undefined, stat_value);
}

um_apply_scorestreak_editor()
{
    self endon("disconnect");

    stat_value = self um_medal_editor_value();

    if (!isdefined(self.um_scorestreak_editor_action))
        return;

    self um_back();

    self iprintlnbold("^3APPLY ^7" + stat_value + " ^3WAIT...");
    wait 0.8;

    // Use the original working scorestreak routine directly.
    if (self.um_scorestreak_editor_action == "everything")
        self um_allscorestreaks(undefined, stat_value);
}

um_equipment_stat(action, value)
{
    self endon("disconnect");
    if (!isdefined(action) || !isdefined(value))
        return;

    if (action == "everything")
    {
        self thread um_allequipment(undefined, value);
        return;
    }

    if (action == "satchel_used") self addweaponstat("satchel_charge_mp", "used", value);
    else if (action == "satchel_kills") self addweaponstat("satchel_charge_mp", "kills", value);
    else if (action == "frag_used") self addweaponstat("frag_grenade_mp", "used", value);
    else if (action == "frag_kills") self addweaponstat("frag_grenade_mp", "kills", value);
    else if (action == "hatchet_used") self addweaponstat("hatchet_mp", "used", value);
    else if (action == "hatchet_kills") self addweaponstat("hatchet_mp", "kills", value);
    else if (action == "sticky_used") self addweaponstat("sticky_grenade_mp", "used", value);
    else if (action == "sticky_kills") self addweaponstat("sticky_grenade_mp", "kills", value);
    else if (action == "betty_used") self addweaponstat("bouncingbetty_mp", "used", value);
    else if (action == "betty_kills") self addweaponstat("bouncingbetty_mp", "kills", value);
    else if (action == "claymore_used") self addweaponstat("claymore_mp", "used", value);
    else if (action == "claymore_kills") self addweaponstat("claymore_mp", "kills", value);
    else if (action == "willy_used") self addweaponstat("willy_pete_mp", "used", value);
    else if (action == "concussion_used") self addweaponstat("concussion_grenade_mp", "used", value);
    else if (action == "emp_used") self addweaponstat("emp_grenade_mp", "used", value);
    else if (action == "sensor_used") self addweaponstat("sensor_grenade_mp", "used", value);
    else if (action == "flash_used") self addweaponstat("flash_grenade_mp", "used", value);
    else if (action == "proximity_used") self addweaponstat("proximity_grenade_mp", "used", value);
    else if (action == "pda_used") self addweaponstat("pda_hack_mp", "used", value);
    else if (action == "tac_insert_used") self addweaponstat("tactical_insertion_mp", "used", value);
    else if (action == "trophy_used") self addweaponstat("trophy_system_mp", "used", value);
    else if (action == "capture_smoke") self addplayerstat("capture_objective_in_smoke", value);
    else if (action == "kill_concussed") self addplayerstat("kill_concussed_enemy", value);
    else if (action == "destroy_emp") self addplayerstat("destroy_equipment_with_emp_grenade", value);
    else if (action == "kill_sensor") self addplayerstat("kill_enemy_revealed_by_sensor", value);
    else if (action == "kill_flashed") self addplayerstat("kill_flashed_enemy", value);
    else if (action == "kill_shocked") self addplayerstat("kill_shocked_enemy", value);
    else if (action == "hack_target") self addplayerstat("hack_enemy_target", value);
    else if (action == "kill_tac_insert") self addplayerstat("kill_after_tac_insert", value);
    else if (action == "destroy_trophy") self addplayerstat("destroy_explosive_with_trophy", value);

    self iprintlnbold("^5Equipment stat ^7" + value + " applied");
}

um_scorestreak_stat(action, value)
{
    self endon("disconnect");
    if (!isdefined(action) || !isdefined(value))
        return;

    if (action == "everything")
    {
        self thread um_allscorestreaks(undefined, value);
        return;
    }

    if (action == "radar_used") self addweaponstat("radar_mp", "used", value);
    else if (action == "radar_assists") self addweaponstat("radar_mp", "assists", value);
    else if (action == "dragonfire_used") self addweaponstat("paragonfire_mp", "used", value);
    else if (action == "dragonfire_kills") self addweaponstat("paragonfire_mp", "kills", value);
    else if (action == "hunter_used") self addweaponstat("killstreak_qrdrone_mp", "used", value);
    else if (action == "hunter_kills") self addweaponstat("killstreak_qrdrone_mp", "kills", value);
    else if (action == "rcxd_used") self addweaponstat("rcbomb_mp", "used", value);
    else if (action == "rcxd_kills") self addweaponstat("rcbomb_mp", "kills", value);
    else if (action == "lightning_used") self addweaponstat("planemortar_mp", "used", value);
    else if (action == "lightning_kills") self addweaponstat("planemortar_mp", "kills", value);
    else if (action == "missile_drone_used") self addweaponstat("missile_drone_mp", "used", value);
    else if (action == "missile_drone_kills") self addweaponstat("missile_drone_mp", "kills", value);
    else if (action == "lodestar_used") self addweaponstat("remote_mortar_mp", "used", value);
    else if (action == "lodestar_kills") self addweaponstat("remote_mortar_mp", "kills", value);
    else if (action == "hellstorm_used") self addweaponstat("remote_missile_mp", "used", value);
    else if (action == "hellstorm_kills") self addweaponstat("remote_missile_mp", "kills", value);
    else if (action == "emp_streak_used") self addweaponstat("emp_mp", "used", value);
    else if (action == "emp_streak_assists") self addweaponstat("emp_mp", "assists", value);
    else if (action == "warthog_used") self addweaponstat("straferun_mp", "used", value);
    else if (action == "warthog_kills") self addweaponstat("straferun_mp", "kills", value);
    else if (action == "dogs_used") self addweaponstat("dogs_mp", "used", value);
    else if (action == "dogs_kills") self addweaponstat("dogs_mp", "kills", value);
    else if (action == "supplydrop_used") self addweaponstat("supplydrop_mp", "used", value);
    else if (action == "supplydrop_kills") self addweaponstat("supplydrop_mp", "kills", value);
    else if (action == "vtol_used") self addweaponstat("helicopter_player_gunner_mp", "used", value);
    else if (action == "vtol_kills") self addweaponstat("helicopter_player_gunner_mp", "kills", value);
    else if (action == "sentry_used") self addweaponstat("autoturret_mp", "used", value);
    else if (action == "sentry_kills") self addweaponstat("autoturret_mp", "kills", value);
    else if (action == "guardian_used") self addweaponstat("microwaveturret_mp", "used", value);
    else if (action == "guardian_kills") self addweaponstat("microwaveturret_mp", "kills", value);
    else if (action == "swarm_used") self addweaponstat("missile_swarm_mp", "used", value);
    else if (action == "swarm_kills") self addweaponstat("missile_swarm_mp", "kills", value);
    else if (action == "agr_used") self addweaponstat("ai_tank_drop_mp", "used", value);
    else if (action == "agr_kills") self addweaponstat("ai_tank_drop_mp", "kills", value);
    else if (action == "counter_used") self addweaponstat("counteruav_mp", "used", value);
    else if (action == "counter_assists") self addweaponstat("counteruav_mp", "assists", value);
    else if (action == "death_machine_used") self addweaponstat("inventory_minigun_mp", "used", value);
    else if (action == "death_machine_kills") self addweaponstat("minigun_mp", "kills", value);
    else if (action == "war_machine_used") self addweaponstat("inventory_m32_mp", "used", value);
    else if (action == "war_machine_kills") self addweaponstat("m32_mp", "kills", value);
    else if (action == "stealth_used") self addweaponstat("helicopter_comlink_mp", "used", value);
    else if (action == "stealth_kills") self addweaponstat("helicopter_comlink_mp", "kills", value);
    else if (action == "vsat_used") self addweaponstat("radardirection_mp", "used", value);
    else if (action == "vsat_assists") self addweaponstat("radardirection_mp", "assists", value);
    else if (action == "escort_used") self addweaponstat("helicopter_guard_mp", "used", value);
    else if (action == "escort_kills") self addweaponstat("helicopter_guard_mp", "kills", value);

    self iprintlnbold("^6Scorestreak stat ^7" + value + " applied");
}

um_set_number_digits(value)
{
    if (!isdefined(value))
        value = 0;

    if (value < 0)
        value = 0;
    if (value > 1000000000)
        value = 1000000000;

    self.um_medal_digits = [];
    self.um_medal_digits[0] = 0;
    self.um_medal_digits[1] = 0;
    self.um_medal_digits[2] = 0;
    self.um_medal_digits[3] = 0;
    self.um_medal_digits[4] = 0;
    self.um_medal_digits[5] = 0;
    self.um_medal_digits[6] = 0;
    self.um_medal_digits[7] = 0;
    self.um_medal_digits[8] = 0;
    self.um_medal_digits[9] = 0;

    remaining = value;
    for (i = 9; i >= 0; i--)
    {
        self.um_medal_digits[i] = remaining % 10;
        remaining = int(remaining / 10);
    }

    self.um_medal_digit_cursor = 0;
    for (i = 0; i < 10; i++)
    {
        if (self.um_medal_digits[i] != 0)
        {
            self.um_medal_digit_cursor = i;
            break;
        }
    }
}

um_apply_othermedals()
{
    self endon("disconnect");

    stat_value = self um_medal_editor_value();

    // Close the Select Number Stats page first.
    self um_back();

    self iprintlnbold("^3APPLY ^7" + stat_value + " ^3WAIT...");
    wait 0.8;

    self thread um_othermedals(stat_value, undefined);
}

um_apply_gamemodestats_editor()
{
    self endon("disconnect");

    stat_value = self um_medal_editor_value();

    // Close the Select Number Stats page first.
    self um_back();

    self iprintlnbold("^3APPLY ^7" + stat_value + " ^3WAIT...");
    wait 0.8;

    self thread um_gamemodestats(undefined, stat_value);
}

um_medal_editor_value()
{
    if (!isdefined(self.um_medal_digits))
    {
        if (self.um_cur == "weaponnum")
            return self.um_weapon_editor_default;
        if (self.um_cur == "gamemodenum")
            return 667667;
        if (self.um_cur == "statsnum")
            return self.um_accountstats_editor_default;
        if (self.um_cur == "equipnum")
            return self.um_equipment_editor_default;
        if (self.um_cur == "streaknum")
            return self.um_scorestreak_editor_default;
        return 1337;
    }

    value = 0;
    for (i = 0; i < 10; i++)
        value = (value * 10) + self.um_medal_digits[i];

    if (value > 1000000000)
        value = 1000000000;

    return value;
}

um_othermedals(a, b)
{
    self endon("disconnect");

    stat_value = a;
    if (!isdefined(stat_value))
        stat_value = 1337;

    if (stat_value < 0)
        stat_value = 0;

    if (stat_value > 1000000000)
        stat_value = 1000000000;

    medals = strTok("medal_aitank_kill,medal_assisted_suicide,medal_backstabber_kill,medal_ballistic_knife_kill,medal_bomb_detonated,medal_bounce_hatchet_kill,medal_capture_enemy_crate,medal_clear_2_attackers,medal_comeback_from_deathstreak,medal_completed_match,medal_crossbow_kill,medal_death_machine_kill,medal_defend_hq_last_alive,medal_defused_bomb,medal_defused_bomb_last_man_alive,medal_destroyed_aitank,medal_destroyed_counteruav,medal_destroyed_heli_comlink,medal_destroyed_heli_guard,medal_destroyed_heli_gunner,medal_destroyed_microwave_turret,medal_destroyed_missile_drone,medal_destroyed_missile_swarm,medal_destroyed_plane_mortar,medal_destroyed_qrdrone,medal_destroyed_rcbomb,medal_destroyed_remote_missle,medal_destroyed_remote_mortar,medal_destroyed_sentry_gun,medal_destroyed_straferun,medal_destroyed_supply_drop,medal_destroyed_uav,medal_dogs_kill,medal_elimination_and_last_player_alive,medal_final_kill_elimination,medal_first_kill,medal_flag_capture,medal_flag_carrier_kill_return_close,medal_hacked,medal_hatchet_kill,medal_headshot,medal_helicopter_comlink_kill,medal_helicopter_guard_kill,medal_helicopter_gunner_kill,medal_hq_destroyed,medal_hq_secure,medal_killed_bomb_defuser,medal_killed_bomb_planter,medal_killed_enemy_while_carrying_flag,medal_killstreak_10,medal_killstreak_15,medal_killstreak_20,medal_killstreak_25,medal_killstreak_30,medal_killstreak_5,medal_killstreak_more_than_30,medal_kill_confirmed_multi,medal_kill_enemies_one_bullet,medal_kill_enemy_after_death,medal_kill_enemy_injuring_teammate,medal_kill_enemy_one_bullet,medal_kill_enemy_recent_dive_prone,medal_kill_enemy_when_injured,medal_kill_enemy_while_capping,medal_kill_enemy_who_killed_teammate,medal_kill_enemy_with_care_package_crush,medal_kill_enemy_with_hacked_care_package,medal_kill_enemy_with_their_weapon,medal_kill_flag_carrier,medal_koth_secure,medal_longshot_kill,medal_melee_kill_with_riot_shield,medal_microwave_turret_kill,medal_missile_drone_kill,medal_missile_swarm_kill,medal_multikill_2,medal_multikill_3,medal_multikill_4,medal_multikill_5,medal_multikill_6,medal_multikill_7,medal_multikill_8,medal_multikill_more_than_8,medal_multiple_grenade_launcher_kill,medal_neutral_b_secured,medal_plane_mortar_kill,medal_position_secure,medal_qrdrone_kill,medal_quickly_secure_point,medal_rcxd_kill,medal_remote_missile_kill,medal_remote_mortar_kill,medal_retrieve_own_tags,medal_revenge_kill,medal_sentry_gun_kill,medal_share_package_aitank,medal_share_package_ammo,medal_share_package_counter_uav,medal_share_package_death_machine,medal_share_package_dogs,medal_share_package_emp,medal_share_package_helicopter_comlink,medal_share_package_helicopter_guard,medal_share_package_helicopter_gunner,medal_share_package_microwave_turret,medal_share_package_missile_drone,medal_share_package_missle_swarm,medal_share_package_multiple_grenade_launcher,medal_share_package_plane_mortar,medal_share_package_qrdrone,medal_share_package_rcbomb,medal_share_package_remote_missile,medal_share_package_remote_mortar,medal_share_package_satellite,medal_share_package_sentry_gun,medal_share_package_strafe_run,medal_share_package_uav,medal_stick_explosive_kill,medal_stop_enemy_killstreak,medal_straff_run_kill,medal_teammate_confirm_kill,medal_uninterrupted_obit_feed_kills,medal_won_match", ",");

    count = 0;
    foreach(medal in medals)
    {
        self addPlayerStat(medal, stat_value);
        count++;
        wait 0.1;
    }

    self iprintlnbold("^2Other Medals ^7x" + stat_value + " ^2(" + count + ")");
}

um_medaltable(a, b)
{
    self endon("disconnect");

    if (!isdefined(a))
        a = 3;

    if (!isdefined(b))
        b = 667667;

    switch(a)
    {
        case 1:
            start = 0;
            end = 256;
            break;

        case 2:
            start = 256;
            end = 512;
            break;

        case 3:
            start = 512;
            end = 768;
            break;

        default:
            return;
    }

    tableName = tableLookupFindCoreAsset("mp/statsmilestones" + a + ".csv");
    medalCount = 0;

    for(rowIndex = start; rowIndex < end; rowIndex++)
    {
        statType = tableLookupColumnForRow(tableName, rowIndex, 3);
        statName = tableLookupColumnForRow(tableName, rowIndex, 4);

        if (!isdefined(statName) || statName == "")
            continue;

        if (statType == "global")
        {
            self addPlayerStat(statName, b);
            medalCount++;
            wait 0.1;
        }
        else if (statType == "killstreak")
        {
            tokens = strTok(tableLookupColumnForRow(tableName, rowIndex, 13), " ");

            foreach(token in tokens)
            {
                kstokens = strTok(token, "_");
                rebuilt = "";

                for(x = 0; x < kstokens.size; x++)
                {
                    if (kstokens[x] != "killstreak")
                    {
                        rebuilt += kstokens[x];
                        rebuilt += x != (kstokens.size - 1) ? "_" : "_mp";
                    }
                }

                if (rebuilt == "qrdrone_mp")
                    rebuilt = "qrdrone_turret_mp";

                if (rebuilt == "auto_turret_mp")
                    rebuilt = "autoturret_mp";

                self addWeaponStat(rebuilt, statName, b);
                medalCount++;
                wait 0.1;
            }
        }
    }

    self iprintlnbold("^2Medals ^7x" + b + " ^2(" + medalCount + ")");
}

um_gamemodemedals(a, b)
{
    self endon("disconnect");

    if (!isdefined(a))
        a = 4;

    if (!isdefined(b))
        b = 997;

    start = 768;
    end = 1024;

    tableName = tableLookupFindCoreAsset("mp/statsmilestones" + a + ".csv");
    medalCount = 0;

    for(rowIndex = start; rowIndex < end; rowIndex++)
    {
        statType = tableLookupColumnForRow(tableName, rowIndex, 3);
        statName = tableLookupColumnForRow(tableName, rowIndex, 4);

        if (!isdefined(statName) || statName == "")
            continue;

        if (statType == "gamemode")
        {
            tokens = strTok(tableLookupColumnForRow(tableName, rowIndex, 13), " ");

            foreach(token in tokens)
            {
                self setDStat("PlayerStatsByGameType", token, statName, "StatValue", b);
                self setDStat("PlayerStatsByGameType", token, statName, "ChallengeValue", b);
                medalCount++;
                wait 0.1;
            }
        }
    }

    self iprintlnbold("^2GameModes ^7x" + b + " ^2(" + medalCount + ")");
}

um_gamemodestats(a, b)
{
    self endon("disconnect");

    if (!isdefined(b))
        b = 667667;

    if (isdefined(self.um_busy))
    {
        self iprintln("^1Already running, wait");
        return;
    }

    self.um_busy = true;
    self iprintlnbold("^6Game Mode stats started ^7(24 modes)");

    // BO2 PlayerStatsByGameType: all stats exposed by gametypestats_s.
    gametypes = [];
    gametypes[gametypes.size] = "tdm";
    gametypes[gametypes.size] = "dm";
    gametypes[gametypes.size] = "sd";
    gametypes[gametypes.size] = "dom";
    gametypes[gametypes.size] = "koth";
    gametypes[gametypes.size] = "hq";
    gametypes[gametypes.size] = "dem";
    gametypes[gametypes.size] = "ctf";
    gametypes[gametypes.size] = "conf";
    gametypes[gametypes.size] = "gun";
    gametypes[gametypes.size] = "oic";
    gametypes[gametypes.size] = "shrp";
    gametypes[gametypes.size] = "sas";
    gametypes[gametypes.size] = "hctdm";
    gametypes[gametypes.size] = "hcdm";
    gametypes[gametypes.size] = "hcsd";
    gametypes[gametypes.size] = "hcdom";
    gametypes[gametypes.size] = "hckoth";
    gametypes[gametypes.size] = "hchq";
    gametypes[gametypes.size] = "hcdem";
    gametypes[gametypes.size] = "hcctf";
    gametypes[gametypes.size] = "hcconf";
    gametypes[gametypes.size] = "oneflag";
    gametypes[gametypes.size] = "hconeflag";

    stats = [];
    stats[stats.size] = "assists";
    stats[stats.size] = "cur_win_streak";
    stats[stats.size] = "crush";
    stats[stats.size] = "deaths";
    stats[stats.size] = "defends";
    stats[stats.size] = "kdratio";
    stats[stats.size] = "kills";
    stats[stats.size] = "kill_streak";
    stats[stats.size] = "losses";
    stats[stats.size] = "offends";
    stats[stats.size] = "score";
    stats[stats.size] = "ties";
    stats[stats.size] = "time_played_total";
    stats[stats.size] = "top3";
    stats[stats.size] = "top3team";
    stats[stats.size] = "topplayer";
    stats[stats.size] = "wins";
    stats[stats.size] = "win_streak";
    stats[stats.size] = "wlratio";
    stats[stats.size] = "challenge1";
    stats[stats.size] = "challenge2";
    stats[stats.size] = "challenge3";
    stats[stats.size] = "challenge4";
    stats[stats.size] = "challenge5";
    stats[stats.size] = "challenge6";
    stats[stats.size] = "challenge7";
    stats[stats.size] = "challenge8";
    stats[stats.size] = "challenge9";
    stats[stats.size] = "challenge10";

    changed = 0;
    for (i = 0; i < gametypes.size; i++)
    {
        for (j = 0; j < stats.size; j++)
        {
            self setDStat("PlayerStatsByGameType", gametypes[i], stats[j], "StatValue", b);
            changed++;
            wait 0.03;
        }
    }

    self.um_busy = undefined;
    self iprintlnbold("^2Game Mode stats done ^7(" + changed + " stats x 24 modes)");
}

// ---- weapon lists
um_list(kind)
{
    l = [];
    if (kind == "all" || kind == "ar")
    {
        l[l.size] = "an94_mp";      l[l.size] = "hk416_mp";   l[l.size] = "sa58_mp";
        l[l.size] = "saritch_mp";   l[l.size] = "scar_mp";    l[l.size] = "sig556_mp";
        l[l.size] = "tar21_mp";     l[l.size] = "type95_mp";  l[l.size] = "xm8_mp";
    }
    if (kind == "all" || kind == "smg")
    {
        l[l.size] = "evoskorpion_mp"; l[l.size] = "insas_mp";  l[l.size] = "mp7_mp";
        l[l.size] = "pdw57_mp";       l[l.size] = "peacekeeper_mp";
        l[l.size] = "qcw05_mp";       l[l.size] = "vector_mp";
    }
    if (kind == "all" || kind == "lmg")
    {
        l[l.size] = "hamr_mp"; l[l.size] = "lsat_mp"; l[l.size] = "mk48_mp"; l[l.size] = "qbb95_mp";
    }
    if (kind == "all" || kind == "sniper")
    {
        l[l.size] = "as50_mp"; l[l.size] = "ballista_mp"; l[l.size] = "dsr50_mp"; l[l.size] = "svu_mp";
    }
    if (kind == "all" || kind == "sg")
    {
        l[l.size] = "870mcs_mp"; l[l.size] = "ksg_mp"; l[l.size] = "saiga12_mp"; l[l.size] = "srm1216_mp";
    }
    if (kind == "all" || kind == "pistol")
    {
        l[l.size] = "beretta93r_mp"; l[l.size] = "fiveseven_mp"; l[l.size] = "fnp45_mp";
        l[l.size] = "judge_mp";      l[l.size] = "kard_mp";
    }
    if (kind == "all" || kind == "other")
    {
        l[l.size] = "fhj18_mp";   l[l.size] = "smaw_mp";  l[l.size] = "usrpg_mp";
        l[l.size] = "crossbow_mp"; l[l.size] = "knife_ballistic_mp";
        l[l.size] = "riotshield_mp"; l[l.size] = "knife_held_mp"; l[l.size] = "knife_mp";
    }
    return l;
}

um_unlockall(a, b)
{
    self endon("disconnect");

    if (isdefined(self.um_busy))
    {
        self iprintln("^1Already running, wait");
        return;
    }

    self.um_busy = true;
    self thread um_unlockall_waitmsg();
    self iprintlnbold("Unlock ALL - Please wait");
    self iprintln("For a full unlock, please save and restart a new game,");
    self iprintln("then apply Unlock All a second time to unlock everything!");
    // ================================================================
    // Predator v6.7 Unlock Everything additions
    // Missing account stats + gametype stats + killstreak Combat Record stats.
    // Kept separate from the existing stats-milestones unlock system.

    self addPlayerStat("score", 550000);
    wait 0.03;
    self addPlayerStat("time_played_total", 50000);
    wait 0.03;

    self addgametypestat("killstreak_10", 2244);
    wait 0.03;
    self addgametypestat("killstreak_15", 1542);
    wait 0.03;
    self addgametypestat("killstreak_20", 733);
    wait 0.03;
    self addgametypestat("killstreak_30", 72);
    wait 0.03;
    self addgametypestat("round_win_no_deaths", 831);
    wait 0.03;
    self addgametypestat("last_man_defeat_3_enemies", 323);
    wait 0.03;
    self addgametypestat("CRUSH", 623);
    wait 0.03;
    self addgametypestat("most_kills_least_deaths", 143);
    wait 0.03;
    self addgametypestat("SHUT_OUT", 434);
    wait 0.03;
    self addgametypestat("ANNIHILATION", 321);
    wait 0.03;
    self addgametypestat("kill_2_enemies_capturing_your_objective", 351);
    wait 0.03;
    self addgametypestat("capture_b_first_minute", 234);
    wait 0.03;
    self addgametypestat("immediate_capture", 346);
    wait 0.03;
    self addgametypestat("contest_then_capture", 692);
    wait 0.03;
    self addgametypestat("both_bombs_detonate_10_seconds", 56);
    wait 0.03;
    self addgametypestat("multikill_3", 294);
    wait 0.03;
    self addgametypestat("kill_enemy_who_killed_teammate", 3423);
    wait 0.03;
    self addgametypestat("kill_enemy_injuring_teammate", 511);
    wait 0.03;
    self addgametypestat("defused_bomb_last_man_alive", 245);
    wait 0.03;
    self addgametypestat("elimination_and_last_player_alive", 232);
    wait 0.03;
    self addgametypestat("killed_bomb_planter", 234);
    wait 0.03;
    self addgametypestat("killed_bomb_defuser", 341);
    wait 0.03;
    self addgametypestat("kill_flag_carrier", 131);
    wait 0.03;
    self addgametypestat("defend_flag_carrier", 112);
    wait 0.03;
    self addgametypestat("killed_bomb_planter", 162);
    wait 0.03;
    self addgametypestat("killed_bomb_defuser", 152);
    wait 0.03;
    self addgametypestat("kill_flag_carrier", 114);
    wait 0.03;
    self addgametypestat("defend_flag_carrier", 183);
    wait 0.03;

    self addweaponstat("dogs_mp", "used", 21);
    wait 0.03;
    self addweaponstat("emp_mp", "used", 23);
    wait 0.03;
    self addweaponstat("missile_drone_mp", "used", 38);
    wait 0.03;
    self addweaponstat("missile_swarm_mp", "used", 13);
    wait 0.03;
    self addweaponstat("planemortar_mp", "used", 39);
    wait 0.03;
    self addweaponstat("killstreak_qrdrone_mp", "used", 39);
    wait 0.03;
    self addweaponstat("remote_missile_mp", "used", 28);
    wait 0.03;
    self addweaponstat("remote_mortar_mp", "used", 38);
    wait 0.03;
    self addweaponstat("straferun_mp", "used", 21);
    wait 0.03;
    self addweaponstat("supplydrop_mp", "used", 18);
    wait 0.03;
    self addweaponstat("ai_tank_drop_mp", "used", 12);
    wait 0.03;
    self addweaponstat("acoustic_sensor_mp", "used", 22);
    wait 0.03;
    self addweaponstat("qrdrone_turret_mp", "destroyed", 23);
    wait 0.03;
    self addweaponstat("rcbomb_mp", "destroyed", 21);
    wait 0.03;
    self addweaponstat("qrdrone_turret_mp", "used", 23);
    wait 0.03;
    self addweaponstat("rcbomb_mp", "used", 43);
    wait 0.03;
    self addweaponstat("microwaveturret_mp", "used", 13);
    wait 0.03;
    self addweaponstat("autoturret_mp", "used", 14);
    wait 0.03;
    self addweaponstat("helicopter_player_gunner_mp", "used", 17);
    wait 0.03;
    self addweaponstat("missile_drone_mp", "destroyed", 173);
    wait 0.03;
    self addweaponstat("missile_swarm_mp", "destroyed", 84);
    wait 0.03;
    self addweaponstat("planemortar_mp", "destroyed", 413);
    wait 0.03;
    self addweaponstat("killstreak_qrdrone_mp", "destroyed", 634);
    wait 0.03;
    self addweaponstat("remote_missile_mp", "destroyed", 535);
    wait 0.03;
    self addweaponstat("remote_mortar_mp", "destroyed", 824);
    wait 0.03;
    self addweaponstat("straferun_mp", "destroyed", 485);
    wait 0.03;
    self addweaponstat("supplydrop_mp", "destroyed", 556);
    wait 0.03;
    self addweaponstat("ai_tank_drop_mp", "destroyed", 302);
    wait 0.03;
    self addweaponstat("acoustic_sensor_mp", "destroyed", 1002);
    wait 0.03;
    self addweaponstat("microwaveturret_mp", "destroyed", 923);
    wait 0.03;
    self addweaponstat("autoturret_mp", "destroyed", 994);
    wait 0.03;
    self addweaponstat("helicopter_player_gunner_mp", "destroyed", 1017);
    wait 0.03;
    self addweaponstat("willy_pete_mp", "CombatRecordStat", 123);
    wait 0.03;
    self addweaponstat("emp_grenade_mp", "combatRecordStat", 232);
    wait 0.03;
    self addweaponstat("counteruav_mp", "assists", 323);
    wait 0.03;
    self addweaponstat("radar_mp", "assists", 242);
    wait 0.03;
    self addweaponstat("radardirection_mp", "assists", 103);
    wait 0.03;
    self addweaponstat("emp_mp", "assists", 74);
    wait 0.03;


    for (file = 1; file < 5; file++)
    {
        start = 0;
        end = 0;

        if (file == 1)
        {
            start = 0;
            end = 256;
        }
        else if (file == 2)
        {
            start = 256;
            end = 512;
        }
        else if (file == 3)
        {
            start = 512;
            end = 768;
        }
        else if (file == 4)
        {
            start = 768;
            end = 1024;
        }

        for (value = start; value < end; value++)
        {
            stat_value = Int(TableLookup("mp/statsmilestones" + file + ".csv", 0, value, 2));
            stat_type = TableLookup("mp/statsmilestones" + file + ".csv", 0, value, 3);
            stat_name = TableLookup("mp/statsmilestones" + file + ".csv", 0, value, 4);

            if (!isdefined(stat_value) || !isdefined(stat_name) || !isdefined(stat_type))
                continue;

            if (stat_type == "global")
            {
                if (stat_name == "lifetime_career_score_HC")
                    stat_name = "career_score_hc";
                else if (stat_name == "lifetime_career_score")
                    stat_name = "career_score";
                else if (stat_name == "lifetime_career_score_MULTITEAM")
                    stat_name = "career_score_multiteam";

                // Add progress so existing accounts also receive a fresh unlock event.
                self addPlayerStat(stat_name, stat_value);
                self setDStat("PlayerStatsList", stat_name, "ChallengeValue", 50000);
            }
            else if (stat_type == "killstreak")
            {
                tokens = StrTok(TableLookup("mp/statsmilestones" + file + ".csv", 0, value, 13), " ");

                foreach (token in tokens)
                {
                    rebuilt = "";
                    kstokens = StrTok(token, "_");

                    for (k = 0; k < kstokens.size; k++)
                    {
                        if (kstokens[k] != "killstreak")
                        {
                            rebuilt += kstokens[k];

                            if (k != (kstokens.size - 1))
                                rebuilt += "_";
                            else
                                rebuilt += "_mp";
                        }
                    }

                    if (rebuilt == "qrdrone_mp")
                        rebuilt = "qrdrone_turret_mp";

                    if (rebuilt == "auto_turret_mp")
                        rebuilt = "autoturret_mp";

                    self AddWeaponStat(rebuilt, stat_name, stat_value);
                    self setDStat("itemStats", GetBaseWeaponItemIndex(rebuilt), "purchased", 1);
                }
            }
            else if (stat_type == "attachment")
            {
                attachments = StrTok(TableLookup("mp/statsmilestones" + file + ".csv", 0, value, 13), " ");

                foreach (attachment in attachments)
                {
                    self setDStat("attachments", attachment, "stats", stat_name, "StatValue", stat_value);
                    self setDStat("attachments", attachment, "stats", stat_name, "ChallengeValue", stat_value);

                    if (stat_name == "challenges")
                    {
                        for (k = 1; k < (stat_value + 1); k++)
                        {
                            self setDStat("attachments", attachment, "stats", "challenge" + k, "StatValue", 500);
                            self setDStat("attachments", attachment, "stats", "challenge" + k, "ChallengeValue", 500);
                        }
                    }
                }
            }
            else if (stat_type == "group")
            {
                group = TableLookup("mp/statsmilestones" + file + ".csv", 0, value, 13);

                self setDStat("GroupStats", group, "stats", stat_name, "StatValue", stat_value);
                self setDStat("GroupStats", group, "stats", stat_name, "ChallengeValue", stat_value);
                self setDStat("GroupStats", group, "stats", "kills", "StatValue", 1000);
                self setDStat("GroupStats", group, "stats", "kills", "ChallengeValue", 1000);
            }
            else if (stat_type == "gamemode")
            {
                tokens = StrTok(TableLookup("mp/statsmilestones" + file + ".csv", 0, value, 13), " ");

                foreach (token in tokens)
                {
                    // Add progress for existing profiles, then force the challenge value high enough.
                    self addgametypestat(stat_name, stat_value);
                    self setDStat("PlayerStatsByGameType", token, stat_name, "ChallengeValue", 50000);

                    if (stat_name == "challenges")
                    {
                        for (k = 1; k < (stat_value + 1); k++)
                        {
                            self setDStat("PlayerStatsByGameType", token, "challenge" + k, "StatValue", 50000);
                            self setDStat("PlayerStatsByGameType", token, "challenge" + k, "ChallengeValue", 50000);
                        }
                    }
                }
            }
            else if (stat_type == "bonuscard")
            {
                bonuscard = TableLookup("mp/statsmilestones" + file + ".csv", 0, value, 13);
                bonuscard_index = maps\mp\gametypes\_rank::getitemindex(bonuscard);

                self setDStat("itemStats", bonuscard_index, "purchased", 1);
                self setDStat("itemStats", bonuscard_index, "stats", stat_name, "StatValue", stat_value);
                self setDStat("itemStats", bonuscard_index, "stats", stat_name, "ChallengeValue", stat_value);
            }
            else if (isSubStr(stat_type, "weapon_"))
            {
                for (k = 1; k < 132; k++)
                {
                    class = TableLookup("mp/statstable.csv", 0, k, 2);

                    if (class != stat_type)
                        continue;

                    if (class == "weapon_grenadelauncher")
                    {
                        weapon_index = maps\mp\gametypes\_rank::getitemindex(class);

                        self setDStat("itemStats", weapon_index, "stats", stat_name, "StatValue", stat_value);
                        self setDStat("itemStats", weapon_index, "stats", stat_name, "ChallengeValue", stat_value);
                        break;
                    }

                    weapon = TableLookup("mp/statstable.csv", 0, k, 4);
                    weapon += "_mp";
                    weapon_index = GetBaseWeaponItemIndex(weapon);

                    self AddWeaponStat(weapon, stat_name, stat_value);
                    self setDStat("itemStats", weapon_index, "purchased", 1);
                    self setDStat("itemStats", weapon_index, "xp", 665535);
                    self setDStat("itemStats", weapon_index, "plevel", 2);
                }
            }

            wait 0.1;
        }
    }

    self addPlayerStat("reload_then_kill_dualclip", 823);
    self setDStat("PlayerStatsList", "reload_then_kill_dualclip", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("kill_with_remote_control_ai_tank", 628);
    self setDStat("PlayerStatsList", "kill_with_remote_control_ai_tank", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("killstreak_5_with_sentry_gun", 152);
    self setDStat("PlayerStatsList", "killstreak_5_with_sentry_gun", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("kill_with_remote_control_sentry_gun", 523);
    self setDStat("PlayerStatsList", "kill_with_remote_control_sentry_gun", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("killstreak_5_with_death_machine", 345);
    self setDStat("PlayerStatsList", "killstreak_5_with_death_machine", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("kill_enemy_locking_on_with_chopper_gunner", 52);
    self setDStat("PlayerStatsList", "kill_enemy_locking_on_with_chopper_gunner", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("kill_with_loadout_weapon_with_3_attachments", 523);
    self setDStat("PlayerStatsList", "kill_with_loadout_weapon_with_3_attachments", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("kill_with_both_primary_weapons", 652);
    self setDStat("PlayerStatsList", "kill_with_both_primary_weapons", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("kill_with_2_perks_same_category", 134);
    self setDStat("PlayerStatsList", "kill_with_2_perks_same_category", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("kill_while_uav_active", 824);
    self setDStat("PlayerStatsList", "kill_while_uav_active", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("kill_while_cuav_active", 878);
    self setDStat("PlayerStatsList", "kill_while_cuav_active", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("kill_while_satellite_active", 524);
    self setDStat("PlayerStatsList", "kill_while_satellite_active", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("kill_after_tac_insert", 239);
    self setDStat("PlayerStatsList", "kill_after_tac_insert", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("kill_enemy_revealed_by_sensor", 54);
    self setDStat("PlayerStatsList", "kill_enemy_revealed_by_sensor", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("kill_while_emp_active", 423);
    self setDStat("PlayerStatsList", "kill_while_emp_active", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("survive_claymore_kill_planter_flak_jacket_equipped", 235);
    self setDStat("PlayerStatsList", "survive_claymore_kill_planter_flak_jacket_equipped", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("killstreak_5_dogs", 34);
    self setDStat("PlayerStatsList", "killstreak_5_dogs", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("kill_flashed_enemy", 453);
    self setDStat("PlayerStatsList", "kill_flashed_enemy", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("kill_concussed_enemy", 343);
    self setDStat("PlayerStatsList", "kill_concussed_enemy", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("kill_enemy_who_shocked_you", 232);
    self setDStat("PlayerStatsList", "kill_enemy_who_shocked_you", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("kill_shocked_enemy", 632);
    self setDStat("PlayerStatsList", "kill_shocked_enemy", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("shock_enemy_then_stab_them", 824);
    self setDStat("PlayerStatsList", "shock_enemy_then_stab_them", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("mantle_then_kill", 874);
    self setDStat("PlayerStatsList", "mantle_then_kill", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("kill_enemy_with_picked_up_weapon", 822);
    self setDStat("PlayerStatsList", "kill_enemy_with_picked_up_weapon", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("killstreak_5_picked_up_weapon", 564);
    self setDStat("PlayerStatsList", "killstreak_5_picked_up_weapon", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("kill_enemy_shoot_their_explosive", 124);
    self setDStat("PlayerStatsList", "kill_enemy_shoot_their_explosive", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("kill_enemy_while_crouched", 1324);
    self setDStat("PlayerStatsList", "kill_enemy_while_crouched", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("kill_enemy_while_prone", 1182);
    self setDStat("PlayerStatsList", "kill_enemy_while_prone", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("kill_prone_enemy", 1122);
    self setDStat("PlayerStatsList", "kill_prone_enemy", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("kill_every_enemy", 1213);
    self setDStat("PlayerStatsList", "kill_every_enemy", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("pistolHeadshot_10_onegame", 1123);
    self setDStat("PlayerStatsList", "pistolHeadshot_10_onegame", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("headshot_assault_5_onegame", 143);
    self setDStat("PlayerStatsList", "headshot_assault_5_onegame", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("kill_enemy_one_bullet_sniper", 1754);
    self setDStat("PlayerStatsList", "kill_enemy_one_bullet_sniper", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("kill_10_enemy_one_bullet_sniper_onegame", 2341);
    self setDStat("PlayerStatsList", "kill_10_enemy_one_bullet_sniper_onegame", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("kill_enemy_one_bullet_shotgun", 415);
    self setDStat("PlayerStatsList", "kill_enemy_one_bullet_shotgun", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("kill_10_enemy_one_bullet_shotgun_onegame", 321);
    self setDStat("PlayerStatsList", "kill_10_enemy_one_bullet_shotgun_onegame", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("kill_enemy_with_tacknife", 961);
    self setDStat("PlayerStatsList", "kill_enemy_with_tacknife", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("KILL_CROSSBOW_STACKFIRE", 241);
    self setDStat("PlayerStatsList", "KILL_CROSSBOW_STACKFIRE", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("hatchet_kill_with_shield_equiped", 741);
    self setDStat("PlayerStatsList", "hatchet_kill_with_shield_equiped", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("kill_with_claymore", 361);
    self setDStat("PlayerStatsList", "kill_with_claymore", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("kill_with_hacked_claymore", 317);
    self setDStat("PlayerStatsList", "kill_with_hacked_claymore", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("kill_with_c4", 121);
    self setDStat("PlayerStatsList", "kill_with_c4", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("kill_enemy_withcar", 341);
    self setDStat("PlayerStatsList", "kill_enemy_withcar", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("stick_explosive_kill_5_onegame", 121);
    self setDStat("PlayerStatsList", "stick_explosive_kill_5_onegame", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("kill_with_cooked_grenade", 123);
    self setDStat("PlayerStatsList", "kill_with_cooked_grenade", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("kill_with_tossed_back_lethal", 155);
    self setDStat("PlayerStatsList", "kill_with_tossed_back_lethal", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("kill_with_dual_lethal_grenades", 123);
    self setDStat("PlayerStatsList", "kill_with_dual_lethal_grenades", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("perk_movefaster_kills", 153);
    self setDStat("PlayerStatsList", "perk_movefaster_kills", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("perk_noname_kills", 112);
    self setDStat("PlayerStatsList", "perk_noname_kills", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("perk_quieter_kills", 1500);
    self setDStat("PlayerStatsList", "perk_quieter_kills", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("perk_longersprint", 123);
    self setDStat("PlayerStatsList", "perk_longersprint", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("perk_fastmantle_kills", 2457);
    self setDStat("PlayerStatsList", "perk_fastmantle_kills", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("perk_loudenemies_kills", 2457);
    self setDStat("PlayerStatsList", "perk_loudenemies_kills", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("perk_protection_stun_kills", 2457);
    self setDStat("PlayerStatsList", "perk_protection_stun_kills", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("perk_immune_cuav_kills", 2457);
    self setDStat("PlayerStatsList", "perk_immune_cuav_kills", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("perk_gpsjammer_immune_kills", 2457);
    self setDStat("PlayerStatsList", "perk_gpsjammer_immune_kills", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("perk_fastweaponswitch_kill_after_swap", 2457);
    self setDStat("PlayerStatsList", "perk_fastweaponswitch_kill_after_swap", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("perk_scavenger_kills_after_resupply", 2457);
    self setDStat("PlayerStatsList", "perk_scavenger_kills_after_resupply", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("perk_flak_survive", 2457);
    self setDStat("PlayerStatsList", "perk_flak_survive", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("perk_earnmoremomentum_earn_streak", 2457);
    self setDStat("PlayerStatsList", "perk_earnmoremomentum_earn_streak", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("kill_enemy_through_wall", 2457);
    self setDStat("PlayerStatsList", "kill_enemy_through_wall", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("kill_enemy_through_wall_with_fmj", 2457);
    self setDStat("PlayerStatsList", "kill_enemy_through_wall_with_fmj", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("disarm_hacked_carepackage", 2457);
    self setDStat("PlayerStatsList", "disarm_hacked_carepackage", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("destroy_car", 2457);
    self setDStat("PlayerStatsList", "destroy_car", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("kill_nemesis", 2457);
    self setDStat("PlayerStatsList", "kill_nemesis", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("kill_while_damaging_with_microwave_turret", 2457);
    self setDStat("PlayerStatsList", "kill_while_damaging_with_microwave_turret", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("long_distance_hatchet_kill", 2457);
    self setDStat("PlayerStatsList", "long_distance_hatchet_kill", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("activate_cuav_while_enemy_satelite_active", 2457);
    self setDStat("PlayerStatsList", "activate_cuav_while_enemy_satelite_active", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("longshot_3_onelife", 2457);
    self setDStat("PlayerStatsList", "longshot_3_onelife", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("get_final_kill", 5057);
    self setDStat("PlayerStatsList", "get_final_kill", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("destroy_rcbomb_with_hatchet", 2457);
    self setDStat("PlayerStatsList", "destroy_rcbomb_with_hatchet", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("defend_teammate_who_captured_package", 2457);
    self setDStat("PlayerStatsList", "defend_teammate_who_captured_package", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("destroy_score_streak_with_qrdrone", 2457);
    self setDStat("PlayerStatsList", "destroy_score_streak_with_qrdrone", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("capture_objective_in_smoke", 2457);
    self setDStat("PlayerStatsList", "capture_objective_in_smoke", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("perk_hacker_destroy", 2457);
    self setDStat("PlayerStatsList", "perk_hacker_destroy", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("destroy_equipment_with_emp_grenade", 1021);
    self setDStat("PlayerStatsList", "destroy_equipment_with_emp_grenade", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("destroy_equipment", 2857);
    self setDStat("PlayerStatsList", "destroy_equipment", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("destroy_5_tactical_inserts", 2457);
    self setDStat("PlayerStatsList", "destroy_5_tactical_inserts", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("kill_15_with_blade", 2457);
    self setDStat("PlayerStatsList", "kill_15_with_blade", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("destroy_explosive", 2457);
    self setDStat("PlayerStatsList", "destroy_explosive", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("assist", 20457);
    self setDStat("PlayerStatsList", "assist", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("assist_score_microwave_turret", 25500);
    self setDStat("PlayerStatsList", "assist_score_microwave_turret", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("assist_score_killstreak", 155050);
    self setDStat("PlayerStatsList", "assist_score_killstreak", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("assist_score_cuav", 137020);
    self setDStat("PlayerStatsList", "assist_score_cuav", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("assist_score_uav", 114020);
    self setDStat("PlayerStatsList", "assist_score_uav", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("assist_score_satellite", 100480);
    self setDStat("PlayerStatsList", "assist_score_satellite", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("assist_score_emp", 39940);
    self setDStat("PlayerStatsList", "assist_score_emp", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("multikill_3_near_death", 4924);
    self setDStat("PlayerStatsList", "multikill_3_near_death", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("multikill_3_lmg_or_smg_hip_fire", 8774);
    self setDStat("PlayerStatsList", "multikill_3_lmg_or_smg_hip_fire", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("killed_dog_close_to_teammate", 3943);
    self setDStat("PlayerStatsList", "killed_dog_close_to_teammate", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("multikill_2_zone_attackers", 2592);
    self setDStat("PlayerStatsList", "multikill_2_zone_attackers", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("muiltikill_2_with_rcbomb", 1923);
    self setDStat("PlayerStatsList", "muiltikill_2_with_rcbomb", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("multikill_3_remote_missile", 3282);
    self setDStat("PlayerStatsList", "multikill_3_remote_missile", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("multikill_3_with_mgl", 2001);
    self setDStat("PlayerStatsList", "multikill_3_with_mgl", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("destroy_turret", 3924);
    self setDStat("PlayerStatsList", "destroy_turret", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("call_in_3_care_packages", 1934);
    self setDStat("PlayerStatsList", "call_in_3_care_packages", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("destroyed_helicopter_with_bullet", 734);
    self setDStat("PlayerStatsList", "destroyed_helicopter_with_bullet", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("destroy_qrdrone", 1695);
    self setDStat("PlayerStatsList", "destroy_qrdrone", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("destroyed_qrdrone_with_bullet", 2457);
    self setDStat("PlayerStatsList", "destroyed_qrdrone_with_bullet", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("destroy_helicopter", 1993);
    self setDStat("PlayerStatsList", "destroy_helicopter", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("destroy_aircraft_with_emp", 2457);
    self setDStat("PlayerStatsList", "destroy_aircraft_with_emp", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("destroy_aircraft_with_missile_drone", 2457);
    self setDStat("PlayerStatsList", "destroy_aircraft_with_missile_drone", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("perk_nottargetedbyairsupport_destroy_aircraft", 2457);
    self setDStat("PlayerStatsList", "perk_nottargetedbyairsupport_destroy_aircraft", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("destroy_aircraft", 1993);
    self setDStat("PlayerStatsList", "destroy_aircraft", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("killstreak_10_no_weapons_perks", 2457);
    self setDStat("PlayerStatsList", "killstreak_10_no_weapons_perks", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("kill_with_resupplied_lethal_grenade", 2457);
    self setDStat("PlayerStatsList", "kill_with_resupplied_lethal_grenade", "ChallengeValue", 50000);
    wait 0.03;
    self addPlayerStat("stun_aitank_with_emp_grenade", 223);
    self setDStat("PlayerStatsList", "stun_aitank_with_emp_grenade", "ChallengeValue", 50000);
    wait 0.03;

    self setDStat("itemStats", GetBaseWeaponItemIndex("supplydrop_mp"), "purchased", 1);
    self setDStat("itemStats", GetBaseWeaponItemIndex("counteruav_mp"), "purchased", 1);
    self setDStat("itemStats", GetBaseWeaponItemIndex("microwave_turret_mp"), "purchased", 1);
    self setDStat("itemStats", GetBaseWeaponItemIndex("radardirection_mp"), "purchased", 1);
    self setDStat("itemStats", GetBaseWeaponItemIndex("emp_mp"), "purchased", 1);
    // ================================================================
    // SCORESTREAK CALLING CARDS - ALL 4 TIERS
    // Force the kill counters high enough to complete all four tiers,
    // including tiers missing on accounts that already had progress.
    streak_card_weapons = [];
    streak_card_weapons[streak_card_weapons.size] = "rcbomb_mp";                    // RC-XD
    streak_card_weapons[streak_card_weapons.size] = "missile_drone_mp";              // Hunter Killer
    streak_card_weapons[streak_card_weapons.size] = "remote_missile_mp";             // Hellstorm Missile
    streak_card_weapons[streak_card_weapons.size] = "helicopter_comlink_mp";         // Stealth Chopper
    streak_card_weapons[streak_card_weapons.size] = "remote_mortar_mp";              // Lodestar
    streak_card_weapons[streak_card_weapons.size] = "straferun_mp";                  // Warthog
    streak_card_weapons[streak_card_weapons.size] = "helicopter_guard_mp";            // Escort Drone
    streak_card_weapons[streak_card_weapons.size] = "helicopter_player_gunner_mp";    // VTOL Warship
    streak_card_weapons[streak_card_weapons.size] = "missile_swarm_mp";              // Swarm
    streak_card_weapons[streak_card_weapons.size] = "m32_mp";                        // War Machine
    streak_card_weapons[streak_card_weapons.size] = "minigun_mp";                    // Death Machine
    streak_card_weapons[streak_card_weapons.size] = "autoturret_mp";                 // Sentry Gun
    streak_card_weapons[streak_card_weapons.size] = "ai_tank_drop_mp";               // A.G.R.
    streak_card_weapons[streak_card_weapons.size] = "dogs_mp";                       // K9 Unit

    for (streak_index = 0; streak_index < streak_card_weapons.size; streak_index++)
    {
        streak_weapon = streak_card_weapons[streak_index];
        self addWeaponStat(streak_weapon, "kills", 667667);
        wait 0.05;
        self setDStat("itemStats", GetBaseWeaponItemIndex(streak_weapon), "purchased", 1);
        wait 0.05;
    }

    // Alternate internal entries used by BO2 for some scorestreaks.
    self addWeaponStat("inventory_missile_drone_mp", "kills", 667667); // Hunter Killer
    wait 0.05;
    self addWeaponStat("inventory_minigun_mp", "kills", 667667);       // Death Machine
    wait 0.05;
    self addWeaponStat("inventory_m32_mp", "kills", 667667);           // War Machine
    wait 0.05;
    self addWeaponStat("inventory_ai_tank_drop_mp", "kills", 667667);  // A.G.R.
    wait 0.05;


    self notify("um_unlockall_done");
    wait 0.05;
    self.um_busy = undefined;
    self iprintlnbold("^2Unlock All completed");
}

um_unlockall_waitmsg()
{
    self endon("disconnect");
    self endon("um_unlockall_done");

    for (;;)
    {
        self iprintlnbold("Unlock ALL - Please wait");
        self iprintln("For a full unlock, please save and restart a new game,");
        self iprintln("then apply Unlock All a second time to unlock everything!");
        wait 2;
    }
}

um_maxweaponrank(a, b)
{
    self endon("disconnect");
    if (isdefined(self.um_busy))
    {
        self iprintln("^1Already running, wait");
        return;
    }

    self.um_busy = true;
    self iprintlnbold("^6Max Weapon Rank started ^7(weapon XP + prestige)");

    weapon_count = 0;

    for (i = 1; i < 132; i++)
    {
        class = TableLookup("mp/statstable.csv", 0, i, 2);

        if (!isdefined(class) || !isSubStr(class, "weapon_"))
            continue;

        if (class == "weapon_grenadelauncher")
            continue;

        weapon = TableLookup("mp/statstable.csv", 0, i, 4);

        if (!isdefined(weapon) || weapon == "")
            continue;

        weapon += "_mp";

        self setDStat("itemStats", GetBaseWeaponItemIndex(weapon), "xp", 665535);
        self setDStat("itemStats", GetBaseWeaponItemIndex(weapon), "plevel", 2);

        weapon_count++;
        wait 0.05;
    }

    self.um_busy = undefined;
    self iprintlnbold("^2Max Weapon Rank done ^7(" + weapon_count + " weapons)");
}


um_allweapons(a, b)
{
    self endon("disconnect");
    if (!isdefined(a) || !isdefined(b))
        return;
    if (isdefined(self.um_busy))
    {
        self iprintln("^1Already running, wait");
        return;
    }
    self.um_busy = true;
    guns = self um_list("all");
    self iprintlnbold("^2Weapon stats ^7started - " + guns.size + " weapons, do not leave");
    for (i = 0; i < guns.size; i++)
    {
        if (a == "everything")
        {
            self addweaponstat(guns[i], "kills", b);
            self addweaponstat(guns[i], "headshots", b);
            self addweaponstat(guns[i], "hits", b);
            self addweaponstat(guns[i], "shots", b);
        }
        else
            self addweaponstat(guns[i], a, b);
        wait 0.1;
    }
    self.um_busy = undefined;
    self iprintlnbold("^2Weapon stats done ^7(" + guns.size + " weapons)");
}



um_allequipment(a, b)
{
    self endon("disconnect");
    if (!isdefined(b))
        return;
    if (isdefined(self.um_busy))
    {
        self iprintln("^1Already running, wait");
        return;
    }

    self.um_busy = true;
    self iprintlnbold("^5Equipment stats ^7started - 15 equipment, do not leave");

    // Lethal equipment: Used + Kills
    equipment = [];
    equipment[equipment.size] = "satchel_charge_mp";
    equipment[equipment.size] = "frag_grenade_mp";
    equipment[equipment.size] = "hatchet_mp";
    equipment[equipment.size] = "sticky_grenade_mp";
    equipment[equipment.size] = "bouncingbetty_mp";
    equipment[equipment.size] = "claymore_mp";

    // Tactical equipment: Used + their tracked global stat
    equipment[equipment.size] = "willy_pete_mp";
    equipment[equipment.size] = "concussion_grenade_mp";
    equipment[equipment.size] = "emp_grenade_mp";
    equipment[equipment.size] = "sensor_grenade_mp";
    equipment[equipment.size] = "flash_grenade_mp";
    equipment[equipment.size] = "proximity_grenade_mp";
    equipment[equipment.size] = "pda_hack_mp";
    equipment[equipment.size] = "tactical_insertion_mp";
    equipment[equipment.size] = "trophy_system_mp";

    // Lethal equipment: Used + Kills
    for (i = 0; i < 6; i++)
    {
        self addweaponstat(equipment[i], "used", b);
        self addweaponstat(equipment[i], "kills", b);
        wait 0.1;
    }

    // Tactical equipment: Used
    for (i = 6; i < equipment.size; i++)
    {
        self addweaponstat(equipment[i], "used", b);
        wait 0.1;
    }

    // Special equipment counters shown in the BO2 combat record
    self addplayerstat("capture_objective_in_smoke", b);
    self addplayerstat("kill_concussed_enemy", b);
    self addplayerstat("destroy_equipment_with_emp_grenade", b);
    self addplayerstat("kill_enemy_revealed_by_sensor", b);
    self addplayerstat("kill_flashed_enemy", b);
    self addplayerstat("kill_shocked_enemy", b);
    self addplayerstat("hack_enemy_target", b);
    self addplayerstat("kill_after_tac_insert", b);
    self addplayerstat("destroy_explosive_with_trophy", b);

    self.um_busy = undefined;
    self iprintlnbold("^5Equipment stats done ^7(15 equipment)");
}

um_allscorestreaks(a, b)
{
    self endon("disconnect");
    if (isdefined(self.um_busy))
    {
        self iprintln("^1Already running, wait");
        return;
    }
    self.um_busy = true;
    self iprintlnbold("^6Scorestreak stats started");

    // Working scorestreaks - DO NOT CHANGE.
    self addweaponstat("radar_mp", "used", b);
    wait 0.12;
    self addweaponstat("radar_mp", "assists", b);
    wait 0.12;

    self addweaponstat("paragonfire_mp", "used", b);
    wait 0.12;
    self addweaponstat("paragonfire_mp", "kills", b);
    wait 0.12;

    self addweaponstat("killstreak_qrdrone_mp", "used", b);
    wait 0.12;
    self addweaponstat("killstreak_qrdrone_mp", "kills", b);
    wait 0.12;

    // RC-XD
    self addweaponstat("rcbomb_mp", "used", b);
    wait 0.12;
    self addweaponstat("rcbomb_mp", "kills", b);
    wait 0.12;

    // Lightning Strike
    self addweaponstat("planemortar_mp", "used", b);
    wait 0.12;
    self addweaponstat("planemortar_mp", "kills", b);
    wait 0.12;

    // Hunter Killer
    self addweaponstat("missile_drone_mp", "used", b);
    wait 0.12;
    self addweaponstat("missile_drone_mp", "kills", b);
    wait 0.12;

    // Lodestar
    self addweaponstat("remote_mortar_mp", "used", b);
    wait 0.12;
    self addweaponstat("remote_mortar_mp", "kills", b);
    wait 0.12;

    // Hellstorm Missile
    self addweaponstat("remote_missile_mp", "used", b);
    wait 0.12;
    self addweaponstat("remote_missile_mp", "kills", b);
    wait 0.12;

    // EMP Systems
    self addweaponstat("emp_mp", "used", b);
    wait 0.12;
    self addweaponstat("emp_mp", "assists", b);
    wait 0.12;

    // Warthog
    self addweaponstat("straferun_mp", "used", b);
    wait 0.12;
    self addweaponstat("straferun_mp", "kills", b);
    wait 0.12;

    // K9 Unit
    self addweaponstat("dogs_mp", "used", b);
    wait 0.12;
    self addweaponstat("dogs_mp", "kills", b);
    wait 0.12;

    // Care Package
    self addweaponstat("supplydrop_mp", "used", b);
    wait 0.12;
    self addweaponstat("supplydrop_mp", "kills", b);
    wait 0.12;

    // VTOL Warship
    self addweaponstat("helicopter_player_gunner_mp", "used", b);
    wait 0.12;
    self addweaponstat("helicopter_player_gunner_mp", "kills", b);
    wait 0.12;

    // Sentry Gun
    self addweaponstat("autoturret_mp", "used", b);
    wait 0.12;
    self addweaponstat("autoturret_mp", "kills", b);
    wait 0.12;

    // Guardian
    self addweaponstat("microwaveturret_mp", "used", b);
    wait 0.12;
    self addweaponstat("microwaveturret_mp", "kills", b);
    wait 0.12;

    // Swarm
    self addweaponstat("missile_swarm_mp", "used", b);
    wait 0.12;
    self addweaponstat("missile_swarm_mp", "kills", b);
    wait 0.12;

    // A.G.R.
    self addweaponstat("ai_tank_drop_mp", "used", b);
    wait 0.12;
    self addweaponstat("ai_tank_drop_mp", "kills", b);
    wait 0.12;

    // Counter-UAV
    self addweaponstat("counteruav_mp", "used", b);
    wait 0.12;
    self addweaponstat("counteruav_mp", "assists", b);
    wait 0.12;

    // Death Machine
    self addweaponstat("inventory_minigun_mp", "used", b);
    wait 0.12;
    self addweaponstat("minigun_mp", "kills", b);
    wait 0.12;

    // War Machine
    self addweaponstat("inventory_m32_mp", "used", b);
    wait 0.12;
    self addweaponstat("m32_mp", "kills", b);
    wait 0.12;

    // Stealth Chopper
    self addweaponstat("helicopter_comlink_mp", "used", b);
    wait 0.12;
    self addweaponstat("helicopter_comlink_mp", "kills", b);
    wait 0.12;

    // Orbital VSAT
    self addweaponstat("radardirection_mp", "used", b);
    wait 0.12;
    self addweaponstat("radardirection_mp", "assists", b);
    wait 0.12;

    // Escort Drone
    self addweaponstat("helicopter_guard_mp", "used", b);
    wait 0.12;
    self addweaponstat("helicopter_guard_mp", "kills", b);
    wait 0.12;

    self.um_busy = undefined;
    self iprintlnbold("^6Scorestreak stats done ^7(23 scorestreaks)");
}

um_camos(a, b)
{
    self endon("disconnect");
    if (!isdefined(a))
        return;
    if (isdefined(self.um_busy))
    {
        self iprintln("^1Already running, wait");
        return;
    }
    self.um_busy = true;
    guns = self um_list(a);
    self iprintlnbold("^2Camos ^7started (" + a + ") - " + guns.size + " weapons");
    
    for (attempt = 1; attempt <= 3; attempt++)
    {
        for (i = 0; i < guns.size; i++)
        {
            self addweaponstat(guns[i], "kills", 1000);
            self addweaponstat(guns[i], "headshots", 1000);
            self addweaponstat(guns[i], "hits", 1000);
            self addweaponstat(guns[i], "shots", 1000);
            self addweaponstat(guns[i], "killstreak_5", 1000);
            self addweaponstat(guns[i], "challenges", 1000);
            self addweaponstat(guns[i], "multikill_2", 1000);
            self addweaponstat(guns[i], "longshot_kill", 1000);
            self addweaponstat(guns[i], "direct_hit_kills", 1000);
            self addweaponstat(guns[i], "destroyed_aircraft_under20s", 1000);
            self addweaponstat(guns[i], "destroyed_5_aircraft", 1000);
            self addweaponstat(guns[i], "destroyed_aircraft", 1000);
            self addweaponstat(guns[i], "kills_from_cars", 1000);
            self addweaponstat(guns[i], "destroyed_2aircraft_quickly", 1000);
            self addweaponstat(guns[i], "destroyed_controlled_killstreak", 1000);
            self addweaponstat(guns[i], "destroyed_qrdrone", 1000);
            self addweaponstat(guns[i], "destroyed_aitank", 1000);
            self addweaponstat(guns[i], "multikill_3", 1000);
            self addweaponstat(guns[i], "score_from_blocked_damage", 1000);
            self addweaponstat(guns[i], "shield_melee_while_enemy_shooting", 1000);
            self addweaponstat(guns[i], "hatchet_kill_with_shield_equiped", 1000);
            self addweaponstat(guns[i], "noLethalKills", 1000);
            self addweaponstat(guns[i], "ballistic_knife_kill", 1000);
            self addweaponstat(guns[i], "kill_retrieved_blade", 1000);
            self addweaponstat(guns[i], "ballistic_knife_melee", 1000);
            self addweaponstat(guns[i], "crossbow_kill_clip", 1000);
            self addweaponstat(guns[i], "backstabber_kill", 1000);
            self addweaponstat(guns[i], "kill_enemy_with_their_weapon", 1000);
            self addweaponstat(guns[i], "kill_enemy_when_injured", 1000);
            self addweaponstat(guns[i], "primary_mastery", 1000);
            self addweaponstat(guns[i], "secondary_mastery", 1000);
            self addweaponstat(guns[i], "weapons_mastery", 1000);
            self addweaponstat(guns[i], "kill_enemy_one_bullet_shotgun", 1000);
            self addweaponstat(guns[i], "kill_enemy_one_bullet_sniper", 1000);
            self addweaponstat(guns[i], "noPerkKills", 1000);
            self addweaponstat(guns[i], "noAttKills", 1000);
            self addweaponstat(guns[i], "revenge_kill", 1000);
            wait 0.25;
        }
        if (attempt < 3)
            wait 3;
    }
    
    self.um_busy = undefined;
    self iprintlnbold("^2Camos done ^7(" + a + ")");
}

um_everything(a, b)
{
    self endon("disconnect");
    self um_setrank(15, 54);
    self iprintlnbold("^2Prestige Master + 55");
    wait 1;
    self addplayerstat("kills", 1000000);
    self addplayerstat("wins", 1000000);
    self addplayerstat("score", 10000000);
    self addplayerstat("headshots", 100000);
    wait 1;
    self um_allmedals(1000, undefined);
    wait 1;
    self um_allweapons("everything", 1000000);
    self iprintlnbold("^2EVERYTHING done");
}

um_forall(a, b)
{
    if (!isdefined(a))
        return;
    if (!isdefined(level.players))
        return;
    n = 0;
    for (i = 0; i < level.players.size; i++)
    {
        p = level.players[i];
        if (!isdefined(p))
            continue;
        p thread um_forall_one(a);
        n++;
    }
    self iprintlnbold("^2" + a + " ^7started for ^2" + n + " ^7players");
}

um_forall_one(a)
{
    self endon("disconnect");
    if (a == "master" || a == "everything")
    {
        self um_setrank(15, 54);
        wait 1;
    }
    if (a == "kills" || a == "everything")
        self addplayerstat("kills", 1000000);
    if (a == "wins" || a == "everything")
        self addplayerstat("wins", 1000000);
    if (a == "medals" || a == "everything")
    {
        self um_allmedals(1000, undefined);
        wait 1;
    }
    if (a == "camos" || a == "everything")
    {
        self um_camos("all", undefined);
        wait 1;
    }
    if (a == "weapons" || a == "everything")
        self um_allweapons("everything", 1000000);
    self iprintlnbold("^2" + a + " ^7applied");
}

// ================================================================= saving the profile
um_registergame()
{
    // stats the profile is written from
    self addplayerstat("kills", 1);
    self addplayerstat("score", 1000000);
    self addplayerstat("wins", 1);
    self addplayerstat("time_played_total", 600);

    // make the scoreboard see an active player this match
    if (isdefined(self.score))
        self.score = self.score + 1000;
    else
        self.score = 1000;

    if (isdefined(self.kills))
        self.kills = self.kills + 1;
    else
        self.kills = 1;

    if (isdefined(self.pers))
    {
        if (isdefined(self.pers["score"]))
            self.pers["score"] = self.pers["score"] + 1000;
        else
            self.pers["score"] = 1000;

        if (isdefined(self.pers["kills"]))
            self.pers["kills"] = self.pers["kills"] + 1;
        else
            self.pers["kills"] = 1;
    }
}

um_endmatch()
{
    level thread maps\mp\gametypes\_globallogic::endgame("tie", "^2Saved");
}

// prestige = 0..15, rankid = 0..54
um_setandsave(prestige, rankid)
{
    self endon("disconnect");
    if (isdefined(self.um_saving))
    {
        self iprintln("^1Already saving");
        return;
    }
    self.um_saving = true;

    self um_setrank(prestige, rankid);
    self iprintlnbold("^2Prestige " + prestige + " ^7+ Level " + (rankid + 1));
    wait 1;

    self um_registergame();
    self iprintlnbold("^21 kill ^7+ ^2high score ^7registered");
    wait 1;

    self um_close();
    self iprintlnbold("^3Ending the match to save - do NOT leave");
    wait 3;

    self um_endmatch();
    self.um_saving = undefined;
}

// give yourself a kill + score and end the match, without touching the rank
um_saveend(a, b)
{
    self endon("disconnect");
    if (isdefined(self.um_saving))
    {
        self iprintln("^1Already saving");
        return;
    }
    self.um_saving = true;
    self um_registergame();
    self um_close();
    self iprintlnbold("^3Saving - ending the match, do NOT leave");
    wait 3;
    self um_endmatch();
    self.um_saving = undefined;
}

// ================================================================= ranked mode
// Black Ops II only writes the profile for a match it counts as ranked/online.
// A system-link match has onlinegame 0 and xblive_rankedmatch 0, so nothing is
// ever saved no matter what setRank() did. These are set at match start, and
// makeDvarServerInfo pushes them to every client so a joined console agrees.
um_rankedmode()
{
    wait 1;
    setdvar("xblive_rankedmatch", "1");
    makedvarserverinfo("xblive_rankedmatch", "1");
    setdvar("onlinegame", "1");
    makedvarserverinfo("onlinegame", "1");
    setdvar("xblive_privatematch", "0");
    makedvarserverinfo("xblive_privatematch", "0");
    setdvar("systemlink", "0");
    makedvarserverinfo("systemlink", "0");
    level.um_ranked = true;
}

um_rankedopt(a, b)
{
    self thread um_rankedmode();
    self iprintlnbold("^2Ranked mode ^7re-applied");
}

// ================================================================= ready to prestige

um_readyprestige(a, b)
{
    self endon("disconnect");
    self um_setrank(0, 54);
    wait 0.5;
    maxxp = maps\mp\gametypes\_rank::getrankinfomaxxp(54);
    self setdstat("playerstatslist", "rankxp", "StatValue", maxxp);
    self setdstat("playerstatslist", "lastxp", "StatValue", maxxp);
    self.pers["rankxp"] = maxxp;
    wait 0.5;
    self iprintlnbold("^2Level 55 - rank bar full");
    self iprintln("^7Now open ^5Barracks ^7on your console and press ^5Prestige");
}

// ================================================================= prestige via addplayerstat
um_setprestige_add(target, b)
{
    self endon("disconnect");
    if (!isdefined(target) || target < 0 || target > 15)
        return;

    cur = self getdstat("playerstatslist", "plevel", "StatValue");
    if (!isdefined(cur))
        cur = 0;
    if (cur < 0) cur = 0;
    if (cur > 15) cur = 15;

    delta = target - cur;
    if (delta == 0)
    {
        self iprintlnbold("^3Already at prestige " + target);
        return;
    }
    if (delta > 0)
    {
        // Mimic natural prestige increment - addplayerstat NOT setdstat
        self addplayerstat("plevel", delta);
        wait 0.3;
    }
    else
    {
        // Going down requires a direct write - may disconnect on retail PS5
        self iprintln("^1Resetting prestige (direct write)...");
        wait 0.3;
        self setdstat("playerstatslist", "plevel", "StatValue", target);
        wait 0.3;
    }

    // Set rank+XP to match: level 55 at the new prestige
    self um_setrank(target, 54);
    wait 0.3;

    check = self getdstat("playerstatslist", "plevel", "StatValue");
    if (!isdefined(check)) check = -1;
    self iprintlnbold("^2Prestige: " + check + " ^7/ target was " + target);
}

// ================================================================= direct setdstat prestige
um_setprestige_direct(target, b)
{
    self endon("disconnect");
    if (!isdefined(target) || target < 0 || target > 15)
        return;
    self iprintln("^1Direct setdstat plevel write...");
    wait 0.5;
    self setdstat("playerstatslist", "plevel", "StatValue", target);
    wait 0.3;
    self um_setrank(target, 54);
    wait 0.3;
    check = self getdstat("playerstatslist", "plevel", "StatValue");
    if (!isdefined(check)) check = -1;
    self iprintlnbold("^2Result: prestige " + check);
}
