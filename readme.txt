WeaponMenu 3.8

This is a mod to make swapping weapons easier.  It will display your two equipped weapons in a bar.  Mouseover on either weapon will display a menu of up to 30 weapons in your bags to swap.

__ New in 3.81 __
- Scaling now done via sliders in options
- Updated for 3.0 client
- Removed obsolete buff cache system
- Auto swaps while casting wait until done casting

__ Swapping/Using weapons __

Left click a weapon in the menu to equip it to the top weapon slot.
Right click a weapon in the menu to equip it to the bottom weapon slot.

Left or Right click either equipped weapon to use them.  Or make a key binding for either weapon.

__ Auto Queue __

3.0 introduces auto weapon queues to WeaponMenu.  In options you can sort a weapon slot to the order you want weapons equipped, turn on Auto Queue for that slot (Alt+Click the weapon on the bar or check the tab in options), and the mod will automatically swap weapons as they're used and come off cooldown.

It was (hopefully) made to be intuitive enough to use without instructions, but if wondering about specifics:

The auto queue rules are:
- A weapon at 30 seconds or less cooldown is considered off cooldown.
- If the currently equipped weapon is on cooldown, swap to the first available weapon not on cooldown.
- If the currently equipped weapon cannot go on cooldown (passive weapons), equip a higher ranking weapon when it comes off cooldown.
- If the currently equipped weapon is ready for use, then do nothing unless a higher-ranked weapon marked 'Priority' is waiting to swap in.
- If a weapon has a 'Delay' defined, then hold that weapon for its delay before swapping it out. (ie, Earthstrike for 20 seconds)
- If a weapon grants a buff and that buff is currently on you, hold that weapon until the buff fades.

Auto queue icon colors:
- A gold gear on a weapon means that auto queue is active for that slot.
- A grey gear on a weapon means the equipped weapon has a delay defined and is waiting to swap out.
- A red gear on a weapon means the equipped weapon is flagged 'Pause Queue' and auto queue is suspended.

Other auto queue notes:
- If you use some mod to automatically swap in passive weapons (Carrot on a Stick or Argent Dawn Commission), flag those weapons 'Pause Queue' to suspend the queue while they're equipped.
- Swapping a passive weapon manually in WeaponMenu will stop the auto queue for that slot.  Alt+click the slot to turn auto queue back on.
- A purely passive weapon will mark the natural end of a queue.  If you would like the queue to stop sooner (ie, Burst of Knowledge as bottom-most weapon even on cooldown), move the "-- stop queue here--" mark to where you want the queue to stop.
- The auto queues work independently of the "weapon ready!" notifications.
- Weapons attempting to swap during combat or while dead will queue for when you drop out of combat or return to life.
- If you don't want to use auto queue and would like to remove it completely, you can delete WeaponMenuQueue.xml and WeaponMenuQueue.lua while out of game.  The remaining mod will be about the size of WeaponMenu 2.7 and run better than 2.7.

__ Auto Queue Shared Timers __

Keep in mind as you set up your queues that many weapons trigger shared cooldown timers.  As an example:

Weapon 0 contains a Cannonball Runner not on cooldown
Weapon 1 contains a Diamond Flask not on cooldown

When you click Diamond Flask, it will put the Cannonball Runner into a 60-second cooldown.  WeaponMenu will then look for something more available for Weapon 0, and then 30 seconds later as the Cannonball Runner comes off cooldown it will swap it back in.

This is expected behavior.  If it seems like this happens a lot, you may want to Auto Queue only one weapon slot, until you get weapons that can be used without triggering the other's cooldown.

__ Customizing Display __

The main and menu windows are independently scalable and rotatable.  While the windows are unlocked:

- Move either window by dragging its edge.
- Rotate either window by right-clicking its edge.
- Scale/resize either window with a slider in options.

If you're having problems grabbing the edge of the menu window to move/rotate it, hold Shift down while it's open and the menu won't go away when the mouse leaves the menu's edge.

