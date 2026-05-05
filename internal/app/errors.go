package app

import "fmt"

func showErrorAndWait(err error) {
	if err != nil {
		fmt.Println(red(err.Error()))
	}
	ask(exitString())
}
