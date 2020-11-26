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
local oldpm=false
local lpos={x=0,y=0,z=0}
local info=minetest.get_server_info()
local stprefix="autofly-".. info['address']  .. '-'
autofly.flying=false
autofly.cruiseheight = 30

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

function autofly.get2ddst(pos1,pos2)
    return vector.distance({x=pos1.x,y=0,z=pos1.z},{x=pos2.x,y=0,z=pos2.z})
end

local last_sprint = false

minetest.register_globalstep(function()
    autofly.axissnap()
    if minetest.settings:get_bool("autosprint") or (minetest.settings:get_bool("continuous_forward") and minetest.settings:get_bool("autofsprint")) then
        core.set_keypress("special1", true)
        last_sprint = true
    elseif last_sprint then
        core.set_keypress("special1", false)
        last_sprint = false
    end


    if not minetest.localplayer then return end
    if not autofly.flying then autofly.set_hud_info("")
     else
        local pos = autofly.last_coords
        if pos then
            local dst = vector.distance(pos,minetest.localplayer:get_pos())
            local etatime=-1
            if not (speed == 0) then etatime = round2(dst / speed / 60,2) end
            autofly.etatime=etatime
            autofly.set_hud_info(autofly.last_name .. "\n" .. pos_to_string(pos) .. "\n" .. "ETA" .. etatime .. " mins")
            if  autofly.flying and dst < landing_distance then
                autofly.arrived()
            end
        end
    end
    if not minetest.settings:get_bool("freecam") and autofly.flying and (minetest.settings:get_bool('afly_autoaim')) then
        autofly.aim(autofly.last_coords)
        --core.set_keypress("special1", true)
    end

    if ( os.time() < ltime + 1 ) then return end
    ltime=os.time()
    if lpos then
        local dst=vector.distance(minetest.localplayer:get_pos(),lpos)
        speed=round2(dst,1)
        autofly.speed=speed
    end
    lpos=minetest.localplayer:get_pos()
    autofly.cruise()
end)


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
    autofly.last_name=title
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
    return true
end

local hud_info
function autofly.set_hud_info(text)
    if not minetest.localplayer then return end
    if type(text) ~= "string" then return end
    local vspeed=minetest.localplayer:get_velocity()
    local ttext=text.."\nSpeed: "..speed.."n/s\n"..round2(vspeed.x,2) ..','..round2(vspeed.y,2) ..','..round2(vspeed.z,2) .."\nYaw:"..round2(minetest.localplayer:get_yaw(),2).."° Pitch:" ..round2(minetest.localplayer:get_pitch(),2).."°"
    if hud_info then
        minetest.localplayer:hud_change(hud_info,'text',ttext)
    else
        hud_info = minetest.localplayer:hud_add({
            hud_elem_type = 'text',
            name          = "Flight Info",
            text          = ttext,
            number        = 0x00ff00,
            direction   = 0,
            position = {x=0,y=0.90},
            alignment ={x=1,y=1},
            offset = {x=0, y=0}
        })
    end
    return true
end



function autofly.display_waypoint(name)
    local pos=autofly.get_waypoint(name)
    autofly.last_name = name
    autofly.last_coords = pos
    autofly.set_hud_info(name)
    autofly.aim(autofly.last_coords)
    autofly.set_hud_wp(autofly.last_coords, autofly.last_name)
    return true
end

function autofly.goto_waypoint(name)
    local wp=autofly.get_waypoint(name)
    autofly.goto(wp)
    autofly.last_name=name
    autofly.display_waypoint(autofly.last_name)
    return true
end

function autofly.goto(pos)
    oldpm=minetest.settings:get_bool("pitch_move")
    minetest.settings:set_bool("pitch_move",true)
    minetest.settings:set_bool("continuous_forward",true)
    if minetest.settings:get_bool("afly_sprint") then
        minetest.settings:set_bool("autofsprint",true)
        minetest.settings:set_bool("autoeat_timed",true)
    end
    minetest.settings:set_bool("afly_autoaim",true)
    autofly.last_coords = pos
    autofly.last_name = minetest.pos_to_string(pos)
    autofly.aim(autofly.last_coords)
    autofly.flying=true
    autofly.set_hud_wp(autofly.last_coords, autofly.last_name)
    return true
end

