local time_scheduler = {}

function time_scheduler.new()
	local self = {
		toss = {
			Event = nil,
			_fireAssert = function(self, errorMessage)
				self.Event(errorMessage)
			end,
		}
	}
	self._assert = function(check, errorMessage)
		if not check then
			self.toss:_fireAssert(errorMessage)
			
			coroutine.yield()
		end
	end
	
	self._lastTick = tick()
	self._setTimes = {}
	self._markers = {}
	
	self._markerCallbacks = {}
	
	self._markerCategories = {}
	
	self.catch = function(self, func)
		self.toss.Event = function(message)
			func(message .. debug.traceback(" << \n", 4))
		end
	end
	
	self.SetTimer = function(self, _duration: number, _callback: any)
		coroutine.wrap(function()
			self._assert(_duration ~= nil, "TimeScheduler:SetTimer(..., duration): duration is nil")
			self._assert(typeof(_callback) == "function", "TimeScheduler:SetTimer(..., duration, callback): callback is not a function")
			self._assert(typeof(_duration) == "number", "TimeScheduler:SetTimer(..., duration): duration is not a number")

			self._setTimes[#self._setTimes + 1] = {
				Tick = tick() + _duration,
				Callback = _callback,
			}
		end)()
		
		return #self._setTimes
	end

	self.Wait = function(self, _duration)
		local _self = {}
		local Destroyed = false
		local Cancel = false
		
		self._assert(_duration ~= nil, "TimeScheduler:Wait(..., duration): duration is nil")
		self._assert(typeof(_duration) == "number", "TimeScheduler:Wait(..., duration): duration is not a number")
		
		local StartTick = tick()
		
		_self.Cancel = function(self)
			Cancel = true
		end
		
		_self.Start = function(self)
			repeat
				local runService = game:GetService("RunService")

				runService.Heartbeat:Wait()
			until Destroyed or tick() - StartTick > _duration or Cancel
		end
		
		_self.Destroy = function(self)
			Destroyed = true
		end
		
		return _self
	end
	
	self.SetMarker = function(self, name: string, category: string, callbacks: table)
		self._assert(typeof(callbacks) ~= "table", "TimeScheduler:SetMarker(..., callbacks): Callback is not a table/dictionary")
		
		self._markers[name or #self._markers + 1] = {
			Time = tick(),
			Category = self._markerCategories[category] or nil,
		}
		
		if callbacks then
			for i, v in pairs(callbacks) do
				if typeof(v) == "function" then
					self._markerCallbacks[#self._markerCallbacks + 1] = {
						Time = i,
						Function = v,
					}
				end
			end
		end
		
		if not self._markerCategories[category] then
			self._markerCategories[category] = {}
		end
		
		self._markerCategories[category][#self._markerCategories[category] + 1] = self._markers[name or #self._markers]
		
		return name or #self._markers
	end
	
	self.GetMarker = function(self, id: string)
		self._assert(id ~= nil, "TimeScheduler:GetMarker(id) 'Id' is nil")
		
		if self._markers[id] then
			return {
				TimeSince = tick() - self._markers[id].Time,
			}
		end
	end
	
	self.GetMarkersInCategory = function(self, category: string, dontRefine)
		self._assert(category ~= nil, "TimeScheduler:GetMarkersInCategory(category) 'category' is nil")
		
		local data = self._markerCategories[category]
		local newdata = nil
		
		if not dontRefine then
			newdata = {}
			
			for i, v in pairs(data) do
				newdata[i] = {
					Time = v.Time,
					TimeSince = tick() - v.Time
				}
			end
		end
		
		return newdata or data
	end
	
	self._Connection = game:GetService("RunService").Heartbeat:Connect(function()
		for index, timers in pairs(self._setTimes) do
			if tick() > timers.Tick then
				timers.Callback()
				
				self._setTimes[index] = nil
			end
		end
	end)
	
	return self
end

return time_scheduler
