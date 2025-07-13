#!/bin/bash

# SublinkX 安装测试脚本
# 用于测试安装脚本是否正常工作

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# 测试函数
test_github_api() {
    print_info "测试 GitHub API 访问..."
    
    # 测试获取最新版本
    latest_release=$(curl --silent "https://api.github.com/repos/moshouhot/sublinkX/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    
    if [ -z "$latest_release" ]; then
        print_error "无法获取最新版本信息"
        return 1
    fi
    
    print_success "最新版本: $latest_release"
    return 0
}

test_download_links() {
    print_info "测试下载链接..."
    
    # 获取最新版本
    latest_release=$(curl --silent "https://api.github.com/repos/moshouhot/sublinkX/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    
    # 检测系统架构
    arch=$(uname -m)
    case $arch in
        x86_64)
            file_name="sublink_amd64"
            ;;
        aarch64|arm64)
            file_name="sublink_arm64"
            ;;
        *)
            print_error "不支持的架构: $arch"
            return 1
            ;;
    esac
    
    download_url="https://github.com/moshouhot/sublinkX/releases/download/$latest_release/$file_name"
    print_info "测试下载链接: $download_url"
    
    # 测试链接是否可访问
    if curl --output /dev/null --silent --head --fail "$download_url"; then
        print_success "下载链接可访问"
        return 0
    else
        print_error "下载链接不可访问"
        return 1
    fi
}

test_install_script() {
    print_info "测试安装脚本访问..."
    
    install_url="https://raw.githubusercontent.com/moshouhot/sublinkX/main/install.sh"
    
    if curl --output /dev/null --silent --head --fail "$install_url"; then
        print_success "安装脚本可访问"
        return 0
    else
        print_error "安装脚本不可访问"
        return 1
    fi
}

test_menu_script() {
    print_info "测试菜单脚本访问..."
    
    menu_url="https://raw.githubusercontent.com/moshouhot/sublinkX/main/menu.sh"
    
    if curl --output /dev/null --silent --head --fail "$menu_url"; then
        print_success "菜单脚本可访问"
        return 0
    else
        print_error "菜单脚本不可访问"
        return 1
    fi
}

# 主测试流程
main() {
    print_info "开始测试 SublinkX 安装环境..."
    echo
    
    # 检查必要工具
    for tool in curl grep sed; do
        if ! command -v $tool &> /dev/null; then
            print_error "缺少必要工具: $tool"
            exit 1
        fi
    done
    print_success "必要工具检查通过"
    echo
    
    # 运行测试
    tests=(
        "test_github_api"
        "test_download_links" 
        "test_install_script"
        "test_menu_script"
    )
    
    failed_tests=0
    
    for test in "${tests[@]}"; do
        if ! $test; then
            ((failed_tests++))
        fi
        echo
    done
    
    # 输出结果
    if [ $failed_tests -eq 0 ]; then
        print_success "所有测试通过！安装环境正常"
        echo
        print_info "可以使用以下命令进行安装："
        print_info "curl -s -H \"Cache-Control: no-cache\" -H \"Pragma: no-cache\" https://raw.githubusercontent.com/moshouhot/sublinkX/main/install.sh | sudo bash"
    else
        print_error "有 $failed_tests 个测试失败"
        exit 1
    fi
}

# 运行主函数
main "$@"
