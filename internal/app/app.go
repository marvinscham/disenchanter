package app

import (
	"bufio"
	"bytes"
	"crypto/tls"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"
)

const (
	blueEssence       = "CURRENCY_champion"
	orangeEssence     = "CURRENCY_cosmetic"
	mythicEssence     = "CURRENCY_mythic"
	keyFragment       = "MATERIAL_key_fragment"
	keyRecipe         = "MATERIAL_key_fragment_forge"
	championShard     = "CHAMPION_RENTAL"
	championPermanent = "CHAMPION"
	skinShard         = "SKIN_RENTAL"
	skinPermanent     = "SKIN"
	wardShard         = "WARDSKIN_RENTAL"
	wardPermanent     = "WARDSKIN"
	eternalShard      = "STATSTONE_SHARD"
	eternalPermanent  = "STATSTONE"
	emoteType         = "EMOTE"
	iconType          = "SUMMONERICON"
	tacticianType     = "COMPANION"
	emoteRerollRecipe = "EMOTE_forge"
	randomSkinShard   = "CHEST_291"
	statusOwned       = "ALREADY_OWNED"
)

type Client struct {
	Port    string
	Token   string
	Locale  string
	Version string
	Debug   bool
	DryRun  bool
	Stats   *Stats
	http    *http.Client
}

type Stats struct{ Actions, BlueEssence, OrangeEssence, Disenchanted, Crafted, Redeemed, Opened int }
type Loot map[string]any
type Recipe map[string]any

var reader = bufio.NewReader(os.Stdin)
var translations map[string]string
var locale = "en"

func Run(version string) error {
	if _, err := os.Stat("./build/.build.lockfile"); err == nil {
		fmt.Println(yellow("Detected build environment, skipping execution..."))
		time.Sleep(time.Second)
		return nil
	}
	loadTranslations("en")
	port, token, path, err := grabLockfile()
	if err != nil {
		showErrorAndWait(err)
		return nil
	}
	c := &Client{Port: port, Token: token, Version: version, Locale: grabLocale(path), Stats: &Stats{}, http: insecureClient()}
	loadTranslations(mapLocale(c.Locale))
	fmt.Println(white(t("meta.auto_loaded_locale", "locale_name", t("meta.locale_name"))))
	c.greet()
	if err := c.checkSummoner(); err != nil {
		fmt.Println(red(t("menu.main.summoner_check_failed")))
		fmt.Println(black(err.Error()))
		ask(exitString())
		return nil
	}
	mainMenu(c)
	finish(c.Stats)
	return nil
}

func insecureClient() *http.Client {
	return &http.Client{Transport: &http.Transport{TLSClientConfig: &tls.Config{InsecureSkipVerify: true}}, Timeout: 45 * time.Second}
}

func (c *Client) greet() {
	fmt.Println(green(t("menu.main.hello")))
	fmt.Print(blue(t("menu.main.version_info", "version", c.Version) + " - "))
	checkUpdate(c.Version)
	fmt.Println(separator())
	fmt.Println(blue(t("menu.main.exit_shortcut_notice") + "\n"))
	fmt.Println(blue(t("menu.main.confirm_banner_intro")))
	fmt.Println(magenta(t("common.confirm_banner") + ": " + t("menu.main.confirm_banner_example") + " [y|n]"))
	fmt.Println(separator())
}

func (c *Client) checkSummoner() error {
	s, err := c.Get("lol-summoner/v1/current-summoner")
	if err != nil {
		return err
	}
	name, _ := s["gameName"].(string)
	tag, _ := s["tagLine"].(string)
	if name == "" {
		return errors.New("missing summoner name")
	}
	fmt.Println(blue("\n" + t("menu.main.logged_in_as", "name", name, "tagline", tag)))
	fmt.Println(separator())
	return nil
}

func (c *Client) host() string { return "https://127.0.0.1:" + c.Port }

func (c *Client) Get(path string) (map[string]any, error) {
	var out map[string]any
	err := c.request(http.MethodGet, path, nil, &out)
	return out, err
}

