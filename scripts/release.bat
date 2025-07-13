@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: SublinkX 发布脚本 (Windows版本)
:: 用于创建新版本标签并触发GitHub Actions自动编译

echo [INFO] SublinkX 版本发布脚本
echo.

:: 检查是否在git仓库中
git rev-parse --git-dir >nul 2>&1
if errorlevel 1 (
    echo [ERROR] 当前目录不是git仓库
    exit /b 1
)

:: 检查是否有未提交的更改
git diff-index --quiet HEAD -- >nul 2>&1
if errorlevel 1 (
    echo [WARNING] 检测到未提交的更改，请先提交所有更改
    git status --porcelain
    exit /b 1
)

:: 获取当前版本
for /f "tokens=3 delims= " %%a in ('findstr "version = " main.go') do (
    set current_version=%%a
    set current_version=!current_version:"=!
)
echo [INFO] 当前版本: !current_version!

:: 获取新版本号
if "%1"=="" (
    set /p new_version="请输入新版本号 (当前: !current_version!): "
) else (
    set new_version=%1
)

echo [INFO] 准备发布版本: v!new_version!

:: 更新main.go中的版本号
echo [INFO] 更新main.go中的版本号...
powershell -Command "(Get-Content main.go) -replace 'version = \".*\"', 'version = \"!new_version!\"' | Set-Content main.go"

:: 提交版本更新
echo [INFO] 提交版本更新...
git add main.go
git commit -m "chore: bump version to !new_version!"

:: 创建标签
set tag_name=v!new_version!
echo [INFO] 创建标签: !tag_name!
git tag -a "!tag_name!" -m "Release !tag_name!"

:: 推送到远程仓库
echo [INFO] 推送到远程仓库...
git push origin main
git push origin "!tag_name!"

echo.
echo [SUCCESS] 版本 !tag_name! 发布成功！
echo [INFO] GitHub Actions将自动开始编译，请访问以下链接查看进度：
echo [INFO] https://github.com/moshouhot/sublinkX/actions
echo.
echo [INFO] 编译完成后，可以通过以下命令安装：
echo [INFO] curl -s -H "Cache-Control: no-cache" -H "Pragma: no-cache" https://raw.githubusercontent.com/moshouhot/sublinkX/main/install.sh ^| sudo bash

pause
