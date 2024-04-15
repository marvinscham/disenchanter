# Changelog

All notable changes to this project will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/). Related: [versioning strategy](./VERSIONING.md).

## v1.8.0 - Apr 15, 2024
### Added
- Polish translation by **The_Shade2** (Thank you!)

### Changed
- Updates to Traditional Chinese translation by @nico12313 (Thank you!)

### Fixed
- Dependency updates

## v1.7.3 - Apr 04, 2024
### Fixed
- #167 Honor Level 3 Orbs now have proper display names

## v1.7.2 - Mar 03, 2024
### Fixed
- #157 Fixed a broken placeholder variable reference blocking mythic crafting from executing

## v1.7.1 - Feb 29, 2024
### Fixed
- Fixed and extended English locale detection
- #34 Loot with line breaks in its name will now properly be listed in the disenchant preview
- #126 Network related errors will no longer break the script
- #152 Mastery Token upgrade no longer offers inefficient upgrades
  - This happened when you had a champion permanent that had a disenchant value higher than the upgrade price
  - Champion shard disenchanting will now also take this into consideration

## v1.7.0 - Feb 29, 2024
### Added
- #144 Support for i18n, you can contribute using [Weblate](https://weblate.ms-ds.org/engage/disenchanter/).
  - Support for (most of) German, Esperanto and Traditional Chinese
- Documentation for contributions, project setup, translation credits
### Changed
- Mastery Chart shortcut will now auto-detect your region
- Some wording and display colors have been updated

## v1.6.0 - Feb 17, 2024
### Added
- #35 Disenchanter can be started from anywhere now
  - It will try to find your League Client via registry > start menu > default path > locally
- #57 Re-rolling owned esports emotes that cannot be disenchanted
- #19 Tacticians can now be disenchanted
- Shortcut to your [Mastery Chart](https://masterychart.com) profile
- #27 Proper changelog and versioning info
### Changed
- (dev) Code is split in modules now instead of stuffed into a single script
- (dev) Switched from ocra to ocran for building the executable
### Fixed
- #142 Script won't crash if you don't have a summoner name
  - Essentially Riot ID support
- #87 Shards of champions with no mastery will no longer falsely be considered for disenchanting
- #127 Champion permanents can be disenchanted again
- Reliability improvements via more flexible recipe and currency detection
  - #128 Allows properly disenchanting things like blue essence granting summoner icons

## v1.5.0 - Jul 26, 2022
### Added
- Support for disenchanting champion, skin, ward skin and eternal permanents
- Mastery token upgrades will also use champion permanents
- Debug options for troubleshooting
- (dev) Linting and formatting rules
- Demo image in `README` :)
### Changed
- Smarter detection for items that aren't owned yet
- Blue essence directly looted from capsules is now included in stats
- Loot will be refreshed more frequently to prevent calls on stale data
### Fixed
- Clarity when upgrading mastery tokens
- Some chest display names like Honor Capsules will have the name manually injected instead
- Faulty crafting recipes adjusted
- Typos removed

## v1.4.0 - Jul 14, 2022
### Added
- Disenchanting summoner icons
- Efficient mastery 6/7 token upgrades
  - Does not support champion permanents (yet)
### Changed
- Menu order is now like in the Client's loot tab
  - Materials are in separate submenu now
### Fixed
- #21 Bugfix for event token crafting
- Smarter version check for people directly running the Ruby script
- Code cleanup, minor bugfixes

## v1.3.2 - Jun 30, 2022
### Fixed
- #10 Collection feature properly retains one shard per champion

## v1.3.1 - Jun 29, 2022
### Fixed
- Fixed "keep shards of champions you don't own yet" option
- Fixed in-place updater + added backwards compatibility

## v1.3.0 - Jun 28, 2022
### Added
- In-place updating
  - Future versions can replace the old script with the latest version
- More things to disenchant:
  - Ward skins
  - Skins
  - Eternals
### Changed
- Swapped to new, less bloated menu style
### Fixed
- Reliability improvements to existing options

## v1.2.3 - Jun 21, 2022
### Fixed
- Clarity in wording and visuals
- Fixes to conservative options

## v1.2.2 - Jun 21, 2022
### Fixed
- Failing one step will no longer break the script but fall back to the main menu

## v1.2.1 - Jun 19, 2022
### Fixed
- Bugfix for capsule handling
### Docs
- Added info on malware false positives

## v1.2.0 - Jun 19, 2022
### Added
- Mythic Essence crafting to random skin shards, blue essence and orange essence
- Opening of keyless capsules
- Colors in terminal
- User can now specify how many event tokens should be used

## v1.1.1 - Jun 18, 2022
### Fixed
- Bugfix in stat submission

## v1.1.0 - Jun 17, 2022
### Added
- Will notify the user whether the latest version is running

## v1.0.0 - Jun 17, 2022
### Added
- Initial Release