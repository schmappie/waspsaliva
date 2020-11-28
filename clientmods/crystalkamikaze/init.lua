local fnd=false
local cpos={x=0,y=0,z=0}
local function find_crystal()
    if fnd then return cpos end
    for k, v in ipairs(minetest.localplayer.get_nearby_objects(100)) do
		if ( v:get_item_textures():find("mcl_end_crystal")) then
                cpos=v:get_pos()
                fnd=true
                return true
        end
    end
    return false
end

minetest.register_globalstep(function()
    if not minetest.settings:get_bool("crystalkamikaze") then return end
    if not find_crystal() then return end

    minetest.settings:set_bool('noclip',true)
    minetest.settings:set_bool("pitch_move",true)
    minetest.settings:set_bool("continuous_forward",true)
    autofly.aim(cpos)
    core.set_keypress("special1", true)
end)

minetest.register_on_death(function()
    if not minetest.settings:get_bool("crystalkamikaze") then return end
    fnd=false
end)

minetest.register_cheat("CrystalKamikaze", "Combat", "crystalkamikaze")
