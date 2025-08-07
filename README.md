# FS25_AlphabeticalHusbandries

Tired of hunting through your husbandries to find the right animals? This mod sorts your husbandries alphabetically in the Animals menu for easier management and navigation.

Singleplayer only.

## Notes
This mod hooks into the in-game Animals menu to provide alphabetical sorting of husbandries. It works by sorting both the underlying data and the GUI selector when you open the Animals menu.

## Features
- **Alphabetical Sorting**: Automatically sorts husbandries by the names you have given them 
- **No Configuration Required**: Works automatically - just install and enjoy


## Installation
1. Download the mod files
2. Copy the `FS25_AlphabeticalHusbandries` folder into your Farming Simulator 2025 mods directory:
   - Windows: `Documents/My Games/FarmingSimulator2025/mods`
   - macOS: `~/Library/Application Support/FarmingSimulator2025/mods`
3. Start the game and the mod will automatically sort your husbandries alphabetically

## How It Works
The mod works by:
- Hooking into the `InGameMenuAnimalsFrame.updateHusbandries` event to sort data whenever husbandries are loaded or updated
- Hooking into the `InGameMenuAnimalsFrame.onFrameOpen` event to update the selector display when the menu opens
- Sorting the `sortedHusbandries` data array alphabetically by husbandry name
- Updating the `subCategorySelector` component with the sorted husbandry names

