<div align="center">
<img src="webs/src/assets/logo.png" width="150px" height="150px" />
</div>

<div align="center">
    <img src="https://img.shields.io/badge/Vue-5.0.8-brightgreen.svg"/>
    <img src="https://img.shields.io/badge/Go-1.22.0-green.svg"/>
    <img src="https://img.shields.io/badge/Element Plus-2.6.1-blue.svg"/>
    <img src="https://img.shields.io/badge/license-MIT-green.svg"/>
    <a href="https://t.me/+u6gLWF0yP5NiZWQ1" target="_blank">
        <img src="https://img.shields.io/badge/TG-交流群-orange.svg"/>
    </a>
    <div align="center"> 中文 | <a href="README.en-US.md">English</div>
</div>

## [项目简介]

项目基于sublink项目二次开发：https://github.com/jaaksii/sublink

前端基于：https://github.com/youlaitech/vue3-element-admin

后端采用go+gin+gorm

默认账号admin 密码123456  自行修改

因为重写目前还有很多布局结构以及功能稍少

## [项目特色]

自由度和安全性较高，能够记录访问订阅，配置轻松

二进制编译无需Docker容器

目前仅支持客户端：v2ray clash surge

v2ray为base64通用格式

clash支持协议:ss ssr trojan vmess vless hy hy2 tuic

surge支持协议:ss trojan vmess hy2 tuic

## [核心功能：模版和节点合并机制]

### 架构概述

SublinkX 采用了模版+节点的灵活架构，通过将代理节点信息与客户端配置模版分离，实现了高度可定制的订阅生成系统。

### 数据模型

#### 1. 节点模型 (Node)
```go
type Node struct {
    gorm.Model
    ID         int
    Name       string  // 节点名称
    Link       string  // 节点链接(支持多种协议)
    GroupNodes []GroupNode `gorm:"many2many:group_node_nodes"`
}
```

#### 2. 订阅模型 (Subscription)
```go
type Subcription struct {
    gorm.Model
    ID        int
    Name      string
    Config    string    `gorm:"type:text"` // 配置信息(JSON格式)
    NodeOrder string    `gorm:"type:text"` // 节点顺序
    Nodes     []Node    `gorm:"many2many:subcription_nodes;"`
    SubLogs   []SubLogs `gorm:"foreignKey:SubcriptionID;"`
}
```

#### 3. 配置结构
```go
type SubscriptionConfig struct {
    Clash string `json:"clash"` // Clash模版路径
    Surge string `json:"surge"` // Surge模版路径
    UDP   bool   `json:"udp"`   // UDP支持
    Cert  bool   `json:"cert"`  // 证书验证
}
```

### 合并流程详解

#### 第一步：订阅创建
1. **前端选择**：用户在前端界面选择节点和模版
   - 选择已有节点列表
   - 选择Clash/Surge模版文件
   - 配置UDP和证书选项

2. **数据提交**：前端将配置信息提交到后端
```javascript
const config = JSON.stringify({
    "clash": Clash.value.trim(),
    "surge": Surge.value.trim(),
    "udp": checkList.value.includes('udp') ? true : false,
    "cert": checkList.value.includes('cert') ? true : false
})
```

#### 第二步：节点解析与处理
当用户访问订阅链接时，系统执行以下步骤：

1. **获取订阅信息**
```go
// 根据订阅名称查找订阅
sub.Name = SunName
err := sub.Find()
```

2. **节点链接处理**
系统支持三种节点链接类型：
- **单个节点**：直接使用节点链接
- **多个节点**：逗号分隔的多个链接
- **订阅链接**：HTTP/HTTPS远程订阅

```go
for _, v := range sub.Nodes {
    switch {
    case strings.Contains(v.Link, ","):
        // 处理多个节点
        links := strings.Split(v.Link, ",")
        urls = append(urls, links...)
    case strings.Contains(v.Link, "http://") || strings.Contains(v.Link, "https://"):
        // 处理远程订阅
        resp, err := http.Get(v.Link)
        // 解码并分割节点
        nodes := node.Base64Decode(string(body))
        links := strings.Split(nodes, "\n")
        urls = append(urls, links...)
    default:
        // 单个节点
        urls = append(urls, v.Link)
    }
}
```

