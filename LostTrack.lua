--[[ Lost Track - automatic hunter tracking for WotLK 3.3.5
     Keeps the hunter's tracking on the target's creature type: target a beast
     and Track Beasts goes up, target a humanoid and Track Humanoids replaces
     it. With no target, the tracking that was up before Lost Track took over
     (Find Herbs, Track Undead, ...) is restored, or none if there was none.
     A tracking you switch to yourself after that is left alone: only the
     tracking this addon put up is ever changed back.

     /lt on|off   enable or disable
     /lt status   show what it is doing
     (long form: /losttrack)

     File layout: Logging > Data > Tracking > Events > Slash.
]]

local ADDON_NAME = ...
local _, MY_CLASS = UnitClass("player") -- never changes, so looked up once
local db
local applied -- index of the tracking type Lost Track set, nil when it set none
local saved   -- index of the tracking it replaced, restored once the target is gone (nil = none)

---------------------------------------------------------------------------
-- Logging
---------------------------------------------------------------------------
local TAG = "|cff33ff99Lost Track|r"
local ADDON_VERSION = GetAddOnMetadata("LostTrack", "Version") or "?"
local function Log(msg) DEFAULT_CHAT_FRAME:AddMessage(TAG .. " " .. msg) end
local function LogLoad(hint) Log("v" .. ADDON_VERSION .. " loaded." .. (hint and (" " .. hint) or "")) end

---------------------------------------------------------------------------
-- Data
---------------------------------------------------------------------------
local DEFAULTS = { enabled = true }

local function InitDB()
	LostTrackDB = LostTrackDB or {}
	for k, v in pairs(DEFAULTS) do
		if LostTrackDB[k] == nil then LostTrackDB[k] = v end
	end
	db = LostTrackDB
end

---------------------------------------------------------------------------
-- Tracking
---------------------------------------------------------------------------
-- index of the tracking type for a creature type, or nil when the client has
-- none for it (critters, totems, mechanicals, ...). Plain find: "Track Beasts"
-- contains "beast", so the plural tracking names match their singular type.
local function TrackingFor(creatureType)
	local needle = creatureType:lower()
	for i = 1, GetNumTrackingTypes() do
		local name = GetTrackingInfo(i)
		if name and name:lower():find(needle, 1, true) then return i end
	end
end

-- index of the tracking type that is active right now, or nil
local function CurrentTracking()
	local texture = GetTrackingTexture()
	if not texture then return nil end
	for i = 1, GetNumTrackingTypes() do
		if select(2, GetTrackingInfo(i)) == texture then return i end
	end
end

-- Bring tracking in line with the current target. `applied` is the type Lost
-- Track set and `saved` the tracking it replaced; with no target the player
-- gets that original tracking back. Clearing never touches a tracking the
-- player chose themselves (e.g. Find Herbs) or one they switched to after the
-- addon picked.
local function Update()
	if not db or not db.enabled or MY_CLASS ~= "HUNTER" then return end

	-- Target cleared: put back the tracking Lost Track replaced
	if not UnitExists("target") then
		if applied then
			-- skip while tracking is no longer the type we set, or when the
			-- type to restore is already active: SetTracking on the active
			-- type would toggle tracking off
			if CurrentTracking() == applied and saved ~= applied then
				SetTracking(saved) -- nil when the player had no tracking before
			end
			applied = nil
			saved = nil
		end
		return
	end

	local creatureType = UnitCreatureType("target")
	if not creatureType then return end

	local index = TrackingFor(creatureType)
	if not index then return end -- nothing tracks this type, leave tracking alone

	local current = CurrentTracking()
	if current ~= index then
		-- Remember the player's own tracking, unless what is up is a type we
		-- set ourselves for an earlier target.
		if not applied or current ~= applied then
			saved = current
		end
		SetTracking(index)
		applied = index
	end
end

---------------------------------------------------------------------------
-- Status & slash command
---------------------------------------------------------------------------
local function Status()
	local state = db.enabled and "|cff00ff00ON|r" or "|cffff0000OFF|r"
	if MY_CLASS ~= "HUNTER" then
		Log("Lost Track is " .. state .. ", but this character is not a hunter, so it sits idle.")
		return
	end
	local index = CurrentTracking()
	local name = index and GetTrackingInfo(index) or "off"
	if not UnitExists("target") then
		Log("Lost Track is " .. state .. ". No target; tracking is " .. name .. ".")
	else
		Log(string.format("Lost Track is %s. Target: %s; tracking is %s.",
			state, UnitCreatureType("target") or "unknown", name))
	end
end

local function PrintHelp()
	Log("commands:")
	DEFAULT_CHAT_FRAME:AddMessage("  /lt on | off | toggle  - enable or disable")
	DEFAULT_CHAT_FRAME:AddMessage("  /lt status  - show what it is doing")
end

SLASH_LOSTTRACK1 = "/losttrack"
SLASH_LOSTTRACK2 = "/lt"
SlashCmdList["LOSTTRACK"] = function(msg)
	if not db then return end

	local cmd = strlower(strtrim(msg or ""))
	if cmd == "on" then
		db.enabled = true
		Update()
		Status()
	elseif cmd == "off" then
		db.enabled = false
		Status()
	elseif cmd == "toggle" then
		db.enabled = not db.enabled
		Update()
		Status()
	elseif cmd == "status" then
		Status()
	else
		Status()
		PrintHelp()
	end
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------
local frame = CreateFrame("Frame")

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_TARGET_CHANGED")

frame:SetScript("OnEvent", function(self, event, arg1)
	if event == "ADDON_LOADED" then
		if arg1 ~= ADDON_NAME then return end
		InitDB()
		self:UnregisterEvent("ADDON_LOADED")
		if MY_CLASS == "HUNTER" then
			LogLoad("/lt to toggle.")
		else
			LogLoad("only hunters track; Lost Track sits idle on this character.")
		end
		return
	end
	-- a new or cleared target, or a zone-in with a target already up
	Update()
end)
