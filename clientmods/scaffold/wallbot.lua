local wall_pos1={x=-1254,y=-4,z=791}
local wall_pos2={x=-1454,y=80,z=983}
local iwall_pos1={x=-1264,y=-4,z=801}
local iwall_pos2={x=-1444,y=80,z=973}

local bpos = {
    {x=-1265,y=40,z=802},
    {x=-1265,y=40,z=972},
    {x=-1443,y=40,z=972},
    {x=-1443,y=40,z=802}
}

local wbtarget = bpos[1]


local function between(x, y, z) -- x is between y and z (inclusive)
    return y <= x and x <= z
end

local function mkposvec(vec)
    vec.x=vec.x + 30927
    vec.y=vec.y + 30927
    vec.z=vec.z + 30927
    return vec
end

local function normvec(vec)
    vec.x=vec.x - 30927
    vec.y=vec.y - 30927
    vec.z=vec.z - 30927
    return vec
end

local function in_cube(tpos,wpos1,wpos2)
    local xmax=wpos2.x
    local xmin=wpos1.x

    local ymax=wpos2.y
    local ymin=wpos1.y

    local zmax=wpos2.z
    local zmin=wpos1.z
    if wpos1.x > wpos2.x then
        xmax=wpos1.x
        xmin=wpos2.x
    end
    if wpos1.y > wpos2.y then
        ymax=wpos1.y
        ymin=wpos2.y
    end
    if wpos1.z > wpos2.z then
        zmax=wpos1.z
        zmin=wpos2.z
    end
    if between(tpos.x,xmin,xmax) and between(tpos.y,ymin,ymax) and between(tpos.z,zmin,zmax) then
        return true
    end
    return false
end

local function in_wall(pos)
    if in_cube(pos,wall_pos1,wall_pos2) and not in_cube(pos,iwall_pos1,iwall_pos2) then
        return true end
    return false
end

scaffold.register_template_scaffold("WallTool", "scaffold_walltool", function(pos)
    local lp=minetest.localplayer:get_pos()
    local p1=vector.add(lp,{x=5,y=5,z=5})
    local p2=vector.add(lp,{x=-5,y=-5,z=-5})
    local nn=nlist.get_mclnodes()
    table.insert(nn,'air')
    local nds,cnt=minetest.find_nodes_in_area(p1,p2,nn,true)
    for k,v in pairs(nds) do for kk,vv in pairs(v) do
        if vv and in_wall(vv) then
            scaffold.place_if_needed({'mcl_core:cobble'},vv)
            local nd=minetest.get_node_or_nil(vv)
            if nd and nd.name ~= 'mcl_core:cobble' then
                scaffold.dig(vv)
            end
        end
    end end
end)
local posi=1

local function flythere()
    minetest.settings:set_bool('noclip',true)
    minetest.settings:set_bool('scaffold_walltool',true)
    minetest.settings:set_bool("pitch_move",true)
    minetest.settings:set_bool("free_move",true)
    minetest.settings:set_bool("continuous_forward",true)
    autofly.aim(wbtarget)
    core.set_keypress("special1", true)
end

local function stopflight()
    minetest.settings:set_bool("continuous_forward",false)
    minetest.settings:set_bool('scaffold_walltool',false)
    minetest.settings:set_bool("noclip",false)
    minetest.settings:set_bool("pitch_move",false)
    core.set_keypress("special1", false)
end

local function findholes()
    local lp=minetest.localplayer:get_pos()
    local p1=vector.add(lp,{x=15,y=60,z=15})
    local p2=vector.add(lp,{x=-15,y=-60,z=-15})
    local nn=nlist.get_mclnodes()
    table.insert(nn,'air')
    local nds,cnt=minetest.find_nodes_in_area(p1,p2,nn,true)
        for k,v in pairs(nds) do for kk,vv in pairs(v) do
        if vv and in_wall(vv) then
            wbtarget=vv
        end
    end end
end
math.randomseed(os.time())
scaffold.register_template_scaffold("WallABot", "scaffold_wallabot", function(pos)
    local lp=minetest.localplayer:get_pos()
    if vector.distance(lp,bpos[posi]) < 3 then
        posi=posi+1
        if posi > 4 then posi=1 end
        wbtarget=bpos[posi]
        wbtarget.y=math.random(15,65)
    end
    local tn=minetest.get_node_or_nil(wbtarget)
    if tn and tn.name == 'mcl_core:cobble' then wbtarget=bpos[i] end
    flythere()
    findholes()
end,false,function()
    stopflight()
end)
