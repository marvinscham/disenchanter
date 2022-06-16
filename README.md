# Disenchanter

Essence emporium is coming up and you can't be bothered to manually disenchant hundreds of champion shards? Let Disenchanter help you out!

## Prerequisites

This script is intended for usage on Windows.

You'll need to have [Ruby](https://www.ruby-lang.org/) installed to use the script.

## Is this going to get me banned?

No, the script only uses [official Riot APIs](https://developer.riotgames.com/docs/lol#league-client).

The script triggers the same server requests as you would in your League Client. It won't make you sit through the animations, though.

## Usage

Put the `disenchanter.rb` file in the same folder as your `LeagueClient.exe`, e.g. `C:\Riot Games\League of Legends`.

You need to be logged into your League Client for this to work.

The script is interactive and will guide you through the process with simple yes/no questions and mode choices.

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

### Feature Suggestions

You'd like to see a feature that isn't yet supported? [Create an issue](https://github.com/marvinscham/disenchanter/issues/new), send a pull request or just hit me up at dev[at]marvinscham.de.
