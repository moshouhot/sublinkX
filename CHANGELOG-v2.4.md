# SublinkX v2.4 更新日志

## 🎯 版本升级总结

本次更新将 SublinkX 从 v2.3 升级到 v2.4，主要改进用户体验。

## 🎉 新功能

### 1. 首页版本号显示

- 在首页欢迎区域显示当前后端版本号
- 实时从 `/api/v1/version` API 获取版本信息
- 格式：`当前版本：v2.4 | SublinkX 订阅管理系统`

### 2. 安装脚本优化

- 统一的一键安装/更新命令
- 自动检测系统架构 (x86_64 / ARM64)
- 智能判断首次安装还是更新
- 版本比较，已是最新版本时提示
- 彩色终端输出，信息更清晰

## 📦 文件变更清单

### 修改的文件
- `main.go` - 版本号更新到 2.4
- `webs/src/views/dashboard/index.vue` - 首页显示版本号
- `webs/src/api/total/index.ts` - 新增 getVersion API
- `install.sh` - 优化为智能安装/更新脚本
- `README.md` - 简化安装说明

### 新增的文件
- `CHANGELOG-v2.4.md` - 本更新日志

## 🔄 升级指南

### 从任意版本升级到 v2.4

统一使用一键命令：

```bash
curl -s https://raw.githubusercontent.com/moshouhot/sublinkX/main/install.sh | sudo bash
```

脚本会自动检测并完成升级。

## 🎉 总结

SublinkX v2.4 主要改进：

- ✅ **首页版本显示**：方便用户确认当前运行版本
- ✅ **智能安装脚本**：一条命令搞定安装和更新
- ✅ **架构自动检测**：支持 x86_64 和 ARM64
