package app

import (
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"os/exec"
	"runtime"
	"sort"
	"strconv"
	"strings"
	"sync"
)

func ask(q string) string {
	fmt.Print(q)
	s, _ := reader.ReadString('\n')
	return strings.TrimRight(s, "\r\n")
}
func inputCheck(q string, answers []string, display, preset string) string {
	question := q
	switch preset {
	case "confirm":
		question = magenta(t("common.confirm_banner")+": "+q+" ") + white(display) + magenta(": ")
	case "dry":
		question += red(" " + display + " (DRY RUN): ")
	case "raw":
		question += white(display + ": ")
	default:
		question += white(" " + display + ": ")
	}
	for {
		in := ask(question)
		for _, a := range answers {
			if in == a {
				return in
			}
		}
		fmt.Println(red(t("common.invalid_answer")+": ") + white(display))
	}
}

func ansYN() []string     { return []string{"y", "yes", "n", "no"} }
func isYes(s string) bool { return s == "y" || s == "yes" }
func isNo(s string) bool  { return s == "n" || s == "no" }
func exitString() string  { return cyan(t("common.press_enter_to_exit")) }
func separator() string   { return black("____________________________________________________________") }
func translationURL() string {
	return "https://github.com/marvinscham/disenchanter/blob/main/CONTRIBUTING.md"
}

func keys(m map[string]string) []string {
	out := make([]string, 0, len(m))
	for k := range m {
		out = append(out, k)
	}
	sort.Slice(out, func(i, j int) bool {
		if out[i] == "x" || out[j] == "x" {
			return out[j] == "x"
		}
		return out[i] < out[j]
	})
	return out
}
func todoString(items map[string]string, done map[string]bool) string {
	out := ""
	for _, k := range keys(items) {
		out += white("[" + k + "] ")
		if done[k] {
			out += green(items[k] + " (" + t("menu.option_done") + ")\n")
		} else {
			out += cyan(items[k] + "\n")
		}
	}
	return out
}
func rangeAnswers(n int) []string {
	out := []string{"all", "x"}
	for i := 1; i <= n; i++ {
		out = append(out, strconv.Itoa(i))
	}
	return out
}

func str(m map[string]any, k string) string {
	if v, ok := m[k].(string); ok {
		return v
	}
	return fmt.Sprint(m[k])
}
func num(m map[string]any, k string) int {
	switch v := m[k].(type) {
	case int:
		return v
	case int64:
		return int(v)
	case float64:
		return int(v)
	case json.Number:
		i, _ := v.Int64()
		return int(i)
	case string:
		i, _ := strconv.Atoi(v)
		return i
	}
	return 0
}
func arr(m map[string]any, k string) []map[string]any {
	raw, _ := m[k].([]any)
	out := []map[string]any{}
	for _, v := range raw {
		if mm, ok := v.(map[string]any); ok {
			out = append(out, mm)
		}
	}
	return out
}
func count(items []Loot) int {
	c := 0
	for _, l := range items {
		c += num(l, "count")
	}
	return c
}
func filterLoot(in []Loot, pred func(Loot) bool) []Loot {
	out := []Loot{}
	for _, l := range in {
		if pred(l) {
			out = append(out, l)
		}
	}
	return out
}
func totals(items []Loot) (int, int) {
	be, oe := 0, 0
	for _, l := range items {
		v := num(l, "disenchantValue") * num(l, "count")
		if str(l, "disenchantLootName") == blueEssence {
			be += v
		}
		if str(l, "disenchantLootName") == orangeEssence {
			oe += v
		}
	}
	return be, oe
}
func parallel(items []Loot, fn func(Loot)) {
	var wg sync.WaitGroup
	for _, item := range items {
		wg.Add(1)
		go func(l Loot) { defer wg.Done(); fn(l) }(item)
	}
	wg.Wait()
}
func report(err error, name string) bool {
	if err == nil {
		return false
	}
	fmt.Println(red(t("handler.exception.error_occurred", "name", name)))
	fmt.Println(black(err.Error()))
	fmt.Println(yellow(t("handler.exception.skipping_step")))
	return true
}

