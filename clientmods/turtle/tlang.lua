local tlang = {}

tlang.lex = dofile("tlang_lex.lua")
tlang.parse = dofile("tlang_parse.lua")
tlang.builtins, tlang.gassign, tlang.step = dofile("tlang_vm.lua")

-- TODO
--[[
code shouldnt require a final whitespace
lexer should include line/character number in symbols
error messages
maps shouldnt require whitespace around [ and ]
maps should be able to have out of order number indexes (like [1 2 3 10:"Out of order"])
map.key accessing syntax
--]]

function tlang.run(state)
    while true do
        local more = tlang.step(state)
        if more == true or more == nil then
            -- continue along
        elseif type(more) == "string" then
            print(more) -- error
        elseif more == false then
            return -- done
        else
            print("Unknown error, tlang.step returned: " .. tostring(more))
        end
    end
end

local function assign_many(state, source)
    for k, v in pairs(source) do
        tlang.gassign(state, k, v)
    end
end

-- convert a lua value into a tlang literal
function tlang.valconv(value)
    local t = type(value)
    if t == "string" then
        return {type = "string", value = value}
    elseif t == "number" then
        return {type = "number", value = value}
    elseif t == "table" then
        local map = {}

        for k, v in pairs(value) do
            map[k] = tlang.valconv(v)
        end

        return {type = "map", value = map}
    end
end

function tlang.get_state(code)
    local lexed = tlang.lex(code)
    local parsed = tlang.parse(lexed)

    return {
        locals = {{
            pc = {sg = 1, pos = "__ast__", elem = 1},
            v__src__ = tlang.valconv(code),
            v__lex__ = tlang.valconv(lexed),
            v__ast__ = {type = "code", value = parsed}}},
        stack = {},
        builtins = tlang.builtins,
        wait_target = nil,
        nextpop = false,
        tree = parse_state
    }
end

function tlang.exec(code)
    local state = tlang.get_state(code)
    tlang.run(state)
end


local complex = [[{dup *} `square =
-5.42 square
"Hello, world!" print
[ 1 2 3 str:"String" ]
]]

local number = [[-4.2123
]]

local simple = [[{dup *}
]]

local map = [[
[ "thing":1 ]
]]

tlang.exec([[{dup *} `square =
5 square print
]])

return tlang
