g_Plugin = nil

PluginPrefix = "Itemspawner: "

-- Cache all last used and enabled item spawners
g_ItemSpawners = {}

-- List of items
g_Items = {}

-- The radius in which the items will be spawned
g_DefaultRadius = 25

-- The interval between spawning items, in seconds
g_DefaultInterval = 10

function Initialize(a_Plugin)
	a_Plugin:SetName("ItemSpawner")
	a_Plugin:SetVersion(1)
	g_Plugin = a_Plugin

	if not(InitializeStorage(a_Plugin:GetLocalFolder() .. cFile:GetPathSeparator() .. "spawners.sqlite")) then
		LOGERROR(PluginPrefix .. " Creating or opening the sqlite database failed!")
		return false
	end

	cPluginManager:AddHook(cPluginManager.HOOK_DISCONNECT, OnDisconnect)

	-- Random, random
	math.randomseed(os.time())
	math.random(); math.random(); math.random()

	LoadItems()

	LoadAllEnabledSpawnerInfos()

	-- Load the InfoReg shared library
	dofile(cPluginManager:GetPluginsPath() .. cFile:GetPathSeparator() .. "InfoReg.lua")

	-- Bind all the commands
	RegisterPluginInfoCommands()

	return true
end



function OnDisable()
	g_Storage.m_SqliteDB:close()

	LOG( "Disabled ItemSpawner!" )
end



-- Remove spawner infos that are not enabled and the
-- player who changed it has disconnected
function OnDisconnect(a_Client, a_Reason)
	local player = a_Client:GetPlayer()
	if not(player) then
		return
	end

	for name, spawnerInfo in pairs(g_ItemSpawners) do
		if
			not(spawnerInfo.m_IsEnabled) and
			spawnerInfo.m_UpdatedBy == player:GetName()
		then
			g_ItemSpawners[name] = nil
		end
	end
end
