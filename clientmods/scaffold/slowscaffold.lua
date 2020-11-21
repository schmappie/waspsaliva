if minetest.settings:get("slow_blocks_per_second") == nil then
    minetest.settings:set("slow_blocks_per_second", 8)
end

-- Could remove the queue and have nowplace() check if it can place at the position

local lastt = 0

local posqueue = {}

local function posq_pos(pos)
    local plen = #posqueue
    for i = 0, #posqueue - 1 do
        if vector.equals(pos, posqueue[plen - i]) then
            return plen - i
        end
    end
end

local function nowplace(pos)
    local p = posq_pos(pos)
    if p then
        table.remove(posqueue, p)
    end

    minetest.place_node(pos)
end

local function place(pos)
    if not posq_pos(pos) then
        local now = os.clock()

        if lastt < now then
            lastt = now
        end

        local interval = 1 / minetest.settings:get("slow_blocks_per_second")
        lastt = lastt + interval

        minetest.after(lastt - now, nowplace, pos)

        posqueue[#posqueue + 1] = pos
    end
end

local function can_place_at(pos)
    local node = minetest.get_node_or_nil(pos)
    return (node and (node.name == "air" or minetest.get_node_def(node.name).buildable_to))
end

-- should check if wield is placeable
-- minetest.get_node(wielded:get_name()) ~= nil should probably work
local function can_place(pos)
    local wield_empty = minetest.localplayer:get_wielded_item():is_empty()
    return not wield_empty and can_place_at(pos)
end

scaffold.register_template_scaffold("scaffold_slow", function(pos)
    if can_place(pos) then
        place(pos)
    end
end)

scaffold.register_template_scaffold("scaffold_check", function(pos)
    if can_place(pos) then
        minetest.place_node(pos)
    end
end)

if minetest.register_cheat then
    minetest.register_cheat("SlowScaffold", "Scaffold", "scaffold_slow")
    minetest.register_cheat("CheckScaffold", "Scaffold", "scaffold_check")
end
