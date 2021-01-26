-- CC0/Unlicense Emilia 2020

-- Optimizes stuff.

-- texture is a prefix
local function remove_ents(texture)
    if not minetest.localplayer then return end
    local obj = minetest.localplayer.get_nearby_objects(10000)

    for i, v in ipairs(obj) do
        -- CAOs with water/lava textures are droplets
        --minetest.log("ERROR",v:get_item_textures())
        if v:get_item_textures():find("^" .. texture) then
            v:set_visible(false)
            v:remove_from_scene(true)
        end
    end
end


core.register_on_spawn_particle(function(particle)
    if minetest.settings:get_bool("noparticles") then return true end
end)

local epoch = os.clock()

minetest.register_globalstep(function()
    if os.clock() > epoch + 1 then
        if minetest.settings:get_bool("optimize_water_drops") then
            remove_ents("default_water_source")
        end
        epoch = os.clock()
    end
end)


minetest.register_cheat("NoParticles", "Render", "noparticles")
minetest.register_cheat("NoDroplets", "Render", "optimize_water_drops")
minetest.register_cheat("NoHearts", "Render", "optimize_hearts")
