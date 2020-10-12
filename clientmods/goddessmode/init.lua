--
-- cora's defensive combat hax

local tprange=50


local function sleep(n)  -- seconds
  local t0 = os.clock()
  while os.clock() - t0 <= n do end
end


local function mwarp(pos)
	minetest.localplayer:set_pos(pos)
end


local tprangeh=20
local tprangepy=50
local tprangeny=60
local karange=7

local function gettarget(epos)
	--local mpos=minetest.localplayer:get_pos()
	math.randomseed(os.time())
	local angle=math.random(0,360)
	local tg={x=0,y=0,z=0}
	tg.x=karange * math.sin(angle)
	tg.z=karange * math.cos(angle)
	return vector.add(epos,tg)
end

local function rro() -- reverse restraining order
    for k, v in ipairs(minetest.localplayer.get_nearby_objects(10)) do
        if (v:is_player() and v:get_name() ~= minetest.localplayer:get_name()) then
            local pos = v:get_pos()
            pos.y = pos.y - 1
			local mpos=minetest.localplayer:get_pos()
            local distance=vector.distance(mpos,pos)
            if distance < karange then mwarp(gettarget(pos)) end
            --autofly.aim(pos)
            return
        end
    end
end

minetest.register_globalstep(function()
    if minetest.settings:get_bool("goddess") then
        rro()
    end
end)



-- REG cheats on DF
if (_G["minetest"]["register_cheat"] ~= nil) then
	 minetest.register_cheat("Goddess Mode", "Combat", "goddess")
else
	 minetest.settings:set_bool('goddess',true)
end