func genericInfo(items []Loot, name string, be, oe int) string {
	sort.Slice(items, func(i, j int) bool {
		return str(items[i], "redeemableStatus")+str(items[i], "itemDesc") < str(items[j], "redeemableStatus")+str(items[j], "itemDesc")
	})
	fmt.Println(blue(t("handler.generic.disenchant_preview", "count", count(items), "loot", name)))
	for _, l := range items {
		lootName := str(l, "itemDesc")
		if lootName == "" {
			lootName = str(l, "localizedName")
		}
		currency := t("loot.orange_essence_short")
		if str(l, "disenchantLootName") == blueEssence {
			currency = t("loot.blue_essence_short")
		}
		line := black(fmt.Sprintf("%-5s", strconv.Itoa(num(l, "count"))+"x ")) + white(fmt.Sprintf("%-40s", lootName)) + black(" @ "+fmt.Sprintf("%-8s", strconv.Itoa(num(l, "disenchantValue")*num(l, "count"))+" "+currency))
		if str(l, "redeemableStatus") != statusOwned {
			line += yellow(" (" + t("common.not_owned") + ")")
		}
		fmt.Println(line)
	}
	parts := []string{}
	if oe > 0 {
		parts = append(parts, strconv.Itoa(oe)+" "+t("loot.orange_essence"))
	}
	if be > 0 {
		parts = append(parts, strconv.Itoa(be)+" "+t("loot.blue_essence"))
	}
	return strings.Join(parts, " and ")
}

func presentChampions(items []Loot, accept int) {
	fmt.Println(blue(t("handler.champion.present_selection", "count", count(items))))
	for _, l := range items {
		line := black(fmt.Sprintf("%-5s", strconv.Itoa(num(l, "count"))+"x ")) + white(fmt.Sprintf("%-15s", str(l, "itemDesc"))) + black(" @ "+fmt.Sprintf("%-8s", strconv.Itoa(num(l, "disenchantValue")*num(l, "count"))+" "+t("loot.blue_essence_short")))
		if accept != 2 && num(l, "count_keep") > 0 {
			line += green(" " + t("handler.champion.shards_to_keep", "count", num(l, "count_keep")))
		}
		fmt.Println(line)
	}
}
func championExclusions(items []Loot) []Loot {
	excluded := map[string]bool{}
	for isYes(inputCheck(t("handler.champion.exclusions.ask"), ansYN(), "[y|n]", "default")) {
		raw := ask(cyan(t("handler.champion.exclusions.ask_which")+" ") + white(t("handler.champion.exclusions.entry_requirements")) + cyan(": "))
		for _, x := range strings.Split(raw, ",") {
			excluded[strings.TrimSpace(x)] = true
		}
		fmt.Print(green(t("handler.champion.exclusions.recognized") + " "))
		for _, l := range items {
			if excluded[str(l, "itemDesc")] {
				fmt.Print(white(str(l, "itemDesc") + " "))
			}
		}
		fmt.Println()
	}
	return filterLoot(items, func(l Loot) bool { return !excluded[str(l, "itemDesc")] })
}

func chestName(c *Client, lootID string) string {
	info, err := c.Get("lol-loot/v1/player-loot/" + lootID)
	if err == nil && str(info, "localizedName") != "" {
		return str(info, "localizedName")
	}
	catalog := map[string]string{"CHEST_128": t("loot.champion_capsule"), "CHEST_129": t("loot.glorious_champion_capsule"), "CHEST_209": t("loot.honor_3_orb"), "CHEST_210": t("loot.honor_4_orb"), "CHEST_211": t("loot.honor_5_orb")}
	if v := catalog[lootID]; v != "" {
		return v
	}
	return lootID
}
func trackAdded(c *Client, res map[string]any) {
	for _, add := range arr(res, "added") {
		pl, _ := add["playerLoot"].(map[string]any)
		if str(pl, "lootId") == blueEssence {
			c.Stats.BlueEssence += num(add, "deltaCount")
		}
		if str(pl, "lootId") == orangeEssence {
			c.Stats.OrangeEssence += num(add, "deltaCount")
		}
	}
}

func handleStatSubmission(s *Stats) {
	if s.Actions == 0 {
		return
	}
	if isYes(inputCheck(cyan(t("handler.stat_submission.ask_contribute")+"\n")+gatherStats(s)+t("handler.stat_submission.ask_submit"), ansYN(), "[y|n]", "raw")) {
		body, _ := json.Marshal(map[string]int{"a": s.Actions, "d": s.Disenchanted, "o": s.Opened, "c": s.Crafted, "r": s.Redeemed, "be": s.BlueEssence, "oe": s.OrangeEssence})
		http.Post("https://checksch.de/hook/disenchanter.php", "application/json", strings.NewReader(string(body)))
		fmt.Println(green(t("handler.stat_submission.thanks")))
	}
}
func gatherStats(s *Stats) string {
	stats := [][2]string{{t("common.actions"), strconv.Itoa(s.Actions)}, {t("common.disenchanted"), strconv.Itoa(s.Disenchanted)}, {t("common.opened"), strconv.Itoa(s.Opened)}, {t("common.crafted"), strconv.Itoa(s.Crafted)}, {t("common.redeemed"), strconv.Itoa(s.Redeemed)}, {t("loot.blue_essence"), strconv.Itoa(s.BlueEssence)}, {t("loot.orange_essence"), strconv.Itoa(s.OrangeEssence)}}
	out := blue("Your stats:\n")
	for _, st := range stats {
		out += fmt.Sprintf("%-15s%-7s\n", st[0], st[1])
	}
	return out
}