#### 第三步：协议解析与转换
系统根据节点链接的协议类型进行解析：

**支持的协议类型**：
- **SS (Shadowsocks)**：`ss://`
- **SSR (ShadowsocksR)**：`ssr://`
- **Trojan**：`trojan://`
- **VMess**：`vmess://`
- **VLESS**：`vless://`
- **Hysteria**：`hy://` 或 `hysteria://`
- **Hysteria2**：`hy2://` 或 `hysteria2://`
- **TUIC**：`tuic://`

每种协议都有对应的解析函数，例如：
```go
case Scheme == "ss":
    ss, err := DecodeSSURL(link)
    ssproxy := Proxy{
        Name:             ss.Name,
        Type:             "ss",
        Server:           ss.Server,
        Port:             ss.Port,
        Cipher:           ss.Param.Cipher,
        Password:         ss.Param.Password,
        Udp:              sqlconfig.Udp,
        Skip_cert_verify: sqlconfig.Cert,
    }
    proxys = append(proxys, ssproxy)
```

#### 第四步：模版处理与合并

##### Clash配置生成
1. **读取模版文件**
```go
// 支持本地文件和远程URL
if strings.Contains(yamlfile, "://") {
    resp, err := http.Get(yamlfile)
    data, err = io.ReadAll(resp.Body)
} else {
    data, err = os.ReadFile(yamlfile)
}
```

2. **YAML解析与修改**
```go
config := make(map[interface{}]interface{})
err = yaml.Unmarshal(data, &config)

// 添加代理节点到proxies部分
proxies, ok := config["proxies"].([]interface{})
for _, p := range proxys {
    ProxiesNameList = append(ProxiesNameList, p.Name)
    proxies = append(proxies, p)
}
config["proxies"] = proxies
```

3. **智能代理组更新**
```go
// 通过关键词匹配需要添加节点的代理组
proxyGroups := config["proxy-groups"].([]interface{})

for i, pg := range proxyGroups {
    proxyGroup := pg.(map[string]interface{})
    groupName := proxyGroup["name"].(string)
    groupType := proxyGroup["type"].(string)

    // 跳过链式代理
    if groupType == "relay" {
        continue
    }

    // 通过关键词判断是否需要添加节点
    shouldAddNodes := false
    keywords := []string{"节点选择", "自动选择", "手动切换"}
    for _, keyword := range keywords {
        if strings.Contains(groupName, keyword) {
            shouldAddNodes = true
            break
        }
    }

    if shouldAddNodes {
        // 添加节点到代理组
        validProxies := proxyGroup["proxies"].([]interface{})
        for _, newProxy := range ProxiesNameList {
            validProxies = append(validProxies, newProxy)
        }
        proxyGroup["proxies"] = validProxies
        log.Printf("已向代理组 '%s' 添加 %d 个节点", groupName, len(ProxiesNameList))
    }
}
```

##### Surge配置生成
1. **读取模版文件**（同Clash）

2. **正则表达式替换**
```go
// 使用正则表达式定位[Proxy]和[Proxy Group]部分
proxyReg := regexp.MustCompile(`(?s)\[Proxy\](.*?)\[*]`)
groupReg := regexp.MustCompile(`(?s)\[Proxy Group\](.*?)\[*]`)

// 替换[Proxy]部分
proxyPart := proxyReg.ReplaceAllStringFunc(string(surge), func(s string) string {
    text := strings.Join(proxys, "\n")
    return "[Proxy]\n" + text + s[len("[Proxy]"):]
})

// 替换[Proxy Group]部分
groupPart := groupReg.ReplaceAllStringFunc(proxyPart, func(s string) string {
    lines := strings.Split(s, "\n")
    grouplist := strings.Join(groups, ",")
    for i, line := range lines {
        if strings.Contains(line, "=") {
            lines[i] = strings.TrimSpace(line) + ", " + grouplist
        }
    }
    return strings.Join(lines, "\n")
})
```

#### 第五步：配置输出
最终生成的配置文件通过HTTP响应返回给客户端：

```go
// Clash配置
c.Writer.Header().Set("Content-Type", "text/plain; charset=utf-8")
c.Writer.WriteString(string(DecodeClash))

// Surge配置
c.Writer.Header().Set("Content-Type", "text/plain; charset=utf-8")
c.Writer.WriteString(string(DecodeClash))
```

