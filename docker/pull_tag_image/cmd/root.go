package cmd

import (
    "fmt"
    "github.com/spf13/cobra"
	"os"
)

// rootCmd 是应用程序的根命令
var rootCmd = &cobra.Command{
    Use:   "itools",
    Short: "itools is a tool for managing Docker images",
    Long:  `itools is a command-line application to pull and tag Docker images from a specified repository.`,
    Run: func(cmd *cobra.Command, args []string) {
        fmt.Println("imagetools -h或者imagetolls help查看用法")
    },
}

// Execute 执行根命令
func Execute() {
    if err := rootCmd.Execute(); err != nil {
        fmt.Println(err)
        os.Exit(1)
    }
}