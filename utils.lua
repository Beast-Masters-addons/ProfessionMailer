local _, addon = ...

-- Add a message to chat frame with colors
function addon:cprint(message, r, g, b)
    local DEFAULT_FONT_COLOR = {["R"]=255, ["G"]=255, ["G"]=255}
    DEFAULT_CHAT_FRAME:AddMessage(message,
            (r or DEFAULT_FONT_COLOR["R"]),
            (g or DEFAULT_FONT_COLOR["G"]),
            (b or DEFAULT_FONT_COLOR["B"]));
end

-- Add a message to chat frame with red color
function addon:error(message)
    self:cprint(message, 255, 0,0)
end

-- Get character name and realm, fall back to current player if character not specified
function addon:get_char(character, realm)
    if not character or character == "" then
        character = UnitName("player")
    end
    if not realm then
        realm = GetRealmName()
    end
    return character, realm
end

-- Get character name and realm as a string
function addon:get_char_string(character, realm)
    character, realm = self:get_char(character, realm)
    return string.format('%s-%s', character, realm)
end

function addon:IsWoWClassic()
    return select(4, GetBuildInfo()) < 20000
end