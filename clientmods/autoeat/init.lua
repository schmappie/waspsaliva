autoeat = {}
autoeat.last = 0
local last_step_eating = false
local interval = 5

function autoeat.eat()
	local player = minetest.localplayer
	local owx=player:get_wield_index()
	autoeat.eating = true
	player:set_wield_index(8)
	minetest.place_node(player:get_pos())
	minetest.after("0.2",function()
		player:set_wield_index(owx)
	end)
end

function autoeat.conditional()
		if os.time() < autoeat.last + ( interval * 60 ) then return	end
		autoeat.last = os.time()
		autoeat.eat()
end

minetest.register_on_damage_taken(function()
	if not minetest.settings:get_bool("autoeat") then return end
	autoeat.eat()
end)

minetest.register_globalstep(function()
	if last_step_eating then
		autoeat.eating, last_step_eating = false, false
	elseif autoeat.eating then
		last_step_eating = true
	end
	if ( autofly.speed ~= 0 and minetest.settings:get_bool("autosprint") )
	or (minetest.settings:get_bool("autosprintfsprint") and minetest.settings:get_bool("continuous_forward")  )
	or (minetest.settings:get_bool("killaura")) then
		autoeat.conditional()
	end


end)

minetest.register_cheat("AutoEat", "Player", "autoeat")
