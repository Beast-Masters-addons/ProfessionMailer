---@type ProfessionMailer
local _, addon = ...

addon.data = _G['ProfessionData']
---@type LibProfessionsCommon
local professions = _G.LibStub("LibProfessions-0")

---@type LibInventoryAce
local lib_inventory = _G.LibStub("AceAddon-3.0"):GetAddon('LibInventoryAce')
---@type LibInventoryLocations
local inventory = lib_inventory:GetModule('LibInventoryLocations')
---@type LibInventoryContainer
local container = lib_inventory:GetModule('LibInventoryContainer')
--@type LibInventoryCharacter
--local character_utils = lib_inventory:GetModule('LibInventoryCharacter')

---@type LibInventoryLocations
addon.inventory = inventory
---@type LibInventoryMail
local mail = lib_inventory:GetModule('LibInventoryMail')
---@type BMUtils
local utils = _G.LibStub('BM-utils-1')
---@type BMUtilsTable
local table_utils = _G.LibStub('BM-utils-2'):GetModule("BMUtilsTable")
local PT = addon.PT

---Blizzard Item object (defined in Interface/FrameXML/ObjectAPI/Item.lua)
local Item = _G.Item

local frame = _G.CreateFrame("FRAME"); -- Need a frame to respond to events
frame:RegisterEvent("ADDON_LOADED"); -- Fired when saved variables are loaded

local character_id = utils:GetCharacterString()
local _, realm = utils:GetCharacterInfo()

function addon:init_variables()
    _G['ItemRecipes'] = {}
    _G['RecipeReagents'] = {}
    table_utils.subTableCheck(_G['CharacterDifficulty'], character_id)
    table_utils.subTableCheck(_G['CharacterProfessions'], character_id)
end

--/dump ProfessionMailer:SaveReagents()
function addon:SaveReagents()
    local professionName, rank, maxRank = professions.api:GetInfo()
    local craftItemId
    if professionName == 'UNKNOWN' then
        return
    end
    --@debug@
    utils:cprint("Saving reagents for " .. professionName)
    --@end-debug@

    local recipes = professions.currentProfession:GetRecipes()
    if not recipes or recipes == {} then
        utils:error('No recipes found, close and reopen the profession window')
        return
    end
    for recipeID, recipe in pairs(recipes) do
        if recipe['link'] == nil then
            utils:error(utils:sprintf('No link for recipe %s', recipeID))
            return
        end
        --print('recipeID:', recipeID)
        craftItemId = utils:ItemIdFromLink(recipe['link'])
        recipes[recipeID]['craftItemId'] = craftItemId
        --ItemRecipes
        local reagents = professions.currentProfession:GetReagents(recipeID)
        _G['RecipeReagents'][craftItemId] = reagents

        for _, reagent in pairs(reagents) do
            local reagentItemID = reagent["reagentItemID"]
            local reagentName = reagent["reagentName"]
            if not reagentItemID or not reagentName then
                --No need to retry in BfA, if it does not work on first attempt, it will never work
                if utils:IsWoWClassic() then
                    utils:error("Close and re-open profession to get all information")
                end
            else
                if not _G['ItemRecipes'][reagentItemID] then
                    _G['ItemRecipes'][reagentItemID] = {}
                end
                if not _G['ItemRecipes'][reagentItemID][craftItemId] then
                    _G['ItemRecipes'][reagentItemID][craftItemId] = {name = recipe['name'],
                                                                     itemID = craftItemId}
                end
                _G['CharacterDifficulty'][character_id][craftItemId] = recipe['difficulty']
            end
        end
    end
    _G['CharacterProfessions'][character_id][professionName] = {
        recipes = recipes,
        skill = {current = rank,
                 max = maxRank
        },
    }
    utils:cprint("Successfully saved reagents")
end

-- Event handler
function frame:OnEvent(event, arg1)
    if event == "ADDON_LOADED" and arg1 == "ProfessionMailer" then
        --@debug@
        utils:cprint("ProfessionMailer loaded with debug output", 0, 255, 0)
        --@end-debug@
        addon:init_variables()

        if addon.wow_major < 7 then
            frame:RegisterEvent("TRADE_SKILL_UPDATE")
        else
            frame:RegisterEvent("TRADE_SKILL_LIST_UPDATE")
        end
    elseif event == "TRADE_SKILL_LIST_UPDATE" or event == "TRADE_SKILL_UPDATE" and professions.api:IsReady() then
        addon:SaveReagents()
        --Unregister events after saving
        if utils:IsWoWClassic() then
            frame:UnregisterEvent("TRADE_SKILL_UPDATE")
        else
            frame:UnregisterEvent("TRADE_SKILL_LIST_UPDATE")
        end
    end
end


