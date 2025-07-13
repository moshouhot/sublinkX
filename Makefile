# SublinkX Makefile

.PHONY: all build build-frontend build-backend clean test release help

# 变量定义
APP_NAME = sublink
VERSION = $(shell grep 'version = ' main.go | sed 's/.*version = "\(.*\)".*/\1/')
BUILD_TIME = $(shell date +%Y-%m-%d\ %H:%M:%S)
GIT_COMMIT = $(shell git rev-parse --short HEAD)

# Go编译参数
LDFLAGS = -ldflags="-s -w -X 'main.buildTime=$(BUILD_TIME)' -X 'main.gitCommit=$(GIT_COMMIT)'"

# 默认目标
all: build

# 构建前端
build-frontend:
	@echo "构建前端..."
	cd webs && npm install && npm run build

# 构建后端
build-backend:
	@echo "构建后端..."
	go mod tidy
	go build $(LDFLAGS) -o $(APP_NAME) main.go

# 完整构建
build: build-frontend build-backend
	@echo "构建完成: $(APP_NAME)"

# 多平台编译
build-all: build-frontend
	@echo "开始多平台编译..."
	
	@echo "编译 Linux amd64..."
	GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build $(LDFLAGS) -o dist/$(APP_NAME)_linux_amd64 main.go
	
	@echo "编译 Linux arm64..."
	GOOS=linux GOARCH=arm64 CGO_ENABLED=0 go build $(LDFLAGS) -o dist/$(APP_NAME)_linux_arm64 main.go
	
	@echo "编译 Windows amd64..."
	GOOS=windows GOARCH=amd64 CGO_ENABLED=0 go build $(LDFLAGS) -o dist/$(APP_NAME)_windows_amd64.exe main.go
	
	@echo "编译 macOS amd64..."
	GOOS=darwin GOARCH=amd64 CGO_ENABLED=0 go build $(LDFLAGS) -o dist/$(APP_NAME)_darwin_amd64 main.go
	
	@echo "编译 macOS arm64..."
	GOOS=darwin GOARCH=arm64 CGO_ENABLED=0 go build $(LDFLAGS) -o dist/$(APP_NAME)_darwin_arm64 main.go
	
	@echo "多平台编译完成！"

# 运行测试
test:
	@echo "运行测试..."
	go test -v ./...

# 清理构建文件
clean:
	@echo "清理构建文件..."
	rm -f $(APP_NAME)
	rm -rf dist/
	rm -rf webs/dist/

# 运行开发服务器
dev: build
	@echo "启动开发服务器..."
	./$(APP_NAME)

# 创建发布
release:
	@echo "创建发布版本 $(VERSION)..."
	@if [ -z "$(VERSION)" ]; then \
		echo "错误: 无法获取版本号"; \
		exit 1; \
	fi
	./scripts/release.sh $(VERSION)

# 显示版本信息
version:
	@echo "SublinkX 版本: $(VERSION)"
	@echo "构建时间: $(BUILD_TIME)"
	@echo "Git提交: $(GIT_COMMIT)"

# 安装依赖
deps:
	@echo "安装Go依赖..."
	go mod download
	@echo "安装前端依赖..."
	cd webs && npm install

# 格式化代码
fmt:
	@echo "格式化Go代码..."
	go fmt ./...
	@echo "格式化前端代码..."
	cd webs && npm run format

# 代码检查
lint:
	@echo "检查Go代码..."
	golangci-lint run
	@echo "检查前端代码..."
	cd webs && npm run lint

# 帮助信息
help:
	@echo "SublinkX 构建工具"
	@echo ""
	@echo "可用命令:"
	@echo "  build          - 构建应用程序 (前端+后端)"
	@echo "  build-frontend - 只构建前端"
	@echo "  build-backend  - 只构建后端"
	@echo "  build-all      - 多平台编译"
	@echo "  test           - 运行测试"
	@echo "  clean          - 清理构建文件"
	@echo "  dev            - 运行开发服务器"
	@echo "  release        - 创建发布版本"
	@echo "  version        - 显示版本信息"
	@echo "  deps           - 安装依赖"
	@echo "  fmt            - 格式化代码"
	@echo "  lint           - 代码检查"
	@echo "  help           - 显示此帮助信息"
