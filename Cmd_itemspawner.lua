function HandleHelpCommand(a_Split, a_Player)
	a_Player:SendMessageInfo("Sub commands:")
	a_Player:SendMessage("/itemspawner create <name> [radius] [interval] - Create a new item spawner")
	a_Player:SendMessage("/itemspawner remove <name> - Removes the spawner")
	a_Player:SendMessage("/itemspawner list - List all item spawners")
	a_Player:SendMessage("/itemspawner info <name> - Show the info to the item spawner")
	a_Player:SendMessage("/itemspawner enable <name> - Enable the item spawner")
	a_Player:SendMessage("/itemspawner disable <name> - Disable the item spawner")
	a_Player:SendMessage("/itemspawner update <name> <interval> - Update the interval, spawn items every X seconds")
	return true
end



function HandleCreateCommand(a_Split, a_Player)
	if #a_Split == 2 then
		a_Player:SendMessage("/itemspawner create <name> [radius] [interval] - Create a new item spawner")
		return true
	end

	-- Get params
	local name = string.lower(a_Split[3])
	if g_ItemSpawners[name] then
		a_Player:SendMessage("There is already a item spawner with this name " .. name .. " You can use '/itemspawner remove <name>' to remove it.")
		return true
	end

	local worldName = a_Player:GetWorld():GetName()
	local posX = a_Player:GetPosX()
	local posY = a_Player:GetPosY()
	local posZ = a_Player:GetPosZ()

	-- Check if radius has been passed
	if not(a_Split[4]) then
		a_Split[4] = g_DefaultRadius
	end

	local radius = tonumber(a_Split[4])
	if not(radius) or radius <= 0 then
		a_Player:SendMessage("Invalid number for radius passed, expect a positive number!")
		return true
	end

	-- Check if interval has been passed
	if not(a_Split[5]) then
		a_Split[5] = g_DefaultInterval
	end

	local interval = tonumber(a_Split[5])
	if not(interval) or interval <= 0 then
		a_Player:SendMessage("Invalid number for interval passed, expect a positive number!")
		return true
	end

	local spawnerInfo = cSpawnerInfo:new(
		name,
		worldName,
		posX, posY, posZ,
		tonumber(a_Split[4]),
		tonumber(a_Split[5]))

	spawnerInfo.m_UpdatedBy = a_Player:GetName()

	spawnerInfo:Save()
	g_ItemSpawners[a_Split[3]] = spawnerInfo
	a_Player:SendMessageInfo("Created item spawner and saved it.")
	return true
end



function HandleRemoveCommand(a_Split, a_Player)
	if #a_Split < 3 then
		a_Player:SendMessage("/itemspawner remove <name> - Removes the item spawner")
		return true
	end

	local spawnerInfo = GetSpawnerInfo(a_Split[3], a_Player)
	if not(spawnerInfo) then
		a_Player:SendMessageInfo("There it no item spawner with that name.")
		return true
	end

	if (spawnerInfo.m_IsEnabled) then
		spawnerInfo.m_IsEnabled = false
	end

	if not(g_Storage:DelSpawnerInfo(spawnerInfo.m_ID)) then
		a_Player:SendMessageFailure("SQL error occurred, reported to console!")
		return true
	end
	g_ItemSpawners[spawnerInfo.m_Name] = nil
	a_Player:SendMessageInfo("Removed item spawner.")
	return true
end



function HandleListCommand(a_Split, a_Player)
	local tbNamesEnabled = g_Storage:GetListOfAllSpawnerNames()
	if tbNamesEnabled == -1 then
		a_Player:SendMessageFailure("SQL error occurred, reported to console!")
		return true
	end

	a_Player:SendMessageInfo("Names of all item spawners (green is enabled):")
	if tbNamesEnabled == nil then
		a_Player:SendMessage("<empty>")
	else
		local list = ""
		for name, enabled in pairs(tbNamesEnabled) do
			if list ~= "" then
				list = list .. ", "
			end

			if enabled then
				list = list .. cChatColor.Green .. name
			else
				list = list .. name
			end
		end
		a_Player:SendMessage(list)
	end
	return true
