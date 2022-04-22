local noteVal = 2 ^ (1/12)

--- Get the relative pitch value of a note.
local function pitch(note)
    return noteVal
end

--- Return the interval between steps.
local function interval(bpm)
    return 1 / (bpm / 15)
end

local function slice(tbl, first, last, step)
    local sliced = {}
  
    for i = first or 1, last or #tbl, step or 1 do
        sliced[#sliced+1] = tbl[i]
    end
  
    return sliced
end

local function printTable(tbl, delim)
    if not (type(tbl) == "table") then return end

    local outstr = ''
    local d = delim or ' '

    for k,v in pairs(tbl) do
        if not (type(v) == "table" or type(v) == "number") then
            local vv = v or "nil"
            if (type(vv) == "string") then
                outstr = outstr .. k .. ':' .. vv .. '\n'
            else
                print(vv)
            end
        end
    end

    for i,el in ipairs(tbl) do
        if not (type(el) == "table") then
            outstr = outstr .. el
            if tbl[i + 1] then outstr = outstr .. d end
        end
    end

    print(outstr)
end

local function bytesToString(bytes)
    local outstr = ''

    for i,b in ipairs(bytes) do
        outstr = outstr .. string.char(b)
    end

    return outstr
end

--- Unpack a string and return what's left (if anything).
local function unpackRest(fmt, str)
    local t = {love.data.unpack(fmt, str)}
    local lastc = table.remove(t, #t)
    return t, string.sub(str, lastc)
end

return {
    pitch = pitch,
    interval = interval,
    slice = slice,
    printTable = printTable,
    bytesToString = bytesToString,
    unpackRest = unpackRest
}