function autofly.arrived()
    if not autofly.flying then return end
    minetest.settings:set("continuous_forward", "false")
    minetest.settings:set_bool("autofsprint",false)
    minetest.settings:set_bool("pitch_move",oldpm)
    minetest.settings:set_bool("afly_autoaim",false)
    minetest.settings:set_bool("autoeat_timed",false)
    autofly.set_hud_info("Arrived at destination")
    autofly.flying = false
    minetest.localplayer:hud_change(hud_info,'text',autofly.last_name .. "\n" .. "Arrived at destination.")
    minetest.sound_play({name = "default_alert", gain = 1.0})
end

local cruise_wason=false
local nfctr=0
local nodenames_ground = {
    'mcl_core:dirt',
    'mcl_core:stone',
    'mcl_core:sand',
    'mcl_core:redsand',
    'mcl_colorblocks:hardened_clay',
    'mcl_colorblocks:hardened_clay_orange',
    'mcl_colorblocks:hardened_clay_yellow',
    'mcl_colorblocks:hardened_clay_red',
    'mcl_core:endstone',
    'mcl_core:netherrack',
    'mcl_core:gravel',
    'mcl_core:water_source',
    'mcl_core:water_flowing',
    'mcl_core:lava_source',
    'mcl_core:lava_flowing',
    'mcl_core:ice',
    "mcl_anvils:anvil",
"mcl_anvils:update",
"mcl_armor:boots",
"mcl_armor:chestplate",
"mcl_armor:helmet",
"mcl_armor:leggings",
"mcl_banners:banner",
"mcl_banners:hanging",
"mcl_banners:respawn",
"mcl_banners:standing",
"mcl_beds:bed",
"mcl_beds:sleeping",
"mcl_beds:spawn",
"mcl_biomes:chorus",
"mcl_boats:boat",
"mcl_books:book",
"mcl_books:bookshelf",
"mcl_books:signing",
"mcl_books:writable",
"mcl_books:written",
"mcl_bows:arrow",
"mcl_bows:bow",
"mcl_bows:use",
"mcl_brewing:stand",
"mcl_buckets:bucket",
"mcl_cake:cake",
"mcl_cauldrons:cauldron",
"mcl_chests:chest",
"mcl_chests:ender",
"mcl_chests:reset",
"mcl_chests:trapped",
"mcl_chests:update",
"mcl_chests:violet",
"mcl_clock:clock",
"mcl_cocoas:cocoa",
"mcl_colorblocks:concrete",
"mcl_colorblocks:glazed",
"mcl_colorblocks:hardened",
"mcl_comparators:comparator",
"mcl_compass:compass",
"mcl_core:acacialeaves",
"mcl_core:acaciasapling",
"mcl_core:acaciatree",
"mcl_core:acaciawood",
"mcl_core:andesite",
"mcl_core:apple",
"mcl_core:axe",
"mcl_core:barrier",
"mcl_core:bedrock",
"mcl_core:birchsapling",
"mcl_core:birchtree",
"mcl_core:birchwood",
"mcl_core:bone",
"mcl_core:bowl",
"mcl_core:brick",
"mcl_core:cactus",
"mcl_core:charcoal",
"mcl_core:clay",
"mcl_core:coal",
"mcl_core:coalblock",
"mcl_core:coarse",
"mcl_core:cobble",
"mcl_core:cobblestone",
"mcl_core:cobweb",
"mcl_core:darksapling",
"mcl_core:darktree",
"mcl_core:darkwood",
"mcl_core:deadbush",
"mcl_core:diamond",
"mcl_core:diamondblock",
"mcl_core:diorite",
"mcl_core:dirt",
"mcl_core:emerald",
"mcl_core:emeraldblock",
"mcl_core:flint",
"mcl_core:frosted",
"mcl_core:glass",
"mcl_core:gold",
"mcl_core:goldblock",
"mcl_core:granite",
"mcl_core:grass",
"mcl_core:gravel",
"mcl_core:ice",
"mcl_core:iron",
"mcl_core:ironblock",
"mcl_core:jungleleaves",
"mcl_core:junglesapling",
"mcl_core:jungletree",
"mcl_core:junglewood",
"mcl_core:ladder",
"mcl_core:lapisblock",
"mcl_core:lava",
"mcl_core:leaves",
"mcl_core:mat",
"mcl_core:mossycobble",
"mcl_core:mycelium",
"mcl_core:obsidian",
"mcl_core:packed",
"mcl_core:paper",
"mcl_core:pick",
"mcl_core:podzol",
"mcl_core:realm",
"mcl_core:redsand",
"mcl_core:redsandstone",
"mcl_core:redsandstonecarved",
"mcl_core:redsandstonesmooth",
"mcl_core:redsandstonesmooth2",
"mcl_core:reeds",
"mcl_core:replace",
"mcl_core:sand",
"mcl_core:sandstone",
"mcl_core:sandstonecarved",
"mcl_core:sandstonesmooth",
"mcl_core:sandstonesmooth2",
"mcl_core:sapling",
"mcl_core:shears",
"mcl_core:shovel",
"mcl_core:slimeblock",
"mcl_core:snow",
"mcl_core:snowblock",
"mcl_core:spruceleaves",
"mcl_core:sprucesapling",
"mcl_core:sprucetree",
"mcl_core:sprucewood",
"mcl_core:stick",
"mcl_core:stone",
"mcl_core:stonebrick",
"mcl_core:stonebrickcarved",
"mcl_core:stonebrickcracked",
"mcl_core:stonebrickmossy",
"mcl_core:sugar",
"mcl_core:sword",
"mcl_core:tallgrass",
"mcl_core:torch",
"mcl_core:tree",
"mcl_core:vine",
"mcl_core:void",
"mcl_core:water",
"mcl_core:wood",
"mcl_dispenser:dispenser",
"mcl_dispensers:dispenser",
"mcl_dispensers:update",
"mcl_doors:acacia",
"mcl_doors:birch",
"mcl_doors:dark",
"mcl_doors:iron",
"mcl_doors:jungle",
"mcl_doors:register",
"mcl_doors:spruce",
"mcl_doors:trapdoor",
"mcl_doors:wooden",
"mcl_droppers:dropper",
"mcl_droppers:update",
"mcl_dye:black",
"mcl_dye:blue",
"mcl_dye:brown",
"mcl_dye:cyan",
"mcl_dye:dark",
"mcl_dye:green",
"mcl_dye:grey",
"mcl_dye:lightblue",
"mcl_dye:magenta",
"mcl_dye:orange",
"mcl_dye:pink",
"mcl_dye:red",
"mcl_dye:violet",
"mcl_dye:white",
"mcl_dye:yellow",
"mcl_end:chorus",
"mcl_end:dragon",
"mcl_end:end",
"mcl_end:ender",
"mcl_end:purpur",
"mcl_farming:add",
"mcl_farming:beetroot",
"mcl_farming:bread",
"mcl_farming:carrot",
"mcl_farming:cookie",
"mcl_farming:grow",
"mcl_farming:growth",
"mcl_farming:hay",
"mcl_farming:hoe",
"mcl_farming:melon",
"mcl_farming:melontige",
"mcl_farming:mushroom",
"mcl_farming:place",
"mcl_farming:potato",
"mcl_farming:pumkin",
"mcl_farming:pumpkin",
"mcl_farming:pumpkintige",
"mcl_farming:soil",
"mcl_farming:stem",
"mcl_farming:wheat",
"mcl_fences:dark",
"mcl_fences:fence",
"mcl_fences:nether",
"mcl_fire:basic",
"mcl_fire:eternal",
"mcl_fire:fire",
"mcl_fire:flint",
"mcl_fire:smoke",
"mcl_fishing:bobber",
"mcl_fishing:clownfish",
"mcl_fishing:fish",
"mcl_fishing:fishing",
"mcl_fishing:pufferfish",
"mcl_fishing:salmon",
"mcl_flowerpots:flower",
"mcl_flowers:allium",
"mcl_flowers:azure",
"mcl_flowers:blue",
"mcl_flowers:dandelion",
"mcl_flowers:double",
"mcl_flowers:fern",
"mcl_flowers:lilac",
"mcl_flowers:oxeye",
"mcl_flowers:peony",
"mcl_flowers:poppy",
"mcl_flowers:rose",
"mcl_flowers:sunflower",
"mcl_flowers:tallgrass",
"mcl_flowers:tulip",
"mcl_flowers:waterlily",
"mcl_furnaces:flames",
"mcl_furnaces:furnace",
"mcl_furnaces:update",
"mcl_heads:creeper",
"mcl_heads:skeleton",
"mcl_heads:wither",
"mcl_heads:zombie",
"mcl_hoppers:hopper",
"mcl_hoppers:update",
"mcl_hunger:exhaustion",
"mcl_hunger:hunger",
"mcl_hunger:saturation",
"mcl_inventory:workbench",
"mcl_itemframes:item",
"mcl_itemframes:respawn",
"mcl_itemframes:update",
"mcl_jukebox:jukebox",
"mcl_jukebox:record",
"mcl_maps:empty",
"mcl_maps:filled",
"mcl_meshhand:hand",
"mcl_minecarts:activator",
"mcl_minecarts:check",
"mcl_minecarts:chest",
"mcl_minecarts:command",
"mcl_minecarts:detector",
"mcl_minecarts:furnace",
"mcl_minecarts:get",
"mcl_minecarts:golden",
"mcl_minecarts:hopper",
"mcl_minecarts:is",
"mcl_minecarts:minecart",
"mcl_minecarts:rail",
"mcl_minecarts:tnt",
"mcl_minecarts:velocity",
"mcl_mobitems:beef",
"mcl_mobitems:blaze",
"mcl_mobitems:bone",
"mcl_mobitems:carrot",
"mcl_mobitems:chicken",
"mcl_mobitems:cooked",
"mcl_mobitems:ender",
"mcl_mobitems:feather",
"mcl_mobitems:ghast",
"mcl_mobitems:gunpowder",
"mcl_mobitems:leather",
"mcl_mobitems:magma",
"mcl_mobitems:milk",
"mcl_mobitems:mutton",
"mcl_mobitems:nether",
"mcl_mobitems:porkchop",
"mcl_mobitems:rabbit",
"mcl_mobitems:rotten",
"mcl_mobitems:saddle",
"mcl_mobitems:shulker",
"mcl_mobitems:slimeball",
"mcl_mobitems:spider",
"mcl_mobitems:string",
"mcl_mobs:nametag",
"mcl_mobspawners:doll",
"mcl_mobspawners:respawn",
"mcl_mobspawners:spawner",
"mcl_mushrooms:brown",
"mcl_mushrooms:mushroom",
"mcl_mushrooms:red",
"mcl_mushrooms:replace",
"mcl_nether:glowstone",
"mcl_nether:magma",
"mcl_nether:nether",
"mcl_nether:netherbrick",
"mcl_nether:netherrack",
"mcl_nether:quartz",
"mcl_nether:red",
"mcl_nether:soul",
"mcl_observers:observer",
"mcl_ocean:dead",
"mcl_ocean:dried",
"mcl_ocean:kelp",
"mcl_ocean:prismarine",
"mcl_ocean:sea",
"mcl_ocean:seagrass",
"mcl_paintings:painting",
"mcl_playerplus:surface",
"mcl_player:preview",
"mcl_portals:end",
"mcl_portals:portal",
"mcl_potions:awkward",
"mcl_potions:dragon",
"mcl_potions:fermented",
"mcl_potions:fire",
"mcl_potions:glass",
"mcl_potions:harming",
"mcl_potions:healing",
"mcl_potions:invisibility",
"mcl_potions:leaping",
"mcl_potions:mundane",
"mcl_potions:night",
"mcl_potions:poison",
"mcl_potions:regeneration",
"mcl_potions:river",
"mcl_potions:slowness",
"mcl_potions:speckled",
"mcl_potions:strength",
"mcl_potions:swiftness",
"mcl_potions:thick",
"mcl_potions:water",
"mcl_potions:weakness",
"mcl_signs:respawn",
"mcl_signs:set",
"mcl_signs:standing",
"mcl_signs:text",
"mcl_signs:wall",
"mcl_skins:skin",
"mcl_sponges:sponge",
"mcl_sprint:sprint",
"mcl_stairs:slab",
"mcl_stairs:stair",
"mcl_stairs:stairs",
"mcl_supplemental:nether",
"mcl_supplemental:red",
"mcl_throwing:arrow",
"mcl_throwing:bow",
"mcl_throwing:egg",
"mcl_throwing:ender",
"mcl_throwing:flying",
"mcl_throwing:snowball",
"mcl_tnt:tnt",
"mcl_tools:axe",
"mcl_tools:pick",
"mcl_tools:shears",
"mcl_tools:shovel",
"mcl_tools:sword",
"mcl_torches:flames",
"mcl_torches:torch",
"mcl_walls:andesite",
"mcl_walls:brick",
"mcl_walls:cobble",
"mcl_walls:diorite",
"mcl_walls:endbricks",
"mcl_walls:granite",
"mcl_walls:mossycobble",
"mcl_walls:netherbrick",
"mcl_walls:prismarine",
"mcl_walls:rednetherbrick",
"mcl_walls:redsandstone",
"mcl_walls:sandstone",
"mcl_walls:stonebrick",
"mcl_walls:stonebrickmossy",
"mcl_wool:black",
"mcl_wool:blue",
"mcl_wool:brown",
"mcl_wool:cyan",
"mcl_wool:dark",
"mcl_wool:gold",
"mcl_wool:green",
"mcl_wool:grey",
"mcl_wool:light",
"mcl_wool:lime",
"mcl_wool:magenta",
"mcl_wool:orange",
"mcl_wool:pink",
"mcl_wool:purple",
"mcl_wool:red",
"mcl_wool:silver",
"mcl_wool:white",
"mcl_wool:yellow",
    }

