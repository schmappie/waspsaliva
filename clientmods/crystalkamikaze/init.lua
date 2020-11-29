local fnd=false
local cpos={x=0,y=0,z=0}
local crange=250
local hud_wp=nil
local zz={x=0,y=64,z=0}

local function set_kwp(name,pos)
    if hud_wp then
        minetest.localplayer:hud_change(hud_wp, 'world_pos', pos)
        minetest.localplayer:hud_change(hud_wp, 'name', name)
    else
        hud_wp = minetest.localplayer:hud_add({
            hud_elem_type = 'waypoint',
            name          = name,
            text          = 'm',
            number        = 0x00ff00,
            world_pos     = pos
        })
    end
end

local function find_crystal()
    if fnd then return cpos end
    local obs=minetest.localplayer.get_nearby_objects(crange)
    for k, v in ipairs(obs) do
		if ( v:get_item_textures():find("mcl_end_crystal") ) then
                cpos=v:get_pos()
                set_kwp(v:get_item_textures(),v:get_pos())
                fnd=true
                return true
        end
    end
    for k, v in ipairs(obs) do
		if ( v:get_item_textures():find("arrow_box") ) then
                cpos=v:get_pos()
                set_kwp(v:get_item_textures(),v:get_pos())
                fnd=true
                return true
        end
    end

    --minetest.display_chat_message("crystalKamikaze: nothing found. flying to 0,0,0")
    fnd=false
    return false
end

minetest.register_globalstep(function()
    if not minetest.settings:get_bool("crystalkamikaze") and not minetest.localplayer:get_name():find("kamikaze") then return end

    local lp = minetest.localplayer:get_pos()
    if not find_crystal() then
        set_kwp('nothing found',zz)
        if vector.distance(lp,zz) < 1 then
            minetest.settings:set_bool("continuous_forward",false)
            core.set_keypress("special1", false)
        else
            autofly.aim(zz)
            minetest.settings:set_bool('noclip',true)
            minetest.settings:set_bool("pitch_move",true)
            minetest.settings:set_bool("continuous_forward",true)
        end
    elseif vector.distance(lp,cpos) < 1 then
        minetest.settings:set_bool("continuous_forward",false)
        core.set_keypress("special1", false)
        fnd=false
        minetest.after("2.0",function() if fnd then find_crystal() end end)
    else
        minetest.settings:set_bool('noclip',true)
        minetest.settings:set_bool("pitch_move",true)
        minetest.settings:set_bool("continuous_forward",true)
        autofly.aim(cpos)
        core.set_keypress("special1", true)
    end
end)

minetest.register_on_death(function()
    if not minetest.settings:get_bool("crystalkamikaze") then return end
    fnd=false
end)



minetest.register_chatcommand('sctest',{func=function() minetest.localplayer:set_control() end})

minetest.register_cheat("CrystalKamikaze", "Combat", "crystalkamikaze")
