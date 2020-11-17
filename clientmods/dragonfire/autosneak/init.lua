local was_enabled = false
local pwas_enabled = false

minetest.register_globalstep(function()
	if minetest.settings:get_bool("autosneak") then
		minetest.set_keypress("sneak", true)
		was_enabled = true
	elseif was_enabled then
		was_enabled = false
		minetest.set_keypress("sneak", false)
	end
	if minetest.settings:get_bool("autosneak_conditional") then
		local blck=minetest.get_node_or_nil(vector.add(minetest.localplayer:get_pos(),{x=0,y=-1,z=0}))
		if blck ~= nil and blck.name~="air" then
			minetest.set_keypress("sneak", true)
			pwas_enabled = true
		end
	elseif pwas_enabled then
		pwas_enabled = false
		minetest.set_keypress("sneak", false)
	end
end)

minetest.register_cheat("AutoSneak", "Movement", "autosneak")
minetest.register_cheat("GroundASneak", "Movement", "autosneak_conditional")
