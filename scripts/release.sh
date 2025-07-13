#!/bin/bash

# SublinkX 发布脚本
# 用于创建新版本标签并触发GitHub Actions自动编译

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查是否在git仓库中
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    print_error "当前目录不是git仓库"
    exit 1
fi

# 检查是否有未提交的更改
if ! git diff-index --quiet HEAD --; then
    print_warning "检测到未提交的更改，请先提交所有更改"
    git status --porcelain
    exit 1
fi

# 获取当前版本
current_version=$(grep 'version = ' main.go | sed 's/.*version = "\(.*\)".*/\1/')
print_info "当前版本: $current_version"

# 获取版本号参数
if [ $# -eq 0 ]; then
    print_info "请输入新版本号 (当前: $current_version):"
    read -r new_version
else
    new_version=$1
fi

# 验证版本号格式
if [[ ! $new_version =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]]; then
    print_error "版本号格式错误，应为 x.y 或 x.y.z 格式"
    exit 1
fi

print_info "准备发布版本: v$new_version"

# 更新main.go中的版本号
print_info "更新main.go中的版本号..."
sed -i "s/version = \".*\"/version = \"$new_version\"/" main.go

# 提交版本更新
print_info "提交版本更新..."
git add main.go
git commit -m "chore: bump version to $new_version

- 更新版本号到 $new_version
- 准备发布新版本"

# 创建标签
tag_name="v$new_version"
print_info "创建标签: $tag_name"
git tag -a "$tag_name" -m "Release $tag_name

## SublinkX $tag_name

### 🎉 新功能
- 智能代理组选择：只向包含特定关键词的代理组添加节点
- 优化节点合并逻辑，减少配置冗余

### 🔧 改进
- 简化关键词匹配：节点选择、自动选择、手动切换
- 移除代理组数量限制，支持任意数量的符合条件的代理组
- 优化代码结构，提高性能

### 📦 下载说明
- sublink_amd64: Linux x86_64
- sublink_arm64: Linux ARM64  
- sublink_windows_amd64.exe: Windows x86_64
- sublink_darwin_amd64: macOS Intel
- sublink_darwin_arm64: macOS Apple Silicon

### 🚀 快速安装
\`\`\`bash
curl -s -H \"Cache-Control: no-cache\" -H \"Pragma: no-cache\" https://raw.githubusercontent.com/moshouhot/sublinkX/main/install.sh | sudo bash
\`\`\`"

# 推送到远程仓库
print_info "推送到远程仓库..."
git push origin main
git push origin "$tag_name"

print_success "版本 $tag_name 发布成功！"
print_info "GitHub Actions将自动开始编译，请访问以下链接查看进度："
print_info "https://github.com/moshouhot/sublinkX/actions"
print_info ""
print_info "编译完成后，可以通过以下命令安装："
print_info "curl -s -H \"Cache-Control: no-cache\" -H \"Pragma: no-cache\" https://raw.githubusercontent.com/moshouhot/sublinkX/main/install.sh | sudo bash"
