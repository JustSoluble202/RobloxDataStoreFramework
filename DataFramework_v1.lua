-- // Services
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local LocalizationService = game:GetService("LocalizationService")
-- // Modules
local DataProcessor = {}
local ServerConfig = require(game.ServerScriptService.ServerScriptCore.Configuration.ServerCore)
-- // DataStore
local PlayerStatsStore = DataStoreService:GetDataStore("PlayerData") -- 901052178 (PlayerStats)

-- // Cashe
DataProcessor.ProfileCache = {}
DataProcessor.UsersCaching = {}

-- // Mechanica lWorks
function DataProcessor.DNUprintTableFunc(tab, string)
	for i,v in pairs(tab) do
		if type(v) == "table" then
			warn(string,i," : ",v,":::")
			DataProcessor.DNUprintTableFunc(v, string.."     ")
		else
			warn(string,i," : ",v)
		end
	end
end
function DataProcessor.printTable(tab)
	DataProcessor.DNUprintTableFunc(tab, "")
end
function DataProcessor.RemoveTableDupes(table_)
	local hash = {}
	local res = {}
	for _,v in ipairs(table_) do
		if (not hash[v]) then
			res[#res+1] = v
			hash[v] = true
		end
	end
	return res
end

-- GET FROM DATASTORE, LOAD INTO ProfileCache. Returns RAWData
function DataProcessor.fetchDatastore(player)
	local PlayerFetchedUserId = Players:GetUserIdFromNameAsync(player.Name)
	local CurrentDate = DateTime.now():FormatUniversalTime("L", LocalizationService.RobloxLocaleId)
	local dataRaw
	local s, r = pcall(function() 
		dataRaw = PlayerStatsStore:GetAsync(PlayerFetchedUserId) 
	end)
	if s == false then
		warn("["..player.Name.."][DATA][ERR] failed to fetch data from datastore. "..r)
		return false
	else
		local dataFormat = {
			Figures = {
				PlaceData = {},
				Money = ServerConfig.defaults.money,
			};
			Settings = {
				MusicMuted = false,
			};
			Misc = {
				FirstJoined = CurrentDate,
				LastJoined = false,
				Purchased = {},
				TimesJoined = 1,
				Banned = false,
				BannedReason = false,
				BannedTimeStamp = false,
				Muted = false,
				MutedReason = false,
				MutedTimeStamp = false
			};
		}

		if dataRaw ~= nil then -- has a profile
			dataFormat.Figures.PlaceData = dataRaw.Figures.PlaceData
			dataFormat.Figures.Money = dataRaw.Figures.Money or ServerConfig.defaults.money

			dataFormat.Settings.MusicMuted = dataRaw.Settings.MusicMuted or false

			dataFormat.Misc.FirstJoined = dataRaw.Misc.FirstJoined or CurrentDate
			dataFormat.Misc.LastJoined = dataRaw.Misc.LastJoined or false
			dataFormat.Misc.Purchased = dataRaw.Misc.Purchased or {}
			dataFormat.Misc.TimesJoined = dataRaw.Misc.TimesJoined + 1 or 1
			dataFormat.Misc.Banned = dataRaw.Misc.Banned or false
			dataFormat.Misc.BannedReason = dataRaw.Misc.BannedReason or false
			dataFormat.Misc.BannedTimeStamp = dataRaw.Misc.BannedTimeStamp or false
			dataFormat.Misc.Muted = dataRaw.Misc.Muted or false
			dataFormat.Misc.MutedReason = dataRaw.Misc.MutedReason or false
			dataFormat.Misc.MutedTimeStamp = dataRaw.Misc.MutedTimeStamp or false
			
			local found = false
			for i,v in pairs(dataFormat.Figures.PlaceData) do
				if i == tostring(game.PlaceId) then
					found = true
				end
			end
			if found == false then
				dataFormat["Figures"]["PlaceData"][tostring(game.PlaceId)] = {["Level"] = ServerConfig.defaults.level}
			end
			

			for i,v in pairs(dataFormat.Misc.Purchased) do
				local found = false
				for i1,v1 in pairs(ServerConfig.store) do
					if v == v1["DisplayName"] then
						found = true
					end
				end
				if found == false then
					table.remove(dataFormat.Misc.Purchased, i)
					print("["..player.Name.."][DATA][WRN] product ["..v.."] is not avalable. removed from players cache")
				end
			end
			dataFormat.Misc.Purchased = DataProcessor.RemoveTableDupes(dataFormat.Misc.Purchased)

		elseif dataRaw == nil then
			dataFormat["Figures"]["PlaceData"][tostring(game.PlaceId)] = {["Level"] = ServerConfig.defaults.level}
			print("["..player.Name.."][DATA][LOG] created default data profile")
			dataFormat.Misc.TimesJoined = 1
		end
		print("["..player.Name.."][DATA][LOG] loading data profile into cashe")
		DataProcessor.ProfileCache[PlayerFetchedUserId] = dataFormat	
		print(DataProcessor.ProfileCache[PlayerFetchedUserId])
		return dataFormat
	end
end

-- GET SCOPE, SAVE TO CACHE
function DataProcessor.syncCashe(player, ...) -- "Settings", "MusicMuted", true
	local PlayerFetchedUserId = Players:GetUserIdFromNameAsync(player.Name)
	if DataProcessor.ProfileCache[PlayerFetchedUserId] ~= nil then
		local scopes = {...}
		local s, r = pcall(function() 
			if DataProcessor.ProfileCache[PlayerFetchedUserId][scopes[1]] ~= nil then -- Top Level
				if scopes[2] == "Level" then
					DataProcessor.ProfileCache[PlayerFetchedUserId][scopes[1]]["PlaceData"][tostring(game.PlaceId)][scopes[2]] = scopes[3]	
				elseif scopes[2] == "Purchased" then
					print("work on this")
					--[[
					for i3,v3 in pairs(ServerConfig.store) do
									if v3["DisplayName"] == scopes[3] then
										found = true
									end
								end
								if found == false then
									print("["..player.Name.."][DATA][LOG] product scope ["..scopes[3].."] cannot be found in store while syncing cache")
									return false
								end

								if table.find(DataProcessor.ProfileCache[PlayerFetchedUserId]["Misc"]["Purchased"], scopes[3]) == nil then
									table.insert(DataProcessor.ProfileCache[PlayerFetchedUserId][i1][i2], scopes[3])
									print("["..player.Name.."][DATA][LOG] updated ["..i2.."] scope in cashe")
									return true
								else
									print("["..player.Name.."][DATA][WRN] rejected cashe update as ["..scopes[3].."] is already cached")
									return false
								end
					]]
				else
					if DataProcessor.ProfileCache[PlayerFetchedUserId][scopes[1]][scopes[2]] ~= nil then -- sub level
						DataProcessor.ProfileCache[PlayerFetchedUserId][scopes[1]][scopes[2]] = scopes[3]	
					end
				end

			end

		end)
		if s == false then
			warn("["..player.Name.."][DATA][ERR] failed to update cache. "..r)
			return false
		end
	else
		warn("["..player.Name.."][DATA][ERR] failed to find user in cache")
		return false
	end
end

-- RETURN PLAYERS CASHE
function DataProcessor.fetchCache(player)
	local PlayerFetchedUserId = Players:GetUserIdFromNameAsync(player.Name)
	if DataProcessor.ProfileCache[PlayerFetchedUserId] ~= nil then
		return DataProcessor.ProfileCache[PlayerFetchedUserId]
	else
		warn("["..player.Name.."][DATA][ERR] failed to find user in cashe")
		return false
	end
end

-- RETURN PURCHASED ITEMS
function DataProcessor.fetchPurchases(player)
	local PlayerFetchedUserId = Players:GetUserIdFromNameAsync(player.Name)
	if DataProcessor.ProfileCache[PlayerFetchedUserId] ~= nil then
		local dataFormat = {
			Purchased = {},
			NotPurchased = {},
		}
		for i1, v1 in pairs(ServerConfig.store) do
			local productFormat = {
				ImageId = v1["ImageId"],
				Category = v1["Category"],
				PlaceLocked = v1["PlaceLocked"],
				Description = v1["Description"],
				Cost = v1["Cost"],
				DisplayName = v1["DisplayName"],
			}
			if v1["PlaceLocked"] == game.PlaceId or v1["PlaceLocked"] == false then
				if table.find(DataProcessor.ProfileCache[PlayerFetchedUserId]["Misc"]["Purchased"], v1["DisplayName"]) then
					table.insert(dataFormat.Purchased, productFormat)
				else
					table.insert(dataFormat.NotPurchased,productFormat)
				end
			end
		end
		return dataFormat
	else
		warn("["..player.Name.."][DATA][ERR] failed to find user in cashe")
		return false
	end
end

function DataProcessor.syncPurchase(player, productname)
	local PlayerFetchedUserId = Players:GetUserIdFromNameAsync(player.Name)
	if DataProcessor.ProfileCache[PlayerFetchedUserId] ~= nil then
		for i,v in pairs(ServerConfig.store) do
			if v["DisplayName"] == productname then
				if v["PlaceLocked"] == tostring(game.PlaceId) or v["PlaceLocked"] == false then
					table.insert(DataProcessor.ProfileCache[PlayerFetchedUserId]["Misc"]["Purchased"], v["DisplayName"])
					return true
				else 
					print("is PlaceLocked")
				end
			end
		end
		return false
	else
		warn("["..player.Name.."][DATA][ERR] failed to find user in cashe")
		return false
	end
end

-- GET PLAYER CASHE, SAVE TO DATASTORE
function DataProcessor.syncDatastore(player)
	local PlayerFetchedUserId = Players:GetUserIdFromNameAsync(player.Name)
	if DataProcessor.UsersCaching[player] == nil then
		DataProcessor.UsersCaching[player] = true
		if DataProcessor.ProfileCache[PlayerFetchedUserId] ~= nil then
			local s, r = pcall(function() 
				PlayerStatsStore:SetAsync(PlayerFetchedUserId, DataProcessor.ProfileCache[PlayerFetchedUserId]) 
				warn(DataProcessor.ProfileCache[PlayerFetchedUserId])
			end)
			if s then
				print("["..player.Name.."][DATA][LOG] synced cache to datastore")
			elseif s == false then
				warn("["..player.Name.."][DATA][ERR] failed to sync. "..r)
				return false
			end
		else
			warn("["..player.Name.."][DATA][ERR] failed to find user in cache")
			return false
		end
		DataProcessor.UsersCaching[player] = nil
		return true
	end
end

-- RETURN PLAYERS CACHE
function DataProcessor.clearProfileCache(player)
	local PlayerFetchedUserId = Players:GetUserIdFromNameAsync(player.Name)
	DataProcessor.ProfileCache[PlayerFetchedUserId] = nil
end

return DataProcessor
