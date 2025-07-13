# SublinkX 部署指南

## 🚀 快速部署

### 方法一：一键安装脚本（推荐）

```bash
curl -s -H "Cache-Control: no-cache" -H "Pragma: no-cache" https://raw.githubusercontent.com/moshouhot/sublinkX/main/install.sh | sudo bash
```

安装完成后，使用 `sublink` 命令管理服务。

### 方法二：手动编译部署

#### 环境要求
- Go 1.22+
- Node.js 18+
- Git

#### 编译步骤

```bash
# 克隆项目
git clone https://github.com/moshouhot/sublinkX.git
cd sublinkX

# 构建前端
cd webs
npm install
npm run build
cd ..

# 构建后端
go mod tidy
go build -ldflags="-s -w" -o sublinkx main.go

# 运行
./sublinkx
```

## 📦 版本管理

### 发布新版本

#### 使用发布脚本（Linux/macOS）

```bash
# 给脚本执行权限
chmod +x scripts/release.sh

# 发布新版本
./scripts/release.sh 2.2
```

#### 使用发布脚本（Windows）

```cmd
# 运行批处理脚本
scripts\release.bat 2.2
```

#### 手动发布

```bash
# 更新版本号
sed -i 's/version = ".*"/version = "2.2"/' main.go

# 提交更改
git add main.go
git commit -m "chore: bump version to 2.2"

# 创建标签
git tag -a v2.2 -m "Release v2.2"

# 推送到远程
git push origin main
git push origin v2.2
```

### GitHub Actions 自动构建

推送标签后，GitHub Actions 会自动：

1. **构建多平台二进制文件**：
   - Linux (amd64, arm64)
   - Windows (amd64)
   - macOS (amd64, arm64)

2. **构建 Docker 镜像**：
   - 支持 linux/amd64 和 linux/arm64
   - 推送到 Docker Hub

3. **创建 GitHub Release**：
   - 自动生成发布说明
   - 上传所有构建产物

## 🔧 配置说明

### 环境变量

| 变量名 | 默认值 | 说明 |
|--------|--------|------|
| `TZ` | `Asia/Shanghai` | 时区设置 |
| `GIN_MODE` | `release` | Gin 运行模式 |

### 数据目录

| 目录 | 说明 | 备份重要性 |
|------|------|-----------|
| `db/` | 数据库文件 | ⭐⭐⭐ 重要 |
| `logs/` | 日志文件 | ⭐ 一般 |
| `template/` | 配置模版 | ⭐⭐ 重要 |

### 端口配置

- **默认端口**：8000
- **修改方法**：
  ```bash
  ./sublinkx setting -port 9000
  ```

## 🛠️ 开发环境

### 本地开发

```bash
# 安装依赖
make deps

# 构建项目
make build

# 运行开发服务器
make dev

# 运行测试
make test
```

### 可用的 Make 命令

```bash
make help              # 显示帮助信息
make build             # 构建应用程序
make build-all         # 多平台编译
make test              # 运行测试
make clean             # 清理构建文件
make dev               # 运行开发服务器
make release           # 创建发布版本
make version           # 显示版本信息
make deps              # 安装依赖
make fmt               # 格式化代码
make lint              # 代码检查
```

## 🔍 故障排除

### 常见问题

#### 1. 端口被占用
```bash
# 查看端口占用
netstat -tlnp | grep 8000

# 修改端口
./sublinkx setting -port 9000
```

#### 2. 权限问题
```bash
# 给予执行权限
chmod +x sublinkx

# 检查数据目录权限
ls -la db/ logs/ template/
```

#### 3. Docker 构建失败
```bash
# 清理 Docker 缓存
docker system prune -a

# 重新构建
docker-compose build --no-cache
```

#### 4. 前端资源加载失败
```bash
# 重新构建前端
cd webs
npm install
npm run build
```

### 日志查看

```bash
# 查看应用日志
tail -f logs/sublinkx.log

# 查看 Docker 日志
docker-compose logs -f sublinkx
```

## 📋 更新升级

### 从旧版本升级

1. **备份数据**：
   ```bash
   cp -r db/ db_backup_$(date +%Y%m%d)
   cp -r template/ template_backup_$(date +%Y%m%d)
   ```

2. **停止服务**：
   ```bash
   # 系统服务
   systemctl stop sublinkx
   
   # Docker
   docker-compose down
   ```

3. **更新程序**：
   ```bash
   # 下载新版本
   curl -LO https://github.com/moshouhot/sublinkX/releases/latest/download/sublink_amd64
   
   # 替换旧版本
   mv sublink_amd64 sublinkx
   chmod +x sublinkx
   ```

4. **启动服务**：
   ```bash
   # 系统服务
   systemctl start sublinkx
   
   # Docker
   docker-compose pull
   docker-compose up -d
   ```

### 数据库迁移

如果版本更新涉及数据库结构变更，程序会在启动时自动执行迁移。

## 🔐 安全建议

1. **修改默认密码**：
   ```bash
   ./sublinkx setting -username admin -password your_secure_password
   ```

2. **使用 HTTPS**：
   - 配置 Nginx 反向代理
   - 申请 SSL 证书

3. **防火墙设置**：
   ```bash
   # 只允许必要端口
   ufw allow 8000/tcp
   ufw enable
   ```

4. **定期备份**：
   ```bash
   # 创建备份脚本
   #!/bin/bash
   DATE=$(date +%Y%m%d_%H%M%S)
   tar -czf "sublinkx_backup_$DATE.tar.gz" db/ template/
   ```

## 📞 技术支持

- **GitHub Issues**: https://github.com/moshouhot/sublinkX/issues
- **文档**: https://github.com/moshouhot/sublinkX/blob/main/README.md
- **更新日志**: https://github.com/moshouhot/sublinkX/releases
