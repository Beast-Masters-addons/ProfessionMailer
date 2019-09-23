local professions = LibStub("LibProfessions-1.0")
local profession = professions
--local inventory = LibStub("LibInventory-1.0")
local owned_items

local frame = CreateFrame("FRAME"); -- Need a frame to respond to events
frame:RegisterEvent("ADDON_LOADED"); -- Fired when saved variables are loaded

local character_name = UnitName("player") .. '-' .. GetRealmName()

local function init_variables()
    --CharacterProfessions = {}
    --CharacterProfessions[character_name] = {}
    if CharacterNeeds == nil then
        CharacterNeeds = {}
    end

    if CharacterNeeds[character_name] == nil then
        CharacterNeeds[character_name] = {}
    end
    -- local CurrentCharacterProfessions = CharacterProfessions[character_name]
end

local function SaveReagents()
    local professionName, skillLineRank, skillLineMaxRank, skillLineModifier = profession:GetInfo()
    if CharacterNeeds[character_name][professionName] == nil then
        CharacterNeeds[character_name][professionName] = {}
    end

    local recipes = profession:GetRecipes()
    print('Recipes:', recipes)
    for recipeID, recipe in pairs(recipes) do
        print('recipeID:', recipeID)
        print(recipe['name'])
        local reagents = profession:GetReagents(recipeID)
        for _, reagent in pairs(reagents) do
            local reagentItemID = reagent[1]
            local reagentName = reagent[2]
            print('Index: ', reagentItemID, reagentName)
            -- local reagentItemID, reagentName, reagentTexture, reagentCount, playerReagentCount, reagentLink = reagent
            -- print('Multi: ', reagentItemID)
            if profession:DifficultyToNum(recipe['difficulty']) > 1 then
                CharacterNeeds[character_name][professionName][reagentItemID] = reagent
            end
        end
    end
end

function frame:OnEvent(event, arg1)

    if event == "ADDON_LOADED" and arg1 == "ProfessionMailer" then
        frame:RegisterEvent("TRADE_SKILL_SHOW");
        frame:RegisterEvent("TRADE_SKILL_DATA_SOURCE_CHANGED");
        frame:RegisterEvent("TRADE_SKILL_LIST_UPDATE");
        frame:RegisterEvent("TRADE_SKILL_DETAILS_UPDATE");
        init_variables()
        owned_items = GetBags()
    else
        print('Skill show')
        if profession:IsReady() then
            SaveReagents()
        end
    end
end

local function needed(character)
    local char
    local lines = {""}
    if character == nil or character == "" then
        char = character_name
    else
        char = character .. '-' .. GetRealmName()
    end
    for professionName, need in pairs(CharacterNeeds[char]) do
        table.insert(lines, char .. ' needs this for ' .. professionName .. ':')
        for reagentItemID, reagent in pairs(need) do
            if owned_items[reagentItemID] ~= nil then
                table.insert(lines,reagent[6] .. ' you have ' .. owned_items[reagentItemID]['itemCount'])
            else
                table.insert(lines, reagent[6])
            end
        end
    end
    return lines
end

SLASH_NEEDED1 = "/needed"

SlashCmdList["NEEDED"] = function(msg)
    local lines = needed(msg)
    NeedFrame:Show()
    NeedText:SetText(table.concat(lines, "\n"))
    print(table.concat(lines, "\n"))
end

frame:SetScript("OnEvent", frame.OnEvent);

SLASH_SAVE1 = "/looptest"

SlashCmdList["SAVE"] = function(msg)
    local recipes = profession:GetRecipes()
    for id, value in pairs(recipes) do
        print(id, value)
        print(value['name'])
    end
end