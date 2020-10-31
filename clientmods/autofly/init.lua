-- autofly by cora
-- gui shit shamelessly stolen from advmarkers
-- https://git.minetest.land/luk3yx/advmarkers-csm
--[[
    PATCHING MINETEST: (for autoaim)
in l_localplayer.h add:
	static int l_set_yaw(lua_State *L);
	static int l_set_pitch(lua_State *L);

in l_localplayer.cpp add:
    int LuaLocalPlayer::l_set_yaw(lua_State *L)
    {
        LocalPlayer *player = getobject(L, 1);
        f32 p = (float) luaL_checkinteger(L, 2);
        player->setYaw(p);
        g_game->cam_view.camera_yaw = p;
        g_game->cam_view_target.camera_yaw = p;
        player->setYaw(p);
        return 0;
    }
    int LuaLocalPlayer::l_set_pitch(lua_State *L)
    {
        LocalPlayer *player = getobject(L, 1);
        f32 p = (float) luaL_checkinteger(L, 2);
        player->setPitch(p);
        g_game->cam_view.camera_pitch = p;
        g_game->cam_view_target.camera_pitch = p;
        player->setPitch(p);
        return 0;
    }
in src/client/game.h, below class Game { public: add:
	CameraOrientation cam_view = {0};
	CameraOrientation cam_view_target  = { 0 };

from src/client/game.cpp remove
    CameraOrientation cam_view = {0};
	CameraOrientation cam_view_target  = { 0 };

--]]

-- Chat commands:
-- .wa x,y,z name - add waypoint with coords and name
-- .wah - quickadd this location (name will be time and date)
-- .wp - open the selection menu
-- .cls - remove hud

autofly = {}
wps={}
local landing_distance=100
local speed=0;
local ltime=0

local storage = minetest.get_mod_storage()
local wpr=false;
local twpname=nil
local oldpm=false
local info=minetest.get_server_info()
local stprefix="autofly-".. info['address']  .. '-'

local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)
dofile(modpath .. "/wpforms.lua")

local hud_wp
local hud_info
-- /COMMON
local function pos_to_string(pos)
    if type(pos) == 'table' then
        pos = minetest.pos_to_string(vector.round(pos))
    end
    if type(pos) == 'string' then
        return pos
    end
end

local function string_to_pos(pos)
    if type(pos) == 'string' then
        pos = minetest.string_to_pos(pos)
    end
    if type(pos) == 'table' then
        return vector.round(pos)
    end
end
function round2(num, numDecimalPlaces)
  return tonumber(string.format("%." .. (numDecimalPlaces or 0) .. "f", num))
end

minetest.register_globalstep(function()
    autofly.checkfall()
    if minetest.settings:get_bool("autosprint") then
        core.set_keypress("special1", true)
    elseif minetest.settings:get_bool("continuous_forward") and minetest.settings:get_bool("autofsprint") then
        core.set_keypress("special1", true)
    end
    if not minetest.localplayer then return end
    if not twpname then
         autofly.set_hud_info("")
    else
        local pos = string_to_pos(autofly.get_waypoint(twpname))
        if pos then
            local dst = vector.distance(pos,minetest.localplayer:get_pos())
            local etatime=-1
            if not (speed == 0) then etatime = round2(dst / speed / 60,2) end
            autofly.set_hud_info(twpname .. "\n" .. pos_to_string(pos) .. "\n" .. "ETA" .. etatime .. " mins")
            if twpname and dst < landing_distance then
                autofly.arrived()
            end
        end
    end
    if twpname and (minetest.settings:get_bool('afly_autoaim')) then
        autofly.aim(autofly.get_waypoint(twpname))
        core.set_keypress("special1", true)
    end

    if ( os.time() < ltime + 1 ) then return end
    ltime=os.time()
    if lpos then
        local dst=vector.distance(minetest.localplayer:get_pos(),lpos)
        speed=round2(dst,1)
    end
    lpos=minetest.localplayer:get_pos()
end)

function autofly.getwps()
    local wp={}
    for name, _ in pairs(storage:to_table().fields) do
        if name:sub(1, string.len(stprefix)) == stprefix then
            table.insert(wp, name:sub(string.len(stprefix)+1))
        end
    end
    table.sort(wp)
    return wp
end

function autofly.set_hud_wp(pos, title)
    if hud_wp then
            minetest.localplayer:hud_remove(hud_wp)
    end
    pos = string_to_pos(pos)
    hud_wp=nil
    if not pos then return end
    if not title then
        title = pos.x .. ', ' .. pos.y .. ', ' .. pos.z
    end
    twpname=title
    if hud_wp then
        minetest.localplayer:hud_change(hud_wp, 'name', title)
        minetest.localplayer:hud_change(hud_wp, 'world_pos', pos)
    else
        hud_wp = minetest.localplayer:hud_add({
            hud_elem_type = 'waypoint',
            name          = title,
            text          = 'm',
            number        = 0x00ff00,
            world_pos     = pos
        })
    end
    minetest.display_chat_message('Waypoint set to ' .. title)
       -- minetest.colorize('#00ffff', title))
    return true
