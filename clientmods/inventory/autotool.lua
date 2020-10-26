autotool={}
local odx=nil
function autotool.check_tool(stack, node_groups, old_best_time)
	local toolcaps = stack:get_tool_capabilities()
	if not toolcaps then return end
	local best_time = old_best_time
	for group, groupdef in pairs(toolcaps.groupcaps) do
		local level = node_groups[group]
		if level then
			local this_time = groupdef.times[level]
			if this_time < best_time then
				best_time = this_time
			end
		end
	end
	return best_time < old_best_time, best_time
end


minetest.register_on_punchnode(function(pos, node)
	--minetest.display_chat_message(dump(node))
	if not minetest.settings:get_bool("autotool") then return end
	local player = minetest.localplayer
	local inventory = minetest.get_inventory("current_player")
	local node_groups = minetest.get_node_def(node.name).groups
	local new_index = player:get_wield_index()
	local is_better, best_time = false, math.huge
	is_better, best_time = autotool.check_tool(player:get_wielded_item(), node_groups, best_time)
	for index, stack in pairs(inventory.main) do
		is_better, best_time = autotool.check_tool(stack, node_groups, best_time)
		if is_better then
			new_index = index - 1
		end
	end
	odx=player:get_wield_index()
	player:set_wield_index(new_index)
	minetest.after("0.5",function()
		local nd=minetest.get_node_or_nil(pos)
		if nd.name == "air" then
			minetest.localplayer:set_wield_index(odx)
		end
	end)
end)


minetest.register_cheat("AutoTool", "Inventory", "autotool")