If you right-click the gear icon around the minimap (or /weapon options) a small options window will appear under the minimap.  Here you can customize the display further by showing cooldowns as numbers and keeping the menu always open.

Once you're settled on a setup you like, you can lock the windows in options.

To set an exact scale (optional):
/weapon scale main n : Scale the main window to n
/weapon scale menu n : Scale the menu window to n
ie: /weapon scale menu 0.85

__ Docking __

While 'Keep Menu Docked' is checked (default), the menu will always be docked to one corner of the main window.  To change the corner where it's docked, drag the menu window so that a corner of the main and menu windows meet.  White brackets will appear at the corners that will dock as you drag.

If you uncheck 'Keep Menu Docked', remember the menu goes away when the mouse leaves your weapons.  Feel free to experiment if you'd like.  Remember that /weapon reset will restore positions/docking, or you can hold Shift down to keep the menu open.  Or you can turn on 'Keep Menu Open' in options.

__ Combat/Death Queued Weapons __

We can't swap weapons during combat or when we're dead.  If you attempt to swap weapons during combat or while dead it will put the weapon on hold and automatically swap them once you leave combat:

- The queued weapon will appear as a small icon inset into the slot it's heading to.
- If you want to unqueue the weapon, reselect it again for that slot (left or right click).
- If you want to queue the weapon to the other slot, reselect it again for the other slot (left or right click).
- The "combat queue" is only one-weapon deep right now.  Meaning, once a queued weapon is equipped that queue is emptied.
- Selecting a series of weapons for a slot will only change the queued weapon, it won't set up an order to them.  Go to options to set up an auto queue sort order.

__ Misc __

- If you hold shift while you move weapons up/down the sort list, the list will stay in place.
- You can drag the minimap icon around the minimap directly.
- You can Shift+click the weapons to link them to chats just as you would from your bags or inventory.
- If you log in to a character with no weapons in bags or on their person, the weapon window will not be displayed.
- You can hold Shift while swapping weapons or manipulating the windows to prevent the menu from disappearing.
- You can set up key bindings to use whatever weapon is in the top or bottom slot.
- If you have Scrolling Combat Text installed, and 'Notify When Ready' checked, it will send a message via SCT when a weapon is ready.

__ Optional Slash Commands __

/weapon or /weaponmenu : toggle the window
/weapon reset : reset window
/weapon opt : summons options window
/weapon lock|unlock : toggles window lock
/weapon scale main|menu n : scales windows to exact scale
/weapon help : lists the above commands

__ WeaponMenu.SetQueue (Advanced Users) __

This function is intended to be used by those that want to script different sort orders or script the auto queue behavior to work with other gear-swapping mods.

WeaponMenu.SetQueue(0 or 1,"ON" or "OFF" or "PAUSE" or "RESUME" or list)

"ON" : Turn queue on irregardless of previous state
"OFF" : Turn queue off irregardless of previous state
"PAUSE" : Suspend queue if it was on
"RESUME" : Return queue to normal operation if it was paused

some examples:
/script WeaponMenu.SetQueue(1,"PAUSE") -- if queue is going, pause it
/script WeaponMenu.SetQueue(1,"RESUME") -- if queue is paused, resume it
/script WeaponMenu.SetQueue(1,"SORT","Earthstrike","Insignia of the Alliance","Diamond Flask") -- set sort
/script WeaponMenu.SetQueue(0,"SORT","Lifestone","Darkmoon Card: Heroism") -- set sort
/script WeaponMenu.SetQueue(1,"SORT","PVP Profile") -- set sort to "PVP Profile"
(a "stop the queue" is assumed at the end of the list)

So in ItemRack if you want a different queue when in a raid or not:

name: In Raid
trigger: RAID_ROSTER_UPDATE
delay: 0.5
script:
if GetNumRaidMembers()>0 and not IR_INRAID then
  IR_INRAID = 1
  WeaponMenu.SetQueue(1,"SORT","Zandalarian Hero Badge","Force of Will")
