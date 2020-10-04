--
-- cora's defensive combat hax
-- * undying
-- * damagepanic

flightaura = {}
local undying = true --will automatically /sethome when taking damage below 3 hp, tp you back when you die and dig the bones undying needs autorespawn enabled in dragonfire (might steal the code at some point to enable it for vanilla / other clients)
local damagepanic = true --will tp you 50 nodes up on damage taken when hp is < paniclimit

local check_target = true

local paniclimit=17

local tprange=50;


local function sleep(n)  -- seconds
  local t0 = os.clock()
  while os.clock() - t0 <= n do end
end


local function mwarp(pos)
	if not pos then return end
	--minetest.display_chat_message("Flightaura: Damage taken, target clear. Tping up to "..pos['y'])
	minetest.localplayer:set_pos(pos)

end

minetest.register_on_death(function()
	if not minetest.settings:get_bool("undying") then return end
	minetest.send_chat_message("/home")
	sleep(2)
	local bn=minetest.find_node_near(minetest.localplayer:get_pos(), 4, {"bones:bones"},true)
	if not bn then return end
	minetest.dig_node(bn)
end)

local tprangeh=20
local tprangepy=50
local tprangeny=60


local function get_rnd_pos()
	local ppos=minetest.localplayer:get_pos()
	local xx=1
	local yy=40
	local zz=1
	local pos=vector.add(ppos,{x=xx,y=yy,z=zz})
	return pos
end

function flightaura.find_target()
	if not minetest.settings:get_bool("damagepanic") then return end

		local nod=minetest.get_node_or_nil(get_rnd_pos())
		if not nod then return end
		while (nod["name"] ~= "air") do
			local rpos=get_rnd_pos()
			local tpos=vector.add(ppos,rpos)
			nod=minetest.get_node_or_nil(tpos)
			fnd=true
		end
	--minetest.display_chat_message(dump(rpos))
	if not fnd then
		--minetest.display_chat_message("no clear node to flee. turning on Killaura.")
		minetest.settings:set_bool("killaura",true)
		return false
	end
	return tpos
end

minetest.register_on_damage_taken(function(hp)
	local hhp=minetest.localplayer:get_hp()
	--minetest.display_chat_message("hp:"..hp)
	--minetest.display_chat_message("hhp:"..hhp)
	if (hp==0 ) then return end
	if ( hhp < paniclimit ) and (hhp >= 3 ) then
		cpos=flightaura.find_target()
		if minetest.settings:get_bool("damagepanic") then
			minetest.settings:set("free_move", "true")
			mwarp(vector.add(cpos,{x=0,y=-1,z=0}))
		end
	elseif (hp < 3 ) then
		if minetest.settings:get_bool("undying") then
			minetest.settings:set_bool("autorespawn",true)
			minetest.send_chat_message("/sethome") end
		end
end
)


minetest.register_chatcommand("eat", {
	params = "",
	description = "",
	func = function()
		local pl = minetest.localplayer
		local inv = minetest.get_inventory("current_player")
		for index, stack in pairs(inv.main) do
			minetest.display_chat_message(stack)
			if (stack == "mcl_farming:carrot_item_gold") then pl.set_wield_index(index) break end
		end
		return
end})
minetest.register_chatcommand("dhead", {
	params = "",
	description = "",
	func = function()
		--eat()
	--	minetest.display_chat_message("head")
--		minetest.display_chat_message(dump(minetest.get_inventory("current_player").main))
		minetest.settings:set_bool("autotool",true)
		sleep(1)
		local ppos=vector.add(minetest.localplayer:get_pos(),{x=0,y=1,z=0})
		if ppos then minetest.dig_node(ppos) end
		return
end
})




-- REG cheats on DF
if (_G["minetest"]["register_cheat"] ~= nil) then
	 minetest.register_cheat("Flightaura", "Combat", "damagepanic")
	 minetest.register_cheat("Undying", "Combat", "undying")
else
	 minetest.settings:set_bool('undying',true)
	 minetest.settings:set_bool('damagepanic',false)
end
