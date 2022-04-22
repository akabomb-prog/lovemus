-- A simple timing module for Lua.
timing = {}

Timer = {}
Timer._index = Timer

function copy(t)
    local u = { }
    for k, v in pairs(t) do u[k] = v end
    return setmetatable(u, getmetatable(t))
  end

function Timer:new(interval, measurer, times)
    local obj = copy(Timer)
    setmetatable(obj, Timer)

    obj.interval = interval
    obj.measurer = measurer
    obj.times = times or -1

    obj.enabled = true
    obj.lastTrigger = obj.measurer()

    return obj
end

function Timer:tick()
    if not self.enabled or self.times == 0 then return end

    local now = self.measurer()
    local delta = now - self.lastTrigger
    local idealOffset = delta - self.interval
    if (delta >= self.interval) then
        self:tock(delta)
        self.lastTrigger = now - idealOffset
        self.times = self.times - 1
    end
end

function Timer:since()
    return self.measurer() - self.lastTrigger
end

function Timer:delay(amount)
    self.lastTrigger = self.lastTrigger + amount
end

function Timer:tock(delta)
    print("Timer tock! Delta: " .. delta)
end

timing.Timer = Timer

timing.gTimers = {}
timing.add = function (id, interval, measurer, times)
    if timing.gTimers[id] then return end
    timing.gTimers[id] = timing.Timer:new(interval, measurer, times)
    return timing.gTimers[id]
end
timing.remove = function (id)
    if not timing.gTimers[id] then return end
    timing.gTimers[id] = nil
end
timing.tickAll = function ()
    for k,v in pairs(timing.gTimers) do
        v:tick()
    end
end

return timing