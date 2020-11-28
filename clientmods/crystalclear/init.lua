local fnd=false
local cpos={x=0,y=0,z=0}
local function find_crystal()
    if fnd then return cpos end
    for k, v in ipairs(minetest.localplayer.get_nearby_objects(100)) do
		if ( v:get_item_textures():find("mcl_end_crystal")) then
                cpos=v:get_pos()
                fnd=true
                return cpos
        end
    end
end

minetest.register_globalstep(function()
    if minetest.settings:get_bool("crystalclear") then
        minetest.settings:set_bool('noclip',true)
        minetest.settings:set_bool("pitch_move",true)
        minetest.settings:set_bool("continuous_forward",true)
        find_crystal()
        autofly.aim(cpos)
        core.set_keypress("special1", true)
    end
end)

minetest.register_on_death(function()
    if not minetest.settings:get_bool("crystalclear") then return end
    fnd=false
end)

minetest.register_cheat("crystalClear", "Combat", "crystalclear")
