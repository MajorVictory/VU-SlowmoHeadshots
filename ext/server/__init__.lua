class "SlowmoHeadshots"

function SlowmoHeadshots:__init()
	self.enabled = true
	self.slowmoTime = 3.0
	self.slowmoTimeScale = 0.5
	self.normalTimeScale = 1.0

	self.cumulatedTime = -1
	self:RegisterRcon()
	self:RegisterEvents()
end

function SlowmoHeadshots:RegisterRcon()
	RCON:RegisterCommand('vu-slowmowheadshots.enabled', RemoteCommandFlag.RequiresLogin, self, self.onRconEnabled)
	RCON:RegisterCommand('vu-slowmowheadshots.slowmoTime', RemoteCommandFlag.RequiresLogin, self, self.onRconSlowmoTime)
	RCON:RegisterCommand('vu-slowmowheadshots.slowmoTimeScale', RemoteCommandFlag.RequiresLogin, self, self.onRconSlowmoTimeScale)

	local result = RCON:SendCommand('vu.timeScale')
	if (result[1] == 'OK') then
		self.normalTimeScale = result[2]
	end
end

function SlowmoHeadshots:RegisterEvents()
	Events:Subscribe('Engine:Update', self, self.onEngineUpdate)
	Events:Subscribe('Player:Killed', self, self.onPlayerKilled)
end

function SlowmoHeadshots:DeregisterEvents()
	Events:Unsubscribe('Engine:Update')
	Events:Unsubscribe('Player:Killed')
end

function SlowmoHeadshots:onRconEnabled(command, values)
	if (values == nil or #values == 0) then
		return {'OK', tostring(self.enabled)}
	end

	local enabled = values[1] == '1' or values[1]:lower() == 'true' or values[1]:lower() == 'on' or values[1]:lower() == 'yes'

	if (self.enabled ~= enabled) then
		self.enabled = enabled
		if (self.enabled) then
			self:RegisterEvents()
		else
			self:DeregisterEvents()
		end
	end
	return {'OK', tostring(self.enabled)}
end

function SlowmoHeadshots:onRconSlowmoTime(command, values)
	if (values == nil or #values == 0) then
		return {'OK', tostring(self.slowmoTime)}
	end

	local slowmoTime = tonumber(values[1])
	if (slowmoTime == nil) then
		return {'Invalid Value: Time must be a float value'}
	end

	self.slowmoTime = slowmoTime
	return {'OK', self.slowmoTime}
end

function SlowmoHeadshots:onRconSlowmoTimeScale(command, values)
	if (values == nil or #values == 0) then
		return {'OK', tostring(self.slowmoTimeScale)}
	end

	local slowmoTimeScale = tonumber(values[1])
	if (slowmoTimeScale == nil) then
		return {'Invalid Value: Scale must be a float value'}
	end

	self.slowmoTimeScale = slowmoTimeScale
	return {'OK', self.slowmoTimeScale}
end


function SlowmoHeadshots:onEngineUpdate(deltaTime, simulationDeltaTime)
	if self.cumulatedTime < 0 then return end

	self.cumulatedTime = self.cumulatedTime + deltaTime

	if self.cumulatedTime >= self.slowmoTime then
		self.cumulatedTime = -1
		print('vu.timeScale: '..self.normalTimeScale)
		RCON:SendCommand('vu.timeScale', {tostring(self.normalTimeScale)})
	end
end

function SlowmoHeadshots:onPlayerKilled(player, inflictor, position, weapon, isRoadKill, isHeadShot, wasVictimInReviveState, info)
	if isHeadShot then
		print('vu.timeScale: '..self.slowmoTimeScale)
		RCON:SendCommand('vu.timeScale', {tostring(self.slowmoTimeScale)})
		self.cumulatedTime = 0
	end
end

SlowmoHeadshots()