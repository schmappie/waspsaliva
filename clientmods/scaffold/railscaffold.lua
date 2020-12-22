-- CC0/Unlicense Emilia/cora 2020

local ground = {
    "mesecons_torch:redstoneblock"
}

local rails = {
    "mcl_minecarts:golden_rail",
    "mcl_minecarts:rail"
}

local tunnelmaterial = {
    'mcl_core:cobble',
    'mcl_core:andesite',
    'mcl_core:diorite',
    'mcl_core:granite',
    'mcl_core:dirt'
}
minetest.register_cheat("RailT",'Scaffold','scaffold_railtunnel')
local function checknode(pos)
    local node = minetest.get_node_or_nil(pos)
    if node and node.name ~="mesecons_torch:redstoneblock" and not node.name:find("_rail")  then return true end
    return false
end

scaffold.register_template_scaffold("RailScaffold", "scaffold_rails", function(below)
    local lp = vector.round(minetest.localplayer:get_pos())

    local fpos1=turtle.dircoord(1,1,0)
    local fpos2=turtle.dircoord(1,0,0)
    local fpos3=turtle.dircoord(1,-1,0)

    if checknode(fpos2) then scaffold.dig(fpos2) end
    if checknode(fpos3) then scaffold.dig(fpos3) end
    if checknode(fpos1) then scaffold.dig(fpos1) end

    minetest.after("0.1",function()
        if scaffold.place_if_needed(ground, below) then
            scaffold.place_if_needed(rails, lp)
        end
    end)
    if minetest.settings:get_bool('scaffold_railtunnel') then
        scaffold.place_if_needed(tunnelmaterial, turtle.dircoord(0,2,0))
        scaffold.place_if_needed(tunnelmaterial, turtle.dircoord(0,0,1))
        scaffold.place_if_needed(tunnelmaterial, turtle.dircoord(0,1,1))
        scaffold.place_if_needed(tunnelmaterial, turtle.dircoord(0,0,-1))
        scaffold.place_if_needed(tunnelmaterial, turtle.dircoord(0,1,-1))
    end
end)
