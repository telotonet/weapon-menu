--[[ WeaponMenu 3.81 ]]--

WeaponMenu = {}

-- localized strings required to support engineering bags
WeaponMenu.BAG = "Bag" -- 7th return of GetItemInfo on a normal bag
WeaponMenu.ENGINEERING_BAG = "Engineering Bag" -- 7th return of GetItemInfo on an engineering bag
WeaponMenu.TRADE_GOODS = "Trade Goods" -- 6th return of GetItemInfo on most engineered weapons
WeaponMenu.DEVICES = "Devices" -- 7th return of GetItemInfo on most engineered weapons
WeaponMenu.REQUIRES_ENGINEERING = "Requires Engineering" -- from tooltip when GetItemInfo ambiguous

function WeaponMenu.LoadDefaults()

	WeaponMenuOptions = WeaponMenuOptions or {
		IconPos = -100,				-- angle of initial minimap icon position
		ShowIcon = "ON",			-- whether to show the minimap button
		SquareMinimap = "OFF",		-- whether the minimap is square instead of circular
		CooldownCount = "OFF",		-- whether to display numerical cooldown counters
		LargeCooldown = "ON",		-- whether cooldown numbers are large or small
		TooltipFollow = "OFF",		-- whether tooltips follow the mouse
		KeepOpen = "OFF",			-- whether menu hides after use
		KeepDocked = "ON",			-- whether to keep menu docked at all times
		Notify = "OFF",				-- whether a message appears when a weapon is ready
		DisableToggle="OFF",		-- whether minimap button toggles weapons
		NotifyUsedOnly="OFF",		-- whether notify happens only on weapons used
		NotifyChatAlso="OFF",		-- whether to send notify to chat also
		Locked = "OFF",				-- whether windows can be moved/scaled/rotated
		ShowTooltips = "ON",		-- whether to display tooltips at all
		NotifyThirty = "OFF",		-- whether to notify cooldowns at 30 seconds instead of 0
		MenuOnShift = "OFF",		-- whether menu requires Shift to display
		TinyTooltips = "OFF",		-- whether tooltips display only name and cooldown
		SetColumns = "OFF",			-- whether number of columns in menu is chosen automatically
		Columns = 4,				-- if SetColumns "ON", number of columns before menu wraps
		ShowHotKeys = "OFF",		-- whether hotkeys show on weapons
		StopOnSwap = "OFF",			-- whether to stop auto queue on all manual swaps
		RedRange = "OFF",			-- whether to monitor and red out out of range weapons
		MenuOnRight = "OFF",		-- whether to open menu with right-click
	}

	WeaponMenuPerOptions = WeaponMenuPerOptions or {
		MainDock = "BOTTOMRIGHT",	-- corner of main window docked to
		MenuDock = "BOTTOMLEFT",	-- corner menu window is docked from
		MainOrient = "HORIZONTAL",	-- direction of main window
		MenuOrient = "VERTICAL",	-- direction of menu window
		XPos = 400,					-- left edge of main window
		YPos = 400,					-- top edge of main window
		MainScale = 1,				-- scaling of main window
		MenuScale = 1,				-- scaling of menu window
		Visible="ON",				-- whether to display the weapons
		FirstUse = true,			-- whether this is the first time this user has used the mod
		ItemsUsed = {},				-- table of weapons used and their cooldown status
		Alpha = 1,					-- alpha of both windows
		Hidden = {},				-- table of weapons hidden
	}
end

--[[ Misc Variables ]]--

WeaponMenu_Version = 3.81
BINDING_HEADER_WEAPONMENU = "WeaponMenu"
setglobal("BINDING_NAME_CLICK WeaponMenu_Weapon0:LeftButton","Use Top Weapon")
setglobal("BINDING_NAME_CLICK WeaponMenu_Weapon1:LeftButton","Use Bottom Weapon")

WeaponMenu.MaxWeapons = 30 -- add more to WeaponMenu_MenuFrame if this changes
WeaponMenu.BaggedWeapons = {} -- indexed by number, 1-30 of weapons in the menu
WeaponMenu.NumberOfWeapons = 0 -- number of weapons in the menu
WeaponMenu.CombatQueue = {} -- [0] or [1] = name of weapon queued for slot 0 or 1
WeaponMenu.Corners = {"TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT"}

--[[ Local functions ]]--

-- dock-dependant offset and directions: MainDock..MenuDock
-- x/yoff   = offset MenuFrame is positioned to MainFrame
-- x/ydir   = direction weapons are added to menu
-- x/ystart = starting offset when building a menu, relativePoint MenuDock
WeaponMenu.DockStats = { ["TOPRIGHTTOPLEFT"] =		 { xoff=-4, yoff=0,  xdir=1,  ydir=-1, xstart=8,   ystart=-8 },
					 ["BOTTOMRIGHTBOTTOMLEFT"] = { xoff=-4, yoff=0,  xdir=1,  ydir=1,  xstart=8,   ystart=44 },
					 ["TOPLEFTTOPRIGHT"] =		 { xoff=4,  yoff=0,  xdir=-1, ydir=-1, xstart=-44, ystart=-8 },
					 ["BOTTOMLEFTBOTTOMRIGHT"] = { xoff=4,  yoff=0,  xdir=-1, ydir=1,  xstart=-44, ystart=44 },
					 ["TOPRIGHTBOTTOMRIGHT"] =   { xoff=0,  yoff=-4, xdir=-1, ydir=1,  xstart=-44,  ystart=44 },
					 ["BOTTOMRIGHTTOPRIGHT"] =   { xoff=0,  yoff=4,	 xdir=-1, ydir=-1, xstart=-44,  ystart=-8 },
					 ["TOPLEFTBOTTOMLEFT"] =	 { xoff=0,  yoff=-4, xdir=1,  ydir=1,  xstart=8,   ystart=44 },
					 ["BOTTOMLEFTTOPLEFT"] =	 { xoff=0,  yoff=4,  xdir=1,  ydir=-1, xstart=8,   ystart=-8 } }

-- returns offset and direction depending on current docking. ie: WeaponMenu.DockInfo("xoff")
function WeaponMenu.DockInfo(arg1)
	local anchor = WeaponMenuPerOptions.MainDock..WeaponMenuPerOptions.MenuDock
	if WeaponMenu.DockStats[anchor] and arg1 and WeaponMenu.DockStats[anchor][arg1] then
		return WeaponMenu.DockStats[anchor][arg1]
	else
		return 0
	end
end

-- hide the docking markers
function WeaponMenu.ClearDocking()
	for i=1,4 do
		getglobal("WeaponMenu_MainDock_"..WeaponMenu.Corners[i]):Hide()
		getglobal("WeaponMenu_MenuDock_"..WeaponMenu.Corners[i]):Hide()
	end
end

-- returns true if the two values are close to each other
function WeaponMenu.Near(arg1,arg2)
	return (math.max(arg1,arg2)-math.min(arg1,arg2))<15
end

