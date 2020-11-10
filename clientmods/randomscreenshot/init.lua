---
-- random screenshots


randomscreenshot = {}

local interval=10 -- minimum number of minutes to wait til next screenshot
local rnd=10 --random time
local nextsc=0


minetest.register_globalstep(function()
    if not minetest.settings:get_bool("randomsc") then return end
    if os.time() < nextsc then return end
    math.randomseed(os.clock())
    nextsc=os.time() + ( interval * 60 ) + math.random(rnd * 60)
    minetest.after("15.0",minetest.take_screenshot)

end)

if (_G["minetest"]["register_cheat"] ~= nil) then
    minetest.register_cheat("Random Screenshot", "World", "randomsc")
else
    minetest.settings:set_bool('randomsc',true)
end
