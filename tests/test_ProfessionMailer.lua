local lu = require('luaunit')

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