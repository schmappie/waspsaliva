-- CC0/Unlicense Emilia 2020

-- Optimizes stuff.

-- texture is a prefix
local function remove_drops(texture)
    local obj = minetest.localplayer.get_nearby_objects(10000)

    for i, v in ipairs(obj) do
        -- CAOs with water/lava textures are droplets
        if v:get_item_textures():find("^" .. texture) then
            v:set_visible(false)
            v:remove_from_scene(true)
        end
    end
end

local epoch = 0

minetest.register_globalstep(function()
    if os.clock() > epoch + 1 then
        if minetest.settings:get_bool("optimize_water_drops") then
            remove_drops("default_water_source")
        end

        epoch = os.clock()
    end
end)
