---
-- coras esp ..  indev


autominer = {}
local dmg=false
local digging=false
local radius=10 -- limit is 4,096,000 nodes (i.e. 160^3 -> a number > 79 won't work)
local esplimit=30; -- display at most this many waypoints
local espinterval=1 --number of seconds to wait between scans (a lower number can induce clientside lag)

--nodes={"group:chest",'mcl_chests:chest','mcl_chests:chest_left','mcl_chests:ender_chest','group:shulker_box','mcl_crafting_table:crafting_table','mcl_furnaces:furnace'}
nodes={'mcl_core:stone_with_coal','mcl_core:stone_with_gold','mcl_core:stone_with_iron','mcl_core:stone_with_diamond','mcl_core:stone_with_redstone'}
nextpos={}
local function sleep(n)  -- seconds
  local t0 = os.clock()
  while os.clock() - t0 <= n do end
end
local function shuffle(tbl)
  for i = #tbl, 2, -1 do
    local j = math.random(i)
    tbl[i], tbl[j] = tbl[j], tbl[i]
  end
  return tbl
end
local function checklava(pos)
    local n=minetest.find_node_near(pos, 3, {'mcl_core:lava_source','mcl_core:lava_flowing'}, true)
    if n == nil then return false end
    return true
end
local function find_tnod()
    local rr=false
    local pos = minetest.localplayer:get_pos()
	local pos1 = vector.add(pos,{x=radius,y=radius,z=radius})
    local pos2 = vector.add(pos,{x=-radius,y=-radius,z=-radius})
    local rt=shuffle(minetest.find_nodes_in_area(pos1, pos2, shuffle(nodes), true))
    for k,v in pairs(rt) do
        for kk,vv in pairs(shuffle(v)) do
       -- minetest.display_chat_message("Found nodes:" ..dump(rt))
            if not checklava(vv) and ( vv.y > -57 ) then
                rr=vv
                break
            end
        end
    end
    return rr
--    return rt
end
local function get_hnode()
    local ppos=minetest.localplayer:get_pos()
    local n=minetest.get_node_or_nil(vector.add(ppos,{x=0,y=1,z=0}))
    return n
end
local function dighead()
            if not minetest.localplayer then return end
            minetest.settings:set_bool("autotool",true)
            local ppos=vector.add(minetest.localplayer:get_pos(),{x=0,y=1,z=0})
            --minetest.display_chat_message(dump(ppos))
            minetest.dig_node(ppos)
            minetest.dig_node(vector.add(ppos,{x=0,y=1,z=0}))
            digging=false
            if (minetest.settings:get_bool('aminer_active')) then
                local hp=minetest.localplayer:get_hp()
                local hn=get_hnode()
                if (hp > 15) then
                    autominer.aminer()
                else
                        minetest.display_chat_message("taken too much damage. stop.")
                        local ppos=vector.add(minetest.localplayer:get_pos(),{x=0,y=1,z=0})
                        minetest.dig_node(ppos)
                        minetest.dig_node(vector.add(ppos,{x=0,y=1,z=0}))
                        --minetest.dig_node(vector.add(ppos,{x=0,y=2,z=0}))
                        minetest.dig_node(vector.add(ppos,{x=0,y=-1,z=0}))
                        minetest.settings:set_bool("aminer_active",false)
                end
            end
end



local function abswarp(pos)
	minetest.localplayer:set_pos(vector.add(pos,{x=0,y=-1,z=0}))
    minetest.display_chat_message("Warped to " .. minetest.pos_to_string(pos) )
end

local function rwarp()
    if not (minetest.settings:get_bool("aminer_active")) then return end
    digging=true
    local nod=find_tnod()
    if not nod then
        minetest.display_chat_message('lava detected. stop.')
        return
    end
    minetest.localplayer:set_pos(vector.add(nod,{x=0,y=-1,z=0}))
    minetest.after(0.05, dighead)
end

local function relwarp(rpos)
		local success, pos = minetest.parse_relative_pos(rpos)
		if success then
			minetest.localplayer:set_pos(pos)
        minetest.display_chat_message("Warped to ".. minetest.pos_to_string(pos) )
		end
		return false, pos
end

local function amine()
            minetest.settings:set_bool("autotool",true)
            minetest.after(1.0,rwarp)
end
function autominer.aminer()
        if not digging then
            digging=true
            minetest.settings:set_bool("autotool",true)
            if dmg then
                dmg=hpchange.get_status()
                minetest.after(2.0,rwarp)
            else
                minetest.after(0.8,rwarp)
            end
        end
end
local lastch=0
minetest.register_globalstep(function()
    if os.time() < lastch + 5 then return end
    lastch=os.time()
    if ( minetest.settings:get_bool('aminer_active') ) then
        dmg=true
        digging=false
        autominer.aminer()
    end
end)

minetest.register_chatcommand("aminer", {
	description = "",
	func = function()
        dmg=true
        digging=false
        minetest.settings:set_bool("aminer_active",true)
        autominer.aminer()
    end,
})
minetest.register_chatcommand("amine", {
	description = "",
	func = amine
})
minetest.register_chatcommand("dhe", {
	description = "",
	func = dighead
})
minetest.register_on_damage_taken(function(hp)
    dmg=true
end)

--[[]
local wps={}
local hud2=nil
local hud;
local lastch=0

minetest.register_globalstep(function()
    if not minetest.settings:get_bool("espactive") then
        if hud2 then minetest.localplayer:hud_remove(hud2) hud2=nil end
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
    local fpos,cnt=minetest.find_nodes_in_area(pos1, pos2, nodes, false)
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
        if(hud2) then minetest.localplayer:hud_remove(hud2) end
        local infotxt=""
        for k,v in pairs(cnt) do -- display a summary
            if not ( v == 0 ) then
                if minetest.settings:get_bool("espautostop") then minetest.settings:set("continuous_forward", "false") end
                infotxt=infotxt.."\n"..k..":"..v
            end
        end
        if infotxt ~= "" then
            hud2=minetest.localplayer:hud_add({
                hud_elem_type = 'text',
                name          = "ESP info",
                text          = "NOIs in range ("..radius..")\n"..infotxt,
                number        = 0x00ff00,
                direction   = 0,
                position = {x=0.75,y=0.4},
                alignment ={x=1,y=1},
                offset = {x=0, y=0}
               })
        end

        local ii=0;
        for m,xx in pairs(epos) do -- display found nodes as WPs
            for kk,vv in pairs(xx) do
                if ( ii > esplimit ) then break end
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
--]]

if (_G["minetest"]["register_cheat"] ~= nil) then
    minetest.register_cheat("active    (!!! ALPHA!! this will lead to you dying!!!)", "Autominer", "aminer_active")
else
    minetest.settings:set_bool('aminer_active',false)
end
