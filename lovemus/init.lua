local LoveInstrument_Meta, LoveInstrument = require "lovemus.love_instrument"
local LoveKit_Meta, LoveKit = require "lovemus.love_kit"
local LoveFile_Meta, LoveFile = require "lovemus.love_file"
local IOFile_Meta, IOFile = require "lovemus.io_file"
local Song_Meta, Song = require "lovemus.song"

return {
    LoveInstrument = LoveInstrument,
    LoveKit = LoveKit,
    LoveFile = LoveFile,
    IOFile = IOFile,
    Song = Song
}
