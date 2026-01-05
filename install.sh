#!/bin/bash
# SublinkX 一键安装/更新脚本
# 自动检测首次安装或更新，支持多种架构

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置
INSTALL_DIR="/usr/local/bin/sublink"
SERVICE_NAME="sublink"
REPO="moshouhot/sublinkX"

# 打印带颜色的信息
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# 检查 root 权限
check_root() {
    if [ "$(id -u)" != "0" ]; then
        error "该脚本必须以 root 身份运行，请使用 sudo bash 或 root 用户执行"
    fi
}

# 检测系统架构
detect_arch() {
    local arch=$(uname -m)
    case $arch in
        x86_64)
            FILE_NAME="sublink_amd64"
            ;;
        aarch64|arm64)
            FILE_NAME="sublink_arm64"
            ;;
        *)
            error "不支持的系统架构: $arch (仅支持 x86_64 和 aarch64)"
            ;;
    esac
    info "检测到系统架构: $arch -> 使用 $FILE_NAME"
}

# 获取最新版本号
get_latest_version() {
    info "正在获取最新版本信息..."
    LATEST_VERSION=$(curl -s "https://api.github.com/repos/$REPO/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    if [ -z "$LATEST_VERSION" ]; then
        error "无法获取最新版本信息，请检查网络连接"
    fi
    info "最新版本: $LATEST_VERSION"
}

# 获取当前安装的版本
get_current_version() {
    if [ -f "$INSTALL_DIR/sublink" ]; then
        CURRENT_VERSION=$("$INSTALL_DIR/sublink" -version 2>/dev/null || echo "未知")
        IS_UPDATE=true
    else
        CURRENT_VERSION="未安装"
        IS_UPDATE=false
    fi
}

# 检查服务状态
check_service() {
    if systemctl is-active --quiet $SERVICE_NAME 2>/dev/null; then
        return 0  # 服务运行中
    else
        return 1  # 服务未运行
    fi
}

# 停止服务
stop_service() {
    if check_service; then
        info "正在停止 $SERVICE_NAME 服务..."
        systemctl stop $SERVICE_NAME
        sleep 1
    fi
}

# 启动服务
start_service() {
    info "正在启动 $SERVICE_NAME 服务..."
    systemctl start $SERVICE_NAME
    sleep 2
    if check_service; then
        success "服务启动成功"
    else
        warning "服务启动可能存在问题，请检查日志: journalctl -u $SERVICE_NAME -n 20"
    fi
}

# 创建安装目录
create_directories() {
    if [ ! -d "$INSTALL_DIR" ]; then
        info "创建安装目录: $INSTALL_DIR"
        mkdir -p "$INSTALL_DIR"
        mkdir -p "$INSTALL_DIR/db"
        mkdir -p "$INSTALL_DIR/logs"
        mkdir -p "$INSTALL_DIR/template"
    fi
}

# 下载并安装
download_and_install() {
    local temp_file="/tmp/$FILE_NAME"
    
    info "正在下载 $FILE_NAME..."
    if ! curl -L -o "$temp_file" "https://github.com/$REPO/releases/latest/download/$FILE_NAME"; then
        error "下载失败，请检查网络连接"
    fi
    
    # 验证下载的文件
    if [ ! -f "$temp_file" ] || [ ! -s "$temp_file" ]; then
        error "下载的文件无效"
    fi
    
    info "正在安装..."
    chmod +x "$temp_file"
    mv "$temp_file" "$INSTALL_DIR/sublink"
    
    # 验证安装
    if [ -f "$INSTALL_DIR/sublink" ]; then
        success "二进制文件安装成功"
    else
        error "安装失败"
    fi
}

# 创建 systemd 服务
create_service() {
    info "创建 systemd 服务..."
    cat > /etc/systemd/system/$SERVICE_NAME.service << EOF
[Unit]
Description=SublinkX Service
After=network.target

[Service]
Type=simple
ExecStart=$INSTALL_DIR/sublink
WorkingDirectory=$INSTALL_DIR
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    systemctl enable $SERVICE_NAME
    success "服务配置完成并已设置开机启动"
}

# 下载管理菜单脚本
download_menu() {
    info "下载管理菜单脚本..."
    curl -s -o /usr/bin/sublink "https://raw.githubusercontent.com/$REPO/main/menu.sh"
    chmod 755 /usr/bin/sublink
    success "管理菜单安装完成，输入 'sublink' 可呼出菜单"
}

# 显示安装信息
show_info() {
    echo ""
    echo "========================================"
    if [ "$IS_UPDATE" = true ]; then
        success "SublinkX 更新完成!"
        echo "  旧版本: $CURRENT_VERSION"
        echo "  新版本: $LATEST_VERSION"
    else
        success "SublinkX 安装完成!"
        echo "  版本: $LATEST_VERSION"
    fi
    echo "========================================"
    echo ""
    echo "  📂 安装目录: $INSTALL_DIR"
    echo "  🌐 访问地址: http://服务器IP:8000"
    echo "  👤 默认账号: admin"
    echo "  🔑 默认密码: 123456"
    echo ""
    echo "  📝 常用命令:"
    echo "     sublink           - 打开管理菜单"
    echo "     systemctl status $SERVICE_NAME   - 查看服务状态"
    echo "     systemctl restart $SERVICE_NAME  - 重启服务"
    echo "     journalctl -u $SERVICE_NAME -f   - 查看实时日志"
    echo ""
    echo "========================================"
}

# 主函数
main() {
    echo ""
    echo "  ╔═══════════════════════════════════════════╗"
    echo "  ║       SublinkX 一键安装/更新脚本          ║"
    echo "  ╚═══════════════════════════════════════════╝"
    echo ""
    
    check_root
    detect_arch
    get_latest_version
    get_current_version
    
    if [ "$IS_UPDATE" = true ]; then
        info "检测到已安装版本: $CURRENT_VERSION"
        if [ "$CURRENT_VERSION" = "$LATEST_VERSION" ]; then
            warning "当前已是最新版本 ($LATEST_VERSION)"
            read -p "是否强制重新安装? [y/N]: " force
            if [[ ! "$force" =~ ^[Yy]$ ]]; then
                info "取消操作"
                exit 0
            fi
        fi
        info "开始更新..."
        stop_service
    else
        info "首次安装模式..."
        create_directories
    fi
    
    download_and_install
    
    if [ "$IS_UPDATE" = false ]; then
        create_service
        download_menu
    fi
    
    start_service
    show_info
}

# 运行主函数
main "$@"
