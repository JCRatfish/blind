local AddonName, AddonTable = ...
if not AddonTable.Ace3.Addon then return end

local Ace3 = AddonTable.Ace3
local Ace3GUIElements = Ace3.GUI.ELMS
local Rosters = Ace3.Addon:NewModule("Rosters", "AceEvent-3.0")
Ace3.Modules.Rosters = Rosters

function Rosters:SetupGroupRoster()
  self.GroupRoster = {
    Members = {},
    MemberCounts = {},
    MemberNamesSorted = {}
  }
  local PartyMemberEventsCallback = function(unitId)
    if string.match(unitId, "raid%d+") or string.match(unitId, "party%d+") then
      -- trigger update only when unitTarget is a group member
      self.GROUP_ROSTER_UPDATE("GROUP_ROSTER_UPDATE", true)
    end
  end
  self:RegisterEvent("PARTY_MEMBER_DISABLE", function(event, unitTarget)
    -- Ace3.Modules.Helpers.PrintDebugDump({[event] = unitTarget})
    PartyMemberEventsCallback(unitTarget)
  end)
  self:RegisterEvent("PARTY_MEMBER_ENABLE", function(event, unitTarget)
    -- Ace3.Modules.Helpers.PrintDebugDump({[event] = unitTarget})
    PartyMemberEventsCallback(unitTarget)
  end)
  self:RegisterEvent("GROUP_ROSTER_UPDATE", self.GROUP_ROSTER_UPDATE) -- this event fires numerous times
end

function Rosters:ShutdownGroupRoster()
  self.GroupRoster = {
    Members = {},
    MemberCounts = {},
    MemberNamesSorted = {}
  }
  self:UnregisterEvent("PARTY_MEMBER_DISABLE")
  self:UnregisterEvent("PARTY_MEMBER_ENABLE")
  self:UnregisterEvent("GROUP_ROSTER_UPDATE")
end

function Rosters.GROUP_ROSTER_UPDATE(event, isPartyMemberEvent)
  -- Ace3.Modules.Helpers.PrintDebug("GROUP_ROSTER_UPDATE")
  local EventTable = {
    GroupRoster = {
      Members = {},
      MemberCounts = {},
      MemberNamesSorted = {}
    }
  }
  local unitPrefix = "party"
  if IsInRaid() then
    unitPrefix = "raid"
  end
  C_Timer.After(1, function() -- wait 1 second otherwise UnitIsConnected() is incorrect
    -- MemberCounts include the player
    EventTable.GroupRoster.MemberCounts.Total, EventTable.GroupRoster.MemberCounts.Online = GetNumGroupMembers(), 0
    if not IsInRaid() then
      -- player is included in raidN but not partyN
      EventTable.GroupRoster.MemberCounts.Total = EventTable.GroupRoster.MemberCounts.Total-1
    end
    if isPartyMemberEvent or (Rosters.GroupRoster.MemberCounts.Total ~= EventTable.GroupRoster.MemberCounts.Total) then
      -- skip event unless isPartyMemberEvent, GroupRoster is empty, or MemberCounts.Total has changed
      for i=1, EventTable.GroupRoster.MemberCounts.Total, 1 do
        local _, class, _, _, _, name = GetPlayerInfoByGUID(UnitGUID(unitPrefix .. i))
        if name ~= AddonTable.Player.Name then
          if UnitIsConnected(name) then
            table.insert(EventTable.GroupRoster.MemberNamesSorted, name)
            EventTable.GroupRoster.Members[name] = { RaidClassName = class }
            if AddonTable.Ace3.Modules.Communication.Channels.Rosters.Payloads[name] then
              EventTable.GroupRoster.Members[name].Addons = AddonTable.Ace3.Modules.Communication.Channels.Rosters.Payloads[name]
            end
            EventTable.GroupRoster.MemberCounts.Online = EventTable.GroupRoster.MemberCounts.Online+1
          else
            EventTable.GroupRoster.Members[name] = nil
          end
        end
      end
      table.sort(EventTable.GroupRoster.MemberNamesSorted)
      Rosters.GroupRoster = EventTable.GroupRoster
      -- Ace3.Modules.Helpers.PrintDebugDump({[event] = EventTable.GroupRoster})
    end
    -- GUI updates for every event due to leadership changes
    if Ace3GUIElements.BlizOptionsGroup.SimpleGroup.TabGroup.Tabs.Accountability.TabGroup.ELM.localstatus.selected == "Group" then
      Ace3GUIElements.BlizOptionsGroup.SimpleGroup.TabGroup.Tabs.Accountability.TabGroup.Tabs.Group.ScrollFrame.SimpleGroup.functions.Render("Group")
      Ace3GUIElements.BlizOptionsGroup.SimpleGroup.TabGroup.Tabs.Accountability.TabGroup.Tabs.Group.ScrollFrame.ELM:DoLayout()
    end
  end)
