package main

import (
	"fmt"
	"os"
	"os/exec"
	"regexp"
	"strings"
)

func getLayout() (string, error) {
	cmd := exec.Command("gdbus", "call", "--session",
		"--dest", "org.gnome.Shell",
		"--object-path", "/me/madhead/Shyriiwook",
		"--method", "org.freedesktop.DBus.Properties.Get",
		"me.madhead.Shyriiwook", "currentLayout")

	output, err := cmd.Output()
	if err != nil {
		return "", err
	}

	// Extract the quoted string (equivalent to grep -o "'[^']*'" | tr -d "'")
	re := regexp.MustCompile(`'([^']*)'`)
	matches := re.FindStringSubmatch(string(output))
	if len(matches) > 1 {
		return matches[1], nil
	}

	return strings.TrimSpace(string(output)), nil
}

func setLayout(layout string) error {
	cmd := exec.Command("gdbus", "call", "--session",
		"--dest", "org.gnome.Shell",
		"--object-path", "/me/madhead/Shyriiwook",
		"--method", "me.madhead.Shyriiwook.activate",
		layout)
	cmd.Stdout = nil
	cmd.Stderr = nil
	return cmd.Run()
}

func main() {
	if len(os.Args) < 2 || os.Args[1] == "" {
		// No argument provided, get current layout
		layout, err := getLayout()
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error getting layout: %v\n", err)
			os.Exit(1)
		}
		fmt.Println(layout)
	} else {
		// Argument provided, set layout
		err := setLayout(os.Args[1])
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error setting layout: %v\n", err)
			os.Exit(1)
		}
	}
}
