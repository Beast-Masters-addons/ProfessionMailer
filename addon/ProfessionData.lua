---Handle saved profession data
_G['ProfessionData'] = {}
local lib =_G['ProfessionData']
local common = _G['ProfessionMailerCommon-@project-version@']
local utils = common.utils

--- Initialize a table as a global variable
--- @param name string Global variable name
--- @param character string Character key
function lib:init_table(name, character)
	if not _G[name] then
		_G[name] = {}
	end
	if character and not _G[name][character] then
		_G[name][character] = {}
	end
end

--- Get recipes an item can be used for
--- @param itemID number Item ID
--- @return table Recipes indexed by crafted item ID
function lib:ItemUsedFor(itemID)
	return _G['ItemRecipes'][itemID]
end

--- Get the difficulty of a recipe for a character
--- @param character string Character name and realm
--- @param craftedItemId number Item ID of the crafted item
--- @return string Difficulty name (trivial, optimal, etc)
function lib:RecipeDifficulty(_, character, craftedItemId)
	return _G['CharacterDifficulty'][character][craftedItemId]
end

--- Who need an item for crafting?
--- @param itemID number Item ID to check
--- @return table
function lib:whoNeeds(itemID)
	local crafts = self:ItemUsedFor(itemID)
	if not crafts then
		print('No known usages of item ' .. itemID)
		return
	end
	local difficulty
	local crafted = {}
	for craftedItemId, craft in pairs(crafts) do
		--difficulty = self.RecipeDifficulty()
		for character, difficulties in pairs(_G['CharacterDifficulty']) do
			difficulty = difficulties[craftedItemId]
			if difficulty then
				print(utils:sprintf('%s can use %s to craft %s with difficulty %s', character, itemID, craft['name'], difficulty))
				table.insert(crafted, {
					name = craft['name'], --Crafted item name
					craftedItemId = craft['itemID'],
					materialItemId = itemID,
					character = character,
					difficulty = difficulty,
				})
			end
		end
	end
	return crafted
end
