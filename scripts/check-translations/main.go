package main

import (
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

type localeFile struct {
	path   string
	locale string
	keys   map[string]bool
}

func main() {
	root := flag.String("root", ".", "repository root")
	flag.Parse()

	used, err := usedTranslationKeys(*root)
	if err != nil {
		fatal(err)
	}
	locales, err := loadLocaleFiles(filepath.Join(*root, "i18n"))
	if err != nil {
		fatal(err)
	}

	failed := false
	for _, file := range locales {
		unused := difference(file.keys, used)
		if len(unused) > 0 {
			failed = true
			fmt.Printf("%s has unused translations:\n", file.path)
			for _, key := range unused {
				fmt.Printf("  %s\n", key)
			}
		}
	}

	if failed {
		os.Exit(1)
	}
	fmt.Printf("translation check passed: %d source keys, %d locale files\n", len(used), len(locales))
}

func usedTranslationKeys(root string) (map[string]bool, error) {
	keys := map[string]bool{}
	err := filepath.WalkDir(root, func(path string, entry os.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if entry.IsDir() {
			switch entry.Name() {
			case ".git", "build", "scripts", "vendor":
				return filepath.SkipDir
			}
			return nil
		}
		if filepath.Ext(path) != ".go" {
			return nil
		}

		file, err := parser.ParseFile(token.NewFileSet(), path, nil, 0)
		if err != nil {
			return err
		}
		ast.Inspect(file, func(node ast.Node) bool {
			call, ok := node.(*ast.CallExpr)
			if !ok || len(call.Args) == 0 {
				return true
			}
			fn, ok := call.Fun.(*ast.Ident)
			if !ok || fn.Name != "t" {
				return true
			}
			arg, ok := call.Args[0].(*ast.BasicLit)
			if !ok || arg.Kind != token.STRING {
				return true
			}
			key, err := strconv.Unquote(arg.Value)
			if err == nil {
				keys[key] = true
			}
			return true
		})
		return nil
	})
	return keys, err
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
