# Vicinae 项目编译依赖完整分析报告

## 依赖结构总览图

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              Vicinae 应用                                        │
│                         (vicinae/src/)                                          │
└─────────────────────────────────────────────────────────────────────────────────┘
                                      │
           ┌──────────────────────────┼──────────────────────────┐
           ▼                          ▼                          ▼
┌─────────────────────┐   ┌─────────────────────┐   ┌─────────────────────────────┐
│  Qt6 框架 (必需)     │   │  内部库 (lib/)       │   │  TypeScript 扩展系统         │
├─────────────────────┤   ├─────────────────────┤   ├─────────────────────────────┤
│ • Qt6::Core         │   │ • xdgpp             │   │ • extension-manager         │
│ • Qt6::Widgets      │   │ • emoji → ICU       │   │   └─ @vicinae/api           │
│ • Qt6::Sql          │   │ • script-command    │   │   └─ raycast-api-compat     │
│ • Qt6::Network      │   │   └─ glaze          │   │ • Node.js ≥18               │
│ • Qt6::Svg          │   │ • vicinae-ipc       │   │ • React 19.0.0              │
│ • Qt6::DBus         │   │   └─ glaze          │   │ • react-reconciler 0.32.0   │
│ • Qt6::Concurrent   │   │ • browser-extension │   │ • esbuild                   │
│ • Qt6::WaylandClient│   │   └─ glaze          │   │ • typescript ^5             │
└─────────────────────┘   │   └─ vicinae-ipc    │   └─────────────────────────────┘
                          └─────────────────────┘
           ┌──────────────────────────┼──────────────────────────┐
           ▼                          ▼                          ▼
┌─────────────────────┐   ┌─────────────────────┐   ┌─────────────────────────────┐
│  IPC & 序列化        │   │  安全 & 密钥         │   │  Wayland & X11              │
├─────────────────────┤   ├─────────────────────┤   ├─────────────────────────────┤
│ • Protobuf v32.0    │   │ • OpenSSL           │   │ • wayland-client            │
│   └─ Abseil 20250814│   │ • qt-keychain 0.14  │   │ • wayland-protocols         │
│ • glaze (JSON)      │   │   └─ libsecret      │   │ • layer-shell-qt            │
│ • LibXml2           │   │                     │   │ • xkbcommon                 │
│ • cmark-gfm 0.29    │   │                     │   │ • X11/XCB                   │
└─────────────────────┘   └─────────────────────┘   └─────────────────────────────┘
           │                                                      │
           ▼                                                      ▼
┌─────────────────────┐                               ┌─────────────────────────────┐
│  其他功能库          │                               │  可选功能                    │
├─────────────────────┤                               ├─────────────────────────────┤
│ • ICU (Unicode)     │                               │ • libqalculate (计算器)      │
│ • minizip (压缩)    │                               │ • Catch2 3 (测试)           │
└─────────────────────┘                               └─────────────────────────────┘
```

---

## 一、C++ 核心依赖详细清单

### 1.1 Qt6 框架依赖

| 组件 | 版本要求 | 必需性 | 用途 |
|------|---------|--------|------|
| Qt6::Core | ≥6.2 | 必需 | 核心库 |
| Qt6::Widgets | - | 必需 | UI 控件和窗口管理 |
| Qt6::Sql | - | 必需 | 数据库 (剪贴板、设置、索引) |
| Qt6::Network | - | 必需 | 网络通信 (OAuth、favicon) |
| Qt6::Svg | - | 必需 | SVG 图像渲染 |
| Qt6::DBus | - | 必需 | D-Bus 通信 (GNOME) |
| Qt6::Concurrent | - | 必需 | 线程池和异步任务 |
| Qt6::WaylandClient | - | 可选 | Wayland 集成 |

### 1.2 Protocol Buffers & 序列化

| 依赖 | 版本 | 构建方式 | 用途 |
|------|------|---------|------|
| Protobuf | v32.0 | 系统/FetchContent | IPC 序列化 |
| Abseil | 20250814.0 | 系统/FetchContent | Protobuf 依赖 |
| glaze | b64f4a68 | FetchContent | 高性能 JSON |
| cmark-gfm | 0.29.0.gfm.13 | 系统/FetchContent | Markdown 渲染 |
| LibXml2 | - | 系统 | XML 解析 |

### 1.3 安全与密钥存储

| 依赖 | 版本 | 用途 |
|------|------|------|
| OpenSSL | - | 密码学操作 |
| qt-keychain | v0.14.0 | 系统密钥管理 |
| libsecret | - | qt-keychain 依赖 |

### 1.4 Wayland & X11 支持

| 依赖 | 用途 |
|------|------|
| wayland-client | Wayland 客户端 |
| wayland-protocols | Wayland 协议定义 |
| layer-shell-qt | Layer Shell 支持 |
| xkbcommon | 键盘布局处理 |
| X11::xcb | X11 窗口管理 |

### 1.5 其他库

| 依赖 | 用途 |
|------|------|
| ICU | Unicode/国际化 (emoji) |
| minizip | ZIP 压缩/解压 |
| libqalculate | 高级计算器后端 (可选) |

---

## 二、内部库依赖关系图

```
┌─────────────────────────────────────────────────────┐
│                     vicinae (主应用)                 │
└─────────────────────────────────────────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        ▼                   ▼                   ▼
┌───────────────┐   ┌───────────────┐   ┌───────────────┐
│    xdgpp      │   │    emoji      │   │ script-command│
│  (XDG 规范)   │   │  (表情符号)    │   │  (脚本命令)   │
│               │   │               │   │               │
│ 依赖: 无      │   │ 依赖: ICU     │   │ 依赖: glaze   │
│ C++26 标准    │   │ C++23 标准    │   │ C++23 标准    │
└───────────────┘   └───────────────┘   └───────────────┘
                                                │
                                                ▼
                                        ┌───────────────┐
                                        │  vicinae-ipc  │
                                        │   (IPC 库)    │
                                        │               │
                                        │ 依赖: glaze   │
                                        │ C++23 标准    │
                                        └───────────────┘
                                                │
                                                ▼
                                        ┌───────────────┐
                                        │browser-extension│
                                        │ (浏览器扩展)   │
                                        │               │
                                        │依赖: glaze    │
                                        │     vicinae-ipc│
                                        │ C++23 标准    │
                                        └───────────────┘