function autofly.cruise()
    if not minetest.settings:get_bool('afly_cruise') then
        if cruise_wason then
            cruise_wason=false
            core.set_keypress("jump",false)
            core.set_keypress("sneak",false)
        end
    return end

    local lp=minetest.localplayer:get_pos()
    local pos1 = vector.add(lp,{x=16,y=100,z=16})
    local pos2 = vector.add(lp,{x=-16,y=-100,z=-16})
    local nds=minetest.find_nodes_in_area_under_air(pos1, pos2, nodenames_ground)
    local y=0
    local found=false


    for k,v in ipairs(nds) do
        local nd = minetest.get_node_or_nil(v)
        if nd ~= nil and nd.name ~= "air" then
            if v.y > y then
                y=v.y
                found=true
            end
        end
    end
    if (autofly.cruiseheight ~= nil) then y=y+autofly.cruiseheight end
    local diff = math.ceil(lp.y - y)

    if not cruise_wason then --initially set the cruiseheight to the current value above ground
       -- if not found then return end --wait with activation til a ground node has been found.
        local clr,nnd=minetest.line_of_sight(lp,vector.add(lp,{x=1,y=-200,z=1}))
        if not clr then diff = math.ceil(lp.y - nnd.y)
        elseif not found then return end
        if diff < 1 then autofly.cruiseheight = 20
        else autofly.cruiseheight = diff end

        cruise_wason=true
        minetest.display_chat_message("cruise mode activated. target height set to " .. diff .. " nodes above ground.")
    end

    if not found then
        if nfctr<20 then nfctr = nfctr + 1 return end
        --minetest.display_chat_message("no nodes found for 20 iterations. lowering altitude.")
        nfctr=0
        minetest.settings:set_bool("free_move",false)
        core.set_keypress("jump",false)
        core.set_keypress("sneak",false)
        return
    end

    local tolerance = 1
    if diff < -tolerance then
        minetest.settings:set_bool("free_move",true)
        core.set_keypress("jump",true)
        core.set_keypress("sneak",false)
        --minetest.display_chat_message("too low: " .. y)
    elseif diff > tolerance * 10 then
        core.set_keypress("jump",false)
        core.set_keypress("sneak",true)
        minetest.settings:set_bool("free_move",false)
        --minetest.display_chat_message("too high: " .. y)
    elseif diff > tolerance then
        core.set_keypress("jump",false)
        core.set_keypress("sneak",true)
    else
        minetest.settings:set_bool("free_move",true)
        core.set_keypress("jump",false)
        core.set_keypress("sneak",false)
        --minetest.display_chat_message("target height reached: " .. y)
    end


