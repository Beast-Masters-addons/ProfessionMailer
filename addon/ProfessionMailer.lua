local addon = {}
_G['ProfessionMailer'] = addon
addon.data = _G['ProfessionData']

local profession = _G['CurrentProfession']
local profession_api = _G['ProfessionAPI']
local inventory = _G['LibInventory']
local mail = _G['LibInventoryMail']
local utils = _G['BMUtils']

if LibStub then
    profession = LibStub("LibCurrentProfession-1.1")
    profession_api = LibStub("LibProfessionAPI-1.0")
    inventory = LibStub("LibInventory-0")
    mail = inventory.mail
    utils = LibStub("BM-utils-1")
end

local frame = CreateFrame("FRAME"); -- Need a frame to respond to events
frame:RegisterEvent("ADDON_LOADED"); -- Fired when saved variables are loaded

local character_id = utils:GetCharacterString()
local _, realm = utils:GetCharacterInfo()

function addon:init_variables()
    self.data:init_table('ItemRecipes')
    self.data:init_table('RecipeReagents')
    self.data:init_table('CharacterDifficulty', character_id)
    self.data:init_table('CharacterProfessions', character_id)
end

--/dump ProfessionMailer:SaveReagents()
function addon:SaveReagents()
    local professionName, rank, maxRank = profession_api:GetInfo()
    local craftItemId
    if professionName == 'UNKNOWN' then
        return
    end
    --@debug@
    utils:cprint("Saving reagents for " .. professionName)
    --@end-debug@

    local recipes = profession:GetRecipes()
    if not recipes or recipes == {} then
        utils:error('No recipes found, close and reopen the profession window')
        return
    end
    for recipeID, recipe in pairs(recipes) do
        if recipe['link'] == nil then
            utils:printf('No link for %s', recipeID)
            return
        end
        --print('recipeID:', recipeID)
        craftItemId = utils:ItemIdFromLink(recipe['link'])
        recipes[recipeID]['craftItemId'] = craftItemId
        --ItemRecipes
        local reagents = profession:GetReagents(recipeID)
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
                    _G['CharacterDifficulty'][character_id][craftItemId] = recipe['difficulty']
                end
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
        frame:RegisterEvent("TRADE_SKILL_SHOW")
        addon:init_variables()
    elseif event == "TRADE_SKILL_SHOW" then
        if utils:IsWoWClassic() then
            frame:RegisterEvent("TRADE_SKILL_UPDATE")
        else
            frame:RegisterEvent("TRADE_SKILL_LIST_UPDATE")
        end
    elseif event == "TRADE_SKILL_LIST_UPDATE" or event == "TRADE_SKILL_UPDATE" and profession_api:IsReady() then
        addon:SaveReagents()
        --Unregister events after saving
        if utils:IsWoWClassic() then
            frame:UnregisterEvent("TRADE_SKILL_UPDATE")
        else
            frame:UnregisterEvent("TRADE_SKILL_LIST_UPDATE")
        end
    end
end

--/dump ProfessionMailer:characterNeeds("Quadduo-Mirage Raceway")
--- Find items in you inventory that another character needs
function addon:characterNeeds(character)
    local needed_have = {}
    local needs = {}
    local craftedItemId, reagents, item
    for professionName, professionInfo in pairs(_G['CharacterProfessions'][character]) do
        for _, recipe in pairs(professionInfo['recipes']) do
            craftedItemId = recipe['craftItemId']
            reagents = _G['RecipeReagents'][craftedItemId]
            for _, reagent in ipairs(reagents) do
                item = inventory:FindItem(reagent['reagentItemID'])
                local difficulty = utils:DifficultyToNum(recipe["difficulty"])
                utils:printf('%s need %s for %s', character, reagent['reagentItemID'], recipe['craftItemId'])
                if item ~= nil and difficulty>1 then
                    table.insert(needed_have, reagent['reagentItemID'])
                    table.insert(needs, {
                        item = item,
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
                need["item"]["itemLink"],
                need["recipe"]["link"])
        text = color:WrapTextInColorCode(text)

        table.insert(need_string_lines, text)
    end
    return table.concat(need_string_lines, "\n")
end

function addon:close_need_frame()
    NeedFrame:Hide()
end

function addon:show_need_frame(character)
    local close = CreateFrame("Button", "NeedCloseButton", NeedFrame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -1, -1)
    close:SetScript("OnClick", addon.close_need_frame)
    NeedFrame:Show()
    NeedText:SetText(addon:need_string_links(character))
    HeaderText:SetText(string.format("Items needed by %s", character))
end

SLASH_NEEDED1 = "/needed"
SLASH_NEEDED2 = "/need"

SlashCmdList["NEEDED"] = function(msg)
    local character = utils:GetCharacterString(msg)
    local links = addon:need_string_links(character)
    if not links then
        utils:cprint(string.format("%s does not need anything", character), 255, 255 ,0)
        return
    end
    utils:cprint(links)
    addon:show_need_frame(character)
end

frame:SetScript("OnEvent", frame.OnEvent);

GameTooltip:HookScript("OnTooltipSetItem", function(self)
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

        GameTooltip:AddLine(string.format('%s: %s', character , need["name"]), color['r'], color['g'], color['b'])
    end
end

function addon:need_mail(character)
    local needed_have = self:characterNeeds(character)
    utils:cprint('Send needed items to ' .. character)

    if not needed_have then
        return
    end

    local stacks
    local key = 1
    for _, itemID in pairs(needed_have) do
        stacks = inventory:FindItemStacks(itemID)
        for _, position in ipairs(stacks) do
            --@debug@
            utils:cprint(string.format('Adding item %d from bag %d slot %d as attachment %d',
                                        itemID, position["bag"], position["slot"], key))
            --@end-debug@
            mail:AddAttachment(position["bag"], position["slot"], key)
            key = key +1
        end
    end
    mail:recipient(character)
end

SLASH_NEEDMAIL1 = "/needmail"
SlashCmdList["NEEDMAIL"] = function(msg)
    local character = utils:GetCharacterString(msg)
    addon:need_mail(character)
end

SLASH_NEEDCLEAR1 = "/needclear"
SlashCmdList["NEEDCLEAR"] = function()
    _G['ItemRecipes'] = {}
    _G['CharacterDifficulty'] = {}
    _G['CharacterProfessions'] = {}
    _G['RecipeReagents'] = {}
    addon:init_variables()
    addon:cprint("Cleared all saved needs", 0, 255, 0)
end


local PT = LibStub("LibPeriodicTable-3.1")

SLASH_MATS1 = "/sendmats"
SLASH_MATS2 = "/mats"
SlashCmdList["MATS"] = function(msg)
    addon:MailMats(msg)
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
    local location
    print("Mail set", set)
    for item in PT:IterateSet(set) do
        location = inventory:FindItem(item)
        if location then
            --print(string.format('item: %s bag: %s slot: %s', item, location["bag"], location["slot"]))
            --if mail.mail_open then
            PickupContainerItem(location["bag"], location["slot"])
            ClickSendMailItemButton()
            --end
        end
    end
end

SLASH_SCANBAGS1 = "/scanbags"
SlashCmdList["SCANBAGS"] = function()
    inventory:ScanAllBags()
end
