
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
        tree = {}
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
    state.locals[#state.locals + 1] = {pc = target}
end

local function access(state, name)
    name = "v" .. name
    for i, v in ipairs(state.locals) do
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
        code = state.stack[pc.pos]
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
    if state.nextpop then
        state.locals[#state.locals] = nil
        if #state.locals == 0 then
            return nil
        end
        state.nextpop = false
    end

    local current = accesspc(state, getpc(state))

    local incd = incpc(state, getpc(state))
    state.locals[#state.locals].pc = incd
    if not incd then
        state.nextpop = true
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

local function statepop_type(state, t)
    local tos = statepeek(state)

    if tos.type == t then
        return statepop(state)
    else
        return nil -- ERROR
    end
end

local function statepush(state, value)
    state.stack[#state.stack + 1] = value
end



local builtins = {}

builtins["="] = function(state)
    local name = statepop_type(state, "quote")
    local value = statepop(state)

    assign(state, name.value, value)
end

builtins["*"] = function(state)
    local tos = statepop_type(state, "number")
    local tos1 = statepop_type(state, "number")

    statepush(state, {type = "number", value = tos.value * tos.value})
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
