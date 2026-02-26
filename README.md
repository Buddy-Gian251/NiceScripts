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
### UI VERSION: 152-Beta 02222026A
Here is a list of NiceUI's public functions
## Usable
1. `get_gui()` gives you a separate GUI container that NiceUI can manage. No arguments
2. `set_name(name)` sets the name of the interface. 1 argument: a string value
3. `create_tab(name)` creates a tab with a name. 1 argument: a string value
4. `create_click_button(name, tab, callback)` creates a button in a tab with a name. 3 arguments: string, string, function
5. `create_slider(name, init_number, float_enabled, range, tab, callback)` creates a slider in a tab. 6 arguments: string, number, boolean, {number, number}, string, function
6. `create_text_editor(name, text, tab, callback)` creates a text editor in a tab. 4 arguments: string, string, string, function
7. `create_item_picker(name, items, default, tab, callback)` creates an item picker for a table. 5 arguments: string, table, table.item, string, function
8. `create_color_editor(name, value, tab, callback)` creates a color editor. 4 arguments: string, color3, string, function
9. `create_boolean(name, default, tab, callback)` creates a true/false toggle. 4 arguments: string, boolean, string, function
10. `create_text(name, value, tab)` creates a text. 3 arguments: string, string, string
11. `make_stealth_mode()` hides/unhides the GUI, useful when recording a gameplay (since the separate GUI hides also).
12. `create_popup(name, description, choices, callback)` creates a pop-up for confirmation or an alternate way of sending notifications. 4 arguments: string, string, table, function
13. `display_message(customtitle, customtext, customsound)` casts a message, traditional use for notifications.

## Deprecated
1. `create_gui(name, smoothness)` creates the GUI, please migrate to `set_name(name)` to avoid errors (WILL BE DELETED ON v154).

## Temporarily Disabled
1. `apply_theme(instance, theme_name)` applies to the target theme. 2 arguments: object, name
2. `create_theme(name, data)` creates a theme. 2 arguments: string, {color3, color3, color3, color3, color3, color3)
