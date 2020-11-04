local function find_swap(items)
    for i, v in ipairs(items) do
        local n = minetest.find_item(v)
        if n then
            minetest.localplayer:set_wield_index(n - 1)
            return true
        end
    end
    return false
end

local function in_list(val, list)
    for i, v in ipairs(list) do
        if v == val then
            return true
        end
    end
    return false
end

local function nilify_node(node)
    if node and node.name == "air" then
        return nil
    end
    return node
end

local dirt = {
    "mcl_core:dirt",
    "mcl_core:dirt_with_grass"
}

local saplings = {
    "mcl_core:sapling",
    "mcl_core:darksapling",
    "mcl_core:junglesapling",
    "mcl_core:sprucesapling",
    "mcl_core:birchsapling",
    "mcl_core:acaciasapling"
}

local function sapper()
    local lp = minetest.localplayer:get_pos()
    local below = vector.add(lp, {x = 0, y = -1, z = 0})
    local node_here = nilify_node(minetest.get_node_or_nil(lp))
    local node_under = nilify_node(minetest.get_node_or_nil(below))

    -- if theres a node below its prob bad but its good if its dirt
    if node_under and not in_list(node_under.name, dirt) then
        return
    end

    if not node_under and find_swap(dirt) then
        minetest.place_node(below)
    end

    if not node_here and find_swap(saplings) then
        minetest.place_node(lp)
    end
end

minetest.register_globalstep(function()
    if minetest.settings:get_bool("scaffold_saplings") then
        sapper()
    end
end)

if minetest.register_cheat then
    minetest.register_cheat("SapScaffold", "World", "scaffold_saplings")
end
