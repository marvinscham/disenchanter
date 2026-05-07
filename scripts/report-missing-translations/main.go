package main

import (
	"bytes"
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"

	"gopkg.in/yaml.v3"
)

const baseLocale = "en"

type localeFile struct {
	path   string
	locale string
	keys   map[string]bool
}

func main() {
	root := flag.String("root", ".", "repository root")
	output := flag.String("output", "translation-report.txt", "report output path")
	flag.Parse()

	locales, err := loadLocaleFiles(filepath.Join(*root, "i18n"))
	if err != nil {
		fatal(err)
	}
	base := localeByName(locales, baseLocale)
	if base == nil {
		fatal(fmt.Errorf("missing base locale i18n/%s.yml", baseLocale))
	}

	var report bytes.Buffer
	fmt.Fprintf(&report, "Translation report (baseline: %s)\n\n", base.path)

	hasFindings := false
	for _, file := range locales {
		if file.locale == baseLocale {
			continue
		}

		missing := difference(base.keys, file.keys)
		extra := difference(file.keys, base.keys)
		if len(missing) == 0 && len(extra) == 0 {
			continue
		}

		hasFindings = true
		fmt.Fprintf(&report, "%s (%s)\n", file.locale, file.path)
		writeKeys(&report, "Missing", missing)
		writeKeys(&report, "Not in baseline", extra)
		fmt.Fprintln(&report)
	}

	if !hasFindings {
		fmt.Fprintln(&report, "No missing or extra translation keys found.")
	}

	if err := os.WriteFile(*output, report.Bytes(), 0644); err != nil {
		fatal(err)
	}
	fmt.Printf("wrote translation report to %s\n", *output)
}

func loadLocaleFiles(dir string) ([]localeFile, error) {
	entries, err := os.ReadDir(dir)
	if err != nil {
		return nil, err
	}
	locales := []localeFile{}
	for _, entry := range entries {
		if entry.IsDir() || filepath.Ext(entry.Name()) != ".yml" {
			continue
		}
		path := filepath.Join(dir, entry.Name())
		keys, locale, err := loadLocaleFile(path)
		if err != nil {
			return nil, err
		}
		locales = append(locales, localeFile{path: path, locale: locale, keys: keys})
	}
	sort.Slice(locales, func(i, j int) bool { return locales[i].locale < locales[j].locale })
	return locales, nil
}

func loadLocaleFile(path string) (map[string]bool, string, error) {
	b, err := os.ReadFile(path)
	if err != nil {
		return nil, "", err
	}
	var raw map[string]any
	if err := yaml.Unmarshal(b, &raw); err != nil {
		return nil, "", err
	}
	locale := strings.TrimSuffix(filepath.Base(path), filepath.Ext(path))
	root, ok := raw[locale].(map[string]any)
	if !ok {
		return nil, "", fmt.Errorf("%s must contain top-level locale %q", path, locale)
	}
	keys := map[string]bool{}
	flatten(keys, "", root)
	return keys, locale, nil
}

func flatten(out map[string]bool, prefix string, values map[string]any) {
	for key, value := range values {
		fullKey := key
		if prefix != "" {
			fullKey = prefix + "." + key
		}
		if child, ok := value.(map[string]any); ok {
			flatten(out, fullKey, child)
			continue
		}
		out[fullKey] = true
	}
}

func difference(left, right map[string]bool) []string {
	keys := []string{}
	for key := range left {
		if !right[key] {
			keys = append(keys, key)
		}
	}
	sort.Strings(keys)
	return keys
}

func localeByName(locales []localeFile, name string) *localeFile {
	for i := range locales {
		if locales[i].locale == name {
			return &locales[i]
		}
	}
	return nil
}

func writeKeys(report *bytes.Buffer, title string, keys []string) {
	fmt.Fprintf(report, "  %s: %d\n", title, len(keys))
	for _, key := range keys {
		fmt.Fprintf(report, "    - %s\n", key)
	}
}

func fatal(err error) {
	fmt.Fprintln(os.Stderr, err)
	os.Exit(1)
}
