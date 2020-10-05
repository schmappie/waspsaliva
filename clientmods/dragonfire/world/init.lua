minetest.register_chatcommand("findnodes", {
	description = "Scan for one or multible nodes in a radius around you",
	param = "<radius> <node1>[,<node2>...]",
	func = function(param)
		local radius = tonumber(param:split(" ")[1])
		local nodes = param:split(" ")[2]:split(",")
		local pos = minetest.localplayer:get_pos()
		local fpos = minetest.find_node_near(pos, radius, nodes, true)
		if fpos then
			return true, "Found " .. table.concat(nodes, " or ") .. " at " .. minetest.pos_to_string(fpos)
		end
		return false, "None of " .. table.concat(nodes, " or ") .. " found in a radius of " .. tostring(radius)
	end,
}) 

minetest.register_chatcommand("place", {
	params = "<X>,<Y>,<Z>",
	description = "Place wielded item",
	func = function(param)
		local success, pos = minetest.parse_relative_pos(param)
		if success then
			minetest.place_node(pos)
			return true, "Node placed at " .. minetest.pos_to_string(pos)
		end
		return false, pos
	end,
})

minetest.register_chatcommand("dig", {
	params = "<X>,<Y>,<Z>",
	description = "Dig node",
	func = function(param)
		local success, pos = minetest.parse_relative_pos(param)
		if success then
			minetest.dig_node(pos)
			return true, "Node at " .. minetest.pos_to_string(pos) .. " dug"
		end
		return false, pos
	end,
})

minetest.register_on_dignode(function(pos)
	if minetest.settings:get_bool("replace") then
		minetest.after(0, minetest.place_node, pos)
	end
end)

local etime = 0

minetest.register_globalstep(function(dtime)
	etime = etime + dtime
	if etime < 1 then return end
	local player = minetest.localplayer
	if not player then return end
	local pos = player:get_pos()
	local item = player:get_wielded_item()
	local def = minetest.get_item_def(item:get_name())
	local nodes_per_tick = tonumber(minetest.settings:get("nodes_per_tick")) or 8
	if item and item:get_count() > 0 and def and def.node_placement_prediction ~= "" then
		if minetest.settings:get_bool("scaffold") then
			minetest.place_node(vector.add(pos, {x = 0, y = -0.6, z = 0}))
		elseif minetest.settings:get_bool("highway_z") then
			local z = pos.z
			local positions = {
				{x = 0, y = 0, z = z},
				{x = 1, y = 0, z = z},
				{x = 2, y = 1, z = z},
				{x = -2, y = 1, z = z},
				{x = -2, y = 0, z = z},
				{x = -1, y = 0, z = z},
				{x = 2, y = 0, z = z}
			}
			for i, p in pairs(positions) do
				if i > nodes_per_tick then break end
				minetest.place_node(p)
			end
		elseif minetest.settings:get_bool("block_water") then
			local positions = minetest.find_nodes_near(pos, 5, {"mcl_core:water_source", "mcl_core:water_floating"}, true)
			for i, p in pairs(positions) do
				if i > nodes_per_tick then break end
				minetest.place_node(p)
			end
		elseif minetest.settings:get_bool("autotnt") then
			local positions = minetest.find_nodes_near_under_air_except(pos, 5, item:get_name(), true)
			for i, p in pairs(positions) do
				if i > nodes_per_tick then break end
				minetest.place_node(vector.add(p, {x = 0, y = 1, z = 0}))
			end
		end
	end
end) 

minetest.register_cheat("Scaffold", "World", "scaffold")
minetest.register_cheat("HighwayZ", "World", "highway_z")
minetest.register_cheat("BlockWater", "World", "block_water")
minetest.register_cheat("AutoTNT", "World", "autotnt")
minetest.register_cheat("Replace", "World", "replace")
