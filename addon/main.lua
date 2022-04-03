local common = _G['ProfessionMailerCommon-@project-version@']
local addon = _G['ProfessionMailer-@project-version@']
local utils = common.utils


_G.SLASH_NEEDMAIL1 = "/needmail"
_G.SlashCmdList["NEEDMAIL"] = function(msg)
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