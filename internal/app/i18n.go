package app

import (
	"fmt"
	"path"
	"strings"

	assets "github.com/marvinscham/disenchanter"
	"gopkg.in/yaml.v3"
)

const defaultLocale = "en"

func loadTranslations(want string) {
	translations = map[string]string{}
	loadLocale(defaultLocale)
	if want != defaultLocale && loadLocale(want) {
		locale = want
		return
	}
	locale = defaultLocale
}

func loadLocale(name string) bool {
	b, err := assets.I18n.ReadFile(path.Join("i18n", name+".yml"))
	if err != nil {
		return false
	}

	var raw map[string]any
	if yaml.Unmarshal(b, &raw) != nil {
		return false
	}
	root, ok := raw[name].(map[string]any)
	if !ok {
		return false
	}
	flattenTranslations("", root)
	return true
}

func flattenTranslations(prefix string, m map[string]any) {
	for k, v := range m {
		key := k
		if prefix != "" {
			key = prefix + "." + k
		}
		switch t := v.(type) {
		case map[string]any:
			flattenTranslations(key, t)
		case string:
			translations[key] = t
		default:
			translations[key] = fmt.Sprint(t)
		}
	}
}

func t(key string, args ...any) string {
	out := translations[key]
	if out == "" {
		out = key
	}
	for i := 0; i+1 < len(args); i += 2 {
		out = strings.ReplaceAll(out, "%{"+fmt.Sprint(args[i])+"}", fmt.Sprint(args[i+1]))
	}
	return out
}
