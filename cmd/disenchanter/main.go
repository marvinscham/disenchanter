package main

import (
	"fmt"
	"os"

	"github.com/marvinscham/disenchanter/internal/app"
)

func main() {
	if err := app.Run("v3.0.1"); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