```

---

## 三、TypeScript 依赖关系图

```
┌─────────────────────────────────────────────────────────────────┐
│                    extension-manager                             │
│                    (扩展管理进程)                                 │
├─────────────────────────────────────────────────────────────────┤
│ 生产依赖:                                                        │
│   • @vicinae/api (file:../api)                                  │
│   • @vicinae/raycast-api-compat (file:../raycast-api-compat)    │
│   • react-reconciler 0.32.0                                     │
│ 开发依赖:                                                        │
│   • @biomejs/biome 2.3.2, typescript ^5.8.2                     │
│   • @bufbuild/protobuf ^2.7.0, ts-proto ^2.7.5                  │
│   • esbuild ^0.25.9, nodemon ^3.1.10                            │
└─────────────────────────────────────────────────────────────────┘
                            │
            ┌───────────────┴───────────────┐
            ▼                               ▼
┌─────────────────────────┐     ┌─────────────────────────────────┐
│     @vicinae/api        │     │  @vicinae/raycast-api-compat    │
│     (核心 SDK)          │     │     (Raycast 兼容层)            │
├─────────────────────────┤     ├─────────────────────────────────┤
│ 生产依赖:               │     │ 生产依赖:                        │
│   • react 19.0.0        │◄────│   • @vicinae/api (file:../api)  │
│   • zod ^4.0.17         │     │ 开发依赖:                        │
│   • @oclif/core ^4      │     │   • @raycast/api ^1.103.6       │
│   • esbuild ^0.25.2     │     │   • typescript ^5.9.2           │
│   • chokidar ^4.0.3     │     └─────────────────────────────────┘
│ 开发依赖:               │
│   • typescript ^5       │
│   • ts-proto ^2.7.5     │
│   • @biomejs/biome 2.3.2│
│   • mocha ^10, chai ^4  │
└─────────────────────────┘
```

### TypeScript 版本锁定策略

| 包名 | 锁定版本 | 说明 |
|------|---------|------|
| react | 19.0.0 | React 核心 |
| @types/react | 19.0.10 | React 类型 |
| react-reconciler | 0.32.0 | 渲染引擎 |
| @types/react-reconciler | 0.32.1 | 类型定义 |
| @biomejs/biome | 2.3.2 | 格式化工具 |

---

## 四、CMake 构建选项与依赖关系

| 选项 | 默认值 | 影响的依赖 |
|------|--------|----------|
| `USE_SYSTEM_PROTOBUF` | ON | 系统 Protobuf vs FetchContent v32.0 |
| `USE_SYSTEM_ABSEIL` | ON | 系统 Abseil vs FetchContent 20250814.0 |
| `USE_SYSTEM_CMARK_GFM` | ON | 系统 cmark-gfm vs FetchContent 0.29.0.gfm.13 |
| `USE_SYSTEM_LAYER_SHELL` | ON | 系统 layer-shell-qt vs FetchContent |
| `USE_SYSTEM_GLAZE` | OFF | 始终 FetchContent (header-only) |
| `USE_SYSTEM_QT_KEYCHAIN` | ON | 系统 qtkeychain vs FetchContent v0.14.0 |
| `LIBQALCULATE_BACKEND` | ON | 启用 libqalculate 计算器 |
| `WAYLAND_LAYER_SHELL` | ON | 启用 Wayland layer-shell |
| `TYPESCRIPT_EXTENSIONS` | ON | 启用 Node.js/TypeScript 扩展 |
| `BUILD_TESTS` | OFF | 启用 Catch2 测试框架 |
| `PREFER_STATIC_LIBS` | OFF | 强制静态链接 |

---

## 五、系统包依赖 (Ubuntu 22.04)

### 必需包

```bash
# 构建工具
build-essential cmake ninja-build pkg-config git

