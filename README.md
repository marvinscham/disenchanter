# Disenchanter

Essence emporium is coming up and you can't be bothered to manually disenchant hundreds of champion shards? Let Disenchanter help you out!

This script is based on a [project by Anujan](https://github.com/Anujan/disenchant-champ-shards).

## Prerequisites

This script is intended for usage on Windows.

To use it, download the pre-built `disenchanter.exe` from the [Latest Release](https://github.com/marvinscham/disenchanter/releases). Note that downloading as well as running this file can cause a false positive alert from your anti-virus.

If you'd like to run the Ruby script instead of the pre-built executable you'll need to have [Ruby](https://www.ruby-lang.org/) installed.

## Is this going to get me banned?

No, the script only uses [official Riot APIs](https://developer.riotgames.com/docs/lol#league-client).

The script triggers the same server requests as you would in your League Client. It won't make you sit through the animations, though.

## Usage

Put the `disenchanter.exe` (or `.rb`) file in the same folder as your `LeagueClient.exe`, e.g. `C:\Riot Games\League of Legends` and run it.

The script is interactive and will guide you through the process with simple `[y|n]` questions and mode choices. Before you disenchant or craft anything, you will be asked to confirm your action in a separate color and a `CONFIRM:` banner to prevent accidents.

You need to be logged into your League Client for this to work.

### Features

- Disenchant champion shards by a set of rules

  - Disenchant all champion shards

  - Keep shards for champions you don't own yet

  - Keep shards for champions you own mastery 6/7 tokens for

  - Keep shards for champions above a specified mastery level

  - Manually add exceptions

- Combine Key Fragments

- Craft Event Tokens to Blue Essence or Emotes

- Open keyless chests and capsules

- Craft Mythic Essence to Random Skin Shards, Blue Essence or Orange Essence

### Feature Suggestions

You'd like to see a feature that isn't yet supported? [Create an issue](https://github.com/marvinscham/disenchanter/issues/new), send a pull request or just hit me up at dev[at]marvinscham.de.

### Stat Collection

At the end of the script you're asked to contribute your (anonymous) stats to the [Global Stats](https://checksch.de/hook/disenchanter.php).

This step is **completely optional** and easy to decline but I'd like to encourage you to contribute as it helps me as a dev.

_What info is collected?_

- Number of disenchanted items

- Number of opened chests

- Number of items crafted

- Number of items redeemed

- Number of actions (sum of the above)

- Blue Essence gained

- Orange Essence gained

- Timestamp

This information is generated per script run and saved as a tuple in a database on my server.

### Build Executable

If you trust the code but not the pre-built executable, feel free to build it yourself.

I used [Ocra](https://github.com/larsch/ocra) with the config provided in [`build.cmd`](https://github.com/marvinscham/disenchanter/blob/main/build.cmd).
