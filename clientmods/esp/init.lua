---
-- coras esp ..  indev


esp = {}

local radius=60 -- limit is 4,096,000 nodes (i.e. 160^3 -> a number > 79 won't work)
local esplimit=30; -- display at most this many waypoints
local espinterval=4 --number of seconds to wait between scans (a lower number can induce clientside lag)
local stpos={x=0,y=0,z=0}

--nodes={"group:chest",'mcl_chests:chest','mcl_chests:chest_left','mcl_chests:ender_chest','group:shulker_box','mcl_crafting_table:crafting_table','mcl_furnaces:furnace'}
nodes={'mcl_chests:chest','mcl_chests:chest_left','mcl_chests:ender_chest','group:shulker_box','mcl_furnaces:furnace','mcl_chests:violet_shulker_box'}

local wps={}
local hud2=nil
local hud;
local lastch=0

minetest.register_globalstep(function()
    if not minetest.settings:get_bool("espactive") then
        for k,v in pairs(wps) do
                minetest.localplayer:hud_remove(v)
                table.remove(wps,k)
        end
        return
    end

    if os.time() < lastch + espinterval then return end
    lastch=os.time()

    local pos = minetest.localplayer:get_pos()
	local pos1 = vector.add(pos,{x=radius,y=radius,z=radius})
    local pos2 = vector.add(pos,{x=-radius,y=-radius,z=-radius})
    local epos=minetest.find_nodes_in_area(pos1, pos2, nodes, true)

    for k,v in pairs(wps) do --clear waypoints out of range
        local hd=minetest.localplayer:hud_get(v)
        local dst=vector.distance(pos,hd.world_pos)
        if (dst > radius + 50 ) then
            minetest.localplayer:hud_remove(v)
            table.remove(wps,k)
            end
    end

    if epos then
        local ii=0;
        for m,xx in pairs(epos) do -- display found nodes as WPs
            for kk,vv in pairs(xx) do
                if ( ii > esplimit ) then break end
                if vector.distance(stpos,pos) > 200 then
                    stpos=minetest.localplayer:get_pos()
                    if minetest.settings:get_bool("espautostop") then
                        minetest.settings:set("continuous_forward", "false")
                        autofly.aim(vv)
                    end
                end
                ii=ii+1
                table.insert(wps,minetest.localplayer:hud_add({
                    hud_elem_type = 'waypoint',
                    name          = m,
                    text          = "m",
                    number        = 0x00ff00,
                    world_pos     = vv
                    })
                )
            end
       end
    end
end)

if (_G["minetest"]["register_cheat"] ~= nil) then
    minetest.register_cheat("NodeESP", "Render", "espactive")
else
    minetest.settings:set_bool('espactive',true)
end