end

function Rosters:SetupGuildRoster()
  self.GuildRoster = {
    AccountabilityTab = Ace3GUIElements.BlizOptionsGroup.SimpleGroup.TabGroup.Tabs.Accountability.TabGroup.Tabs.Guild,
    Events = {
      Previous = {},
      Current = {},
      Next = { Timer = C_Timer.NewTimer(0, function() end) },
    },
    Members = {},
    MemberCounts = {},
    MemberNamesSorted = {}
  }
  self:RegisterEvent("GUILD_ROSTER_UPDATE", self.GUILD_ROSTER_UPDATE) -- this event seems to fire in pairs
end

function Rosters:ShutdownGuildRoster()
  self.GuildRoster = nil
  self:UnregisterEvent("GUILD_ROSTER_UPDATE")
end

function Rosters.GUILD_ROSTER_UPDATE()
  -- Ace3.Modules.Helpers.PrintDebug("GUILD_ROSTER_UPDATE")
  local EventTable = {
    CurrentTimeInSeconds = math.floor(GetTime()),
    UpdateText = "Guild Roster update in: ",
    GuildRoster = {
      Members = {},
      MemberCounts = {},
      MemberNamesSorted = {}
    }
  }
  -- MemberCounts include the player so we need to take this into account elsewhere
  EventTable.GuildRoster.MemberCounts.Total, EventTable.GuildRoster.MemberCounts.Online = GetNumGuildMembers()
  if EventTable.GuildRoster.MemberCounts.Total == 0 and EventTable.GuildRoster.MemberCounts.Online == 0 then
    Rosters.GuildRoster.Events.Current.IsSkipped = true
    return
  end

  -- reset parameters
  Rosters.GuildRoster.Events.Previous = Ace3.Modules.Helpers.DeepCopyTable(Rosters.GuildRoster.Events.Current)
  Rosters.GuildRoster.Events.Current.IsSkipped = false
  Rosters.GuildRoster.Events.Current.IsUpdated = false
  Rosters.GuildRoster.Events.Current.Time = EventTable.CurrentTimeInSeconds
  if Rosters.GuildRoster.Events.Previous.Time then
    Rosters.GuildRoster.Events.Current.TimeDelta = EventTable.CurrentTimeInSeconds - Rosters.GuildRoster.Events.Previous.Time
  else
    Rosters.GuildRoster.Events.Current.TimeDelta = 0 -- only used for the first GUILD_ROSTER_UPDATE event
  end

  if Rosters.GuildRoster.MemberCounts and (Rosters.GuildRoster.MemberCounts.Online == EventTable.GuildRoster.MemberCounts.Online) then
    -- the number of online guild members has not changed even though the event fired... isn't that annoying?
    if Rosters.GuildRoster.Events.Current.TimeDelta > 10 then
      -- the previous event occured over 10 seconds ago; request the guild roster and stop execution
      GuildRoster()
      -- Ace3.Modules.Helpers.PrintDebugDump({GUILD_ROSTER_UPDATE = { Events = Rosters.GuildRoster.Events, MemberCounts = Rosters.GuildRoster.MemberCounts }})
      return
    elseif Rosters.GuildRoster.Events.Current.TimeDelta > 0 and Rosters.GuildRoster.Events.Next.Timer._remainingIterations == 0 then
      -- the previous event occured less than or equal to 10 and more than 0 seconds ago; queue a request for the guild roster and stop execution
      local secondsBeforeNextPossibleGuildRosterEvent = 11 - Rosters.GuildRoster.Events.Current.TimeDelta
      local currentTime = Rosters.GuildRoster.Events.Current.Time -- local copy, otherwise countdown gets messed up
      if IsInGuild() and Ace3GUIElements.BlizOptionsGroup.SimpleGroup.TabGroup.Tabs.Accountability.TabGroup.ELM.localstatus.selected == "Guild" then
        Rosters.GuildRoster.AccountabilityTab.ScrollFrame.SimpleGroup.SyncLabel.ELM:SetText(EventTable.UpdateText .. secondsBeforeNextPossibleGuildRosterEvent) -- GUI update
      end
      -- start ticker for SyncLabel
      C_Timer.NewTicker(1, function()
        local remainingTime = secondsBeforeNextPossibleGuildRosterEvent - (math.floor(GetTime()) - currentTime)
        if remainingTime > 0 and IsInGuild() and Ace3GUIElements.BlizOptionsGroup.SimpleGroup.TabGroup.Tabs.Accountability.TabGroup.ELM.localstatus.selected == "Guild" then
          Rosters.GuildRoster.AccountabilityTab.ScrollFrame.SimpleGroup.SyncLabel.ELM:SetText(EventTable.UpdateText .. remainingTime) -- GUI update
        end
      end, secondsBeforeNextPossibleGuildRosterEvent)
      -- start timer
      Rosters.GuildRoster.Events.Next.Timer = C_Timer.NewTimer(secondsBeforeNextPossibleGuildRosterEvent, function()
        EventTable.CurrentTimeInSeconds = math.floor(GetTime())
        Rosters.GuildRoster.Events.Current.TimeDelta = EventTable.CurrentTimeInSeconds - Rosters.GuildRoster.Events.Current.Time
        Rosters.GuildRoster.Events.Current.Time = EventTable.CurrentTimeInSeconds
        GuildRoster()
        if IsInGuild() and Ace3GUIElements.BlizOptionsGroup.SimpleGroup.TabGroup.Tabs.Accountability.TabGroup.ELM.localstatus.selected == "Guild" then
          Rosters.GuildRoster.AccountabilityTab.ScrollFrame.SimpleGroup.SyncLabel.ELM:SetText("Guild Roster is up to date!") -- GUI update
        end
      end)
      -- Ace3.Modules.Helpers.PrintDebugDump({GUILD_ROSTER_UPDATE = { Events = Rosters.GuildRoster.Events, MemberCounts = Rosters.GuildRoster.MemberCounts }})
      return
    else
      -- skip this event; if timer is not running request the guild roster and stop execution
      Rosters.GuildRoster.Events.Current.IsSkipped = true
      if Rosters.GuildRoster.Events.Next.Timer._remainingIterations == 0 then
        GuildRoster()
      end
      -- Ace3.Modules.Helpers.PrintDebugDump({GUILD_ROSTER_UPDATE = { Events = Rosters.GuildRoster.Events, MemberCounts = Rosters.GuildRoster.MemberCounts }})
      return
    end
  else
    -- the number of online guild members has changed; collect member data
    for i=1, EventTable.GuildRoster.MemberCounts.Total, 1 do
      local name, rankName, rankIndex, level, classDisplayName, zone, publicNote, officerNote, isOnline, status,
        class, achievementPoints, achievementRank, isMobile, canSoR, repStanding, GUID = GetGuildRosterInfo(i)
      if isOnline and name then
        local playerName = Ace3.Modules.Helpers.ExplodeString("-", name)[1] -- remove realm from name
        if playerName ~= AddonTable.Player.Name then
          table.insert(EventTable.GuildRoster.MemberNamesSorted, playerName)
          EventTable.GuildRoster.Members[playerName] = { RaidClassName = class }
          if AddonTable.Ace3.Modules.Communication.Channels.Rosters.Payloads[playerName] then
            EventTable.GuildRoster.Members[playerName].Addons = AddonTable.Ace3.Modules.Communication.Channels.Rosters.Payloads[playerName]
          end
        end
      end
    end
    -- store member data
    table.sort(EventTable.GuildRoster.MemberNamesSorted)
    Rosters.GuildRoster.MemberNamesSorted = EventTable.GuildRoster.MemberNamesSorted
    Rosters.GuildRoster.MemberCounts = EventTable.GuildRoster.MemberCounts
    Rosters.GuildRoster.Members = EventTable.GuildRoster.Members
    Rosters.GuildRoster.Events.Current.IsUpdated = true
    -- Ace3.Modules.Helpers.PrintDebugDump({GUILD_ROSTER_UPDATE = { Events = Rosters.GuildRoster.Events, MemberCounts = Rosters.GuildRoster.MemberCounts }})
    -- GUI updates
    if IsInGuild() and Ace3GUIElements.BlizOptionsGroup.SimpleGroup.TabGroup.Tabs.Accountability.TabGroup.ELM.localstatus.selected == "Guild" then
      Rosters.GuildRoster.AccountabilityTab.ScrollFrame.SimpleGroup.SyncLabel.ELM:SetText("Guild Roster is up to date!")
      Rosters.GuildRoster.AccountabilityTab.ScrollFrame.SimpleGroup.functions.Render("Guild")
      Rosters.GuildRoster.AccountabilityTab.ScrollFrame.ELM:DoLayout()
    end
  end
end