end

local hud_info
function autofly.set_hud_info(text)
    if not minetest.localplayer then return end
    local vspeed=minetest.localplayer:get_last_velocity()
    local ttext=text.."\nSpeed: "..speed.."n/s\n"..round2(vspeed.x / 10,1)..','..round2(vspeed.y / 10,1)..','..round2(vspeed.z / 10,1)
    if hud_info then
        minetest.localplayer:hud_change(hud_info,'text',ttext)
    else
        hud_info = minetest.localplayer:hud_add({
            hud_elem_type = 'text',
            name          = "Flight Info",
            text          = ttext,
            number        = 0x00ff00,
            direction   = 0,
            position = {x=0.75,y=0.9},
            alignment ={x=1,y=1},
            offset = {x=0, y=0}
        })
    end
    return true
end


function autofly.arrived()
        minetest.settings:set("continuous_forward", "false")
        minetest.settings:set("afly_autoaim", "false")
        autofly.set_hud_info("Arrived at destination")
        minetest.sound_play({name = "sounds/autofly_arrived", gain = 1.0})
        wpr=false
        twpname=nil
end

function autofly.checkfall()
    if(speed > 30) then
        local nod=minetest.get_node_or_nil(vector.add(minetest.localplayer:get_pos(),{x=0,y=-100,z=0}))
        if nod and not ( nod['name'] == "air" ) then
            minetest.settings:set("free_move", "true")
            minetest.settings:set("noclip", "false")
            minetest.display_chat_message("fall detected")
        end

    end
end

function autofly.display_waypoint(name)
        autofly.last_coords = autofly.get_waypoint(name)
        autofly.last_name = name
        autofly.set_hud_info(name)
        autofly.aim(autofly.last_coords)
    return autofly.set_hud_wp(autofly.get_waypoint(name), name)
end

function autofly.goto_waypoint(name)
        oldpm=minetest.settings:get_bool("pitch_move")
        minetest.settings:set_bool("pitch_move",true)
        minetest.settings:set_bool("continuous_forward",true)
        autofly.last_coords = autofly.get_waypoint(name)
        autofly.last_name = name
        autofly.set_hud_info(name)
        --minetest.settings:set("movement_speed_walk", "5")
        autofly.aim(autofly.last_coords)
        core.set_keypress("special1", true)
    return autofly.set_hud_wp(autofly.get_waypoint(name), name)
end

function autofly.arrived()
        minetest.settings:set("continuous_forward", "false")
        minetest.settings:set_bool("pitch_move",oldpm)
         core.set_keypress("special1", false)
        autofly.set_hud_info("Arrived at destination")
        minetest.localplayer:hud_change(hud_info,'text',twpname .. "\n" .. "Arrived at destination.")
        wpr=false
        twpname=nil
end

function autofly.checkfall()
    if(speed > 30) then
        local nod=minetest.get_node_or_nil(vector.add(minetest.localplayer:get_pos(),{x=0,y=-100,z=0}))
        if nod and not ( nod['name'] == "air" ) then
          --  minetest.display_chat_message("Autofly: Fall to ground detected!")
         --   minetest.display_chat_message("Deactivating noclip.")
            minetest.settings:set("noclip", "false")
            if(minetest.settings:get_bool("afly_softlanding")) then
             --   minetest.display_chat_message("Soft landing engaged.")
                minetest.settings:set("free_move", "true")
            else
               -- minetest.display_chat_message("Lithobreak imminent – maybe turn on soft landing next time")
            end

        end

    end
end

function autofly.warp(name)
    local pos=vector.add(autofly.get_waypoint(name),{x=0,y=150,z=0})
    if pos then
        minetest.localplayer:set_pos(pos)
        return true, "Warped to " .. minetest.pos_to_string(pos)
    end
end
function autofly.warpae(name)
		local s, m = autofly.warp(name)
		if s then
			minetest.disconnect()
		end
		return s,m
end

function autofly.set_waypoint(pos, name)
    pos = pos_to_string(pos)
    if not pos then return end
    storage:set_string(stprefix .. tostring(name), pos)
    wpr=true
    return true
end

-- Delete a waypoint
function autofly.delete_waypoint(name)
    storage:set_string(stprefix .. tostring(name), '')
end

-- Get a waypoint
function autofly.get_waypoint(name)
    return string_to_pos(storage:get_string(stprefix .. tostring(name)))
