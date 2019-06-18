local LFG_OPT = LibStub("AceAddon-3.0"):GetAddon("LookingForGroup_Options")

local function keystone_information(detailed)
	for bagID = 0, 4 do
		for invID = 1, GetContainerNumSlots(bagID) do
			local itemID = GetContainerItemID(bagID, invID)
			if itemID and itemID == 158923 then
				local itemLink = GetContainerItemLink(bagID, invID)
				local item_id, map, keyLevel, l4,l7 = string.match(itemLink, 'keystone:(%d+):(%d+):(%d+):(%d+):(%d+)')
				if not detailed then
					return keyLevel,tonumber(keyLevel)
				end
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
				local activity_id = maps_to_activity_id[tonumber(map)]
				if activity_id then
					return activity_id,keyLevel,tonumber(keyLevel)
				end
			end
		end
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
				local t = keystone_information()
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
				local activityID,key_level,key_level_number = keystone_information(true)
				if not activityID then
					LFG_OPT.expected(disable_text)
					return
				end
				if string.match(LFGListFrame.EntryCreation.Name:GetText(),"(%d+)") ~= key_level then
					LFG_OPT.expected("|cffff0000Title does not contain the keyword|r "..key_level)
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
	}
})

LFG_OPT.Register("mplus_callbacks",nil,function(profile,a,s)
	s.minimum_item_level = GetAverageItemLevel()
	s.role = true
end)

if GetCurrentRegion() == 5 then	-- add +10 ilvl for Chinese Region since they do not have Raider.IO
	LFG_OPT.Register("mplus_callbacks",nil,function(profile,a,s)
		s.fake_minimum_item_level = GetAverageItemLevel()+10
	end)
end