--
-- undying



minetest.register_on_death(function()
	if not minetest.settings:get_bool("undying") then return end
	minetest.after(0.2,function()
		minetest.send_chat_message("/home")
		minetest.after(1.0,function()
			local bn=minetest.find_node_near(minetest.localplayer:get_pos(), 6, {"bones:bones"},true)
			if not bn then return end
			minetest.dig_node(bn)
		end)
	end)
end)

minetest.register_on_damage_taken(function(hp)
	local hhp=minetest.localplayer:get_hp()
	if (hhp==0 ) then return end
	if (hhp < 3 ) then
		if minetest.settings:get_bool("undying") then
			minetest.settings:set_bool("autorespawn",true)
			minetest.send_chat_message("/sethome") end
		end
end
)


-- REG cheats on DF
if (_G["minetest"]["register_cheat"] ~= nil) then
	 minetest.register_cheat("Undying", "Combat", "undying")
else
	 minetest.settings:set_bool('undying',true)
end
