# Disenchanter

Essence emporium is coming up and you can't be bothered to manually disenchant hundreds of champion shards? Let Disenchanter help you out!

## Prerequisites

This script is intended for usage on Windows.

You'll need to have [Ruby](https://www.ruby-lang.org/) installed to use the script.

## Is this going to get me banned?

No, the script only uses [official Riot APIs](https://developer.riotgames.com/docs/lol#league-client).

## Usage

Put the `disenchanter.rb` file in the same folder as your `LeagueClient.exe`, e.g. `C:\Riot Games\League of Legends`.

You need to be logged into your League Client for this to work properly.

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
- `-x X,Y,Z` | Excludes champions' shards by name. You need to enter the **exact** spelling; e.g. `Rek'Sai`, champions with whitespace need to be wrapped in quotation marks like `"Renata Glasc"`.

_Extra_:

- `-k` | Combines key fragments to keys
- `-c` | Opens all capsules (keyless chests) before disenchanting champion shards
- `-e [essence|emotes]` | Will forge all event tokens into Random Champion Shards, 100 BE and 10 BE or Random Emote
  - Note: If you'd like to keep certain shards you might want to run this separately from operational options to not accidentally craft, open and instantly disenchant them

## Examples

### TURN IT ALL TO BLUE ESSENCE

Turns tokens into random champion shards, open all keyless capsules and then disenchant all of your champion shards.

```
ruby disenchanter.rb -dcka -e essence
```

### Tokens, Capsules and Key Fragments

This will turn tokens to champion shards, open those and other keyless capsules and also combine key fragments to keys.

```
ruby disenchanter.rb -ck -e essence
```

### Champion Shards by Mastery Threshold

I want to see what the script would disenchant if I wanted to keep shards for champions at mastery level 4 or higher:

```
ruby disenchanter.rb -d -m 4
```

Example output:

```
Logged in as Summoner
Found a total of 128 unique loot items
____________________________________________________________
Found 112 champion shards
Found 74 champions at or above specified level threshold of 4
Filtered down to 7 shards that aren't needed for champions above level 4
____________________________________________________________
Found 1 Irelia shards, total value: 960 BE
Found 2 Olaf shards, total value: 1260 BE
Found 2 Qiyana shards, total value: 2520 BE
Found 1 Rell shards, total value: 1260 BE
Found 1 Renata Glasc shards, total value: 1260 BE
____________________________________________________________
Dry Run: would disenchant 7 champion shards for a total of 7260 BE.
```

Now, I'd like to keep my champion shards for Rell and Renata Glasc despite them not meeting the mastery level cutoff, so I manually exclude them when running the script again.

```
ruby disenchanter.rb -m 4 -x "Renata Glasc",Rell
```
