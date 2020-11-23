core.cheats = {
	["Combat"] = {
		["Killaura"] = "killaura",
		["AntiKnockback"] = "antiknockback",
		["FastHit"] = "spamclick",
		["AttachmentFloat"] = "float_above_parent",
		["CrystalPvP"] = "crystal_pvp",
		["AutoTotem"] = "autototem",
		["ThroughWalls"] = "dont_point_nodes",
	},
	["Movement"] = {
		["Freecam"] = "freecam",
		["PrivBypass"] = "priv_bypass",
		["AutoForward"] = "continuous_forward",
		["PitchMove"] = "pitch_move",
		["AutoJump"] = "autojump",
		["Jesus"] = "jesus",
		["NoSlow"] = "no_slow",
		["AutoSneak"] = "autosneak",
		["Autosprint"] = 'autosprint',
		["AutoForwSprint"] = 'autofsprint',
		["Jetpack"] = 'jetpack',
	},
	["Render"] = {
		["Xray"] = "xray",
		["Fullbright"] = "fullbright",
		["HUDBypass"] = "hud_flags_bypass",
		["NoHurtCam"] = "no_hurt_cam",
		["BrightNight"] = "no_night",
		["Coords"] = "coords",
		["Tracers"] = "enable_tracers",
		["ESP"] = "enable_esp",
		["Clouds"] = "enable_clouds",
	},
	["World"] = {
		["FastDig"] = "fastdig",
		["FastPlace"] = "fastplace",
		["AutoDig"] = "autodig",
		["AutoPlace"] = "autoplace",
		["InstantBreak"] = "instant_break",
		["IncreasedRange"] = "increase_tool_range",
		["UnlimitedRange"] = "increase_tool_range_plus",
		["PointLiquids"] = "point_liquids",
		["Scaffold"] = "scaffold",
		["ScaffoldPlus"] = "scaffold_plus",
		["BlockWater"] = "block_water",
		["PlaceOnTop"] = "autotnt",
		["Replace"] = "replace",
		["Random SC"] = "randomsc"
	},
	["Exploit"] = {
		["EntitySpeed"] = "entity_speed",
		["ParticleExploit"] = "log_particles",
	},
	["Chat"] = {
		["IgnoreStatus"] = "ignore_status_messages",
		["Deathmessages"] = "mark_deathmessages",
	},
	["Player"] = {
		["NoFallDamage"] = "prevent_natural_damage",
		["NoForceRotate"] = "no_force_rotate",
		["IncreasedRange"] = "increase_tool_range",
		["UnlimitedRange"] = "increase_tool_range_plus",
		["PointLiquids"] = "point_liquids",
		["PrivBypass"] = "priv_bypass",
		["AutoRespawn"] = "autorespawn",
	},
	["Inventory"] = {
		["AutoEject"] = "autoeject",
		["AutoTool"] = "autotool",
		["Enderchest"] = core.open_enderchest,
		["HandSlot"] = core.open_handslot,
		["NextItem"] = "next_item",
	},
}

function core.register_cheat(cheatname, category, func)
	core.cheats[category] = core.cheats[category] or {}
	core.cheats[category][cheatname] = func
end
