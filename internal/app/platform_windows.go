//go:build windows

package app

import "golang.org/x/sys/windows/registry"

func platformLeaguePaths() []string {
	paths := []string{}
	key, err := registry.OpenKey(registry.CURRENT_USER, `SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Riot Game league_of_legends.live`, registry.READ|registry.WOW64_32KEY)
	if err == nil {
		defer key.Close()
		if p, _, err := key.GetStringValue("InstallLocation"); err == nil && p != "" {
			paths = append(paths, p)
		}
	}
	return paths
}
