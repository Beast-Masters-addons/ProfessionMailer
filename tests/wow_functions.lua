---This file contains dummy functions and variables to make WoW functions work in standalone lua
if os.getenv('CLASSIC_VERSION') ~= nil then
    print('Running tests for WoW Classic')
    function _G.GetBuildInfo()
        return "1.13.2", 32600, "Nov 20 2019", 11302
    end
else
    print('Running tests for WoW Retail')
    function _G.GetBuildInfo()
        return "9.0.2", 37474, "Feb 3 2021", 90002
    end
end

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
    return "MirageRaceway"
end

function _G.GetNumAddOns()
    return 0
end

_G['gsub'] = string.gsub

SlashCmdList = {}

