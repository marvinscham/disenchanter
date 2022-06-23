<p align="center" style="margin-bottom: 0px !important;">
  <img src="https://raw.githubusercontent.com/marvinscham/disenchanter/main/BE_icon.ico" width="120" align="center">
</p>
<h1 align="center">Disenchanter</h1>
<div align="center">
  
![License](https://img.shields.io/github/license/marvinscham/disenchanter)
![Release](https://img.shields.io/github/v/release/marvinscham/disenchanter)
![Downloads](https://img.shields.io/github/downloads/marvinscham/disenchanter/total)
![Last Commit](https://img.shields.io/github/last-commit/marvinscham/disenchanter)

![Stat Submissions](https://img.shields.io/badge/dynamic/json?color=blue&label=stat%20submissions&query=%24%5B%3A1%5D.submissions&url=https%3A%2F%2Fchecksch.de%2Fhook%2Fdisenchanter.php)
![Shards Disenchanted](https://img.shields.io/badge/dynamic/json?color=blue&label=shards%20disenchanted&query=%24%5B%3A1%5D.disenchanted_thousands&url=https%3A%2F%2Fchecksch.de%2Fhook%2Fdisenchanter.php&suffix=K)
![Blue Essence Gained](https://img.shields.io/badge/dynamic/json?color=blue&label=blue%20essence%20gained&query=%24%5B%3A1%5D.blue_essence_millions&url=https%3A%2F%2Fchecksch.de%2Fhook%2Fdisenchanter.php&suffix=M)
![Time Saved](https://img.shields.io/badge/dynamic/json?color=blue&label=time%20saved&query=%24%5B%3A1%5D.hours_saved&url=https%3A%2F%2Fchecksch.de%2Fhook%2Fdisenchanter.php&suffix=%20hours)

Mass disenchant LoL loot like champion shards, event tokens, mythic essence and more

This script is based on [Anujan/disenchant-champ-shards](https://github.com/Anujan/disenchant-champ-shards).

</div>

## Prerequisites

This script is intended for usage on Windows.

To use it, download the pre-built `disenchanter.exe` from the [Latest Release](https://github.com/marvinscham/disenchanter/releases). Note that downloading as well as running this file can cause a false positive alert from your anti-virus. That's because the executable creates a temporary Ruby environment, which can be detected as trojan-like behavior.

Known false positives:

- Trojan:Win32/Wacatac.B!ml

- Trojan:Win32/Sabsik.FL.B!ml

If you'd like to run the Ruby script instead of the pre-built executable you'll need to have [Ruby](https://www.ruby-lang.org/) installed.

## Is this going to get me banned?

No, the script only uses [official Riot APIs](https://developer.riotgames.com/docs/lol#league-client).

The script triggers the same server requests as you would in your League Client. It won't make you sit through the animations, though.

## Usage

Put the `disenchanter.exe` (or `.rb`) file in the same folder as your `LeagueClient.exe`, e.g. `C:\Riot Games\League of Legends` and run it.

The script is interactive and will guide you through the process with simple `[y|n]` questions and mode choices. Before you disenchant or craft anything, you will be asked to confirm your action in a separate color and a `CONFIRM:` banner to prevent accidents.

You need to be logged into your League Client for this to work.

## Features

- Disenchant champion shards by a set of rules:

  - Disenchant all champion shards

  - Keep a shard for champions you don't own yet

  - Keep enough (1/2) shards for champions you own mastery 6/7 tokens for

  - Keep enough (1/2) shards to fully master champions at least at mastery level x (select from 1 to 6)

  - Keep enough (1/2) shards to fully master all champions (only disenchant shards that have no possible use)

  - Manual exceptions

- Combine Key Fragments

- Craft Event Tokens to Blue Essence or Emotes

- Disenchant duplicate Emotes

- Open keyless chests and capsules

- Craft Mythic Essence to Random Skin Shards, Blue Essence or Orange Essence

## Problems, Bugs and Feature Suggestions

Something isn't working properly or you'd like to see a feature that isn't yet supported?

- [Create an issue](https://github.com/marvinscham/disenchanter/issues/new/choose)
- (**If you have no GitHub account**) hit me up at dev[at]marvinscham.de

- Do it yourself and open a pull request.

## Stat Collection

At the end of the script you're asked to contribute your (anonymous) stats to the [Global Stats](https://github.com/marvinscham/disenchanter/wiki/Stats).

This step is **completely optional** and easy to decline but I'd like to encourage you to contribute as it helps me as a dev.

_What info is collected?_

- Number of disenchanted, opened, crafted and redeemed items

- Total actions taken (sum of the above)

- Blue/Orange Essence gained

- Timestamp

This information is generated per script run and saved as a tuple in a database on [my server](https://checksch.de/hook/disenchanter.php).

## Build Executable

If you trust the code but not the pre-built executable, feel free to build it yourself.

I used [Ocra](https://github.com/larsch/ocra) with the config provided in [`build.cmd`](https://github.com/marvinscham/disenchanter/blob/main/build.cmd).
