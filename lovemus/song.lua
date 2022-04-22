--- Song implementation

-- require class constructor
local class = require "class"

-- require util library
local util = require "lovemus.util"

-- get what we need as locals
local byte, rep = string.byte, string.rep
local t_unpack = unpack
local unpack = love.data.unpack
local unpackRest, slice = util.unpackRest, util.slice

local Song_Meta, Song = class(function (self, file)
    -- read file
    local contents, size = file:read()
    if contents then
        self._data = contents
        self.data = contents
        self.isValid = true
    end
    self.file = file
    self.size = size
end)

-- default playback information
Song_Meta.songPosition = 1
Song_Meta.songLength = 1
Song_Meta.doRepeat = true

-- default (placeholder) song data
Song_Meta.authorInfo = {
    title = "[unknown]",
    author = "[unknown]"
}
Song_Meta.dataInfo = {
    sampleCount = 1,
    patternLength = 8,
    bpm = 120,

    instruments = {
    {
        sampleName = "music/samples/default.wav",
        transposition = 0,
        volume = 0.5
    }
    }
}
Song_Meta.songData = {
    {
        -- instrument 0
        {
            -- pattern 0
            72, 255, 128,
            72, 255, 128,
            72, 255, 128,
            72, 255, 128,
            72, 255, 128,
            72, 255, 128,
            72, 255, 128,
            72, 255, 128
        }
    }
}

-- other default variables
Song_Meta.isValid = false

--- Read a specified amount of bytes from the data.
function Song_Meta:readBytes(size)
    if #self.data == 0 then return end
    local t, rest = unpackRest(rep('B', size), self.data)
    self.data = rest
    return t
end

--- Read a C string.
function Song_Meta:readCString(size)
    if #self.data == 0 then return end
    local t, rest = unpackRest('c' .. size, self.data)
    self.data = rest
    return t[1]
end

--- Read a single byte from the data.
function Song_Meta:readByte()
    if #self.data == 0 then return end
    local t, rest = unpackRest('B', self.data)
    self.data = rest
    return t[1]
end

--- Peek a single byte.
function Song_Meta:peekByte(next)
    if #self.data == 0 then return end
    next = next or 1
    return byte(self.data:sub(next, next))
end

--- Read a zero-terminated string.
function Song_Meta:readString()
    if #self.data == 0 then return end
    local t, rest = unpackRest('z', self.data)
    self.data = rest
    return t[1]
end

--- Read byte-float (centered byte)
function Song_Meta:readBFloat()
    if #self.data == 0 then return end
    local byte = self:readByte()
    if byte > 128 then
        return (byte - 128) / 127
    elseif byte < 128 then
        return ((byte - 1) / 127) - 1
    else
        return 0 
    end
end

--- Return if the Song is valid.
function Song_Meta:valid() return self.isValid end

