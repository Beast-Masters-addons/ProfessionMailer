local lu = require('luaunit')

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

loadfile('wow_functions.lua')()
loadfile('frame.lua')()

loadfile('load_toc.lua')('../ProfessionMailer.toc')
loadfile('profession_api.lua')()

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