### 模版文件结构

#### Clash模版 (clash.yaml)
- **基础配置**：端口、DNS、日志等
- **代理部分**：`proxies: ~` (占位符，将被替换)
- **代理组**：预定义的策略组，节点会自动添加到这些组中
- **规则集**：流量分流规则

#### Surge模版 (surge.conf)
- **[General]**：基础配置
- **[Proxy]**：代理节点部分
- **[Proxy Group]**：代理组配置
- **[Rule]**：分流规则

### 优势特点

1. **模版与节点分离**：便于维护和更新
2. **多协议支持**：支持主流代理协议
3. **灵活配置**：支持本地和远程模版
4. **智能合并**：选择性地将节点添加到特定代理组
5. **实时生成**：访问时动态生成配置

### 🎯 智能代理组选择策略

为了避免向所有代理组添加节点（这会导致配置冗余和管理困难），系统采用了关键词匹配策略：

#### 选择规则
1. **关键词匹配**：通过代理组名称中的关键词来判断
2. **类型过滤**：自动跳过链式代理（`relay` 类型）
3. **精准识别**：只向真正需要节点的代理组添加

#### 匹配关键词
系统会检查代理组名称是否包含以下关键词：
- `节点选择` - 手动选择类代理组
- `自动选择` - 自动测速类代理组
- `手动切换` - 手动切换类代理组

#### 支持的代理组名称示例
- `🔰 节点选择` ✅
- `♻️ 自动选择` ✅
- `🚀 手动切换` ✅
- `Proxy 节点选择` ✅
- `Auto 自动选择` ✅

#### 排除的代理组
系统会自动跳过以下类型的代理组：
- 功能性代理组：`🎥 NETFLIX`、`📲 电报消息`、`🌍 国外媒体`
- 策略性代理组：`⛔️ 广告拦截`、`🎯 全球直连`
- 链式代理组：`type: relay`

#### 配置示例
```yaml
proxy-groups:
  - name: 🔰 节点选择    # ✅ 包含"节点选择"关键词，会添加节点
    type: select
    proxies:
      - ♻️ 自动选择
      - 🎯 全球直连
      # 节点会自动添加到这里

  - name: ♻️ 自动选择    # ✅ 包含"自动选择"关键词，会添加节点
    type: url-test
    url: http://www.gstatic.com/generate_204
    interval: 300
    proxies:
      - DIRECT
      # 节点会自动添加到这里

  - name: 🚀 手动切换    # ✅ 包含"手动切换"关键词，会添加节点
    type: select
    proxies: []
    # 节点会自动添加到这里

  - name: 🎥 NETFLIX     # ❌ 不包含关键词，不会添加节点
    type: select
    proxies:
      - 🔰 节点选择      # 通过引用获得节点
      - ♻️ 自动选择
      - 🎯 全球直连
```

这种设计的优势：
- **精准匹配**：只向真正需要节点的代理组添加节点
- **减少冗余**：避免在功能性代理组中重复添加节点
- **灵活扩展**：支持任意数量的符合条件的代理组
- **易于理解**：通过关键词就能判断哪些组会添加节点

## [技术实现细节]

### API接口设计

#### 订阅管理接口
```go
// 路由定义
SubcriptionGroup := r.Group("/api/v1/subcription")
{
    SubcriptionGroup.POST("/add", api.SubAdd)        // 添加订阅
    SubcriptionGroup.DELETE("/delete", api.SubDel)   // 删除订阅
    SubcriptionGroup.GET("/get", api.SubGet)         // 获取订阅列表
    SubcriptionGroup.POST("/update", api.SubUpdate)  // 更新订阅
}
```

#### 节点管理接口
```go
// 节点相关API
NodeGroup := r.Group("/api/v1/node")
{
    NodeGroup.POST("/add", api.NodeAdd)              // 添加节点
    NodeGroup.DELETE("/delete", api.NodeDel)         // 删除节点
    NodeGroup.GET("/get", api.NodeGet)               // 获取节点列表
    NodeGroup.POST("/update", api.NodeUpdate)        // 更新节点
}
```