elseif IR_INRAID and GetNumRaidMembers()==0 then
  IR_INRAID = nil
  WeaponMenu.SetQueue(1,"SORT","Earthstrike","Diamond Flask","Defender of the Timbermaw")
end
--[[ Changes weapon sort orders depending on whether in a raid or not ]]

or for some situation when you don't want weapons swapping at all:

name: In IF
trigger: ZONE_CHANGED_NEW_AREA
delay: 2
script:
if GetRealZoneText()=="Ironforge" and not IR_INIF then
  IR_INIF = 1
  WeaponMenu.SetQueue(0,"PAUSE")
elseif IR_INIF and GetRealZoneText()~="Ironforge" then
  IR_INIF = nil
  WeaponMenu.SetQueue(0,"RESUME")
end
--[[ Pauses weapon slot 0 auto queue while in IF ]]

__ FAQ for 3.x __

Q: Why did you remove the "missing weapon" bit?
A: Because it wasn't always accurate and to make it more accurate would require more bag scanning than is necessary for the mod to function.  Specifically: when a series of BAG_UPDATEs occur, it waits until they're done and then quickly scans only the bags that updated.  When it finds a weapon it notes its position.  If a weapon disappeared it doesn't care because it's not going to show in the menu.  I am hyper-sensitive to BAG_UPDATE performance and don't want to spend more CPU cycles than is necessary in normal BAG_UPDATE actions. (You may note that if you remove the WeaponMenuQueue.* files then BAG_UPDATE isn't registered at all)

Q: Can you let the auto queue remain enabled when I swap in passive weapons?
A: At some point, you will have to tell the mod that you no longer want to use the passive weapon.  Alt+clicking the slot seems simplest.

Q: Can you make auto queue stop/start with my weapon-swapping mod/macro?
A: There are numerous ways of equipping weapons: UseContainerItem, UseAction, PickupContainerItem/PickupInventoryItem, EquipCursorItem, etc.  I don't want to hook all those functions.  I want this mod to be small and unobtrusive.  Check 'Pause Queue' on weapons your mod/macro equips, or use WeaponMenu.SetQueue in the macro or event that does the swap.

Q: You said you'd never add full queues to this.  Why the change?
A: Mostly it was to work out some design problems for ItemRack that will have queues for equippable and consumable items.  I needed to back up to a simpler level and adding queues to WeaponMenu was a logical place to work them out.

Q: One reason I used WeaponMenu was because it wasn't bloated with bells and whistles.  Will you release a version without the Auto Queues?
A: If you delete WeaponMenuQueue.xml and WeaponMenuQueue.lua then it will remove the Auto Queue and all the frames and code associated with it.  What's left will be about the same size as 2.7 WeaponMenu.  If there's demand I can post a zip with those files removed.

Q: Does this mean you're not working on ItemRack?
A: See above.  Work is progressing.  Some design issues needed sorted out and this mod's update was a helpful part of that.

Q: Why a rewrite?
A: I'm hoping to keep this mod tidy with as little feature creep as possible.  Rewrites are a good way to trim out unnecessary junk.

Q: I set the menu columns to X, but it's doing X rows and the wrong number of columns.
A: Rotate the menu by right-clicking its unlocked edge.  Then rows will become columns and vice versa.

Q: I made Weapon A higher priority than Weapon B, but when Weapon A comes off cooldown it's not equipping.
A: The default behavior is to not swap weapons if the currently-equipped weapon is clickable and not on cooldown.  This is to prevent the weapon slots excessively swapping and spending a lot of time in 30-second cooldowns.  If you have a weapon you want equipped ASAP when it's ready, select it and check 'Priority' at the bottom.

__ FAQ __

Q: How do I equip a weapon to the "off" weapon slot?
A: Left click goes to main weapon slot, right click goes to off slot.

