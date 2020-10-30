function core.parse_pos(param)
	local p = {}
	local playerpos = core.localplayer:get_pos()
	p.x, p.y, p.z = string.match(param, "^([~|%d.-]+)[, ] *([~|%d.-]+)[, ] *([~|%d.-]+)$")
	for k, v in pairs(p) do
		if p[k] == "~" then
			p[k] = playerpos[k]
		else
			p[k] = tonumber(v)
		end
	end
	if p.x and p.y and p.z then
		return true, vector.round(p)
	end
	return false, "Invalid position (" .. param .. ")"
end

function core.parse_relative_pos(param)
	local success, pos = core.parse_pos(param:gsub("~", "0"))
	if success then pos = vector.round(vector.add(core.localplayer:get_pos(), pos)) end
	return success, pos
end

function core.find_item(item)
	for index, stack in ipairs(core.get_inventory("current_player").main) do
		if stack:get_name() == item then
			return index
		end
	end
end

function core.switch_to_item(item)
	local i = core.find_item(item)
	if i then
		core.localplayer:set_wield_index(i - 1)
		return true
	else
		return false
	end
end
