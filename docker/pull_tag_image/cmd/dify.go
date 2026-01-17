package cmd

import (
    "fmt"
    "github.com/spf13/cobra"
    "regexp"
)
var (
    version string
    localstorage bool
)
var DifyCmd = &cobra.Command{
    Use:   "dify",
    Short: "dify Docker images",
    Run: func(cmd *cobra.Command, args []string) {
        // 在这里添加您拉取镜像的逻辑
        fmt.Println("difyCmd拉取镜像的逻辑在这里执行",version)
    
      // 验证version格式
      if !isValidVersion(version) {
        fmt.Println("无效的版本格式，请使用类似version 1.1.1 或者 -v 1.1.1的格式")
        return
    }

        image_pull_tag_dify(version,localstorage)

    },
}

func init() {
    PullCmd.AddCommand(DifyCmd)
	DifyCmd.Flags().StringVarP(&version, "version", "v", "", "镜像版本")
    // 正确使用 TrueVarP 定义布尔类型的标志
    DifyCmd.Flags().BoolVarP(&localstorage, "localstorage", "l", false, "启用本地保存镜像为 xxx.tar")
}

// isValidVersion 检查版本格式是否有效
func isValidVersion(version string) bool {
    // 正则表达式匹配版本格式
    re := regexp.MustCompile(`^\d+\.\d+\.\d+$`)
    return re.MatchString(version)
}

func image_pull_tag_dify(version string, localstorage bool) error { // 修改函数签名，添加error返回值
    // 设置镜像列表的下载 URL
    imageURL := fmt.Sprintf("https://chfs.sxxpqp.top:8443/chfs/shared/docker/pull_tag_image/dify/%s/images.txt", version)
    if !fileExists(saveimagepath) {
        if err := downloadImages(imageURL, saveimagepath); err != nil {
            return fmt.Errorf("下载镜像列表失败: %v", err) // 现在返回错误
        }
    }

    if err := processImages(saveimagepath, localstorage, version); err != nil {
        return fmt.Errorf("处理镜像时出错: %v", err) // 现在返回错误
    }
    fmt.Println("所有操作完成")
    return nil // 添加返回 nil 表示成功
}