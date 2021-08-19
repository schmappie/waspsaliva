-- CC0/Unlicense Emilia/cora 2020

-- south:5,1.5
--west:-x,1.5,-5
--east:-x,1.5,5
-- north 5,1.5(3096:2.5,25025:1.5),z
local storage = minetest.get_mod_storage()
local ground = {
    "mesecons_torch:redstoneblock"
}

local rails = {
    "mcl_minecarts:golden_rail",
    "mcl_minecarts:rail"
}

local tunnelmaterial = {
    'mcl_core:glass_light_blue',
    'mcl_core:cobble',
    'mcl_core:stone',
    'mcl_nether:netherrack',
    'mcl_core:dirt',
    'mcl_core:andesite',
    'mcl_core:diorite',
    'mcl_core:granite'
    --"mesecons_torch:redstoneblock"
}

local function is_rail(pos)
    pos=vector.round(pos)
    if pos.y ~= 1 then return false end
    if pos.z > 5 then
        if pos.x == -5 then return "north" end
    elseif pos.z < -5 then
        if pos.x == 5 then return "south" end
    end
    if pos.x > 5 then
        if pos.z == 5 then return "east" end
    elseif pos.x < -5 then
        if pos.z == -5 then return "west" end
    end
    return false
end

local function get_railnode(pos)
    if is_rail(pos) then
        return "mcl_minecarts:golden_rail"
    end
    if is_rail(vector.add(pos,{x=0,y=1,x=0})) then
        return "mesecons_torch:redstoneblock"
    end
    return false
end

local function is_lantern(pos)
   local dir=ws.getdir()
   pos=vector.round(pos)
   if dir == "north" or dir == "south" then
        if pos.z % 8 == 0 then
            return true
        end
   else
        if pos.x % 8 == 0 then
            return true
        end
   end
   return false
end

ws.rg('RailTool','Scaffold','railtool',function()
    local poss=ws.get_reachable_positions(5)
    for k,p in pairs(poss) do
        local n=get_railnode(p)
        if n then ws.place(p,n) end
    end
end)



minetest.register_cheat("RailT",'Bots','scaffold_railtunnel')
local function checknode(pos)
    local node = minetest.get_node_or_nil(pos)
    if node and node.name ~="mesecons_torch:redstoneblock" and not node.name:find("_rail")  then return true end
    return false
end
local function dignodes(poss)
    for k,v in pairs(poss) do
        if checknode(v) then ws.dig(v) end
    end
end
local function blockliquids()
    local lp=ws.lp:get_pos()
    local liquids={'mcl_core:lava_source','mcl_core:water_source','mcl_core:lava_flowing','mcl_core:water_flowing'}
    local bn=minetest.find_nodes_near(lp, 1, liquids, true)
    for kk,vv in pairs(bn) do
        if vv.y > lp.y then scaffold.place_if_needed(tunnelmaterial,vv) end
    end
end

local function invcheck(item)
    if mintetest.switch_to_item(item) then return true end
    refill.refill_at(ws.dircoord(1,1,0),'railkit')
end

local direction="north"

ws.rg("RailBot","Bots", "railbot", function()
    local lp = ws.dircoord(0,0,0)
    local below = ws.dircoord(0,-1,0)
    blockliquids()

    local goon=true
    for i=-4,4,1 do

       ws.dig(ws.dircoord(i,1,0))
        if checknode(ws.dircoord(i,0,0)) then ws.dig(ws.dircoord(i,0,0)) end
        if checknode(ws.dircoord(i,-1,0)) then ws.dig(ws.dircoord(i,-1,0)) end
        scaffold.place_if_needed(ground, ws.dircoord(i,-1,0))
        scaffold.place_if_needed(rails, ws.dircoord(i,0,0))

        local lpn=minetest.get_node_or_nil(ws.dircoord(i,0,0))
        local bln=minetest.get_node_or_nil(ws.dircoord(i,-1,0))
        if not ( bln and bln.name=="mesecons_torch:redstoneblock" and lpn and lpn.name == "mcl_minecarts:golden_rail_on" ) then
            goon=false
        end
        local lpos=ws.dircoord(i,2,0)
        if is_lantern(lpos) then
            local ln=minetest.get_node_or_nil(lpos)
            if not ln or ln.name ~= 'mcl_ocean:sea_lantern' then
                goon=false
                ws.dig(lpos)
                scaffold.place_if_needed({'mcl_ocean:sea_lantern'}, lpos)
            end
        end
    end

    if (goon) then minetest.settings:set_bool('continuous_forward',true)
    else minetest.settings:set_bool('continuous_forward',false) end


end,
function()--startfunc
    direction=ws.get_dir()
    storage:set_string('BOTDIR', direction)
end,function() --stopfunc
    direction=""
    storage:set_string('BOTDIR',direction)
end,{'afly_axissnap','continuous_forward','autorefill'}) --'scaffold_ltbm'

ws.on_connect(function()
        local sdir=storage:get_string('BOTDIR')
        if sdir ~= "" then
            ws.set_dir(sdir)
        else
            minetest.settings:set_bool('railbot',false)
        end
end)

scaffold.register_template_scaffold("LanternTBM", "scaffold_ltbm", function()
   local dir=ws.getdir()
   local lp=vector.round(ws.dircoord(0,0,0))
   local pl=is_lantern(lp)
   if pl then
        local lpos=ws.dircoord(0,2,0)
        local nd=minetest.get_node_or_nil(lpos)
        if nd and nd.name ~= 'mcl_ocean:sea_lantern' then
            ws.dig(lpos)
            minetest.after("0",function()
                scaffold.place_if_needed({'mcl_ocean:sea_lantern'}, lpos)
                ws.place(lpos,'mcl_ocean:sea_lantern')
            end)
        end
   end
end)
