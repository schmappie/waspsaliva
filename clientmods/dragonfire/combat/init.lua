local placed_crystal
local switched_to_totem = 0
local used_sneak = true
local totem_move_action = InventoryAction("move")
totem_move_action:to("current_player", "main", 9)

minetest.register_list_command("friend", "Configure Friend List (friends dont get attacked by Killaura or Forcefield)", "friendlist")

minetest.register_globalstep(function(dtime)
	local player = minetest.localplayer
	if not player then return end
	local control = player:get_control()
	local pointed = minetest.get_pointed_thing()
	local item = player:get_wielded_item():get_name()
	if minetest.settings:get_bool("killaura") or minetest.settings:get_bool("forcefield") and control.dig then
		local friendlist = minetest.settings:get("friendlist"):split(",")
		for _, obj in ipairs(minetest.get_objects_inside_radius(player:get_pos(), 5)) do
			local do_attack = true
			if obj:is_local_player() then
				do_attack = false
			else
				for _, friend in ipairs(friendlist) do
					if obj:get_name() == friend or obj:get_nametag() == friend then
						do_attack = false
						break
					end
				end
			end
			if do_attack then
				obj:punch()
			end
		end
	elseif minetest.settings:get_bool("crystal_pvp") then
		if placed_crystal then
			if minetest.switch_to_item("mobs_mc:totem") then
				switched_to_totem = 5
			end
			placed_crystal = false
		elseif switched_to_totem > 0 then
			if item ~= "mobs_mc:totem"  then
				switched_to_totem = 0
			elseif pointed and pointed.type == "object" then
				pointed.ref:punch()
				switched_to_totem = 0
			else
				switched_to_totem = switched_to_totem
			end
		elseif control.place and item == "mcl_end:crystal" then
			placed_crystal = true
		elseif control.sneak then
			if pointed and pointed.type == "node" and not used_sneak then
				local pos = minetest.get_pointed_thing_position(pointed)
				local node = minetest.get_node_or_nil(pos)
				if node and (node.name == "mcl_core:obsidian" or node.name == "mcl_core:bedrock") then
					minetest.switch_to_item("mcl_end:crystal")
					minetest.place_node(pos)
					placed_crystal = true
				end	
			end
			used_sneak = true
		else
			used_sneak = false
		end
	end
	
	if minetest.settings:get_bool("autototem") then
		local totem_stack = minetest.get_inventory("current_player").main[9]
		if totem_stack and totem_stack:get_name() ~= "mobs_mc:totem" then
			local totem_index = minetest.find_item("mobs_mc:totem")
			if totem_index then
				totem_move_action:from("current_player", "main", totem_index)
				totem_move_action:apply()
				player:set_wield_index(9)
			end
		end
	end
end)


minetest.register_cheat("Killaura", "Combat", "killaura")
minetest.register_cheat("Forcefield", "Combat", "forcefield")
minetest.register_cheat("CrystalPvP", "Combat", "crystal_pvp")
minetest.register_cheat("AutoTotem", "Combat", "autototem")