-- moves the MenuFrame to the dock position against MainFrame
function WeaponMenu.DockWindows()
	WeaponMenu.ClearDocking()
	if WeaponMenuOptions.KeepDocked=="ON" then
		WeaponMenu_MenuFrame:ClearAllPoints()
		if WeaponMenuOptions.Locked=="OFF" then
			WeaponMenu_MenuFrame:SetPoint(WeaponMenuPerOptions.MenuDock,"WeaponMenu_MainFrame",WeaponMenuPerOptions.MainDock,WeaponMenu.DockInfo("xoff"),WeaponMenu.DockInfo("yoff"))
		else
			WeaponMenu_MenuFrame:SetPoint(WeaponMenuPerOptions.MenuDock,"WeaponMenu_MainFrame",WeaponMenuPerOptions.MainDock,WeaponMenu.DockInfo("xoff")*3,WeaponMenu.DockInfo("yoff")*3)
		end
	end
	if WeaponMenu_MenuFrame:IsVisible() then
		WeaponMenu.BuildMenu()
	end
end

-- displays windows vertically or horizontally
function WeaponMenu.OrientWindows()
	if WeaponMenuPerOptions.MainOrient=="HORIZONTAL" then
		WeaponMenu_MainFrame:SetWidth(92)
		WeaponMenu_MainFrame:SetHeight(52)
	else
		WeaponMenu_MainFrame:SetWidth(52)
		WeaponMenu_MainFrame:SetHeight(92)
	end
end

