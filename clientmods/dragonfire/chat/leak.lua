local etime = 0

--[[minetest.register_globalstep(function(dtime)
	if not minetest.settings:get_bool("leak") then return end
	etime = etime + dtime
	if etime < 5 then return end
	etime = 0
	local player = minetest.localplayer
	minetest.send_chat_message(minetest.pos_to_string(vector.floor(player:get_pos())))
end)--]]
function cleak()
	minetest.send_chat_message(minetest.pos_to_string(vector.floor(player:get_pos())))
end  
minetest.register_chatcommand("cleak", {
        params = "<pos>",
            description = "Open node inventory metadata at position.",
                func = cleak
            })


--minetest.register_cheat("Leak", "Player", "leak")