end

-- Rename a waypoint and re-interpret the position.
function autofly.rename_waypoint(oldname, newname)
    oldname, newname = tostring(oldname), tostring(newname)
    local pos = autofly.get_waypoint(oldname)
    if not pos or not autofly.set_waypoint(pos, newname) then return end
    if oldname ~= newname then
        autofly.delete_waypoint(oldname)
    end
    return true
end


function autofly.get_chatcommand_pos(pos)
    if pos == 'h' or pos == 'here' then
        pos = minetest.localplayer:get_pos()
    elseif pos == 't' or pos == 'there' then
        if not autofly.last_coords then
            return false, 'No-one has used ".coords" and you have not died!'
        end
        pos = autofly.last_coords
    else
        pos = string_to_pos(pos)
        if not pos then
            return false, 'Invalid position!'
        end
    end
    return pos
end

local function register_chatcommand_alias(old, ...)
    local def = assert(minetest.registered_chatcommands[old])
    def.name = nil
    for i = 1, select('#', ...) do
        minetest.register_chatcommand(select(i, ...), table.copy(def))
    end
end

minetest.register_chatcommand('waypoints', {
    params      = '',
    description = 'Open the autofly GUI',
    func = function(param)
        if param == '' then
            autofly.display_formspec()
        else
            local pos, err = autofly.get_chatcommand_pos(param)
            if not pos then
                return false, err
            end
            if not autofly.set_hud_wp(pos) then
                return false, 'Error setting the waypoint!'
            end
        end
    end
})

register_chatcommand_alias('waypoints','wp', 'wps', 'waypoint')

-- Add a waypoint
minetest.register_chatcommand('add_waypoint', {
    params      = '<pos / "here" / "there"> <name>',
    description = 'Adds a waypoint.',
    func = function(param)
        local s, e = param:find(' ')
        if not s or not e then
            return false, 'Invalid syntax! See .help add_mrkr for more info.'
        end
        local pos = param:sub(1, s - 1)
        local name = param:sub(e + 1)

        -- Validate the position
        local pos, err = autofly.get_chatcommand_pos(pos)
        if not pos then
            return false, err
        end

        -- Validate the name
        if not name or #name < 1 then
            return false, 'Invalid name!'
        end

        -- Set the waypoint
        return autofly.set_waypoint(pos, name), 'Done!'
    end
})
register_chatcommand_alias('add_waypoint','wa', 'add_wp')


minetest.register_chatcommand('add_waypoint_here', {
    params      = 'name',
    description = 'marks the current position',
    func = function(param)
        local name = os.date("%Y-%m-%d %H:%M:%S")
        local pos  = minetest.localplayer:get_pos()
        return autofly.set_waypoint(pos, name), 'Done!'
    end
})
register_chatcommand_alias('add_waypoint_here', 'wah', 'add_wph')
minetest.register_chatcommand('clear_waypoint', {
    params = '',
    description = 'Hides the displayed waypoint.',
    func = function(param)
        if twpname then twpname = nil end
        if hud_wp then
            minetest.localplayer:hud_remove(hud_wp)
            hud_wp = nil
            twpname=nil
            wpr=nil
            return true, 'Hidden the currently displayed waypoint.'
        elseif not minetest.localplayer.hud_add then
            minetest.run_server_chatcommand('clrmrkr')
            return
        elseif not hud_wp then
            return false, 'No waypoint is currently being displayed!'
        end
        for k,v in wps do
            minetest.localplayer:hud_remove(v)
            table.remove(k)
        end

    end,
})

minetest.register_on_death(function()
    if minetest.localplayer then
        local name = 'Death waypoint'
        local pos  = minetest.localplayer:get_pos()
        autofly.last_coords = pos
        autofly.set_waypoint(pos, name)
        minetest.display_chat_message('Added waypoint "' .. name .. '".')
    end
end)

function autofly.aim(tpos)
    local ppos=minetest.localplayer:get_pos()
    --local dir=tpos
    local dir=vector.direction(ppos,tpos)
    local yyaw=0;
    local pitch=0;
    if dir.x < 0 then
        yyaw = math.atan2(-dir.x, dir.z) + (math.pi * 2)
    else
        yyaw = math.atan2(-dir.x, dir.z)
    end
    yyaw = round2(math.deg(yyaw),0)
    pitch = round2(math.deg(math.asin(-dir.y) * 1),0);
    minetest.localplayer:set_yaw(yyaw)
    minetest.localplayer:set_pitch(pitch)

end


register_chatcommand_alias('clear_waypoint', 'cwp','cls')

if (_G["minetest"]["register_cheat"] == nil) then

    minetest.settings:set_bool("afly_autoaim",false)
    minetest.settings:set_bool("afly_softlanding",true)
end
