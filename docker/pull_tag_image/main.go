package main
// GOOS=windows GOARCH=amd64 go build -o itools.exe main.go
import (
	"itools/cmd" // 替换为您的实际模块名
)

func main() {
	cmd.Execute()
}
