-- CC0/Unlicense Emilia 2020

local category = "Scaffold"

scaffold = {}
scaffold.registered_scaffolds = {}

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

local mpath = minetest.get_modpath(minetest.get_current_modname())
dofile(mpath .. "/sapscaffold.lua")
dofile(mpath .. "/slowscaffold.lua")
dofile(mpath .. "/autofarm.lua")
