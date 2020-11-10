minetest.register_globalstep(function()
    if minetest.settings:get_bool("movement_ignore_server_speed") then
        minetest.localplayer:set_override_speed()
    end
end)

minetest.register_cheat("IgnoreServerSpeed", "Movement", "movement_ignore_server_speed")