end

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

function autofly.autotp(tpname)
   if minetest.localplayer == nil then return end
    local tpos=nil
    if tpname == nil then
        tpos = autofly.get_waypoint('AUTOTP')
    elseif type(tpname) == "table" then
        tpos = tpname
    else
        tpos=autofly.get_waypoint(tpname)
    end
    if tpos == nil then return end
    local lp=minetest.localplayer
    local dst=vector.distance(lp:get_pos(),tpos)
    if (dst < 500) then
        minetest.sound_play({name = "default_alert", gain = 3.0})
        autofly.delete_waypoint('AUTOTP')
        return
    end
    autofly.set_waypoint(tpos,'AUTOTP')
    for k, v in ipairs(lp.get_nearby_objects(4)) do
        local txt = v:get_item_textures()
		if ( txt:find('mcl_boats_texture')) then
            autofly.aim(vector.add(v:get_pos(),{x=0,y=-1.5,z=0}))
            minetest.after("0.2",function()
                minetest.interact("place") end)
            minetest.after("2.5",function()
                 autofly.warpae('AUTOTP')
              end)
			return
        end
    end
    minetest.sound_play({name = "default_alert", gain = 3.0})
    autofly.delete_waypoint('AUTOTP')
end

function autofly.axissnap()
    if not minetest.settings:get_bool('afly_snap') then return end
    local y=minetest.localplayer:get_yaw()
    local yy=nil
    if ( y < 45 or y > 315 ) then
        yy=0
    elseif (y < 135) then
        yy=90
    elseif (y < 225 ) then
        yy=180
    elseif ( y < 315 ) then
        yy=270
    end
    if yy ~= nil then
        minetest.localplayer:set_yaw(yy)
    end
