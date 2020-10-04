autowarp = {}

local storage = minetest.get_mod_storage()

local cond=true;
local function isleep(s)
  local ntime = os.time() + s
  repeat until os.time() > ntime
end


minetest.register_chatcommand("awarp", {
	params = "",
	description = "Warp to a set warp or a position.",
	func = function(param)
		local xx=4000
		--for o,p in poss do
			--local pos = minetest.parse_pos("4000,20,4000")
		while cond do
			minetest.localplayer:set_pos({x=xx,y=20,z=4000})
			isleep(5)
			xx=xx-100
			if xx < -4000 then break end
		end
    end
})
