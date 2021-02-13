local fnd=false
local cpos={x=0,y=0,z=0}
local crange=500
local hud_wp=nil
local zz={x=0,y=64,z=0}
local badnodes={'mcl_tnt:tnt','mcl_fire:basic_flame','mcl_fire:eternal_fire','mcl_fire:fire','mcl_fire:fire_charge','mcl_sponges:sponge','mcl_sponges:sponge_wet'}
local searchheight=64

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
local nextzz=0
local function randomzz()
    if nextzz > os.clock() then return false end
    math.randomseed(os.time())
    zz.x=math.random(-128,128)
    zz.y=math.random(64,searchheight)
    zz.z=math.random(-128,128)
    nextzz=os.clock()+ 15
end


local function find_bad_things()
    if fnd then return true end
    local obs=minetest.localplayer.get_nearby_objects(crange)
    local lp=minetest.localplayer:get_pos()
    local odst=500;
    for k, v in ipairs(obs) do -- look for crystals first
		if ( v:get_item_textures():find("mcl_end_crystal") ) then
                local npos=v:get_pos()
                local dst=vector.distance(npos,minetest.localplayer:get_pos())
                if odst > dst then cpos=npos
                    set_kwp(v:get_item_textures(),v:get_pos())
                    fnd=true
                    return true
                end
        end
    end
    odst=500
    for k, v in ipairs(obs) do
		if ( v:get_item_textures():find("arrow_box") ) then
                local npos=v:get_pos()
                local dst=vector.distance(npos,minetest.localplayer:get_pos())
                if odst > dst then cpos=npos
                    set_kwp(v:get_item_textures(),v:get_pos())
                    fnd=true
                    return true
                end
        end
    end
    odst=500
    local epos=minetest.find_nodes_in_area(vector.add(lp,{x=79,y=79,z=79}), vector.add(lp,{x=-79,y=-79,z=-79}), badnodes, true)
    if epos then
        for k,v in pairs(epos) do for kk,vv in pairs(v) do
            local lp=minetest.localplayer:get_pos()
            local dst=vector.distance(lp,vv)
            if odst > dst then odst=dst cpos=vv fnd=true end
        end end
        if fnd then set_kwp('badnode',cpos) return true end
    end

    set_kwp('nothing found',zz)
    randomzz()
    fnd=false
    return false
end



local function flythere()
    minetest.settings:set_bool("continuous_forward",true)
    autofly.aim(cpos)
end

local function stopflight()
    minetest.settings:set_bool("continuous_forward",false)
    minetest.after("0",function()
        minetest.interact("start_digging")
        minetest.dig_node(cpos)
        fnd=false
    end)
end


minetest.register_globalstep(function()
    if not minetest.settings:get_bool("kamikaze") and not(minetest.localplayer and minetest.localplayer:get_name():find("kamikaze")) then

ws.rg('Kamikaze','Bots','kamikaze', function()
    local lp = minetest.localplayer:get_pos()
    if not find_bad_things() then
        if vector.distance(lp,zz) < 1 then
            stopflight()
            return
        else
            cpos=zz
        end
    elseif vector.distance(lp,cpos) < 1 then
        stopflight()
        return
    end
    flythere()

end,function()
    core.set_keypress("special1", true)
end, function()
    core.set_keypress("special1", false)
    fnd=false
    if hud_wp then
        minetest.localplayer:hud_remove(hud_wp)
    end
end,{"noclip","pitch_move"})



minetest.register_on_death(function()
    if not minetest.settings:get_bool("kamikaze") then return end
    minetest.after("5.0",function()
        fnd=false
    end)
end)
