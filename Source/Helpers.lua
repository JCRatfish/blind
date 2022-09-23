local AddonName, AddonTable = ...
if not AddonTable.Ace3.Addon then return end

local Ace3 = AddonTable.Ace3
local Helpers = Ace3.Addon:NewModule("Helpers")
Ace3.Modules.Helpers = Helpers

--- Explodes a string similar to PHP
-- @param d  Delimiter
-- @param p  The string to split
-- @return t  A table of substrings
function Helpers.ExplodeString(d,p)
  local t, ll
  t={}
  ll=0
  if(#p == 1) then
    return {p}
  end
  while true do
    l = string.find(p, d, ll, true) -- find the next d in the string
    if l ~= nil then -- if "not not" found then..
      table.insert(t, string.sub(p,ll,l-1)) -- Save it in our array.
      ll = l + 1 -- save just after where we found it for searching next time.
    else
      table.insert(t, string.sub(p,ll)) -- Save what's left in our array.
      break -- Break at end, as it should be, according to the lua manual.
    end
  end
  return t
end

--- Copies all table levels
-- @param original  Original table
-- @return copy  Copy of original table
function Helpers.DeepCopyTable(original)
	local copy = {}
	for k, v in pairs(original) do
		if type(v) == "table" then
			v = Helpers.DeepCopyTable(v)
		end
		copy[k] = v
	end
	return copy
end

--- Gets the color code for a given class used in the WrapTextInColorCode function
-- @param class  Class of the player
-- @return colorHexString
function Helpers.GetRaidClassColorCode(class)
  return "FF".. RAID_CLASS_COLORS[class].colorStr:sub(3):upper()
end

--- Dumps a table into a string
-- @param input  String or table
-- @return string
function Helpers.Dump(input)
  if type(input) == 'table' then
    local s = '{ '
    for k,v in pairs(input) do
      if type(k) ~= 'number' then k = '"'..k..'"' end
      s = s .. '['..k..'] = ' .. Helpers.Dump(v) .. ','
    end
    return s .. '} '
  else
    return tostring(input)
  end
end

--- Debug printer
-- @param input  String to be printed
function Helpers.PrintDebug(input)
  if AddonTable.Debug then
    Ace3.Addon:Print(input)
  end
end

--- Debug dump printer
-- @param input  String or table to be printed
function Helpers.PrintDebugDump(input)
  Helpers.PrintDebug(Helpers.Dump(input))
end
