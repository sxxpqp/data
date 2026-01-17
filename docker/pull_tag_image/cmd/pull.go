package cmd

import (
    "fmt"
    "github.com/spf13/cobra"
)

var PullCmd = &cobra.Command{
    Use:   "pull xxxxxx",
    Short: "Pull Docker images",
	// Args:  cobra.ExactArgs(1), 
    Run: func(cmd *cobra.Command, args []string) {
        // 在这里添加您拉取镜像的逻辑
		// local := args[-1] // 获取命令参数
        // fmt.Println("获取到的值:", local)
        fmt.Println("PullCmd拉取镜像的逻辑在这里执行")
    },
}

func init() {
    rootCmd.AddCommand(PullCmd)
	// pullCmd.Flags().IntVarP(&dify, "dify", "d", 1, "要拉取的镜像数量")
	// pullCmd.Flags().StringVarP(&dify, "dify", "d", "", "镜像版本")
	// pullCmd.Flags().StringVarP(&version, "version", "v", "", "镜像版本")
}