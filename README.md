# Signpost Fast Travel

Fast travel from signposts to their locations if you have already been there before.

Inspired by the Witcher 3 fast travel system and [Andromedas Fast Travel](https://www.nexusmods.com/morrowind/mods/41542), automatically supports [Tamriel Rebuilt](https://www.tamriel-rebuilt.org/) if that's installed as well, and borrows NPC travel features from [Attend Me](https://www.nexusmods.com/morrowind/mods/51232).

**Requires OpenMW 0.49 or newer!**

Part of this mod's development was live streamed, [please check it out](https://www.youtube.com/watch?v=uFPRcE03ljc)!

#### Credits

Author: **johnnyhostile**

Lua Assistance: **Pharis, urm, kuyondo, gnounc, ZackHasACat**

**Special Thanks**:

* **SGMonkey** for making [Andromedas Fast Travel](https://www.nexusmods.com/morrowind/mods/41542)
* **urm** for making [Attend Me](https://www.nexusmods.com/morrowind/mods/51232) and being cool with me using his follower teleport code
* **CDPR** for making Witcher 3
* **The Tamriel Rebuilt Team** for making [Tamriel Rebuilt](https://www.tamriel-rebuilt.org/)
* **The OpenMW team, including every contributor** for making OpenMW and OpenMW-CS
* **The Modding-OpenMW.com team** for being amazing
* **All the users in the `modding-openmw-dot-com` Discord channel on the OpenMW server** for their dilligent testing <3
* **Bethesda** for making Morrowind

And a big thanks to the entire OpenMW and Morrowind modding communities! I wouldn't be doing this without all of you.

#### Localization

EN: johnnyhostile

PT_BR: Hurdrax Custos

RU: urm

SV: Lysol

#### Web

[Project Home](https://modding-openmw.gitlab.io/signpost-fast-travel/)

<!-- [Nexus Mods](https://www.nexusmods.com/morrowind/mods/#TODO) -->

[Source on GitLab](https://gitlab.com/modding-openmw/signpost-fast-travel)

#### Installation

**OpenMW 0.49 or newer is required!**

1. Download the mod from [this URL](https://modding-openmw.gitlab.io/signpost-fast-travel/)
1. Extract the zip to a location of your choosing, examples below:

        # Windows
        C:\games\OpenMWMods\Travel\signpost-fast-travel

        # Linux
        /home/username/games/OpenMWMods/Travel/signpost-fast-travel

        # macOS
        /Users/username/games/OpenMWMods/Travel/signpost-fast-travel

1. Add the appropriate data path to your `opemw.cfg` file (e.g. `data="C:\games\OpenMWMods\Travel\signpost-fast-travel"`)
1. Add `content=signpost-fast-travel.omwscripts` and `content=signpost-fast-travel.omwaddon` to your load order in `openmw.cfg` or enable them via OpenMW-Launcher
    * If you're also using [Signposts Retextured](https://www.nexusmods.com/morrowind/mods/42126), activate the `PB_SignpostsRetextured.omwaddon` and `PB_SignpostsRetexturedTR.omwaddon` (if also using TR) plugins that come with this instead of the ones that come with it.

#### Configuration

Various aspects of this mod are configurable via the script settings menu (ESC >> Options >> Scripts):

* Teleport followers (**on by default**, auto-disabled when Attend Me is installed alongside this)
* Time passes when traveling (**on by default**)
* Gold cost for travel per "unit" (**5 gold by default**; set to 0 for free travel)
* Show messages when traveling (**on by default**)
* Play footstep sounds when traveling (**on by default**)

#### Known Issues / Notes

* Not all signposts have a "name" that corresponds to a named external cell that can be traveled to.
  * Some simply don't have a related exterior and are ignored.
  * Others do relate to an actual exterior but have extra details e.g, `Ildrim (main road)` or `Firewatch via Aranyon Pass`.
    * In this case, an internal map is kept that points these to the appropriate name.
* Time doesn't actually pass when traveling, so any active spells or other potentially timed things won't be affected. This can be resolved when OpenMW-Lua adds a way to pass time.
* The engine silently turns activators with no "name" into statics. This means mods that remove the name for immersion purposes will break this mod (see [Compatibility](#compatibility) below). This can be resolved when OpenMW-Lua adds a way to see nearby statics in the same way it does activators.
* OpenMW-Lua doesn't yet have a way to take money from the player or pass time. I achieve both via the "MWScript bridge" which is why this mod requires a global script. When I can do those things from Lua, the global script can go away.
* Paying money to the signpost is a tad strange, but I felt that dropping NPCs at every signpost was more strange. The current implementation is a compromise that gives a cost to travel without the extra burden and potential awkwardness of NPCs.

#### Compatibility

This mod should be compatible with any replacer that preserves the "name" of the signpost activators. Mods known to be incompatible due to this:

* [Signposts Retextured](https://www.nexusmods.com/morrowind/mods/42126)
    * Patched plugins are included with this mod, they restore the "name" field which also restores the name tooltip when you look at the signs

#### Adding Support For New Signs

This mod comes with an interface that can be used to add support for more signs via a third party mod. Please note that a valid sign should be an activator with a `name` field that matches some named exterior cell or cells.

To do this, two files are needed:

1. `YourAddonName.omwscripts` with the following contents:

```
GLOBAL: scripts/YourAddonName/global.lua
```

1. `scripts/YourAddonName/global.lua` with the following contents:

```lua
local SFT = require("openmw.interfaces").SignPostFastTravel

if not SFT then
    error("ERROR: Signpost Fast Travel is not installed!")
end

SFT.RegisterSigns({
        "signpost_id_01",
        "signpost_id_02",
        ...
})
```

File layout:

```
.
├── YourAddonName.omwscripts
└── scripts
    └── YourAddonName
        └── global.lua
```

Note you should change `YourAddonName` to match your mod's name and the IDs used to match the IDs you want to add.

The `SFT` variable gives you direct access to the Signpost Fast Travel interface. You can use whatever script and path names you like, but it must be [a global script](https://openmw.readthedocs.io/en/latest/reference/lua-scripting/overview.html#format-of-omwscripts).

#### Lua Console Commands

You can use these from the in-game console to test the functionality of this mod.

1. Press the \` key to open the console
1. Type `luap` and press Enter
1. Type `I.SignpostFastTravel.Forget("Some Name")` and press Enter to delete all of the stored travel points for the given location (not reversible!)
1. Type `I.SignpostFastTravel.ForgetAll()` and press Enter to forget all travel targets (not reversible!)
1. Type `I.SignpostFastTravel.ShowPoints("Some Name")` and press Enter to travel to a print points for the given location to the console (F10)
1. Type `I.SignpostFastTravel.P()` and press Enter to print your list of found targets and their points to the console (F10)
1. Type `I.SignpostFastTravel.TravelTo("Some Name")` and press Enter to travel to a random stored point in the given location
1. Type `exit()` and press Enter to exit the Lua console when done

#### Lua Interface

The following may be used in another mod when installed alongside this one:

* `I.SignpostFastTravel.GetPoint("Some Name")` returns a random point for the given location as a `util.vector3` if there is one, `nil` if not

```lua
if I.SignpostFastTravel then
  local balmoraRandPoint = I.SignpostFastTravel.GetPoint("Balmora")
  if balmoraRandPoint then
    -- Do something with the point
    ...
  end
end
```

#### Report A Problem

If you've found an issue with this mod, or if you simply have a question, please use one of the following ways to reach out:

* [Open an issue on GitLab](https://gitlab.com/modding-openmw/signpost-fast-travel/-/issues)
* Email `signpost-fast-travel@modding-openmw.com`
* Contact the author on Discord: `@johnnyhostile`
* Contact the author on Libera.chat IRC: `johnnyhostile`

#### Planned Features

* Disable traveling if a hostile enemy is nearby
* Some way to use all the points that are generated for cells that have no corresponding sign post (A menu, perhaps?)
* Allow adding to the cell naughty list via the interface
* Use pathgrid path vs a straight line
* Factor player stats such as speed into time cost
* Factor timescale
