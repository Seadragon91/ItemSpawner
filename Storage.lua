
-- Storage.lua
-- Implements the storage access object, shielding the rest of the code away from the DB

--[[
The cStorage class is the interface to the underlying storage, the SQLite database.

Also, a g_Storage global variable is declared, it holds the single instance of the storage.
--]]



cStorage = {}
cStorage.__index = cStorage

g_Storage = {}



--- Initializes the storage subsystem, creates the g_Storage object
-- Returns true if successful, false if not
function InitializeStorage(a_FilePath)
	g_Storage = cStorage:new()
	if not(g_Storage:OpenDB(a_FilePath)) then
		return false
	end
	return true
end



function cStorage:new()
	return setmetatable({}, cStorage)
end



--- Opens the DB and makes sure it has all the columns needed
-- Returns true if successful, false otherwise
function cStorage:OpenDB(a_FilePath)
	assert(a_FilePath)
	assert(self)

	local errCode, errMsg
	self.m_SqliteDB, errCode, errMsg = sqlite3.open(a_FilePath)
	if not(self.m_SqliteDB) then
		LOGWARNING(PluginPrefix .. "Cannot open spawners.sqlite, error " .. errCode .. " (" .. errMsg ..")")
		return false
	end

	if not(self:CreateTable("Spawners", {"ID INTEGER PRIMARY KEY AUTOINCREMENT", "Name", "WorldName", "PosX", "PosY", "PosZ", "Radius", "Interval", "IsEnabled" })) then
		LOGWARNING(PluginPrefix .. "Cannot create DB tables!")
		return false
	end

	return true
end





--- Executes the SQL command given, calling the a_Callback for each result
-- If the SQL command fails, prints it out on the server console and returns false
-- Returns true on success
function cStorage:DBExec(a_SQL, a_Callback, a_CallbackParam)
	assert(a_SQL)
	assert(self)

	local errCode = self.m_SqliteDB:exec(a_SQL, a_Callback, a_CallbackParam)
	if (errCode ~= sqlite3.OK) then
		LOGWARNING(PluginPrefix .. "Error " .. errCode .. " (" .. self.m_SqliteDB:errmsg() ..
			") while processing SQL command >>" .. a_SQL .. "<<"
		)
		return false
	end
	return true
end





