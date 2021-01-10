-- CC0/Unlicense Emilia 2021

refill = {}

local function nameformat(description)
    description = description:gsub(string.char(0x1b) .. "%(.@[^)]+%)", "")
    description = description:match("([^\n]*)")
    return description
end

local function find_named(list, name, test)
    for i, v in ipairs(list) do
        if (v:get_name():find("shulker_box")
            and nameformat(v:get_description()) == name
            and (test and test(v))) then
            return i
        end
    end
end

local function hasitems(stack)
    local list = minetest.deserialize(stack:get_metadata())

    for i, v in ipairs(list) do
        if not ItemStack(v):is_empty() then
            return true
        end
    end

    return false
end

local function shulk_switch(name)
    local plinv = minetest.get_inventory("current_player")
    local pos = find_named(plinv.main, name, hasitems)
                 --or find_named(plinv.enderchest, name, hasitems))
    if pos then
        minetest.localplayer:set_wield_index(pos)
        return true
    end
end

local function shulk_place(pos, name)
    if shulk_switch(name) then
        minetest.place_node(pos)
        return true
    end
end

local function invposformat(pos)
    pos = vector.round(pos)
    return string.format("nodemeta:%i,%i,%i", pos.x, pos.y, pos.z)
end

local function do_refill(pos)
    local q = quint.invaction_new()
    quint.invaction_dump(q,
        {location = invposformat(pos), inventory = "main"},
        {location = "current_player", inventory = "main"})
    quint.invaction_apply(q)
end

local function queue_refill(pos, name)
    if shulk_place(pos, name) then
        minetest.after(1, do_refill, pos)
        minetest.after(2, minetest.dig_node, pos)
    end
end

function refill.refill_here(name)
    local pos = vector.round(minetest.localplayer:get_pos())
    queue_refill(pos, name)
end

minetest.register_chatcommand("refill", {
    description = "Refill the inventory with a named shulker.",
    params = "<shulker name>",
    func = refill.refill_here
})
