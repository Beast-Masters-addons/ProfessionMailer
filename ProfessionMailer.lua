local addonName, addon = ...
local professions = LibStub("LibProfessions-1.0")
local profession = professions
local inventory = LibStub("LibInventory-0.1")
local mail = LibStub("LibMail-0.1")

local utils = addon

local frame = CreateFrame("FRAME"); -- Need a frame to respond to events
frame:RegisterEvent("ADDON_LOADED"); -- Fired when saved variables are loaded

local character_name = utils:get_char_string()

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

function addon:SaveReagents()
    local professionName = profession:GetInfo()
    if professionName == 'UNKNOWN' then
        return
    end
    self:cprint("Saving reagents for " .. professionName)

    if CharacterNeeds[character_name][professionName] == nil then
        CharacterNeeds[character_name][professionName] = {}
    end

    local recipes = profession:GetRecipes()
    if not recipes or #recipes == 0 then
        self:error('No recipes found, close and reopen the profession window')
        return
    end
    for recipeID, recipe in pairs(recipes) do
        --print('recipeID:', recipeID)
        local reagents = profession:GetReagents(recipeID)
        for _, reagent in pairs(reagents) do
            local reagentItemID = reagent["reagentItemID"]
            local reagentName = reagent["reagentName"]
            if not reagentItemID or not reagentName then
                self:error("Close and re-open profession to get all information")
                return
            end

            if profession:DifficultyToNum(recipe['difficulty']) > 1 then
                CharacterNeeds[character_name][professionName][reagentItemID] = {["recipe"]=recipe, ["reagent"]=reagent}
            end
        end
    end
end

-- Event handler
function frame:OnEvent(event, arg1)
    if event == "ADDON_LOADED" and arg1 == "ProfessionMailer" then
        frame:RegisterEvent("TRADE_SKILL_UPDATE")
        init_variables()
    elseif event == "TRADE_SKILL_UPDATE" and profession:IsReady() then
        addon:SaveReagents()
    end
end

function addon:needed(character)
    local needed_have = {}
    local needs = {}

    for professionName, need in pairs(CharacterNeeds[character]) do
        for reagentItemID, craft in pairs(need) do
            item = inventory:FindItem(reagentItemID)
            if item ~= nil then
                table.insert(needed_have, reagentItemID)
                table.insert(needs, {["item"]=owned_items[reagentItemID], ["profession"]=professionName, ["recipe"]=craft["recipe"]})
                --print('Needed have', owned_items[reagentItemID]["itemID"], owned_items[reagentItemID]["bag"], owned_items[reagentItemID]["slot"])
            end
        end
    end
    return needed_have, needs
end

-- Build a string with needed item links
function addon:need_string_links(character)
    local need_string_lines = {}
    local _, needs = self:needed(character)
    if not needs then
        return
    end

    for _, need in ipairs(needs) do
        table.insert(need_string_lines, string.format('%s need %s for %s', character, need["item"]["itemLink"], need["recipe"]["link"]))
    end
    return table.concat(need_string_lines, "\n")
end

function addon:need_string_all(character)
    local lines = {}

    for professionName, items in pairs(CharacterNeeds[character]) do
        table.insert(lines, professionName .. ':')
        for itemID, craft in pairs(items) do
            item = inventory:FindItem(itemID)
            if item ~= nil then
                table.insert(lines,craft["reagent"]["reagentName"] .. ' you have ' .. item['itemCount'])
            else
                table.insert(lines, craft["reagent"]["reagentName"])
            end
        end
        table.insert(lines, "")
    end
    return table.concat(lines, "\r\n")
end

function addon:close_need_frame()
    NeedFrame:Hide()
end

function addon:show_need_frame(character)
    local close = CreateFrame("Button", "NeedCloseButton", NeedFrame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -1, -1)
    close:SetScript("OnClick", addon.close_need_frame)
    NeedFrame:Show()
    NeedText:SetText(addon:need_string_all(character))
    HeaderText:SetText(string.format("Items needed by %s", character))
end

SLASH_NEEDED1 = "/needed"
SLASH_NEEDED2 = "/need"

SlashCmdList["NEEDED"] = function(msg)
    local character = utils:get_char_string(msg)
    if CharacterNeeds[character] == nil or next(CharacterNeeds[character]) == nil then
        utils:cprint(string.format("%s does not need anything", character), 255, 255 ,0)
        return
    end
    addon:cprint(addon:need_string_links(character))
    addon:show_need_frame(character)
end

frame:SetScript("OnEvent", frame.OnEvent);

function addon:need_mail(character)
    local needed_have = self:needed(character)
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
            utils:cprint(string.format('Adding item %d from bag %d slot %d as attachment %d', itemID, position["bag"], position["slot"], key))
            --@end-debug@
            --TODO: Use mail:AddAttachment
            PickupContainerItem(position["bag"], position["slot"])
            ClickSendMailItemButton(key)
            key = key +1
        end
    end
    mail:recipient(character)
end

SLASH_NEEDMAIL1 = "/needmail"
SlashCmdList["NEEDMAIL"] = function(msg)
    local character = utils:get_char_string(msg)
    addon:need_mail(character)
end

SLASH_NEEDCLEAR1 = "/needclear"
SlashCmdList["NEEDCLEAR"] = function()
    CharacterNeeds = {}
    init_variables()
    addon:cprint("Cleared all saved needs", 0, 255, 0)
end