#### 模版管理接口
```go
// 模版相关API
TemplateGroup := r.Group("/api/v1/template")
{
    TemplateGroup.POST("/add", api.TempAdd)          // 添加模版
    TemplateGroup.DELETE("/delete", api.TempDel)     // 删除模版
    TemplateGroup.GET("/get", api.TempGet)           // 获取模版列表
    TemplateGroup.POST("/update", api.TempUpdate)    // 更新模版
}
```

### 数据库设计

#### 多对多关系
```go
// 订阅与节点的多对多关系
type Subcription struct {
    Nodes []Node `gorm:"many2many:subcription_nodes;"`
}

// 节点与分组的多对多关系
type Node struct {
    GroupNodes []GroupNode `gorm:"many2many:group_node_nodes"`
}
```

#### 关联查询
```go
// 预加载关联数据
models.DB.Model(sub).Preload("Nodes").Find(&sub)
```

### 节点链接格式支持

#### Shadowsocks格式
```
ss://base64(method:password)@hostname:port#name
```

#### VMess格式
```json
{
    "v": "2",
    "ps": "节点名称",
    "add": "服务器地址",
    "port": "端口",
    "id": "UUID",
    "aid": "额外ID",
    "net": "传输协议",
    "type": "伪装类型",
    "host": "伪装域名",
    "path": "路径",
    "tls": "TLS"
}
```

#### Trojan格式
```
trojan://password@hostname:port?sni=domain&type=tcp#name
```

### 配置生成算法

#### Clash配置合并算法
1. **解析YAML结构**：使用yaml.Unmarshal解析模版
2. **节点转换**：将各协议节点转换为Clash格式
3. **代理组更新**：遍历所有代理组，添加新节点
4. **配置重组**：使用yaml.Marshal生成最终配置

#### Surge配置合并算法
1. **正则匹配**：使用正则表达式定位配置段
2. **文本替换**：直接进行字符串替换操作
3. **格式化输出**：保持原有格式结构

### 错误处理机制

#### 节点解析错误处理
```go
for _, link := range urls {
    Scheme := strings.Split(link, "://")[0]
    switch {
    case Scheme == "ss":
        ss, err := DecodeSSURL(link)
        if err != nil {
            log.Println(err)
            continue  // 跳过错误节点，继续处理其他节点
        }
    }
}
```

#### 模版文件错误处理
```go
// 本地文件读取错误
data, err = os.ReadFile(yamlfile)
if err != nil {
    log.Printf("error: %v", err)
    return nil, err
}

// 远程文件获取错误
resp, err := http.Get(yamlfile)
if err != nil {
    log.Println("http.Get error", err)
    return nil, err
}
```

### 性能优化

#### 缓存机制
- 模版文件缓存：避免重复读取
- 节点解析缓存：缓存解析结果
- 配置生成缓存：缓存最终配置

#### 并发处理
- 多节点并发解析
- 异步配置生成
- 连接池复用

### 安全特性

#### 路径安全验证
```go
func safeFilePath(filename string) (string, error) {
    // 验证文件路径，防止目录遍历攻击
    if strings.Contains(filename, "..") {
        return "", errors.New("unsafe file path")
    }
    return filepath.Join("./template", filename), nil
}
```

#### 输入验证
- 节点链接格式验证
- 模版文件类型验证
- 用户权限验证

## [使用示例]

### 1. 创建节点
```bash
curl -X POST http://localhost:8000/api/v1/node/add \
  -F "name=测试节点" \
  -F "link=ss://YWVzLTI1Ni1nY206cGFzc3dvcmQ@example.com:8388#测试节点"
```

### 2. 创建订阅
```bash
curl -X POST http://localhost:8000/api/v1/subcription/add \
  -F "name=我的订阅" \
  -F "nodes=测试节点" \
  -F 'config={"clash":"./template/clash.yaml","surge":"./template/surge.conf","udp":true,"cert":false}'
```

### 3. 获取配置
```bash
# 获取Clash配置
curl http://localhost:8000/clash/我的订阅

# 获取Surge配置
curl http://localhost:8000/surge/我的订阅

# 获取V2Ray配置
curl http://localhost:8000/v2ray/我的订阅
```

