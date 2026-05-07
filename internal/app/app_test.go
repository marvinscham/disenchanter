package app

import (
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"testing"
)

type fixtureTransport struct {
	t      *testing.T
	routes map[string]string

	mu    sync.Mutex
	posts []string
}

func newFixtureClient(t *testing.T, routes map[string]string) (*Client, *fixtureTransport) {
	t.Helper()
	tr := &fixtureTransport{t: t, routes: routes}
	return &Client{
		Port:  "0",
		Token: "test-token",
		Stats: &Stats{},
		http:  &http.Client{Transport: tr},
	}, tr
}

func (f *fixtureTransport) RoundTrip(req *http.Request) (*http.Response, error) {
	key := req.Method + " " + strings.TrimPrefix(req.URL.RequestURI(), "/")
	fixture := f.routes[key]

	if req.Method == http.MethodPost {
		f.mu.Lock()
		f.posts = append(f.posts, strings.TrimPrefix(req.URL.RequestURI(), "/"))
		f.mu.Unlock()

		if fixture == "" && strings.Contains(req.URL.Path, "/craft") {
			fixture = "post_added_essence.json"
		}
		if fixture == "" && strings.Contains(req.URL.Path, "/refresh") {
			return fixtureResponse(req, `{}`), nil
		}
	}

	if fixture == "" {
		f.t.Fatalf("no fixture route for %s", key)
	}

	return fixtureResponse(req, readFixture(f.t, fixture)), nil
}

func (f *fixtureTransport) postCount() int {
	f.mu.Lock()
	defer f.mu.Unlock()
	return len(f.posts)
}

func fixtureResponse(req *http.Request, body string) *http.Response {
	return &http.Response{
		StatusCode: http.StatusOK,
		Status:     "200 OK",
		Header:     make(http.Header),
		Body:       io.NopCloser(strings.NewReader(body)),
		Request:    req,
	}
}

func readFixture(t *testing.T, name string) string {
	t.Helper()
	b, err := os.ReadFile(filepath.Join("..", "..", "test", "reference", name))
	if err != nil {
		t.Fatal(err)
	}
	return string(b)
}

func TestMain(m *testing.M) {
	os.Setenv("NO_COLOR", "1")
	loadTranslations("en")
	os.Exit(m.Run())
}

func TestCheckSummonerUsesReferenceResponses(t *testing.T) {
	t.Run("valid summoner", func(t *testing.T) {
		c, _ := newFixtureClient(t, map[string]string{
			"GET lol-summoner/v1/current-summoner": "summoner_valid.json",
		})

		if err := c.checkSummoner(); err != nil {
			t.Fatalf("checkSummoner() error = %v", err)
		}
	})

	t.Run("missing name", func(t *testing.T) {
		c, _ := newFixtureClient(t, map[string]string{
			"GET lol-summoner/v1/current-summoner": "summoner_missing_name.json",
		})

		if err := c.checkSummoner(); err == nil || err.Error() != "missing summoner name" {
			t.Fatalf("checkSummoner() error = %v, want missing summoner name", err)
		}
	})
}

func TestHandleKeyFragmentsUsesReferenceVariants(t *testing.T) {
	t.Run("crafts full keys", func(t *testing.T) {
		c, tr := newFixtureClient(t, map[string]string{
			"GET lol-loot/v1/player-loot": "loot_key_fragments_enough.json",
		})

		handleKeyFragments(c, 1)

		if c.Stats.Crafted != 2 || c.Stats.Actions != 2 {
			t.Fatalf("stats = %+v, want Crafted=2 Actions=2", c.Stats)
		}
		if tr.postCount() != 1 {
			t.Fatalf("postCount = %d, want 1", tr.postCount())
		}
	})

	t.Run("skips when not enough fragments", func(t *testing.T) {
		c, tr := newFixtureClient(t, map[string]string{
			"GET lol-loot/v1/player-loot": "loot_key_fragments_not_enough.json",
		})

		handleKeyFragments(c, 1)

		if *c.Stats != (Stats{}) {
			t.Fatalf("stats = %+v, want zero", c.Stats)
		}
		if tr.postCount() != 0 {
			t.Fatalf("postCount = %d, want 0", tr.postCount())
		}
	})
}

func TestHandleGenericUsesReferenceVariants(t *testing.T) {
	t.Run("soft mode keeps unowned items", func(t *testing.T) {
		c, _ := newFixtureClient(t, map[string]string{
			"GET lol-loot/v1/player-loot": "loot_generic_mixed_owned.json",
		})

		handleGeneric(c, "skin shards", skinShard, 1)

		if c.Stats.Disenchanted != 2 || c.Stats.OrangeEssence != 200 || c.Stats.Actions != 2 {
			t.Fatalf("stats = %+v, want Disenchanted=2 OrangeEssence=200 Actions=2", c.Stats)
		}
	})

	t.Run("hard mode includes unowned items", func(t *testing.T) {
		c, _ := newFixtureClient(t, map[string]string{
			"GET lol-loot/v1/player-loot": "loot_generic_mixed_owned.json",
		})

		handleGeneric(c, "skin shards", skinShard, 2)

		if c.Stats.Disenchanted != 3 || c.Stats.OrangeEssence != 400 || c.Stats.Actions != 3 {
			t.Fatalf("stats = %+v, want Disenchanted=3 OrangeEssence=400 Actions=3", c.Stats)
		}
	})

	t.Run("skips when no matching loot", func(t *testing.T) {
		c, tr := newFixtureClient(t, map[string]string{
			"GET lol-loot/v1/player-loot": "loot_generic_none.json",
		})

		handleGeneric(c, "skin shards", skinShard, 2)

		if *c.Stats != (Stats{}) {
			t.Fatalf("stats = %+v, want zero", c.Stats)
		}
		if tr.postCount() != 0 {
			t.Fatalf("postCount = %d, want 0", tr.postCount())
		}
	})
}

func TestHandleCapsulesUsesRecipeReferenceVariants(t *testing.T) {
	t.Run("opens keyless capsules and tracks added essence", func(t *testing.T) {
		c, _ := newFixtureClient(t, map[string]string{
			"GET lol-loot/v1/player-loot":                         "loot_capsules_keyless.json",
			"GET lol-loot/v1/recipes/initial-item/CHEST_TEST":     "recipes_capsule_open.json",
			"GET lol-loot/v1/player-loot/CHEST_TEST":              "lootinfo_capsule.json",
			"POST lol-loot/v1/recipes/CHEST_TEST_OPEN/craft?repeat=2": "post_added_essence.json",
		})

		handleCapsules(c, 1)

		if c.Stats.Opened != 2 || c.Stats.Actions != 2 || c.Stats.BlueEssence != 25 || c.Stats.OrangeEssence != 50 {
			t.Fatalf("stats = %+v, want Opened=2 Actions=2 BlueEssence=25 OrangeEssence=50", c.Stats)
		}
	})

	t.Run("skips capsules that require keys", func(t *testing.T) {
		c, tr := newFixtureClient(t, map[string]string{
			"GET lol-loot/v1/player-loot":                                     "loot_capsules_keyed.json",
			"GET lol-loot/v1/recipes/initial-item/CHEST_LOCKED_TEST":          "recipes_capsule_keyed.json",
		})

		handleCapsules(c, 1)

		if *c.Stats != (Stats{}) {
			t.Fatalf("stats = %+v, want zero", c.Stats)
		}
		if tr.postCount() != 0 {
			t.Fatalf("postCount = %d, want 0", tr.postCount())
		}
	})
}
