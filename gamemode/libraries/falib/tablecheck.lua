--[[
tablecheck

Author: FPtje Falco

Purpose:
Allow validating tables by creating schemas of tables. Inspired by Joi (https://github.com/hapijs/joi)

Requires fn library (https://github.com/FPtje/GModFunctional)
--]]

module("tc", package.seeall)

-- Helpers for quick access to metatables
angle                  = FindMetaTable("Angle")
convar                 = FindMetaTable("ConVar")
effectdata             = FindMetaTable("CEffectData")
entity                 = FindMetaTable("Entity")
file                   = FindMetaTable("File")
imaterial              = FindMetaTable("IMaterial")
irestore               = FindMetaTable("IRestore")
isave                  = FindMetaTable("ISave")
itexture               = FindMetaTable("ITexture")
lualocomotion          = FindMetaTable("CLuaLocomotion")
movedata               = FindMetaTable("CMoveData")
navarea                = FindMetaTable("CNavArea")
navladder              = FindMetaTable("CNavLadder")
nextbot                = FindMetaTable("NextBot")
npc                    = FindMetaTable("NPC")
pathfollower           = FindMetaTable("PathFollower")
physobj                = FindMetaTable("PhysObj")
player                 = FindMetaTable("Player")
recipientfilter        = FindMetaTable("CRecipientFilter")
soundpatch             = FindMetaTable("CSoundPatch")
takedamageinfo         = FindMetaTable("CTakeDamageInfo")
usercmd                = FindMetaTable("CUserCmd")
vector                 = FindMetaTable("Vector")
vehicle                = FindMetaTable("Vehicle")
vmatrix                = FindMetaTable("VMatrix")
weapon                 = FindMetaTable("Weapon")

-- Assert function, asserts a property and returns the error if false.
-- Allows f to override err and hints by simply returning them
addHint = function(f, err, hints) return function(...)
    local res = {f(...)}
    res[2] = err
    res[3] = hints

    return unpack(res)
end end

--[[ Validates a table against a schema
Capable of nesting
--]]
function checkTable(schema)
    return function(tbl)
        if not istable(tbl) then
            return false, "Not a table!"
        end

        for k, v in pairs(schema or {}) do
            local correct, err, hints = tbl[v] ~= nil
            if isfunction(v) then correct, err, hints, replace, replaceWith = v(tbl[k], tbl) end


            if not correct then
                err = err or string.format("Element '%s' is corrupt!", k)
                return correct, err, hints
            end

            -- Update the value
            if correct and replace == true and replaceWith then
                tbl[k] = replaceWith
            end
        end

        return true
    end
end

-- Returns whether a value is nil
isnil = fn.Curry(fn.Eq, 2)(nil)

-- Returns whether a value is a color
iscolor = IsColor

-- Returns true on the client
client = function() return CLIENT end

-- returns true on the server
server = function() return SERVER end

-- Optional value, when filled in it must meet the conditions
optional = function(...) return fn.FOr{isnil, ...} end

-- Default value, implies optional. Only works in combination with tc.checkTable
-- Note that the tc.addHint is to be the second parameter of default.
--      tc.addHint(tc.default(x)) does NOT work, default(x, tc.addHint(...)) does.
-- example: tc.checkTable{test = tc.default(3, tc.addHint(isnumber, "must be a number"))}
-- example: tc.checkTable{test = tc.default(3)}
default = function(def, f)
    return function(val, ...)
        if val == nil then
            -- second return value is the default value. Expects parent function to actually change the value
            return true, nil, nil, true, def
        end
        -- Return in if statement rather than "return f and f(val) or true" to allow multiple return values
        if f then return f(val, ...) else return true end
    end
end

-- A table of which each element must meet condition f
-- i.e. "this must be a table of xxx"
-- example: tc.tableOf(isnumber) demands that the table contains only numbers
tableOf = function(f) return function(tbl, parentTbl)
    if not istable(tbl) then return false end
    for _, v in pairs(tbl) do
        local res = {f(v, parentTbl)}
        if not res[1] then
            return unpack(res)
        end
    end

    return true
end end

-- Checks whether a value is amongst a given set of values
-- exapmle: tc.oneOf{"jobs", "entities", "shipments", "weapons", "vehicles", "ammo"}
oneOf = function(f) return fp{table.HasValue, f} end

-- A table that is non-empty, also useful for wrapping around tableOf
-- example: tc.nonEmpty(tc.tableOf(isnumber))
-- example: tc.nonEmpty() -- just checks that the table is non-empty
nonEmpty = function(f) return function(tbl, parentTbl)
    if not istable(tbl) or table.IsEmpty(tbl) then return false end
    if not f then return true end
    return f(tbl, parentTbl)
end end

-- Number check: minimum
min = function(n) return fn.FAnd{isnumber, fp{fn.Lte, n}} end

-- Number check: maximum
max = function(n) return fn.FAnd{isnumber, fp{fn.Gte, n}} end

-- Number check: positive
positive = min(0)

-- Number check: negative
negative = max(0)


-- Whether the input matches regex
-- Note: uses string.match, so it doesn't support full regex.
-- May also allow numbers, since string.match also accepts numbers.
-- Note, also matches on substrings. Use ^pattern$ for a full match.
regex = function(pattern, startpos) return function(val)
    return (isstring(val) or isnumber(val)) and tobool(string.match(val, pattern, startpos))
end end

-- Requires that the value only contains alphanumeric characters
alphanum = regex("^[a-zA-Z0-9]+$")
