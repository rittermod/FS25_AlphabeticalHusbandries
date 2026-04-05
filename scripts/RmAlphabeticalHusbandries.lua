-- RmAlphabeticalHusbandries.lua
-- Purpose: Sorts husbandries alphabetically in the Animals menu
-- Author: Ritter

RmAlphabeticalHusbandries = {}
local RmAlphabeticalHusbandries_mt = Class(RmAlphabeticalHusbandries)

local Log = RmLogging.getLogger("AlphabeticalHusbandries")

function RmAlphabeticalHusbandries.new(customMt)
    local self = setmetatable({}, customMt or RmAlphabeticalHusbandries_mt)
    return self
end

-- =============================================================================
-- CORE LOGIC
-- =============================================================================

--- Sort comparator for husbandry objects - alphabetical by name (case-insensitive)
---@param a table|nil Husbandry object with getName() method
---@param b table|nil Husbandry object with getName() method
---@return boolean true if a should come before b
function RmAlphabeticalHusbandries.alphabeticalSortHusbandries(a, b)
    local nameA = ""
    local nameB = ""

    if a ~= nil and a.getName ~= nil then
        nameA = a:getName() or ""
    end

    if b ~= nil and b.getName ~= nil then
        nameB = b:getName() or ""
    end

    return string.upper(nameA) < string.upper(nameB)
end

-- =============================================================================
-- FILTERING
-- =============================================================================

--- Filter out empty husbandries from a sorted list
--- Only hides husbandries that have getNumOfAnimals AND it returns 0.
--- Husbandries without the method are kept visible (never hide unknowns).
---@param sortedList table Array of husbandry objects
---@return table Filtered array (or original if setting is off)
function RmAlphabeticalHusbandries.filterEmptyHusbandries(sortedList)
    if not RmSettings.isHideEmptyEnabled() then
        return sortedList
    end

    local filtered = {}
    local hiddenCount = 0

    for _, husbandry in ipairs(sortedList) do
        if husbandry ~= nil and husbandry.getNumOfAnimals ~= nil then
            local numAnimals = husbandry:getNumOfAnimals()
            if numAnimals == 0 then
                hiddenCount = hiddenCount + 1
                Log:trace("Hiding empty husbandry: %s", husbandry.getName and husbandry:getName() or "unknown")
            else
                -- Has animals, or nil return (treat unknown count as non-empty)
                table.insert(filtered, husbandry)
            end
        else
            -- Unknown type or missing method -- keep visible
            table.insert(filtered, husbandry)
        end
    end

    if hiddenCount > 0 then
        Log:debug("Filtered %d empty husbandries, showing %d", hiddenCount, #filtered)
    end

    return filtered
end

-- =============================================================================
-- HOOKS
-- =============================================================================

function RmAlphabeticalHusbandries.missionStarted()
    Log:trace(">>> missionStarted")
    Log:info("Mission started, hooking into husbandry sorting functions")

    if InGameMenuAnimalsFrame then
        -- Hook updateHusbandries to sort data whenever it's updated
        InGameMenuAnimalsFrame.updateHusbandries = Utils.appendedFunction(InGameMenuAnimalsFrame.updateHusbandries, function(self)
            if self.sortedHusbandries and type(self.sortedHusbandries) == "table" and #self.sortedHusbandries > 0 then
                table.sort(self.sortedHusbandries, RmAlphabeticalHusbandries.alphabeticalSortHusbandries)
                self.sortedHusbandries = RmAlphabeticalHusbandries.filterEmptyHusbandries(self.sortedHusbandries)
                Log:debug("Sorted and filtered husbandries in updateHusbandries, showing %d", #self.sortedHusbandries)
            else
                Log:trace("updateHusbandries: no husbandries to sort")
            end
        end)

        -- Hook onFrameOpen to update selector when animals menu is opened
        InGameMenuAnimalsFrame.onFrameOpen = Utils.appendedFunction(InGameMenuAnimalsFrame.onFrameOpen, function(self)
            Log:trace(">>> onFrameOpen hook")
            if self.sortedHusbandries and type(self.sortedHusbandries) == "table" and #self.sortedHusbandries > 0 then
                table.sort(self.sortedHusbandries, RmAlphabeticalHusbandries.alphabeticalSortHusbandries)
                self.sortedHusbandries = RmAlphabeticalHusbandries.filterEmptyHusbandries(self.sortedHusbandries)

                if self.subCategorySelector then
                    local sortedTexts = {}
                    for _, husbandry in ipairs(self.sortedHusbandries) do
                        if husbandry and husbandry.getName then
                            table.insert(sortedTexts, husbandry:getName())
                        end
                    end

                    if self.subCategorySelector.setTexts then
                        self.subCategorySelector:setTexts(sortedTexts)
                        Log:debug("Updated selector with alphabetical order")
                    else
                        Log:warning("subCategorySelector.setTexts not found, cannot update texts")
                    end
                else
                    Log:warning("subCategorySelector not found in InGameMenuAnimalsFrame")
                end
            else
                Log:trace("onFrameOpen: no husbandries to sort")
            end
        end)

        Log:info("Successfully hooked InGameMenuAnimalsFrame sorting")
    else
        Log:warning("InGameMenuAnimalsFrame not found")
    end
end

g_messageCenter:subscribe(MessageType.CURRENT_MISSION_START, RmAlphabeticalHusbandries.missionStarted)
