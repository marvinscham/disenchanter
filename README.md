# Disenchanter

Essence emporium is coming up and you can't be bothered to manually disenchant hundreds of champion shards? Let Disenchanter help you out!

## Prerequisites

This script is intended for usage on Windows.

You'll need to have [Ruby](https://www.ruby-lang.org/) installed to use the script.

## Is this going to get me banned?

No, the script only uses [official Riot APIs](https://developer.riotgames.com/docs/lol#league-client).

## Usage

Put the `disenchanter.rb` file in the same folder as your `LeagueClient.exe`, e.g. `C:\Riot Games\League of Legends`.

Running the script (`ruby disenchanter.rb`) without any options will present you with a help message.

### Options

_Supporting_:

- `-h` | Display a help message
- `-d` | Dry run: show what the chosen option would result in without actually disenchanting
- `-v` | Verbose: Shows more details

_Operational_:

Ordered by aggressiveness top to bottom, choose one

- `-a` | Disenchants ALL champion shards
- `-o` | Keeps shards for champions you don't own
- `-t` | Keeps shards for champions you own mastery tokens for
- `-m LEVEL` | Keeps shards for champions you have at mastery level LEVEL or above
- `-f` | Keeps shards for all champions you don't have at mastery level 7 yet

### Example

I want to see what the script would disenchant if I wanted to keep shards for champions at mastery level 4 or higher:

`ruby disenchanter.rb -d -m 4`

Example output:

```
Logged in as <summoner_name>
Found a total of 12613 loot items
Found 153 champion shards
Found 104 champions at or above specified level threshold of 4
Filtered down to 9 shards that aren't needed for champions above level 4
Disenchanting 2 Kled shards for 2520 BE
Disenchanting 2 Rakan shards for 2520 BE
Disenchanting 1 Rell shards for 1260 BE
Disenchanting 1 Renata Glasc shards for 1260 BE
Disenchanting 2 Taric shards for 540 BE
Disenchanting 1 Yuumi shards for 1260 BE
Dry Run: would disenchant 9 champion shards for a total of 9360 BE.
```

If you're satisfied with the suggested disenchantments, run the script again without the dry run option `-d`.

`ruby disenchanter.rb -m 4`