-- scan inventory and build MenuFrame
function WeaponMenu.BuildMenu()

	if not IsShiftKeyDown() and WeaponMenuOptions.MenuOnShift=="ON" then
		return
	end

	local idx,i,j,k,texture = 1
	local itemLink,itemID,itemName,equipSlot,itemTexture

	-- go through bags and gather weapons into .BaggedWeapons
	for i=0,4 do
		for j=1,GetContainerNumSlots(i) do
			itemLink = GetContainerItemLink(i,j)
			
			if itemLink then
				_,_,itemID,itemName = string.find(GetContainerItemLink(i,j) or "","item:(%d+).+%[(.+)%]")
				_,_,_,_,_,_,_,_,equipSlot,itemTexture = GetItemInfo(itemID or "")
				if (equipSlot=="INVTYPE_WEAPON" or equipSlot=="INVTYPE_2HWEAPON" or equipSlot=="INVTYPE_SHIELD") and (IsAltKeyDown() or not WeaponMenuPerOptions.Hidden[itemID]) then
					if not WeaponMenu.BaggedWeapons[idx] then
						WeaponMenu.BaggedWeapons[idx] = {}
					end
					WeaponMenu.BaggedWeapons[idx].id = itemID
					WeaponMenu.BaggedWeapons[idx].bag = i
					WeaponMenu.BaggedWeapons[idx].slot = j
					WeaponMenu.BaggedWeapons[idx].name = itemName
					WeaponMenu.BaggedWeapons[idx].texture = itemTexture
					idx = idx + 1
				end
			end
		end
	end
	WeaponMenu.NumberOfWeapons = math.min(idx-1,WeaponMenu.MaxWeapons)

	if WeaponMenu.NumberOfWeapons<1 then
		-- user has no bagged weapons :(
		WeaponMenu_MenuFrame:Hide()
	else
		-- display weapons outward from docking point
		local col,row,xpos,ypos = 0,0,WeaponMenu.DockInfo("xstart"),WeaponMenu.DockInfo("ystart")
		local max_cols = 1

		if WeaponMenu.NumberOfWeapons>24 then
			max_cols = 5
		elseif WeaponMenu.NumberOfWeapons>18 then
			max_cols = 4
		elseif WeaponMenu.NumberOfWeapons>12 then
			max_cols = 3
		elseif WeaponMenu.NumberOfWeapons>4 then
			max_cols = 2
		end
		if WeaponMenuOptions.SetColumns=="ON" and WeaponMenuOptions.Columns then
			max_cols = WeaponMenuOptions.Columns
		end

		local item,icon
		for i=1,WeaponMenu.NumberOfWeapons do
			item = getglobal("WeaponMenu_Menu"..i)
			icon = getglobal("WeaponMenu_Menu"..i.."Icon")
			icon:SetTexture(WeaponMenu.BaggedWeapons[i].texture)
			if WeaponMenuPerOptions.Hidden[WeaponMenu.BaggedWeapons[i].id] then
				icon:SetDesaturated(1)
			else
				icon:SetDesaturated(0)
			end
			item:SetPoint("TOPLEFT","WeaponMenu_MenuFrame",WeaponMenuPerOptions.MenuDock,xpos,ypos)

			if WeaponMenuPerOptions.MenuOrient=="VERTICAL" then
				xpos = xpos + WeaponMenu.DockInfo("xdir")*40
				col = col + 1
				if col==max_cols then
					xpos = WeaponMenu.DockInfo("xstart")
					col = 0
					ypos = ypos + WeaponMenu.DockInfo("ydir")*40
					row = row + 1
				end
				item:Show()
			else
				ypos = ypos + WeaponMenu.DockInfo("ydir")*40
				col = col + 1
				if col==max_cols then
					ypos = WeaponMenu.DockInfo("ystart")
					col = 0
					xpos = xpos + WeaponMenu.DockInfo("xdir")*40
					row = row + 1
				end
				item:Show()
			end
		end
		for i=(WeaponMenu.NumberOfWeapons+1),WeaponMenu.MaxWeapons do
			getglobal("WeaponMenu_Menu"..i):Hide()
		end
		if col==0 then
			row = row-1
		end

		if WeaponMenuPerOptions.MenuOrient=="VERTICAL" then
			WeaponMenu_MenuFrame:SetWidth(12+(max_cols*40))
			WeaponMenu_MenuFrame:SetHeight(12+((row+1)*40))
		else
			WeaponMenu_MenuFrame:SetWidth(12+((row+1)*40))
			WeaponMenu_MenuFrame:SetHeight(12+(max_cols*40))
		end
		WeaponMenu.UpdateMenuCooldowns()
		WeaponMenu_MenuFrame:Show()
		WeaponMenu.StartTimer("MenuMouseover")
	end

end

function WeaponMenu.Initialize()

	local options = WeaponMenuOptions
	options.KeepDocked = options.KeepDocked or "ON" -- new option for 2.1
	options.Notify = options.Notify or "OFF" -- 2.1
	options.DisableToggle = options.DisableToggle or "OFF" -- new option for 2.2
	options.NotifyUsedOnly = options.NotifyUsedOnly or "OFF" -- 2.2
	options.NotifyChatAlso = options.NotifyChatAlso or "OFF" -- 2.2
	options.ShowTooltips = options.ShowTooltips or "ON" -- 2.3
	options.NotifyThirty = options.NotifyThirty or "OFF" -- 2.5
	options.SquareMinimap = options.SquareMinimap or "OFF" -- 2.6
	options.MenuOnShift = options.MenuOnShift or "OFF" -- 2.6
	options.TinyTooltips = options.TinyTooltips or "OFF" -- 3.0
	options.SetColumns = options.SetColumns or "OFF" -- 3.0
	options.Columns = options.Columns or 4 -- 3.0
	options.LargeCooldown = options.LargeCooldown or "OFF" -- 3.0
	options.ShowHotKeys = options.ShowHotKeys or "OFF" -- 3.0
	WeaponMenuPerOptions.ItemsUsed = WeaponMenuPerOptions.ItemsUsed or {} -- 3.0
	options.StopOnSwap = options.StopOnSwap or "OFF" -- 3.2
	options.HideOnLoad = options.HideOnLoad or "OFF" -- 3.4
	options.RedRange = options.RedRange or "OFF" -- 3.54
	WeaponMenuPerOptions.Alpha = WeaponMenuPerOptions.Alpha or 1 -- 3.5
	WeaponMenuPerOptions.Hidden = WeaponMenuPerOptions.Hidden or {}
	options.MenuOnRight = options.MenuOnRight or "OFF" -- 3.61

	if WeaponMenuPerOptions.XPos and WeaponMenuPerOptions.YPos then
		WeaponMenu_MainFrame:SetPoint("TOPLEFT","UIParent","BOTTOMLEFT",WeaponMenuPerOptions.XPos,WeaponMenuPerOptions.YPos)
	end
	if WeaponMenuPerOptions.MainScale then
		WeaponMenu_MainFrame:SetScale(WeaponMenuPerOptions.MainScale)
	end
	if WeaponMenuPerOptions.MenuScale then
		WeaponMenu_MenuFrame:SetScale(WeaponMenuPerOptions.MenuScale)
	end
	WeaponMenu.ReflectAlpha()

	WeaponMenu_Weapon0:SetAttribute("type","item")
	WeaponMenu_Weapon1:SetAttribute("type","item")
	WeaponMenu_Weapon0:SetAttribute("slot",16)
	WeaponMenu_Weapon1:SetAttribute("slot",17)
	if WeaponMenu.QueueInit then
		-- alt has a special purpose if queue installed
		WeaponMenu_Weapon0:SetAttribute("alt-slot*",ATTRIBUTE_NOOP)
		WeaponMenu_Weapon1:SetAttribute("alt-slot*",ATTRIBUTE_NOOP)
	end
	WeaponMenu_Weapon0:SetAttribute("shift-slot*",ATTRIBUTE_NOOP)
	WeaponMenu_Weapon1:SetAttribute("shift-slot*",ATTRIBUTE_NOOP)
	WeaponMenu.ReflectMenuOnRight()

	WeaponMenu.InitTimers()
	WeaponMenu.CreateTimer("UpdateWornWeapons",WeaponMenu.UpdateWornWeapons,.75)
	WeaponMenu.CreateTimer("DockingMenu",WeaponMenu.DockingMenu,.2,1)
	WeaponMenu.CreateTimer("MenuMouseover",WeaponMenu.MenuMouseover,.25,1)
	WeaponMenu.CreateTimer("TooltipUpdate",WeaponMenu.TooltipUpdate,1,1)
	WeaponMenu.CreateTimer("CooldownUpdate",WeaponMenu.CooldownUpdate,1,1)
	WeaponMenu.CreateTimer("RedRange",WeaponMenu.RedRangeUpdate,.33,1)

	hooksecurefunc("UseInventoryItem", WeaponMenu.newUseInventoryItem)
	hooksecurefunc("UseAction", WeaponMenu.newUseAction)

	WeaponMenu.InitOptions()

	WeaponMenu.UpdateWornWeapons()
	WeaponMenu.DockWindows()
	WeaponMenu.OrientWindows()
	WeaponMenu.StartTimer("CooldownUpdate")
	WeaponMenu.ReflectRedRange()

	if WeaponMenuPerOptions.Visible=="ON" and (GetInventoryItemLink("player",16) or GetInventoryItemLink("player",17)) then
		WeaponMenu_MainFrame:Show()
	end

	-- fix for OmniCC by N00bZXI
	WeaponMenu_MainFrame:SetFrameLevel(1)
	WeaponMenu_MenuFrame:SetFrameLevel(1)
	WeaponMenu_Weapon0:SetFrameLevel(2)
	WeaponMenu_Weapon1:SetFrameLevel(2)
	for i=1,30 do
		getglobal("WeaponMenu_Menu"..i):SetFrameLevel(2)
	end

end

function WeaponMenu.ReflectMenuOnRight()
	WeaponMenu_Weapon0:SetAttribute("slot2",WeaponMenuOptions.MenuOnRight=="ON" and ATTRIBUTE_NOOP or nil)
	WeaponMenu_Weapon1:SetAttribute("slot2",WeaponMenuOptions.MenuOnRight=="ON" and ATTRIBUTE_NOOP or nil)
end

-- returns true if the player is really dead or ghost, not merely FD
function WeaponMenu.IsPlayerReallyDead()
	local dead = UnitIsDeadOrGhost("player")
	if select(2,UnitClass("player"))=="HUNTER" then
		if UnitAura("player","Feign Death") then
			return nil
		end
		for i=1,24 do
			if select(3,UnitAura("player",i))=="Interface\\Icons\\Ability_Rogue_FeignDeath" then
				return nil
			end
		end
	end
	return dead
end

function WeaponMenu.ItemInfo(slot)
	local link,id,name,equipLoc,texture = GetInventoryItemLink("player",slot)
	if link then
		local _,_,id = string.find(link,"item:(%d+)")
		name,_,_,_,_,_,_,_,equipLoc,texture = GetItemInfo(id)
	else
		_,texture = GetInventorySlotInfo("Weapon"..(slot-16).."Slot")
	end
	return texture,name,equipLoc
end

function WeaponMenu.FindItem(name,includeInventory)
	if includeInventory then
		for i=16,17 do
			if string.find(GetInventoryItemLink("player",i) or "",name,1,1) then
				return i
			end
		end
	end
	for i=0,4 do
		for j=1,GetContainerNumSlots(i) do
			if string.find(GetContainerItemLink(i,j) or "",name,1,1) then
				return nil,i,j
			end
		end
	end
end

--[[ Frame Scripts ]]--

function WeaponMenu.OnLoad(self)

	SlashCmdList["WeaponMenuCOMMAND"] = WeaponMenu.SlashHandler
	SLASH_WeaponMenuCOMMAND1 = "/weaponmenu";
	SLASH_WeaponMenuCOMMAND2 = "/weapon";
	
	self:RegisterEvent("PLAYER_LOGIN")
end

function WeaponMenu.OnEvent(self,event,...)

	if event=="UNIT_INVENTORY_CHANGED" and select(1,...)=="player" then
		WeaponMenu.UpdateWornWeapons()
	elseif event=="ACTIONBAR_UPDATE_COOLDOWN" then
		WeaponMenu.UpdateWornCooldowns(1)
	elseif (event=="PLAYER_REGEN_ENABLED" or event=="PLAYER_UNGHOST" or event=="PLAYER_ALIVE") and not WeaponMenu.IsPlayerReallyDead() then
		-- weapons can now be swapped after combat/death
		if WeaponMenu.CombatQueue[0] or WeaponMenu.CombatQueue[1] then
			WeaponMenu.EquipWeaponByName(WeaponMenu.CombatQueue[0],16)
			WeaponMenu.EquipWeaponByName(WeaponMenu.CombatQueue[1],17)
			WeaponMenu.CombatQueue[0] = nil
			WeaponMenu.CombatQueue[1] = nil
			WeaponMenu.UpdateCombatQueue()
		end
		WeaponMenu_OptMenuOnRight:Enable()
	elseif event=="UPDATE_BINDINGS" then
		WeaponMenu.KeyBindingsChanged()
	elseif event=="PLAYER_REGEN_DISABLED" then
		WeaponMenu_OptMenuOnRight:Disable()
	elseif event=="PLAYER_LOGIN" then
		WeaponMenu.LoadDefaults()
		WeaponMenu.Initialize()
		self:RegisterEvent("PLAYER_REGEN_ENABLED")
		self:RegisterEvent("PLAYER_REGEN_DISABLED")
		self:RegisterEvent("PLAYER_UNGHOST")
		self:RegisterEvent("PLAYER_ALIVE")
		self:RegisterEvent("UNIT_INVENTORY_CHANGED")
		self:RegisterEvent("UPDATE_BINDINGS")
		self:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
	end
end

function WeaponMenu.UpdateWornWeapons()
	local texture,name = WeaponMenu.ItemInfo(16)
	WeaponMenu_Weapon0Icon:SetTexture(texture)
	texture,name = WeaponMenu.ItemInfo(17)
	WeaponMenu_Weapon1Icon:SetTexture(texture)
	WeaponMenu_Weapon0Icon:SetDesaturated(0)
	WeaponMenu_Weapon0:SetChecked(0)
	WeaponMenu_Weapon1Icon:SetDesaturated(0)
	WeaponMenu_Weapon1:SetChecked(0)
	WeaponMenu.UpdateWornCooldowns()
	if WeaponMenu_MenuFrame:IsVisible() then
		WeaponMenu.BuildMenu()
	end
end

function WeaponMenu.SlashHandler(msg)

	local _,_,which,profile = string.find(msg,"load (.+) (.+)")

	if profile and WeaponMenu.SetQueue then
		which = string.lower(which)
		if which=="top" or which=="0" then
			which = 0
		elseif which=="bottom" or which=="1" then
			which = 1
		end
		if type(which)=="number" then
			WeaponMenu.SetQueue(which,"SORT",profile)
			return
		end
	end

	msg = string.lower(msg)

	if not msg or msg=="" then
		WeaponMenu.ToggleFrame(WeaponMenu_MainFrame)
	elseif string.find(msg,"^opt") or string.find(msg,"^config") then
		WeaponMenu.ToggleFrame(WeaponMenu_OptFrame)
	elseif msg=="lock" then
		WeaponMenuOptions.Locked="ON"
		WeaponMenu.DockWindows()
		WeaponMenu.ReflectLock()
	elseif msg=="unlock" then
		WeaponMenuOptions.Locked="OFF"
		WeaponMenu.DockWindows()
		WeaponMenu.ReflectLock()
	elseif msg=="reset" then
		WeaponMenu.ResetSettings()
	elseif string.find(msg,"alpha") then
		local _,_,alpha = string.find(msg,"alpha (.+)")
		alpha = tonumber(alpha)
		if alpha and alpha>0 and alpha<=1.0 then
			WeaponMenuPerOptions.Alpha = alpha
		else
			DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00WeaponMenu alpha:")
			DEFAULT_CHAT_FRAME:AddMessage("weapon alpha (number) : set alpha from 0.1 to 1.0")
		end
		WeaponMenu.ReflectAlpha()
	elseif string.find(msg,"scale") then
		local _,_,menuscale = string.find(msg,"scale menu (.+)")
		if tonumber(menuscale) then
			WeaponMenu.FrameToScale = WeaponMenu_MenuFrame
			WeaponMenu.ScaleFrame(menuscale)
		end
		local _,_,mainscale = string.find(msg,"scale main (.+)")
		if tonumber(mainscale) then
			WeaponMenu.FrameToScale = WeaponMenu_MainFrame
			WeaponMenu.ScaleFrame(mainscale)
		end
		if not tonumber(menuscale) and not tonumber(mainscale) then
			DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00WeaponMenu scale:")
			DEFAULT_CHAT_FRAME:AddMessage("/weapon scale main (number) : set exact main scale")
			DEFAULT_CHAT_FRAME:AddMessage("/weapon scale menu (number) : set exact menu scale")
			DEFAULT_CHAT_FRAME:AddMessage("ie, /weapon scale menu 0.85")
			DEFAULT_CHAT_FRAME:AddMessage("Note: You can drag the lower-right corner of either window to scale.  This slash command is for those who want to set an exact scale.")
		end
		WeaponMenu.FrameToScale = nil
		WeaponMenuPerOptions.MainScale = WeaponMenu_MainFrame:GetScale()
		WeaponMenuPerOptions.MenuScale = WeaponMenu_MenuFrame:GetScale()
	elseif string.find(msg,"load") then
		DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00WeaponMenu load:")
		DEFAULT_CHAT_FRAME:AddMessage("/weapon load (top|bottom) profilename\nie: /weapon load bottom PvP")
	else
		DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00WeaponMenu useage:")
		DEFAULT_CHAT_FRAME:AddMessage("/weapon or /weaponmenu : toggle the window")
		DEFAULT_CHAT_FRAME:AddMessage("/weapon reset : reset all settings")
		DEFAULT_CHAT_FRAME:AddMessage("/weapon opt : summon options window")
		DEFAULT_CHAT_FRAME:AddMessage("/weapon lock|unlock : toggles window lock")
		DEFAULT_CHAT_FRAME:AddMessage("/weapon scale main|menu (number) : sets an exact scale")
		DEFAULT_CHAT_FRAME:AddMessage("/weapon load top|bottom profilename : loads a profile to top or bottom weapon")
	end
end

function WeaponMenu.ResetSettings()
	StaticPopupDialogs["WEAPONMENURESET"] = {
		text = "Are you sure you want to reset WeaponMenu to default state and reload the UI?",
		button1 = "Yes", button2 = "No", showAlert=1, timeout = 0, whileDead = 1,
		OnAccept = function() WeaponMenuOptions=nil WeaponMenuPerOptions=nil WeaponMenuQueue=nil ReloadUI() end,
	}
	StaticPopup_Show("WEAPONMENURESET")
end

--[[ Window Movement ]]--

function WeaponMenu.MainFrame_OnMouseUp(self)
	local arg1=GetMouseButtonClicked()
	if arg1=="LeftButton" then
		self:StopMovingOrSizing()
		WeaponMenuPerOptions.XPos = WeaponMenu_MainFrame:GetLeft()
		WeaponMenuPerOptions.YPos = WeaponMenu_MainFrame:GetTop()
	elseif WeaponMenuOptions.Locked=="OFF" then
		if WeaponMenuPerOptions.MainOrient=="VERTICAL" then
			WeaponMenuPerOptions.MainOrient = "HORIZONTAL"
		else
			WeaponMenuPerOptions.MainOrient = "VERTICAL"
		end
		WeaponMenu.OrientWindows()
	end
end

function WeaponMenu.MainFrame_OnMouseDown(self)
	if GetMouseButtonClicked()=="LeftButton" and WeaponMenuOptions.Locked=="OFF" then
		self:StartMoving()
	end
end

--[[ Timers ]]

function WeaponMenu.InitTimers()
	WeaponMenu.TimerPool = {}
	WeaponMenu.Timers = {}
end

function WeaponMenu.CreateTimer(name,func,delay,rep)
	WeaponMenu.TimerPool[name] = { func=func,delay=delay,rep=rep,elapsed=delay }
end

function WeaponMenu.IsTimerActive(name)
	for i,j in ipairs(WeaponMenu.Timers) do
		if j==name then
			return i
		end
	end
	return nil
end

function WeaponMenu.StartTimer(name,delay)
	WeaponMenu.TimerPool[name].elapsed = delay or WeaponMenu.TimerPool[name].delay
	if not WeaponMenu.IsTimerActive(name) then
		table.insert(WeaponMenu.Timers,name)
		WeaponMenu_TimersFrame:Show()
	end
end

function WeaponMenu.StopTimer(name)
	local idx = WeaponMenu.IsTimerActive(name)
	if idx then
		table.remove(WeaponMenu.Timers,idx)
		if #(WeaponMenu.Timers)<1 then
			WeaponMenu_TimersFrame:Hide()
		end
	end
end

function WeaponMenu.TimersFrame_OnUpdate(elapsed)
	local timerPool
	for _,name in ipairs(WeaponMenu.Timers) do
		timerPool = WeaponMenu.TimerPool[name]
		timerPool.elapsed = timerPool.elapsed - elapsed
		if timerPool.elapsed < 0 then
			timerPool.func()
			if timerPool.rep then
				timerPool.elapsed = timerPool.delay
			else
				WeaponMenu.StopTimer(name)
			end
		end
	end
end

function WeaponMenu.TimerDebug()
	local on = "|cFF00FF00On"
	local off = "|cFFFF0000Off"
	DEFAULT_CHAT_FRAME:AddMessage("|cFF44AAFFWeaponMenu_TimersFrame is "..(WeaponMenu_TimersFrame:IsVisible() and on or off))
	for i in pairs(WeaponMenu.TimerPool) do
		DEFAULT_CHAT_FRAME:AddMessage(i.." is "..(WeaponMenu.IsTimerActive(i) and on or off))
	end
end

--[[ OnClicks ]]

function WeaponMenu.MainWeapon_OnClick(self)
	local arg1=GetMouseButtonClicked()
	self:SetChecked(0)
	if arg1=="RightButton" and WeaponMenuOptions.MenuOnRight=="ON" then
		if WeaponMenu_MenuFrame:IsVisible() then
			WeaponMenu_MenuFrame:Hide()
		else
			WeaponMenu.BuildMenu()
		end
	elseif IsShiftKeyDown() then
		if ChatFrameEditBox:IsVisible() then
			ChatFrameEditBox:Insert(GetInventoryItemLink("player",self:GetID()))
		end
	elseif IsAltKeyDown() and WeaponMenu.QueueInit then
		local which = self:GetID()-16
		if WeaponMenuQueue.Enabled[which] then
			WeaponMenu.CombatQueue[self:GetID()-16]=nil
			WeaponMenuQueue.Enabled[which] = nil
		else
			WeaponMenuQueue.Enabled[which] = 1
		end
		WeaponMenu.ReflectQueueEnabled()
		WeaponMenu.UpdateCombatQueue()
		-- toggle queue
	else
		WeaponMenu.ReflectWeaponUse(self:GetID())
	end
end

function WeaponMenu.MenuWeapon_OnClick(self)
	local arg1=GetMouseButtonClicked()
	self:SetChecked(0)
	local bag,slot = WeaponMenu.BaggedWeapons[self:GetID()].bag
	local slot = WeaponMenu.BaggedWeapons[self:GetID()].slot
	if IsShiftKeyDown() and ChatFrameEditBox:IsVisible() then
		ChatFrameEditBox:Insert(GetContainerItemLink(bag,slot))
	elseif IsAltKeyDown() then
		local _,_,itemID = string.find(GetContainerItemLink(bag,slot) or "","item:(%d+)")
		if WeaponMenuPerOptions.Hidden[itemID] then
			WeaponMenuPerOptions.Hidden[itemID] = nil
		else
			WeaponMenuPerOptions.Hidden[itemID] = 1
		end
		WeaponMenu.BuildMenu()
	else
		local slot = (arg1=="LeftButton") and 16 or 17
		if WeaponMenu.QueueInit then
			local _,_,canCooldown = GetContainerItemCooldown(WeaponMenu.BaggedWeapons[self:GetID()].bag,WeaponMenu.BaggedWeapons[self:GetID()].slot)
			if canCooldown==0 or WeaponMenuOptions.StopOnSwap=="ON" then -- if incoming weapon can't go on cooldown
				WeaponMenuQueue.Enabled[slot-16]=nil -- turn off autoqueue
				WeaponMenu.ReflectQueueEnabled()
			end
		end
		WeaponMenu.EquipWeaponByName(WeaponMenu.BaggedWeapons[self:GetID()].name,slot)
		if not IsShiftKeyDown() and WeaponMenuOptions.KeepOpen=="OFF" then
			WeaponMenu_MenuFrame:Hide()
		end
	end
end

--[[ Docking ]]

function WeaponMenu.MenuFrame_OnMouseDown()
	local arg1=GetMouseButtonClicked()
	if arg1=="LeftButton" and WeaponMenuOptions.Locked=="OFF" then
		WeaponMenu_MenuFrame:StartMoving()

		if WeaponMenuOptions.KeepDocked=="ON" then
			WeaponMenu.StartTimer("DockingMenu")
		end
	end
end

function WeaponMenu.MenuFrame_OnMouseUp()
	local arg1=GetMouseButtonClicked()
	if arg1=="LeftButton" then
		WeaponMenu.StopTimer("DockingMenu")
		WeaponMenu_MenuFrame:StopMovingOrSizing()
		if WeaponMenuOptions.KeepDocked=="ON" then
			WeaponMenu.DockWindows()
		end
	elseif WeaponMenuOptions.Locked=="OFF" then
		if WeaponMenuPerOptions.MenuOrient=="VERTICAL" then
			WeaponMenuPerOptions.MenuOrient="HORIZONTAL"
		else
			WeaponMenuPerOptions.MenuOrient="VERTICAL"
		end
		WeaponMenu.BuildMenu()
	end
end

function WeaponMenu.DockingMenu()

	local main = WeaponMenu_MainFrame
	local menu = WeaponMenu_MenuFrame
	local mainscale = WeaponMenu_MainFrame:GetScale()
	local menuscale = WeaponMenu_MenuFrame:GetScale()
	local near = WeaponMenu.Near

	if near(main:GetRight()*mainscale,menu:GetLeft()*menuscale) then
		if near(main:GetTop()*mainscale,menu:GetTop()*menuscale) then
			WeaponMenuPerOptions.MainDock = "TOPRIGHT"
			WeaponMenuPerOptions.MenuDock = "TOPLEFT"
		elseif near(main:GetBottom()*mainscale,menu:GetBottom()*menuscale) then
			WeaponMenuPerOptions.MainDock = "BOTTOMRIGHT"
			WeaponMenuPerOptions.MenuDock = "BOTTOMLEFT"
		end
	elseif near(main:GetLeft()*mainscale,menu:GetRight()*menuscale) then
		if near(main:GetTop()*mainscale,menu:GetTop()*menuscale) then
			WeaponMenuPerOptions.MainDock = "TOPLEFT"
			WeaponMenuPerOptions.MenuDock = "TOPRIGHT"
		elseif near(main:GetBottom()*mainscale,menu:GetBottom()*menuscale) then
			WeaponMenuPerOptions.MainDock = "BOTTOMLEFT"
			WeaponMenuPerOptions.MenuDock = "BOTTOMRIGHT"
		end
	elseif near(main:GetRight()*mainscale,menu:GetRight()*menuscale) then
		if near(main:GetTop()*mainscale,menu:GetBottom()*menuscale) then
			WeaponMenuPerOptions.MainDock = "TOPRIGHT"
			WeaponMenuPerOptions.MenuDock = "BOTTOMRIGHT"
		elseif near(main:GetBottom()*mainscale,menu:GetTop()*menuscale) then
			WeaponMenuPerOptions.MainDock = "BOTTOMRIGHT"
			WeaponMenuPerOptions.MenuDock = "TOPRIGHT"
		end
	elseif near(main:GetLeft()*mainscale,menu:GetLeft()*menuscale) then
		if near(main:GetTop()*mainscale,menu:GetBottom()*menuscale) then
			WeaponMenuPerOptions.MainDock = "TOPLEFT"
			WeaponMenuPerOptions.MenuDock = "BOTTOMLEFT"
		elseif near(main:GetBottom()*mainscale,menu:GetTop()*menuscale) then
			WeaponMenuPerOptions.MainDock = "BOTTOMLEFT"
			WeaponMenuPerOptions.MenuDock = "TOPLEFT"
		end
	end
	WeaponMenu.ClearDocking()
	getglobal("WeaponMenu_MainDock_"..WeaponMenuPerOptions.MainDock):Show()
	getglobal("WeaponMenu_MenuDock_"..WeaponMenuPerOptions.MenuDock):Show()
end

function WeaponMenu.MenuMouseover()
	if (not MouseIsOver(WeaponMenu_MainFrame)) and (not MouseIsOver(WeaponMenu_MenuFrame)) and not IsShiftKeyDown() and (WeaponMenuOptions.KeepOpen=="OFF") then
		WeaponMenu.StopTimer("MenuMouseover")
		WeaponMenu_MenuFrame:Hide()
	end
end

--[[ Cooldowns ]]

function WeaponMenu.UpdateWornCooldowns(maybeGlobal)
	local start,duration,enable = GetInventoryItemCooldown("player",16)
	CooldownFrame_SetTimer(WeaponMenu_Weapon0Cooldown,start,duration,enable)
	start,duration,enable = GetInventoryItemCooldown("player",17)
	CooldownFrame_SetTimer(WeaponMenu_Weapon1Cooldown,start,duration,enable)
	if not maybeGlobal then
		WeaponMenu.WriteWornCooldowns()
	end
end

function WeaponMenu.UpdateMenuCooldowns()
	local start,duration,enable
	for i=1,WeaponMenu.NumberOfWeapons do
		start,duration,enable = GetContainerItemCooldown(WeaponMenu.BaggedWeapons[i].bag,WeaponMenu.BaggedWeapons[i].slot)
		CooldownFrame_SetTimer(getglobal("WeaponMenu_Menu"..i.."Cooldown"),start,duration,enable)
	end
	WeaponMenu.WriteMenuCooldowns()
end

--[[ Item use ]]

function WeaponMenu.ReflectWeaponUse(slot)
	getglobal("WeaponMenu_Weapon"..(slot-16)):SetChecked(1)
	WeaponMenu.StartTimer("UpdateWornWeapons")
	local _,_,id = string.find(GetInventoryItemLink("player",slot) or "","item:(%d+)")
	if id then
		WeaponMenuPerOptions.ItemsUsed[id] = 0 -- 0 is an indeterminate state, cooldown will figure if it's worth watching
	end
end

function WeaponMenu.newUseInventoryItem(slot)
	if slot==16 or slot==17 and not MerchantFrame:IsVisible() then
		WeaponMenu.ReflectWeaponUse(slot)
	end
end

function WeaponMenu.newUseAction(slot,cursor,self)
	if IsEquippedAction(slot) then
		WeaponMenu_TooltipScan:SetOwner(WorldFrame,"ANCHOR_NONE")
		WeaponMenu_TooltipScan:SetAction(slot)
		local _,weapon0 = WeaponMenu.ItemInfo(16)
		local _,weapon1 = WeaponMenu.ItemInfo(17)

		if GameTooltipTextLeft1:GetText()==weapon0 then
			WeaponMenu.ReflectWeaponUse(16)
		elseif GameTooltipTextLeft1:GetText()==weapon1 then
			WeaponMenu.ReflectWeaponUse(17)
		end
	end
end

--[[ Tooltips ]]

function WeaponMenu.WornWeaponTooltip(self)
	-- local id = self:GetID()
	-- if WeaponMenuOptions.ShowTooltips=="OFF" then
	-- 	return
	-- end
	-- WeaponMenu.TooltipOwner = self
	-- WeaponMenu.TooltipType = "INVENTORY"
	-- WeaponMenu.TooltipSlot = id
	-- WeaponMenu.TooltipBag = WeaponMenu.CombatQueue[id]
	-- WeaponMenu.StartTimer("TooltipUpdate",0)
end

function WeaponMenu.MenuWeaponTooltip(self)
	-- local id = self:GetID()
	-- if WeaponMenuOptions.ShowTooltips=="OFF" then
	-- 	return
	-- end
	-- WeaponMenu.TooltipOwner = self
	-- WeaponMenu.TooltipType = "INVENTORY"
	-- WeaponMenu.TooltipBag = WeaponMenu.BaggedWeapons[id].bag
	-- WeaponMenu.TooltipSlot = WeaponMenu.BaggedWeapons[id].slot
	-- WeaponMenu.StartTimer("TooltipUpdate",0)
end

function WeaponMenu.ClearTooltip()
	GameTooltip:Hide()
	WeaponMenu.StopTimer("TooltipUpdate")
	WeaponMenu.TooltipType = nil
end

function WeaponMenu.AnchorTooltip(self)
	if WeaponMenuOptions.TooltipFollow=="ON" then
		if self.GetLeft and self:GetLeft() and self:GetLeft()<400 then
			GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
		else
			GameTooltip:SetOwner(self,"ANCHOR_LEFT")
		end
	else
		GameTooltip_SetDefaultAnchor(GameTooltip,self)
	end
end

-- updates the tooltip created in the functions above
function WeaponMenu.TooltipUpdate()
	if WeaponMenu.TooltipType then
		local cooldown
		WeaponMenu.AnchorTooltip(WeaponMenu.TooltipOwner)
		if WeaponMenu.TooltipType=="BAG" then
			GameTooltip:SetBagItem(WeaponMenu.TooltipBag,WeaponMenu.TooltipSlot)
			cooldown = GetContainerItemCooldown(WeaponMenu.TooltipBag,WeaponMenu.TooltipSlot)
		else
			GameTooltip:SetInventoryItem("player",WeaponMenu.TooltipSlot)
			cooldown = GetInventoryItemCooldown("player",WeaponMenu.TooltipSlot)
		end
		WeaponMenu.ShrinkTooltip(WeaponMenu.TooltipOwner) -- if TinyTooltips on, shrink it
		if WeaponMenu.TooltipType=="INVENTORY" and WeaponMenu.TooltipBag then
			GameTooltip:AddLine("Queued: "..WeaponMenu.TooltipBag)
		end
		GameTooltip:Show()
		if cooldown==0 then
			-- stop updates if this weapon has no cooldown
			WeaponMenu.TooltipType = nil
			WeaponMenu.StopTimer("TooltipUpdate")
		end
	end

end

-- normal tooltip for options
function WeaponMenu.OnTooltip(self,line1,line2)
	if WeaponMenuOptions.ShowTooltips=="ON" then
		WeaponMenu.AnchorTooltip(self)
		if line1 then
			GameTooltip:AddLine(line1)
			GameTooltip:AddLine(line2,.8,.8,.8,1)
			GameTooltip:Show()
		else
			local name = self:GetName() or ""
			for i=1,#(WeaponMenu.CheckOptInfo) do
				if name=="WeaponMenu_Opt"..WeaponMenu.CheckOptInfo[i][1] and WeaponMenu.CheckOptInfo[i][3] then
					WeaponMenu.OnTooltip(self,WeaponMenu.CheckOptInfo[i][3],WeaponMenu.CheckOptInfo[i][4])
				end
			end
			for i=1,#(WeaponMenu.TooltipInfo) do
				if WeaponMenu.TooltipInfo[i][1]==name and WeaponMenu.TooltipInfo[i][2] then
					WeaponMenu.OnTooltip(self,WeaponMenu.TooltipInfo[i][2],WeaponMenu.TooltipInfo[i][3])
				end
			end
		end
	end
end

-- strip format reordering in global strings
WeaponMenu.ITEM_SPELL_CHARGES = string.gsub(ITEM_SPELL_CHARGES,"%%%d%$d","%%d")

function WeaponMenu.ShrinkTooltip(owner)
	if WeaponMenuOptions.TinyTooltips=="ON" then
		local r,g,b = GameTooltipTextLeft1:GetTextColor()
		local name = GameTooltipTextLeft1:GetText()
		local line,cooldown,charge
		for i=2,GameTooltip:NumLines() do
			line = getglobal("GameTooltipTextLeft"..i)
			if line:IsVisible() then
				line = line:GetText() or ""
				if string.find(line,COOLDOWN_REMAINING) then
					cooldown = line
				end
				if string.find(line,WeaponMenu.ITEM_SPELL_CHARGES) then
					charge = line
				end
			end
		end
		WeaponMenu.AnchorTooltip(owner)
		GameTooltip:AddLine(name,r,g,b)
		GameTooltip:AddLine(charge,1,1,1)
		GameTooltip:AddLine(cooldown,1,1,1)
	end
end

-- returns 1 if the item at bag(,slot) is an engineered weapon
function WeaponMenu.IsEngineered(bag,slot)
	local item = slot and GetContainerItemLink(bag,slot) or GetInventoryItemLink("player",bag)
	if item then
		local _,_,_,_,_,itemType,itemSubtype,_,itemLoc = GetItemInfo(item)
		if itemType==WeaponMenu.TRADE_GOODS and itemSubtype==WeaponMenu.DEVICES and (itemLoc=="INVTYPE_WEAPON" or temLoc=="INVTYPE_2HWEAPON" or temLoc=="INVTYPE_SHIELD") then
			return 1
		end
		WeaponMenu_TooltipScan:SetOwner(WorldFrame,"ANCHOR_NONE")
		WeaponMenu_TooltipScan:SetHyperlink(item)
		for i=1,WeaponMenu_TooltipScan:NumLines() do
			if string.match(getglobal("WeaponMenu_TooltipScanTextLeft"..i):GetText() or "",WeaponMenu.REQUIRES_ENGINEERING) then
				return 1
			end
		end
	end
end

-- returns bag,slot of a free bag space, if one found.  engineering true if only looking for an engineering bag
function WeaponMenu.FindSpace(engineering)
	local bagType
	for i=4,0,-1 do
		bagType = select(7,GetItemInfo(GetInventoryItemLink("player",16+i) or ""))
		if (engineering and bagType==WeaponMenu.ENGINEERING_BAG) or (not engineering and bagType==WeaponMenu.BAG) then
			for j=1,GetContainerNumSlots(i) do
				if not GetContainerItemLink(i,j) then
					return i,j
				end
			end
		end
	end
end

--[[ Combat Queue ]]

function WeaponMenu.EquipWeaponByName(name,slot)
	if not name then return end
	if UnitAffectingCombat("player") or WeaponMenu.IsPlayerReallyDead() then
		-- queue weapon
		local queue = WeaponMenu.CombatQueue
		local which = slot-16 -- 0 or 1
		if queue[which]==name and not imperative then
			queue[which] = nil
		elseif queue[1-which]==name then
			queue[1-which] = nil
			queue[which] = name
		else
			queue[which] = name
		end
	elseif not CursorHasItem() and not SpellIsTargeting() then
		local _,b,s = WeaponMenu.FindItem(name)
		if b then
			local _,_,isLocked = GetContainerItemInfo(b,s)
			if not isLocked and not IsInventoryItemLocked(slot) then
				-- neither container item nor inventory item locked, perform swap
				local directSwap = 1 -- assume a direct swap will happen
				if select(7,GetItemInfo(GetInventoryItemLink("player",19+b) or ""))==WeaponMenu.ENGINEERING_BAG then
					-- incoming weapon is in an engineering bag
					if not WeaponMenu.IsEngineered(slot) then
						-- outgoing weapon can't go inside it
						local freeBag,freeSlot = WeaponMenu.FindSpace()
						if freeBag then
							PickupInventoryItem(slot)
							PickupContainerItem(freeBag,freeSlot)
							PickupContainerItem(b,s)
							EquipCursorItem(slot)
							directSwap = nil
						end
					end
				elseif WeaponMenu.IsEngineered(slot) and not WeaponMenu.IsEngineered(b,s) then
					-- outgoing weapon is engineered, incoming weapon is not
					local freeBag,freeSlot = WeaponMenu.FindSpace(1)
					if freeBag then
						-- move outgoing weapon to engineering bag, equip incoming weapon
						PickupInventoryItem(slot)
						PickupContainerItem(freeBag,freeSlot)
						PickupContainerItem(b,s)
						EquipCursorItem(slot)
						directSwap = nil
					end
				end
				if directSwap then
					PickupContainerItem(b,s)
					PickupInventoryItem(slot)
				end
				getglobal("WeaponMenu_Weapon"..(slot-16).."Icon"):SetDesaturated(1)
				WeaponMenu.StartTimer("UpdateWornWeapons") -- in case it's not equipped (stunned, etc)
			end
		end
	end
	WeaponMenu.UpdateCombatQueue()
end	

function WeaponMenu.UpdateCombatQueue()
	local bag,slot
	for which=0,1 do
		local weapon = WeaponMenu.CombatQueue[which]
		local icon = getglobal("WeaponMenu_Weapon"..which.."Queue")
		icon:Hide()
		if weapon then
			_,bag,slot = WeaponMenu.FindItem(weapon)
			if bag then
				icon:SetTexture(GetContainerItemInfo(bag,slot))
				icon:Show()
			end
		elseif WeaponMenu.QueueInit and WeaponMenuQueue and WeaponMenuQueue.Enabled[which] then
			icon:SetTexture("Interface\\AddOns\\WeaponMenu\\WeaponMenu-Gear")
			icon:Show()
		end
	end
end

--[[ Notify ]]

function WeaponMenu.Notify(msg)
	PlaySound("GnomeExploration")
	if SCT_Display then -- send via SCT if it exists
		SCT_Display(msg,{r=.2,g=.7,b=.9})
	elseif SHOW_COMBAT_TEXT=="1" then
		CombatText_AddMessage(msg, CombatText_StandardScroll, .2, .7, .9) -- or default UI's SCT
	else
		-- send vis UIErrorsFrame if neither SCT exists
		UIErrorsFrame:AddMessage(msg,.2,.7,.9,1,UIERRORS_HOLD_TIME)
	end
	if WeaponMenuOptions.NotifyChatAlso=="ON" then
		DEFAULT_CHAT_FRAME:AddMessage("|cff33b2e5"..msg)
	end
end

function WeaponMenu.CooldownUpdate()
	local inv,bag,slot,start,duration,name,remain
	for i in pairs(WeaponMenuPerOptions.ItemsUsed) do
		start,duration = GetItemCooldown(i)
		if start and WeaponMenuPerOptions.ItemsUsed[i]<3 then
			WeaponMenuPerOptions.ItemsUsed[i] = WeaponMenuPerOptions.ItemsUsed[i] + 1 -- count for 3 seconds before seeing if this is a real cooldown
		elseif start then
			if start>0 then
				remain = duration - (GetTime()-start)
				if WeaponMenuPerOptions.ItemsUsed[i]<5 then
					if remain>29 then
						WeaponMenuPerOptions.ItemsUsed[i] = 30 -- first actual cooldown greater than 30 seconds, tag it for 30+0 notify
					elseif remain>5 then
						WeaponMenuPerOptions.ItemsUsed[i] = 5 -- first actual cooldown less than 30 but greater than 5, tag for 0 notify
					end
				end
			end
			if WeaponMenuPerOptions.ItemsUsed[i]==30 and start>0 and remain<30 then
				if WeaponMenuOptions.NotifyThirty=="ON" then
					name = GetItemInfo(i)
					if name then
						WeaponMenu.Notify(name.." ready soon!")
					end
				end
				WeaponMenuPerOptions.ItemsUsed[i]=5 -- tag for just 0 notify now
			elseif WeaponMenuPerOptions.ItemsUsed[i]==5 and start==0 then
				if WeaponMenuOptions.Notify=="ON" then
					name = GetItemInfo(i)
					if name then
						WeaponMenu.Notify(name.." ready!")
					end
				end
			end
			if start==0 then
				WeaponMenuPerOptions.ItemsUsed[i] = nil
			end
		end
	end

	-- update cooldown numbers
	if WeaponMenuOptions.CooldownCount=="ON" then
		if WeaponMenu_MainFrame:IsVisible() then
			WeaponMenu.WriteWornCooldowns()
		end
		if WeaponMenu_MenuFrame:IsVisible() then
			WeaponMenu.WriteMenuCooldowns()
		end
	end

	if WeaponMenu.PeriodicQueueCheck then
		WeaponMenu.PeriodicQueueCheck()
	end
end

function WeaponMenu.WriteWornCooldowns()
	local start, duration
	start, duration = GetInventoryItemCooldown("player",16)
	WeaponMenu.WriteCooldown(WeaponMenu_Weapon0Time,start,duration)
	start, duration = GetInventoryItemCooldown("player",17)
	WeaponMenu.WriteCooldown(WeaponMenu_Weapon1Time,start,duration)
end

function WeaponMenu.WriteMenuCooldowns()
	local start, duration
	for i=1,WeaponMenu.NumberOfWeapons do
		start, duration = GetContainerItemCooldown(WeaponMenu.BaggedWeapons[i].bag,WeaponMenu.BaggedWeapons[i].slot)
		WeaponMenu.WriteCooldown(getglobal("WeaponMenu_Menu"..i.."Time"),start,duration)
	end
end

function WeaponMenu.WriteCooldown(where,start,duration)
	local cooldown = duration - (GetTime()-start)
	if start==0 or WeaponMenuOptions.CooldownCount=="OFF" then
		where:SetText("")
	elseif cooldown<3 and not where:GetText() then
		-- this is a global cooldown. don't display it. not accurate but at least not annoying
	else
		where:SetText((cooldown<60 and math.floor(cooldown+.5).." s") or (cooldown<3600 and math.ceil(cooldown/60).." m") or math.ceil(cooldown/3600).." h")
	end
end

function WeaponMenu.OnShow()
	WeaponMenuPerOptions.Visible = "ON"
	if WeaponMenuOptions.KeepOpen=="ON" then
		WeaponMenu.BuildMenu()
	end
end

function WeaponMenu.OnHide()
	WeaponMenuPerOptions.Visible = "OFF"
	WeaponMenu_MenuFrame:Hide()
end

function WeaponMenu.ReflectAlpha()
	WeaponMenu_MainFrame:SetAlpha(WeaponMenuPerOptions.Alpha)
	WeaponMenu_MenuFrame:SetAlpha(WeaponMenuPerOptions.Alpha)
end

--[[ Key bindings ]]

function WeaponMenu.KeyBindingsChanged()
	if WeaponMenuOptions.ShowHotKeys=="ON" then
		local key
		for i=0,1 do
			key = GetBindingKey("CLICK WeaponMenu_Weapon"..i..":LeftButton")
			getglobal("WeaponMenu_Weapon"..i.."HotKey"):SetText(GetBindingText(key or "",nil,1))
		end
	else
		WeaponMenu_Weapon0HotKey:SetText("")
		WeaponMenu_Weapon1HotKey:SetText("")
	end
end

--[[ Monitor Range ]]

function WeaponMenu.ReflectRedRange()
	if WeaponMenuOptions.RedRange=="ON" then
		WeaponMenu.StartTimer("RedRange")
	else
		WeaponMenu.StopTimer("RedRange")
		WeaponMenu_Weapon0Icon:SetVertexColor(1,1,1)
		WeaponMenu_Weapon1Icon:SetVertexColor(1,1,1)
	end
end

function WeaponMenu.RedRangeUpdate()
	local item
	for i=16,17 do
		item = GetInventoryItemLink("player",i)
		if item and IsItemInRange(item)==0 then
			getglobal("WeaponMenu_Weapon"..(i-16).."Icon"):SetVertexColor(1,.3,.3)
		else
			getglobal("WeaponMenu_Weapon"..(i-16).."Icon"):SetVertexColor(1,1,1)
		end
	end
end

