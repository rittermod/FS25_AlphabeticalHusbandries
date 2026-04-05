-- main.lua
-- Purpose: Mod loader - sources scripts in order, registers lifecycle hooks
-- Author: Ritter

local modDirectory = g_currentModDirectory
local modName = g_currentModName

-- =============================================================================
-- SOURCE SCRIPTS
-- =============================================================================

source(modDirectory .. "scripts/rmlib/RmLogging.lua")
local Log = RmLogging.getLogger("AlphabeticalHusbandries")
Log:setLevel(RmLogging.LOG_LEVEL.DEBUG)

source(modDirectory .. "scripts/RmSettings.lua")
source(modDirectory .. "scripts/RmAlphabeticalHusbandries.lua")

-- =============================================================================
-- TESTING (conditional - tests excluded from release builds)
-- =============================================================================

local testRunnerPath = modDirectory .. "scripts/tests/RmTestRunner.lua"
if fileExists(testRunnerPath) then
    source(testRunnerPath)
end

-- =============================================================================
-- LIFECYCLE
-- =============================================================================

addModEventListener(RmAlphabeticalHusbandries)

Log:info("Alphabetical Husbandries loaded (v%s)", g_modManager:getModByName(modName).version)
