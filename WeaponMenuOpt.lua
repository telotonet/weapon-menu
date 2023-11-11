--[[ WeaponMenuOpt.lua : Options and sort window for WeaponMenu ]]

WeaponMenu.CheckOptInfo = {
{"ShowIcon","ON","Minimap Button","Show or hide minimap button."},
{"SquareMinimap","OFF","Square Minimap","Move minimap button as if around a square minimap.","ShowIcon"},
{"CooldownCount","OFF","Cooldown Numbers","Display time remaining on cooldowns ontop of the button."},
{"TooltipFollow","OFF","At Mouse","Display all tooltips near the mouse.","ShowTooltips"},
{"KeepOpen","OFF","Keep Menu Open","Keep menu open at all times."},
{"KeepDocked","ON","Keep Menu Docked","Keep menu docked at all times."},
{"Notify","OFF","Notify When Ready","Sends an overhead notification when a weapon's cooldown is complete."},
{"DisableToggle","OFF","Disable Toggle","Disables the minimap button's ability to toggle the weapon frame.","ShowIcon"},
{"NotifyChatAlso","OFF","Notify Chat Also","Sends notifications through chat also."},
{"Locked","OFF","Lock Windows","Prevents the windows from being moved, resized or rotated."},
{"ShowTooltips","ON","Show Tooltips","Shows tooltips."},
{"NotifyThirty","ON","Notify At 30 sec","Sends an overhead notification when a weapon has 30 seconds left on cooldown."},
{"MenuOnShift","OFF","Menu On Shift","Check this to prevent the menu appearing unless Shift is held."},
{"TinyTooltips","OFF","Tiny Tooltips","Shrink weapon tooltips to only their name, charges and cooldown.","ShowTooltips"},
{"SetColumns","OFF","Wrap at: ","Define how many weapons before the menu will wrap to the next row.\n\nUncheck to let WeaponMenu choose how to wrap the menu."},
{"LargeCooldown","ON","Large Numbers","Display the cooldown time in a larger font.","CooldownCount"},
{"ShowHotKeys","ON","Show Key Bindings","Display the key bindings over the equipped weapons."},
{"StopOnSwap","OFF","Stop Queue On Swap","Swapping a passive weapon stops an auto queue.  Check this to also stop the auto queue when a clickable weapon is manually swapped in via WeaponMenu.  This will have the most use to those with frequent weapons marked Priority."},
{"HideOnLoad","OFF","Close On Profile Load","Check this to dismiss this window when you load a profile."},
{"RedRange","OFF","Red Out of Range","Check this to red out worn weapons that are out of range to a valid target.  ie, Gnomish Death Ray and Gnomish Net-O-Matic."},
{"MenuOnRight","OFF","Menu On Right-Click","Check this to prevent the menu from appearing until either worn weapon is right-clicked.\n\nNOTE: This setting CANNOT be changed while in combat."},
}

-- table.insert(WeaponMenu.CheckOptInfo,)

WeaponMenu.TooltipInfo = {
{"WeaponMenu_LockButton","Lock Windows","Prevents the windows from being moved, resized or rotated."},
{"WeaponMenu_Weapon0Check","Top Weapon Auto Queue","Check this to enable auto queue for this weapon slot.  You can also Alt+Click the weapon slot to toggle Auto Queue."},
{"WeaponMenu_Weapon1Check","Bottom Weapon Auto Queue","Check this to enable auto queue for this weapon slot.  You can also Alt+Click the weapon slot to toggle Auto Queue."},
{"WeaponMenu_SortPriority","High Priority","When checked, this weapon will be swapped in as soon as possible, whether the equipped weapon is on cooldown or not.\n\nWhen unchecked, this weapon will not equip over one already worn that's not on cooldown."},
{"WeaponMenu_SortDelay","Swap Delay","This is the time (in seconds) before a weapon will be swapped out.  ie, for Earthstrike you want 20 seconds to get the full 20 second effect of the buff."},
{"WeaponMenu_SortKeepEquipped","Pause Queue","Check this to suspend the auto queue while this weapon is equipped. ie, for Carrot on a Stick if you have a mod to auto-equip it to a slot with Auto Queue active."},
{"WeaponMenu_Profiles","Profiles","Here you can load or save auto queue profiles."},
{"WeaponMenu_Delete","Delete","Remove this weapon from the list.  Weapons further down the list don't affect performance at all.  This option is merely to keep the list managable. Note: Weapons in your bags will return to end of the list."},
{"WeaponMenu_ProfilesDelete","Delete Profile","Remove this profile."},
{"WeaponMenu_ProfilesLoad","Load Profile","Load a queue order for the selected weapon slot.  You can double-click a profile to load it also."},
{"WeaponMenu_ProfilesSave","Save Profile","Save the queue order from the selected weapon slot.  Either weapon slot can use saved profiles."},
{"WeaponMenu_ProfileName","Profile Name","Enter a name to call the profile.  When saved, you can load this profile to either weapon slot."},
}

