local AddonName, AddonTable = ...
if not AddonTable.Ace3.Addon then return end

local Ace3 = AddonTable.Ace3
local Ace3GUI = Ace3.GUI.Lib
local Ace3GUIElements = Ace3.GUI.ELMS

local function Render(self, event)
  local MainTabGroup = Ace3GUIElements.BlizOptionsGroup.SimpleGroup.TabGroup
  MainTabGroup.ELM:SetLayout("List")

  local Label = { ELM = Ace3GUI:Create("Label") }
  Label.ELM:SetText("\n" .. "Test label")
  MainTabGroup.ELM:AddChild(Label.ELM)

  local button = Ace3GUI:Create("Button")
  button:SetText("Print Debug Data")
  button:SetCallback("OnClick", function()
    Ace3.Modules.Helpers.PrintDebugDump(Ace3.Modules.Rosters.GroupRoster)
  end)
  MainTabGroup.ELM:AddChild(button)
end

Ace3GUIElements.EventBus:SetCallback("BlizOptionsGroup.SimpleGroup.MainTabGroup.Debug.Render", Render)
