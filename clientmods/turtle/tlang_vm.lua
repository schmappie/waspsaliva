-- CC0/Unlicense Emilia 2020

local tlang = {}

local function in_list(value, list)
    for k, v in ipairs(list) do
        if v == value then
            return true
        end
    end
    return false
end

local function in_keys(value, list)
    for k, v in pairs(list) do
        if k == value then
            return true
        end
    end
    return false
end

-- state
--[[
    {
        locals = {},
        stack = {},
        builtins = {},
        code_stack = {},
        wait_target = int,
        nextpop = f/t
    }
--]]

-- program counter
--[[
    sg = 0/1,
    pos = int/string,
    elem = int,
    wait_target = float
--]]

-- convert a lua value into a tlang literal
function tlang.value_to_tlang(value)
    local t = type(value)
    if t == "string" then
        return {type = "string", value = value}
    elseif t == "number" then
        return {type = "number", value = value}
    elseif t == "table" then
        local map = {}

        for k, v in pairs(value) do
            map[k] = tlang.value_to_tlang(v)
        end

        return {type = "map", value = map}
    end
end

-- convert a tlang literal to a lua value
function tlang.tlang_to_value(tl)
    if type(tl) ~= "table" then
        return
    end

    if tl.type == "map" then
        local o = {}

        for k, v in pairs(tl.value) do
            o[k] = tlang.tlang_to_value(v)
        end

        return o
    else
        return tl.value
    end
end

local literals = {
    "quote",
    "code",
    "map",
    "string",
    "number"
}


