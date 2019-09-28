local inv = LibStub:NewLibrary("LibInventory-1.0", 1)
local NUM_EQUIPMENT_SLOTS = 19
local addonName, addon = ...

--/dump LibStub("LibInventory-1.0"):GetBags()
function addon:GetBags()
    local items = {}

    for bag=1, 4, 1 do
        slots = GetContainerNumSlots(bag)
        for slot=1, slots, 1 do
            --local itemId = GetContainerItemID(bag, slot);
            --local itemLink = GetContainerItemLink(bag, slot)
            local icon, itemCount, locked, quality, readable, lootable, itemLink, isFiltered, noValue, itemID = GetContainerItemInfo(bag, slot)
            if itemID ~= nil then
                items[itemID] = {["bag"]=bag, ["slot"]=slot, ["icon"]=icon, ["itemCount"]=itemCount, ["locked"]=locked, ["quality"]=quality, ["readable"]=readable, ["lootable"]=lootable, ["itemLink"]=itemLink, ["isFiltered"]=isFiltered, ["noValue"]=noValue, ["itemID"]=itemID}
            end
        end
    end
    return items
end