Q: Can you add items other than weapons to the menu?
A: See ItemRack, which is the big brother to this mod.  It handles all inventory slots as well as item sets and stuff.

Q: What does ItemRack mean for WeaponMenu's future?
A: WeaponMenu will stay focused on weapons.  For the foreseeable future it will be maintained alongside ItemRack since many are looking for just a weapon manager without the extras.  While some new stuff may be added from time to time, any larger changes would probably happen in ItemRack.  WeaponMenu will be kept small and focused.

Q: Localization?
A: This mod should work on all clients.  I can't test this for myself but many report it works fine.

Q: I changed my notify settings on my warrior, but the change shows on my other characters also.
A: Everything in the options window saves for all characters.  Just position, orientation, docking and scaling are saved per-character.

Q: I'd like to go back to using global position/orientation/docking for all my characters.  Can I do this?
A: Sure.  Edit WeaponMenu.toc and change these two lines to the one that follows:

Change:
## SavedVariables: WeaponMenuOptions
## SavedVariablesPerCharacter: WeaponMenuPerOptions

To:
## SavedVariables: WeaponMenuOptions, WeaponMenuPerOptions

To change all settings (notify, tooltips, etc), change the previous two lines to:
## SavedVariablesPerCharacter: WeaponMenuOptions, WeaponMenuPerOptions

Q: How do I move the minimap icon?
A: Drag it like a normal window.  Left click and drag it around and it will slide around the edge.

Q: I'm trying to swap weapons, but instead of swapping it put a tiny weapon icon over my equipped one.
A: This means you're in combat mode.  You won't be able to swap weapons until you leave combat.  The tiny weapon is the one that will swap in once you leave combat.

Q: What if I don't have Scrolling Combat Text, will it still notify me when weapon cooldowns expire?
A: If you don't have SCT, it will notify in the "errors" overhead, where you get "Insufficient mana", "Out of range", etc type errors.

Q: I don't have many weapons and because of this I'm having problems docking to some corners.  Any way to make it easier?
A: Temporarily resize either window to make the differences greater so it's easier to dock to an exact corner.

Q: It's not showing all my weapons, I have over 30 of them in my bags.
A: This version can handle only up to 32 weapons.  Two equipped and 30 in bags.  If you exceed this amount, post how many weapons you have and I'll up the limit.  30 seemed a reasonable number, but as the screenshots show it's not very difficult to get 30 weapons if you're an engineer.  In the meantime the mod will lift weapons from right bag to left if you want to control which 30 are displayed.

Q: I can't rotate, move or do anything with the windows.
A: That sounds like the windows are locked.  Enter: /weapon unlock

