-- CC0/Unlicense Emilia 2020

local seeds = {
    "mcl_farming:wheat_seeds",
    "mcl_farming:beetroot_seeds",
    "mcl_farming:carrots",
    "mcl_farming:potatoes"
}

local nodeseeds = {
    "mcl_farming:melon_seeds",
    "mcl_farming:pumpkin_seeds"
}

local tillable = {
    "mcl_core:dirt",
    "mcl_core:dirt_with_grass",
    "mcl_farming:soil"
}

local hoes = {
    "mcl_farming:hoe_wood",
    "mcl_farming:hoe_stone",
    "mcl_farming:hoe_iron",
    "mcl_farming:hoe_gold",
    "mcl_farming:hoe_diamond"
}

local water = {
    "mcl_core:water_source",
    "mcl_buckets:bucket_water",
    "mcl_buckets:bucket_river_water"
}

scaffold.register_template_scaffold("AutoFarm", "scaffold_farm", function(below)
    local lp = vector.round(minetest.localplayer:get_pos())

    -- farmland
    if below.x % 2 ~= 0 or below.z % 2 ~= 0 then
        if scaffold.place_if_needed(tillable, below) then
            if scaffold.can_place_at(lp) then
                if scaffold.find_any_swap(hoes) then
                    minetest.interact("place", below)
                    scaffold.place_if_needed(seeds, lp)
                end
            end
        end
    -- water
    else
        scaffold.place_if_needed(water, below)
    end
end)
