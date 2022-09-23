local AddonName, AddonTable = ...
if not AddonTable.Ace3.Addon then return end

local Ace3 = AddonTable.Ace3
local Ace3GUI = Ace3.GUI.Lib
local Ace3GUIElements = Ace3.GUI.ELMS

local function TabGroupCallback(container, event, group)
  container:SetLayout("Fill")
  container:ReleaseChildren()
  selectedTab = Ace3GUIElements.BlizOptionsGroup.SimpleGroup.TabGroup.Tabs.Accountability.TabGroup.Tabs[group]
  selectedTab.ScrollFrame = { ELM = Ace3GUI:Create("ScrollFrame") }
  selectedTab.ScrollFrame.ELM:SetLayout("List")
  container:AddChild(selectedTab.ScrollFrame.ELM)
  selectedTab.ScrollFrame.SimpleGroup = { ELM = Ace3GUI:Create("SimpleGroup") }
  selectedTab.ScrollFrame.SimpleGroup.ELM:SetFullWidth(true)
  selectedTab.ScrollFrame.SimpleGroup.ELM:SetLayout("Flow")
  selectedTab.ScrollFrame.ELM:AddChild(selectedTab.ScrollFrame.SimpleGroup.ELM)
  local selectedTabSimpleGroup = selectedTab.ScrollFrame.SimpleGroup
  if (group == "Guild") and not IsInGuild() then
    local NotInGuildMessage = Ace3GUI:Create("Label")
    NotInGuildMessage:SetText("\n" .. "Nothing to see here until you join a Guild.")
    NotInGuildMessage:SetFullWidth(true)
    NotInGuildMessage:SetJustifyH("CENTER")
    NotInGuildMessage.label:SetTextHeight(16)
    selectedTabSimpleGroup.ELM:AddChild(NotInGuildMessage)
    return
  end
  selectedTabSimpleGroup.functions = {
    Render = function(group)
      selectedTabSimpleGroup.ELM:ReleaseChildren()
      if group == "Guild" then
        selectedTabSimpleGroup.SyncLabel = { ELM = Ace3GUI:Create("Label") }
        selectedTabSimpleGroup.SyncLabel.ELM:SetFontObject(GameFontNormal)
        selectedTabSimpleGroup.SyncLabel.ELM:SetJustifyH("CENTER")
        selectedTabSimpleGroup.SyncLabel.ELM:SetFullWidth(true)
        selectedTabSimpleGroup.SyncLabel.ELM:SetText("Guild Roster is up to date!")
        selectedTabSimpleGroup.ELM:AddChild(selectedTabSimpleGroup.SyncLabel.ELM)
      end
      local RosterKey = group .."Roster"
      local Roster = Ace3.Modules.Rosters[RosterKey]
      if Roster and next(Roster.MemberCounts) and ((group == "Guild" and Roster.MemberCounts.Online > 1) or (group == "Group") and Roster.MemberCounts.Online > 0) then
        -- check addons status for headings
        local addonChecks = {
          [AddonName .."Disabled"] = false,
          [AddonName .."Outdated"] = false,
          [AddonName .."ProhibitedAddons"] = false,
        }
        for i,rosterMemberName in ipairs(Roster.MemberNamesSorted) do
          local rosterMember = Roster.Members[rosterMemberName]
          if rosterMember and rosterMember.Addons then
            local version = rosterMember.Addons[AddonName].version
            if AddonTable.Versions.Current.Major > version.Major or (AddonTable.Versions.Current.Major == version.Major and AddonTable.Versions.Current.Minor > version.Minor) or (AddonTable.Versions.Current.Major == version.Major and AddonTable.Versions.Current.Minor == version.Minor and AddonTable.Versions.Current.Patch > version.Patch) then
              addonChecks[AddonName .."Outdated"] = true
            else
              for addonName,addonData in pairs(rosterMember.Addons) do
                if addonName ~= AddonName and addonData.enabled then
                  addonChecks[AddonName .."ProhibitedAddons"] = true
                end
              end
            end
          else
            addonChecks[AddonName .."Disabled"] = true
          end
        end
        -- check if all guild members are "blindfolded"
        local isRosterBlindfolded = true
        for headingName,enabled in pairs(addonChecks) do
          if enabled then
            isRosterBlindfolded = false
          end
        end
        if isRosterBlindfolded then
          local rosterBlindfoldedLabel = Ace3GUI:Create("Label")
          rosterBlindfoldedLabel:SetText("\n" .. "All members are blindfolded!")
          rosterBlindfoldedLabel:SetFullWidth(true)
          rosterBlindfoldedLabel:SetJustifyH("CENTER")
          rosterBlindfoldedLabel.label:SetTextHeight(16)
          selectedTabSimpleGroup.ELM:AddChild(rosterBlindfoldedLabel)
          return
        else
          -- draw leadership buttons
          if group == "Guild" and (select(3, GetGuildInfo("player")) <= 1) then
            local syncLabelSpacer = Ace3GUI:Create("Label")
            syncLabelSpacer:SetFullWidth(true)
            syncLabelSpacer:SetText(" ")
            syncLabelSpacer.label:SetTextHeight(3)
            selectedTabSimpleGroup.ELM:AddChild(syncLabelSpacer)
            local leaderPrivateButtonSpacer = Ace3GUI:Create("Label")
            leaderPrivateButtonSpacer:SetRelativeWidth(0.25)
            selectedTabSimpleGroup.ELM:AddChild(leaderPrivateButtonSpacer)
          elseif group == "Group" and ((select(3, GetGuildInfo("player")) <= 1) or (UnitIsGroupLeader("player") or (IsInRaid() and (select(2, GetRaidRosterInfo(UnitInRaid("player"))) > 0)))) then
            local leaderPublicButton = Ace3GUI:Create("Button")
            leaderPublicButton:SetText("Publicly Name and Shame")
            leaderPublicButton:SetRelativeWidth(0.5)
            leaderPublicButton:SetCallback("OnClick", function()
              local chatType = nil
              if IsInRaid() then
                chatType = "RAID"
              else
                chatType = "PARTY"
              end
              for headingName,enabled in pairs(addonChecks) do
                if enabled then
                  local message, membersCount = nil, 0
                  if headingName == AddonName .."Disabled" then
                    message = "Blind AddOn missing: "
                  elseif headingName == AddonName .."Outdated" then
                    message = "Blind AddOn outdated: "
                  elseif headingName == AddonName .."ProhibitedAddons" then
                    message = "Prohibited AddOn(s) enabled: "
                  end
                  for i,rosterMemberName in ipairs(Roster.MemberNamesSorted) do
                    local rosterMember, listMember = Roster.Members[rosterMemberName], false
                    if not rosterMember.Addons then
                      if headingName == AddonName .."Disabled" then
                        listMember = true
                      end
                    else
                      if headingName == AddonName .."Outdated" then
                        local version = rosterMember.Addons[AddonName].version
                        if AddonTable.Versions.Current.Major > version.Major or (AddonTable.Versions.Current.Major == version.Major and AddonTable.Versions.Current.Minor > version.Minor) or (AddonTable.Versions.Current.Major == version.Major and AddonTable.Versions.Current.Minor == version.Minor and AddonTable.Versions.Current.Patch > version.Patch) then
                          listMember = true
                        end
                      elseif headingName == AddonName .."ProhibitedAddons" then
                        for addonName,addonData in pairs(rosterMember.Addons) do
                          if addonName ~= AddonName and addonData.enabled then
                            listMember = true
                          end
                        end
                      end
                    end
                    if listMember then
                      membersCount = membersCount+1
                      if membersCount > 1 then
                        message = message ..", "
                      end
                      message = message .. rosterMemberName
                    end
                  end
                  SendChatMessage("[ALERT] ".. message, chatType)
                end
              end
            end)
            selectedTabSimpleGroup.ELM:AddChild(leaderPublicButton)
          end
          if (select(3, GetGuildInfo("player")) <= 1) or (group == "Group" and (UnitIsGroupLeader("player") or (IsInRaid() and (select(2, GetRaidRosterInfo(UnitInRaid("player"))) > 0)))) then
            local leaderPrivateButton = Ace3GUI:Create("Button")
            leaderPrivateButton:SetText("Privately Name and Shame")
            leaderPrivateButton:SetRelativeWidth(0.5)
            leaderPrivateButton:SetCallback("OnClick", function()
              for i,rosterMemberName in ipairs(Roster.MemberNamesSorted) do
                local rosterMember = Roster.Members[rosterMemberName]
                local message = nil
                if not rosterMember.Addons then
                  message = "Your Blind AddOn is disabled or not installed!"
                else
                  local version = rosterMember.Addons[AddonName].version
                  if AddonTable.Versions.Current.Major > version.Major or (AddonTable.Versions.Current.Major == version.Major and AddonTable.Versions.Current.Minor > version.Minor) or (AddonTable.Versions.Current.Major == version.Major and AddonTable.Versions.Current.Minor == version.Minor and AddonTable.Versions.Current.Patch > version.Patch) then
                    message = "You have an outdated version of the Blind AddOn!"
                  else
                    message = "You have prohibited AddOn(s) enabled: "
                    local prohibitedAddonsEnabledCount = 0
                    for addonName,addonData in pairs(rosterMember.Addons) do
                      if addonName ~= AddonName and addonData.enabled then
                        prohibitedAddonsEnabledCount = prohibitedAddonsEnabledCount+1
                        if prohibitedAddonsEnabledCount > 1 then
                          message = message ..", "
                        end
                        message = message .. addonName
                      end
                    end
                  end
                end
                SendChatMessage("[ALERT] ".. message, "WHISPER", AddonTable.Player.LanguageID, rosterMemberName)
              end
            end)
            selectedTabSimpleGroup.ELM:AddChild(leaderPrivateButton)
          end
        end
        -- setup headings
        local headings = {
          {[AddonName .."Disabled"] = {text = "Blind AddOn Missing"}},
          {[AddonName .."Outdated"] = {text = "Blind AddOn Outdated"}},
          {[AddonName .."ProhibitedAddons"] = {text = "Prohibited AddOn(s) Enabled"}},
        }
        for i,headingEntry in ipairs(headings) do
          for headingName,headingParams in pairs(headingEntry) do
            local heading = Ace3GUI:Create("Heading")
            heading.label:SetTextHeight(16)
            heading:SetFullWidth(true)
            heading:SetHeight(32)
            heading:SetText(headingParams.text)
            selectedTabSimpleGroup[headingName] = { ELM = heading }
            if addonChecks[headingName] then
              selectedTabSimpleGroup.ELM:AddChild(heading)
              selectedTabSimpleGroup.functions.CreatePlayerButtons(headingName)
            end
          end
        end
      else
        local noPlayersLabel = Ace3GUI:Create("Label")
        noPlayersLabel:SetText("\n" .. "No other members are online.")
        noPlayersLabel:SetFullWidth(true)
        noPlayersLabel:SetJustifyH("CENTER")
        noPlayersLabel.label:SetTextHeight(16)
        selectedTabSimpleGroup.ELM:AddChild(noPlayersLabel)
      end
    end,
    CreatePlayerButtons = function(headingName)
      local drawPlayerButton = function(rosterMemberName, rosterMember)
        local button = Ace3GUI:Create("Button")
        button:SetText(WrapTextInColorCode(rosterMemberName, Ace3.Modules.Helpers.GetRaidClassColorCode(rosterMember.RaidClassName)))
        button:SetRelativeWidth(0.25)
        if (select(3, GetGuildInfo("player")) <= 1) or (group == "Group" and (UnitIsGroupLeader("player") or (IsInRaid() and (select(2, GetRaidRosterInfo(UnitInRaid("player"))) > 0)))) then
          button:SetDisabled(false)
        else
          button:SetDisabled(true)
        end
        button:SetCallback("OnClick", function()
          local message = nil
          if not rosterMember.Addons then
            message = "Your Blind AddOn is disabled or not installed!"
          else
            local version = rosterMember.Addons[AddonName].version
            if AddonTable.Versions.Current.Major > version.Major or (AddonTable.Versions.Current.Major == version.Major and AddonTable.Versions.Current.Minor > version.Minor) or (AddonTable.Versions.Current.Major == version.Major and AddonTable.Versions.Current.Minor == version.Minor and AddonTable.Versions.Current.Patch > version.Patch) then
              message = "You have an outdated version of the Blind AddOn!"
            else
              message = "You have prohibited AddOn(s) enabled: "
              local prohibitedAddonsEnabledCount = 0
              for addonName,addonData in pairs(rosterMember.Addons) do
                if addonName ~= AddonName and addonData.enabled then
                  prohibitedAddonsEnabledCount = prohibitedAddonsEnabledCount+1
                  if prohibitedAddonsEnabledCount > 1 then
                    message = message ..", "
                  end
                  message = message .. addonName
                end
              end
            end
          end
          SendChatMessage("[ALERT] ".. message, "WHISPER", AddonTable.Player.LanguageID, rosterMemberName)
        end)
        selectedTabSimpleGroup.ELM:AddChild(button)
      end
      local Roster = Ace3.Modules.Rosters[group .."Roster"]
      if Roster then
        for i,rosterMemberName in ipairs(Roster.MemberNamesSorted) do
          local rosterMember = Roster.Members[rosterMemberName]
          if rosterMember then
            if headingName == AddonName .."Disabled" then
              if not rosterMember.Addons then
                drawPlayerButton(rosterMemberName, rosterMember)
              end
            elseif headingName == AddonName .."Outdated" then
              if rosterMember.Addons then
                local version = rosterMember.Addons[AddonName].version
                if AddonTable.Versions.Current.Major > version.Major or (AddonTable.Versions.Current.Major == version.Major and AddonTable.Versions.Current.Minor > version.Minor) or (AddonTable.Versions.Current.Major == version.Major and AddonTable.Versions.Current.Minor == version.Minor and AddonTable.Versions.Current.Patch > version.Patch) then
                  drawPlayerButton(rosterMemberName, rosterMember)
                end
              end
            elseif headingName == AddonName .."ProhibitedAddons" then
              if rosterMember.Addons then
                local prohibitedAddonsEnabled = false
                for addonName,addonData in pairs(rosterMember.Addons) do
                  if addonName ~= AddonName and addonData.enabled then
                    prohibitedAddonsEnabled = true
                  end
                end
                local version = rosterMember.Addons[AddonName].version
                if AddonTable.Versions.Current.Major > version.Major or (AddonTable.Versions.Current.Major == version.Major and AddonTable.Versions.Current.Minor > version.Minor) or (AddonTable.Versions.Current.Major == version.Major and AddonTable.Versions.Current.Minor == version.Minor and AddonTable.Versions.Current.Patch > version.Patch) then
                  -- version is outdated, ignore addon data
                elseif prohibitedAddonsEnabled then
                  drawPlayerButton(rosterMemberName, rosterMember)
                end
              end
            end
          end
        end
      end
    end
  }
  selectedTabSimpleGroup.functions.Render(group)
  selectedTab.ScrollFrame.ELM:DoLayout()
