--- LoveInstrument implementation

-- require class constructor
local class = require "class"

-- require util library
local util = require "lovemus.util"

-- get what we need as locals
local pitch = util.pitch

local LoveInstrument_Meta, LoveInstrument = class(function (self, source)
    self.source = source
end)

LoveInstrument_Meta.transposition = 0

--- Play a note on the Instrument.
function LoveInstrument_Meta:play(note)
    self.source:setPitch(pitch(note + self.transposition - 53))
    self.source:stop()
    self.source:play()
end

--- Pan the Instrument (if it's mono).
function LoveInstrument_Meta:pan(amount)
    self.source:setPosition(amount, 1, 0)
end

--- Set the Instrument's volume.
function LoveInstrument_Meta:vol(amount)
    self.source:setVolume(amount)
end

--- Transpose the Instrument.
function LoveInstrument_Meta:transpose(newTransposition)
    self.transposition = newTransposition
end

-- return meta and constructor
return LoveInstrument_Meta, LoveInstrument
