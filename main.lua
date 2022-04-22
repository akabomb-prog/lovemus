lovemus = require "lovemus.init"

function love.load()
    local thingamajig = lovemus.IOFile("thingamajig.mus")
    mySong = lovemus.Song(thingamajig)
    mySong:load()
end
