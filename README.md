# NiceScripts
### Where ideas turn into reality
### By nicehouse10000e and some00004 (Roblox users)

# Introduction
NiceScripts (also known as NicePrograms) is a large-scale project that began on November 27, 2025, and is still actively being developed.

The script is designed to work in three different Roblox environments:
- HiddenUI (exploit-based GUI)
- CoreGui (Roblox’s built-in UI layer, such as chat and emotes)
- PlayerGui (higher detection risk)

# History
NiceScripts started as a simple white interface. At first, its only feature was a basic `create_config_button` function. It was unreliable, minimal, and experimental.

Before the original release — then called "Nice Template" — the developer almost scrapped the idea. After some hesitation and debugging, he realized it could serve as a foundation for something bigger and even be shared online.

What began as a small prototype slowly evolved into what is now known as "NiceUI." After several hours of fixing issues and refining the system, the first public build was released: Build #38 (NT v38).

# Programs
We have these available scripts that can be used publicly without any issues
## Active (Updated frequently)
1. NiceUI
2. NiceScare
3. NiceAura (ONLY USE THIS IN ROBLOX "PRISON LIFE")
4. Nice "See"
## Archived
1. NiceTemplate v151

# About: NiceUI
### UI Version: 152-Beta 02222026A

NiceUI is the primary interface framework of the NiceScripts project.  
It is designed to be lightweight, modular, and easy to integrate into different Roblox environments.  
The goal of NiceUI is to provide a structured and expandable UI system that developers can build on without rewriting core components.

Below is a list of public functions currently available.

## Public Functions

### Core
1. `get_gui()`  
   Returns a dedicated GUI container managed by NiceUI.  
   Arguments: none

2. `set_name(name)`  
   Sets the main interface title.  
   Arguments: `string`

3. `create_tab(name)`  
   Creates a new tab inside the interface.  
   Arguments: `string`

### Interactive Components
4. `create_click_button(name, tab, callback)`  
   Creates a clickable button inside a specified tab.  
   Arguments: `string, string, function`

5. `create_slider(name, default_value, allow_float, range, tab, callback)`  
   Creates a slider with configurable range and optional floating-point values.  
   Arguments: `string, number, boolean, {number, number}, string, function`

6. `create_text_editor(name, default_text, tab, callback)`  
   Creates a text editor field for user input.  
   Arguments: `string, string, string, function`

7. `create_item_picker(name, items, default_item, tab, callback)`  
   Creates a selectable item list from a provided table.  
   Arguments: `string, table, table.item, string, function`

8. `create_color_editor(name, default_color, tab, callback)`  
   Creates a Color3 editor for selecting UI or feature colors.  
   Arguments: `string, Color3, string, function`

9. `create_boolean(name, default_value, tab, callback)`  
   Creates a toggle (true/false switch).  
   Arguments: `string, boolean, string, function`

### Display & Utility
10. `create_text(name, value, tab)`  
    Displays static text inside a tab.  
    Arguments: `string, string, string`

11. `create_popup(title, description, choices, callback)`  
    Creates a confirmation or decision popup window.  
    Arguments: `string, string, table, function`

12. `display_message(title, message, sound_id)`  
    Displays a notification message with optional sound.  
    Arguments: `string, string, string`

13. `make_stealth_mode()`  
    Toggles visibility of the GUI. Useful during gameplay recording or screenshots.  
    Arguments: none

## Deprecated
- `create_gui(name, smoothness)`  
  This function will be removed in v154.  
  Please migrate to `set_name(name)` to avoid future compatibility issues.

## Temporarily Disabled
- `apply_theme(instance, theme_name)`  
  Applies a specified theme to a target instance.  
  Arguments: `object, string`

- `create_theme(name, data)`  
  Creates a new custom theme configuration.  
  Arguments: `string, {Color3, Color3, Color3, Color3, Color3, Color3}`

### Additional notes:
NiceUI's name set as "stereotypica", which means it's a beta or unstable release version of NiceUI