# Qt6
qt6-base-dev qt6-wayland-dev libqt6svg6-dev libqt6sql6-sqlite

# Protocol Buffers
libprotobuf-dev protobuf-compiler libabsl-dev

# Markdown
libcmark-gfm-dev libcmark-gfm-extensions-dev

# 密钥存储
qtkeychain-qt6-dev libsecret-1-dev

# Wayland/X11
libwayland-dev wayland-protocols
libx11-dev libxcb1-dev libxkbcommon-dev

# 其他
libssl-dev libxml2-dev libminizip-dev libicu-dev
libgl-dev libegl-dev

# Node.js
nodejs npm
```

### 可选包

```bash
# 计算器后端
libqalculate-dev libgmp3-dev libmpfr-dev libcurl4-openssl-dev

# 加速工具
ccache mold
```

---

## 六、Proto 协议文件 (13个)

```
proto/
├── common.proto          # 通用消息类型
├── ipc.proto             # IPC 核心协议
├── command.proto         # 命令定义
├── extension.proto       # 扩展接口
├── manager.proto         # 扩展管理器
├── clipboard.proto       # 剪贴板服务
├── storage.proto         # 存储服务
├── oauth.proto           # OAuth 服务
├── file-search.proto     # 文件搜索
├── wlr-clipboard.proto   # Wayland 剪贴板
├── wm.proto              # 窗口管理
├── ui.proto              # UI 通信
└── application.proto     # 应用服务
```

---

## 七、版本汇总表

### C++ 依赖版本

| 依赖 | FetchContent 版本 | 备注 |
|------|------------------|------|
| Protobuf | v32.0 | 固定 |
| Abseil | 20250814.0 | 固定 |
| cmark-gfm | 0.29.0.gfm.13 | 固定 |
| qt-keychain | v0.14.0 | 固定 |
| glaze | b64f4a68... | commit hash |
| layer-shell-qt | master | vicinaehq fork |

### 工具链要求

| 工具 | 最低版本 | 推荐版本 |
|------|---------|---------|
| GCC | 13+ | 15+ |
| CMake | 3.16 | 4.0+ |
| Node.js | 18 | 20+ |
| Qt6 | 6.2 | 6.10+ |

---

## 八、AppImage 构建依赖 (完整清单)

### 8.1 基础构建环境

| 组件 | 说明 |
|------|------|
| 基础镜像 | Ubuntu 22.04 (兼容 Debian 12/Ubuntu 24.04) |
| 构建系统 | CMake + Ninja |
| Node.js | 用于 TypeScript 扩展 |

### 8.2 自编译依赖库

AppImage 构建通常需要自编译以下库以确保兼容性:

- **Qt6**: 自编译确保功能完整
- **Protobuf**: 版本控制
- **libqalculate**: 计算器后端
- **cmark-gfm**: Markdown 渲染
- **minizip-ng**: 压缩支持
- **layer-shell-qt**: Wayland layer shell
- **fcitx5**: 输入法支持 (可选)

### 8.3 部署工具

| 工具 | 用途 |
|------|------|
| linuxdeploy | AppImage 打包 |
| linuxdeploy-plugin-qt | Qt 库自动处理 |
| squashfs-tools | SquashFS 打包 |

### 8.4 AppImage 包含的运行时组件

```
AppImage 内容结构:
├── usr/
│   ├── bin/
│   │   ├── vicinae              # 主程序
│   │   └── node                 # Node.js
│   ├── lib/
│   │   ├── libQt6*.so*          # Qt6 动态库
│   │   ├── libprotobuf.so*      # Protobuf
│   │   ├── libqalculate.so*     # 计算器
│   │   └── libssl.so*           # OpenSSL
│   ├── plugins/
│   │   ├── platforms/           # Qt 平台插件
│   │   ├── wayland*/            # Wayland 插件
│   │   └── sqldrivers/          # SQLite 驱动
│   └── share/
│       ├── vicinae/
│       │   └── themes/          # 主题文件
│       └── applications/
│           └── vicinae.desktop  # 桌面文件
└── AppRun                       # 启动脚本
```

---

## 验证步骤

1. **检查系统依赖**: `cmake -B build -G Ninja` 会报告缺失依赖
2. **检查 TypeScript**: `cd typescript/api && npm install` 验证 Node 依赖
3. **完整构建测试**: `make release` 验证所有依赖正确安装
