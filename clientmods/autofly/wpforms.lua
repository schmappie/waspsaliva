


-- ADVMARKERS Stuff
-- Get the waypoints formspec
local formspec_list = {}
local selected_name = false

local storage = minetest.get_mod_storage()
local wpr=false;
local twpname=nil
local info=minetest.get_server_info()
local stprefix="autofly-".. info['address']  .. '-'

autofly = {}
wps={}
local tspeed = 20 -- speed in blocks per second
local speed=0;
local ltime=0
function autofly.display_formspec()
    local formspec = 'size[5.25,8]' ..
                     'label[0,0;Waypoint list]' ..
                     'button_exit[0,7.5;1.3125,0.5;display;GO]' ..
                     'button[1.1125,7.5;0.9,0.5;warp;wrp]' ..
                     'button[1.6125,7.5;1.2,0.5;warpae;w+e]' ..
                     'button[2.625,7.5;1.3,0.5;rename;Rename]' ..
                     'button[3.9375,7.5;1.3,0.5;delete;Delete]' ..
                     'textlist[0,0.75;5,6;marker;'

    -- Iterate over all the waypoints
    local selected = 1
    formspec_list = {}

    local waypoints = autofly.getwps()


    for id, name in ipairs(waypoints) do
        if id > 1 then
            formspec = formspec .. ','
        end
        if not selected_name then
            selected_name = name
        end
        if name == selected_name then
            selected = id
        end
        formspec_list[#formspec_list + 1] = name
        formspec = formspec .. '##' .. minetest.formspec_escape(name)
    end

    -- Close the text list and display the selected waypoint position
    formspec = formspec .. ';' .. tostring(selected) .. ']'
    if selected_name then
        local pos = autofly.get_waypoint(selected_name)
        if pos then
            pos = minetest.formspec_escape(tostring(pos.x) .. ', ' ..
            tostring(pos.y) .. ', ' .. tostring(pos.z))
            pos = 'Waypoint position: ' .. pos
            formspec = formspec .. 'label[0,6.75;' .. pos .. ']'
        end
    else
        -- Draw over the buttons
        formspec = formspec .. 'button_exit[0,7.5;5.25,0.5;quit;Close dialog]' ..
            'label[0,6.75;No waypoints. Add one with ".add_mrkr".]'
    end

    -- Display the formspec
    return minetest.show_formspec('autofly-csm', formspec)
end

minetest.register_on_formspec_input(function(formname, fields)
    if formname == 'autofly-ignore' then
        return true
    elseif formname ~= 'autofly-csm' then
        return
    end
    local name = false
    if fields.marker then
        local event = minetest.explode_textlist_event(fields.marker)
        if event.index then
            name = formspec_list[event.index]
        end
    else
        name = selected_name
    end

    if name then
        if fields.display then
            if not autofly.display_waypoint(name) then
                minetest.display_chat_message('Error displaying waypoint!')
            end
        elseif fields.warp then
        if not autofly.warp(name) then
                minetest.display_chat_message('warp error')
            end
        elseif fields.warpae then
            if not autofly.warpae(name) then
                minetest.display_chat_message('warpandexit error')
            end
        elseif fields.rename then
            minetest.show_formspec('autofly-csm', 'size[6,3]' ..
                'label[0.35,0.2;Rename waypoint]' ..
                'field[0.3,1.3;6,1;new_name;New name;' ..
                minetest.formspec_escape(name) .. ']' ..
                'button[0,2;3,1;cancel;Cancel]' ..
                'button[3,2;3,1;rename_confirm;Rename]')
        elseif fields.rename_confirm then
            if fields.new_name and #fields.new_name > 0 then
                if autofly.rename_waypoint(name, fields.new_name) then
                    selected_name = fields.new_name
                else
                    minetest.display_chat_message('Error renaming waypoint!')
                end
                autofly.display_formspec()
            else
                minetest.display_chat_message(
                    'Please enter a new name for the marker.'
                )
            end
        elseif fields.delete then
            minetest.show_formspec('autofly-csm', 'size[6,2]' ..
                'label[0.35,0.25;Are you sure you want to delete this waypoint?]' ..
                'button[0,1;3,1;cancel;Cancel]' ..
                'button[3,1;3,1;delete_confirm;Delete]')
        elseif fields.delete_confirm then
            autofly.delete_waypoint(name)
            selected_name = false
            autofly.display_formspec()
        elseif fields.cancel then
            autofly.display_formspec()
        elseif name ~= selected_name then
            selected_name = name
            autofly.display_formspec()
        end
    elseif fields.display or fields.delete then
        minetest.display_chat_message('Please select a waypoint.')
    end
    return true
end)


-- Export waypoints
function autofly.export(raw)
    local s = storage:to_table().fields
    if raw == 'M' then
        s = minetest.compress(minetest.serialize(s))
        s = 'M' .. minetest.encode_base64(s)
    elseif not raw then
        s = minetest.compress(minetest.write_json(s))
        s = 'J' .. minetest.encode_base64(s)
    end
    return s
end

-- Allow string exporting
minetest.register_chatcommand('wpexp', {
    params      = '[old]',
    description = 'Exports an autofly string containing all your markers.',
    func = function(param)
        local export
        if param == 'old' then
            export = autofly.export('M')
        else
            export = autofly.export()
        end
        minetest.show_formspec('autofly-ignore',
            'field[_;Your waypoint export string;' ..
            minetest.formspec_escape(export) .. ']')
    end
})

--register_chatcommand_alias('wpexp', 'wp_export', 'waypoint_export')

-- String importing
minetest.register_chatcommand('wpimp', {
    params      = '<autofly string>',
    description = 'Imports an autofly string. This will not overwrite ' ..
        'existing markers that have the same name.',
    func = function(param)
        if autofly.import(param) then
            return true, 'Waypoints imported!'
        else
            return false, 'Invalid autofly string!'
        end
    end
})
--register_chatcommand_alias('wpimp', 'wp_import', 'waypoint_import')

-- Import waypoints
function autofly.import(s)
    if type(s) ~= 'table' then
        local ver = s:sub(1, 1)
        if ver ~= 'M' and ver ~= 'J' then return end
        s = minetest.decode_base64(s:sub(2))
        local success, msg = pcall(minetest.decompress, s)
        if not success then return end
        if ver == 'M' then
            s = minetest.deserialize(msg, true)
        else
            s = minetest.parse_json(msg)
        end
    end

    -- Iterate over waypoints to preserve existing ones and check for errors.
    if type(s) == 'table' then
        for name, pos in pairs(s) do
            if type(name) == 'string' and type(pos) == 'string' and
              name:sub(1, 7) == 'marker-' and minetest.string_to_pos(pos) and
              storage:get_string(name) ~= pos then
                -- Prevent collisions
                local c = 0
                while #storage:get_string(name) > 0 and c < 50 do
                    name = name .. '_'
                    c = c + 1
                end

                -- Sanity check
                if c < 50 then
                    storage:set_string(name, pos)
                end
            end
        end
        return true
    end
end