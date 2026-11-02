--[[ Lost Track - automatic hunter tracking for WotLK 3.3.5
     While in combat, keeps the hunter's tracking on the target's creature
     type: target a beast and Track Beasts goes up, target a humanoid and
     Track Humanoids replaces it. Tracking is never touched out of combat.
     Losing the target in combat, or combat ending, turns tracking off
     entirely (no previous tracking is restored).

     /lt on|off   enable or disable
     /lt status   show what it is doing
     (long form: /losttrack)

     File layout: Logging > Data > Tracking > Events > Slash.
]]

local ADDON_NAME = ...
local _, MY_CLASS = UnitClass("player") -- never changes, so looked up once
local db
local engaged -- Lost Track is controlling tracking for this combat

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

-- Turn tracking off. In 3.3.5 SetTracking(nil) is the "None" option.
local function ClearTracking()
	if CurrentTracking() then
		SetTracking(nil)
	end
end

-- Bring tracking in line with the current target, in combat only. Out of
-- combat tracking belongs to the player and is never touched.
local function Update()
	if not db or not db.enabled or MY_CLASS ~= "HUNTER" then return end
	if not UnitAffectingCombat("player") then return end
	engaged = true

	local index
	if UnitExists("target") then
		local creatureType = UnitCreatureType("target")
		if creatureType then index = TrackingFor(creatureType) end
	end

	if index then
		if CurrentTracking() ~= index then
			SetTracking(index)
		end
	else
		-- no target, target deselected, or a creature type with no tracking
		ClearTracking()
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
	local when = UnitAffectingCombat("player") and "in combat" or "out of combat"
	if not UnitExists("target") then
		Log(string.format("Lost Track is %s (%s). No target; tracking is %s.", state, when, name))
	else
		Log(string.format("Lost Track is %s (%s). Target: %s; tracking is %s.",
			state, when, UnitCreatureType("target") or "unknown", name))
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
		engaged = false -- leave tracking alone once disabled
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
frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")

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
	-- combat over: tracking off, nothing restored
	if event == "PLAYER_REGEN_ENABLED" then
		if engaged then
			engaged = false
			if db and db.enabled and MY_CLASS == "HUNTER" then
				ClearTracking()
			end
		end
		return
	end
	-- entering combat, a new or cleared target, or a zone-in with combat running
	Update()
end)
