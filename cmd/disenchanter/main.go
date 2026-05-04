package main

import (
	"fmt"
	"os"

	"github.com/marvinscham/disenchanter/internal/app"
)

func main() {
	if err := app.Run("v2.0.2"); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
