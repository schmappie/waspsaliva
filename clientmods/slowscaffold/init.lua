if minetest.settings:get("slow_blocks_per_second") == nil then
    minetest.settings:set("slow_blocks_per_second", 8)
end

local lastt = 0
local interval = 1 / minetest.settings:get("slow_blocks_per_second")

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

        lastt = lastt + interval

        minetest.after(lastt - now, nowplace, pos)

        posqueue[#posqueue + 1] = pos
    end
end

local function cplace(pos)
    local wield_empty = minetest.localplayer:get_wielded_item():is_empty()

    local node = minetest.get_node_or_nil(pos)
    if not wielded_empty and node and (node.name == "air" or minetest.get_node_def(node.name).buildable_to) then
        place(pos)
    end
end

local function scaffold()
    if minetest.settings:get_bool("slow_scaffold") then
        local lp = minetest.localplayer:get_pos()
        local tgt = vector.round(vector.add(lp, {x = 0, y = -1, z = 0}))
        cplace(tgt)
    end
end

minetest.register_globalstep(scaffold)

if minetest.register_cheat then
    minetest.register_cheat("SlowScaffold", "World", "slow_scaffold")
end