--- Process the file data.
function Song_Meta:load()
    if not self:valid() then
        error("couldn't load song as it is invalid!")
        return
    end

    -- check header
    local LOVEMUS = self:readCString(7)
    local LOVEMUS2 = self:readByte()
    if not (LOVEMUS == "LOVEMUS" and LOVEMUS2 == 127) then
        error("file " .. self.file:name() .. " is not a LOVEMUS music tracker file!")
        return
    end

    -- read sections
    local currentSection = 1

    -- there are 3 sections:
    -- author info
    -- data info
    -- data
    while currentSection <= 3 do
        -- get section header
        local header = self:readBytes(2)
        local section = header[2]

        if section == 1 then
            -- author info section

            while self:peekByte() ~= 255 do
                -- while we're not on course to another section

                -- get title and author
                local which = self:readByte()

                if which == 1 then
                    self.authorInfo.title = self:readString()
                elseif which == 2 then
                    self.authorInfo.author = self:readString()
                end
                love.timer.sleep(1)
            end
        elseif section == 2 then
            -- data info section
            local totalInstruments = 0

            while self:peekByte() ~= 255 do
                -- get which variable we're getting:
                -- 1. sample count
                -- 2. pattern length
                -- 3. bpm
                -- 4. global fine tuning
                -- everything after that: instruments array
                local which = self:readByte()

                if which == 1 then
                    self.dataInfo.sampleCount = self:readByte()
                elseif which == 2 then
                    self.dataInfo.patternLength = self:readByte()
                elseif which == 3 then
                    self.dataInfo.bpm = self:readByte()
                elseif which == 4 then
                    self.dataInfo.globalFine = self:readBFloat()
                else
                    -- instruments array
                    local currentInstrument = which - 4 -- instruments are 1-indexed
                    self.dataInfo.instruments[currentInstrument] = {} 
                    self.songData[currentInstrument] = {} -- initialize pattern list for instrument

                    -- increment instrument counter
                    totalInstruments = totalInstruments + 1
                    
                    while self:peekByte() > 128 and not (self:peekByte() == 255) do
                        local which2 = self:readByte()
                        if which2 == 129 then
                            -- sample name
                            local sample = self:readString()
                            self.dataInfo.instruments[currentInstrument].sampleName = sample
                        elseif which2 == 130 then
                            -- transposition
                            local transposition = self:readByte() - 128
                            self.dataInfo.instruments[currentInstrument].transposition = transposition
                        elseif which2 == 131 then
                            -- volume
                            local volume = self:readByte() / 255
                            self.dataInfo.instruments[currentInstrument].volume = volume
                        end
                    end
                end
            end

            -- set 0th member of instruments to be the total instrument count
            self.dataInfo.instruments[0] = totalInstruments
        elseif section == 3 then
            -- data section

            local i = 1
            while self:peekByte(3 * self.dataInfo.patternLength - 1) do
                -- while not EOF
                for j=1,self.dataInfo.instruments[0] do
                    -- for each instrument
                    self.songData[j][i] = {}
                    for k=1,self.dataInfo.patternLength do
                        -- for each note
                        local note = self:readBytes(3)
                        self.songData[j][i][k] = note
                    end
                end
                i = i + 1
            end
            self.songLength = ((i - 1) * self.dataInfo.patternLength) + 1
        end

        currentSection = currentSection + 1
    end

    -- close file
    self.file:close()

    -- rebuild instruments
    self:rebuildInstruments()

    -- call :loaded()
    if self.loaded then self:loaded() end
end

-- get LoveInstrument
local _, LoveInstrument = t_unpack(require "lovemus.love_instrument")

--- Rebuild LoveInstruments.
function Song_Meta:rebuildInstruments()
    self.instruments = {}
    for i,instInfo in ipairs(self.dataInfo.instruments) do
        local inst = LoveInstrument(instInfo.sampleName)
        inst:transpose(instInfo.transposition)
        inst:vol(instInfo.volume)
        table.insert(self.instruments, inst)
    end
end

--- This function is called when the song is loaded successfully.
function Song_Meta:loaded()
    print("song " .. self.authorInfo.title .. " loaded!")
end

--- Progress the Song.
function Song_Meta:progress()
    -- get the pattern we're currently on
    local pattern = math.floor((self.songPosition - 1) / self.dataInfo.patternLength) + 1

    -- get the position in the pattern
    local pos = ((self.songPosition - 1) % self.dataInfo.patternLength) + 1
    
    -- play instruments
    for i,inst in ipairs(self.dataInfo.instruments) do
        local noteData = self.songData[i][pattern][pos]
        local note = noteData[1]
        local velocity = noteData[2] / 255
        local volume = inst.volume
        local fine = self.dataInfo.globalFine
        if velocity ~= 0 then
            inst:vol(volume * velocity)
            inst:play(note + fine)
        end
    end

    -- increment song counter
    self.songPosition = self.songPosition + 1

    -- repeat if we have to, call :finished()
    if self.songPosition == self.songLength then
        if self.doRepeat then
            self.songPosition = 1
        end
        if self.finished then self:finished(self.songPosition) end
    end
end

-- return meta and constructor
return { Song_Meta, Song }