func (c *Client) GetArray(path string) ([]Loot, error) {
	var raw []map[string]any
	err := c.request(http.MethodGet, path, nil, &raw)
	items := make([]Loot, len(raw))
	for i := range raw {
		items[i] = Loot(raw[i])
	}
	return items, err
}

func (c *Client) GetAny(path string) (any, error) {
	var out any
	err := c.request(http.MethodGet, path, nil, &out)
	return out, err
}

func (c *Client) GetRecipes(lootID string) ([]Recipe, error) {
	var raw []map[string]any
	err := c.request(http.MethodGet, "lol-loot/v1/recipes/initial-item/"+lootID, nil, &raw)
	items := make([]Recipe, len(raw))
	for i := range raw {
		items[i] = Recipe(raw[i])
	}
	return items, err
}

func (c *Client) request(method, path string, body io.Reader, out any) error {
	url := c.host() + "/" + path
	req, err := http.NewRequest(method, url, body)
	if err != nil {
		return err
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Basic "+strings.TrimSpace(c.Token))
	res, err := c.http.Do(req)
	if err != nil {
		return err
	}
	defer res.Body.Close()
	if res.StatusCode >= 400 {
		return fmt.Errorf("%s returned %s", path, res.Status)
	}
	if out == nil {
		io.Copy(io.Discard, res.Body)
		return nil
	}
	return json.NewDecoder(res.Body).Decode(out)
}

func (c *Client) PostRecipe(recipe string, lootIDs any, repeat int) map[string]any {
	c.Stats.Actions += repeat
	if c.Debug {
		fmt.Println(black("POST: " + c.host() + "/lol-loot/v1/recipes/" + recipe + "/craft?repeat=" + strconv.Itoa(repeat)))
	}
	if c.DryRun {
		fmt.Println(red("DRY RUN: did nothing."))
		return nil
	}
	ids := []string{}
	switch v := lootIDs.(type) {
	case string:
		ids = []string{v}
	case []string:
		ids = v
	}
	body, _ := json.Marshal(ids)
	var out map[string]any
	if err := c.request(http.MethodPost, "lol-loot/v1/recipes/"+recipe+"/craft?repeat="+strconv.Itoa(repeat), bytes.NewReader(body), &out); err != nil {
		fmt.Println(yellow(err.Error()))
		fmt.Println(red(t("handler.exception.network_error", "email", "dev@marvinscham.de")))
		return nil
	}
	if c.Debug && out != nil {
		b, _ := json.Marshal(out)
		os.WriteFile("disenchanter_post.json", b, 0644)
	}
	return out
}

func (c *Client) RefreshLoot() {
	_ = c.request(http.MethodPost, "lol-loot/v1/refresh?force=true", strings.NewReader(""), nil)
}

func mainMenu(c *Client) {
	items := map[string]string{"1": t("loot.soft"), "2": t("loot.hard"), "3": t("loot.detailed"), "l": t("menu.main.options.language_settings"), "m": t("menu.main.options.open_mastery_chart"), "s": t("menu.main.options.open_usage_stats"), "r": t("menu.main.options.open_repository"), "d": "Debug Tools", "x": t("menu.main.options.exit")}
	runMenu(c, t("menu.what_to_do"), items, func(choice string) bool {
		switch choice {
		case "1":
			handleMass(c, 1)
			return true
		case "2":
			handleMass(c, 2)
			return true
		case "3":
			detailMenu(c)
		case "l":
			languageMenu(c)
			c.greet()
		case "m":
			openMasteryChart(c)
		case "s":
			openURL("https://github.com/marvinscham/disenchanter/wiki/Stats", t("handler.url.opening_stats", "url", "https://github.com/marvinscham/disenchanter/wiki/Stats"))
		case "r":
			openURL("https://github.com/marvinscham/disenchanter/", t("handler.url.opening_repository", "url", "https://github.com/marvinscham/disenchanter/"))
		case "d":
			debugMenu(c)
		case "x":
			return true
		default:
			return false
		}
		c.RefreshLoot()
		return false
	})
}

func detailMenu(c *Client) {
	items := map[string]string{"1": t("loot.materials"), "2": t("loot.champions"), "3": t("loot.skins"), "4": t("loot.tacticians"), "5": t("loot.eternals"), "6": t("loot.emotes"), "7": t("loot.ward_skins"), "8": t("loot.icons"), "x": t("menu.back_to_main")}
	runMenu(c, t("menu.detail.what_to_do"), items, func(choice string) bool {
		switch choice {
		case "1":
			materialsMenu(c)
		case "2":
			handleChampions(c, 0)
		case "3":
			handleSkins(c, 0)
		case "4":
			handleGeneric(c, t("loot.tacticians"), tacticianType, 0)
		case "5":
			handleEternals(c, 0)
		case "6":
			handleEmotes(c, 0)
		case "7":
			handleWards(c, 0)
		case "8":
			handleGeneric(c, t("loot.icons"), iconType, 0)
		case "x":
			return true
		default:
			return false
		}
		c.RefreshLoot()
		return false
	})
}

func materialsMenu(c *Client) {
	items := map[string]string{"1": t("menu.materials.options.mythic_essence"), "2": t("menu.materials.options.key_fragments"), "3": t("menu.materials.options.capsules"), "x": t("menu.back_to_detail")}
	runMenu(c, t("menu.what_to_do"), items, func(choice string) bool {
		switch choice {
		case "1":
			handleMythic(c)
		case "2":
			handleKeyFragments(c, 0)
		case "3":
			handleCapsules(c, 0)
		case "x":
			return true
		default:
			return false
		}
		return false
	})
}

func runMenu(c *Client, text string, items map[string]string, handle func(string) bool) {
	done := map[string]bool{}
	for {
		choice := inputCheck("\n"+cyan(text)+"\n\n"+todoString(items, done), keys(items), t("menu.option"), map[bool]string{true: "dry", false: "default"}[c.DryRun])
		done[choice] = true
		fmt.Println(separator() + "\n\n" + white(t("menu.option_chosen")+": "+items[choice]))
		if handle(choice) || choice == "x" {
			fmt.Println(separator())
			return
		}
		fmt.Println(separator())
	}
}

func handleMass(c *Client, accept int) {
	if accept == 1 && isNo(inputCheck(t("menu.mass.ask_run_soft"), ansYN(), "[y|n]", "confirm")) {
		return
	}
	if accept == 2 && inputCheck(t("menu.mass.ask_run_hard"), []string{"YES", "n"}, "[YES|n]", "confirm") == "n" {
		return
	}
	handleKeyFragments(c, accept)
	handleCapsules(c, accept)
	handleChampions(c, accept)
	handleSkins(c, accept)
	handleGeneric(c, t("loot.tacticians"), tacticianType, accept)
	handleEternals(c, accept)
	handleEmotes(c, accept)
	handleWards(c, accept)
	handleGeneric(c, t("loot.icons"), iconType, accept)
	fmt.Println(green(t("menu.mass.all_steps_success")))
}

func handleKeyFragments(c *Client, accept int) {
	loot, err := c.GetArray("lol-loot/v1/player-loot")
	if report(err, "key fragments") {
		return
	}
	fragments := count(filterLoot(loot, func(l Loot) bool { return str(l, "lootId") == keyFragment }))
	keys := fragments / 3
	if fragments < 3 {
		fmt.Println(yellow(t("handler.key_fragments.not_enough_fragments")))
		return
	}
	fmt.Println(blue(t("handler.key_fragments.found_fragments", "count", fragments)))
	if accept >= 1 || isYes(inputCheck(t("handler.key_fragments.ask_craft_keys", "key_count", keys, "fragment_count", fragments), ansYN(), "[y|n]", "confirm")) {
		c.Stats.Crafted += keys
		c.PostRecipe(keyRecipe, keyFragment, keys)
		fmt.Println(green(t("common.done")))
	}
}

func handleCapsules(c *Client, accept int) {
	loot, err := c.GetArray("lol-loot/v1/player-loot")
	if report(err, "capsules") {
		return
	}
	caps := filterLoot(loot, func(l Loot) bool { return strings.HasPrefix(str(l, "lootName"), "CHEST_") })
	keyless := []Loot{}
	for _, cap := range caps {
		recipes, err := c.GetRecipes(str(cap, "lootId"))
		if err == nil && len(recipes) > 0 && len(arr(recipes[0], "slots")) <= 1 && str(recipes[0], "type") == "OPEN" {
			keyless = append(keyless, cap)
		}
	}
	if count(keyless) == 0 {
		fmt.Println(yellow(t("handler.capsule.no_capsules_found")))
		return
	}
	fmt.Println(blue(t("handler.capsule.found_capsules", "count", count(keyless))))
	for _, cap := range keyless {
		fmt.Println(black(strconv.Itoa(num(cap, "count"))+"x ") + white(chestName(c, str(cap, "lootId"))))
	}
	if accept >= 1 || isYes(inputCheck(t("handler.capsule.ask_open_capsules", "count", count(keyless)), ansYN(), "[y|n]", "confirm")) {
		parallel(keyless, func(l Loot) {
			res := c.PostRecipe(str(l, "lootId")+"_OPEN", str(l, "lootId"), num(l, "count"))
			trackAdded(c, res)
		})
		c.Stats.Opened += count(keyless)
		fmt.Println(green(t("common.done")))
	}
}

func handleChampions(c *Client, accept int) {
	loot, err := c.GetArray("lol-loot/v1/player-loot")
	if report(err, "champions") {
		return
	}
	shards := filterLoot(loot, func(l Loot) bool { return str(l, "type") == championShard })
	perms := filterLoot(loot, func(l Loot) bool { return str(l, "type") == championPermanent })
	if accept >= 1 || (count(perms) > 0 && isYes(inputCheck(t("handler.champion.ask_include_permanents"), ansYN(), "[y|n]", "default"))) {
		shards = append(shards, perms...)
	}
	if count(shards) == 0 {
		fmt.Println(yellow(t("handler.champion.no_shards_found")))
		return
	}
	fmt.Println(blue(t("handler.champion.found_shards", "count", count(shards))))
	for _, s := range shards {
		s["count_keep"] = 0
		s["disenchant_note"] = ""
	}
	if accept != 2 {
		unowned := filterLoot(shards, func(l Loot) bool { return str(l, "redeemableStatus") != statusOwned })
		if len(unowned) == 0 {
			fmt.Println(blue(t("handler.champion.no_unowned_champs_found")))
		} else if accept == 1 || isYes(inputCheck(t("handler.champion.ask_keep_unowned_champs"), ansYN(), "[y|n]", "default")) {
			for _, s := range shards {
				if str(s, "redeemableStatus") != statusOwned {
					s["count"] = num(s, "count") - 1
					s["count_keep"] = num(s, "count_keep") + 1
				}
			}
		}
	}
	if accept < 1 {
		choice := inputCheck(cyan(t("menu.choose_option"))+"\n\n"+todoString(map[string]string{"1": t("menu.champions.options.all"), "2": t("menu.champions.options.collector"), "x": t("menu.back_to_detail")}, map[string]bool{}), []string{"1", "2", "x"}, t("menu.option"), "default")
		if choice == "x" {
			return
		}
		if choice == "2" {
			for _, s := range shards {
				s["count"] = num(s, "count") - 1
				s["count_keep"] = num(s, "count_keep") + 1
			}
		}
	}
	shards = filterLoot(shards, func(l Loot) bool { return num(l, "count") > 0 })
	if count(shards) == 0 {
		fmt.Println(green(t("handler.champion.already_done")))
		return
	}
	presentChampions(shards, accept)
	if accept < 1 {
		shards = championExclusions(shards)
		if count(shards) == 0 {
			return
		}
	}
	total := 0
	for _, s := range shards {
		total += num(s, "disenchantValue") * num(s, "count")
	}
	if accept >= 1 || isYes(inputCheck(t("handler.champion.ask_disenchant", "count", count(shards), "amount", total), ansYN(), "[y|n]", "confirm")) {
		c.Stats.BlueEssence += total
		c.Stats.Disenchanted += count(shards)
		parallel(shards, func(l Loot) { c.PostRecipe(str(l, "disenchantRecipeName"), str(l, "lootId"), num(l, "count")) })
	}
	fmt.Println(green(t("common.done")))
}

func handleSkins(c *Client, accept int) {
	handleGeneric(c, t("loot.skin_shards"), skinShard, accept)
	handleGeneric(c, t("loot.skin_permanents"), skinPermanent, accept)
}
func handleEternals(c *Client, accept int) {
	handleGeneric(c, t("loot.eternal_shards"), eternalShard, accept)
	handleGeneric(c, t("loot.eternal_permanents"), eternalPermanent, accept)
}
func handleWards(c *Client, accept int) {
	handleGeneric(c, "Ward Skin Shards", wardShard, accept)
	handleGeneric(c, "Ward Skin Permanents", wardPermanent, accept)
}

func handleEmotes(c *Client, accept int) {
	handleGeneric(c, t("loot.emotes"), emoteType, accept)
	c.RefreshLoot()
	if handleEsportsEmotes(c, accept) {
		handleGeneric(c, t("loot.emotes"), emoteType, accept)
	}
}

func handleGeneric(c *Client, name, typ string, accept int) {
	loot, err := c.GetArray("lol-loot/v1/player-loot")
	if report(err, name) {
		return
	}
	items := filterLoot(loot, func(l Loot) bool { return str(l, "type") == typ && str(l, "disenchantLootName") != "" })
	if count(items) == 0 {
		fmt.Println(yellow(t("handler.generic.found_nothing", "name", name)))
		return
	}
	fmt.Println(blue(t("handler.generic.found_some", "count", count(items), "name", name)))
	items = handleGenericOwned(items, name, accept)
	if items == nil {
		return
	}
	if count(items) == 0 {
		fmt.Println(yellow(t("handler.generic.found_no_owned", "name", name)))
		return
	}
	totBE, totOE := totals(items)
	info := genericInfo(items, name, totBE, totOE)
	if accept >= 1 || isYes(inputCheck(t("handler.generic.ask_disenchant", "count", count(items), "loot", name, "currency", info), ansYN(), "[y|n]", "confirm")) {
		c.Stats.Disenchanted += count(items)
		c.Stats.BlueEssence += totBE
		c.Stats.OrangeEssence += totOE
		parallel(items, func(l Loot) { c.PostRecipe(str(l, "disenchantRecipeName"), str(l, "lootId"), num(l, "count")) })
		fmt.Println(green(t("common.done")))
	}
}

func handleGenericOwned(items []Loot, name string, accept int) []Loot {
	contains := false
	for _, l := range items {
		if str(l, "redeemableStatus") != statusOwned {
			contains = true
		}
	}
	if !contains {
		return items
	}
	choice := ""
	if accept == 2 {
		choice = "n"
	} else if accept == 1 {
		choice = "y"
	} else {
		choice = inputCheck(cyan(t("handler.generic.keep_unowned", "loot", name)+"\n")+white("[y] ")+cyan(t("common.yup")+"\n")+white("[n] ")+cyan(t("common.nah")+"\n")+white("[x] ")+cyan(t("menu.back_to_main")+"\n"+t("menu.option")+" "), []string{"y", "n", "x"}, "[y|n|x]", "raw")
	}
	if choice == "x" {
		fmt.Println(yellow(t("handler.generic.action_cancelled")))
		return nil
	}
	if choice == "y" {
		out := filterLoot(items, func(l Loot) bool { return str(l, "redeemableStatus") == statusOwned })
		fmt.Println(blue(t("handler.generic.filtered_down", "count", count(out))))
		return out
	}
	return items
}

func handleEsportsEmotes(c *Client, accept int) bool {
	loot, err := c.GetArray("lol-loot/v1/player-loot")
	if report(err, "esports emotes") {
		return false
	}
	items := filterLoot(loot, func(l Loot) bool {
		return str(l, "type") == emoteType && str(l, "disenchantLootName") == "" && str(l, "redeemableStatus") == statusOwned
	})
	if count(items) == 0 {
		fmt.Println(yellow(t("handler.esports_emotes.none_found")))
		return false
	}
	fmt.Println(t("handler.esports_emotes.found_some", "count", count(items)))
	if accept >= 1 || isYes(inputCheck(t("handler.esports_emotes.ask_re_roll", "count", count(items)), ansYN(), "[y|n]", "confirm")) {
		c.Stats.Crafted += count(items)
		parallel(items, func(l Loot) { c.PostRecipe(emoteRerollRecipe, str(l, "lootId"), num(l, "count")) })
		fmt.Println(green(t("common.done")))
		c.RefreshLoot()
		return true
	}
	return false
}

func handleMythic(c *Client) {
	loot, err := c.GetArray("lol-loot/v1/player-loot")
	if report(err, "mythic essence") {
		return
	}
	var essence Loot
	for _, l := range loot {
		if str(l, "lootId") == mythicEssence {
			essence = l
		}
	}
	if essence == nil || num(essence, "count") == 0 {
		fmt.Println(yellow(t("handler.mythic_essence.none_found")))
		return
	}
	fmt.Println(blue(t("handler.mythic_essence.found_some", "amount", num(essence, "count"))))
	choices := map[string]string{"1": t("menu.mythic.options.blue_essence"), "2": t("menu.mythic.options.orange_essence"), "3": t("menu.mythic.options.random_skin_shards"), "x": t("menu.back_to_detail")}
	choice := inputCheck(cyan(t("menu.what_to_do"))+"\n\n"+todoString(choices, map[string]bool{}), keys(choices), t("menu.option"), "default")
	if choice == "x" {
		return
	}
	target := map[string]string{"1": blueEssence, "2": orangeEssence, "3": randomSkinShard}[choice]
	recipes, err := c.GetRecipes(mythicEssence)
	if report(err, "mythic essence") {
		return
	}
	var recipe Recipe
	for _, r := range recipes {
		outs := arr(r, "outputs")
		if len(outs) > 0 && str(Loot(outs[0]), "lootName") == target {
			recipe = r
		}
	}
	if recipe == nil {
		fmt.Println(yellow(t("menu.mythic.recipes_unavailable", "loot", choices[choice])))
		return
	}
	cost := num(Loot(arr(recipe, "slots")[0]), "quantity")
	outQty := num(Loot(arr(recipe, "outputs")[0]), "quantity")
	fmt.Println(blue(t("menu.mythic.recipe_found", "thing_to_craft", str(recipe, "contextMenuText"), "amount", cost)))
	amountStr := inputCheck(t("handler.mythic_essence.amount_to_use", "target_name", choices[choice]), rangeAnswers(num(essence, "count")), "[1.."+strconv.Itoa(num(essence, "count"))+"|all|x]", "default")
	if amountStr == "x" {
		fmt.Println(yellow(t("handler.mythic_essence.cancelled")))
		return
	}
	amount := num(essence, "count")
	if amountStr != "all" {
		amount, _ = strconv.Atoi(amountStr)
	}
	repeat := amount / cost
	if repeat == 0 {
		fmt.Println(yellow(t("handler.mythic_essence.not_enough")))
		return
	}
	qty := repeat * outQty
	price := repeat * cost
	if isYes(inputCheck(t("handler.mythic_essence.craft_confirm", "quantity", qty, "loot_name", choices[choice], "total_cost", price), ansYN(), "[y|n]", "confirm")) {
		if target == blueEssence {
			c.Stats.BlueEssence += qty
		} else if target == orangeEssence {
			c.Stats.OrangeEssence += qty
		}
		c.Stats.Crafted += repeat
		c.PostRecipe(str(recipe, "recipeName"), mythicEssence, repeat)
		fmt.Println(green(t("common.done")))
	}
}

func finish(s *Stats) {
	fmt.Println(green(t("menu.main.all_done")))
	if s.Actions > 0 {
		fmt.Println(green(t("menu.main.time_saved", "time_saved", s.Actions*3)))
		fmt.Println(separator())
	}
	handleStatSubmission(s)
	fmt.Println(green(t("menu.main.see_you")))
	ask(exitString())
}