__ Changes __
3.81, 10/8/08, passed self to SortPriority_OnClick
3.8, 10/8/08, wotlk beta: scaling done via sliders, removed resize grips, this->self conversion should be complete, removed buff cache, queue won't process while casting
3.71, 5/7/08, removed ITEM_SPELL_CHARGES_P1 from tiny tooltip, no longer exists
3.7, 4/1/06, added: engineering bag support, queue won't swap a weapon with an active buff running
3.6, 12/5/06, live release of 3.5x beta changes
3.56, 12/1/06, bug fixed: GameTooltip:NumLines in shrink tooltip, removed use entries from Bindings.xml
3.55, 11/4/06, changed: key bindings moved to ClickBinder, added: shift/alt click options for minimap button
3.543, 10/27/06, changed: all key binding code to new dummy key bind method, attributes alt-item* to alt-slot*
3.542, 10/25/06, bugs fixed: converted .../args to .../select(#,...) in SetQueue, equip by name in process queue
3.541, 10/23/06, changed: UISpecialFrames temporarily removed
3.54, 10/22/06, added: key bindings, red out of range, removed: item cache and BAG_UPDATE system (wee), changed: using GetItemCooldown instead
3.53, 10/19/06, changed: "inventory" attribute to "item", check if GetItemInfo results valid on new item at patch
3.52, 10/14/06, changed: uses secure templates, alt to hide/show weapons in menu, helpful pointer to the delay bit, /itemrack alpha
3.41, 8/24/06, added: /weapon load, changed: tabs removed and window shortened if WeaponMenuQueue not installed, bug fixed: /weapon reset (savedvars load defaults if nil), checked for Queue before setting HideOnLoad
3.4, 8/22/06, added: weapon profiles, delete weapon button
3.3, 8/5/06, added: 1.12 "Floating Combat Text" support, changed: weapons coming off cooldown clear combat queue, toggle key binding obeys 'Disable Toggle' option
3.22, 7/24/06, added: WeaponMenu.SetQueue and WeaponMenu.GetQueue
3.21, 7/16/06, changed: lock also locks OptFrame, bug fixed: global strings stripped "%1$d Charge" to "%d Charge"
3.2, 7/16/06, added: Stop Queue On Swap option, global cooldown spinners, alt+click to stop queue cancels combatqueue
3.1, 7/12/06, changed: cooldown-enabled weapons swapped in manually will not stop queue, added: "pause queue" attribute to weapons, bug fixed: error from weapon used then banked while on cooldown, removed: weapon missing checks
3.01, 7/9/06, bug fixed: hunter fd will allow swap, minimap button can turn off
3.0, 7/9/06, rewritten, auto weapon queues, new timer and cooldown/notification system, options: set menu columns, tiny tooltips, large cooldowns, show key bindings
2.7 3/30/05 - added: /weapon debug, changed: update events disabled while zoning
2.6 2/8/05 - bug fixed: minimap button movement, added: option to drag around square minimap, option to show menu on shift only
2.5 1/4/05 - added: notify at 30 sec option, changes: 1.9 scaling, uses GetItemInfo, removed: scalebugfix, cooldowns off screen check
2.4 10/21/05 - added: /weapon scale slash command, sound on notify, changed: per-character position/orientation/docking, UseInventoryItem 13 and 14 hooked to reflect use, bug fixed: added scale bug fix back in
2.3 10/2/05 - added: option to disable tooltip, changed: options movable window that defaults to center, bug fixed: logging in character without weapons won't prevent it from showing next login, for 1.8: pre-emptive fix for 1.8 SetPoint layout-cache bit, scale bug fix no longer performed
2.23 9/3/05 - bug fixed: hunter fd won't queue a weapon that can ordinarily swap, if the mod is hidden on logout it will be hidden on login
2.22 9/2/05 - bug fixed: if res'ed before releasing your spirit with weapons in queue, they'll swap on revive normally
2.21 8/21/05 - bug fixed: window scaling bug definitively fixed, and error when clicking an empty weapon slot
2.2 8/20/05 - added: swap attempts while dead will queue weapons to swap on revive, options to disable toggle, notify used only, and notify chats also, bugs fixed: error for more than 30 weapons, notify corrected, hopeful fix for location bug some have: forced start/stopmove to save to layout-cache.txt, move the window to saved point going in/out of windowed mode
2.11 8/17/05 - changed: swap attempts won't happen if anything on cursor, bug fixed: options window will appear on screen irregardless where minimap is, added: /weapon debug to help find location bug issue some see
2.1 8/17/05 - added: a resize grip to lower right corner, weapon queue, option to dock/undock, notification when weapon cooldown ends (via SCT or overhead), bugs fixed: cooldown update made less frequent, 
2.0 8/14/05 - rewritten from scratch, added up to 30+2 weapons, menu grows outward, cooldown numbers, keep menu open option, minimap icon and scaling, far better handling of bag/inventory updates, cooldown models won't update if they're off the screen
1.1 7/20/05 - only react to BAG_UPDATE every second (by Thelgar), made lock/unlock more visually apparent and moved menu closer to main window
1.0 4/8/05 - initial release

