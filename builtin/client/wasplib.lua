
ws = {}
ws.registered_globalhacks = {}
ws.displayed_wps={}

ws.lp = minetest.localplayer
ws.c = core

local nextact = {}
local ghwason={}

function ws.s(name,value)
    if value == nil then
        return ws.c.settings:get(name)
    else
        ws.c.settings:set(name,value)
        return ws.c.settings:get(name)
    end
end

function ws.dcm(msg)
    return minetest.display_chat_message(msg)
end

function ws.globalhacktemplate(setting,func,funcstart,funcstop)
    funcstart = funcstart or function() end
    funcstop = funcstop or function() end
    return function()
        if not minetest.localplayer then return end
        if minetest.settings:get_bool(setting) then
            if nextact[setting] and nextact[setting] > os.clock() then return end
            nextact[setting] = os.clock() + 0.1
            if not ghwason[setting] then
                funcstart()
                ws.dcm(setting.. " activated")
                ghwason[setting] = true
            else
                func()
            end

        elseif ghwason[setting] then
            ghwason[setting] = false
            funcstop()
            ws.dcm(setting.. " deactivated")
        end
    end
end

function ws.register_globalhack(func)
    table.insert(ws.registered_globalhacks,func)
end

function ws.register_globalhacktemplate(name,category,setting,func,funcstart,funcstop)
    ws.register_globalhack(ws.globalhacktemplate(setting,func,funcstart,funcstop))
    minetest.register_cheat(name,category,setting)
end

ws.rg=ws.register_globalhacktemplate

function ws.step_globalhacks()
    for i, v in ipairs(ws.registered_globalhacks) do
        v()
    end
end

minetest.register_globalstep(ws.step_globalhacks)

function ws.get_reachable_positions(range)
    range=range or 2
    local rt={}
    for x = -range,range,1 do
        for y = -range,range,1 do
            for z = -range,range,1 do
                table.insert(rt,vector.new(x,y,z))
            end
        end
    end
    return rt
end

function ws.do_area(radius,func,plane)
    for k,v in pairs(ws.get_reachable_positions(range)) do
        if not plane or v.y == ws.lp:get_pos().y -1 then
            func(v)
        end
    end
end


function ws.display_wp(pos,name)
    table.insert(ws.displayed_wps,minetest.localplayer:hud_add({
            hud_elem_type = 'waypoint',
            name          = name,
            text          = name,
            number        = 0x00ff00,
            world_pos     = pos
        }))
end

function ws.clear_wps()
    for k,v in pairs(ws.displayed_wps) do
        ws.lp:hud_remove(v)
        table.remove(ws.displayed_wps,k)
    end
end

function ws.on_connect(func)
	if not minetest.localplayer then minetest.after(0,function() ws.on_connect(func) end) return end
	if func then func() end
end

ws.on_connect(function()
    ws.lp=minetest.localplayer
end)
