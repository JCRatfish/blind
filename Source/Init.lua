local AddonName, AddonTable = ...
local AddonNameVerification = "Blind"
if (AddonName ~= AddonNameVerification) or (not LibStub) then return end

-- Put all the Ace3 stuff in one place
AddonTable.Ace3 = {
  GUI = {
    Lib = LibStub("AceGUI-3.0"),
    ELMS = {} -- Elements
  },
  Addon = LibStub("AceAddon-3.0"):NewAddon(AddonName, "AceConsole-3.0"),
  Modules = {}
}

-- Create frame for handling custom events
AddonTable.Ace3.GUI.ELMS.EventBus = AddonTable.Ace3.GUI.Lib:Create("SimpleGroup")

-- Debug control
AddonTable.Debug = false

-- Store version converted to integers
AddonTable.Versions = { Current = {}, New = {} }
AddonTable.Versions.Current.Major, AddonTable.Versions.Current.Minor, AddonTable.Versions.Current.Patch = strsplit(".", GetAddOnMetadata(AddonName, "Version"))
AddonTable.Versions.Current.Major, AddonTable.Versions.Current.Minor, AddonTable.Versions.Current.Patch = tonumber(AddonTable.Versions.Current.Major), tonumber(AddonTable.Versions.Current.Minor), tonumber(AddonTable.Versions.Current.Patch)

-- Get player data
AddonTable.Player = {
  GUID = UnitGUID("player"),
  Name = UnitName("player"),
  LanguageID = select(2, GetDefaultLanguage()),
}

-- Set prohibited addons
AddonTable.ProhibitedAddons = {
  { name = "BigWigs" },
  { name = "DBM-Core" },
  { name = "PlexusStatusRaidDebuff" },
  { name = "TellMeWhen" },
  { name = "VocalRaidAssistant" },
  { name = "WeakAuras" },
}
