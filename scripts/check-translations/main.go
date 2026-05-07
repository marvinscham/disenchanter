package main

import (
	"bytes"
	"flag"
	"fmt"
	"go/ast"
	"go/parser"
	"go/token"
	"os"
	"path/filepath"
	"sort"
	"strconv"
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
	remove := flag.Bool("remove", false, "remove unused translations from locale files")
	reportMissing := flag.Bool("report-missing", false, "write missing and extra translation keys compared to the base locale")
	output := flag.String("output", "translation-report.txt", "report output path")
	flag.Parse()

	locales, err := loadLocaleFiles(filepath.Join(*root, "i18n"))
	if err != nil {
		fatal(err)
	}
	if *reportMissing {
		if err := writeMissingTranslationReport(locales, *output); err != nil {
			fatal(err)
		}
		fmt.Printf("wrote translation report to %s\n", *output)
		return
	}

	used, err := usedTranslationKeys(*root)
	if err != nil {
		fatal(err)
	}

	failed := walkTranslationKeys(locales, used, remove)

	if *remove {
		fmt.Printf("translation cleanup completed: %d source keys, %d locale files\n", len(used), len(locales))
		return
	}

	if failed {
		os.Exit(1)
	}
	fmt.Printf("translation check passed: %d source keys, %d locale files\n", len(used), len(locales))
}

func writeMissingTranslationReport(locales []localeFile, output string) error {
	base := localeByName(locales, baseLocale)
	if base == nil {
		return fmt.Errorf("missing base locale i18n/%s.yml", baseLocale)
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
	return os.WriteFile(output, report.Bytes(), 0644)
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

func walkTranslationKeys(locales []localeFile, used map[string]bool, remove *bool) bool {
	failed := false
	for _, file := range locales {
		unused := difference(file.keys, used)
		if len(unused) > 0 {
			if *remove {
				if err := removeUnusedTranslations(file.path, file.locale, unused); err != nil {
					fatal(err)
				}
				fmt.Printf("%s removed %d unused translations\n", file.path, len(unused))
				continue
			}
			failed = true
			fmt.Printf("%s has unused translations:\n", file.path)
			for _, key := range unused {
				fmt.Printf("  %s\n", key)
			}
		}
	}

	return failed
}

func usedTranslationKeys(root string) (map[string]bool, error) {
	keys := map[string]bool{}
	err := filepath.WalkDir(root, func(path string, entry os.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if skip, err := shouldSkipSourcePath(entry); skip || err != nil {
			return err
		}
		if !isGoSource(path) {
			return nil
		}
		return collectTranslationKeys(path, keys)
	})
	return keys, err
}

func shouldSkipSourcePath(entry os.DirEntry) (bool, error) {
	if !entry.IsDir() {
		return false, nil
	}
	switch entry.Name() {
	case ".git", "build", "scripts", "vendor":
		return true, filepath.SkipDir
	default:
		return true, nil
	}
}

func isGoSource(path string) bool {
	return filepath.Ext(path) == ".go"
}

func collectTranslationKeys(path string, keys map[string]bool) error {
	file, err := parser.ParseFile(token.NewFileSet(), path, nil, 0)
	if err != nil {
		return err
	}
	ast.Inspect(file, func(node ast.Node) bool {
		key, ok := translationKeyFromCall(node)
		if ok {
			keys[key] = true
		}
		return true
	})
	return nil
}

func translationKeyFromCall(node ast.Node) (string, bool) {
	call, ok := node.(*ast.CallExpr)
	if !ok || len(call.Args) == 0 {
		return "", false
	}
	fn, ok := call.Fun.(*ast.Ident)
	if !ok || fn.Name != "t" {
		return "", false
	}
	arg, ok := call.Args[0].(*ast.BasicLit)
	if !ok || arg.Kind != token.STRING {
		return "", false
	}
	key, err := strconv.Unquote(arg.Value)
	return key, err == nil
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
	sort.Slice(locales, func(i, j int) bool { return locales[i].path < locales[j].path })
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

func removeUnusedTranslations(path, locale string, unused []string) error {
	b, err := os.ReadFile(path)
	if err != nil {
		return err
	}
	var doc yaml.Node
	if err := yaml.Unmarshal(b, &doc); err != nil {
		return err
	}
	if len(doc.Content) != 1 || doc.Content[0].Kind != yaml.MappingNode {
		return fmt.Errorf("%s must contain one top-level mapping", path)
	}
	root := mappingValue(doc.Content[0], locale)
	if root == nil || root.Kind != yaml.MappingNode {
		return fmt.Errorf("%s must contain top-level locale %q", path, locale)
	}
	for _, key := range unused {
		removeKey(root, strings.Split(key, "."))
	}
	out, err := os.Create(path)
	if err != nil {
		return err
	}
	defer out.Close()
	encoder := yaml.NewEncoder(out)
	encoder.SetIndent(2)
	if err := encoder.Encode(&doc); err != nil {
		return err
	}
	return encoder.Close()
}

func mappingValue(node *yaml.Node, key string) *yaml.Node {
	for i := 0; i < len(node.Content)-1; i += 2 {
		if node.Content[i].Value == key {
			return node.Content[i+1]
		}
	}
	return nil
}

func removeKey(node *yaml.Node, parts []string) bool {
	if node.Kind != yaml.MappingNode || len(parts) == 0 {
		return false
	}
	for i := 0; i < len(node.Content)-1; i += 2 {
		if node.Content[i].Value != parts[0] {
			continue
		}
		if len(parts) == 1 {
			node.Content = append(node.Content[:i], node.Content[i+2:]...)
			return true
		}
		if !removeKey(node.Content[i+1], parts[1:]) {
			return false
		}
		if node.Content[i+1].Kind == yaml.MappingNode && len(node.Content[i+1].Content) == 0 {
			node.Content = append(node.Content[:i], node.Content[i+2:]...)
		}
		return true
	}
	return false
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

func fatal(err error) {
	fmt.Fprintln(os.Stderr, err)
	os.Exit(1)
}
