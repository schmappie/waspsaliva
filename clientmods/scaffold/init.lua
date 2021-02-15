-- CC0/Unlicense Emilia & cora 2020

local category = "Scaffold"

scaffold = {}
scaffold.registered_scaffolds = {}
scaffold.lockdir = false
scaffold.locky = false
scaffold.constrain1 = false
scaffold.constrain2 = false
local hwps={}

local storage=minetest.get_mod_storage()

scaffold.wason = {}

local nextact = {}

local towerbot_height = 75

function scaffold.template(setting, func, offset, funcstop )
    offset = offset or {x = 0, y = -1, z = 0}
    funcstop = funcstop or function() end

    return function()
        if minetest.localplayer and minetest.settings:get_bool(setting) then
            if scaffold.constrain1 and not inside_constraints(tgt) then return end
            local tgt=vector.add(minetest.localplayer:get_pos(),offset)
            func(tgt)
        end
    end
end

function scaffold.register_template_scaffold(name, setting, func, offset, funcstop)
    ws.rg(name,'Scaffold',setting,scaffold.template(setting, func, offset),funcstop )
end

local function between(x, y, z) return y <= x and x <= z end -- x is between y and z (inclusive)

function scaffold.in_cube(tpos,wpos1,wpos2)
    local xmax=wpos2.x
    local xmin=wpos1.x

    local ymax=wpos2.y
    local ymin=wpos1.y

    local zmax=wpos2.z
    local zmin=wpos1.z
    if wpos1.x > wpos2.x then
        xmax=wpos1.x
        xmin=wpos2.x
    end
    if wpos1.y > wpos2.y then
        ymax=wpos1.y
        ymin=wpos2.y
    end
    if wpos1.z > wpos2.z then
        zmax=wpos1.z
        zmin=wpos2.z
    end
    if between(tpos.x,xmin,xmax) and between(tpos.y,ymin,ymax) and between(tpos.z,zmin,zmax) then
        return true
    end
    return false
end

local function set_hwp(name,pos)
    ws.display_wp(pos,name)
end

function scaffold.set_pos1(pos)
    if not pos then local pos=minetest.localplayer:get_pos() end
    scaffold.constrain1=vector.round(pos)
    local pstr=minetest.pos_to_string(scaffold.constrain1)
    set_hwp('scaffold_pos1 '..pstr,scaffold.constrain1)
    minetest.display_chat_message("scaffold pos1 set to "..pstr)
end
function scaffold.set_pos2(pos)
    if not pos then pos=minetest.localplayer:get_pos() end
    scaffold.constrain2=vector.round(pos)
    local pstr=minetest.pos_to_string(scaffold.constrain2)
    set_hwp('scaffold_pos2 '..pstr,scaffold.constrain2)
    minetest.display_chat_message("scaffold pos2 set to "..pstr)
end

function scaffold.reset()
    scaffold.constrain1=false
    scaffold.constrain2=false
    for k,v in pairs(hwps) do
        minetest.localplayer:hud_remove(v)
        table.remove(hwps,k)
    end
end

local function inside_constraints(pos)
    if (scaffold.constrain1 and scaffold.constrain2 and scaffold.in_cube(pos,scaffold.constrain1,scaffold.constrain2)) then return true
    elseif not scaffold.constrain1 then return true
    end
    return false
end

minetest.register_chatcommand("sc_pos1", { func = scaffold.set_pos1 })
minetest.register_chatcommand("sc_pos2", { func = scaffold.set_pos2 })
minetest.register_chatcommand("sc_reset", { func = scaffold.reset })




function scaffold.can_place_at(pos)
    local node = minetest.get_node_or_nil(pos)
    return (node and (node.name == "air" or node.name=="mcl_core:water_source" or node.name=="mcl_core:water_flowing" or node.name=="mcl_core:lava_source" or node.name=="mcl_core:lava_flowing" or minetest.get_node_def(node.name).buildable_to))
end

-- should check if wield is placeable
-- minetest.get_node(wielded:get_name()) ~= nil should probably work
-- otherwise it equips armor and eats food
function scaffold.can_place_wielded_at(pos)
    local wield_empty = minetest.localplayer:get_wielded_item():is_empty()
    return not wield_empty and scaffold.can_place_at(pos)
end

function scaffold.find_any_swap(items)
    for i, v in ipairs(items) do
        local n = minetest.find_item(v)
        if n then
            minetest.localplayer:set_wield_index(n)
            return true
        end
    end
    return false
end

function scaffold.in_list(val, list)
    if type(list) ~= "table" then return false end
    for i, v in ipairs(list) do
        if v == val then
            return true
        end
    end
    return false
end

-- swaps to any of the items and places if need be
-- returns true if placed and in inventory or already there, false otherwise

local lastact=0
local lastplc=0
local lastdig=0
local actint=10
function scaffold.place_if_needed(items, pos, place)
    if not inside_constraints(pos) then return end
    --if lastplc + actint > os.time() then return end
    if not pos then return end
    lastplc=os.time()

    place = place or minetest.place_node

    local node = minetest.get_node_or_nil(pos)
    if not node then return end
    -- already there
    if node and scaffold.in_list(node.name, items) then
        return true
    else
        local swapped = scaffold.find_any_swap(items)

        -- need to place
        if swapped and scaffold.can_place_at(pos) then
            place(pos)
            return true
        -- can't place
        else
            return false
        end
    end
end

function scaffold.place_if_able(pos)
    if not pos then return end
    if not inside_constraints(pos) then return end
    if scaffold.can_place_wielded_at(pos) then
        minetest.place_node(pos)
    end
end

