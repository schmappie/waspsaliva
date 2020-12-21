-- CC0/Unlicense Emilia 2020

local dirt = {
    "mesecons_torch:redstoneblock"
}

local saplings = {
    "mcl_minecarts:golden_rail"
}

local function checknode(pos)
    local node = minetest.get_node_or_nil(pos)
    if node and node.name ~="mesecons_torch:redstoneblock" and node.name ~= "mcl_minecarts:golden_rail"  then return true end
    return false
end

scaffold.register_template_scaffold("RailScaffold", "scaffold_rails", function(below)
    local lp = vector.round(minetest.localplayer:get_pos())

    local fpos1=turtle.dircoord(1,2,0)
    local fpos2=turtle.dircoord(1,1,0)
    local fpos3=turtle.dircoord(1,0,0)

    if checknode(fpos2) then scaffold.dig(fpos2) end
    if checknode(fpos3) then scaffold.dig(fpos3) end
    if checknode(fpos1) then scaffold.dig(fpos1) end
    --if checknode(fpos2) then minetest.after("0",function() scaffold.dig(fpos2) end) end
    --if checknode(fpos3) then minetest.after("0",function() scaffold.dig(fpos3) end) end
    minetest.after("0.1",function()
        if scaffold.place_if_needed(dirt, below) then
            scaffold.place_if_needed(saplings, lp)
        end
    end)
end)