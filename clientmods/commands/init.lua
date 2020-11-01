-- Minetest: builtin/common/chatcommands.lua
--[[
core.registered_chatcommands = {}

function core.register_chatcommand(cmd, def)
	def = def or {}
	def.params = def.params or ""
	def.description = def.description or ""
	def.privs = def.privs or {}
	def.mod_origin = core.get_current_modname() or "??"
	core.registered_chatcommands[cmd] = def
end

function core.unregister_chatcommand(name)
	if core.registered_chatcommands[name] then
		core.registered_chatcommands[name] = nil
	else
		core.log("warning", "Not unregistering chatcommand " ..name..
			" because it doesn't exist.")
	end
end

function core.override_chatcommand(name, redefinition)
	local chatcommand = core.registered_chatcommands[name]
	assert(chatcommand, "Attempt to override non-existent chatcommand "..name)
	for k, v in pairs(redefinition) do
		rawset(chatcommand, k, v)
	end
	core.registered_chatcommands[name] = chatcommand
end

if INIT == "client" then
	function core.register_list_command(command, desc, setting)
		local def = {}
		def.description = desc
		def.params = "del <item> | add <item> | list"
		function def.func(param)
			local list = (minetest.settings:get(setting) or ""):split(",")
			if param == "list" then
				return true, table.concat(list, ", ")
			else
				local sparam = param:split(" ")
				local cmd = sparam[1]
				local item = sparam[2]
				if cmd == "del" then
					if not item then
						return false, "Missing item."
					end
					local i = table.indexof(list, item)
					if i == -1 then
						return false, item .. " is not on the list."
					else
						table.remove(list, i)
						core.settings:set(setting, table.concat(list, ","))
						return true, "Removed " .. item .. " from the list."
					end
				elseif cmd == "add" then
					if not item then
						return false, "Missing item."
					end
					local i = table.indexof(list, item)
					if i ~= -1 then
						return false, item .. " is already on the list."
					else
						table.insert(list, item)
						core.settings:set(setting, table.concat(list, ","))
						return true, "Added " .. item .. " to the list."
					end
				end
			end
			return false, "Invalid usage. (See /help " .. command .. ")"
		end
		core.register_chatcommand(command, def)
	end
end

local cmd_marker = "/"

local function gettext(...)
	return ...
end

local function gettext_replace(text, replace)
	return text:gsub("$1", replace)
end


if INIT == "client" then
	cmd_marker = "."
	gettext = core.gettext
	gettext_replace = fgettext_ne
end

local function do_help_cmd(name, param)
	local function format_help_line(cmd, def)
		local msg = core.colorize("#00ffff", cmd_marker .. cmd)
		if def.params and def.params ~= "" then
			msg = msg .. " " .. def.params
		end
		if def.description and def.description ~= "" then
			msg = msg .. ": " .. def.description
		end
		return msg
	end
	if param == "" then
		local cmds = {}
		for cmd, def in pairs(core.registered_chatcommands) do
			if INIT == "client" or core.check_player_privs(name, def.privs) then
				cmds[#cmds + 1] = cmd
			end
		end
		table.sort(cmds)
		return true, gettext("Available commands: ") .. table.concat(cmds, " ") .. "\n"
				.. gettext_replace("Use '$1help <cmd>' to get more information,"
				.. " or '$1help all' to list everything.", cmd_marker)
	elseif param == "all" then
		local cmds = {}
		for cmd, def in pairs(core.registered_chatcommands) do
			if INIT == "client" or core.check_player_privs(name, def.privs) then
				cmds[#cmds + 1] = format_help_line(cmd, def)
			end
		end
		table.sort(cmds)
		return true, gettext("Available commands:").."\n"..table.concat(cmds, "\n")
	elseif INIT == "game" and param == "privs" then
		local privs = {}
		for priv, def in pairs(core.registered_privileges) do
			privs[#privs + 1] = priv .. ": " .. def.description
		end
		table.sort(privs)
		return true, "Available privileges:\n"..table.concat(privs, "\n")
	else
		local cmd = param
		local def = core.registered_chatcommands[cmd]
		if not def then
			return false, gettext("Command not available: ")..cmd
		else
			return true, format_help_line(cmd, def)
		end
	end
end

if INIT == "client" then
	core.register_chatcommand("help", {
		params = gettext("[all | <cmd>]"),
		description = gettext("Get help for commands"),
		func = function(param)
			return do_help_cmd(nil, param)
		end,
	})
--]]
core.register_chatcommand("say", {
	description = "Send raw text",
	func = function(text)
		minetest.send_chat_message(text)
		return true
	end,
})

core.register_chatcommand("teleport", {
	params = "<X>,<Y>,<Z>",
	description = "Teleport to relative coordinates.",
	func = function(param)
		local success, pos = minetest.parse_relative_pos(param)
		if success then
			minetest.localplayer:set_pos(pos)
			return true, "Teleporting to " .. minetest.pos_to_string(pos)
		end
		return false, pos
	end,
})

core.register_chatcommand("wielded", {
	description = "Print itemstring of wieleded item",
	func = function()
		return true, minetest.localplayer:get_wielded_item():get_name()
	end
})

core.register_chatcommand("disconnect", {
	description = "Exit to main menu",
	func = function(param)
		minetest.disconnect()
	end,
})

core.register_chatcommand("players", {
	description = "List online players",
	func = function(param)
		return true, "Online players: " .. table.concat(minetest.get_player_names(), ", ")
	end
})

core.register_chatcommand("kill", {
	description = "Kill yourself",
	func = function()
		minetest.send_damage(minetest.localplayer:get_hp())
	end,
})

core.register_chatcommand("hop", {
	description = "Hop",
	func = function()
		minetest.set_keypress("jump", true)
	end,
})

core.register_chatcommand("set", {
	params = "([-n] <name> <value>) | <name>",
	description = "Set or read client configuration setting",
	func = function(param)
		local arg, setname, setvalue = string.match(param, "(-[n]) ([^ ]+) (.+)")
		if arg and arg == "-n" and setname and setvalue then
			minetest.settings:set(setname, setvalue)
			return true, setname .. " = " .. setvalue
		end

		setname, setvalue = string.match(param, "([^ ]+) (.+)")
		if setname and setvalue then
			if not minetest.settings:get(setname) then
				return false, "Failed. Use '.set -n <name> <value>' to create a new setting."
			end
			minetest.settings:set(setname, setvalue)
			return true, setname .. " = " .. setvalue
		end

		setname = string.match(param, "([^ ]+)")
		if setname then
			setvalue = minetest.settings:get(setname)
			if not setvalue then
				setvalue = "<not set>"
			end
			return true, setname .. " = " .. setvalue
		end

		return false, "Invalid parameters (see .help set)."
	end,
})
--[[]
else
	core.register_chatcommand("help", {
		params = "[all | privs | <cmd>]",
		description = "Get help for commands or list privileges",
		func = do_help_cmd,
	})
end
--]]
