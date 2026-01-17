package cmd

import (
	"bufio"
	"fmt"
	"io/ioutil"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)
var saveimagepath string ="images.txt"


// processImages 下载镜像列表并处理每个镜像
func processImages(imageFlieName string,localstorage bool,version string,) error {
   

    images, err := readImages(imageFlieName)
    if err != nil {
        return fmt.Errorf("读取镜像列表失败: %v", err)
    }

    sourceRepo := "registry.cn-hangzhou.aliyuncs.com/sxxpqp"
    for _, image := range images {
        if err := processImage(sourceRepo, image,localstorage,version); err != nil {
            fmt.Printf("处理镜像时出错: %v\n", err)
        }
    }

    // 清理临时文件
    if err := os.Remove(saveimagepath); err != nil {
        return fmt.Errorf("删除临时文件失败: %v", err)
    }
    return nil
}
// processImage 处理单个镜像的拉取和标记
func processImage(sourceRepo, image string,localstorage bool,version string,) error {
    cleanedImage := strings.TrimPrefix(image, "#")
    fmt.Printf("获取到镜像名称是: %s\n", cleanedImage)

    baseName := cleanedImage[strings.LastIndex(cleanedImage, "/")+1:]
    sourceImage := fmt.Sprintf("%s/%s", sourceRepo, baseName)
    fmt.Printf("拉取镜像: %s\n", sourceImage)

    if err := dockerPull(sourceImage); err != nil {
        return fmt.Errorf("拉取镜像失败: %s, 错误: %v", sourceImage, err)
    }

    targetImage := cleanedImage
    fmt.Printf("标记镜像为: %s\n", targetImage)

    if err := dockerTag(sourceImage, targetImage); err != nil {
        return fmt.Errorf("标记镜像失败: %s, 错误: %v", targetImage, err)
    }

    fmt.Printf("镜像标记成功: %s\n", targetImage)
	if localstorage{
		dockerSave(targetImage,baseName,"imagefile"+version)
	}
    fmt.Println("------")
    return nil
}


// downloadImages 从指定 URL 下载镜像列表
func downloadImages(url string, filename string) error {
	resp, err := http.Get(url)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("HTTP请求失败: %s", resp.Status)
	}

	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return err
	}

	return ioutil.WriteFile(filename, body, 0644)
}

// readImages 从文件中读取镜像列表
func readImages(filename string) ([]string, error) {
	var images []string
	file, err := os.Open(filename)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		images = append(images, scanner.Text())
	}
	return images, scanner.Err()
}

// dockerPull 封装 docker pull 命令
func dockerPull(image string) error {
	cmd := exec.Command("docker", "pull", image)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run()
}
// dockerSave 封装 docker pull 命令
func dockerSave(targetImage,baseName string, outputDir string) error {
    // 确保输出目录存在，不存在则创建
    if _, err := os.Stat(outputDir); os.IsNotExist(err) {
        if err := os.MkdirAll(outputDir, os.ModePerm); err != nil {
            return fmt.Errorf("创建输出目录失败: %v", err)
        }
    }
	fmt.Println("保存镜像名称是:",targetImage)
    // 构建保存的文件名
    // 从镜像名称中获取文件名，去掉任何 Docker 仓库前缀
    outputFile := filepath.Join(outputDir, baseName+".tar") // 生成完整的输出文件路径
	fmt.Println("保存镜像文件路径/文件名是:",outputFile)
    // 创建执行命令
    cmd := exec.Command("docker", "save", "-o", outputFile, targetImage)
    cmd.Stdout = os.Stdout
    cmd.Stderr = os.Stderr

    // 执行命令
    return cmd.Run()
}
// dockerTag 封装 docker tag 命令
func dockerTag(source string, target string) error {
	cmd := exec.Command("docker", "tag", source, target)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run()
}

func fileExists(filename string) bool {
	if _, err := os.Stat(filename); os.IsNotExist(err) {
		return false
	}
	return true
}
