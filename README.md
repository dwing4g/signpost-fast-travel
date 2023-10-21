# Signpost Fast Travel

Fast travel from signposts to their locations if you have already been there before.

**Requires OpenMW 0.49 or newer!**

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

#### Testing This Mod

There are console commands available to "find" all travel targets as well as to "forget" them again. To use:

1. Press the \` key to open the console
1. Type `luap` and press Enter
1. Type `I.SignpostFastTravel.findAll()` and press Enter to find all travel targets
1. Type `I.SignpostFastTravel.p()` and press Enter to print your list of found targets to the console (F10)
1. Type `I.SignpostFastTravel.forgetAll()` and press Enter to forget all travel targets
1. Type `exit()` and press Enter to exit the Lua console when done

#### Report A Problem

If you've found an issue with this mod, or if you simply have a question, please use one of the following ways to reach out:

* [Open an issue on GitLab](https://gitlab.com/modding-openmw/signpost-fast-travel/-/issues)
* Email `signpost-fast-travel@modding-openmw.com`
* Contact the author on Discord: `johnnyhostile#6749`
* Contact the author on Libera.chat IRC: `johnnyhostile`