--- Creates the table of the specified name and columns[]
-- If the table exists, any columns missing are added existing data is kept
function cStorage:CreateTable(a_TableName, a_Columns)
	assert(a_TableName)
	assert(a_Columns)
	assert(self)

	-- Try to create the table first
	local sql = "CREATE TABLE IF NOT EXISTS '" .. a_TableName .. "' ("
	sql = sql .. table.concat(a_Columns, ", ")
	sql = sql .. ")"
	if not(self:DBExec(sql)) then
		LOGWARNING(PluginPrefix .. "Cannot create DB Table " .. a_TableName)
		return false
	end
	-- SQLite doesn't inform us if it created the table or not, so we have to continue anyway

	-- Check each column whether it exists
	-- Remove all the existing columns from a_Columns:
	local RemoveExistingColumn = function(UserData, NumCols, Values, Names)
		-- Remove the received column from a_Columns. Search for column name in the Names[] / Values[] pairs
		for i = 1, NumCols do
			if (Names[i] == "name") then
				local ColumnName = Values[i]:lower()
				-- Search the a_Columns if they have that column:
				for j = 1, #a_Columns do
					-- Cut away all column specifiers (after the first space), if any:
					local SpaceIdx = string.find(a_Columns[j], " ")
					if (SpaceIdx ~= nil) then
						SpaceIdx = SpaceIdx - 1
					end
					local ColumnTemplate = string.lower(string.sub(a_Columns[j], 1, SpaceIdx))
					-- If it is a match, remove from a_Columns:
					if (ColumnTemplate == ColumnName) then
						table.remove(a_Columns, j)
						break  -- for j
					end
				end  -- for j - a_Columns[]
			end
		end  -- for i - Names[] / Values[]
		return 0
	end

	if not(self:DBExec("PRAGMA table_info(" .. a_TableName .. ")", RemoveExistingColumn)) then
		LOGWARNING(PluginPrefix .. "Cannot query DB table structure")
		return false
	end

	-- Create the missing columns
	-- a_Columns now contains only those columns that are missing in the DB
	if (#a_Columns > 0) then
		LOGINFO(PluginPrefix .. "Database table \"" .. a_TableName .. "\" is missing " .. #a_Columns .. " columns, fixing now.")
		for idx, ColumnName in ipairs(a_Columns) do
			if not(self:DBExec("ALTER TABLE '" .. a_TableName .. "' ADD COLUMN " .. ColumnName)) then
				LOGWARNING(PluginPrefix .. "Cannot add DB table \"" .. a_TableName .. "\" column \"" .. ColumnName .. "\"")
				return false
			end
		end
		LOGINFO(PluginPrefix .. "Database table \"" .. a_TableName .. "\" columns fixed.")
	end

	return true
end



--- Adds a new spawner info into the DB.
-- Returns the ID of the new spawner info, or -1 on failure
function cStorage:AddSpawnerInfo(a_SpawnerInfo)
	assert(a_SpawnerInfo)
	assert(self)

	-- Store the spawner info in the DB
	local id = -1
	local function RememberID(UserData, NumCols, Values, Names)
		for i = 1, NumCols do
			if (Names[i] == "ID") then
				id = Values[i]
			end
		end
		return 0
	end
	local lcWorldName = string.lower(a_SpawnerInfo.m_WorldName)
	local lcSpawnerName = string.lower(a_SpawnerInfo.m_Name)
	local enabled = 0
	if a_SpawnerInfo.m_IsEnabled then
		enabled = 1
	end
	local sql = "INSERT INTO Spawners (ID, Name, WorldName, PosX, PosY, PosZ, Radius, Interval, IsEnabled) VALUES (NULL, "
	local values = string.format("%q, %q, %d, %d, %d, %d, %d, %d", lcSpawnerName, lcWorldName, a_SpawnerInfo.m_PosX, a_SpawnerInfo.m_PosY, a_SpawnerInfo.m_PosZ, a_SpawnerInfo.m_Radius, a_SpawnerInfo.m_Interval, enabled)
	sql = sql .. values .. "); SELECT last_insert_rowid() AS ID"

	if not(self:DBExec(sql, RememberID)) then
		LOGWARNING(PluginPrefix .. "SQL Error while inserting new spawner info")
		return -1  -- Indicate an error
	end
	if (id == -1) then
		LOGWARNING(PluginPrefix .. "SQL Error while retrieving INSERTION ID")
		return -1  -- Indicate an error
	end
	return id
end



-- Updates the column to new value
function cStorage:UpdateColumn(a_ID, a_ColumnName, a_NewValue)
	assert(a_ID)
	assert(a_ColumnName)
	assert(a_NewValue ~= nil)
	assert(self)

	local value
	if type(a_NewValue) == "boolean" then
		if a_NewValue then
			value = 1
		else
			value = 0
		end
	elseif type(a_NewValue) == "string" then
		value = string.format("%q", a_NewValue)
	elseif type(a_NewValue) == "number" then
		value = a_NewValue
	else
		assert("Type not handled: " .. type(a_NewValue))
	end

	local sql = "UPDATE Spawners SET " .. a_ColumnName .. " = " .. value .. " WHERE ID = " .. a_ID
	if not(self:DBExec(sql)) then
		LOGWARNING(string.format("%q SQL error while updating %q to %q!", PluginPrefix, a_ColumnName, tostring(value)))
		return false
	end
	return true
end



function cStorage:DelSpawnerInfo(a_ID)
	assert(a_ID)
	assert(self)

	local sql = "DELETE FROM Spawners WHERE ID = " .. a_ID
	if not(self:DBExec(sql)) then
		LOGWARNING(string.format("%q SQL error while deleting spawner info %d!", PluginPrefix, a_ID))
		return false
	end
	return true
end



function cStorage:GetSpawnerInfo(a_Name)
	assert(a_Name)
	assert(self)

	local spawnerInfo

	function GetValues(UserData, NumValues, Values, Names)
		if NumValues ~= 9 then
			return 0
		end

		spawnerInfo = cSpawnerInfo:new(
			Values[2],  -- Name
			Values[3],  -- WorldName
			tonumber(Values[4]),  -- PosX
			tonumber(Values[5]),  -- PosY
			tonumber(Values[6]),  -- PosZ
			tonumber(Values[7]),  -- Radius
			tonumber(Values[8]))  -- Interval

		local enabled = tonumber(Values[9])  -- IsEnabled
		if enabled  == 1 then
			spawnerInfo.m_IsEnabled = true
			spawnerInfo:Runit()
		else
			spawnerInfo.m_IsEnabled = false
		end

		spawnerInfo.m_ID = tonumber(Values[1])
		return 0
	end

	local sql = string.format("SELECT * FROM Spawners WHERE Name = %q", a_Name)
	if not(self:DBExec(sql, GetValues)) then
		LOGWARNING(PluginPrefix .. "SQL Error while getting spawner info")
		return -1  -- Indicate an error
	end

	return spawnerInfo
end



function cStorage:GetListOfAllSpawnerNames()
	assert(self)

	local tbNamesEnabled = {}
	local empty = true

	function GetName(UserData, NumValues, Values, Names)
		if NumValues ~= 2 then
			return 0
		end

		empty = false
		local enabled = false
		if tonumber(Values[2]) == 1 then  -- IsEnabled
			enabled = true
		end

		tbNamesEnabled[Values[1]] = enabled
		return 0
	end

	local sql = "SELECT Name, IsEnabled FROM Spawners"
	if not(self:DBExec(sql, GetName)) then
		LOGWARNING(PluginPrefix .. "SQL Error while getting list of spawner names.")
		return -1
	end

	if empty then
		return nil
	end
	return tbNamesEnabled
end