function WeaponMenu.InitOptions()
	WeaponMenu.CreateTimer("DragMinimapButton",WeaponMenu.DragMinimapButton,0,1)
	WeaponMenu.MoveMinimapButton()
	local item
	for i=1,#(WeaponMenu.CheckOptInfo) do
		item = getglobal("WeaponMenu_Opt"..WeaponMenu.CheckOptInfo[i][1].."Text")
		if item then
			item:SetText(WeaponMenu.CheckOptInfo[i][3])
			item:SetTextColor(.95,.95,.95)
		end
	end
	WeaponMenu.Tab_OnClick(1)
	table.insert(UISpecialFrames,"WeaponMenu_OptFrame")
	WeaponMenu_Title:SetText("WeaponMenu "..WeaponMenu_Version)

	WeaponMenu_OptFrame:SetBackdropBorderColor(.3,.3,.3,1)
	WeaponMenu_SubOptFrame:SetBackdropBorderColor(.3,.3,.3,1)
	if WeaponMenu.QueueInit then
		WeaponMenu.QueueInit()
		WeaponMenu_Tab1:Show()
		WeaponMenu_OptFrame:SetHeight(326)
		WeaponMenu_SubOptFrame:SetPoint("TOPLEFT",WeaponMenu_OptFrame,"TOPLEFT",8,-50)
	else
		WeaponMenu_OptStopOnSwap:Hide() -- remove StopOnSwap option if queue not loaded
		WeaponMenu_Tab1:Hide() -- hide options tab if it's only tab
		WeaponMenu_OptFrame:SetHeight(300)
		WeaponMenu_SubOptFrame:SetPoint("TOPLEFT",WeaponMenu_OptFrame,"TOPLEFT",8,-24)
	end
	WeaponMenu_OptColumnsSlider:SetValue(WeaponMenuOptions.Columns)
	WeaponMenu_OptMainScaleSlider:SetValue(WeaponMenuPerOptions.MainScale)
	WeaponMenu_OptMenuScaleSlider:SetValue(WeaponMenuPerOptions.MenuScale)
	WeaponMenu.ReflectLock()
	WeaponMenu.ReflectCooldownFont()
	WeaponMenu.KeyBindingsChanged()
end

function WeaponMenu.ToggleFrame(frame)
	if frame:IsVisible() then
		frame:Hide()
	else
		frame:Show()
	end
end

function WeaponMenu.OptFrame_OnShow()
	WeaponMenu.ValidateChecks()
	if WeaponMenu.CurrentlySorting then
		WeaponMenu.PopulateSort(WeaponMenu.CurrentlySorting)
	end
end

--[[ Minimap button ]]

function WeaponMenu.MoveMinimapButton()
	local xpos,ypos
	if WeaponMenuOptions.SquareMinimap=="ON" then
		xpos = 110 * cos(WeaponMenuOptions.IconPos or 0)
		ypos = 110 * sin(WeaponMenuOptions.IconPos or 0)
		xpos = math.max(-82,math.min(xpos,84))
		ypos = math.max(-86,math.min(ypos,82))
	else
		xpos = 80*cos(WeaponMenuOptions.IconPos or 0)
		ypos = 80*sin(WeaponMenuOptions.IconPos or 0)
	end
	WeaponMenu_IconFrame:SetPoint("TOPLEFT","Minimap","TOPLEFT",52-xpos,ypos-52)
	if WeaponMenuOptions.ShowIcon=="ON" then
		WeaponMenu_IconFrame:Show()
	else
		WeaponMenu_IconFrame:Hide()
	end
end

function WeaponMenu.DragMinimapButton()
	local xpos,ypos = GetCursorPosition()
	local xmin,ymin = Minimap:GetLeft() or 400, Minimap:GetBottom() or 400
	xpos = xmin-xpos/Minimap:GetEffectiveScale()+70
	ypos = ypos/Minimap:GetEffectiveScale()-ymin-70
	WeaponMenuOptions.IconPos = math.deg(math.atan2(ypos,xpos))
	WeaponMenu.MoveMinimapButton()
