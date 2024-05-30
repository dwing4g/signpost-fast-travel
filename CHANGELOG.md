## Signpost Fast Travel Changelog

#### 2.13

* Added a reset-after-quest feature that forgets travel points in cells after a certain point in a given quest
    * This is useful for the Great House faction stronghold quests, where the cell is basically bare but then has statics placed into it
    * Unfortunately this means that the location will not be present in the travel menu until it is revisited
* Added "Bethesda Mode" which enables the player to pull up the fast travel menu with a keypress (at no token cost)
* Fixed a gramatical error in the travel message pop up
* Fixed a dialogue typo

<!-- [Download Link](https://gitlab.com/modding-openmw/signpost-fast-travel/-/packages/#TODO) -->

#### 2.12

* Fixed a dialogue issue that made the quest inaccessible (safe to update an in-progress game, no re-merge should be needed for this)

[Download Link](https://gitlab.com/modding-openmw/signpost-fast-travel/-/packages/25803725)

#### 2.11

* Support when mods change the `Ald-ruhn` sign to `Ald'ruhn`

[Download Link](https://gitlab.com/modding-openmw/signpost-fast-travel/-/packages/25780770)

#### 2.10

* Moved remaining inline timer callbacks to the script body
* Handled an error that could occur when a summoned creature expires

[Download Link](https://gitlab.com/modding-openmw/signpost-fast-travel/-/packages/25354732)

#### 2.9

* Combat checks are more accurate, now checking the distance between the actor and the player
* Added an interface command for seeing who the player is in combat with
* Added DE localization
* Updated EN localization

[Download Link](https://gitlab.com/modding-openmw/signpost-fast-travel/-/packages/25127976)

#### 2.8

* Fixed a bug that prevented the mod from working if it was enabled after the first quest was given

[Download Link](https://gitlab.com/modding-openmw/signpost-fast-travel/-/packages/24046621)

#### 2.7

* The number of points generated per cell as well as the number of times the cell scanning code tries to reach that count is now configurable
* The MWScript bridge global script has been removed, its functionality implemented in pure Lua

[Download Link](https://gitlab.com/modding-openmw/signpost-fast-travel/-/packages/23926813)

#### 2.6

* Optimization: the mod no longer operates in `onUpdate` (meaning every frame when the game's not paused) but now works every two seconds (configurable via the script menu)
* Fixed a bug where Seyda Neen travel points where generated on the chargen boat ([#1](https://gitlab.com/modding-openmw/signpost-fast-travel/-/issues/1))
  * Once the player receives their first mission, this mod's cell scanning will begin after a two minute delay (configurable via the script menu)
* Fixed a bug in the combat detection code

[Download Link](https://gitlab.com/modding-openmw/signpost-fast-travel/-/packages/23717207)

#### 2.5

* Some UI sizing consistency fixes
* Updated the SV localization
* Added support for [Skyrim Home Of The Nords](https://www.nexusmods.com/morrowind/mods/44921) (automatically enabled if it's installed)

[Download Link](https://gitlab.com/modding-openmw/signpost-fast-travel/-/packages/21429927)

#### 2.4

* Added a menu-based fast travel system that lets you go to _any_ named exterior you've previously visited via the click of a menu entry
  * Traveling in this way costs a special "travel token" (can be disabled and made free)
  * The token icon, mesh, and texture are from [OAAB_Data](https://www.nexusmods.com/morrowind/mods/49042)
  * **SPOILER**: These tokens can be gotten from <span class="spoiler">a semi-hidden NPC who is a member of the Mage's Guild out in the field on an expedition with others (the README says which specific location this is)</span>
  * The menu fully supoprts controller and keyboard inputs
* Fixed a bug with loading 2.X on a save that played with 1.0
* All Lua-based strings including console commands are now localized
* More safeguards around code that checks if the player is in combat or not
* Travel points will now only be generated if the player is on solid ground

[Download Link](https://gitlab.com/modding-openmw/signpost-fast-travel/-/packages/21213259)

#### 2.3

* Fixed a problem with detecting if the player is in combat

[Download Link](https://gitlab.com/modding-openmw/signpost-fast-travel/-/packages/20782519)

#### 2.2

* Fixed a problem with case sensitivity of signpost IDs

[Download Link](https://gitlab.com/modding-openmw/signpost-fast-travel/-/packages/20781943)

#### 2.1

* Fixed issues with loading a save that used version `1.0`

[Download Link](https://gitlab.com/modding-openmw/signpost-fast-travel/-/packages/20781842)

#### 2.0

* Note that this version is compatible with old saves but your existing "found" locations will not carry over!
* Added procedurally-generated travel target points
  * This replaces the old, hand-placed travel targets from version 1.0
  * Up to 100 different random points will be selected for each area
    * Named areas that span multiple cells will have up to 100 points _per cell_ (so Seyda Neen can in theory have up to 200, and so on. In reality it's closer to 100 or so across two cells for various reasons relating to terrain and etc)
* Added an interface for adding new signpost IDs via a third party mod (see the README for instructions on how to make such a mod)
* Added several new console interface commands for testing
* Added footstep sounds that play when you travel (can be disabled via settings)
* Added an ID blacklist as well as an ID "naughty list"
  * The blacklist contains IDs that don't map to a valid named exterior cell
  * The naughty list is a map of activator name fields to exterior cell names for things like `Ildrim (main road)` or `Firewatch via Aranyon Pass`
* Added a patched version of the TR plugin from [Signposts Retextured](https://www.nexusmods.com/morrowind/mods/42126) by PeterBitt
* Travel is now disallowed when in combat with a nearby enemy
* The mod will now function without the `.omwaddon` plugin; features that require it will be auto-disabled when it's not present

[Download Link](https://gitlab.com/modding-openmw/signpost-fast-travel/-/packages/20779514)

#### 1.0

* Fixed "seeing" TR signs
* Added a cost to travel, the value is configurable (0 to disable)
* Made the passing of time and showing messages configurable

[Download Link](https://gitlab.com/modding-openmw/signpost-fast-travel/-/packages/19697842)

#### beta4

* The settings menu is now disabled if Attend Me is installed
* Lowercased TR signpost IDs
* Fixed some incorrect pluralizations
* Made Attend Me options configurable if that mod is not also installed

[Download Link](https://gitlab.com/modding-openmw/signpost-fast-travel/-/packages/19600850)

#### beta3

* Follower features from Attend Me are disabled if that mod is also installed
* Fixed some signs that were broken due to not being lowercase

[Download Link](https://gitlab.com/modding-openmw/signpost-fast-travel/-/packages/19600201)

#### beta2

* Added follower teleportation (from [Attend Me](https://www.nexusmods.com/morrowind/mods/51232) - thanks urm!)
  * Currently not configurable, unlike Attend Me

[Download Link](https://gitlab.com/modding-openmw/signpost-fast-travel/-/packages/19600084)

#### beta1

Initial version of the mod, not all features are implemented yet. Noteably: followers don't travel with you.

[Download Link](https://gitlab.com/modding-openmw/signpost-fast-travel/-/packages/19599770)
