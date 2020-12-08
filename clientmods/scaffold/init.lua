-- CC0/Unlicense Emilia 2020

local category = "Scaffold"

scaffold = {}
scaffold.registered_scaffolds = {}

local function shuffle(tbl)
  for i = #tbl, 2, -1 do
    local j = math.random(i)
    tbl[i], tbl[j] = tbl[j], tbl[i]
  end
  return tbl
end

function scaffold.register_scaffold(func)
    table.insert(scaffold.registered_scaffolds, func)
end

function scaffold.step_scaffolds()
    for i, v in ipairs(scaffold.registered_scaffolds) do
        v()
    end
end

function scaffold.template(setting, func, offset)
    offset = offset or {x = 0, y = -1, z = 0}

    return function()
        if minetest.settings:get_bool(setting) then
            local lp = minetest.localplayer:get_pos()
            local tgt = vector.round(vector.add(lp, offset))
            func(tgt)
        end
    end
end

function scaffold.register_template_scaffold(name, setting, func, offset)
    scaffold.register_scaffold(scaffold.template(setting, func, offset))
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
            minetest.localplayer:set_wield_index(n - 1)
            return true
        end
    end
    return false
end

function scaffold.in_list(val, list)
    for i, v in ipairs(list) do
        if v == val then
            return true
        end
    end
    return false
end

-- swaps to any of the items and places if need be
-- returns true if placed and in inventory or already there, false otherwise
function scaffold.place_if_needed(items, pos, place)
    place = place or minetest.place_node

    local node = minetest.get_node_or_nil(pos)

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
    if scaffold.can_place_wielded_at(pos) then
        minetest.place_node(pos)
    end
end

local mpath = minetest.get_modpath(minetest.get_current_modname())
dofile(mpath .. "/sapscaffold.lua")
dofile(mpath .. "/slowscaffold.lua")
dofile(mpath .. "/autofarm.lua")
dofile(mpath .. "/railscaffold.lua")


scaffold.register_template_scaffold("CheckScaffold", "scaffold_check", function(pos)
    scaffold.place_if_able(pos)
end)

scaffold.register_template_scaffold("HereScaffold", "scaffold_here", function(pos)
    scaffold.place_if_able(pos)
end, {x = 0, y = 0, z = 0})

if turtle then
    scaffold.register_template_scaffold("TriScaffold", "scaffold_three_wide", function(pos)
        scaffold.place_if_able(pos)
        scaffold.place_if_able(turtle.dircoord(0, -1, 1))
        scaffold.place_if_able(turtle.dircoord(0, -1, -1))
    end)
end
if turtle then
    scaffold.register_template_scaffold("headTriScaff", "scaffold_three_wide_head", function(pos)
        scaffold.place_if_able(turtle.dircoord(0, 3, 0))
        scaffold.place_if_able(turtle.dircoord(0, 3, 1))
        scaffold.place_if_able(turtle.dircoord(0, 3, -1))
    end)
end
if turtle then
    scaffold.register_template_scaffold("QuintScaffold", "scaffold_five_wide", function(pos)
        scaffold.place_if_able(pos)
        scaffold.place_if_able(turtle.dircoord(0, -1, 1))
        scaffold.place_if_able(turtle.dircoord(0, -1, -1))
        scaffold.place_if_able(turtle.dircoord(0, -1, 2))
        scaffold.place_if_able(turtle.dircoord(0, -1, -2))
    end)
end
function scaffold.dig(pos)
    local n=minetest.get_node_or_nil(pos)
    if not n or n.name == "air"then return true end
    autotool.autotool(pos)
    return minetest.dig_node(pos)
end


scaffold.register_template_scaffold("RandomScaff", "scaffold_rnd", function(below)
    local n = minetest.get_node_or_nil(below)
    if n and scaffold.in_list(n.name,nlist.get('randomscaffold')) then return end
    scaffold.dig(below)
    scaffold.place_if_needed(shuffle(nlist.get('randomscaffold')), below )
end)
