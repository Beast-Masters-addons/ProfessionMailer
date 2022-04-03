local lu = require('luaunit')

loadfile('wow_functions.lua')()
loadfile('build_utils/wow_api/constants.lua')()
loadfile('build_utils/wow_api/functions.lua')()
loadfile('build_utils/wow_api/frame.lua')()
if _G.WOW_PROJECT_ID == _G.WOW_PROJECT_MAINLINE then
    loadfile('build_utils/wow_api/profession_api.lua_retail')()
else
    loadfile('build_utils/wow_api/profession_api_classic.lua')()
end

loadfile('build_utils/utils/load_toc.lua')('resolved.toc')

_G['test'] = {}
local test = _G['test']
local ProfessionMailer = _G['ProfessionMailer']

function _G.DEFAULT_CHAT_FRAME:AddMessage(str, r, g, b)
    if r == 1 and g == 0 and b == 0 then
        error(str)
    else
        print(str)
    end
end

function test:testInitVariables()
    lu.assertNil(_G['ItemRecipes'])
    ProfessionMailer:init_variables()
    lu.assertNotNil(_G['ItemRecipes'])
end

function test:testSaveReagents()
    lu.assertNil(_G['RecipeReagents'][929])
    lu.assertNil(_G['ItemRecipes'][2453])
    ProfessionMailer:SaveReagents()
    lu.assertNotNil(_G['RecipeReagents'][929])
    lu.assertNotNil(_G['ItemRecipes'][2453])
end

os.exit(lu.LuaUnit.run())