--- IOFile implementation (wrapper for files)

-- require class constructor
local class = require "class"

local IOFile_Meta, IOFile = class(function (self, filename)
    self.filename = filename
    self.fObject = io.open(filename, 'r')
end)

--- Read the file's data.
function IOFile_Meta:read()
    if not self.fObject then return end 
    self.fObject:seek('set')
    return self.fObject:read('*a')
end

--- Return the file's name.
function IOFile_Meta:name()
    return self.filename
end

--- Close the file.
function IOFile_Meta:close()
    return self.fObject:close()
end

-- return meta and constructor
return { IOFile_Meta, IOFile }
