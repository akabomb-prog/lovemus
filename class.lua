--- Create a class with a constructor.
--- Returns: class metatable, constructor function
local function class(constr)
    local t = {}
    t.__index = t
    if constr then
        local _constr = constr
        function constr(...)
            local a = setmetatable({}, t)
            _constr(a, ...)
            return a
        end
    else
        function constr(...)
            return setmetatable({}, t)
        end
    end
    return t, constr
end
return class
