local LFG_OPT = LibStub("AceAddon-3.0"):GetAddon("LookingForGroup_Options")

local function keystone_information(detailed)
	local mapid = C_MythicPlus.GetOwnedKeystoneChallengeMapID()
	if mapid then
		local maps_to_activity_id =
		{
			[244] = 502,
			[245] = 518,
			[249] = 514,
			[252] = 522,
			[353] = 534,
			[250] = 504,
			[247] = 510,
			[251] = 507,
			[246] = 526,
			[248] = 530
		}
		return maps_to_activity_id[mapid],C_MythicPlus.GetOwnedKeystoneLevel()
	end
end

local disable_text = "|cffff0000"..string.gsub(MYTHIC_PLUS_TAB_DISABLE_TEXT, "\n"," ").."|r"

LFG_OPT:push("m+",{
	name = LFG_OPT.mythic_keystone_label_name,
	type = "group",
	args =
	{
		title = 
		{
			order = 1,
			name = function()
				local t = C_MythicPlus.GetOwnedKeystoneLevel()
				if t then
					return t
				end
				return disable_text
			end,
			type = "input",
			dialogControl = "LFG_SECURE_NAME_EDITBOX_REFERENCE",
			width = "full"
		},
		create =
		{
			name = function()
				if C_LFGList.HasActiveEntryInfo() then
					return UNLIST_MY_GROUP
				else
					return LIST_GROUP
				end
			end,
			type = "execute",
			order = 2,
			func = function()
				if C_LFGList.HasActiveEntryInfo() then
					C_LFGList.RemoveListing()
					return
				end
				local activityID,key_level_number = keystone_information(true)
				if not activityID then
					LFG_OPT.expected(disable_text)
					return
				end
				if string.match(LFGListFrame.EntryCreation.Name:GetText(),"(%d+)") ~= tostring(key_level_number) then
					LFG_OPT.expected("|cffff0000Title does not contain the keyword|r "..key_level_number)
					return
				end
				local _,_,categoryID,groupID = C_LFGList.GetActivityInfo(activityID)
				local profile = LFG_OPT.db.profile
				local a = profile.a
				local category = a.category
				wipe(a)
				a.category = categoryID
				a.group = groupID
				a.activity = activityID
				if category ~= a.category then
						LFG_OPT.OnProfileChanged()
				end
				local s = profile.s
				local auto_accept = s.auto_accept
				wipe(s)
				s.auto_accept = auto_accept
				local mplus_callbacks = LFG_OPT.mplus_callbacks
				for i=1,#mplus_callbacks do
					mplus_callbacks[i](profile,a,s,key_level_number)
				end
				LFG_OPT.listing(a.activity,s,nil,{"m+"})
			end
		},
		reset =
		{
			name = RESET,
			type = "execute",
			order = 3,
			func = C_LFGList.ClearCreationTextFields
		},
		auto_accept =
		{
			order = 4,
			name = LFG_LIST_AUTO_ACCEPT,
			type = "toggle",
			get = LFG_OPT.options_get_s_function,
			set = LFG_OPT.options_set_s_function
		},
		desc = 
		{
			order = 5,
			name = function()
				local t = {}
				local C_MythicPlus = C_MythicPlus
				if C_MythicPlus.IsWeeklyRewardAvailable() then
					t[#t+1] = "|cffff0000"
					t[#t+1] = CLAIM_REWARD
					t[#t+1] = "|r\n"
				end
				local best_kl = 10
				local best_rw = C_MythicPlus.GetRewardLevelForDifficultyLevel(best_kl)
				while best_kl < 31 do
					local gg = C_MythicPlus.GetRewardLevelForDifficultyLevel(best_kl+3)
					if gg == best_rw then
						break
					end
					best_rw = gg
					best_kl = best_kl + 5
				end
				local owned_keystone_level = C_MythicPlus.GetOwnedKeystoneLevel()
				if owned_keystone_level then
					t[#t+1] = format(MYTHIC_PLUS_MISSING_WEEKLY_CHEST_REWARD,owned_keystone_level,
										C_MythicPlus.GetRewardLevelForDifficultyLevel(owned_keystone_level))
				end
				if owned_keystone_level ~= best_kl then
					if owned_keystone_level then
						t[#t+1] = "\n"
					end
					t[#t+1] = "|cffff0000"
					t[#t+1] = format(MYTHIC_PLUS_MISSING_WEEKLY_CHEST_REWARD,best_kl,best_rw)
					t[#t+1] = "|r"
				end
				local affixes = C_MythicPlus.GetCurrentAffixes()
				if affixes then
					t[#t+1] = "\n\n|cff8080cc"
					t[#t+1] = #affixes
					t[#t+1] = "|r"
					for i=1,#affixes do
						local name,description,filedataid = C_ChallengeMode.GetAffixInfo(affixes[i].id)
						t[#t+1] = "\n|T"
						t[#t+1] = filedataid
						t[#t+1] = ":0:0:0:0:10:10:1:9:1:9|t|cff8080cc"
						t[#t+1] = name
						t[#t+1] = "|r\n"
						t[#t+1] = description
					end
				end
				return table.concat(t)
			end,
			fontSize = "large",
			type = "description"
		}
	}
})

LFG_OPT.Register("mplus_callbacks",nil,function(profile,a,s)
	s.minimum_item_level = GetAverageItemLevel()-2
	s.role = true
end)

if GetCurrentRegion() == 5 then	-- add +10 ilvl for Chinese Region since they do not have Raider.IO
	LFG_OPT.Register("mplus_callbacks",nil,function(profile,a,s)
		s.fake_minimum_item_level = GetAverageItemLevel()+10
	end)
end