local wall_pos1={x=-1254,y=-4,z=791} --not the exact ones rn
local wall_pos2={x=-1454,y=80,z=983}
local iwall_pos1={x=-1264,y=-4,z=801}
local iwall_pos2={x=-1444,y=80,z=973}



local function between(x, y, z) -- x is between y and z (inclusive)
    return y <= x and x <= z
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
