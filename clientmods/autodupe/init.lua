-- to be implemented later
--[[

-- maybe should have a game specifier?
autodupe = {}

-- perform 1 dupe action
function autodupe.dupe()
end

-- dupes an inv and puts into a shulker
function autodupe.make_shulker()
end

--]]

if minetest.settings:get_bool("autodupe_test") then
    local prefix = minetest.get_modpath(minetest.get_current_modname())
    dofile(prefix .. "/test.lua") -- oi no seein my tests
end

