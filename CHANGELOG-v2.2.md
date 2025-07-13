# SublinkX v2.2 更新日志

## 🎯 版本升级总结

本次更新将 SublinkX 从 v2.1 升级到 v2.2，主要包含智能代理组选择优化和完整的 CI/CD 流程建设。

## 🎉 核心功能改进

### 1. 智能代理组选择策略

#### 问题背景
- 原版本向所有代理组添加节点，导致配置冗余
- 用户反馈希望只向特定代理组（如"节点选择"、"自动选择"）添加节点

#### 解决方案
- **关键词匹配**：只向包含特定关键词的代理组添加节点
- **支持关键词**：`节点选择`、`自动选择`、`手动切换`
- **无数量限制**：移除最多2个代理组的限制，支持任意数量符合条件的代理组

#### 代码变更
```go
// 修改前：复杂的多重判断 + 数量限制
addedCount := 0
maxAddGroups := 2
if addedCount >= maxAddGroups { break }

// 修改后：简洁的关键词匹配
keywords := []string{"节点选择", "自动选择", "手动切换"}
for _, keyword := range keywords {
    if strings.Contains(groupName, keyword) {
        shouldAddNodes = true
        break
    }
}
```

#### 实际效果
```yaml
proxy-groups:
  - name: 🔰 节点选择    # ✅ 会添加节点
  - name: ♻️ 自动选择    # ✅ 会添加节点  
  - name: 🚀 手动切换    # ✅ 会添加节点
  - name: 🎥 NETFLIX     # ❌ 不会添加节点
  - name: ⛔️ 广告拦截    # ❌ 不会添加节点
```

## 🔧 CI/CD 流程建设

### 1. GitHub Actions 自动构建

#### 新增文件
- `.github/workflows/build.yml` - 多平台二进制构建
- `.github/workflows/docker.yml` - Docker 镜像构建

#### 支持平台
- **Linux**: amd64, arm64
- **Windows**: amd64
- **macOS**: amd64 (Intel), arm64 (Apple Silicon)

#### 触发条件
- 推送标签 (v*)
- 手动触发 (workflow_dispatch)

### 2. 自动发布流程

#### 发布脚本
- `scripts/release.sh` - Linux/macOS 发布脚本
- `scripts/release.bat` - Windows 发布脚本

#### 发布流程
1. 更新版本号
2. 提交代码变更
3. 创建 Git 标签
4. 推送到远程仓库
5. 触发 GitHub Actions
6. 自动构建和发布

### 3. Docker 优化

#### Dockerfile 改进
- **多阶段构建**：前端构建 → 后端构建 → 最终镜像
- **镜像优化**：使用 Alpine Linux，减小镜像体积
- **健康检查**：添加容器健康检查
- **多架构支持**：linux/amd64, linux/arm64

#### Docker Compose 更新
- **生产配置**：`docker-compose.yml`
- **开发配置**：`docker-compose.dev.yml`
- **数据持久化**：正确的卷挂载配置

## 📦 项目结构优化

### 新增文件

```
sublinkX/
├── .github/workflows/
│   ├── build.yml          # 二进制构建工作流
│   └── docker.yml         # Docker 构建工作流
├── scripts/
│   ├── release.sh         # Linux/macOS 发布脚本
│   ├── release.bat        # Windows 发布脚本
│   └── test-install.sh    # 安装测试脚本
├── Makefile               # 构建工具
├── docker-compose.dev.yml # 开发环境配置
├── DEPLOYMENT.md          # 部署指南
└── CHANGELOG-v2.2.md      # 本更新日志
```

### 更新文件

- `main.go` - 版本号更新到 2.2
- `node/clash.go` - 智能代理组选择逻辑
- `README.md` - 完整的技术文档
- `install.sh` - 修正 GitHub 仓库地址
- `Dockerfile` - 多阶段构建优化
- `docker-compose.yml` - 生产环境配置
- `.gitignore` - 完善忽略规则

## 🚀 部署改进

### 1. 一键安装优化

#### 修复问题
- 修正 GitHub 仓库地址：`gooaclok819/sublinkX` → `moshouhot/sublinkX`
- 确保安装脚本可正常访问和执行

#### 安装命令
```bash
curl -s -H "Cache-Control: no-cache" -H "Pragma: no-cache" https://raw.githubusercontent.com/moshouhot/sublinkX/main/install.sh | sudo bash
```

### 2. 多种部署方式

#### Docker 部署
```bash
# 使用预构建镜像
docker run --name sublinkx -p 8000:8000 \
  -v $PWD/db:/app/db \
  -v $PWD/template:/app/template \
  -v $PWD/logs:/app/logs \
  -d jaaksi/sublinkx:latest
```

#### 手动编译
```bash
# 使用 Makefile
make build

# 或传统方式
cd webs && npm install && npm run build && cd ..
go mod tidy && go build -o sublinkx main.go
```

## 📋 开发工具改进

### 1. Makefile 支持

提供统一的构建命令：
- `make build` - 完整构建
- `make build-all` - 多平台编译
- `make dev` - 开发服务器
- `make test` - 运行测试
- `make clean` - 清理构建文件

### 2. 开发环境

- Docker 开发环境配置
- 代码格式化和检查工具
- 自动化测试脚本

## 🔍 质量保证

### 1. 自动化测试

- 安装环境测试脚本
- GitHub Actions 构建验证
- Docker 镜像健康检查

### 2. 文档完善

- 详细的部署指南 (`DEPLOYMENT.md`)
- 完整的技术文档 (`README.md`)
- 故障排除指南

## 🎯 用户体验提升

### 1. 配置生成优化

- 减少配置冗余：只向必要的代理组添加节点
- 提高生成速度：优化合并算法
- 增强可维护性：清晰的代理组结构

### 2. 部署体验

- 一键安装脚本优化
- 多种部署方式选择
- 详细的部署文档

## 🔄 升级指南

### 从 v2.1 升级到 v2.2

1. **备份数据**：
   ```bash
   cp -r db/ db_backup_$(date +%Y%m%d)
   cp -r template/ template_backup_$(date +%Y%m%d)
   ```

2. **停止服务**：
   ```bash
   systemctl stop sublinkx  # 或 docker-compose down
   ```

3. **更新程序**：
   ```bash
   curl -LO https://github.com/moshouhot/sublinkX/releases/latest/download/sublink_amd64
   mv sublink_amd64 sublinkx && chmod +x sublinkx
   ```

4. **启动服务**：
   ```bash
   systemctl start sublinkx  # 或 docker-compose up -d
   ```

## 🎉 总结

SublinkX v2.2 是一个重要的版本更新，不仅优化了核心功能，还建立了完整的现代化开发和部署流程。主要改进包括：

- ✅ **智能代理组选择**：解决配置冗余问题
- ✅ **自动化 CI/CD**：GitHub Actions 自动构建发布
- ✅ **多平台支持**：支持 5 种平台的二进制文件
- ✅ **Docker 优化**：多架构镜像和完善的容器化方案
- ✅ **开发工具**：Makefile、发布脚本等开发辅助工具
- ✅ **文档完善**：详细的部署和开发指南

这些改进使 SublinkX 更加易用、稳定和可维护，为后续版本的开发奠定了坚实基础。
