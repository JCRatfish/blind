local AddonName, AddonTable = ...
if not AddonTable.Ace3.Addon then return end

local Ace3 = AddonTable.Ace3
local Ace3GUIElements = Ace3.GUI.ELMS
local Blind = Ace3.Addon

function Blind:OnInitialize()
  Ace3.Database = LibStub("AceDB-3.0"):New(AddonName .."DB", {
    profile = { minimap = { hide = false } }
  })
  self:RegisterChatCommand(string.lower(AddonName), function()
    InterfaceOptionsFrame_OpenToCategory(AddonName)
  end)
  self:MinimapButton()
end

function Blind:MinimapButton()
  local minimapButton = LibStub("LibDataBroker-1.1"):NewDataObject("Blind", {
    type = "data source",
    text = "Blind",
    icon = "Interface\\AddOns\\Blind\\Media\\blind-minimap.blp",
    OnClick = function(self, btn)
      -- Prevent options panel from showing if Blizzard Store is showing
      if StoreFrame and StoreFrame:GetAttribute("isshown") then
        return
      end
      if btn == "LeftButton" then
        if Ace3GUIElements.BlizOptionsGroup.ELM:IsVisible() then
          InterfaceOptionsFrame_Show()
        else
          InterfaceOptionsFrame_OpenToCategory(AddonName)
        end
      end
    end,
    OnTooltipShow = function(tooltip)
      if not tooltip or not tooltip.AddLine then
        return
      end
      tooltip:AddLine("Blind ("..GetAddOnMetadata("Blind", "Version")..")")
      tooltip:AddLine(WrapTextInColorCode("Left Click", "FFCFCFCF") ..": Toggle Window")
    end
  })
  LibStub("LibDBIcon-1.0"):Register("BlindMMI", minimapButton, Ace3.Database.profile.minimap)
end
