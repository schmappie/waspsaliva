
ws = {}
ws.registered_globalhacks = {}
ws.displayed_wps={}

ws.lp = minetest.localplayer
ws.c = core

local nextact = {}
local ghwason={}

function ws.s(name,value)
    if value == nil then
        return ws.c.settings:get(name)
    else
        ws.c.settings:set(name,value)
        return ws.c.settings:get(name)
    end
end

function ws.dcm(msg)
    return minetest.display_chat_message(msg)
end

function ws.globalhacktemplate(setting,func,funcstart,funcstop)
    funcstart = funcstart or function() end
    funcstop = funcstop or function() end
    return function()
        if not minetest.localplayer then return end
        if minetest.settings:get_bool(setting) then
            if nextact[setting] and nextact[setting] > os.clock() then return end
            nextact[setting] = os.clock() + 0.1
            if not ghwason[setting] then
                funcstart()
                ws.dcm(setting.. " activated")
                ghwason[setting] = true
            else
                func()
            end

        elseif ghwason[setting] then
            ghwason[setting] = false
            funcstop()
            ws.dcm(setting.. " deactivated")
        end
    end
end

function ws.register_globalhack(func)
    table.insert(ws.registered_globalhacks,func)
end

function ws.register_globalhacktemplate(name,category,setting,func,funcstart,funcstop)
    ws.register_globalhack(ws.globalhacktemplate(setting,func,funcstart,funcstop))
    minetest.register_cheat(name,category,setting)
end

ws.rg=ws.register_globalhacktemplate

function ws.step_globalhacks()
    for i, v in ipairs(ws.registered_globalhacks) do
        v()
    end
end

minetest.register_globalstep(ws.step_globalhacks)

function ws.get_reachable_positions(range)
    range=range or 2
    local rt={}
    for x = -range,range,1 do
        for y = -range,range,1 do
            for z = -range,range,1 do
                table.insert(rt,vector.new(x,y,z))
            end
        end
    end
    return rt
end

function ws.do_area(radius,func,plane)
    for k,v in pairs(ws.get_reachable_positions(range)) do
        if not plane or v.y == ws.lp:get_pos().y -1 then
            func(v)
        end
    end
end


function ws.display_wp(pos,name)
    table.insert(ws.displayed_wps,minetest.localplayer:hud_add({
            hud_elem_type = 'waypoint',
            name          = name,
            text          = name,
            number        = 0x00ff00,
            world_pos     = pos
        }))
end

function ws.clear_wps()
    for k,v in pairs(ws.displayed_wps) do
        ws.lp:hud_remove(v)
        table.remove(ws.displayed_wps,k)
    end
end

function ws.register_chatcommand_alias(old, ...)
      local def = assert(minetest.registered_chatcommands[old])
      def.name = nil
     for i = 1, select('#', ...) do
         minetest.register_chatcommand(select(i, ...), table.copy(def))
     end
end

  function ws.round2(num, numDecimalPlaces)
    return tonumber(string.format("%." .. (numDecimalPlaces or 0) .. "f", num))
  end

 function ws.pos_to_string(pos)
     if type(pos) == 'table' then
         pos = minetest.pos_to_string(vector.round(pos))
     end
     if type(pos) == 'string' then
         return pos
     end
 end

 function ws.string_to_pos(pos)
     if type(pos) == 'string' then
         pos = minetest.string_to_pos(pos)
     end
     if type(pos) == 'table' then
         return vector.round(pos)
     end
end

function ws.on_connect(func)
	if not minetest.localplayer then minetest.after(0,function() ws.on_connect(func) end) return end
	if func then func() end
end

ws.on_connect(function()
    ws.lp=minetest.localplayer
end)

local function find_named(inv, name)
	if not inv then return -1 end
    for i, v in ipairs(inv) do
        --minetest.display_chat_message(name)
        if v:get_name():find(name) then
            return i
        end
    end
end
function ws.switch_inv_or_echest(name,max_count)
	if not minetest.localplayer then return false end
    local plinv = minetest.get_inventory("current_player")

    local pos = find_named(plinv.main, name)
    if pos then
        minetest.localplayer:set_wield_index(pos)
        return true
    end

    local epos = find_named(plinv.enderchest, name)
    if epos then
        local tpos
        for i, v in ipairs(plinv.main) do
            if v:is_empty() then
                tpos = i
                break
            end
        end

        if tpos then
            local mv = InventoryAction("move")
            mv:from("current_player", "enderchest", epos)
            mv:to("current_player", "main", tpos)
            if max_count then
                mv:set_count(max_count)
            end
            mv:apply()
            minetest.localplayer:set_wield_index(tpos)
            return true
        end
    end
    return false
