--[[ WeaponMenuQueue : auto queue system ]]

WeaponMenu.PausedQueue = {} -- 0 or 1 whether queue is paused

function WeaponMenu.QueueInit()
	WeaponMenuQueue = WeaponMenuQueue or {
		Stats = {}, -- indexed by id of weapon, delay, priority and keep
		Sort = {}, -- indexed by number, ids in order of use
		Enabled = {} -- 0 or 1 whether auto queue is on for the slot
	}
	WeaponMenuQueue.Sort[0] = WeaponMenuQueue.Sort[0] or {}
	WeaponMenuQueue.Sort[1] = WeaponMenuQueue.Sort[1] or {}
	WeaponMenu_SubQueueFrame:SetBackdropBorderColor(.3,.3,.3,1)
	WeaponMenu_ProfilesFrame:SetBackdropBorderColor(.3,.3,.3,1)
	WeaponMenu_ProfilesListFrame:SetBackdropBorderColor(.3,.3,.3,1)
	WeaponMenu_SortPriorityText:SetText("Priority")
	WeaponMenu_SortPriorityText:SetTextColor(.95,.95,.95)
	WeaponMenu_SortKeepEquippedText:SetText("Pause Queue")
	WeaponMenu_SortKeepEquippedText:SetTextColor(.95,.95,.95)
	WeaponMenu_SortListFrame:SetBackdropBorderColor(.3,.3,.3,1)
	WeaponMenu.ReflectQueueEnabled()
	WeaponMenu.UpdateCombatQueue()

	WeaponMenuQueue.Profiles = WeaponMenuQueue.Profiles or {}
	WeaponMenu.ValidateProfile()

	WeaponMenu.OpenSort(0)
	WeaponMenu.OpenSort(1)
end

function WeaponMenu.ReflectQueueEnabled()
	WeaponMenu_Weapon0Check:SetChecked(WeaponMenuQueue.Enabled[0])
	WeaponMenu_Weapon1Check:SetChecked(WeaponMenuQueue.Enabled[1])
end	

function WeaponMenu.OpenSort(which)
	WeaponMenu.CurrentlySorting = which
	WeaponMenu.PopulateSort(which)
	WeaponMenu.SortSelected = 0
	WeaponMenu_SortScrollScrollBar:SetValue(0)
	WeaponMenu.SortValidate()
	WeaponMenu.SortScrollFrameUpdate()
end

function WeaponMenu.GetID(bag,slot)
	local id
	if slot then
		_,_,id = string.find(GetContainerItemLink(bag,slot) or "","item:(%d+)")
	else
		_,_,id = string.find(GetInventoryItemLink("player",bag) or "","item:(%d+)")
	end
	return id
end

function WeaponMenu.GetNameByID(id)
	if id==0 then
		return "-- stop queue here --","Interface\\Buttons\\UI-GroupLoot-Pass-Up",1
	else
		local name,_,quality,_,_,_,_,_,_,texture = GetItemInfo(id or "")
		return name,texture,quality
	end
end

-- adds id to which sort if it's not already in the list
function WeaponMenu.AddToSort(which,id)
	if not id then return end
	local found
	for i=1,#(WeaponMenuQueue.Sort[which]) do
		found = found or WeaponMenuQueue.Sort[which][i]==id
	end
	if not found then
		table.insert(WeaponMenuQueue.Sort[which],id)
	end
end

-- populates sorts adding any new weapons
function WeaponMenu.PopulateSort(which)
	WeaponMenuQueue.Sort[which] = WeaponMenuQueue.Sort[which] or {}
	WeaponMenu.AddToSort(which,WeaponMenu.GetID(which+13))
	WeaponMenu.AddToSort(which,WeaponMenu.GetID((1-which)+13))
	local equipLoc,id
	for i=0,4 do
		for j=1,GetContainerNumSlots(i) do
			id = WeaponMenu.GetID(i,j)
			_,_,_,_,_,_,_,_,equipLoc = GetItemInfo(id or "")
			if equipLoc=="INVTYPE_WEAPON" then
				WeaponMenu.AddToSort(which,id)
			end
		end
	end
	WeaponMenu.AddToSort(which,0) -- id 0 is Stop
