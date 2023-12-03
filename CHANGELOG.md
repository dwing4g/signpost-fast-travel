## Signpost Fast Travel Changelog

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
