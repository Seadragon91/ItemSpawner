function LoadItems()
	local pathItems = table.concat({ g_Plugin:GetLocalFolder(), "drop_items.ini" }, cFile:GetPathSeparator())

	if not(cFile:IsFile(pathItems)) then
		-- Create a example list of items
		local tbItems = {
			{ cItem(E_ITEM_IRON, 3), cItem(E_ITEM_IRON_NUGGET, 6), cItem(E_ITEM_IRON_SWORD) },
			{ cItem(E_BLOCK_GOLD_ORE), cItem(E_ITEM_GOLD_AXE), cItem(E_ITEM_GOLD_NUGGET, 1) },
			{ cItem(E_BLOCK_DIAMOND_BLOCK), cItem(E_ITEM_DIAMOND_PICKAXE), cItem(E_ITEM_DIAMOND, 2) }
		}

		local file = cIniFile()
		local cnt = 1
		for _, itemGroup in ipairs(tbItems) do
			local str = ""
			for _, item in ipairs(itemGroup) do
				if str ~= "" then
					str = str .. " "
				end

				str = str .. string.format(
					"%s:%d",
					ItemTypeToString(item.m_ItemType),
					item.m_ItemCount)

				if item.m_ItemDamage > 0 then
					str = str .. ":" .. item.m_ItemDamage
				end
			end
			file:AddValue("Items", cnt, str)
			cnt = cnt + 1
		end
		file:WriteFile(pathItems)
		return
	end

	local file = cIniFile()
	file:ReadFile(pathItems)

	local amount = file:GetNumValues("Items")
	for i = 1, amount do
		local itemGroup = ParseStringToItems(file:GetValue("Items", i))
		for _, item in ipairs(itemGroup) do
			table.insert(g_Items, item)
		end
	end
end


 -- Parses all elements from the string to items and returns a list
function ParseStringToItems(a_ToParse)
	local items = {}
	local list = StringSplit(a_ToParse, " ")
	for i = 1, #list do
		local item = cItem()
		local values = StringSplit(list[i], ":")

		 -- Check if valid item name
		if (StringToItem(values[1], item)) then
			local amount = tonumber(values[2])
			 -- Check if valid number
			if (amount ~= nil) then
				item.m_ItemCount = amount
				if (#values == 3) then
					local dv = tonumber(values[3])
					item.m_ItemDamage = dv
				end
				table.insert(items, item)
			end
		end
	end
	return items
end



--- Returns the item spaawner from the list or database
-- a_Name: the name of the item spawner
-- a_Player: Info for player if not found or error
function GetSpawnerInfo(a_Name, a_Player)
	a_Name = string.lower(a_Name)
	local spawnerInfo = g_ItemSpawners[a_Name]
	if not(spawnerInfo) then
		-- Check database
		spawnerInfo = g_Storage:GetSpawnerInfo(a_Name)
		if spawnerInfo == -1 then
			a_Player:SendMessageFailure("SQL error occurred, reported to console!")
			return nil
		elseif not(spawnerInfo) then
			a_Player:SendMessageInfo("There is no item spawner with that name.")
			return nil
		end

		-- Found in database, add to table
		g_ItemSpawners[a_Name] = spawnerInfo
	end

	return spawnerInfo
end



-- Load all spawners that are enabled
function LoadAllEnabledSpawnerInfos()
	local tbNamesEnabled = g_Storage:GetListOfAllSpawnerNames()
	if tbNamesEnabled == -1 then
		-- SQL error occurred
		return
	end

	if tbNamesEnabled == nil then
		-- Empty
		return
	end

	for name, enabled in pairs(tbNamesEnabled) do
		if enabled then
			local spawnerInfo = g_Storage:GetSpawnerInfo(name)
			if spawnerInfo == -1 then
				-- SQL error occurred
				return
			end

			if spawnerInfo then
				spawnerInfo:Runit()
				g_ItemSpawners[name] = spawnerInfo
			end
		end
	end
end
