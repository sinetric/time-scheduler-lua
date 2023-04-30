local ts = require(game.ReplicatedStorage.ModuleScript)
local newTime = ts.new()

newTime:catch(warn)

newTime:SetMarker("Marker1", "Category")

local _wait = newTime:Wait(2)

_wait:Start()

print(newTime:GetMarker("Marker1").TimeSince)
