-- CC0/Unlicense Emilia & cora 2020

local category = "Scaffold"

scaffold = {}
scaffold.registered_scaffolds = {}
scaffold.lockdir = false
scaffold.locky = false
local storage=minetest.get_mod_storage()

scaffold.wason = {}

local nextact = {}

local towerbot_height = 75




local function get_locks()
    local ly=storage:get_string('lockdir')
    local ld= storage:get_string('locky')
    if ld then scaffold.lockdir = tonumber(ld) end
    if ly then scaffold.locky = tonumber(ly) end
    if scaffold.lockdir or scaffold.locky then return true end
    return false
end
local function set_locks()
    storage:set_string('lockdir', scaffold.lockdir)
    storage:set_string('locky', scaffold.locky)
end
local function del_locks()
    storage:set_string('lockdir','')
    storage:set_string('locky','')
end

if get_locks() then
    if scaffold.lockdir then scaffold.wason.scaffold_lockyaw = true end
    if scaffold.locky then scaffold.wason.scaffold_locky = true end
end

function scaffold.register_scaffold(func)
    table.insert(scaffold.registered_scaffolds, func)
end

function scaffold.step_scaffolds()
    for i, v in ipairs(scaffold.registered_scaffolds) do
        v()
    end
end

function scaffold.template(setting, func, offset, funcstop )
    offset = offset or {x = 0, y = -1, z = 0}
    funcstop = funcstop or function() end

    return function()
        if minetest.localplayer and minetest.settings:get_bool(setting) then
            if nextact[setting] and nextact[setting] > os.clock() then return end
            nextact[setting] = os.clock() + 0.1
            local lp = minetest.localplayer:get_pos()
            local tgt = vector.round(vector.add(lp, offset))
            func(tgt)
            if not scaffold.wason[setting] then scaffold.wason[setting] = true end
        elseif scaffold.wason[setting] then
            scaffold.wason[setting] = false
            funcstop()
        end
    end
end

function scaffold.register_template_scaffold(name, setting, func, offset, funcstop)
    scaffold.register_scaffold(scaffold.template(setting, func, offset, funcstop))
    if minetest.register_cheat then
        minetest.register_cheat(name, category, setting)
    end
end

minetest.register_globalstep(scaffold.step_scaffolds)

function scaffold.can_place_at(pos)
    local node = minetest.get_node_or_nil(pos)
    return (node and (node.name == "air" or minetest.get_node_def(node.name).buildable_to))
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
local actint=1
function scaffold.place_if_needed(items, pos, place)
    --if lastplc + actint > os.time() then return end
    if not pos then return end
    lastplc=os.time()
    if minetest.settings:get_bool('scaffold.locky') and math.round(pos.y) ~= math.round(scaffold.locky) then return end
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
    --if lastplc + actint > os.time() then return end
    lastplc=os.time()
    if minetest.settings:get_bool('scaffold.locky') and math.round(pos.y) ~= math.round(scaffold.locky) then return end
    if scaffold.can_place_wielded_at(pos) then
        minetest.place_node(pos)
    end
end

function scaffold.dig(pos)
    --if lastdig + actint > os.time() then return end
    lastdig=os.time()
    local nd=minetest.get_node_or_nil(pos)
    if not nd then return false end
    local n = minetest.get_node_def(nd.name)
    if n and n.diggable then
        minetest.select_best_tool(nd.name)
        return minetest.dig_node(pos)
    end
    return false
end


local mpath = minetest.get_modpath(minetest.get_current_modname())
dofile(mpath .. "/sapscaffold.lua")
dofile(mpath .. "/slowscaffold.lua")
dofile(mpath .. "/autofarm.lua")
dofile(mpath .. "/railscaffold.lua")
dofile(mpath .. "/wallbot.lua")


scaffold.register_template_scaffold("LockYaw", "scaffold_lockyaw", function(pos)
    if not scaffold.wason.scaffold_lockyaw then
        scaffold.lockdir=turtle.getdir()
        set_locks()
    end
    if scaffold.lockdir  then turtle.setdir(scaffold.lockdir) end
end, false, function() storage:set_string('lockdir','') end)


