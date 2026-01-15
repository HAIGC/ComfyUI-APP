# ComfyAI（ComfyController）

一个基于 Android（Jetpack Compose）的 ComfyUI 移动端控制器：用于连接 ComfyUI 服务、提交工作流到队列、查看执行与产物，并提供“AI 应用”工作流入口与本地画廊管理。

## 功能特性

- 连接 ComfyUI 服务（默认端口 8188），支持 HTTP/HTTPS 与 WebSocket/WSS
- 提交工作流到队列、查看队列与历史、支持中断/清理等控制能力
- “AI 应用”管理：应用卡片封面/标题、本地排序、应用详情参数编辑与运行
- 画廊：本地分类管理、对生成媒体进行归类/查看
- 后台保活：前台服务维持连接，降低退到后台后掉线概率

## 技术栈

- UI：Jetpack Compose + Material 3 + Navigation Compose
- 网络：Retrofit2 + OkHttp（含 WebSocket）
- 图片/视频预览：Coil（coil-compose / coil-video）
- 其他：Gson、Kotlin Coroutines / Flow

## 环境要求

- Android：minSdk 26（Android 8.0+），targetSdk 34
- Android Studio（推荐）或 Windows 下使用仓库自带脚本构建

## 快速开始

### 1) 准备 ComfyUI

确保你的 ComfyUI 服务可被手机访问：

- 服务端监听 `0.0.0.0` 或局域网 IP（而不是仅 `127.0.0.1`）
- 放行端口（默认 8188）
- 如果使用反向代理/HTTPS，确保 WebSocket 也可用（WSS）

### 2) 在手机端配置连接

在应用的设置/连接页面填写：

- 地址：服务器 IP 或域名
- 端口：默认 `8188`
- 协议：HTTP/HTTPS（若是域名证书场景用 HTTPS）

### 3) 构建与安装（Android Studio）

1. 用 Android Studio 打开本项目根目录 `ComfyController/`
2. 等待 Gradle Sync 完成
3. 选择 `app` 模块，运行或打包：
   - 运行到设备：Run
   - 生成 Debug APK：`Build > Build Bundle(s) / APK(s) > Build APK(s)`

### 4) 构建 Debug APK（Windows 脚本）

仓库提供两种方式：

- 一键配置环境并构建（会下载 JDK/Android SDK/组件）：

  ```powershell
  powershell -ExecutionPolicy Bypass -File .\auto_build.ps1
  ```

- 使用本地构建器（依赖 `.build_env` 已存在）：

  ```bat
  .\build_apk.bat
  ```

构建完成后，`ComfyController.apk` 会被复制到仓库根目录。

## 目录结构

```text
app/src/main/java/com/example/comfycontroller/
  data/            数据层（Repository、DI）
  network/         Retrofit API 与 WebSocket 管理
  model/           数据模型
  ui/
    screens/       各页面（控制台、控制器、AI应用、画廊、设置等）
    theme/         主题与配色
  KeepAliveService.kt  后台保活服务
```

## 常见问题

- 连接不上服务端：
  - 确认服务端不是只绑定 `127.0.0.1`
  - 手机与服务端是否同一网络、端口是否放行
  - HTTPS/WSS 场景下证书是否有效
- 画面/媒体看不到：
  - 确认 ComfyUI 的 `view` 接口可用
  - 若使用反向代理，确保 `view`/`history`/`queue`/`prompt` 路由完整转发

## 许可证

仓库当前未提供 `LICENSE` 文件；如需开源许可证，请自行补充并在 README 中说明。

## 联系方式

- 微信：HAIGC1994

