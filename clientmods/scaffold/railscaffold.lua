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
    'mcl_core:granite'
}

local setdir=false;
minetest.register_cheat("RailT",'Scaffold','scaffold_railtunnel')
local function checknode(pos)
    local node = minetest.get_node_or_nil(pos)
    if node and node.name ~="mesecons_torch:redstoneblock" and not node.name:find("_rail")  then return true end
    return false
end

scaffold.register_template_scaffold("RailScaffold", "scaffold_rails", function(below)
    local lp = vector.round(minetest.localplayer:get_pos())

    local fpos1=turtle.dircoord(1,2,0)
    local fpos2=turtle.dircoord(1,1,0)
    local fpos3=turtle.dircoord(1,0,0)

    local fpos4=turtle.dircoord(2,1,0)
    local fpos5=turtle.dircoord(2,0,0)
    local fpos6=turtle.dircoord(2,-1,0)

    if checknode(fpos1) then scaffold.dig(fpos1) end
    if checknode(fpos3) then scaffold.dig(fpos3) end
    if checknode(fpos2) then scaffold.dig(fpos2) end

    local lp=minetest.localplayer:get_pos()
    local pos1=vector.add(lp,{x=-2,y=0,z=-2})
    local pos2=vector.add(lp,{x=2,y=4,z=2})
    local liquids={'mcl_core:lava_source','mcl_core:water_source','mcl_core:lava_flowing','mcl_core:water_flowing'}
    local liquids={'mcl_core:lava_source','mcl_core:water_source'}

    local bn,cnt=minetest.find_nodes_in_area(pos1,pos2,liquids,false)
    for kk,vv in pairs(bn) do
        minetest.switch_to_item("mcl_nether:netherrack")
        minetest.place_node(vv)
    end

    minetest.after("0.1",function()
        local frpos=turtle.dircoord(1,1,0)
        local fgpos=turtle.dircoord(1,0,0)
        local it = core.find_item("mesecons_torch:redstoneblock")
        if not it then minetest.settings:set_bool('continuous_forward',false) end
        scaffold.place_if_needed(ground, below)
        scaffold.place_if_needed(rails, lp)
        scaffold.place_if_needed(ground, fgpos)
        scaffold.place_if_needed(rails, frpos)

    end)
    if minetest.settings:get_bool('scaffold_railtunnel') then
        scaffold.place_if_needed(tunnelmaterial, turtle.dircoord(0,3,0))
        scaffold.place_if_needed(tunnelmaterial, turtle.dircoord(0,2,1))
        scaffold.place_if_needed(tunnelmaterial, turtle.dircoord(0,1,1))
        scaffold.place_if_needed(tunnelmaterial, turtle.dircoord(0,2,-1))
        scaffold.place_if_needed(tunnelmaterial, turtle.dircoord(0,1,-1))
    end
end)
