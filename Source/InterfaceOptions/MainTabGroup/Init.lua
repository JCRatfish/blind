local AddonName, AddonTable = ...
if not AddonTable.Ace3.Addon then return end

local Ace3 = AddonTable.Ace3
local Ace3GUI = Ace3.GUI.Lib
local Ace3GUIElements = Ace3.GUI.ELMS

local function Render(self, event)
  local tabGroup, tabGroupTabs = Ace3GUI:Create("TabGroup"), {}
  Ace3GUIElements.BlizOptionsGroup.SimpleGroup.TabGroup = { ELM = tabGroup, Tabs = {} }

  table.insert(tabGroupTabs, {text="Accountability", value="Accountability"})
  -- if IsInGuild() and (select(3, GetGuildInfo("player")) < 2) then
  --   table.insert(tabGroupTabs,{text="Admin Verification", value="Account"})
  -- end
  if AddonTable.Debug then
    table.insert(tabGroupTabs, {text="Debug", value="Debug"})
  end
  tabGroup:SetTabs(tabGroupTabs)
  for i,tab in ipairs(Ace3GUIElements.BlizOptionsGroup.SimpleGroup.TabGroup.ELM.tabs) do
    Ace3GUIElements.BlizOptionsGroup.SimpleGroup.TabGroup.Tabs[tab.value] = { ELM = tab }
  end

  tabGroup:SetCallback("OnGroupSelected", function(container, event, group)
    container:SetLayout("Fill")
    container:ReleaseChildren()
    Ace3GUIElements.EventBus:Fire("BlizOptionsGroup.SimpleGroup.MainTabGroup.".. group ..".Render")
  end)

  tabGroup:SelectTab("Accountability")
  Ace3GUIElements.BlizOptionsGroup.SimpleGroup.ELM:AddChild(tabGroup)
end

Ace3GUIElements.EventBus:SetCallback("BlizOptionsGroup.SimpleGroup.MainTabGroup.Render", Render)
