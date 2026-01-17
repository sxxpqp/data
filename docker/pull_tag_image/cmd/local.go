package cmd

import (
    "fmt"
    "github.com/spf13/cobra"
    "os"
)
var imagename string
var imagenameFilePath string ="images.txt"
var LocalCmd = &cobra.Command{

    Use:   "local",
    Short: "local Docker images",
    Run: func(cmd *cobra.Command, args []string) {
        // 在这里添加您拉取镜像的逻辑
        fmt.Println("localCmd拉取镜像的逻辑在这里执行")
        if imagename !=""{
            fmt.Println(imagename,"正在下载.....")
            writeImageNameToFile(imagename,imagenameFilePath)
          
        }  
        if err := processImages(imagenameFilePath,localstorage,version); err != nil {
            fmt.Printf("处理镜像时出错: %v\n", err)
        } else {
            fmt.Println("所有操作完成")
        }

    },
}

func init() {
    PullCmd.AddCommand(LocalCmd)
	LocalCmd.Flags().StringVarP(&imagename, "imagename", "i", "", "镜像名:版本 如nginx:latest")
    LocalCmd.Flags().BoolVarP(&localstorage, "localstorage", "l", false, "启用本地保存镜像为 xxx.tar")
}

// writeImageNameToFile 将镜像名称写入到指定的文件中，采用覆盖写的方式
func writeImageNameToFile(imageName string, filePath string) error {
    // 打开文件，采用只写模式，清空原有内容
    file, err := os.OpenFile(filePath, os.O_CREATE|os.O_WRONLY|os.O_TRUNC, 0644)
    if err != nil {
        return fmt.Errorf("无法打开文件 %s: %v", filePath, err)
    }
    defer file.Close()

    // 写入镜像名称到文件
    if _, err := file.WriteString(imageName + "\n"); err != nil {
        return fmt.Errorf("写入文件失败: %v", err)
    }

    return nil
}