end

function WeaponMenu.MinimapButton_OnClick()
	PlaySound("GAMEGENERICBUTTONPRESS")
	if IsShiftKeyDown() then
		WeaponMenuOptions.Locked = WeaponMenuOptions.Locked=="ON" and "OFF" or "ON"
		WeaponMenu.ReflectLock()
	elseif IsAltKeyDown() and WeaponMenu.QueueInit then
		if arg1=="LeftButton" then
			WeaponMenuQueue.Enabled[0] = not WeaponMenuQueue.Enabled[0] and 1 or nil
		elseif arg1=="RightButton" then
			WeaponMenuQueue.Enabled[1] = not WeaponMenuQueue.Enabled[1] and 1 or nil
		end
		WeaponMenu.ReflectQueueEnabled()
		WeaponMenu.UpdateCombatQueue()
	else
		if arg1=="LeftButton" and WeaponMenuOptions.DisableToggle=="OFF" then
			WeaponMenu.ToggleFrame(WeaponMenu_MainFrame)
		else
			WeaponMenu.ToggleFrame(WeaponMenu_OptFrame)
		end
	end
end

--[[ CheckButton ]]

function WeaponMenu.ValidateChecks()
	local check,button
	for i=1,#(WeaponMenu.CheckOptInfo) do
		check = WeaponMenu.CheckOptInfo[i]
		button = getglobal("WeaponMenu_Opt"..check[1])
		if button then
			button:SetChecked(WeaponMenuOptions[check[1]]=="ON")
			if check[5] then
				if WeaponMenuOptions[check[5]]=="ON" then
					button:Enable()
					getglobal("WeaponMenu_Opt"..check[1].."Text"):SetTextColor(.95,.95,.95)
				else
					button:Disable()
					getglobal("WeaponMenu_Opt"..check[1].."Text"):SetTextColor(.5,.5,.5)
				end
			end
		end
	end
	WeaponMenu_OptColumnsSlider:SetAlpha((WeaponMenuOptions.SetColumns=="ON") and 1 or .5)
	WeaponMenu_OptColumnsSlider:EnableMouse((WeaponMenuOptions.SetColumns=="ON") and 1 or 0)
	WeaponMenu_OptColumnsSlider:SetValue(WeaponMenuOptions.Columns)
end

function WeaponMenu.OptColumnsSlider_OnValueChanged(self)
	if WeaponMenuOptions then
		WeaponMenuOptions.Columns = self:GetValue()
		WeaponMenu_OptColumnsSliderText:SetText(WeaponMenuOptions.Columns.." weapons")
		if WeaponMenu_MenuFrame:IsVisible() then
			WeaponMenu.BuildMenu()
		end
	end
end

function WeaponMenu.OptMainScaleSlider_OnValueChanged(self)
	if WeaponMenuPerOptions then
		WeaponMenuPerOptions.MainScale = self:GetValue()
		WeaponMenu_OptMainScaleSliderText:SetText(format("Main Scale: %.2f",WeaponMenuPerOptions.MainScale))
		WeaponMenu_MainFrame:SetScale(WeaponMenuPerOptions.MainScale)
	end
end

function WeaponMenu.OptMenuScaleSlider_OnValueChanged(self)
	if WeaponMenuPerOptions then
		WeaponMenuPerOptions.MenuScale = self:GetValue()
		WeaponMenu_OptMenuScaleSliderText:SetText(format("Menu Scale: %.2f",WeaponMenuPerOptions.MenuScale))
		WeaponMenu_MenuFrame:SetScale(WeaponMenuPerOptions.MenuScale)
	end
end