end

function WeaponMenu.SortScrollFrameUpdate()
	local offset = FauxScrollFrame_GetOffset(WeaponMenu_SortScroll)
	local list = WeaponMenuQueue.Sort[WeaponMenu.CurrentlySorting]
	FauxScrollFrame_Update(WeaponMenu_SortScroll, list and #(list) or 0, 9, 24)

	if list and list[1] then
		local r,g,b,found
		local texture,name,quality
		local item,itemName,itemIcon
		for i=1,9 do
			item = getglobal("WeaponMenu_Sort"..i)
			itemName = getglobal("WeaponMenu_Sort"..i.."Name")
			itemIcon = getglobal("WeaponMenu_Sort"..i.."Icon")
			idx = offset+i
			if idx<=#(list) then
				name,texture,quality = WeaponMenu.GetNameByID(list[idx])
				itemIcon:SetTexture(texture)
				itemName:SetText(name)
				if quality then -- GetItemInfo may not be valid early on after patches
					r,g,b = GetItemQualityColor(quality)
					itemName:SetTextColor(r,g,b)
					itemIcon:SetVertexColor(1,1,1)
				end
				item:Show()
				if idx == WeaponMenu.SortSelected then
					WeaponMenu.LockHighlight(item)
				else
					WeaponMenu.UnlockHighlight(item)
				end
			else
				item:Hide()
			end
		end
	end
end

function WeaponMenu.LockHighlight(frame)
	if type(frame)=="string" then frame = getglobal(frame) end
	if not frame then return end
	frame.lockedHighlight = 1
	getglobal(frame:GetName().."Highlight"):Show()
end

function WeaponMenu.UnlockHighlight(frame)
	if type(frame)=="string" then frame = getglobal(frame) end
	if not frame then return end
	frame.lockedHighlight = nil
	getglobal(frame:GetName().."Highlight"):Hide()
end

-- shows tooltip for items in the sort list
function WeaponMenu.SortTooltip(self)
	local idx = FauxScrollFrame_GetOffset(WeaponMenu_SortScroll) + self:GetID()
	local name,itemLink = GetItemInfo(WeaponMenuQueue.Sort[WeaponMenu.CurrentlySorting][idx] or "")
	_,_,itemLink = string.find(itemLink or "","(item:%d+:%d+:%d+:%d+:%d+:%d+:%d+)")
	if itemLink and WeaponMenuOptions.ShowTooltips=="ON" then
		WeaponMenu.AnchorTooltip(self)
		GameTooltip:SetHyperlink(itemLink)
		GameTooltip:Show()
	else
		WeaponMenu.OnTooltip(self,"Stop Queue Here","Move this to mark the lowest weapon to auto queue.  Sometimes you may want a passive weapon with a click effect to be the end (Burst of Knowledge, Second Wind, etc).")
	end
end

function WeaponMenu.SortOnClick(self)
	WeaponMenu_SortDelay:ClearFocus()
	local idx = FauxScrollFrame_GetOffset(WeaponMenu_SortScroll) + self:GetID()
	if WeaponMenu.SortSelected == idx then
		WeaponMenu.SortSelected = 0
	else
		WeaponMenu.SortSelected = idx
	end
	WeaponMenu.SortScrollFrameUpdate()
	WeaponMenu.SortValidate()
end

-- turns move buttons on/off, moves the list to keep selected in view and keeps the sorting slot button highlighted
function WeaponMenu.SortValidate()
	local selected = WeaponMenu.SortSelected
	local list = WeaponMenuQueue.Sort[WeaponMenu.CurrentlySorting]
	WeaponMenu_MoveTop:Enable()
	WeaponMenu_MoveUp:Enable()
	WeaponMenu_MoveDown:Enable()
	WeaponMenu_MoveBottom:Enable()
	if selected==0 or #(list)<2 then -- none selected, disable all
		WeaponMenu_MoveTop:Disable()
		WeaponMenu_MoveUp:Disable()
		WeaponMenu_MoveDown:Disable()
		WeaponMenu_MoveBottom:Disable()
	elseif selected==1 then -- top selected, disable up
		WeaponMenu_MoveUp:Disable()
		WeaponMenu_MoveTop:Disable()
		WeaponMenu_MoveDown:Enable()
	elseif selected == #(list) then -- bottom selected, disable down
		WeaponMenu_MoveDown:Disable()
		WeaponMenu_MoveBottom:Disable()
	end
	local idx = FauxScrollFrame_GetOffset(WeaponMenu_SortScroll)
	if selected>0 and list[selected] and list[selected]~=0 then
		WeaponMenu_SortDelay:Show()
		WeaponMenu_SortPriority:Show()
		WeaponMenu_SortKeepEquipped:Show()
		WeaponMenu_Delete:Enable()
	else
		WeaponMenu_SortDelay:Hide()
		WeaponMenu_SortPriority:Hide()
		WeaponMenu_SortKeepEquipped:Hide()
		WeaponMenu_Delete:Disable()
	end
	local stats = WeaponMenuQueue.Stats[list[WeaponMenu.SortSelected]]
	WeaponMenu_SortDelay:SetText(stats and (stats.delay or "0") or "0")
	WeaponMenu_SortPriority:SetChecked(stats and stats.priority)
	WeaponMenu_SortKeepEquipped:SetChecked(stats and stats.keep)
			
	if not IsShiftKeyDown() and selected>0 then -- keep selected visible on list, moving thumb as needed, unless shift is down
		local parent = WeaponMenu_SortScrollScrollBar
		local offset
		if selected <= idx then
			offset = (selected==1) and 0 or (parent:GetValue() - (parent:GetHeight() / 2))
			parent:SetValue(offset)
			PlaySound("UChatScrollButton")
		elseif selected >= (idx+10) then
			offset = (selected==#(list)) and WeaponMenu_SortScroll:GetVerticalScrollRange() or (parent:GetValue() + (parent:GetHeight() / 2))
			parent:SetValue(offset)
			PlaySound("UChatScrollButton");
		end
	end
end

-- movement buttons
function WeaponMenu.SortMove(self)
	WeaponMenu_SortDelay:ClearFocus()
	local dir = ((self==WeaponMenu_MoveUp) and -1) or ((self==WeaponMenu_MoveTop) and "top") or ((self==WeaponMenu_MoveDown) and 1) or ((self==WeaponMenu_MoveBottom) and "bottom")
	local list = WeaponMenuQueue.Sort[WeaponMenu.CurrentlySorting]
	local idx1 = WeaponMenu.SortSelected -- FauxScrollFrame_GetOffset(ItemRack_Config_SortScroll) + 
	if dir then
		local idx2 = ((dir=="top") and 1) or ((dir=="bottom") and #(list)) or idx1+dir
		local temp = list[idx1]
		if tonumber(dir) then
			list[idx1] = list[idx2]
			list[idx2] = temp
		elseif dir=="top" then
			table.remove(list,idx1)
			table.insert(list,1,temp)
		elseif dir=="bottom" then
			table.remove(list,idx1)
			table.insert(list,temp)
		end
		WeaponMenu.SortSelected = idx2
	elseif self==WeaponMenu_Profiles then
		WeaponMenu.SortSelected = 0
		WeaponMenu.ShowProfiles(WeaponMenu_SortListFrame:IsVisible())
	elseif self==WeaponMenu_Delete then
		table.remove(list,idx1)
		WeaponMenu.SortSelected = 0
	end
	WeaponMenu.SortValidate()
	WeaponMenu.SortScrollFrameUpdate()
end

function WeaponMenu.SortDelay_OnTextChanged()
	local delay = tonumber(WeaponMenu_SortDelay:GetText()) or 0
	local id = WeaponMenuQueue.Sort[WeaponMenu.CurrentlySorting][WeaponMenu.SortSelected]
	WeaponMenuQueue.Stats[id] = WeaponMenuQueue.Stats[id] or {}
	WeaponMenuQueue.Stats[id].delay = delay~=0 and delay or nil
end

function WeaponMenu.SortPriority_OnClick(self)
	local check = self:GetChecked()
	local id = WeaponMenuQueue.Sort[WeaponMenu.CurrentlySorting][WeaponMenu.SortSelected]
	WeaponMenuQueue.Stats[id] = WeaponMenuQueue.Stats[id] or {}
	WeaponMenuQueue.Stats[id].priority = check
end

function WeaponMenu.SortKeepEquipped_OnClick(self)
	local check = self:GetChecked()
	local id = WeaponMenuQueue.Sort[WeaponMenu.CurrentlySorting][WeaponMenu.SortSelected]
	WeaponMenuQueue.Stats[id] = WeaponMenuQueue.Stats[id] or {}
	WeaponMenuQueue.Stats[id].keep = check
end

function WeaponMenu.TabCheck_OnClick(self)
	WeaponMenuQueue.Enabled[3-self:GetID()] = self:GetChecked()
	WeaponMenu.UpdateCombatQueue()
end

--[[ Auto queue processing ]]

function WeaponMenu.WeaponNearReady(id)
	local start,duration = GetItemCooldown(id)
	if start==0 or duration-(GetTime()-start)<=30 then
		return 1
	end
end

function WeaponMenu.CanCooldown(inv)
	local _,_,enable = GetInventoryItemCooldown("player",inv)
	return enable==1
end

-- this function quickly checks if conditions are right for a possible ProcessAutoQueue
function WeaponMenu.PeriodicQueueCheck()
	for i=0,1 do
		if WeaponMenuQueue.Enabled[i] then
			WeaponMenu.ProcessAutoQueue(i)
		end
	end
end

-- which = 0 or 1, decides if a weapon should be equipped and equips if so
function WeaponMenu.ProcessAutoQueue(which)

	local start,duration,enable = GetInventoryItemCooldown("player",13+which)
	local timeLeft = GetTime()-start
	local _,_,id,name = string.find(GetInventoryItemLink("player",13+which) or "","item:(%d+).+%[(.+)%]")
	local icon = getglobal("WeaponMenu_Weapon"..which.."Queue") 

	if not id then return end -- leave if no weapon equipped
	if IsInventoryItemLocked(13+which) then return end -- leave if slot being swapped
	if UnitCastingInfo("player") then return end -- leave if player is casting
	if WeaponMenu.PausedQueue[which] then
		icon:SetVertexColor(1,.5,.5) -- leave if SetQueue(which,"PAUSE")
		return
	end

	local buff = GetItemSpell(id)
	if buff then
		if UnitAura("player",buff) or (start>0 and (duration-timeLeft)>30 and timeLeft<1) then
			icon:SetDesaturated(1)
			return
		end
	end

	if WeaponMenuQueue.Stats[id] then
		if WeaponMenuQueue.Stats[id].keep then
			icon:SetVertexColor(1,.5,.5)
			return -- leave if .keep flag set on this item
		end
		if WeaponMenuQueue.Stats[id].delay then
			-- leave if currently equipped weapon is on cooldown for less than its delay
			if start>0 and (duration-timeLeft)>30 and timeLeft<WeaponMenuQueue.Stats[id].delay then
				icon:SetDesaturated(1)
				return
			end
		end
	end

	icon:SetDesaturated(0) -- normal queue operation, reflect that in queue inset
	icon:SetVertexColor(1,1,1)

	local name
	local ready = WeaponMenu.WeaponNearReady(GetInventoryItemLink("player",13+which))
	if ready and WeaponMenu.CombatQueue[which] then
		WeaponMenu.CombatQueue[which] = nil
		WeaponMenu.UpdateCombatQueue()
	end
	local list,rank = WeaponMenuQueue.Sort[which]
	for i=1,#(list) do
		if list[i]==0 then rank=i break end
		if ready and list[i]==id then rank=i break end
	end
	if rank then
		local bag,slot
		for i=1,rank do
			if not ready or enable==0 or (WeaponMenuQueue.Stats[list[i]] and WeaponMenuQueue.Stats[list[i]].priority) then
				if WeaponMenu.WeaponNearReady(list[i]) then
					if GetItemCount(list[i])>0 and not IsEquippedItem(list[i]) then
						_,bag,slot = WeaponMenu.FindItem(list[i])
						if bag then
							name = GetItemInfo(list[i])
							if WeaponMenu.CombatQueue[which]~=name then
								WeaponMenu.EquipWeaponByName(name,13+which)
							end
							break
						end
					end
				end
			end
		end
	end
end

--[[ WeaponMenu.SetQueue and WeaponMenu.GetQueue ]]

-- These functions are for macros and mods to configure sort queues.

-- WeaponMenu.SetQueue(0 or 1,"ON" or "OFF" or "PAUSE" or "RESUME" or "SORT"[,"sort list")
-- some examples:
-- WeaponMenu.SetQueue(1,"PAUSE") -- if queue is going, pause it
-- WeaponMenu.SetQueue(1,"RESUME") -- if queue is paused, resume it
-- WeaponMenu.SetQueue(1,"SORT","Earthstrike","Insignia of the Alliance","Diamond Flask") -- set sort
-- WeaponMenu.SetQueue(0,"SORT","Lifestone","Darkmoon Card: Heroism") -- set sort for weapon 0
-- WeaponMenu.SetQueue(1,"SORT","Pvp Profile") -- note you can replace list with a profile name
-- (a "stop the queue" is assumed at the end of the list)
function WeaponMenu.SetQueue(which,...)
	local errorstub = "|cFFBBBBBBWeaponMenu:|cFFFFFFFF "
	if not which or not tonumber(which) or which<0 or which>1 then
		DEFAULT_CHAT_FRAME:AddMessage(errorstub.."First parameter must be 0 for top weapon or 1 for bottom.")
		return
	end
	if select("#",...)<1 then
		DEFAULT_CHAT_FRAME:AddMessage(errorstub.."Second parameter is either ON, OFF, PAUSE, RESUME or the beginning of a list of weapons in a sort order.")
		return
	end
	if WeaponMenu_OptFrame:IsVisible() then
		WeaponMenu_OptFrame:Hide() -- close option frame if it's up. the mess otherwise would be scary
	end
	local cmd = select(1,...)
	if cmd=="ON" then
		WeaponMenuQueue.Enabled[which]=1
		WeaponMenu.PausedQueue[which]=nil
	elseif cmd=="OFF" then
		WeaponMenuQueue.Enabled[which]=nil
		WeaponMenu.PausedQueue[which]=nil
	elseif cmd=="PAUSE" then
		WeaponMenu.PausedQueue[which]=1
	elseif cmd=="RESUME" then
		WeaponMenu.PausedQueue[which]=nil
	elseif cmd=="SORT" and select("#",...)>1 then
		local sortidx,inv,bag,slot,id = 1
		for i in pairs(WeaponMenuQueue.Sort[which]) do
			WeaponMenuQueue.Sort[which][i] = nil
		end
--		table.setn(WeaponMenuQueue.Sort[which],0)
		local profile = WeaponMenu.GetProfileID(select(2,...))
		if profile then
			for i=2,#(WeaponMenuQueue.Profiles[profile]) do
				table.insert(WeaponMenuQueue.Sort[which],WeaponMenuQueue.Profiles[profile][i])
			end
		else
			for i=2,select("#",...) do
				inv,bag,slot = WeaponMenu.FindItem(select(i,...),1) -- include inventory
				if inv then
					table.insert(WeaponMenuQueue.Sort[which],WeaponMenu.GetID(inv))
				elseif bag then
					table.insert(WeaponMenuQueue.Sort[which],WeaponMenu.GetID(bag,slot))
				else
					DEFAULT_CHAT_FRAME:AddMessage(errorstub.."Weapon or profile \""..select(i,...).."\" not found.")
				end
			end
			table.insert(WeaponMenuQueue.Sort[which],0)
		end
	else
		DEFAULT_CHAT_FRAME:AddMessage(errorstub.." Expected ON, OFF, PAUSE, RESUME or SORT+list")
	end

	WeaponMenu.ReflectQueueEnabled()
	WeaponMenu.UpdateCombatQueue()
end

-- returns 1 or nil if queue is enabled, and a table containing an ordered list of the weapons
function WeaponMenu.GetQueue(which)
	if not which or not tonumber(which) or which<0 or which>1 then
		DEFAULT_CHAT_FRAME:AddMessage("|cFFBBBBBBWeaponMenu.GetQueue:|cFFFFFFFF Parameter must be 0 for top weapon or 1 for bottom.")
		return
	end
	local weaponList,name = {}
	for i=1,#(WeaponMenuQueue.Sort[which]) do
		name = WeaponMenu.GetNameByID(WeaponMenuQueue.Sort[which][i])
		table.insert(weaponList,name)
	end
	return WeaponMenuQueue.Enabled[which],weaponList
end

--[[ Profiles ]]

-- add="add" or "remove" to add or remove "frame" from UISpecialFrames
function WeaponMenu.Escable(frame,add)
	local found
	for i in pairs(UISpecialFrames) do
		found = found or (UISpecialFrames[i]==frame and i)
	end
	if not found and add=="add" then
		table.insert(UISpecialFrames,frame)
	elseif found and add=="remove" then
		table.remove(UISpecialFrames,found)
	end
end

-- shows profile if show non-nil. WeaponMenu_ProfilesFrame has an OnHide that calls this with nil
function WeaponMenu.ShowProfiles(show)
	local normalTexture = WeaponMenu_Profiles:GetNormalTexture()
	local pushedTexture = WeaponMenu_Profiles:GetPushedTexture()
	if show then
		WeaponMenu_SortListFrame:Hide()
		WeaponMenu_ProfilesFrame:Show()
		normalTexture:SetTexCoord(.875,1,.25,.375)
		pushedTexture:SetTexCoord(.75,.875,.25,.375)
		WeaponMenu.Escable("WeaponMenu_ProfilesFrame","add")
		WeaponMenu.Escable("WeaponMenu_OptFrame","remove")
	else
		WeaponMenu_SortListFrame:Show()
		WeaponMenu_ProfilesFrame:Hide()
		pushedTexture:SetTexCoord(.875,1,.25,.375)
		normalTexture:SetTexCoord(.75,.875,.25,.375)
		WeaponMenu.Escable("WeaponMenu_ProfilesFrame","remove")
		WeaponMenu.Escable("WeaponMenu_OptFrame","add")
	end
end

function WeaponMenu.ProfilesFrame_OnHide()
	PlaySound("GAMEGENERICBUTTONPRESS")
	WeaponMenu.ResetProfileSelected()
	WeaponMenu.ShowProfiles(nil)
end

function WeaponMenu.ResetProfileSelected()
	WeaponMenu.ProfileSelected = nil
	WeaponMenu_ProfileName:SetText("")
	WeaponMenu.ProfileScrollFrameUpdate()
	WeaponMenu.ValidateProfile()
end

function WeaponMenu.ProfileScrollFrameUpdate()
	local offset = FauxScrollFrame_GetOffset(WeaponMenu_ProfileScroll)
	local list = WeaponMenuQueue.Profiles
	FauxScrollFrame_Update(WeaponMenu_ProfileScroll, #(list) or 0, 7, 20)

	local item
	for i=1,7 do
		idx = offset+i
		item = getglobal("WeaponMenu_Profile"..i)
		if idx<=#(list) then
			getglobal("WeaponMenu_Profile"..i.."Name"):SetText(list[idx][1])
			item:Show()
			if WeaponMenu.ProfileSelected==idx then
				item:LockHighlight()
			else
				item:UnlockHighlight()
			end
		else
			item:Hide()
		end
	end

	if #(list)==0 then
		WeaponMenu_Profile1Name:SetText("No profiles saved yet.")
		WeaponMenu_Profile1:Show()
		WeaponMenu_Profile1:UnlockHighlight()
	end

end

function WeaponMenu.ProfileList_OnClick(self)
	if #(WeaponMenuQueue.Profiles)>0 then
		local idx = self:GetID() + FauxScrollFrame_GetOffset(WeaponMenu_ProfileScroll)
		if WeaponMenu.ProfileSelected == idx then
			WeaponMenu.ProfileSelected = nil
			WeaponMenu_ProfileName:SetText("")
		else
			WeaponMenu.ProfileSelected = idx
			WeaponMenu_ProfileName:SetText(WeaponMenuQueue.Profiles[idx][1])
		end
		WeaponMenu.ProfileScrollFrameUpdate()
		WeaponMenu.ValidateProfile()
	end
end

function WeaponMenu.GetProfileID(name)
	for i=1,#(WeaponMenuQueue.Profiles) do
		if WeaponMenuQueue.Profiles[i][1]==name then
			return i
		end
	end
end

function WeaponMenu.ValidateProfile()
	local name = WeaponMenu_ProfileName:GetText() or ""
	WeaponMenu_ProfilesDelete:Disable()
	WeaponMenu_ProfilesLoad:Disable()
	WeaponMenu_ProfilesSave:Disable()
	if WeaponMenu.GetProfileID(name) then
		WeaponMenu_ProfilesDelete:Enable()
		WeaponMenu_ProfilesLoad:Enable()
	end
	if strlen(name)>0 then
		WeaponMenu_ProfilesSave:Enable()
	end
end

function WeaponMenu.ProfileName_OnTextChanged()
	WeaponMenu.ProfileSelected = WeaponMenu.GetProfileID(WeaponMenu_ProfileName:GetText())
	WeaponMenu.ProfileScrollFrameUpdate()
	WeaponMenu.ValidateProfile()
end

function WeaponMenu.ProfilesButton_OnClick(self)
	local idx = WeaponMenu.ProfileSelected
	local name = WeaponMenu_ProfileName:GetText() or ""

	if self==WeaponMenu_ProfilesDelete then
		if idx and WeaponMenuQueue.Profiles[idx] then
			table.remove(WeaponMenuQueue.Profiles,idx)
		end
		WeaponMenu.ResetProfileSelected()
	elseif self==WeaponMenu_ProfilesSave then
		if idx and WeaponMenuQueue.Profiles[idx] then
			table.remove(WeaponMenuQueue.Profiles,idx)
		end
		table.insert(WeaponMenuQueue.Profiles,1,{name})
		local list = WeaponMenuQueue.Sort[WeaponMenu.CurrentlySorting]
		local save = WeaponMenuQueue.Profiles[1]
		for i=1,#(list) do
			table.insert(save,list[i])
			if list[i]==0 then
				break
			end
		end
		WeaponMenu_ProfilesFrame:Hide()
	elseif self==WeaponMenu_ProfilesLoad then
		WeaponMenu.LoadProfile(WeaponMenu.CurrentlySorting,idx)
	elseif self==WeaponMenu_ProfilesCancel then
		WeaponMenu_ProfilesFrame:Hide()
	end
end

function WeaponMenu.ProfileList_OnDoubleClick(self)
	if #(WeaponMenuQueue.Profiles)>0 then
		local idx = self:GetID() + FauxScrollFrame_GetOffset(WeaponMenu_ProfileScroll)
		if WeaponMenuQueue.Profiles[idx] then
			WeaponMenu.LoadProfile(WeaponMenu.CurrentlySorting,idx)
		end
	end
end

function WeaponMenu.LoadProfile(which,idx)
	local list = WeaponMenuQueue.Sort[which]
	local load = WeaponMenuQueue.Profiles[idx]
	for i in pairs(list) do
		list[i] = nil
	end
--	table.setn(list,0)
	for i=2,#(load) do
		table.insert(list,load[i])
	end
	WeaponMenu_ProfilesFrame:Hide()
	WeaponMenu.OpenSort(which)
	if WeaponMenuOptions.HideOnLoad=="ON" then
		WeaponMenu_OptFrame:Hide()
	end
end
