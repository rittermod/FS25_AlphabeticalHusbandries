-- RmSettings.lua
-- Purpose: Game settings integration for AlphabeticalHusbandries
-- Author: Ritter
--
-- Adds a toggle to the Game Settings page to hide empty husbandries.
-- Follows the RmAscSettings pattern: clone BinaryOption from gameSettingsLayout.

local Log = RmLogging.getLogger("AlphabeticalHusbandries")

RmSettings = {}

-- Runtime state (1 = OFF, 2 = ON; BinaryOption convention)
RmSettings.hideEmptyState = 1  -- default: disabled

-- GUI element reference
RmSettings.uiInitialized = false

-- =============================================================================
-- Public API
-- =============================================================================

--- Check if hide-empty-husbandries is enabled
---@return boolean
function RmSettings.isHideEmptyEnabled()
    return RmSettings.hideEmptyState == 2
end

-- =============================================================================
-- GUI Initialization
-- =============================================================================

--- Initialize GUI elements by cloning from existing game settings
-- Called at source time (g_inGameMenu is available)
function RmSettings.initGui()
    Log:trace(">>> RmSettings.initGui")

    if g_inGameMenu == nil then
        Log:warning("RmSettings: g_inGameMenu not available")
        return
    end

    local settingsPage = g_inGameMenu.pageSettings
    if settingsPage == nil then
        Log:warning("RmSettings: g_inGameMenu.pageSettings not available")
        return
    end

    local scrollPanel = settingsPage.gameSettingsLayout
    if scrollPanel == nil then
        Log:warning("RmSettings: gameSettingsLayout not available")
        return
    end

    -- Find templates: section header and BinaryOption container
    local sectionHeaderTemplate = nil
    local binaryOptionTemplate = nil

    for _, element in pairs(scrollPanel.elements) do
        if element.name == "sectionHeader" and sectionHeaderTemplate == nil then
            sectionHeaderTemplate = element
        end
        if element.typeName == "Bitmap" and binaryOptionTemplate == nil then
            if element.elements[1] ~= nil and element.elements[1].typeName == "BinaryOption" then
                binaryOptionTemplate = element
            end
        end
        if sectionHeaderTemplate ~= nil and binaryOptionTemplate ~= nil then
            break
        end
    end

    if sectionHeaderTemplate == nil or binaryOptionTemplate == nil then
        Log:warning("RmSettings: Could not find UI templates in gameSettingsLayout")
        return
    end

    -- Clone section header
    local header = sectionHeaderTemplate:clone(scrollPanel)
    header:setText(g_i18n:getText("rm_ah_settings_section"))

    -- Clone BinaryOption for hide-empty toggle
    local container = binaryOptionTemplate:clone(scrollPanel)
    container.id = nil  -- clear cloned ID to avoid conflicts

    local binaryOption = container.elements[1]
    local titleText = container.elements[2]

    titleText:setText(g_i18n:getText("rm_ah_settings_hideEmpty"))
    binaryOption.elements[1]:setText(g_i18n:getText("rm_ah_settings_hideEmpty_tooltip"))
    binaryOption.id = "rmAhHideEmpty"
    binaryOption.onClickCallback = RmSettings.onToggleChanged

    -- Store reference for state updates
    settingsPage.rmAhHideEmpty = binaryOption

    container:setVisible(true)
    container:setDisabled(false)

    scrollPanel:invalidateLayout()

    RmSettings.uiInitialized = true
    Log:info("RmSettings: GUI initialized")
end

-- =============================================================================
-- Lifecycle Hooks
-- =============================================================================

--- Set up all lifecycle hooks
function RmSettings.setupHooks()
    Log:trace(">>> RmSettings.setupHooks")

    -- Load user settings after mission loads
    Mission00.loadItemsFinished = Utils.appendedFunction(
        Mission00.loadItemsFinished,
        RmSettings.loadSettings
    )

    -- Save user settings when game saves
    FSCareerMissionInfo.saveToXMLFile = Utils.appendedFunction(
        FSCareerMissionInfo.saveToXMLFile,
        RmSettings.saveSettings
    )

    -- Update UI state when settings frame opens
    InGameMenuSettingsFrame.updateGameSettings = Utils.appendedFunction(
        InGameMenuSettingsFrame.updateGameSettings,
        RmSettings.updateGameSettings
    )

    Log:debug("RmSettings: Lifecycle hooks registered")
end

-- =============================================================================
-- Settings Change Handling
-- =============================================================================

--- Called when BinaryOption is clicked
---@param _ table element (unused)
---@param state number New state (1 = OFF, 2 = ON)
function RmSettings.onToggleChanged(_, state)
    RmSettings.updateHideEmpty(state)
end

--- Update setting state
---@param state number New state (1 = OFF, 2 = ON)
function RmSettings.updateHideEmpty(state)
    if state ~= RmSettings.hideEmptyState then
        RmSettings.hideEmptyState = state
        local enabled = (state == 2)
        Log:info("RmSettings: Hide empty husbandries %s", enabled and "enabled" or "disabled")
    end
end

-- =============================================================================
-- UI State Update
-- =============================================================================

--- Called via updateGameSettings hook when settings frame opens
---@param settingsPage table InGameMenuSettingsFrame instance
function RmSettings.updateGameSettings(settingsPage)
    local element = settingsPage.rmAhHideEmpty
    if element ~= nil then
        element:setState(RmSettings.hideEmptyState)
    end
end

-- =============================================================================
-- Save/Load (user preferences in modSettings directory)
-- =============================================================================

RmSettings.SETTINGS_DIR = "FS25_AlphabeticalHusbandries/"
RmSettings.SETTINGS_FILE = "settings.xml"

--- Get the settings file path, creating the directory if needed
---@return string|nil File path, or nil if modSettings unavailable
function RmSettings.getSettingsPath()
    if g_modSettingsDirectory == nil then
        return nil
    end
    local dir = g_modSettingsDirectory .. RmSettings.SETTINGS_DIR
    createFolder(dir)
    return dir .. RmSettings.SETTINGS_FILE
end

--- Load user settings from modSettings directory
function RmSettings.loadSettings()
    Log:trace(">>> RmSettings.loadSettings")

    local filePath = RmSettings.getSettingsPath()
    if filePath == nil then
        return
    end

    local xmlFile = XMLFile.loadIfExists("rm_AhSettings", filePath, "rmAhSettings")

    if xmlFile ~= nil then
        local hideEmpty = xmlFile:getBool("rmAhSettings#hideEmpty", false)
        RmSettings.hideEmptyState = hideEmpty and 2 or 1

        xmlFile:delete()
        Log:info("RmSettings: Loaded from %s (hideEmpty=%s)", filePath, tostring(hideEmpty))
    end
end

--- Save user settings to modSettings directory
function RmSettings.saveSettings()
    local filePath = RmSettings.getSettingsPath()
    if filePath == nil then
        return
    end

    local xmlFile = XMLFile.create("rm_AhSettings", filePath, "rmAhSettings")

    if xmlFile ~= nil then
        xmlFile:setBool("rmAhSettings#hideEmpty",
            RmSettings.hideEmptyState == 2)
        xmlFile:save()
        xmlFile:delete()
        Log:debug("RmSettings: Saved to %s", filePath)
    end
end

-- =============================================================================
-- Module Initialization (runs at source time)
-- =============================================================================

RmSettings.initGui()
RmSettings.setupHooks()