end
-- TOOLS

local function check_tool(stack, node_groups, old_best_time)
	local toolcaps = stack:get_tool_capabilities()
	if not toolcaps then return end
	local best_time = old_best_time
	for group, groupdef in pairs(toolcaps.groupcaps) do
		local level = node_groups[group]
		if level then
			local this_time = groupdef.times[level]
			if this_time and this_time < best_time then
				best_time = this_time
			end
		end
	end
	return best_time < old_best_time, best_time
end

local function find_best_tool(nodename, switch)
	local player = minetest.localplayer
	local inventory = minetest.get_inventory("current_player")
	local node_groups = minetest.get_node_def(nodename).groups
	local new_index = player:get_wield_index()
	local is_better, best_time = false, math.huge

	is_better, best_time = check_tool(player:get_wielded_item(), node_groups, best_time)
	if inventory.hand then
	    is_better, best_time = check_tool(inventory.hand[1], node_groups, best_time)
    end

	for index, stack in ipairs(inventory.main) do
		is_better, best_time = check_tool(stack, node_groups, best_time)
		if is_better then
			new_index = index
		end
	end

	return new_index
end

function ws.select_best_tool(pos)
    local nodename=minetest.get_node_or_nil(pos).name or 'air'
	minetest.localplayer:set_wield_index(find_best_tool(nodename))
end

--- COORDS
function ws.coord(x, y, z)
    return vector.new(x,y,z)
end
function ws.ordercoord(c)
    if c.x == nil then
        return {x = c[1], y = c[2], z = c[3]}
    else
        return c
    end
end

-- x or {x,y,z} or {x=x,y=y,z=z}
function ws.optcoord(x, y, z)
    if y and z then
        return ws.coord(x, y, z)
    else
        return ws.ordercoord(x)
    end
end
function ws.cadd(c1, c2)
    return ws.coord(c1.x + c2.x, c1.y + c2.y, c1.z + c2.z)
end

function ws.relcoord(x, y, z)
    local pos = minetest.localplayer:get_pos()
    return ws.cadd(pos, ws.optcoord(x, y, z))
end

local function between(x, y, z) -- x is between y and z (inclusive)
    return y <= x and x <= z
end

function ws.getdir() --
    local rot = minetest.localplayer:get_yaw() % 360
    if between(rot, 315, 360) or between(rot, 0, 45) then
        return "north"
    elseif between(rot, 135, 225) then
        return "south"
    elseif between(rot, 225, 315) then
        return "east"
    elseif between(rot, 45, 135) then
        return "west"
    end
end
function ws.setdir(dir) --
    if dir == "north" then
        minetest.localplayer:set_yaw(0)
    elseif dir == "south" then
        minetest.localplayer:set_yaw(180)
    elseif dir == "east" then
        minetest.localplayer:set_yaw(270)
    elseif dir == "west" then
        minetest.localplayer:set_yaw(90)
    end
end

function ws.dircoord(f, y, r)
    local dir=ws.getdir()
    local coord = ws.optcoord(f, y, r)
    local f = coord.x
    local y = coord.y
    local r = coord.z
    local lp=minetest.localplayer:get_pos()
    if dir == "north" then
        return ws.relcoord(r, y, f)
    elseif dir == "south"  then
        return ws.relcoord(-r, y, -f)
    elseif dir == "east" then
        return ws.relcoord(f, y, -r)
    elseif dir== "west" then
        return ws.relcoord(-f, y, r)
    end
    return ws.relcoord(0, 0, 0)
end

function ws.place(pos,node)
    if node then ws.switch_inv_or_echest(node,1) end
    ws.c.place_node(pos)
end

function ws.dig(pos)
    local nd=minetest.get_node_or_nil(pos)
    if nd and minetest.get_node_def(nd.name).diggable then
        ws.select_best_tool(pos)
        minetest.dig_node(pos)
    end

end

ws.rg('DigHead','Player','dighead',function()
    ws.dig(ws.dircoord(0,1,0))
end)
