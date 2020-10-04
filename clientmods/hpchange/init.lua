local widget
local last_hp

local function show_widget()
    widget = minetest.localplayer:hud_add({
        hud_elem_type   = "text",
        name            = "HP Change",
        text            = "Last HP change: ",
        number          = 0x00FF00,
        direction       = 0,
        position        = {x = 0.85, y = 0.8},
        scale           = {x = 0.9, y = 0.9},
        alignment       = {x = 1, y = 1},
        offset          = {x = 0, y = 0}
    })
end

local function update_hud(delta)
    if minetest.localplayer ~= nil and delta ~= 0 then
        if widget == nil then
            show_widget()
        end

        local num = tostring(math.abs(delta))
        if delta < 0 then
            num = "-" .. num
        else
            num = "+" .. num
        end

        minetest.localplayer:hud_change(widget, "text", "Last HP change: " .. num)

        if delta > 0 then
            minetest.localplayer:hud_change(widget, "number", 0x00FF00)
        else
            minetest.localplayer:hud_change(widget, "number", 0xFF0000)
        end

        if last_hp ~= nil then
            last_hp = last_hp + delta
        end
    end
end

-- health decrease (potential)
minetest.register_on_damage_taken(function(hp)
    update_hud(-hp)
end)

-- health increase
minetest.register_on_hp_modification(function(hp)
    if last_hp == nil and minetest.localplayer ~= nil then
        last_hp = minetest.localplayer:get_hp()
    end

    if last_hp ~= nil and last_hp <= hp then
        update_hud(hp - last_hp)
    end
end)
