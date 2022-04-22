lovemusic = {}

local note_val = 2 ^ (1/12)
function lovemusic.getPitch(note)
    return note_val ^ note
end

function lovemusic.bpmToTimer(bpm)
    return 1 / (bpm / 15)
end

local function copy(t)
    local u = { }
    for k, v in pairs(t) do u[k] = v end
    return setmetatable(u, getmetatable(t))
end

LoveInstrument = {}
LoveInstrument._index = LoveInstrument

function LoveInstrument:new(source)
    local obj = copy(LoveInstrument)
    setmetatable(obj, LoveInstrument)

    obj.source = source

    obj.transposition = 0

    return obj
end

function LoveInstrument:play(note)
    self.source:setPitch(lovemusic.getPitch(note + self.transposition - 53))
    self.source:stop()
    self.source:play()
end

function LoveInstrument:pan(amount)
    self.source:setPosition(amount, 1, 0)
end

function LoveInstrument:vol(amount)
    self.source:setVolume(amount)
end

function LoveInstrument:transpose(newTransposition)
    self.transposition = newTransposition
end

lovemusic.LoveInstrument = LoveInstrument

LoveKit = {}
LoveKit._index = LoveKit

function LoveKit:new(sources)
    local obj = copy(LoveKit)
    setmetatable(obj, LoveKit)

    obj.sources = sources

    return obj
end

function LoveKit:play(note)
    local source = self.sources[note + 1]
    if not source then return end
    source:stop()
    source:play()
end

lovemusic.LoveKit = LoveKit

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

Song = {}
Song._index = Song

function Song:new(file)
    local obj = copy(Song)
    setmetatable(obj, Song)

    -- song
    obj.songPosition = 1
    obj.songLength = 1
    obj.doRepeat = true

    -- file contents
    local contents, size = file:read()
    if not contents then
        obj.isValid = false
    else
        obj.data = { string.byte(contents, 1, -1) }
        obj.isValid = true
    end
    obj.file = file
    obj.size = size
    obj.seekPosition = 1

    -- loaded song data
    obj.authorInfo = {
        title = "[unknown]",
        author = "[unknown]"
    }
    obj.dataInfo = {
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
    obj.songData = {
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

    return obj
end

function Song:readBytes(size)
    local sliced = slice(self.data, self.seekPosition, self.seekPosition + size - 1)
    self.seekPosition = self.seekPosition + size
    return sliced
end

function Song:readByte()
    local byte = self.data[self.seekPosition]
    self.seekPosition = self.seekPosition + 1
    return byte
end

function Song:peekByte(next)
    local pos = self.seekPosition + (next or 0)
    local byte = self.data[pos]
    return byte
end

function Song:readString()
    local i = 0
    local outstr = ''

    while not (self.data[self.seekPosition + i] == 0) do
        local char = string.char(self.data[self.seekPosition + i])
        outstr = outstr .. char
        i = i + 1
    end

    self.seekPosition = self.seekPosition + i + 1

    return outstr
end

function Song:readBFloat()
    -- read byte-float (centered byte)
    local byte = self:readByte()
    if byte > 128 then
        return (byte - 128) / 127
    elseif byte < 128 then
        return ((byte - 1) / 127) - 1
    else
        return 0 
    end
end

function Song:valid()
    return self.isValid
end

function Song:load()
    if not self:valid() then
        error("This song object is invalid.")
        return
    end

    local lovemus = bytesToString(self:readBytes(7))
    local lovemus2 = self:readByte()
    if not (lovemus == "LOVEMUS" and lovemus2 == 127) then
        error("File " .. self.file:name() .. " is not a LOVEMUS music tracker file.")
        return
    end

    local currentSection = 1

    while (currentSection <= 3) do
        local header = self:readBytes(2)
        local section = header[2]

        if section == 1 then
            -- author info
            while not (self:peekByte() == 255) do
                -- is not a section
                local which = self:readByte()
                if which == 1 then
                    self.authorInfo.title = self:readString()
                elseif which == 2 then
                    self.authorInfo.author = self:readString()
                end
            end
        elseif section == 2 then
            -- data info
            local totalInstruments = 0
            while not (self:peekByte() == 255) do
                -- is not a section
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
                    local currentInstrument = which - 4
                    self.dataInfo.instruments[currentInstrument] = {}
                    self.songData[currentInstrument] = {} -- initialize pattern list for instrument

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
            self.dataInfo.instruments[0] = totalInstruments
        elseif section == 3 then
            -- data

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

    self.file:close()

    -- song loaded
    self:onLoad()
end

function Song:onLoad()
    print("Song " .. self.file:getFilename() .. " loaded!")
end

function Song:save(file)
    -- save song to lovemusic.File object
end

function Song:progress()
    local pattern = math.floor((self.songPosition - 1) / self.dataInfo.patternLength) + 1
    local pos = ((self.songPosition - 1) % self.dataInfo.patternLength) + 1
    for i,inst in ipairs(self.dataInfo.instruments) do
        local noteData = self.songData[i][pattern][pos]
        local note = noteData[1]
        local velocity = noteData[2] / 255
        local volume = inst.volume
        local fine = self.dataInfo.globalFine
        if not (velocity == 0) then
            inst:vol(volume * velocity)
            inst:play(note + fine)
        end
    end
    self.songPosition = self.songPosition + 1
    if (self.songPosition == self.songLength) then self.songPosition = 1 end
end

lovemusic.Song = Song

LoveFile = {}
LoveFile._index = LoveFile

function LoveFile:new(fObject)
    local obj = copy(LoveFile)
    setmetatable(obj, LoveFile)

    obj.fObject = fObject

    return obj
end

function LoveFile:read()
    return self.fObject:read('data'):getString()
end

function LoveFile:name()
    return self.fObject:getFilename()
end

function LoveFile:close()
    self.fObject:close()
end

lovemusic.LoveFile = LoveFile

IOFile = {}
IOFile._index = IOFile

function IOFile:new(filename)
    local obj = copy(IOFile)
    setmetatable(obj, IOFile)

    obj.filename = filename
    obj.fObject = io.open(filename, 'r')

    return obj
end

function IOFile:read()
    if not self.fObject then return end

    self.fObject:seek('set')
    return self.fObject:read('*a')
end

function IOFile:name()
    return self.filename
end

function IOFile:close()
    self.fObject:close()
end

lovemusic.IOFile = IOFile

return lovemusic