end



function HandleInfoCommand(a_Split, a_Player)
	if #a_Split < 3 then
		a_Player:SendMessage("/itemspawner info <name> - Shows info about the item spawner.")
		return true
	end

	local spawnerInfo = GetSpawnerInfo(a_Split[3], a_Player)
	if not(spawnerInfo) then
		return true
	end

	spawnerInfo.m_UpdatedBy = a_Player:GetName()

	a_Player:SendMessageInfo("Info to item spawner " .. spawnerInfo.m_Name)
	a_Player:SendMessage("World: " .. spawnerInfo.m_WorldName)
	a_Player:SendMessage("Position: " .. string.format("x = %d, y = %d, z = %d", spawnerInfo.m_PosX, spawnerInfo.m_PosY, spawnerInfo.m_PosZ))
	a_Player:SendMessage("Interval: " .. string.format("%d seconds", spawnerInfo.m_Interval))
	a_Player:SendMessage("Radius: " .. string.format("%d blocks", spawnerInfo.m_Radius))
	a_Player:SendMessage("IsEnabled: " .. tostring(spawnerInfo.m_IsEnabled))
	return true
end



function HandleEnableCommand(a_Split, a_Player)
	if #a_Split < 3 then
		a_Player:SendMessage("/itemspawner enable <name> - Enable the item spawner.")
		return true
	end

	local spawnerInfo = GetSpawnerInfo(a_Split[3], a_Player)
	if not(spawnerInfo) then
		return true
	end

	spawnerInfo.m_UpdatedBy = a_Player:GetName()

	if spawnerInfo.m_IsEnabled then
		a_Player:SendMessageInfo("The item spawner is already enabled.")
		return true
	end

	spawnerInfo:SetIsEnabled(true)
	spawnerInfo:Runit()
	a_Player:SendMessageInfo("Item spawner enabled.")
	return true
end



function HandleDisableCommand(a_Split, a_Player)
	if #a_Split < 3 then
		a_Player:SendMessage("/itemspawner disable <name> - Disable the item spawner.")
		return true
	end

	local spawnerInfo = GetSpawnerInfo(a_Split[3], a_Player)
	if not(spawnerInfo) then
		return true
	end

	spawnerInfo.m_UpdatedBy = a_Player:GetName()

	if not(spawnerInfo.m_IsEnabled) then
		a_Player:SendMessageInfo("The item spawner is already disabled.")
		return true
	end

	spawnerInfo:SetIsEnabled(false)
	a_Player:SendMessageInfo("Item spawner disabled.")
	return true
end



function HandleChangeIntervalCommand(a_Split, a_Player)
	if #a_Split < 4 then
		a_Player:SendMessage("/itemspawner change interval <name> <value> - Change the interval.")
		return true
	end

	local spawnerInfo = GetSpawnerInfo(a_Split[4], a_Player)
	if not(spawnerInfo) then
		return true
	end

	spawnerInfo.m_UpdatedBy = a_Player:GetName()

	local interval = tonumber(a_Split[5])
	if not(interval) or interval <= 0 then
		a_Player:SendMessage("Invalid number for interval, expect a positive number!")
		return true
	end

	spawnerInfo:SetInterval(interval)
	a_Player:SendMessageInfo("Changed the interval.")
	return true
end



function HandleChangeRadiusCommand(a_Split, a_Player)
	if #a_Split < 4 then
		a_Player:SendMessage("/itemspawner change radius <name> <value> - Change the radius.")
		return true
	end

	local spawnerInfo = GetSpawnerInfo(a_Split[4], a_Player)
	if not(spawnerInfo) then
		return true
	end

	spawnerInfo.m_UpdatedBy = a_Player:GetName()

	local radius = tonumber(a_Split[5])
	if not(radius) or radius <= 0 then
		a_Player:SendMessage("Invalid number for radius, expect a positive number!")
		return true
	end

	spawnerInfo:SetRadius(radius)
	a_Player:SendMessageInfo("Changed the radius.")
	return true
end
