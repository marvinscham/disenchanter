# Changelog

All notable changes to this project will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/). Also see the [versioning strategy](./VERSIONING.md).

## v1.6.0 - next
### Added
- #57 Rerolling owned esports emotes that cannot be disenchanted
- #19 Tacticians can now be disenchanted
- #27 Proper changelog and versioning files
### Changed
- (dev) Code is split in modules now instead of stuffed into a single script
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