function tlang.call(state, target)
    if target.sg == 0 then
        state.code_stack[#state.code_stack + 1] = state.stack[target.pos]
        table.remove(state.stack, target.pos)
        target.pos = #state.code_stack
    end

    state.locals[#state.locals + 1] = {pc = target}
end

function tlang.call_tos(state)
    tlang.call(state, {sg = 0, pos = #state.stack, elem = 1})
end

local function find_var_pos(state, name)
    local slen = #state.locals

    for i = 1, slen do
        local v = state.locals[slen + 1 - i]
        if in_keys("v" .. name, v) then
            return slen + 1 - i
        end
    end
end

function tlang.near_access(state, name)
    local n = find_var_pos(state, name)
    if n then
        return state.locals[n]["v" .. name]
    end
end

function tlang.global_assign(state, name, value)
    state.locals[0]["v" .. name] = value
end

function tlang.local_assign(state, name, value)
    state.locals[#state.locals]["v" .. name] = value
end

function tlang.near_assign(state, name, value)
    local n = find_var_pos(state, name)
    if n then
        state.locals[n]["v" .. name] = value
    else
        state.locals[#state.locals]["v" .. name] = value
    end
end

local function getpc(state)
    return state.locals[#state.locals].pc
end

local function accesspc(state, pc)
    local code
    if pc.sg == 0 then -- stack
        code = state.code_stack[pc.pos]
    elseif pc.sg == 1 then -- global
        code = tlang.near_access(state, pc.pos)
    end

    if code then
        return code.value[pc.elem]
    end
end

local function incpc(state, pc)
    local next_pc = {sg = pc.sg, pos = pc.pos, elem = pc.elem + 1}

    if accesspc(state, next_pc) then
        return next_pc
    end
end

local function getnext(state)
    if state.locals[#state.locals].nextpop then
        local pc = getpc(state)

        state.locals[#state.locals] = nil
        if #state.locals == 0 then
            return nil
        end

        -- pop code stack
        if pc.sg == 0 then
            state.code_stack[pc.pos] = nil
        end
    end

    local current
    if not state.locals[#state.locals].nextpop then
        state.current_pc = getpc(state)
        current = accesspc(state, state.current_pc)
    end

    local incd = incpc(state, getpc(state))
    if not incd then
        state.locals[#state.locals].nextpop = true
    else
        state.locals[#state.locals].pc = incd
    end

    return current
end

-- doesn't support jumping out of scope yet
function tlang.set_next_pc(state, pc)
    -- this probably causes issues when jumping outside scope
    state.locals[#state.locals].nextpop = nil

    state.locals[#state.locals].pc = pc
end

function tlang.peek_raw(state)
    return state.stack[#state.stack]
end

function tlang.pop_raw(state)
    local tos = tlang.peek_raw(state)
    state.stack[#state.stack] = nil
    return tos
end

function tlang.push_raw(state, value)
    state.stack[#state.stack + 1] = value
end

function tlang.peek(state)
    return tlang.tlang_to_value(tlang.peek_raw(state))
end

function tlang.pop(state)
    return tlang.tlang_to_value(tlang.pop_raw(state))
end

function tlang.push(state, value)
    tlang.push_raw(state, tlang.value_to_tlang(value))
end

local function statepeek_type(state, t)
    local tos = tlang.peek_raw(state)

    if tos.type == t then
        return tos
    else
        return nil -- ERROR
    end
end

local function statepop_type(state, t)
    local tos = tlang.peek_raw(state)

    if tos.type == t then
        return tlang.pop_raw(state)
    else
        return nil -- ERROR
    end
end

local function statepop_num(state)
    return statepop_type(state, "number")
end

local function statepush_num(state, number)
    tlang.push_raw(state, {type = "number", value = number})
end



tlang.builtins = {}

function tlang.builtins.run(state)
    tlang.call_tos(state)
end

tlang.builtins["="] = function(state)
    local name = statepop_type(state, "quote")
    local value = tlang.pop_raw(state)

    tlang.near_assign(state, name.value, value)
end

function tlang.unary(func)
    return function(state)
        local tos = tlang.pop_raw(state)
        if tos.type == "number" then
            statepush_num(state, func(tos.value))
        elseif tos.type == "quote" then
            local n = tlang.near_access(state, tos.value)
            tlang.near_assign(state, tos.value, {type = "number", value = func(n.value)})
        end
    end
end

function tlang.binary(func)
    return function(state)
        local tos = statepop_num(state)
        local tos1 = statepop_num(state)

        statepush_num(state, func(tos.value, tos1.value))
    end
end

local function boolnum(b)
    if b then
        return 1
    else
        return 0
    end
end

local function numbool(n)
    if n ~= 0 then
        return true
    else
        return false
    end
end

tlang.builtins["--"] = tlang.unary(function(v)
    return v - 1
end)

tlang.builtins["++"] = tlang.unary(function(v)
    return v + 1
end)

tlang.builtins["!"] = tlang.unary(function(v)
    return boolnum(not numbool(v))
end)

tlang.builtins["+"] = tlang.binary(function(v1, v2)
    return v1 + v2
end)

tlang.builtins["-"] = tlang.binary(function(v1, v2)
    return v1 - v2
end)

tlang.builtins["*"] = tlang.binary(function(v1, v2)
    return v1 * v2
end)

tlang.builtins["/"] = tlang.binary(function(v1, v2)
    return v1 / v2
end)

tlang.builtins["%"] = tlang.binary(function(v1, v2)
    return v1 % v2
end)

tlang.builtins["=="] = tlang.binary(function(v1, v2)
    return boolnum(v1 == v2)
end)

tlang.builtins["!="] = tlang.binary(function(v1, v2)
    return boolnum(v1 ~= v2)
end)

tlang.builtins["if"] = function(state)
    local tos = statepop_type(state, "code")
    local tos1 = tlang.pop_raw(state)

    if tos1.type == "number" then
        if tos1.value ~= 0 then
            tlang.push_raw(state, tos)
            tlang.call_tos(state)
        end
    end
end

function tlang.builtins.print(state)
    local value = tlang.pop_raw(state)

    if minetest then
        local message = "[tlang] " .. tostring(value.value)
        minetest.display_chat_message(message)
        minetest.log("info", message)
    else
        print(value.value)
    end
end

function tlang.builtins.dup(state)
    tlang.push_raw(state, tlang.peek_raw(state))
end

function tlang.builtins.popoff(state)
    state.stack[#state.stack] = nil
end

function tlang.builtins.wait(state)
    local tos = statepop_type(state, "number")
    state.wait_target = os.clock() + tos.value
end

tlang.builtins["forever"] = function(state)
    local slen = #state.locals

    if state.locals[slen].broke == true then
        state.locals[slen].broke = nil
        state.locals[slen].loop_code = nil

        return
    end

    if state.locals[slen].loop_code == nil then
        local tos = statepop_type(state, "code")

        state.locals[slen].loop_code = tos
    end

    tlang.push_raw(state, state.locals[slen].loop_code)

    tlang.set_next_pc(state, state.current_pc)

    tlang.call_tos(state)
end

tlang.builtins["while"] = function(state)
    local slen = #state.locals

    if state.locals[slen].broke == true then
        state.locals[slen].broke = nil
        state.locals[slen].loop_code = nil
        state.locals[slen].test_code = nil
        state.locals[slen].loop_stage = nil

        return
    end

    if state.locals[slen].loop_code == nil then
        local while_block = statepop_type(state, "code")
        local test_block = statepop_type(state, "code")

        state.locals[slen].test_code = test_block
        state.locals[slen].loop_code = while_block
        state.locals[slen].loop_stage = 0
    end

    -- stage 0, run test
    if state.locals[slen].loop_stage == 0 then
        tlang.push_raw(state, state.locals[slen].test_code)
        tlang.set_next_pc(state, state.current_pc)
        tlang.call_tos(state)

        state.locals[slen].loop_stage = 1
    -- stage 1, run while
    elseif state.locals[slen].loop_stage == 1 then
        local tos = tlang.pop_raw(state)
        if tos and tos.value ~= 0 then
            tlang.push_raw(state, state.locals[slen].loop_code)
            tlang.set_next_pc(state, state.current_pc)
            tlang.call_tos(state)
        else
            tlang.set_next_pc(state, state.current_pc)
            state.locals[slen].broke = true
        end

        state.locals[slen].loop_stage = 0
    end
end

tlang.builtins["repeat"] = function(state)
    local slen = #state.locals

    if state.locals[slen].broke == true then
        state.locals[slen].broke = nil
        state.locals[slen].loop_code = nil
        state.locals[slen].repeat_count = nil
        state.locals[slen].repeat_n = nil
        state.locals[slen].loop_var = nil

        return
    end

    if state.locals[slen].loop_code == nil then
        local num_var = tlang.pop_raw(state)
        local count
        local block

        if num_var.type == "quote" then
            count = statepop_num(state)
            state.locals[slen].loop_var = num_var.value
        else
            count = num_var
        end

        block = statepop_type(state, "code")

        state.locals[slen].loop_code = block
        state.locals[slen].repeat_count = count.value
        state.locals[slen].repeat_n = 0
    end

    if state.locals[slen].repeat_n ~= state.locals[slen].repeat_count then
        if state.locals[slen].loop_var then
            tlang.local_assign(state,
                state.locals[slen].loop_var,
                {type = "number", value = state.locals[slen].repeat_n})
        end

        tlang.push_raw(state, state.locals[slen].loop_code)

        tlang.set_next_pc(state, state.current_pc)

        tlang.call_tos(state)

        state.locals[slen].repeat_n = state.locals[slen].repeat_n + 1
    else
        tlang.set_next_pc(state, state.current_pc)
        state.locals[slen].broke = true
    end
end

tlang.builtins["break"] = function(state)
    local slen = #state.locals
    local pos = 0
    local found = false

    -- find highest loop_code
    -- slen - i to perform basically bitwise inverse
    -- it allows it to count down the list effectively
    for i = 1, slen do
        if state.locals[slen + 1 - i].loop_code then
            pos = slen + 1 - i
            found = true
        end
    end

    if found then
        -- pop the top layers
        for i = pos + 1, #state.locals do
            state.locals[i] = nil
        end

        -- break in the lower layer
        state.locals[#state.locals].broke = true
    end
end

tlang.builtins["return"] = function(state)
    state.locals[#state.locals] = nil
end

tlang.builtins["args"] = function(state)
    local vars = {}
    local vari = 1

    while true do
        local n = tlang.pop_raw(state)
        if n.type == "quote" then
            vars[vari] = n.value
            vari = vari + 1
        elseif n.type == "number" and n.value == 0 then
            break
        else
            return false
        end
    end

    for i, v in ipairs(vars) do
        tlang.local_assign(state, v, tlang.pop_raw(state))
    end
end


-- returns:
-- true - more to do
-- nil - more to do but waiting
-- false - finished
-- string - error
function tlang.step(state)
    if state.wait_target and os.clock() < state.wait_target then
        return nil
    end

    local cur = getnext(state)

    if cur == nil then
        return false
    elseif in_list(cur.type, literals) then
        state.stack[#state.stack + 1] = cur
    elseif cur.type == "identifier" or cur.type == "symbol" then
        if in_keys(cur.value, state.builtins) then
            local f = state.builtins[cur.value]
            f(state)
        else
            local var = tlang.near_access(state, cur.value)
            if var == nil then
                return "Undefined identifier: " .. cur.value
            elseif var.type == "code" then
                tlang.call(state, {sg = 1, pos = cur.value, elem = 1})
            else
                state.stack[#state.stack + 1] = var
            end
        end
    end

    return true
end

return tlang
