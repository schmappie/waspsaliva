local tlang = {}

dof = dofile
if minetest ~= nil then
    dof = do_file
end

tlang.lex = dof("tlang_lex.lua")
tlang.parse = dof("tlang_parse.lua")
tlang.builtins, tlang.gassign, tlang.step = dof("tlang_vm.lua")

-- TODO
--[[
lexer should include line/character number in symbols
error messages
maps should be able to have out of order number indexes (like [1 2 3 10:"Out of order"])
map.key accessing syntax
    parse as identifier, include . as identifier character, split on . and thats the indexing tree
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
        code_stack = {},
        builtins = tlang.builtins,
        wait_target = nil,
        nextpop = false
    }
end

function tlang.exec(code)
    local state = tlang.get_state(code)
    tlang.run(state)
end


local complex = [[{dup *} `square =
-5.42 square
"Hello, world!" print
[1 2 3 str:"String"]
]]

local number = "-4.2123"

local simple = "{dup *}"

local map = "[this:2 that:3]"

local square = [[{dup *} `square =
5 square print]]

local square_run = "5 {dup *} run print"

local comment_test = "'asd' print # 'aft' print"

local forever_test = [[
5  # iteration count
{
    dup     # duplicate iter count
    print   # print countdown
    --      # decrement
    dup 0 ==    # check if TOS is 0
    {break} if  # break if TOS == 0
}
forever   # run loop
]]

local local_test = [[
'outside' `var =
{
    'inside' `var =
    var print
} run
var print
]]

local while_test = [[
5 `cur = {cur -- `cur = cur} {"five times" print} while
]]


local stack_test = "5 5 == print"

tlang.exec(while_test)

return tlang
