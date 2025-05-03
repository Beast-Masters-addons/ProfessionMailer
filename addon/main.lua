---@type ProfessionMailer
local _, addon = ...
local utils = addon.utils

_G.SLASH_NEEDED1 = "/needed"
_G.SLASH_NEEDED2 = "/need"

_G.SlashCmdList["NEEDED"] = function(msg)
    local character = utils:GetCharacterString(msg)
    local links = addon:need_string_links(character)
    if not links then
        utils:cprint(string.format("%s does not need anything", character), 255, 255 ,0)
        return
    end
    utils:cprint(links)
end

_G.SLASH_NEEDMAIL1 = "/needmail"
_G.SlashCmdList["NEEDMAIL"] = function(msg)
    if msg == '' then
        addon.utils:error('Usage: /needmail [character name]')
        return
    end
    local character = utils:GetCharacterString(msg)
    addon:need_mail(character)
end

_G.SLASH_NEEDCLEAR1 = "/needclear"
_G.SlashCmdList["NEEDCLEAR"] = function()
    _G['ItemRecipes'] = {}
    _G['CharacterDifficulty'] = {}
    _G['CharacterProfessions'] = {}
    _G['RecipeReagents'] = {}
    addon:init_variables()
    addon:cprint("Cleared all saved needs", 0, 255, 0)
end

_G.SLASH_MATS1 = "/sendmats"
_G.SLASH_MATS2 = "/mats"
_G.SlashCmdList["MATS"] = function(msg)
    addon:MailMats(msg)
end

--/sendset Tradeskill.Gather.GemsInNodes.Tin Vein
_G.SLASH_SEND_SET1 = "/sendset"
_G.SlashCmdList['SEND_SET'] = function(msg)
    if msg == '' then
        addon.utils:error('Usage: /sendset [set name]')
        return
    end
    addon:MailSet(msg)
end