end

minetest.register_on_death(function()
    if minetest.localplayer then
        local name = 'Death waypoint'
        local pos  = minetest.localplayer:get_pos()
        autofly.last_coords = pos
        autofly.set_waypoint(pos, name)
        autofly.display_waypoint(name)
    end
end)

function autofly.warp(name)
    local pos=vector.add(autofly.get_waypoint(name),{x=0,y=150,z=0})
    if pos then
        minetest.localplayer:set_pos(pos)
        return true
    end
end
function autofly.warpae(name)
		local s, m = autofly.warp(name)
		if s then
			minetest.disconnect()
		end
		return true
end

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

function autofly.set_waypoint(pos, name)
    pos = pos_to_string(pos)
    if not pos then return end
    storage:set_string(stprefix .. tostring(name), pos)
    return true
end

function autofly.delete_waypoint(name)
    storage:set_string(stprefix .. tostring(name), '')
end

function autofly.get_waypoint(name)
    return string_to_pos(storage:get_string(stprefix .. tostring(name)))
end

function autofly.rename_waypoint(oldname, newname)
    oldname, newname = tostring(oldname), tostring(newname)
    local pos = autofly.get_waypoint(oldname)
    if not pos or not autofly.set_waypoint(pos, newname) then return end
    if oldname ~= newname then
        autofly.delete_waypoint(oldname)
    end
    return true
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
    func = function(param) autofly.display_formspec() end
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
        if autofly.flying then autofly.flying=false end
        if hud_wp then
            minetest.localplayer:hud_remove(hud_wp)
            hud_wp = nil
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
register_chatcommand_alias('clear_waypoint', 'cwp','cls')

