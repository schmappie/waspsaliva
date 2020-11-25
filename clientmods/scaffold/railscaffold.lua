-- CC0/Unlicense Emilia 2020

local dirt = {
    "mesecons_torch:redstoneblock"
}

local saplings = {
    "mcl_minecarts:golden_rail"
}

scaffold.register_template_scaffold("RailScaffold", "scaffold_rails", function(below)
    local lp = vector.round(minetest.localplayer:get_pos())

    if scaffold.place_if_needed(dirt, below) then
        scaffold.place_if_needed(saplings, lp)
    end
end)