func languageMenu(c *Client) bool {
	choices := map[string]string{"en": "English", "de": "Deutsch", "pl": "Polski", "zh": "繁體中文", "eo": "Esperanto", "x": t("menu.back_to_main")}
	choice := inputCheck(cyan(t("menu.language.preferred"))+"\n\n"+todoString(choices, map[string]bool{}), keys(choices), t("menu.option"), "default")
	if choice == "x" {
		return false
	}
	m := map[string]string{"de": "de_DE", "pl": "pl_PL", "zh": "zh_TW", "eo": "eo", "en": "en"}
	loadTranslations(m[choice])
	fmt.Println(t("meta.manually_set_locale", "locale_name", t("meta.locale_name")))
	return true
}

func debugMenu(c *Client) {
	choices := map[string]string{"1": "Write player_loot to file", "2": "Write recipes of lootId to file", "3": "Write loot_info of lootId to file", "4": "Write summoner info to file", "5": "Write settings to file", "d": "Toggle dry run", "m": "Toggle debug mode", "t": "Request terminal", "x": t("menu.back_to_main")}
	runMenu(c, t("menu.what_to_do"), choices, func(ch string) bool {
		switch ch {
		case "1":
			saveJSON("disenchanter_loot.json", mustArray(c.GetArray("lol-loot/v1/player-loot")))
		case "2":
			id := ask(cyan("Which lootId would you like the recipes for?\n"))
			r, _ := c.GetRecipes(id)
			saveJSON("disenchanter_recipes.json", r)
		case "3":
			id := ask(cyan("Which lootId would you like the info for?\n"))
			r, _ := c.Get("lol-loot/v1/player-loot/" + id)
			saveJSON("disenchanter_lootinfo.json", r)
		case "4":
			r, _ := c.Get("lol-summoner/v1/current-summoner")
			saveJSON("disenchanter_summoner.json", r)
		case "5":
			r, _ := c.Get("lol-platform-config/v1/namespaces")
			saveJSON("disenchanter_settings.json", r)
		case "d":
			c.DryRun = !c.DryRun
			c.Debug = c.DryRun
			fmt.Println("Dry run " + map[bool]string{true: "enabled", false: "disabled"}[c.DryRun])
		case "m":
			c.Debug = !c.Debug
			fmt.Println("Debug mode " + map[bool]string{true: "enabled", false: "disabled"}[c.Debug])
		case "t":
			for {
				p := ask("Enter path to GET from:\n")
				if p == "x" {
					break
				}
				r, _ := c.Get(p)
				b, _ := json.MarshalIndent(r, "", "  ")
				fmt.Println(string(b))
			}
		case "x":
			return true
		default:
			return false
		}
		return false
	})
}
func mustArray(v []Loot, err error) []Loot { return v }
func saveJSON(path string, v any) {
	b, _ := json.Marshal(v)
	os.WriteFile(path, b, 0644)
	fmt.Println("Written to " + path)
}

func openURL(url, msg string) {
	fmt.Println(blue(msg))
	var cmd *exec.Cmd
	if runtime.GOOS == "windows" {
		cmd = exec.Command("rundll32", "url.dll,FileProtocolHandler", url)
	} else if runtime.GOOS == "darwin" {
		cmd = exec.Command("open", url)
	} else {
		cmd = exec.Command("xdg-open", url)
	}
	_ = cmd.Start()
}
func openMasteryChart(c *Client) {
	p, _ := c.Get("lol-summoner/v1/current-summoner")
	r, _ := c.GetAny("lol-platform-config/v1/namespaces/LoginDataPacket/platformId")
	region := strings.ToLower(strings.TrimRight(fmt.Sprint(r), "12"))
	url := "https://masterychart.com/profile/" + region + "/" + str(p, "gameName") + "-" + str(p, "tagLine") + "?ref=disenchanter"
	openURL(url, t("handler.url.opening_mastery_chart", "url", url))
}

func color(code, s string) string {
	if os.Getenv("NO_COLOR") != "" {
		return s
	}
	return "\033[" + code + "m" + s + "\033[0m"
}
func green(s string) string   { return color("32", s) }
func yellow(s string) string  { return color("93", s) }
func red(s string) string     { return color("91", s) }
func blue(s string) string    { return color("94", s) }
func white(s string) string   { return color("97", s) }
func black(s string) string   { return color("90", s) }
func cyan(s string) string    { return color("96", s) }
func magenta(s string) string { return color("95", s) }
