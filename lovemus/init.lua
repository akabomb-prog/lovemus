local LoveInstrument_Meta, LoveInstrument = unpack(require "lovemus.love_instrument")
local LoveKit_Meta, LoveKit = unpack(require "lovemus.love_kit")
local LoveFile_Meta, LoveFile = unpack(require "lovemus.love_file")
local IOFile_Meta, IOFile = unpack(require "lovemus.io_file")
local Song_Meta, Song = unpack(require "lovemus.song")

return {
    LoveInstrument = LoveInstrument,
    LoveKit = LoveKit,
    LoveFile = LoveFile,
    IOFile = IOFile,
    Song = Song
}
