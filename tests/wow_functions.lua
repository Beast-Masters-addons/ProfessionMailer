---This file contains dummy functions and variables to make WoW functions work in standalone lua

_G.debugstack = debug.traceback
_G.strmatch = string.match
addon = {}
C_Timer = {}

function C_Timer:NewTicker(...)
end

DEFAULT_CHAT_FRAME = {}
function DEFAULT_CHAT_FRAME:AddMessage(str, r, g, b)
    return str, r, g, b
end

function _G.UnitName(unit)
    if unit == "player" then
        return "Quadduo"
    end
end

function _G.UnitGUID()

end

function GetRealmName()
    return "Mirage Raceway"
end

function _G.GetNumAddOns()
    return 0
end

_G['gsub'] = string.gsub

SlashCmdList = {}

_G.GameTooltip = {}

function _G.GameTooltip:HookScript (...)

end

