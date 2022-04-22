--- LoveFile implementation (wrapper for files)

-- require class constructor
local class = require "class"

local LoveFile_Meta, LoveFile = class(function (self, fObject)
    self.fObject = fObject
end)

--- Read the file's data.
function LoveFile_Meta:read()
    return self.fObject:read("string")
end

--- Return the file's name.
function LoveFile_Meta:name()
    return self.fObject:getFilename()
end

--- Close the file.
function LoveFile_Meta:close()
    return self.fObject:close()
end

-- return meta and constructor
return { LoveFile_Meta, LoveFile }
