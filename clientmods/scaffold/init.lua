scaffold = {}
scaffold.registered_scaffolds = {}

function scaffold.register_scaffold(func)
    table.insert(scaffold.registered_scaffolds, func)
end

function scaffold.step_scaffolds()
    for i, v in ipairs(scaffold.registered_scaffolds) do
        v()
    end
end

function scaffold.template(setting, func, offset)
    if not offset then
        offset = {x = 0, y = -1, z = 0}
    end

    return function()
        if minetest.settings:get_bool(setting) then
            local lp = minetest.localplayer:get_pos()
            local tgt = vector.round(vector.add(lp, offset))
            func(tgt)
        end
    end
end

function scaffold.register_template_scaffold(setting, func, offset)
    scaffold.register_scaffold(scaffold.template(setting, func, offset))
end

minetest.register_globalstep(scaffold.step_scaffolds)

local mpath = minetest.get_modpath(minetest.get_current_modname())
dofile(mpath .. "/sapscaffold.lua")
dofile(mpath .. "/slowscaffold.lua")