------ Find items in your bags that another character needs
---@param character string Character with profession
---@param realm_arg string Realm of the character with profession (set nil to use current realm)
---@param difficulty number Minimum difficulty (do not send materials for grey recipes)
---@param keep_limit number Number of items to keep in your inventory
function addon:characterProfessionNeeds(character, realm_arg, difficulty, keep_limit)
    if realm_arg == nil then
        realm_arg = realm
    end

    local character_string = utils:GetCharacterString(character, realm_arg)
    local reagents = {}
    local items = inventory:getLocationItems('bags')
    for itemId, count in pairs(items) do
        local needs = _G['ProfessionData']:whoNeeds(itemId)
        if needs ~= nil then
            for _, need in ipairs(needs) do
                if need['character'] == character_string then
                    local difficulty_num = utils:DifficultyToNum(need['difficulty'])
                    if (difficulty == nil or difficulty_num >= difficulty) and
                            (keep_limit == nil or count >= keep_limit) then
                        --@debug@
                        utils:printf('%s need %d for %s (%d), difficulty %d, has %d', need['character'],
                                need['materialItemId'], need['name'], need['craftedItemId'], difficulty_num, count)
                        --@end-debug@
                        table.insert(reagents, need['materialItemId'], need['materialItemId'])
                    end
                end
            end
        end
    end
    return reagents
end

--/dump ProfessionMailer:characterNeeds("Quadduo-Mirage Raceway")
--- Find items in you inventory that another character needs
function addon:characterNeeds(character)
    local needed_have = {}
    local needs = {}
    local craftedItemId, reagents, item, locations
    for professionName, professionInfo in pairs(_G['CharacterProfessions'][character]) do
        for _, recipe in pairs(professionInfo['recipes']) do
            craftedItemId = recipe['craftItemId']
            reagents = _G['RecipeReagents'][craftedItemId]
            if not reagents then
                reagents = {}
            end

            for _, reagent in ipairs(reagents) do
                locations = inventory:getItemLocation(reagent['reagentItemID'], addon.character, addon.realm)
                item = Item:CreateFromItemID(reagent['reagentItemID'])

                local difficulty = utils:DifficultyToNum(recipe["difficulty"])
                if next(locations) ~= nil and difficulty > 1 then
                    table.insert(needed_have, reagent['reagentItemID'])
                    table.insert(needs, {
                        item = item,
                        locations = locations,
                        profession = professionName,
                        recipe = recipe,
                    })
                end
            end
        end
    end
    return needed_have, needs
end

--- Build a string with needed item links
function addon:need_string_links(character)
    local need_string_lines = {}
    local text
    local _, needs = self:characterNeeds(character)
    if not needs then
        return
    end

    for _, need in ipairs(needs) do
        local color = utils:DifficultyColor(need["recipe"]["difficulty"], true)
        text = string.format(
                '%s need %s for %s', character,
                need["item"]:GetItemLink(),
                need["recipe"]["link"])
        text = color:WrapTextInColorCode(text)

        table.insert(need_string_lines, text)
    end
    return table.concat(need_string_lines, "\n")
end

frame:SetScript("OnEvent", frame.OnEvent);

_G.GameTooltip:HookScript("OnTooltipSetItem", function(self)
    local _, link = self:GetItem()
    if not link then return end
    local id = utils:ItemIdFromLink(link)
    addon:needTooltip(id)
end)

function addon:needTooltip(itemID)
    local needs = self.data:whoNeeds(itemID)
    if not needs then return end
    local color, character
    for _, need in ipairs(needs) do
        color = utils:DifficultyColor(need['difficulty'])
        local need_char, need_realm = utils:SplitCharacterString(need['character'])

        if need_realm == realm then
            character = need_char
        else
            character = need['character']
        end
        if not need["name"] then
            need["name"] = ("Unknown item %d"):format(need["craftedItemId"])
        end

        _G.GameTooltip:AddLine(string.format('%s: %s', character, need["name"]), color['r'], color['g'], color['b'])
    end
end

function addon:need_mail(character)
    local needed_have = self:characterProfessionNeeds(character)
    utils:cprint('Send needed items to ' .. character)

    local stacks
    local key = 1
    for _, itemID in pairs(needed_have) do
        stacks = container:getLocation(itemID)
        for _, position in ipairs(stacks) do
            mail:AddAttachment(position["container"], position["slot"])
            key = key +1
        end
    end
    mail:recipient(character)
end

function addon:MailMats(type)
    local set = "Tradeskill.Mat.ByType."..type:sub(1,1):upper()..type:sub(2)
    local t = PT:GetSetTable(set)
    if t == nil then
        utils:error('Invalid material type: '..type)
        return
    end

    self:MailSet(set)
end

function addon:MailSet(set)
    --@debug@
    utils:cprint('Mailing set ' .. set, 0, 1, 0)
    --@end-debug@

    local itemCount, itemLocations = container:getMultiContainerItems(0, 4)
    for item in PT:IterateSet(set) do
        if itemCount[item] then
            for _, location in ipairs(itemLocations[item]) do
                --@debug@
                utils:printf('Found item %d in container %d slot %d', item, location['container'], location['slot'])
                --@end-debug@
                mail:AddAttachment(location["container"], location["slot"])
            end
        end
    end
end

