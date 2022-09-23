local AddonName, AddonTable = ...
if not AddonTable.Ace3.Addon then return end

local Ace3 = AddonTable.Ace3
local Ace3GUI = Ace3.GUI.Lib
local Ace3GUIElements = Ace3.GUI.ELMS

local function TabGroupCallback(container, event, group)
  container:SetAutoAdjustHeight(true)
  container:ReleaseChildren()
  if group == "Flagged" then
    --TODO: LIST FLAGGED USERS
    Ace3.Modules.Helpers.PrintDebugDump("Flagged")
    for key,value in BlindDB["flagged"] do
        Ace3.Modules.Helpers.PrintDebugDump("test")
    end
  elseif group == "Verify" then
    local ValidationBox = Ace3GUI:Create("MultiLineEditBox")
    ValidationBox:SetLabel("Paste the user's validation string below:")
    ValidationBox:SetFullWidth(true)
    ValidationBox:DisableButton(true)
    ValidationBox:SetNumLines(5)
    container:AddChild(ValidationBox)
    local ViewingBox = Ace3GUI:Create("MultiLineEditBox")
    ViewingBox:SetLabel("Account Logs:")
    ViewingBox:SetFullWidth(true)
    ViewingBox:DisableButton(true)
    ViewingBox:SetNumLines(19)
    local SelectButton = Ace3GUI:Create("Button")
    SelectButton:SetText("Decode Validation String")
    SelectButton:SetCallback("OnClick", function()
        local string = ValidationBox:GetText()
        -- TODO: DECODE STRING
        ViewingBox:SetText(string)
    end)
    container:AddChild(SelectButton)
    container:AddChild(ViewingBox)
  end
end

local function Render(self, event)
  local tabGroup, tabs = Ace3GUI:Create("TabGroup"), {
    {text="Flagged Users", value="Flagged"},
    {text="Verify User", value="Verify"},
  }
  tabGroup:SetTabs(tabs)
  tabGroup:SetCallback("OnGroupSelected", TabGroupCallback)
  tabGroup:SelectTab("Flagged")
  Ace3GUIElements.BlizOptionsGroup.SimpleGroup.TabGroup.ELM:AddChild(tabGroup)
end

Ace3GUIElements.EventBus:SetCallback("BlizOptionsGroup.SimpleGroup.MainTabGroup.Account.Render", Render)
