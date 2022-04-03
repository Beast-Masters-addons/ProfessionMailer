---@class ProfessionMailer
local addonName, addon = ...
addon.name = addonName
addon.version = '@project-version@'

---@type BMUtils
addon.utils = _G.LibStub('BM-utils-1')

local minor
---@type LibProfessionsCommon
addon.professions, minor = _G.LibStub("LibProfessions-0")
assert(minor >= 10, addon.utils:sprintf('LibProfessions 0.10 or higher required, loaded %d', minor))

---Deprecated, use addon.professions.currentProfession
addon.professions.current = addon.professions.currentProfession

assert(addon.professions.api, 'Error loading LibProfessionsAPI')

addon.is_classic = addon.utils:IsWoWClassic()

addon.PT = _G.LibStub("LibPeriodicTable-3.1")

_G['ProfessionMailer'] = addon