minetest.register_chatcommand('autotp', {
    params      = 'position',
    description = 'autotp',
    func = function(param)
      autofly.autotp(minetest.string_to_pos(param))
    end
})
register_chatcommand_alias('autotp', 'atp')


minetest.after("3.0",function()
    if autofly.get_waypoint('AUTOTP') ~= nil then autofly.autotp(nil) end
end)


math.randomseed(os.time())

local randflying = false

minetest.register_globalstep(function()
    if randflying and not autofly.flying then
        local x = math.random(-31000, 31000)
        local y = math.random(2000, 31000)
        local z = math.random(-31000, 31000)

        autofly.goto({x = x, y = y, z = z})
    end
end)

local function randfly()
    if not randflying then
        randflying = true
        local lp = minetest.localplayer:get_pos()
        autofly.goto(turtle.coord(lp.x, 6000, lp.z))
    else
        randflying = false
        autofly.arrived()
    end
end

minetest.register_chatcommand("randfly", {
    description = "Randomly fly up high (toggle).",
    func = randfly
})


if (_G["minetest"]["register_cheat"] == nil) then
    minetest.settings:set_bool("afly_autoaim", false)
    minetest.settings:set_bool("afly_softlanding", true)
    minetest.settings:set_bool("afly_sprint", true)
else
    minetest.register_cheat("Aim", "Autofly", "afly_autoaim")
    minetest.register_cheat("AxisSnap", "Autofly", "afly_snap")
    minetest.register_cheat("Cruise", "Autofly", "afly_cruise")
    minetest.register_cheat("Sprint", "Autofly", "afly_sprint")
    minetest.register_cheat("Waypoints", "Autofly", autofly.display_formspec)
end
