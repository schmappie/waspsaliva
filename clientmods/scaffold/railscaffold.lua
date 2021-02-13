-- CC0/Unlicense Emilia/cora 2020

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
    'mcl_nether:netherrack',
    'mcl_core:dirt',
    'mcl_core:andesite',
    'mcl_core:diorite',
    'mcl_core:granite',
    "mesecons_torch:redstoneblock"

}



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
    local bn=minetest.find_nodes_near(lp, 5, liquids, true)
    for kk,vv in pairs(bn) do
        if vv.y > lp.y - 1 then scaffold.place_if_needed(tunnelmaterial,vv) end
    end
end

local function invcheck(item)
    if mintetest.switch_to_item(item) then return true end
    refill.refill_at(ws.dircoord(1,1,0),'railkit')
end

ws.rg("RailBot","Bots", "scaffold_rails", function()
    local lp = ws.dircoord(0,0,0)
    local below = ws.dircoord(0,-1,0)
    blockliquids()
    local dpos= {
        ws.dircoord(0,1,0),
        ws.dircoord(0,0,0),
        ws.dircoord(0,-1,0),
        ws.dircoord(1,1,0),
        ws.dircoord(1,0,0),
        ws.dircoord(1,-1,0),
        ws.dircoord(2,1,0),
        ws.dircoord(2,0,0),
        ws.dircoord(2,-1,0)
    }
    dignodes(dpos)
    local bln=minetest.get_node_or_nil(below)
    local lpn=minetest.get_node_or_nil(lp)

    if bln and lpn and lpn.name == "mcl_minecarts:golden_rail_on" then
        minetest.settings:set_bool('continuous_forward',true)
    else
        minetest.settings:set_bool('continuous_forward',false)
    end

    minetest.after("0",function()
        local frpos=ws.dircoord(1,0,0)
        local fgpos=ws.dircoord(1,-1,0)
        local rpos=ws.dircoord(0,0,0)
        local gpos=ws.dircoord(0,-1,0)
        scaffold.place_if_needed(ground, gpos)
        scaffold.place_if_needed(rails, rpos)
        scaffold.place_if_needed(ground, fgpos)
        scaffold.place_if_needed(rails, frpos)

    end)
    if minetest.settings:get_bool('scaffold_railtunnel') then
        scaffold.place_if_needed(tunnelmaterial, ws.dircoord(0,2,0))
        scaffold.place_if_needed(tunnelmaterial, ws.dircoord(0,1,1))
        scaffold.place_if_needed(tunnelmaterial, ws.dircoord(0,0,1))
        scaffold.place_if_needed(tunnelmaterial, ws.dircoord(0,1,-1))
        scaffold.place_if_needed(tunnelmaterial, ws.dircoord(0,0,-1))
    end
end,
function()--startfunc

end,function() --stopfunc

end,{'scaffold_ltbm','snapyaw','continuous_forward'})

scaffold.register_template_scaffold("LanternTBM", "scaffold_ltbm", function()
   local dir=ws.getdir()
   local lp=vector.round(ws.dircoord(0,0,0))
   local pl=false
   if dir == "north" or dir == "south" then
        if lp.z % 8 < 1 then
            pl=true
        end
   else
        if lp.x % 8 < 1 then
            pl=true
        end
   end
   if pl then
        local lpos=ws.dircoord(0,2,0)
        local nd=minetest.get_node_or_nil(lpos)
        if nd and nd.name ~= 'mcl_ocean:sea_lantern' then
            ws.dig(lpos)
            minetest.after("0",function() ws.place(lpos,'mcl_ocean:sea_lantern') end)
        end
   end
end)
