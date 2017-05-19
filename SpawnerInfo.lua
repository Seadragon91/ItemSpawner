cSpawnerInfo = {}
cSpawnerInfo.__index = cSpawnerInfo

function cSpawnerInfo:new(a_Name, a_WorldName, a_PosX, a_PosY, a_PosZ, a_Radius, a_Interval)
	local self = setmetatable({}, cSpawnerInfo)

	--  The name of the spawner
	self.m_Name = a_Name

	-- The world in which it is active
	self.m_WorldName = a_WorldName

	-- The location of the spawner
	self.m_PosX = a_PosX
	self.m_PosY = a_PosY
	self.m_PosZ = a_PosZ

	-- The radius in which the items will be spawned
	self.m_Radius = a_Radius or g_DefaultRadius

	-- The interval between spawning items, in seconds
	self.m_Interval = a_Interval or g_DefaultInterval

	self.m_IsEnabled = false


	-- The name of the player that changed this spawner info
	self.m_UpdatedBy = ""

	-- Will be updated, if spawner info is saved into or loaded from the database
	self.m_ID = -1

	return self
end



function cSpawnerInfo:Runit()
	if not(self.m_IsEnabled) then
		return
	end

	local world = cRoot:Get():GetWorld(self.m_WorldName)
	world:ScheduleTask(self.m_Interval * 20,
		function(a_World)
			-- Re-check
			if not(self.m_IsEnabled) then
				return
			end

			local rx = math.random(-self.m_Radius, self.m_Radius)
			local rz = math.random(-self.m_Radius, self.m_Radius)

			a_World:ChunkStay(
				{{ rx / 16, rz / 16 }},
				nil,
				function()
					local items = cItems()
					items:Add(g_Items[math.random(#g_Items)])
					a_World:SpawnItemPickups(items, self.m_PosX + rx, self.m_PosY, self.m_PosZ + rz, 0)
					self:Runit()
				end)
		end)
end



function cSpawnerInfo:Save()
	-- Store the id for updates
	self.m_ID = g_Storage:AddSpawnerInfo(self)
end



function cSpawnerInfo:SetInterval(a_Interval, a_Player)
	self.m_Interval = a_Interval
	if not(g_Storage:UpdateColumn(self.m_ID, "Interval", self.m_Interval)) then
		a_Player:SendMessageFailure("SQL error occurred, reported to console!")
	end
end



function cSpawnerInfo:SetRadius(a_Radius, a_Player)
	self.m_Radius = a_Radius
	if not(g_Storage:UpdateColumn(self.m_ID, "Radius" , self.m_Radius)) then
		a_Player:SendMessageFailure("SQL error occurred, reported to console!")
	end
end



function cSpawnerInfo:SetIsEnabled(a_IsEnabled, a_Player)
	self.m_IsEnabled = a_IsEnabled
	if not(g_Storage:UpdateColumn(self.m_ID, "IsEnabled" , self.m_IsEnabled)) then
		a_Player:SendMessageFailure("SQL error occurred, reported to console!")
	end
end
