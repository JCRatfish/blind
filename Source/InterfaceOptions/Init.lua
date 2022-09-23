local AddonName, AddonTable = ...
if not AddonTable.Ace3.Addon then return end

local Ace3 = AddonTable.Ace3
local Ace3GUI = Ace3.GUI.Lib
local Ace3GUIElements = Ace3.GUI.ELMS
local InterfaceOptions = Ace3.Addon:NewModule("InterfaceOptions", "AceEvent-3.0")
Ace3.Modules.InterfaceOptions = InterfaceOptions

function InterfaceOptions:OnEnable()
  Ace3GUIElements.BlizOptionsGroup = { ELM = Ace3GUI:Create("BlizOptionsGroup") }
  Ace3GUIElements.BlizOptionsGroup.ELM:SetName(AddonName)
  Ace3GUIElements.BlizOptionsGroup.ELM:SetLayout("Fill")
  Ace3GUIElements.BlizOptionsGroup.ELM:SetTitle(AddonName)
  Ace3GUIElements.BlizOptionsGroup.ELM.label:SetPoint("TOPLEFT", 16, -16) -- set title position to match Blizzard interface options, AceGUI does not do this by default

  Ace3GUIElements.BlizOptionsGroup.SimpleGroup = { ELM = Ace3GUI:Create("SimpleGroup") }
  Ace3GUIElements.BlizOptionsGroup.SimpleGroup.ELM:SetFullWidth(true)
  Ace3GUIElements.BlizOptionsGroup.SimpleGroup.ELM:SetLayout("Fill")
  Ace3GUIElements.BlizOptionsGroup.ELM:AddChild(Ace3GUIElements.BlizOptionsGroup.SimpleGroup.ELM)
  Ace3GUIElements.EventBus:Fire("BlizOptionsGroup.SimpleGroup.MainTabGroup.Render")

  InterfaceOptions_AddCategory(Ace3GUIElements.BlizOptionsGroup.ELM.frame)
  InterfaceAddOnsList_Update() -- force update required
  Ace3GUIElements.BlizOptionsGroup.ELM.frame.default = function() AddonTable.Ace3.Database:ResetProfile() end

  Ace3GUIElements.EventBus:Fire("Ace3.Modules.InterfaceOptions.RenderEvents")
end