scaffold.register_template_scaffold("LockY", "scaffold_locky", function(pos)
    local lp=minetest.localplayer:get_pos()
    if not scaffold.wason.scaffold_locky then
        scaffold.locky = lp.y
        set_locks()
    end
    if scaffold.locky and lp.y ~= scaffold.locky  then
        --minetest.localplayer:set_pos({x=lp.x,y=scaffold.locky,z=lp.z})
    end
    end,false, function() storage:set_string('locky','') end)

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
scaffold.register_template_scaffold("WaterSpam", "scaffold_spamwater", function(pos)
    --if (pos.x % 2 + pos.z % 2) == 0 then
        scaffold.place_if_needed({
            "mcl_buckets:bucket_water",
            "mcl_core:water_source"
        }, pos)
    --end
end)
local function checknode(pos)
    local node = minetest.get_node_or_nil(pos)
    if node then return true end
    return false
end

if turtle then
    scaffold.register_template_scaffold("TBM", "scaffold_tbm", function(pos)
       scaffold.dig(turtle.dircoord(1,1,0))
       scaffold.dig(turtle.dircoord(1,0,0))
    end)
    scaffold.register_template_scaffold("TallTBM", "scaffold_ttbm", function(pos)
        pos = {

        turtle.dircoord(1,4,2),
       turtle.dircoord(1,3,2),
       turtle.dircoord(1,2,2),
       turtle.dircoord(1,1,2),
       turtle.dircoord(1,0,2),

        turtle.dircoord(1,4,-2),
       turtle.dircoord(1,3,-2),
       turtle.dircoord(1,2,-2),
       turtle.dircoord(1,1,-2),
       turtle.dircoord(1,0,-2),


        turtle.dircoord(1,4,1),
       turtle.dircoord(1,3,1),
       turtle.dircoord(1,2,1),
       turtle.dircoord(1,1,1),
       turtle.dircoord(1,0,1),

        turtle.dircoord(1,4,-1),
       turtle.dircoord(1,3,-1),
       turtle.dircoord(1,2,-1),
       turtle.dircoord(1,1,-1),
       turtle.dircoord(1,0,-1),

        turtle.dircoord(1,4,0),
       turtle.dircoord(1,3,0),
       turtle.dircoord(1,2,0),
       turtle.dircoord(1,1,0),
       turtle.dircoord(1,0,0)
        }
        for k,v in pairs(pos) do
            scaffold.dig(v)
        end
        minetest.settings:set_bool('continuous_forward',true)
        for k,v in pairs(pos) do
            local n=minetest.get_node_or_nil(v)
            if n and n.name ~= "air" then
                minetest.settings:set_bool('continuous_forward',false)
            end
            if n and n.name == 'mcl_core:cobble' then
                minetest.settings:set_bool('scaffold_ttbm',false)
                minetest.settings:set_bool('scaffold_lockyaw',false)
            end
        end
    end)

    scaffold.register_template_scaffold("Cobbler", "scaffold_cobbler", function(pos)
        if minetest.settings:get_bool('freecam') then return end
        local fpos=turtle.dircoord(1,0,0)
        local fn=minetest.get_node_or_nil(fpos)
        pos = {

        turtle.dircoord(2,4,2),
       turtle.dircoord(2,3,2),
       turtle.dircoord(2,2,2),
       turtle.dircoord(2,1,2),
       turtle.dircoord(2,0,2),

        turtle.dircoord(2,4,-2),
       turtle.dircoord(2,3,-2),
       turtle.dircoord(2,2,-2),
       turtle.dircoord(2,1,-2),
       turtle.dircoord(2,0,-2),

        turtle.dircoord(2,4,1),
       turtle.dircoord(2,3,1),
       turtle.dircoord(2,2,1),
       turtle.dircoord(2,1,1),
       turtle.dircoord(2,0,1),

        turtle.dircoord(2,4,-1),
       turtle.dircoord(2,3,-1),
       turtle.dircoord(2,2,-1),
       turtle.dircoord(2,1,-1),
       turtle.dircoord(2,0,-1),

        turtle.dircoord(2,4,0),
       turtle.dircoord(2,3,0),
       turtle.dircoord(2,2,0),
       turtle.dircoord(2,1,0),
       turtle.dircoord(2,0,0),


        turtle.dircoord(3,4,2),
       turtle.dircoord(3,3,2),
       turtle.dircoord(3,2,2),
       turtle.dircoord(3,1,2),
       turtle.dircoord(3,0,2),

        turtle.dircoord(3,4,-2),
       turtle.dircoord(3,3,-2),
       turtle.dircoord(3,2,-2),
       turtle.dircoord(3,1,-2),
       turtle.dircoord(3,0,-2),


        turtle.dircoord(4,4,1),
       turtle.dircoord(4,3,1),
       turtle.dircoord(4,2,1),
       turtle.dircoord(4,1,1),
       turtle.dircoord(4,0,1),

        turtle.dircoord(4,4,-1),
       turtle.dircoord(4,3,-1),
       turtle.dircoord(4,2,-1),
       turtle.dircoord(4,1,-1),
       turtle.dircoord(4,0,-1),

        turtle.dircoord(4,4,0),
       turtle.dircoord(4,3,0),
       turtle.dircoord(4,2,0),
       turtle.dircoord(4,1,0),
       turtle.dircoord(4,0,0),

        turtle.dircoord(5,4,2),
       turtle.dircoord(5,3,2),
       turtle.dircoord(5,2,2),
       turtle.dircoord(5,1,2),
       turtle.dircoord(5,0,2),

        turtle.dircoord(5,4,-2),
       turtle.dircoord(5,3,-2),
       turtle.dircoord(5,2,-2),
       turtle.dircoord(5,1,-2),
       turtle.dircoord(5,0,-2),


        turtle.dircoord(5,4,1),
       turtle.dircoord(5,3,1),
       turtle.dircoord(5,2,1),
       turtle.dircoord(5,1,1),
       turtle.dircoord(5,0,1),

        turtle.dircoord(5,4,-1),
       turtle.dircoord(5,3,-1),
       turtle.dircoord(5,2,-1),
       turtle.dircoord(5,1,-1),
       turtle.dircoord(5,0,-1),

        turtle.dircoord(5,4,0),
       turtle.dircoord(5,3,0),
       turtle.dircoord(5,2,0),
       turtle.dircoord(5,1,0),
       turtle.dircoord(5,0,0)
        }

        if fn and fn.name == "mcl_core:cobble" then
            for k,v in pairs(pos) do
                scaffold.place_if_needed({"mcl_core:cobble"},v)
            end

        end
    end)


    scaffold.register_template_scaffold("LanternTBM", "scaffold_ltbm", function(pos)
       --scaffold.dig(turtle.dircoord(1,1,0)) -- let lTBM just be additionally place lanterns mode - useful for rail too.
       --scaffold.dig(turtle.dircoord(1,0,0))
       local dir=turtle.getdir()
       local pl=false
       if dir == "north" or dir == "south" then
            if pos.z % 8 == 0 then
                pl=true
            end
       else
            if pos.x % 8 == 0 then
                pl=true
            end
       end
       if pl then
            local lpos=turtle.dircoord(0,3,0)
            local nd=minetest.get_node_or_nil(lpos)
            if nd and nd.name ~= 'mcl_ocean:sea_lantern' then
                scaffold.dig(lpos)
                minetest.after("0.1",function() scaffold.place_if_needed({'mcl_ocean:sea_lantern'},lpos) end)
            end
       end
    end)
    scaffold.register_template_scaffold("TriScaffold", "scaffold_three_wide", function(pos)
        scaffold.place_if_able(pos)
        scaffold.place_if_able(turtle.dircoord(0, 0, 1))
        scaffold.place_if_able(turtle.dircoord(0, 0, -1))
    end)

    scaffold.register_template_scaffold("WallBot", "scaffold_behind", function(pos)
     minetest.settings:set_bool('scaffold_lockyaw',true)
     minetest.settings:set('movement_speed_walk',1)
        pos = {

        turtle.dircoord(-2,4,2),
       turtle.dircoord(-2,3,2),
       turtle.dircoord(-2,2,2),
       turtle.dircoord(-2,1,2),
       turtle.dircoord(-2,0,2),

        turtle.dircoord(-2,4,-2),
       turtle.dircoord(-2,3,-2),
       turtle.dircoord(-2,2,-2),
       turtle.dircoord(-2,1,-2),
       turtle.dircoord(-2,0,-2),


        turtle.dircoord(-2,4,1),
       turtle.dircoord(-2,3,1),
       turtle.dircoord(-2,2,1),
       turtle.dircoord(-2,1,1),
       turtle.dircoord(-2,0,1),

        turtle.dircoord(-2,4,-1),
       turtle.dircoord(-2,3,-1),
       turtle.dircoord(-2,2,-1),
       turtle.dircoord(-2,1,-1),
       turtle.dircoord(-2,0,-1),

        turtle.dircoord(-2,4,0),
       turtle.dircoord(-2,3,0),
       turtle.dircoord(-2,2,0),
       turtle.dircoord(-2,1,0),
       turtle.dircoord(-2,0,0),
               turtle.dircoord(-2,4,2),
       turtle.dircoord(-2,3,2),
       turtle.dircoord(-2,2,2),
       turtle.dircoord(-2,1,2),
       turtle.dircoord(-2,0,2),

        turtle.dircoord(-3,4,-2),
       turtle.dircoord(-3,3,-2),
       turtle.dircoord(-3,2,-2),
       turtle.dircoord(-3,1,-2),
       turtle.dircoord(-3,0,-2),


        turtle.dircoord(-3,4,1),
       turtle.dircoord(-3,3,1),
       turtle.dircoord(-3,2,1),
       turtle.dircoord(-3,1,1),
       turtle.dircoord(-3,0,1),

        turtle.dircoord(-3,4,-1),
       turtle.dircoord(-3,3,-1),
       turtle.dircoord(-3,2,-1),
       turtle.dircoord(-3,1,-1),
       turtle.dircoord(-3,0,-1),

        turtle.dircoord(-3,4,0),
       turtle.dircoord(-3,3,0),
       turtle.dircoord(-3,2,0),
       turtle.dircoord(-3,1,0),
       turtle.dircoord(-3,0,0)
        }

        local ngo=false

        for k,v in pairs(pos) do
            local n=minetest.get_node_or_nil(v)
            if n and n.name ~= "mcl_core:cobble" then
                scaffold.dig(v)
                ngo=false
            else ngo=true
            end
            if n == nil then ngo=false end
        end

        for k,v in pairs(pos) do
            scaffold.place_if_needed({'mcl_core:cobble'},v)
        end

        minetest.settings:set_bool('continuous_forward',ngo)
    end,false,function()
    minetest.settings:set_bool('continuous_forward',false)
    minetest.settings:set_bool('scaffold_locky',false)
    minetest.settings:set_bool('scaffold_lockyaw',false)
    minetest.settings:set_bool('scaffold_ltbm',false)
    minetest.settings:set('movement_speed_walk',4)
  end)

    scaffold.register_template_scaffold("headTriScaff", "scaffold_three_wide_head", function(pos)
        scaffold.place_if_able(turtle.dircoord(0, 3, 0))
        scaffold.place_if_able(turtle.dircoord(0, 3, 1))
        scaffold.place_if_able(turtle.dircoord(0, 3, -1))
    end)

    scaffold.register_template_scaffold("QuintScaffold", "scaffold_five_wide", function(pos)
        scaffold.place_if_able(pos)
        scaffold.place_if_able(turtle.dircoord(0, 0, 1))
        scaffold.place_if_able(turtle.dircoord(0, 0, -1))
        scaffold.place_if_able(turtle.dircoord(0, 0, 2))
        scaffold.place_if_able(turtle.dircoord(0, 0, -2))
    end)
end

if nlist then
    scaffold.register_template_scaffold("RandomScaff", "scaffold_rnd", function(below)
        if true then return false end
        local n = minetest.get_node_or_nil(below)
        -- n == nil is ignore
        if n and not scaffold.in_list(n.name, nlist.get('randomscaffold')) then
            scaffold.dig(below)
            scaffold.place_if_needed(table.shuffle(nlist.get('randomscaffold')), below)
        end
    end)
end
