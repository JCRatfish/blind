local AddonName, AddonTable = ...
if not AddonTable.Ace3.Addon then return end

local Ace3 = AddonTable.Ace3
local Ace3GUIElements = Ace3.GUI.ELMS
local Communication = Ace3.Addon:NewModule("Communication", "AceComm-3.0", "AceEvent-3.0", "AceSerializer-3.0")
Ace3.Modules.Communication = Communication

function Communication:OnEnable()
  Communication.Channels = {
    Rosters = {
      Payloads = {},
      BuildCommMessage = function(type, recipient)
        local message = Communication.BuildMessage("Rosters")
        message.type = type
        message.recipient = recipient
        message.payload[AddonName] = { enabled = (GetAddOnEnableState(AddonTable.Player.Name, AddonName) == 2), version = {} }
        message.payload[AddonName].version.Major, message.payload[AddonName].version.Minor, message.payload[AddonName].version.Patch = strsplit(".", GetAddOnMetadata(AddonName, "Version"))
        message.payload[AddonName].version.Major, message.payload[AddonName].version.Minor, message.payload[AddonName].version.Patch = tonumber(message.payload[AddonName].version.Major), tonumber(message.payload[AddonName].version.Minor), tonumber(message.payload[AddonName].version.Patch)
        for i,addon in ipairs(AddonTable.ProhibitedAddons) do
          message.payload[addon.name] = { enabled = (GetAddOnEnableState(AddonTable.Player.Name, addon.name) == 2) }
        end
        return Communication:Serialize(message)
      end,
      SendCommMessage = function(type, group, guild)
        local distribution = nil
        if IsInRaid() then
          distribution = "RAID"
        elseif IsInGroup() then
          distribution = "PARTY"
        end
        if distribution and group then
          Communication:SendCommMessage(AddonName, Communication.Channels.Rosters.BuildCommMessage(type), distribution, AddonTable.Player.Name)
          distribution = nil
        end
        if IsInGuild() then
          distribution = "GUILD"
        end
        if distribution and guild then
          Communication:SendCommMessage(AddonName, Communication.Channels.Rosters.BuildCommMessage(type), distribution, AddonTable.Player.Name)
        end
      end,
      RegisterComm = function(prefix, message, distribution, sender)
        if (message.channel == "Rosters") and (sender ~= AddonTable.Player.Name) then
          if message.type == "purge" then
            Communication.Channels.Rosters.Payloads[sender] = nil
            -- Ace3.Modules.Helpers.PrintDebugDump({OnCommReceived = { distribution = distribution, sender = sender, message = message }})
          elseif message.type == "request" then
            Communication.Channels.Rosters.Payloads[sender] = message.payload
            Communication:SendCommMessage(AddonName, Communication.Channels.Rosters.BuildCommMessage("response", sender), distribution) -- reply to a request
            -- Ace3.Modules.Helpers.PrintDebugDump({OnCommReceived = { distribution = distribution, sender = sender, message = message }})
          elseif (message.type == "response") and (message.recipient == AddonTable.Player.Name) then
            Communication.Channels.Rosters.Payloads[sender] = message.payload
            -- Ace3.Modules.Helpers.PrintDebugDump({OnCommReceived = { distribution = distribution, sender = sender, message = message }})
          end
          -- Check for newer version and notify player
          if Communication.Channels.Rosters.Payloads[sender] then
            local version = Communication.Channels.Rosters.Payloads[sender][AddonName].version
            if not next(AddonTable.Versions.New) then
              if AddonTable.Versions.Current.Major < version.Major or (AddonTable.Versions.Current.Major == version.Major and AddonTable.Versions.Current.Minor < version.Minor) or (AddonTable.Versions.Current.Major == version.Major and AddonTable.Versions.Current.Minor == version.Minor and AddonTable.Versions.Current.Patch < version.Patch) then
                AddonTable.Versions.New = version
                Ace3.Addon:Print(WrapTextInColorCode("[ALERT]", "FFFF0000") .." You have an outdated version of the Blind AddOn!")
              end
            end
          end
          -- GUI updates
          if ((distribution == "PARTY") or (distribution == "RAID")) and Ace3.Modules.Rosters.GroupRoster.Members then
            local groupRosterMember = Ace3.Modules.Rosters.GroupRoster.Members[sender]
            if groupRosterMember then
              groupRosterMember.Addons = Communication.Channels.Rosters.Payloads[sender]
              if Ace3GUIElements.BlizOptionsGroup.SimpleGroup.TabGroup.Tabs.Accountability.TabGroup.ELM.localstatus.selected == "Group" then
                Ace3GUIElements.BlizOptionsGroup.SimpleGroup.TabGroup.Tabs.Accountability.TabGroup.Tabs.Group.ScrollFrame.SimpleGroup.functions.Render("Group")
              end
            end
          elseif (distribution == "GUILD") and Ace3.Modules.Rosters.GuildRoster.Members then
            local guildRosterMember = Ace3.Modules.Rosters.GuildRoster.Members[sender]
            if guildRosterMember then
              guildRosterMember.Addons = Communication.Channels.Rosters.Payloads[sender]
              if Ace3GUIElements.BlizOptionsGroup.SimpleGroup.TabGroup.Tabs.Accountability.TabGroup.ELM.localstatus.selected == "Guild" then
                Ace3GUIElements.BlizOptionsGroup.SimpleGroup.TabGroup.Tabs.Accountability.TabGroup.Tabs.Guild.ScrollFrame.SimpleGroup.functions.Render("Guild")
              end
            end
          end
        end
      end,
      RegisterEvents = {
        --- Send a request to guild on login, or group and guild after /reload
        PLAYER_ENTERING_WORLD = function(event, isInitialLogin, isReloadingUi)
          -- Ace3.Modules.Helpers.PrintDebugDump({ [event] = { isInitialLogin = isInitialLogin, isReloadingUi = isReloadingUi } })
          if isInitialLogin then
            -- Communication.Channels.Rosters.SendCommMessage("request", false, true)
          elseif isReloadingUi then
            if IsInRaid() or IsInGroup() then
              Ace3.Modules.Rosters:SetupGroupRoster()
              Ace3.Modules.Rosters.GROUP_ROSTER_UPDATE("GROUP_ROSTER_UPDATE")
            end
            if IsInGuild() and (not Ace3.Modules.Rosters.GuildRoster or not next(Ace3.Modules.Rosters.GuildRoster.MemberCounts)) then
              Ace3.Modules.Rosters:SetupGuildRoster()
            end
            Communication.Channels.Rosters.SendCommMessage("request", true, true)
          else
            -- when entering an instance notify the player if they have prohibited addons enabled
            if IsInRaid() or IsInGroup() or IsInGuild() then
              local isInInstance, instanceType = IsInInstance()
              if isInInstance and (instanceType == "party" or instanceType == "raid") then
                local enabledProhibitedAddons = {}
                for i,addon in ipairs(AddonTable.ProhibitedAddons) do
                  if (GetAddOnEnableState(AddonTable.Player.Name, addon.name) == 2) then
                    table.insert(enabledProhibitedAddons, addon.name)
                  end
                end
                if next(enabledProhibitedAddons) then
                  local alert = WrapTextInColorCode("[ALERT]", "FFFF0000")
                  alert = alert .." Prohibited AddOn(s) are enabled! Please disable the following: "
                  for i,addon in ipairs(enabledProhibitedAddons) do
                    if i > 1 then
                      alert = alert ..", "
                    end
                    alert = alert .. addon
                  end
                  Ace3.Addon:Print(alert)
                end
              end
            end
          end
        end,
        --- Purge payload data from other clients, only fires on /reload
        PLAYER_LEAVING_WORLD = function(event)
          -- Ace3.Modules.Helpers.PrintDebug(event)
          Communication.Channels.Rosters.SendCommMessage("purge", true, true)
        end,
        --- Send a request after joining a group
        GROUP_JOINED = function(event)
          -- Ace3.Modules.Helpers.PrintDebug(event)
          Ace3.Modules.Rosters:SetupGroupRoster()
          Communication.Channels.Rosters.SendCommMessage("request", true, false)
        end,
        --- Reset GroupRoster and update GUI after leaving a group
        GROUP_LEFT = function(event)
          -- Ace3.Modules.Helpers.PrintDebug(event)
          Ace3.Modules.Rosters:ShutdownGroupRoster()
        end,
        --- Reset GuildRoster and update GUI after joining/leaving guild
        PLAYER_GUILD_UPDATE = function(event)
          -- Ace3.Modules.Helpers.PrintDebug(event)
          if IsInGuild() and (not Ace3.Modules.Rosters.GuildRoster or not next(Ace3.Modules.Rosters.GuildRoster.MemberCounts)) then
            Ace3.Modules.Rosters:SetupGuildRoster()
            Communication.Channels.Rosters.SendCommMessage("request", false, true)
            GuildRoster()
            if Ace3GUIElements.BlizOptionsGroup.SimpleGroup.TabGroup.ELM.localstatus.selected == "Accountability" then
              Ace3GUIElements.BlizOptionsGroup.SimpleGroup.TabGroup.Tabs.Accountability.functions.Render()
            end
          elseif not IsInGuild() and Ace3.Modules.Rosters.GuildRoster then
            Ace3.Modules.Rosters:ShutdownGuildRoster()
            if Ace3GUIElements.BlizOptionsGroup.SimpleGroup.TabGroup.ELM.localstatus.selected == "Accountability" then
              Ace3GUIElements.BlizOptionsGroup.SimpleGroup.TabGroup.Tabs.Accountability.functions.Render()
            end
          end
        end,
      }
    },
  }

  -- register channel comms
  self:RegisterComm(AddonName, function(prefix, text, distribution, sender)
    local _, message = Communication:Deserialize(text)
    for ChannelName,Channel in pairs(Communication.Channels) do
      if ChannelName == message.channel then
        Channel.RegisterComm(prefix, message, distribution, sender)
      end
    end
  end)

  -- events may only be registered once per module so they are collected here and registered together
  local EventsToRegister = {}
  for ChannelName,Channel in pairs(Communication.Channels) do
    for EventName,EventCallback in pairs(Channel.RegisterEvents) do
      if EventsToRegister[EventName] then
        table.insert(EventsToRegister[EventName], EventCallback)
      else
        EventsToRegister[EventName] = {}
        table.insert(EventsToRegister[EventName], EventCallback)
      end
    end
  end
  -- register collected events
  for EventName,EventCallbacks in pairs(EventsToRegister) do
    local EventCallback = function(...)
      -- Ace3.Modules.Helpers.PrintDebugDump({...})
      for i,Callback in ipairs(EventCallbacks) do
        Callback(...)
      end
    end
    self:RegisterEvent(EventName, EventCallback)
  end
end

function Communication.BuildMessage(channel)
  return {
    channel = channel,
    payload = {}
  }
end