### 4. 前端集成示例
```javascript
// 添加订阅
const addSubscription = async () => {
    const config = JSON.stringify({
        clash: selectedClashTemplate,
        surge: selectedSurgeTemplate,
        udp: enableUDP,
        cert: skipCertVerify
    });

    await AddSub({
        name: subscriptionName,
        nodes: selectedNodes.join(','),
        config: config
    });
};

// 获取订阅链接
const getSubscriptionUrl = (subName, clientType) => {
    const baseUrl = 'http://localhost:8000';
    return `${baseUrl}/${clientType}/${encodeURIComponent(subName)}`;
};
```

## [项目预览]

![1712594176714](webs/src/assets/1.png)
![1712594176714](webs/src/assets/2.png)

## [部署指南]

### 环境要求
- Go 1.22.0+
- Node.js 16+
- SQLite3 (默认) 或 MySQL/PostgreSQL

### 编译部署
```bash
# 克隆项目
git clone https://github.com/moshouhot/sublinkX.git
cd sublinkX

# 编译前端
cd webs
npm install
npm run build

# 编译后端
cd ..
go mod tidy
go build -o sublinkx main.go

# 运行
./sublinkx
```

### Docker部署
```bash
# 使用Docker Compose
docker-compose up -d

# 或直接运行
docker run --name sublinkx -p 8000:8000 \
  -v $PWD/db:/app/db \
  -v $PWD/template:/app/template \
  -v $PWD/logs:/app/logs \
  -d jaaksi/sublinkx
```

### 配置说明
```yaml
# config.yaml
server:
  port: 8000
  host: "0.0.0.0"

database:
  type: "sqlite"
  dsn: "./db/sublinkx.db"

template:
  path: "./template"

log:
  level: "info"
  path: "./logs"
```

## [故障排除]

### 常见问题

#### 1. 节点解析失败
**问题**：节点链接无法正确解析
**解决方案**：
- 检查节点链接格式是否正确
- 确认协议类型是否支持
- 查看日志获取详细错误信息

```bash
# 查看日志
tail -f logs/sublinkx.log
```

#### 2. 模版文件读取失败
**问题**：无法读取模版文件
**解决方案**：
- 确认模版文件路径正确
- 检查文件权限
- 验证YAML/配置文件格式

```bash
# 检查模版文件
ls -la template/
cat template/clash.yaml | head -20
```

#### 3. 配置生成错误
**问题**：生成的配置文件格式错误
**解决方案**：
- 检查模版文件结构
- 确认节点信息完整
- 验证代理组配置

#### 4. 数据库连接问题
**问题**：数据库连接失败
**解决方案**：
```bash
# 检查数据库文件
ls -la db/
sqlite3 db/sublinkx.db ".tables"

# 重新初始化数据库
rm db/sublinkx.db
./sublinkx  # 自动创建新数据库
```

### 调试模式
```bash
# 启用调试模式
export DEBUG=true
./sublinkx

# 或设置日志级别
export LOG_LEVEL=debug
./sublinkx
```

### 性能监控
```bash
# 查看系统资源使用
top -p $(pgrep sublinkx)

# 查看网络连接
netstat -tlnp | grep 8000

# 查看日志统计
grep "ERROR" logs/sublinkx.log | wc -l
```

## [开发指南]

### 项目结构
```
sublinkX/
├── api/              # API接口层
│   ├── auth.go      # 认证相关
│   ├── clients.go   # 客户端配置生成
│   ├── node.go      # 节点管理
│   ├── sub.go       # 订阅管理
│   └── template.go  # 模版管理
├── models/          # 数据模型层
│   ├── node.go      # 节点模型
│   ├── subcription.go # 订阅模型
│   └── sqlite.go    # 数据库配置
├── node/            # 节点处理层
│   ├── clash.go     # Clash配置生成
│   ├── surge.go     # Surge配置生成
│   ├── common.go    # 通用函数
│   └── *.go         # 各协议解析
├── routers/         # 路由层
├── middlewares/     # 中间件
├── template/        # 配置模版
├── webs/           # 前端代码
└── main.go         # 入口文件
```

### 添加新协议支持

#### 1. 定义协议结构
```go
// node/newprotocol.go
type NewProtocol struct {
    Server   string
    Port     int
    Password string
    // 其他协议特定字段
}
```

#### 2. 实现解析函数
```go
func DecodeNewProtocolURL(link string) (*NewProtocol, error) {
    // 解析协议链接
    // 返回结构化数据
}
```

