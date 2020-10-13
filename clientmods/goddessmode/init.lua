--
-- cora's defensive combat hax

local function mwarp(pos)
	minetest.localplayer:set_pos(pos)
end

local karange=14

local function checkair(pos)
	local n=minetest.get_node_or_nil(pos)
	if n==nil or n['name'] == 'air' then return true end
    return false
end
local function checklava(pos)
    local n=minetest.find_node_near(pos, 2, {'mcl_core:lava_source','mcl_core:lava_flowing'}, true)
    if n == nil then return false end
    return true
end
local function checkgravel(pos)
    local n=minetest.find_node_near(pos, 1, {'mcl_core:gravel','mcl_core:sand'}, true)
    if n == nil then return false end
    return true
end


local function checkarrow()
    for k, v in ipairs(minetest.localplayer.get_nearby_objects(karange)) do
        if ( v:get_item_textures() == "mcl_bows:arrow_box") then
			return true
        end
    end
	return false
end

local function check_tool(stack, node_groups, old_best_time)
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

local function amautotool(pos)
	local player = minetest.localplayer
	local inventory = minetest.get_inventory("current_player")
    local node=minetest.get_node_or_nil(pos)
    if node == nil then return end
	local node_groups = minetest.get_node_def(node.name).groups
	local new_index = player:get_wield_index()
	local is_better, best_time = false, math.huge
		is_better, best_time = check_tool(player:get_wielded_item(), node_groups, best_time)
	is_better, best_time = check_tool(inventory.hand[1], node_groups, best_time)
	for index, stack in pairs(inventory.main) do
		is_better, best_time = check_tool(stack, node_groups, best_time)
		if is_better then
			new_index = index - 1
		end
	end
	player:set_wield_index(new_index)
end
local function get_2dpos_from_yaw(r,yaw)
	local tg={x=0,y=0,z=0}
	tg.x= r * math.sin(yaw)
	tg.z= r * math.cos(yaw)
	return tg
end
local function get_3dpos_from_yaw_and_pitch(r,yaw,pitch)
	local tg={x=0,y=0,z=0}
	tg.x= r * math.sin(yaw)
	tg.y= r * math.sin(pitch)
	tg.z= r * math.cos(yaw)
	return tg
end
local function dhfree()
            if not minetest.localplayer then return end
            local n=vector.add(minetest.localplayer:get_pos(),{x=0,y=2,z=0})
            amautotool(n)
            minetest.dig_node(n)
            minetest.dig_node(vector.add(n,{x=0,y=-1,z=0}))
end
local function evadelava(ppos)
	mwarp(get_target(ppos))
end
local function get_target(epos)
	math.randomseed(os.time())
	local t=vector.add(epos,get_3dpos_from_yaw_and_pitch(karange,math.random(120,240),math.random(270,359)))
	if (checklava(t) or checkgravel(t)) then
		return get_target(epos)
	elseif checkair(t) then
		return t
	else
		amautotool(t)
	end
	return t
end



local function rro() -- reverse restraining order
    for k, v in ipairs(minetest.localplayer.get_nearby_objects(karange+5)) do
        if (v:is_player() and v:get_name() ~= minetest.localplayer:get_name()) then
            local pos = v:get_pos()
            pos.y = pos.y - 1
			local mpos=minetest.localplayer:get_pos()
            local distance=vector.distance(mpos,pos)
            if distance < karange then
				mwarp(get_target(pos))
				minetest.after(0.2,function() autofly.aim(pos) end)
				minetest.after(0.05,function() dhfree() end)
				return
			end
        end
    end
end

minetest.register_globalstep(function()
    if minetest.settings:get_bool("goddess") then
		local ppos=minetest.localplayer:get_pos()
        rro()
        if(checklava(ppos) or checkgravel(ppos) or checkarrow()) then evadelava(ppos) end
    end
end)
minetest.register_chatcommand("dhf", {	description = "",	func = dhfree })


-- REG cheats on DF
if (_G["minetest"]["register_cheat"] ~= nil) then
	 minetest.register_cheat("Goddess Mode", "Combat", "goddess")
else
	 minetest.settings:set_bool('goddess',true)
end
