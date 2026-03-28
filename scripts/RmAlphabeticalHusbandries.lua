RmAlphabeticalHusbandries = {}
local RmAlphabeticalHusbandries_mt = Class(RmAlphabeticalHusbandries)

RmAlphabeticalHusbandries.dir = g_currentModDirectory
source(RmAlphabeticalHusbandries.dir .. "scripts/rmlib/RmLogging.lua")
local Log = RmLogging.getLogger("AlphabeticalHusbandries")

function RmAlphabeticalHusbandries.new(customMt)
    local self = setmetatable({}, customMt or RmAlphabeticalHusbandries_mt)
    return self
end

local function alphabeticalSortHusbandries(a, b)
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

function RmAlphabeticalHusbandries.missionStarted()
    Log:info("Mission started, hooking into husbandry sorting functions")

    if InGameMenuAnimalsFrame then
        -- Hook updateHusbandries to sort data whenever it's updated
        InGameMenuAnimalsFrame.updateHusbandries = Utils.appendedFunction(InGameMenuAnimalsFrame.updateHusbandries, function(self)
            if self.sortedHusbandries and type(self.sortedHusbandries) == "table" and #self.sortedHusbandries > 0 then
                -- Sort the husbandries alphabetically
                table.sort(self.sortedHusbandries, alphabeticalSortHusbandries)
                Log:debug("Sorted %d husbandries in updateHusbandries", #self.sortedHusbandries)
            end
        end)
        
        -- Hook onFrameOpen to update selector when animals menu is opened
        InGameMenuAnimalsFrame.onFrameOpen = Utils.appendedFunction(InGameMenuAnimalsFrame.onFrameOpen, function(self)
            Log:debug("InGameMenuAnimalsFrame.onFrameOpen called")
            if self.sortedHusbandries and type(self.sortedHusbandries) == "table" and #self.sortedHusbandries > 0 then
                -- Ensure data is sorted
                table.sort(self.sortedHusbandries, alphabeticalSortHusbandries)

                -- Update the subCategorySelector with sorted names
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
            end
        end)

        Log:info("Successfully hooked InGameMenuAnimalsFrame onFrameOpen")
    else
        Log:warning("InGameMenuAnimalsFrame not found")
    end
end

g_messageCenter:subscribe(MessageType.CURRENT_MISSION_START, RmAlphabeticalHusbandries.missionStarted)

addModEventListener(RmAlphabeticalHusbandries)