end

local function Render(self, event)
  local MainTabGroup = Ace3GUIElements.BlizOptionsGroup.SimpleGroup.TabGroup
  MainTabGroup.Tabs.Accountability.functions = {
    Render = function()
      local selectedTab = MainTabGroup.Tabs.Accountability
      MainTabGroup.ELM:ReleaseChildren()
      local tabGroup, tabGroupTabs = Ace3GUI:Create("TabGroup"), {}
      selectedTab.TabGroup = { ELM = tabGroup, Tabs = {} }
      tabGroup:SetLayout("Fill")
      if IsInGroup() or IsInRaid() then
        table.insert(tabGroupTabs, {text="Group", value="Group"})
      end
      table.insert(tabGroupTabs, {text="Guild", value="Guild"})
      tabGroup:SetTabs(tabGroupTabs)
      for i,tab in ipairs(selectedTab.TabGroup.ELM.tabs) do
        selectedTab.TabGroup.Tabs[tab.value] = { ELM = tab }
      end
      tabGroup:SetCallback("OnGroupSelected", TabGroupCallback)
      tabGroup:SelectTab("Guild")
      if IsInGroup() or IsInRaid() then
        tabGroup:SelectTab("Group")
      end
      MainTabGroup.ELM:AddChild(tabGroup)
    end
  }
  MainTabGroup.Tabs.Accountability.functions.Render()
end

Ace3GUIElements.EventBus:SetCallback("BlizOptionsGroup.SimpleGroup.MainTabGroup.Accountability.Render", Render)
