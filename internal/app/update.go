package app

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"os/exec"
	"runtime"
	"strconv"
	"strings"
	"time"
)

const latestReleaseURL = "https://api.github.com/repos/marvinscham/disenchanter/releases/latest"

func checkUpdate(local string) {
	tag, err := remoteTag()
	if err != nil {
		fmt.Println(yellow(err.Error()))
		return
	}
	cmp := compareVersion(local, tag)
	if cmp == 0 {
		fmt.Println(green(t("update_checker.up_to_date")))
		return
	}
	if cmp > 0 {
		fmt.Println(magenta(t("update_checker.local_beta_note")))
		fmt.Println(blue(t("update_checker.local_beta_version", "version", strings.TrimPrefix(tag, "v"))))
		return
	}
	fmt.Println(yellow(t("update_checker.update_available", "version", strings.TrimPrefix(tag, "v"))))
	if isYes(inputCheck(t("update_checker.ask_download_now"), ansYN(), "[y|n]", "default")) {
		url := "https://github.com/marvinscham/disenchanter/releases/download/" + tag + "/disenchanter_up.exe"
		if err := downloadFile("disenchanter_up.exe", url); err != nil {
			fmt.Println(red(err.Error()))
			return
		}
		fmt.Println(green(t("update_checker.done_downloading")))
		startDetached("disenchanter_up.exe")
		fmt.Println(black(t("common.exiting")))
		os.Exit(0)
	}
}

func RunUpdater() error {
	if _, err := os.Stat("./build/.build.lockfile"); err == nil {
		fmt.Println(yellow("Detected build environment, skipping execution..."))
		time.Sleep(2 * time.Second)
		return nil
	}
	fmt.Println(blue("Grabbing latest version of Disenchanter..."))
	backwardsCompat()
	tag, err := remoteTag()
	if err != nil {
		showErrorAndWait(err)
		return nil
	}
	fmt.Println(green("Downloading Disenchanter " + tag))
	if err := downloadFile("disenchanter.exe", "https://github.com/marvinscham/disenchanter/releases/download/"+tag+"/disenchanter.exe"); err != nil {
		showErrorAndWait(err)
		return nil
	}
	fmt.Println(black("____________________________________________________________"))
	fmt.Println(green("Done downloading!"))
	startDetached("disenchanter.exe")
	fmt.Println(black("Exiting..."))
	return nil
}

func remoteTag() (string, error) {
	res, err := http.Get(latestReleaseURL)
	if err != nil {
		return "", err
	}
	defer res.Body.Close()
	var out map[string]any
	if err := json.NewDecoder(res.Body).Decode(&out); err != nil {
		return "", err
	}
	tag, _ := out["tag_name"].(string)
	if tag == "" {
		return "", fmt.Errorf("latest release has no tag_name")
	}
	return tag, nil
}
func downloadFile(path, url string) error {
	res, err := http.Get(url)
	if err != nil {
		return err
	}
	defer res.Body.Close()
	if res.StatusCode >= 400 {
		return fmt.Errorf("download failed: %s", res.Status)
	}
	f, err := os.Create(path)
	if err != nil {
		return err
	}
	defer f.Close()
	_, err = io.Copy(f, res.Body)
	return err
}

func compareVersion(a, b string) int {
	pa := versionParts(a)
	pb := versionParts(b)
	for i := 0; i < 3; i++ {
		if pa[i] > pb[i] {
			return 1
		}
		if pa[i] < pb[i] {
			return -1
		}
	}
	return 0
}
func versionParts(v string) [3]int {
	v = strings.TrimPrefix(v, "v")
	v = strings.TrimSuffix(v, "-beta")
	base := strings.Split(v, "-")[0]
	parts := strings.Split(base, ".")
	out := [3]int{}
	for i := 0; i < len(parts) && i < 3; i++ {
		out[i], _ = strconv.Atoi(parts[i])
	}
	return out
}

func backwardsCompat() {
	if runtime.GOOS != "windows" {
		return
	}
	exec.Command("taskkill", "/IM", "disenchanter.exe", "/F", "/T").Run()
	time.Sleep(time.Second)
}
func startDetached(exe string) {
	if runtime.GOOS == "windows" {
		exec.Command("cmd", "/C", "start", "cmd.exe", "@cmd", "/k", exe).Start()
		return
	}
	exec.Command("./" + exe).Start()
}
