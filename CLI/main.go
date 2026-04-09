package main

import "github.com/ddr/ddr-cli-generated/products/ddr"

func main() {
	_ = ddr.NewCommand().Execute()
}
