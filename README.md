<p align="center" style="margin-bottom: 0px !important;">
  <img src="./assets/BE_icon.ico" width="120" align="center">
</p>
<h1 align="center">Disenchanter</h1>
<div align="center">

![Patch](https://img.shields.io/badge/league%20patch-14.6-brightgreen)
![Release](https://img.shields.io/github/v/release/marvinscham/disenchanter)
![Last Commit](https://img.shields.io/github/last-commit/marvinscham/disenchanter)

![Language](https://img.shields.io/badge/language-Ruby-%23701516)
![License](https://img.shields.io/github/license/marvinscham/disenchanter)
![Downloads](https://img.shields.io/github/downloads/marvinscham/disenchanter/total)
[![Translated](https://weblate.ms-ds.org/widget/disenchanter/disenchanter/svg-badge.svg)](https://weblate.ms-ds.org/engage/disenchanter/)

![Stat Submissions](https://img.shields.io/badge/dynamic/json?color=blue&label=stat%20submissions&query=%24%5B%3A1%5D.submissions&url=https%3A%2F%2Fchecksch.de%2Fhook%2Fdisenchanter.php)
![Shards Disenchanted](https://img.shields.io/badge/dynamic/json?color=blue&label=shards%20disenchanted&query=%24%5B%3A1%5D.disenchanted_thousands&url=https%3A%2F%2Fchecksch.de%2Fhook%2Fdisenchanter.php&suffix=K)
![Blue Essence Gained](https://img.shields.io/badge/dynamic/json?color=blue&label=blue%20essence%20gained&query=%24%5B%3A1%5D.blue_essence_millions&url=https%3A%2F%2Fchecksch.de%2Fhook%2Fdisenchanter.php&suffix=M)
![Time Saved](https://img.shields.io/badge/dynamic/json?color=blue&label=time%20saved&query=%24%5B%3A1%5D.hours_saved&url=https%3A%2F%2Fchecksch.de%2Fhook%2Fdisenchanter.php&suffix=%20hours)

Mass disenchant LoL loot like champion shards, eternals, mythic essence and more!

[<img src="./assets/kofi-button.png" width="200" align="center">](https://ko-fi.com/marvinscham)

Based on [Anujan/disenchant-champ-shards](https://github.com/Anujan/disenchant-champ-shards).

可以在[這裡](https://github.com/nico12313/disenchanter/tree/Traditional-Chinese-Translation)找到繁體中文版本的應用程式.

</div>

## Usage

Download the pre-built `disenchanter.exe` from the [Latest Release](https://github.com/marvinscham/disenchanter/releases).

Start your League Client **without admin privileges** and log into your account, then start the script.

### Details

The script is interactive and will guide you through the process with simple `[y|n]` questions and mode options. Before you disenchant or craft anything, you will be asked to confirm the action in a magenta colored message with a big `CONFIRM:` banner so don't be scared to explore the different options!

Once you're finished, you can _optionally_ contribute your (anonymous) stats to the [Global Stats](https://github.com/marvinscham/disenchanter/wiki/Stats). ([Details](https://github.com/marvinscham/disenchanter/wiki/Stat-Collection))

![Demo](./assets/disenchanter.png)

## Is this a virus?

TL;DR: No, but you will probably get a trojan alert. ([Details](https://github.com/marvinscham/disenchanter/wiki/Is-this-a-virus%3F))

## Is this going to get me banned?

No, the script only uses [official Riot APIs](https://developer.riotgames.com/docs/lol#league-client).

The script triggers the same server requests as you would in your League Client. It won't make you sit through any animations, though.

## Features


- Materials
  - Craft Mythic Essence to Skins or Blue/Orange Essence
  - Combine Key Fragments
  - Open keyless capsules
  - Upgrade Mastery Tokens efficiently
- Champion Shards
  - Disenchant all
  - Keep one for champions you don't own yet
  - Keep enough (1/2) for champions you own mastery 6/7 tokens for
  - Keep enough (1/2) to fully master champions at least at mastery level x (select from 1 to 6)
  - Keep enough (1/2) to fully master all champions (only disenchant shards that have no possible use)
  - Keep one of each champion regardless of mastery
  - Manual exceptions
- Disenchant various items
  - Eternals
  - Emotes
  - Ward Skins
  - Summoner Icons
  - Tacticians

## Problems, Bugs and Feature Suggestions

Something isn't working properly or you'd like to see a feature that isn't yet supported?

- [Create an issue](https://github.com/marvinscham/disenchanter/issues/new/choose)
- (**If you have no GitHub account**) hit me up at dev[at]marvinscham.de
- Open a pull request with your contribution.

## Translation

You can help to make Disenchanter available in your language! More info [here!](https://weblate.ms-ds.org/engage/disenchanter/)

[![](https://weblate.ms-ds.org/widget/disenchanter/disenchanter/multi-auto.svg)](https://weblate.ms-ds.org/engage/disenchanter/)


## ❤ Sponsors ❤

- Ze Interrupter
- tsunamihorseracing

## Disclaimer

_Disenchanter isn't endorsed by Riot Games and doesn't reflect the views or opinions of Riot Games or anyone officially involved in producing or managing Riot Games properties. Riot Games, and all associated properties are trademarks or registered trademarks of Riot Games, Inc._
