-- CC0/Unlicense Emilia 2020

local tlang = {}

local prefix = ""
if minetest ~= nil then
    prefix = minetest.get_modpath(minetest.get_current_modname()) .. "/"
end

local function merge_tables(l1, l2)
    local out = {}

    for k, v in pairs(l1) do
        out[k] = v
    end

    for k, v in pairs(l2) do
        out[k] = v
    end

    return out
end

local function load_api_file(file)
    tlang = merge_tables(tlang, dofile(prefix .. file))
end

load_api_file("tlang_lex.lua")
load_api_file("tlang_parse.lua")
load_api_file("tlang_vm.lua")


function tlang.combine_builtins(b1, b2)
    return merge_tables(b1, b2)
end

function tlang.construct_builtins(builtins)
    return merge_tables(tlang.builtins, builtins)
end

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

function tlang.get_state(code)
    local lexed = tlang.lex(code)
    local parsed = tlang.parse(lexed)

    return {
        locals = {{
            pc = {sg = 1, pos = "__ast__", elem = 1},
            v__src__ = tlang.value_to_tlang(code),
            v__lex__ = tlang.value_to_tlang(lexed),
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


local function test()
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
        var print       # should be 'outside'
        'inside' `var =
        var print       # should be 'inside'
    } run
    var print           # should be 'inside'
    ]]

    local while_test = [[
    5 `cur =
    {
        `cur --
        cur
    } {
        "four times" print
    } while
    ]]

    local repeat_test = [[
    {
        "four times" print
    } 4 repeat
    {
        i print
    } 5 `i repeat
    ]]

    local stack_test = "5 5 == print"

    local args_test = [[
    {   0 `first `second args
        first print
        second print
    } `test =
    1 2 test
    ]]

    local ifelse_test = [[
        {
            {
                'if' print
            } {
                'else' print
            } if
        } `ifprint =

        1 ifprint
        0 ifprint
    ]]

    local nest_run = [[
        {
            {
                'innermost' print
            } run
        } run
        'work' print
    ]]

    tlang.exec(ifelse_test)
end

if minetest == nil then
    test()
end

return tlang
