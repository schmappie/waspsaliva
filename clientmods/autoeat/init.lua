autoeat = {}

local last_step_eating = false

function autoeat.eat()
	local player = minetest.localplayer
	local owx=player:get_wield_index()
	player:set_wield_index(8)
	minetest.place_node(player:get_pos())
	minetest.after("0.2",function()
		player:set_wield_index(owx)
	end)
end

minetest.register_on_damage_taken(function()
	if not minetest.settings:get_bool("autoeat") then return end
	autoeat.eat()
	autoeat.eating = true
end)

minetest.register_globalstep(function()
	if last_step_eating then
		autoeat.eating, last_step_eating = false, false
	elseif autoeat.eating then
		last_step_eating = true
	end

end)

minetest.register_cheat("AutoEat", "Player", "autoeat")