#### 3. 添加到主处理流程
```go
// node/clash.go 或 node/surge.go
case Scheme == "newprotocol":
    np, err := DecodeNewProtocolURL(link)
    if err != nil {
        log.Println(err)
        continue
    }
    // 转换为对应客户端格式
```

### 自定义模版

#### Clash模版要求
- 必须包含 `proxies: ~` 占位符
- 代理组中的 `proxies` 字段会自动填充节点
- 保持YAML格式正确性

#### Surge模版要求
- 必须包含 `[Proxy]` 和 `[Proxy Group]` 段
- 代理组配置行必须包含 `=` 符号
- 保持INI格式正确性

### API扩展示例
```go
// 添加新的API端点
func CustomHandler(c *gin.Context) {
    // 自定义处理逻辑
    c.JSON(200, gin.H{
        "code": "00000",
        "data": result,
        "msg":  "success",
    })
}

// 注册路由
r.GET("/api/v1/custom", CustomHandler)
```

## [贡献指南]

### 提交代码
1. Fork 项目
2. 创建特性分支
3. 提交更改
4. 发起 Pull Request

### 代码规范
- 遵循 Go 官方代码规范
- 添加必要的注释
- 编写单元测试
- 更新相关文档

### 问题反馈
- 使用 GitHub Issues 报告问题
- 提供详细的错误信息和日志
- 描述复现步骤

## [快速安装]

### 🚀 一键安装/更新

无论是首次安装还是更新，都可以使用同一条命令：

```bash
curl -s https://raw.githubusercontent.com/moshouhot/sublinkX/main/install.sh | sudo bash
```

脚本会自动：
- ✅ 检测系统架构 (x86_64 / ARM64)
- ✅ 检测是首次安装还是更新
- ✅ 下载对应版本的二进制文件
- ✅ 配置 systemd 服务并启动
- ✅ 安装管理菜单（输入 `sublink` 呼出）

**默认信息**：
- 账号：`admin` 密码：`123456`
- 端口：`8000`
- 管理菜单：运行 `sublink` 命令

> ℹ️ **注意**：更新时不会影响现有数据，`db/`、`template/`、`logs/` 目录中的文件会保留。

---

### 🐳 Docker 快速部署
```bash
# 创建工作目录
mkdir sublinkx && cd sublinkx

# 运行容器
docker run --name sublinkx -p 8000:8000 \
  -v $PWD/db:/app/db \
  -v $PWD/template:/app/template \
  -v $PWD/logs:/app/logs \
  -d jaaksi/sublinkx
```

**重要文件备份**：
- `db/` - 数据库文件
- `template/` - 配置模版文件
- `logs/` - 日志文件

## [更新日志]

### v2.3 更新内容

#### 🚀 性能优化
- **模版列表 API 优化**：列表与内容分离，响应速度从 49 秒优化到毫秒级
- **按需加载**：编辑模版时才获取内容，减少服务器负载
- **新增 API**：`/api/v1/template/content` 用于获取单个模版内容

#### 🐛 问题修复
- 修复模版列表显示“暂无数据”的问题（API 超时导致）

### v2.2 更新内容

#### 🎉 新功能
- **智能代理组选择**：只向包含特定关键词的代理组添加节点
- **关键词匹配**：支持`节点选择`、`自动选择`、`手动切换`关键词识别
- **无数量限制**：支持任意数量的符合条件的代理组

#### 🔧 核心优化
- 简化代理组合并逻辑，减少配置冗余
- 优化节点分配策略，提高配置生成效率
- 改进代码结构，增强可维护性

#### 📦 部署改进
- 新增GitHub Actions自动编译
- 支持多平台二进制文件生成（Linux/Windows/macOS）
- 优化一键安装脚本

### v2.1 更新内容

#### 后端优化
- 修复底层代码架构问题
- 解决多个已知Bug
- 优化数据库结构（建议备份后重新初始化）

#### 前端改进
- 完善节点管理页面
- 优化用户交互体验
- 修复界面显示问题

## [许可证]

本项目采用 MIT 许可证，详见 [LICENSE](LICENSE) 文件。

## Stargazers over time
[![Stargazers over time](https://starchart.cc/moshouhot/sublinkX.svg?variant=adaptive)](https://starchart.cc/moshouhot/sublinkX)

