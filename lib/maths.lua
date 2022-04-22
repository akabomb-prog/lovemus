maths = {}

function maths.round(n, places)
    local p = 1
    if places then p = places end
    tens = 10 ^ p
    return math.floor(n * tens + 0.500000000000001) / tens
end

return maths