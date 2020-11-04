
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

local literals = {
    "quote",
    "code",
    "map",
    "string",
    "number"
}


local function call(state, target)
    if target.sg == 0 then
        state.code_stack[#state.code_stack + 1] = state.stack[target.pos]
        table.remove(state.stack, target.pos)
        target.pos = #state.code_stack
    end

    state.locals[#state.locals + 1] = {pc = target}
end

local function access(state, name)
    name = "v" .. name
    local slen = #state.locals

    for i = 1, slen do
        local v = state.locals[slen + 1 - i]
        if in_keys(name, v) then
            return v[name]
        end
    end
end

local function gassign(state, name, value)
    state.locals[0]["v" .. name] = value
end

local function assign(state, name, value)
    state.locals[#state.locals]["v" .. name] = value
end

local function getpc(state)
    return state.locals[#state.locals].pc
end

local function accesspc(state, pc)
    local code
    if pc.sg == 0 then -- stack
        code = state.code_stack[pc.pos]
    elseif pc.sg == 1 then -- global
        code = access(state, pc.pos)
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
        state.locals[#state.locals] = nil
        if #state.locals == 0 then
            return nil
        end

        -- pop code stack
        local pc = getpc(state)
        if pc.sg == 0 then
            state.code_stack[pc.pos] = nil
        end
    end

    state.current_pc = getpc(state)
    local current = accesspc(state, state.current_pc)

    local incd = incpc(state, getpc(state))
    state.locals[#state.locals].pc = incd
    if not incd then
        state.locals[#state.locals].nextpop = true
    end

    return current
end


local function statepeek(state)
    return state.stack[#state.stack]
end

local function statepop(state)
    local tos = statepeek(state)
    state.stack[#state.stack] = nil
    return tos
end

local function statepeek_type(state, t)
    local tos = statepeek(state)

    if tos.type == t then
        return tos
    else
        return nil -- ERROR
    end
end

local function statepop_type(state, t)
    local tos = statepeek(state)

    if tos.type == t then
        return statepop(state)
    else
        return nil -- ERROR
    end
end

local function statepop_num(state)
    return statepop_type(state, "number")
end

local function statepush(state, value)
    state.stack[#state.stack + 1] = value
end

local function statepush_num(state, number)
    statepush(state, {type = "number", value = number})
end



local builtins = {}

function builtins.run(state)
    call(state, {sg = 0, pos = #state.stack, elem = 1})
end

builtins["="] = function(state)
    local name = statepop_type(state, "quote")
    local value = statepop(state)

    assign(state, name.value, value)
end

builtins["--"] = function(state)
    local tos = statepop_num(state)
    statepush_num(state, tos.value - 1)
end

builtins["++"] = function(state)
    local tos = statepop_num(state)
    statepush_num(state, tos.value + 1)
end

builtins["*"] = function(state)
    local tos = statepop_num(state)
    local tos1 = statepop_num(state)

    statepush_num(state, tos.value * tos1.value)
end

local function boolnum(b)
    if b then
        return 1
    else
        return 0
    end
end

builtins["=="] = function(state)
    local tos = statepop_num(state)
    local tos1 = statepop_num(state)

    statepush_num(state, boolnum(tos.value == tos1.value))
end

builtins["!="] = function(state)
    local tos = statepop_num(state)
    local tos1 = statepop_num(state)

    statepush_num(state, boolnum(tos.value ~= tos1.value))
end

builtins["if"] = function(state)
    local tos = statepop_type(state, "code")
    local tos1 = statepop(state)

    if tos1.type == "number" then
        if tos1.value ~= 0 then
            statepush(state, tos)
            call(state, {sg = 0, pos = #state.stack, elem = 1})
        end
    end
end

function builtins.print(state)
    local value = statepop(state)

    print(value.value)
end

function builtins.dup(state)
    statepush(state, statepeek(state))
end

function builtins.popoff(state)
    state.stack[#state.stack] = nil
end

function builtins.wait(state)
    local tos = statepop_type(state, "number")
    state.wait_target = os.clock() + tos.value
end

builtins["forever"] = function(state)
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

    statepush(state, state.locals[slen].loop_code)

    state.locals[slen].pc = state.current_pc

    call(state, {sg = 0, pos = #state.stack, elem = 1})
end

builtins["while"] = function(state)
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
        statepush(state, state.locals[slen].test_code)
        state.locals[slen].pc = state.current_pc
        call(state, {sg = 0, pos = #state.stack, elem = 1})

        state.locals[slen].loop_stage = 1
    -- stage 1, run while
    elseif state.locals[slen].loop_stage == 1 then
        local tos = statepop(state)
        if tos and tos.value ~= 0 then
            statepush(state, state.locals[slen].loop_code)
            state.locals[slen].pc = state.current_pc
            call(state, {sg = 0, pos = #state.stack, elem = 1})
        else
            state.locals[slen].pc = state.current_pc
            state.locals[slen].broke = true
        end

        state.locals[slen].loop_stage = 0
    end
end

builtins["break"] = function(state)
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

builtins["return"] = function(state)
    state.locals[#state.locals] = nil
end


-- returns:
-- true - more to do
-- nil - more to do but waiting
-- false - finished
-- string - error
local step = function(state)
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
            local var = access(state, cur.value)
            if var == nil then
                return "Undefined identifier: " .. cur.value
            elseif var.type == "code" then
                call(state, {sg = 1, pos = cur.value, elem = 1})
            else
                state.stack[#state.stack + 1] = var
            end
        end
    end

    return true
end

return builtins, gassign, step
