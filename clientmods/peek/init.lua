-- CC0/Unlicense system32 2020

local function parse_coord(c)
    c = string.split(c)
    return {x = tonumber(c[1] or 0), y = tonumber(c[2] or 0), z = tonumber(c[3] or 0)}
end

minetest.register_chatcommand("cpeek", {
    func = function(params)
        local oldpos = minetest.localplayer:get_pos()

        local c = parse_coord(params)
        local dist = vector.distance(c, oldpos)
        local d = tostring(c.x) .. "," .. tostring(c.y) .. "," .. tostring(c.z)
        local f = "size[10,10]\nlabel[0,0;Can access: " .. tostring(dist < 6) .. "(" .. tostring(dist) .. ")]\nlist[nodemeta:" .. d .. ";main;0,0.5;9,3;]"

        minetest.localplayer:set_pos(c)
        minetest.show_formspec("ChestPeek", f)
        minetest.localplayer:set_pos(oldpos)
    end
})



local formspec_base = "size[9,3]"

local formspec_base_label = "size[9,3.5]"

local formspec_item = "\nitem_image_button[X,Y;1,1;N;N;]"

local formspec_item_label = formspec_item .. "\nlabel[X,Z;T]"

local function map(f, t)
    local out = {}
    for i, v in ipairs(t) do
        out[i] = f(v)
    end
    return out
end

-- include_label because i implemented the label then realized item buttons did it themselves
local function make_formspec(items, include_label)
    if items == nil then
        return nil
    end

    local form = formspec_base
    if include_label then
        form = formspec_base_label
    end

    for i, v in ipairs(items) do
        local x = (i - 1) % 9
        local y = math.floor((i - 1) / 9)

        if include_label then
            y = y + (y * 0.2) -- shifts each layer down a bit
        end

        local it = formspec_item
        if include_label then
            it = formspec_item_label
        end

        it = it:gsub("X", x)
        it = it:gsub("Y", y)
        if include_label then
            it = it:gsub("N", v:get_name())
            it = it:gsub("Z", y + 0.8)
            it = it:gsub("T", v:get_count())
        else
            it = it:gsub("N", v:get_name() .. " " .. tostring(v:get_count()))
        end

        form = form .. it
    end
    return form
end

local function get_items()
    local meta = minetest.localplayer:get_wielded_item():get_metadata()
    local list = minetest.deserialize(meta)

    if list == nil then
        return
    end

    local items = map(ItemStack, list)
    return items
end

minetest.register_chatcommand("peek", {
    description = "Peek inside a Mineclone Shulker box.",
    func = function()
        local fs = make_formspec(get_items())
        if fs ~= nil then
            minetest.show_formspec("PeekInventory", fs)
        end
    end
})

