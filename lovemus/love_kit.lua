--- LoveKit implementation

-- require class constructor
local class = require "class"

local LoveKit_Meta, LoveKit = class(function (self, files)
    self.sources = {}
    for i,f in ipairs(files) do
        table.insert(self.sources, love.audio.newSource(f, "static"))
    end
end)

function LoveKit_Meta:play(note)
    local source = self.sources[note + 1]
    if not source then return end
    source:stop()
    source:play()
end

-- return meta and constructor
return { LoveKit_Meta, LoveKit }