local function is_diggable(pos)
    if not pos then return false end
    local nd=minetest.get_node_or_nil(pos)
    if not nd then return false end
    local n = minetest.get_node_def(nd.name)
    if n and n.diggable then return true end
    return false
end

function scaffold.dig(pos)
    if not inside_constraints(pos) then return end
    if is_diggable(pos) then
        minetest.select_best_tool(nd.name)
        if emicor then emicor.supertool()
        end
        minetest.dig_node(pos)
        minetest.select_best_tool(nd.name)
    end
    return false
end


local mpath = minetest.get_modpath(minetest.get_current_modname())
dofile(mpath .. "/sapscaffold.lua")
dofile(mpath .. "/slowscaffold.lua")
dofile(mpath .. "/autofarm.lua")
dofile(mpath .. "/railscaffold.lua")
dofile(mpath .. "/wallbot.lua")
dofile(mpath .. "/ow2bot.lua")
--dofile(mpath .. "/squarry.lua")
local snapdir="north"
ws.rg('DigHead','Player','dighead',function() ws.dig(ws.dircoord(0,1,0)) end)
ws.rg('SnapYaw','Bots','snapyaw',function() ws.setdir(snapdir) end,function() snapdir=ws.getdir() end)


scaffold.register_template_scaffold("Constrain", "scaffold_constrain", function()end,false,function() scaffold.reset() end)

ws.rg("LockYaw","Scaffold", "scaffold_lockyaw", function(pos) end, function()  minetest.settings:set_bool('afly_snap',true) end, function() minetest.settings:set_bool('afly_snap',false) end)


scaffold.register_template_scaffold("CheckScaffold", "scaffold_check", function(pos)
    scaffold.place_if_able(pos)
end)

scaffold.register_template_scaffold("HereScaffold", "scaffold_here", function(pos)
    scaffold.place_if_able(pos)
end, {x = 0, y = 0, z = 0})

scaffold.register_template_scaffold("WaterScaffold", "scaffold_water", function(pos)
    if (pos.x % 2 + pos.z % 2) == 0 then
        scaffold.place_if_needed({
            "mcl_buckets:bucket_water",
            "mcl_core:water_source"
        }, pos)
    end
end)
scaffold.register_template_scaffold("WaterSpam", "scaffold_spamwater", function()
        ws.do_area(3,function(pos)
            scaffold.place_if_needed({
                "mcl_buckets:bucket_water",
                "mcl_core:water_source"
            }, pos)
        end,true)

end)
local function checknode(pos)
    local node = minetest.get_node_or_nil(pos)
    if node then return true end
    return false
end

scaffold.register_template_scaffold("TBM", "scaffold_tbm", function(pos)
   scaffold.dig(ws.dircoord(1,1,0))
   scaffold.dig(ws.dircoord(1,0,0))
end)
scaffold.register_template_scaffold("TallTBM", "scaffold_ttbm", function(pos)
    pos = {

    ws.dircoord(1,4,2),
   ws.dircoord(1,3,2),
   ws.dircoord(1,2,2),
   ws.dircoord(1,1,2),
   ws.dircoord(1,0,2),

    ws.dircoord(1,4,-2),
   ws.dircoord(1,3,-2),
   ws.dircoord(1,2,-2),
   ws.dircoord(1,1,-2),
   ws.dircoord(1,0,-2),


    ws.dircoord(1,4,1),
   ws.dircoord(1,3,1),
   ws.dircoord(1,2,1),
   ws.dircoord(1,1,1),
   ws.dircoord(1,0,1),

    ws.dircoord(1,4,-1),
   ws.dircoord(1,3,-1),
   ws.dircoord(1,2,-1),
   ws.dircoord(1,1,-1),
   ws.dircoord(1,0,-1),

    ws.dircoord(1,4,0),
   ws.dircoord(1,3,0),
   ws.dircoord(1,2,0),
   ws.dircoord(1,1,0),
   ws.dircoord(1,0,0)
    }
    ws.dignodes(pos)

    minetest.settings:set_bool('continuous_forward',true)
    for k,v in pairs(pos) do
        local n=minetest.get_node_or_nil(v)
        if not n or n.name ~= "air" then
            minetest.settings:set_bool('continuous_forward',false)
        end
    end
end)




scaffold.register_template_scaffold("TriScaffold", "scaffold_three_wide", function(pos)
    scaffold.place_if_able(pos)
    scaffold.place_if_able(ws.dircoord(0, -1, 1))
    scaffold.place_if_able(ws.dircoord(0, -1, -1))
end)

scaffold.register_template_scaffold("headTriScaff", "scaffold_three_wide_head", function(pos)
    scaffold.place_if_able(ws.dircoord(0, 3, 0))
    scaffold.place_if_able(ws.dircoord(0, 3, 1))
    scaffold.place_if_able(ws.dircoord(0, 3, -1))
end)

scaffold.register_template_scaffold("QuintScaffold", "scaffold_five_wide", function(pos)
    scaffold.place_if_able(pos)
    scaffold.place_if_able(ws.dircoord(0, -1, 1))
    scaffold.place_if_able(ws.dircoord(0, -1, -1))
    scaffold.place_if_able(ws.dircoord(0, -1, 2))
    scaffold.place_if_able(ws.dircoord(0, -1, -2))
end)


if nlist then
    scaffold.register_template_scaffold("RandomScaff", "scaffold_rnd", function(below)
        local n = minetest.get_node_or_nil(below)
        local nl=nlist.get('randomscaffold')
        table.shuffle(nl)
        if n and not scaffold.in_list(n.name, nl) then
            scaffold.dig(below)
            scaffold.place_if_needed(nl, below)
        end
    end)
end
