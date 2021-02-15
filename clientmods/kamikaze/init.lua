local fnd=false
local cpos=vector.new(0,0,0)
local hud_wp=nil
local zz=vector.new(42,42,42)
local badnodes={'mcl_tnt:tnt','mcl_fire:basic_flame','mcl_fire:fire','mcl_banners:hanging_banner','mcl_banners:standing_banner','mcl_fire:fire_charge','mcl_sponges:sponge','mcl_sponges:sponge_wet','mcl_nether:soul_sand','mcl_heads:wither_skeleton'}
local badobs={'mcl_end_crystal','arrow_box','mobs_mc_wither.png'}
local searchtxt=nil
local searchheight=64
local tob=nil

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
    zz.x=math.random(-128,129)
    zz.y=math.random(0,searchheight)
    zz.z=math.random(-128,128)
    nextzz=os.clock()+ 30
end
local function find_ob(txts)
    local odst=500
    local rt=nil
    local obs=minetest.localplayer.get_nearby_objects(500)
    for k, v in ipairs(obs) do
        for kk,txt in pairs(txts) do
            if ( v:get_item_textures():find(txt) ) then
                local npos=v:get_pos()
                local dst=vector.distance(npos,minetest.localplayer:get_pos())
                if odst > dst then
                    searchtxt=v:get_item_textures()
                    cpos=npos
                    set_kwp(searchtxt,v:get_pos())
                    odst=dst
                    fnd=true
                    tob=v
                    rt=v
                end
            end
        end
    end
    return rt
end
local function find_nd(names)
    local lp=minetest.localplayer:get_pos()
    local epos=minetest.find_nodes_near(lp,60,names,true)
    local rt=nil
    local odst=500
    if epos then
        for k,v in pairs(epos) do
            local node=minetest.get_node_or_nil(v)
            local lp=minetest.localplayer:get_pos()
            local dst=vector.distance(lp,v)
            if odst > dst then
                    odst=dst
                    cpos=vv
                    rt=vv
                    fnd=true
            end
        end
    end
    return rt
end


local function find_bad_things()
    if fnd then return true end
    local lp=minetest.localplayer:get_pos()
    local ob=find_ob(badobs)
    if not ob then ob=find_nd(badnodes) end
    if not ob then
        set_kwp('nothing found',zz)
        randomzz()
        fnd=false
        return false
    end
    return true
end



local function flythere()
    if not minetest.localplayer then return end
    if not cpos then return end
    ws.aim(cpos)
    if incremental_tp.tpactive then return end
    local lp=minetest.localplayer:get_pos()
    local dst=vector.distance(lp,cpos)
    if tob and tob:get_item_textures() == searchtxt then
        dst=vector.distance(lp,tob:get_pos())
        cpos=tob:get_pos()
        set_kwp(searchtxt,cpos)
    end
    minetest.settings:set_bool("continuous_forward",true)
    if dst < 2 then
         minetest.settings:set_bool("continuous_forward",false)
    end
    --incremental_tp.tp(cpos,1)
end
local nextthrow=0
local function throwegg()
    if nextthrow > os.clock() then return false end
    nextthrow=os.clock() + 0.5
    if not ws.switch_inv_or_echest('mcl_throwing:snowball',1) then
        ws.switch_inv_or_echest('mcl_throwing:egg',1)
    end
    ws.aim(cpos)
    minetest.interact('use')
end

local function stopflight()
    local lp = minetest.localplayer:get_pos()
    local dst=vector.distance(lp,cpos)
    minetest.settings:set_bool("continuous_forward",false)
    if tob and tob:get_item_textures():find(searchtxt) then
        if tob and searchtxt == 'mcl_end_crystal.png' and dst < 5 then
            throwegg()
            searchtxt=""
        end
    end
    fnd=false
    tob=nil
end



ws.rg('Kamikaze','Bots','kamikaze', function()
    local lp = minetest.localplayer:get_pos()
    local dst=vector.distance(lp,cpos)
    if not find_bad_things() then
        if vector.distance(lp,zz) < 4 then
            stopflight()
        else
            cpos=zz
        end
    elseif dst < 4 then
        stopflight()
    else
    end
    flythere()
    ws.dignodes(minetest.find_nodes_near(minetest.localplayer:get_pos(),5,badnodes,true))
    if cpos then
       -- minetest.dig_node(cpos)
       -- minetest.interact('start_digging')
        minetest.settings:set_bool("killaura",true)
    end

end,function()
    core.set_keypress("special1", true)
end, function()
    core.set_keypress("special1", false)
    fnd=false
    if hud_wp then
        minetest.localplayer:hud_remove(hud_wp)
        hud_wp=nil
    end
end,{"noclip","pitch_move","dighead"})



minetest.register_on_death(function()
    if not minetest.settings:get_bool("kamikaze") then return end
    tob=nil
--    incremental_tp.tpactive=false
    minetest.after("5.0",function()
        fnd=false
    end)
end)

ws.on_connect(function()
    if minetest.localplayer and minetest.localplayer:get_name():find("kamikaze") then
        minetest.settings:set_bool("kamikaze",true)
    else  minetest.settings:set_bool("kamikaze",false)
    end
end)

minetest.register_cheat('KamiCrystals','Bots','kamikaze_crystals')