function WeaponMenu.CheckButton_OnClick(self)
	local _,_,var = string.find(self:GetName(),"WeaponMenu_Opt(.+)")
	if WeaponMenuOptions[var] then
		WeaponMenuOptions[var] = self:GetChecked() and "ON" or "OFF"
		PlaySound(self:GetChecked() and "igMainMenuOptionCheckBoxOn" or "igMainMenuOptionCheckBoxOff")
		WeaponMenu.ValidateChecks()
	end

	if self==WeaponMenu_OptCooldownCount then
		WeaponMenu.WriteWornCooldowns()
		WeaponMenu.WriteMenuCooldowns()
	elseif self==WeaponMenu_OptLocked then
		WeaponMenu.DockWindows()
		WeaponMenu.ReflectLock()
	elseif self==WeaponMenu_OptKeepOpen or self==WeaponMenu_OptSetColumns then
		if WeaponMenuOptions.KeepOpen=="ON" then
			WeaponMenu.BuildMenu()
		end
	elseif self==WeaponMenu_OptKeepDocked then
		WeaponMenu.DockWindows()
	elseif self==WeaponMenu_OptLargeCooldown then
		WeaponMenu.ReflectCooldownFont()
	elseif self==WeaponMenu_OptSquareMinimap then
		WeaponMenu.MoveMinimapButton()
	elseif self==WeaponMenu_OptShowHotKeys then
		WeaponMenu.KeyBindingsChanged()
	elseif self==WeaponMenu_OptShowIcon then
		WeaponMenu.MoveMinimapButton()
	elseif self==WeaponMenu_OptRedRange then
		WeaponMenu.ReflectRedRange()
	elseif self==WeaponMenu_OptMenuOnRight then
		WeaponMenu.ReflectMenuOnRight()
	end
end

function WeaponMenu.ReflectLock()
	local c = WeaponMenuOptions.Locked=="ON" and 0 or .5
	WeaponMenu_OptFrame:SetBackdropBorderColor(c,c,c,1)
	WeaponMenu_MainFrame:SetBackdropColor(c,c,c,c)
	WeaponMenu_MainFrame:SetBackdropBorderColor(c,c,c,c*2)
	WeaponMenu_MenuFrame:SetBackdropColor(c,c,c,c)
	WeaponMenu_MenuFrame:SetBackdropBorderColor(c,c,c,c*2)
	WeaponMenu_MenuFrame:EnableMouse(c*2)
	WeaponMenu_OptLocked:SetChecked(1-c*2)
	local normalTexture = WeaponMenu_LockButton:GetNormalTexture()
	local pushedTexture = WeaponMenu_LockButton:GetPushedTexture()
	if c==0 then
		normalTexture:SetTexCoord(.875,1,.125,.25)
		pushedTexture:SetTexCoord(.75,.875,.125,.25)
	else
		normalTexture:SetTexCoord(.75,.875,.125,.25)
		pushedTexture:SetTexCoord(.875,1,.125,.25)
	end
end

function WeaponMenu.ReflectCooldownFont()
	WeaponMenu.SetCooldownFont("WeaponMenu_Weapon0")
	WeaponMenu.SetCooldownFont("WeaponMenu_Weapon1")
	for i=1,30 do
		WeaponMenu.SetCooldownFont("WeaponMenu_Menu"..i)
	end
end

function WeaponMenu.SetCooldownFont(button)
	local item = getglobal(button.."Time")
	if WeaponMenuOptions.LargeCooldown=="ON" then
		item:SetFont("Fonts\\FRIZQT__.TTF",16,"OUTLINE")
		item:SetTextColor(1,.82,0,1)
		item:ClearAllPoints()
		item:SetPoint("CENTER",button,"CENTER")
	else
		item:SetFont("Fonts\\ARIALN.TTF",14,"OUTLINE")
		item:SetTextColor(1,1,1,1)
		item:ClearAllPoints()
		item:SetPoint("BOTTOM",button,"BOTTOM")
	end
end


--[[ Titlebar buttons ]]

function WeaponMenu.SmallButton_OnClick(self)
	PlaySound("igMainMenuOptionCheckBoxOn")
	if self==WeaponMenu_CloseButton then
		WeaponMenu_OptFrame:Hide()
	elseif self==WeaponMenu_LockButton then
		WeaponMenuOptions.Locked = (WeaponMenuOptions.Locked=="ON") and "OFF" or "ON"
		WeaponMenu.DockWindows()
		WeaponMenu.ReflectLock()
	end
end

--[[ Tabs ]]

function WeaponMenu.Tab_OnClick(id)
	PlaySound("GAMEGENERICBUTTONPRESS")
	local tab
	if WeaponMenu_ProfilesFrame then
		WeaponMenu_ProfilesFrame:Hide()
	end
	for i=1,3 do
		tab = getglobal("WeaponMenu_Tab"..i)
		if tab then
			tab:UnlockHighlight()
		end
	end
	getglobal("WeaponMenu_Tab"..id):LockHighlight()
	if id==1 then
		WeaponMenu_SubOptFrame:Show()
		if WeaponMenu_SubQueueFrame then
			WeaponMenu_SubQueueFrame:Hide()
		end
	else
		WeaponMenu_SubOptFrame:Hide()
		WeaponMenu_SubQueueFrame:Show()
		WeaponMenu.OpenSort(3-id)
	end
end
