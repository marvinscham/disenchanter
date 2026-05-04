package app

import (
	"encoding/base64"
	"errors"
	"os"
	"path/filepath"
	"regexp"
	"runtime"
	"sort"
	"strings"
)

func grabLockfile() (string, string, string, error) {
	paths := candidateLeaguePaths()
	for _, p := range paths {
		b, err := os.ReadFile(filepath.Join(p, "lockfile"))
		if err != nil {
			continue
		}
		parts := strings.Split(string(b), ":")
		if len(parts) < 4 {
			continue
		}
		token := base64.StdEncoding.EncodeToString([]byte("riot:" + strings.TrimSpace(parts[3])))
		return strings.TrimSpace(parts[2]), token, p, nil
	}
	return "", "", "", errors.New("Failed to automatically find your League Client. Make sure your client is running and logged into your account. If it's running and you're seeing this, please place the script directly in your League Client folder.")
}

func candidateLeaguePaths() []string {
	paths := platformLeaguePaths()
	if runtime.GOOS == "windows" {
		paths = append(paths, `C:\Riot Games\League of Legends`)
	}
	paths = append(paths, ".")
	return paths
}

func grabLocale(path string) string {
	dir := filepath.Join(filepath.FromSlash(strings.ReplaceAll(path, "\\", "/")), "Game", "DATA", "FINAL", "Localized")
	entries, err := os.ReadDir(dir)
	if err != nil {
		return "en"
	}
	type item struct {
		path string
		mod  int64
	}
	items := []item{}
	for _, e := range entries {
		info, err := e.Info()
		if err == nil {
			items = append(items, item{e.Name(), info.ModTime().Unix()})
		}
	}
	sort.Slice(items, func(i, j int) bool { return items[i].mod > items[j].mod })
	re := regexp.MustCompile(`\.([a-z]{2}_[A-Z]{2})\.`)
	for _, it := range items {
		if m := re.FindStringSubmatch(it.path); len(m) == 2 {
			return m[1]
		}
	}
	return "en"
}

func mapLocale(in string) string {
	switch in {
	case "en_GB", "en_US", "en_AU", "en_PH", "en_SG":
		return "en"
	case "pl_PL":
		return "pl_PL"
	default:
		return in
	}
}
