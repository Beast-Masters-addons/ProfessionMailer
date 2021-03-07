_G['ProfessionMailerCommon-@project-version@'] = {}
local common = _G['ProfessionMailerCommon-@project-version@']

common.version = '@project-version@'

common.utils = _G['BMUtils']
common.utils = _G.LibStub("BM-utils-1")

common.professions = _G['LibProfessions']
local minor
common.professions, minor = _G.LibStub("LibProfessions-0", 9)
assert(minor >= 9, common.utils:sprintf('LibProfessions 0.9 or higher required, loaded %d', minor))
common.professions.current = common.professions.currentProfession

assert(common.professions.api, 'Error loading LibProfessionsAPI')

common.inventory = _G['LibInventory']
common.inventory = _G.LibStub("LibInventory-0")

common.is_classic = common.utils:IsWoWClassic()

common.PT = _G.LibStub("LibPeriodicTable-3.1")