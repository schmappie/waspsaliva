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
    'mcl_anvils:anvil',
    'mcl_anvils:anvil_damage_1',
    'mcl_anvils:anvil_damage_2',
    'mcl_anvils:update_formspec_0_60_0',
    'mcl_armor:boots_',
    'mcl_armor:boots_chain',
    'mcl_armor:boots_diamond',
    'mcl_armor:boots_gold',
    'mcl_armor:boots_iron',
    'mcl_armor:boots_leather',
    'mcl_armor:chestplate_',
    'mcl_armor:chestplate_chain',
    'mcl_armor:chestplate_diamond',
    'mcl_armor:chestplate_gold',
    'mcl_armor:chestplate_iron',
    'mcl_armor:chestplate_leather',
    'mcl_armor:helmet_',
    'mcl_armor:helmet_chain',
    'mcl_armor:helmet_diamond',
    'mcl_armor:helmet_gold',
    'mcl_armor:helmet_iron',
    'mcl_armor:helmet_leather',
    'mcl_armor:leggings_',
    'mcl_armor:leggings_chain',
    'mcl_armor:leggings_diamond',
    'mcl_armor:leggings_gold',
    'mcl_armor:leggings_iron',
    'mcl_armor:leggings_leather',
    'mcl_banners:banner_item_',
    'mcl_banners:banner_item_white',
    'mcl_banners:hanging_banner',
    'mcl_banners:respawn_entities',
    'mcl_banners:standing_banner',
    'mcl_beds:bed_',
    'mcl_beds:bed_red_bottom',
    'mcl_beds:bed_red_top',
    'mcl_beds:bed_white_bottom',
    'mcl_beds:sleeping',
    'mcl_beds:spawn',
    'mcl_biomes:chorus_plant',
    'mcl_boats:boat',
    'mcl_books:book',
    'mcl_books:bookshelf',
    'mcl_books:signing',
    'mcl_books:writable_book',
    'mcl_books:written_book',
    'mcl_bows:arrow',
    'mcl_bows:arrow_box',
    'mcl_bows:arrow_entity',
    'mcl_bows:bow',
    'mcl_bows:bow_',
    'mcl_bows:bow_0',
    'mcl_bows:bow_1',
    'mcl_bows:bow_2',
    'mcl_bows:use_bow',
    'mcl_brewing:stand',
    'mcl_brewing:stand_',
    'mcl_brewing:stand_000',
    'mcl_brewing:stand_001',
    'mcl_brewing:stand_010',
    'mcl_brewing:stand_011',
    'mcl_brewing:stand_100',
    'mcl_brewing:stand_101',
    'mcl_brewing:stand_110',
    'mcl_brewing:stand_111',
    'mcl_buckets:bucket_empty',
    'mcl_buckets:bucket_lava',
    'mcl_buckets:bucket_river_water',
    'mcl_buckets:bucket_water',
    'mcl_cake:cake',
    'mcl_cake:cake_',
    'mcl_cake:cake_1',
    'mcl_cake:cake_6',
    'mcl_cauldrons:cauldron',
    'mcl_cauldrons:cauldron_',
    'mcl_cauldrons:cauldron_1',
    'mcl_cauldrons:cauldron_1r',
    'mcl_cauldrons:cauldron_2',
    'mcl_cauldrons:cauldron_2r',
    'mcl_cauldrons:cauldron_3',
    'mcl_cauldrons:cauldron_3r',
    'mcl_chests:chest',
    'mcl_chests:ender_chest',
    'mcl_chests:reset_trapped_chests',
    'mcl_chests:trapped_chest',
    'mcl_chests:trapped_chest_',
    'mcl_chests:trapped_chest_left',
    'mcl_chests:trapped_chest_on',
    'mcl_chests:trapped_chest_on_left',
    'mcl_chests:trapped_chest_on_right',
    'mcl_chests:trapped_chest_right',
    'mcl_chests:update_ender_chest_formspecs_0_60_0',
    'mcl_chests:update_formspecs_0_51_0',
    'mcl_chests:update_shulker_box_formspecs_0_60_0',
    'mcl_chests:violet_shulker_box',
    'mcl_clock:clock',
    'mcl_clock:clock_',
    'mcl_cocoas:cocoa_1',
    'mcl_cocoas:cocoa_2',
    'mcl_cocoas:cocoa_3',
    'mcl_colorblocks:concrete_',
    'mcl_colorblocks:concrete_powder_',
    'mcl_colorblocks:glazed_terracotta_',
    'mcl_colorblocks:glazed_terracotta_black',
    'mcl_colorblocks:glazed_terracotta_blue',
    'mcl_colorblocks:glazed_terracotta_brown',
    'mcl_colorblocks:glazed_terracotta_cyan',
    'mcl_colorblocks:glazed_terracotta_green',
    'mcl_colorblocks:glazed_terracotta_grey',
    'mcl_colorblocks:glazed_terracotta_light_blue',
    'mcl_colorblocks:glazed_terracotta_lime',
    'mcl_colorblocks:glazed_terracotta_magenta',
    'mcl_colorblocks:glazed_terracotta_orange',
    'mcl_colorblocks:glazed_terracotta_pink',
    'mcl_colorblocks:glazed_terracotta_purple',
    'mcl_colorblocks:glazed_terracotta_red',
    'mcl_colorblocks:glazed_terracotta_silver',
    'mcl_colorblocks:glazed_terracotta_white',
    'mcl_colorblocks:glazed_terracotta_yellow',
    'mcl_colorblocks:hardened_clay',
    'mcl_colorblocks:hardened_clay_',
    'mcl_colorblocks:hardened_clay_orange',
    'mcl_comparators:comparator_',
    'mcl_comparators:comparator_off_',
    'mcl_comparators:comparator_off_comp',
    'mcl_comparators:comparator_off_sub',
    'mcl_comparators:comparator_on_',
    'mcl_comparators:comparator_on_comp',
    'mcl_comparators:comparator_on_sub',
    'mcl_compass:compass',
    'mcl_core:acacialeaves',
    'mcl_core:acaciasapling',
    'mcl_core:acaciatree',
    'mcl_core:acaciawood',
    'mcl_core:andesite',
    'mcl_core:andesite_smooth',
    'mcl_core:apple',
    'mcl_core:apple_gold',
    'mcl_core:axe_diamond',
    'mcl_core:axe_gold',
    'mcl_core:axe_iron',
    'mcl_core:axe_stone',
    'mcl_core:axe_wood',
    'mcl_core:barrier',
    'mcl_core:bedrock',
    'mcl_core:birchsapling',
    'mcl_core:birchtree',
    'mcl_core:birchwood',
    'mcl_core:bone_block',
    'mcl_core:bowl',
    'mcl_core:brick',
    'mcl_core:brick_block',
    'mcl_core:cactus',
    'mcl_core:charcoal_lump',
    'mcl_core:clay',
    'mcl_core:clay_lump',
    'mcl_core:coalblock',
    'mcl_core:coal_lump',
    'mcl_core:coarse_dirt',
    'mcl_core:cobble',
    'mcl_core:cobblestone',
    'mcl_core:cobweb',
    'mcl_core:darksapling',
    'mcl_core:darktree',
    'mcl_core:darkwood',
    'mcl_core:deadbush',
    'mcl_core:diamond',
    'mcl_core:diamondblock',
    'mcl_core:diorite',
    'mcl_core:diorite_smooth',
    'mcl_core:dirt',
    'mcl_core:dirt_with_dry_grass',
    'mcl_core:dirt_with_dry_grass_snow',
    'mcl_core:dirt_with_grass',
    'mcl_core:dirt_with_grass_snow',
    'mcl_core:emerald',
    'mcl_core:emeraldblock',
    'mcl_core:flint',
    'mcl_core:frosted_ice_',
    'mcl_core:frosted_ice_0',
    'mcl_core:glass',
    'mcl_core:glass_',
    'mcl_core:glass_black',
    'mcl_core:glass_blue',
    'mcl_core:glass_brown',
    'mcl_core:glass_cyan',
    'mcl_core:glass_gray',
    'mcl_core:glass_green',
    'mcl_core:glass_light_blue',
    'mcl_core:glass_lime',
    'mcl_core:glass_magenta',
    'mcl_core:glass_orange',
    'mcl_core:glass_pink',
    'mcl_core:glass_purple',
    'mcl_core:glass_red',
    'mcl_core:glass_silver',
    'mcl_core:glass_white',
    'mcl_core:glass_yellow',
    'mcl_core:goldblock',
    'mcl_core:gold_ingot',
    'mcl_core:gold_nugget',
    'mcl_core:granite',
    'mcl_core:granite_smooth',
    'mcl_core:grass_path',
    'mcl_core:gravel',
    'mcl_core:ice',
    'mcl_core:ironblock',
    'mcl_core:iron_ingot',
    'mcl_core:iron_nugget',
    'mcl_core:jungleleaves',
    'mcl_core:junglesapling',
    'mcl_core:jungletree',
    'mcl_core:junglewood',
    'mcl_core:ladder',
    'mcl_core:lapisblock',
    'mcl_core:lava_flowing',
    'mcl_core:lava_source',
    'mcl_core:leaves',
    'mcl_core:mat',
    'mcl_core:mossycobble',
    'mcl_core:mycelium',
    'mcl_core:mycelium_snow',
    'mcl_core:obsidian',
    'mcl_core:packed_ice',
    'mcl_core:paper',
    'mcl_core:pick_diamond',
    'mcl_core:pick_gold',
    'mcl_core:pick_iron',
    'mcl_core:pick_stone',
    'mcl_core:pick_wood',
    'mcl_core:podzol',
    'mcl_core:podzol_snow',
    'mcl_core:realm_barrier',
    'mcl_core:redsand',
    'mcl_core:redsandstone',
    'mcl_core:redsandstonecarved',
    'mcl_core:redsandstonesmooth',
    'mcl_core:redsandstonesmooth2',
    'mcl_core:reeds',
    'mcl_core:replace_legacy_dry_grass_0_65_0',
    'mcl_core:sand',
    'mcl_core:sandstone',
    'mcl_core:sandstonecarved',
    'mcl_core:sandstonesmooth',
    'mcl_core:sandstonesmooth2',
    'mcl_core:sapling',
    'mcl_core:shears',
    'mcl_core:shovel_diamond',
    'mcl_core:shovel_gold',
    'mcl_core:shovel_iron',
    'mcl_core:shovel_stone',
    'mcl_core:shovel_wood',
    'mcl_core:slimeblock',
    'mcl_core:snow',
    'mcl_core:snow_',
    'mcl_core:snowblock',
    'mcl_core:spruceleaves',
    'mcl_core:sprucesapling',
    'mcl_core:sprucetree',
    'mcl_core:sprucewood',
    'mcl_core:stick',
    'mcl_core:stone',
    'mcl_core:stonebrick',
    'mcl_core:stonebrickcarved',
    'mcl_core:stonebrickcracked',
    'mcl_core:stonebrickmossy',
    'mcl_core:stone_smooth',
    'mcl_core:stone_with_coal',
    'mcl_core:stone_with_diamond',
    'mcl_core:stone_with_emerald',
    'mcl_core:stone_with_gold',
    'mcl_core:stone_with_iron',
    'mcl_core:stone_with_lapis',
    'mcl_core:stone_with_redstone',
    'mcl_core:stone_with_redstone_lit',
    'mcl_core:sugar',
    'mcl_core:sword_diamond',
    'mcl_core:sword_gold',
    'mcl_core:sword_iron',
    'mcl_core:sword_stone',
    'mcl_core:sword_wood',
    'mcl_core:tallgrass',
    'mcl_core:torch',
    'mcl_core:tree',
    'mcl_core:vine',
    'mcl_core:void',
    'mcl_core:water_flowing',
    'mcl_core:water_source',
    'mcl_core:wood',
    'mcl_dispenser:dispenser_down',
    'mcl_dispenser:dispenser_up',
    'mcl_dispensers:dispenser',
    'mcl_dispensers:dispenser_down',
    'mcl_dispensers:dispenser_up',
    'mcl_dispensers:update_formspecs_0_60_0',
    'mcl_doors:acacia_door',
    'mcl_doors:birch_door',
    'mcl_doors:dark_oak_door',
    'mcl_doors:iron_door',
    'mcl_doors:iron_trapdoor',
    'mcl_doors:iron_trapdoor_open',
    'mcl_doors:jungle_door',
    'mcl_doors:register_door',
    'mcl_doors:register_trapdoor',
    'mcl_doors:spruce_door',
    'mcl_doors:trapdoor',
    'mcl_doors:trapdoor_open',
    'mcl_doors:wooden_door',
    'mcl_droppers:dropper',
    'mcl_droppers:dropper_down',
    'mcl_droppers:dropper_up',
    'mcl_droppers:update_formspecs_0_51_0',
    'mcl_droppers:update_formspecs_0_60_0',
    'mcl_dye:black',
    'mcl_dye:blue',
    'mcl_dye:brown',
    'mcl_dye:cyan',
    'mcl_dye:dark_green',
    'mcl_dye:dark_grey',
    'mcl_dye:green',
    'mcl_dye:grey',
    'mcl_dye:lightblue',
    'mcl_dye:magenta',
    'mcl_dye:orange',
    'mcl_dye:pink',
    'mcl_dye:red',
    'mcl_dye:violet',
    'mcl_dye:white',
    'mcl_dye:yellow',
    'mcl_end:chorus_flower',
    'mcl_end:chorus_flower_dead',
    'mcl_end:chorus_fruit',
    'mcl_end:chorus_fruit_popped',
    'mcl_end:chorus_plant',
    'mcl_end:dragon_egg',
    'mcl_end:end_bricks',
    'mcl_end:ender_eye',
    'mcl_end:end_rod',
    'mcl_end:end_stone',
    'mcl_end:purpur_block',
    'mcl_end:purpur_pillar',
    'mcl_farming:add_gourd',
    'mcl_farming:add_plant',
    'mcl_farming:beetroot',
    'mcl_farming:beetroot_',
    'mcl_farming:beetroot_0',
    'mcl_farming:beetroot_1',
    'mcl_farming:beetroot_2',
    'mcl_farming:beetroot_item',
    'mcl_farming:beetroot_seeds',
    'mcl_farming:beetroot_soup',
    'mcl_farming:bread',
    'mcl_farming:carrot',
    'mcl_farming:carrot_',
    'mcl_farming:carrot_1',
    'mcl_farming:carrot_2',
    'mcl_farming:carrot_3',
    'mcl_farming:carrot_4',
    'mcl_farming:carrot_5',
    'mcl_farming:carrot_6',
    'mcl_farming:carrot_7',
    'mcl_farming:carrot_item',
    'mcl_farming:carrot_item_gold',
    'mcl_farming:cookie',
    'mcl_farming:grow_plant',
    'mcl_farming:growth',
    'mcl_farming:hay_block',
    'mcl_farming:hoe_diamond',
    'mcl_farming:hoe_gold',
    'mcl_farming:hoe_iron',
    'mcl_farming:hoe_stone',
    'mcl_farming:hoe_wood',
    'mcl_farming:melon',
    'mcl_farming:melon_item',
    'mcl_farming:melon_seeds',
    'mcl_farming:melontige_',
    'mcl_farming:melontige_1',
    'mcl_farming:melontige_2',
    'mcl_farming:melontige_3',
    'mcl_farming:melontige_4',
    'mcl_farming:melontige_5',
    'mcl_farming:melontige_6',
    'mcl_farming:melontige_7',
    'mcl_farming:melontige_linked',
    'mcl_farming:melontige_unconnect',
    'mcl_farming:mushroom_brown',
    'mcl_farming:mushroom_red',
    'mcl_farming:place_seed',
    'mcl_farming:potato',
    'mcl_farming:potato_',
    'mcl_farming:potato_1',
    'mcl_farming:potato_2',
    'mcl_farming:potato_3',
    'mcl_farming:potato_4',
    'mcl_farming:potato_5',
    'mcl_farming:potato_6',
    'mcl_farming:potato_7',
    'mcl_farming:potato_item',
    'mcl_farming:potato_item_baked',
    'mcl_farming:potato_item_poison',
    'mcl_farming:pumkin_seeds',
    'mcl_farming:pumpkin',
    'mcl_farming:pumpkin_',
    'mcl_farming:pumpkin_1',
    'mcl_farming:pumpkin_2',
    'mcl_farming:pumpkin_3',
    'mcl_farming:pumpkin_4',
    'mcl_farming:pumpkin_5',
    'mcl_farming:pumpkin_6',
    'mcl_farming:pumpkin_7',
    'mcl_farming:pumpkin_face',
    'mcl_farming:pumpkin_face_light',
    'mcl_farming:pumpkin_pie',
    'mcl_farming:pumpkin_seeds',
    'mcl_farming:pumpkintige_linked',
    'mcl_farming:pumpkintige_unconnect',
    'mcl_farming:soil',
    'mcl_farming:soil_wet',
    'mcl_farming:stem_color',
    'mcl_farming:wheat',
    'mcl_farming:wheat_',
    'mcl_farming:wheat_1',
    'mcl_farming:wheat_2',
    'mcl_farming:wheat_3',
    'mcl_farming:wheat_4',
    'mcl_farming:wheat_5',
    'mcl_farming:wheat_6',
    'mcl_farming:wheat_7',
    'mcl_farming:wheat_item',
    'mcl_farming:wheat_seeds',
    'mcl_fences:dark_oak_fence',
    'mcl_fences:fence',
    'mcl_fences:nether_brick_fence',
    'mcl_fire:basic_flame',
    'mcl_fire:eternal_fire',
    'mcl_fire:fire',
    'mcl_fire:fire_charge',
    'mcl_fire:flint_and_steel',
    'mcl_fire:smoke',
    'mcl_fishing:bobber',
    'mcl_fishing:bobber_entity',
    'mcl_fishing:clownfish_raw',
    'mcl_fishing:fish_cooked',
    'mcl_fishing:fishing_rod',
    'mcl_fishing:fish_raw',
    'mcl_fishing:pufferfish_raw',
    'mcl_fishing:salmon_cooked',
    'mcl_fishing:salmon_raw',
    'mcl_flowerpots:flower_pot',
    'mcl_flowerpots:flower_pot_',
    'mcl_flowers:allium',
    'mcl_flowers:azure_bluet',
    'mcl_flowers:blue_orchid',
    'mcl_flowers:dandelion',
    'mcl_flowers:double_fern',
    'mcl_flowers:double_fern_top',
    'mcl_flowers:double_grass',
    'mcl_flowers:double_grass_top',
    'mcl_flowers:fern',
    'mcl_flowers:lilac',
    'mcl_flowers:lilac_top',
    'mcl_flowers:oxeye_daisy',
    'mcl_flowers:peony',
    'mcl_flowers:peony_top',
    'mcl_flowers:poppy',
    'mcl_flowers:rose_bush',
    'mcl_flowers:rose_bush_top',
    'mcl_flowers:sunflower',
    'mcl_flowers:sunflower_top',
    'mcl_flowers:tallgrass',
    'mcl_flowers:tulip_orange',
    'mcl_flowers:tulip_pink',
    'mcl_flowers:tulip_red',
    'mcl_flowers:tulip_white',
    'mcl_flowers:waterlily',
    'mcl_furnaces:flames',
    'mcl_furnaces:furnace',
    'mcl_furnaces:furnace_active',
    'mcl_furnaces:update_formspecs_0_60_0',
    'mcl_heads:creeper',
    'mcl_heads:skeleton',
    'mcl_heads:wither_skeleton',
    'mcl_heads:zombie',
    'mcl_hoppers:hopper',
    'mcl_hoppers:hopper_disabled',
    'mcl_hoppers:hopper_item',
    'mcl_hoppers:hopper_side',
    'mcl_hoppers:hopper_side_disabled',
    'mcl_hoppers:update_formspec_0_60_0',
    'mcl_hunger:exhaustion',
    'mcl_hunger:hunger',
    'mcl_hunger:saturation',
    'mcl_inventory:workbench',
    'mcl_itemframes:item',
    'mcl_itemframes:item_frame',
    'mcl_itemframes:respawn_entities',
    'mcl_itemframes:update_legacy_item_frames',
    'mcl_jukebox:jukebox',
    'mcl_jukebox:record_',
    'mcl_jukebox:record_1',
    'mcl_jukebox:record_2',
    'mcl_jukebox:record_3',
    'mcl_jukebox:record_4',
    'mcl_jukebox:record_5',
    'mcl_jukebox:record_6',
    'mcl_jukebox:record_7',
    'mcl_jukebox:record_8',
    'mcl_jukebox:record_9',
    'mcl_maps:empty_map',
    'mcl_maps:filled_map',
    'mcl_meshhand:hand',
    'mcl_minecarts:activator_rail',
    'mcl_minecarts:activator_rail_on',
    'mcl_minecarts:check_front_up_down',
    'mcl_minecarts:chest_minecart',
    'mcl_minecarts:command_block_minecart',
    'mcl_minecarts:detector_rail',
    'mcl_minecarts:detector_rail_on',
    'mcl_minecarts:furnace_minecart',
    'mcl_minecarts:get_rail_direction',
    'mcl_minecarts:get_sign',
    'mcl_minecarts:golden_rail',
    'mcl_minecarts:golden_rail_on',
    'mcl_minecarts:hopper_minecart',
    'mcl_minecarts:is_rail',
    'mcl_minecarts:minecart',
    'mcl_minecarts:rail',
    'mcl_minecarts:tnt_minecart',
    'mcl_minecarts:velocity_to_dir',
    'mcl_mobitems:beef',
    'mcl_mobitems:blaze_powder',
    'mcl_mobitems:blaze_rod',
    'mcl_mobitems:bone',
    'mcl_mobitems:carrot_on_a_stick',
    'mcl_mobitems:chicken',
    'mcl_mobitems:cooked_beef',
    'mcl_mobitems:cooked_chicken',
    'mcl_mobitems:cooked_mutton',
    'mcl_mobitems:cooked_porkchop',
    'mcl_mobitems:cooked_rabbit',
    'mcl_mobitems:ender_eye',
    'mcl_mobitems:feather',
    'mcl_mobitems:ghast_tear',
    'mcl_mobitems:gunpowder',
    'mcl_mobitems:leather',
    'mcl_mobitems:magma_cream',
    'mcl_mobitems:milk_bucket',
    'mcl_mobitems:mutton',
    'mcl_mobitems:nether_star',
    'mcl_mobitems:porkchop',
    'mcl_mobitems:rabbit',
    'mcl_mobitems:rabbit_foot',
    'mcl_mobitems:rabbit_hide',
    'mcl_mobitems:rabbit_stew',
    'mcl_mobitems:rotten_flesh',
    'mcl_mobitems:saddle',
    'mcl_mobitems:shulker_shell',
    'mcl_mobitems:slimeball',
    'mcl_mobitems:spider_eye',
    'mcl_mobitems:string',
    'mcl_mobs:nametag',
    'mcl_mobspawners:doll',
    'mcl_mobspawners:respawn_entities',
    'mcl_mobspawners:spawner',
    'mcl_mushrooms:brown_mushroom_block_cap_corner',
    'mcl_mushrooms:brown_mushroom_block_cap_side',
    'mcl_mushrooms:mushroom_brown',
    'mcl_mushrooms:mushroom_red',
    'mcl_mushrooms:mushroom_stew',
    'mcl_mushrooms:red_mushroom_block_cap_corner',
    'mcl_mushrooms:red_mushroom_block_cap_side',
    'mcl_mushrooms:replace_legacy_mushroom_caps',
    'mcl_nether:glowstone',
    'mcl_nether:glowstone_dust',
    'mcl_nether:magma',
    'mcl_nether:nether_brick',
    'mcl_nether:netherbrick',
    'mcl_nether:nether_lava_flowing',
    'mcl_nether:nether_lava_source',
    'mcl_nether:netherrack',
    'mcl_nether:nether_wart',
    'mcl_nether:nether_wart_',
    'mcl_nether:nether_wart_0',
    'mcl_nether:nether_wart_1',
    'mcl_nether:nether_wart_2',
    'mcl_nether:nether_wart_block',
    'mcl_nether:nether_wart_item',
    'mcl_nether:quartz',
    'mcl_nether:quartz_block',
    'mcl_nether:quartz_chiseled',
    'mcl_nether:quartz_ore',
    'mcl_nether:quartz_pillar',
    'mcl_nether:quartz_smooth',
    'mcl_nether:red_nether_brick',
    'mcl_nether:soul_sand',
    'mcl_observers:observer',
    'mcl_observers:observer_down',
    'mcl_observers:observer_down_off',
    'mcl_observers:observer_down_on',
    'mcl_observers:observer_off',
    'mcl_observers:observer_on',
    'mcl_observers:observer_up',
    'mcl_observers:observer_up_off',
    'mcl_observers:observer_up_on',
    'mcl_ocean:dead_',
    'mcl_ocean:dead_brain_coral_block',
    'mcl_ocean:dried_kelp',
    'mcl_ocean:dried_kelp_block',
    'mcl_ocean:kelp',
    'mcl_ocean:kelp_',
    'mcl_ocean:kelp_dirt',
    'mcl_ocean:kelp_gravel',
    'mcl_ocean:kelp_redsand',
    'mcl_ocean:kelp_sand',
    'mcl_ocean:prismarine',
    'mcl_ocean:prismarine_brick',
    'mcl_ocean:prismarine_crystals',
    'mcl_ocean:prismarine_dark',
    'mcl_ocean:prismarine_shard',
    'mcl_ocean:seagrass',
    'mcl_ocean:seagrass_',
    'mcl_ocean:seagrass_dirt',
    'mcl_ocean:seagrass_gravel',
    'mcl_ocean:seagrass_redsand',
    'mcl_ocean:seagrass_sand',
    'mcl_ocean:sea_lantern',
    'mcl_ocean:sea_pickle_',
    'mcl_ocean:sea_pickle_1_',
    'mcl_ocean:sea_pickle_1_dead_brain_coral_block',
    'mcl_ocean:sea_pickle_1_off_',
    'mcl_ocean:sea_pickle_1_off_dead_brain_coral_block',
    'mcl_paintings:painting',
    'mcl_playerplus:surface',
    'mcl_player:preview',
    'mcl_portals:end_portal_frame',
    'mcl_portals:end_portal_frame_eye',
    'mcl_portals:portal',
    'mcl_portals:portal_end',
    'mcl_potions:awkward',
    'mcl_potions:dragon_breath',
    'mcl_potions:fermented_spider_eye',
    'mcl_potions:fire_resistance',
    'mcl_potions:glass_bottle',
    'mcl_potions:harming',
    'mcl_potions:harming_2',
    'mcl_potions:harming_2_splash',
    'mcl_potions:harming_splash',
    'mcl_potions:healing',
    'mcl_potions:healing_2',
    'mcl_potions:healing_2_splash',
    'mcl_potions:healing_splash',
    'mcl_potions:invisibility',
    'mcl_potions:invisibility_plus',
    'mcl_potions:invisibility_plus_splash',
    'mcl_potions:invisibility_splash',
    'mcl_potions:leaping',
    'mcl_potions:leaping_plus',
    'mcl_potions:leaping_plus_splash',
    'mcl_potions:leaping_splash',
    'mcl_potions:mundane',
    'mcl_potions:night_vision',
    'mcl_potions:night_vision_arrow',
    'mcl_potions:night_vision_lingering',
    'mcl_potions:night_vision_plus',
    'mcl_potions:night_vision_plus_arrow',
    'mcl_potions:night_vision_plus_lingering',
    'mcl_potions:night_vision_plus_splash',
    'mcl_potions:night_vision_splash',
    'mcl_potions:poison',
    'mcl_potions:poison_2',
    'mcl_potions:poison_2_splash',
    'mcl_potions:poison_splash',
    'mcl_potions:regeneration',
    'mcl_potions:river_water',
    'mcl_potions:slowness',
    'mcl_potions:slowness_plus',
    'mcl_potions:slowness_plus_splash',
    'mcl_potions:slowness_splash',
    'mcl_potions:speckled_melon',
    'mcl_potions:strength',
    'mcl_potions:strength_2',
    'mcl_potions:strength_2_lingering',
    'mcl_potions:strength_2_splash',
    'mcl_potions:strength_lingering',
    'mcl_potions:strength_plus',
    'mcl_potions:strength_plus_lingering',
    'mcl_potions:strength_plus_splash',
    'mcl_potions:strength_splash',
    'mcl_potions:swiftness',
    'mcl_potions:swiftness_plus',
    'mcl_potions:swiftness_plus_splash',
    'mcl_potions:swiftness_splash',
    'mcl_potions:thick',
    'mcl_potions:water',
    'mcl_potions:water_breathing',
    'mcl_potions:water_splash',
    'mcl_potions:weakness',
    'mcl_potions:weakness_lingering',
    'mcl_potions:weakness_plus',
    'mcl_potions:weakness_plus_lingering',
    'mcl_potions:weakness_plus_splash',
    'mcl_potions:weakness_splash',
    'mcl_signs:respawn_entities',
    'mcl_signs:set_text_',
    'mcl_signs:standing_sign',
    'mcl_signs:standing_sign22_5',
    'mcl_signs:standing_sign45',
    'mcl_signs:standing_sign67_5',
    'mcl_signs:text',
    'mcl_signs:wall_sign',
    'mcl_skins:skin_id',
    'mcl_skins:skin_select',
    'mcl_sponges:sponge',
    'mcl_sponges:sponge_wet',
    'mcl_sponges:sponge_wet_river_water',
    'mcl_sprint:sprint',
    'mcl_stairs:slab_',
    'mcl_stairs:slab_concrete_',
    'mcl_stairs:slab_purpur_block',
    'mcl_stairs:slab_quartzblock',
    'mcl_stairs:slab_redsandstone',
    'mcl_stairs:slab_sandstone',
    'mcl_stairs:slab_stone',
    'mcl_stairs:slab_stonebrick',
    'mcl_stairs:slab_stone_double',
    'mcl_stairs:slab_wood',
    'mcl_stairs:stair_',
    'mcl_stairs:stair_cobble',
    'mcl_stairs:stair_concrete_',
    'mcl_stairs:stair_sandstone',
    'mcl_stairs:stair_stonebrick',
    'mcl_stairs:stair_stonebrickcracked',
    'mcl_stairs:stair_stonebrickcracked_inner',
    'mcl_stairs:stair_stonebrickcracked_outer',
    'mcl_stairs:stair_stonebrick_inner',
    'mcl_stairs:stair_stonebrickmossy',
    'mcl_stairs:stair_stonebrickmossy_inner',
    'mcl_stairs:stair_stonebrickmossy_outer',
    'mcl_stairs:stair_stonebrick_outer',
    'mcl_stairs:stairs_wood',
    'mcl_supplemental:nether_brick_fence_gate',
    'mcl_supplemental:nether_brick_fence_gate_open',
    'mcl_supplemental:red_nether_brick_fence',
    'mcl_supplemental:red_nether_brick_fence_gate',
    'mcl_supplemental:red_nether_brick_fence_gate_open',
    'mcl_throwing:arrow',
    'mcl_throwing:bow',
    'mcl_throwing:egg',
    'mcl_throwing:egg_entity',
    'mcl_throwing:ender_pearl',
    'mcl_throwing:ender_pearl_entity',
    'mcl_throwing:flying_bobber',
    'mcl_throwing:flying_bobber_entity',
    'mcl_throwing:snowball',
    'mcl_throwing:snowball_entity',
    'mcl_tnt:tnt',
    'mcl_tools:axe_diamond',
    'mcl_tools:axe_gold',
    'mcl_tools:axe_iron',
    'mcl_tools:axe_stone',
    'mcl_tools:axe_wood',
    'mcl_tools:pick_diamond',
    'mcl_tools:pick_gold',
    'mcl_tools:pick_iron',
    'mcl_tools:pick_stone',
    'mcl_tools:pick_wood',
    'mcl_tools:shears',
    'mcl_tools:shovel_diamond',
    'mcl_tools:shovel_gold',
    'mcl_tools:shovel_iron',
    'mcl_tools:shovel_stone',
    'mcl_tools:shovel_wood',
    'mcl_tools:sword_diamond',
    'mcl_tools:sword_gold',
    'mcl_tools:sword_iron',
    'mcl_tools:sword_stone',
    'mcl_tools:sword_wood',
    'mcl_torches:flames',
    'mcl_torches:torch',
    'mcl_torches:torch_wall',
    'mcl_walls:andesite',
    'mcl_walls:brick',
    'mcl_walls:cobble',
    'mcl_walls:diorite',
    'mcl_walls:endbricks',
    'mcl_walls:granite',
    'mcl_walls:mossycobble',
    'mcl_walls:netherbrick',
    'mcl_walls:prismarine',
    'mcl_walls:rednetherbrick',
    'mcl_walls:redsandstone',
    'mcl_walls:sandstone',
    'mcl_walls:stonebrick',
    'mcl_walls:stonebrickmossy',
    'mcl_wool:black',
    'mcl_wool:black_carpet',
    'mcl_wool:blue',
    'mcl_wool:blue_carpet',
    'mcl_wool:brown',
    'mcl_wool:brown_carpet',
    'mcl_wool:cyan',
    'mcl_wool:cyan_carpet',
    'mcl_wool:dark_blue',
    'mcl_wool:gold',
    'mcl_wool:green',
    'mcl_wool:green_carpet',
    'mcl_wool:grey',
    'mcl_wool:grey_carpet',
    'mcl_wool:light_blue',
    'mcl_wool:light_blue_carpet',
    'mcl_wool:lime',
    'mcl_wool:lime_carpet',
    'mcl_wool:magenta',
    'mcl_wool:magenta_carpet',
    'mcl_wool:orange',
    'mcl_wool:orange_carpet',
    'mcl_wool:pink',
    'mcl_wool:pink_carpet',
    'mcl_wool:purple',
    'mcl_wool:purple_carpet',
    'mcl_wool:red',
    'mcl_wool:red_carpet',
    'mcl_wool:silver',
    'mcl_wool:silver_carpet',
    'mcl_wool:white',
    'mcl_wool:white_carpet',
    'mcl_wool:yellow',
    'mcl_wool:yellow_carpet',

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
   if minetest.localplayer == nil then autofly.autotp(tpname) end
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
    if (dst < 300) then
        minetest.sound_play({name = "default_alert", gain = 3.0})
        autofly.delete_waypoint('AUTOTP')
        return true
    end
    autofly.set_waypoint(tpos,'AUTOTP')
    local boat_found=false
    for k, v in ipairs(lp.get_nearby_objects(4)) do
        local txt = v:get_item_textures()
		if ( txt:find('mcl_boats_texture')) then
            boat_found=true
            autofly.aim(vector.add(v:get_pos(),{x=0,y=-1.5,z=0}))
            minetest.after("0.2",function()
                minetest.interact("place") end)
            minetest.after("1.5",function()
                 autofly.warpae('AUTOTP')
              end)
            return true
        end
    end
    if not boat_found then minetest.after("5.0",function() autofly.autotp(tpname) end) return end
    --minetest.sound_play({name = "default_alert", gain = 3.0})
    --autofly.delete_waypoint('AUTOTP')
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


minetest.after("5.0",function()
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
