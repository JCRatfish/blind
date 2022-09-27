local AddonName, AddonTable = ...
if not AddonTable.Ace3.Addon then return end

local Ace3 = AddonTable.Ace3
local Ace3GUI = Ace3.GUI.Lib
local Ace3GUIElements = Ace3.GUI.ELMS
local InterfaceOptions = Ace3.Modules.InterfaceOptions

local function RenderAccountabilityTab()
  if Ace3GUIElements.BlizOptionsGroup.SimpleGroup.TabGroup.ELM.localstatus.selected == "Accountability" and Ace3GUIElements.BlizOptionsGroup.SimpleGroup.TabGroup.ELM:IsVisible() then
    Ace3GUIElements.BlizOptionsGroup.SimpleGroup.TabGroup.Tabs.Accountability.functions.Render()
  end
end

local function RenderEvents(self, event)
  InterfaceOptions:RegisterEvent("PLAYER_GUILD_UPDATE", RenderAccountabilityTab)
  InterfaceOptions:RegisterEvent("GROUP_JOINED", RenderAccountabilityTab)
  InterfaceOptions:RegisterEvent("GROUP_LEFT", RenderAccountabilityTab)
  Ace3GUIElements.BlizOptionsGroup.ELM.frame:HookScript("OnShow", RenderAccountabilityTab)
end

Ace3GUIElements.EventBus:SetCallback("Ace3.Modules.InterfaceOptions.RenderEvents", RenderEvents)
