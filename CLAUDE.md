# CLAUDE.md — VoxCPM App

VoxCPM2 语音合成 App：**iOS(SwiftUI) 前端 + FastAPI 后端**。后端封装 `pip install voxcpm`，模型跑在后端机器上（不是手机）。
GitHub: https://github.com/WadeZhao23/voxcpm-ios （public, Apache-2.0）
最后更新：2026-05-30

## 架构
- iOS 前端通过 HTTP 调后端；后端用 VoxCPM2 合成，返回 `audio/wav`。
- 三种能力共用 `model.generate()`，仅参数不同：
  - 朗读 = 直接传 text
  - 声音设计 = `text` 形如 `(描述)正文`
  - 克隆 = 传 `reference_wav_path`（可叠加 `(控制指令)` 调风格）
- VoxCPM2 = 2B 模型、约 8GB 运行内存，**手机带不动** → 必须前后端分离。

## 目录
- `server/` — `main.py`(FastAPI 路由) + `voxcpm_engine.py`(懒加载 + 串行推理封装) + `requirements.txt` + `.env.example`
- `ios/` — `project.yml`(XcodeGen) + `VoxCPMApp/{Theme,Components,Views,Networking,Audio,Resources}`

## 后端：启动与约定
- venv 在 `server/.venv`（Python 3.11，已 gitignore）。
- 启动命令：
  ```bash
  cd server && VOXCPM_DEVICE=auto VOXCPM_OPTIMIZE=false VOXCPM_LOAD_DENOISER=false \
    .venv/bin/uvicorn main:app --host 0.0.0.0 --port 8008
  ```
- ⚠️ **端口 8000 已被本机另一个项目的后端占用 → 本项目固定用 8008（别动 8000）。** 换机器部署时按需调整。
- 模型缓存在 `~/.cache/huggingface`（VoxCPM2 约 4.6G）。首次请求触发下载+加载（加载约 1 分钟），之后不重下。
- 本机 16GB 内存偏紧；嫌卡可 `VOXCPM_DEVICE=cpu`（更慢更稳）或换轻量版 `VOXCPM_MODEL_ID=openbmb/VoxCPM1.5`（会丢声音设计+多语言）。
- 环境变量：`VOXCPM_MODEL_ID`(默认 openbmb/VoxCPM2) / `VOXCPM_DEVICE`(auto|cpu|mps|cuda) / `VOXCPM_OPTIMIZE`(Mac 上 false) / `VOXCPM_LOAD_DENOISER`(false)。

## 后端：API
| 方法 | 路径 | 说明 |
|---|---|---|
| GET | `/` | 服务信息 + 接口清单 |
| GET | `/health` | 健康检查 |
| GET | `/api/info` | `{model_id, device, loaded, sample_rate}`（loaded=true 即模型就绪，sample_rate=48000） |
| POST | `/api/tts` | JSON：`text`, `cfg_value`(2.0), `inference_timesteps`(10), `normalize`(false) |
| POST | `/api/design` | JSON：`text`, `description`, `cfg_value`, `inference_timesteps` |
| POST | `/api/clone` | multipart：`text`, `reference_audio`(文件), `control`(可选), `cfg_value`, `inference_timesteps` |

合成接口返回 `audio/wav`。

## iOS：构建与约定
- **`.xcodeproj` 和 `Info.plist` 由 xcodegen 从 `project.yml` 生成，不入库** → 改完任何 iOS 文件/配置后先 `cd ios && xcodegen generate`。
- 命令行构建（本机 `xcode-select` 指向 CommandLineTools，需临时指向 Xcode，免 sudo）：
  ```bash
  DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild build \
    -project VoxCPMApp.xcodeproj -scheme VoxCPMApp \
    -destination 'generic/platform=iOS Simulator' -configuration Debug CODE_SIGNING_ALLOWED=NO
  ```
- 部署目标 **iOS 17**。签名：自动，Team `4JG5RQJXV4`，Bundle ID `com.wadezhao23.voxcpm`。
- 真机：手机与 Mac 同一 WiFi，App「设置」页填 `http://<Mac局域网IP>:8008`（IP 用 `ipconfig getifaddr en0` 查）。模拟器可用 `http://localhost:8008`。
- ATS 已放开明文 HTTP（`NSAllowsArbitraryLoads`）、麦克风权限 `NSMicrophoneUsageDescription` 在 `project.yml` 的 info 里。

## 设计系统（Ego 风格）
- **来源：复刻自本机另一个 iOS 工程（Ego，健康类 App）的设计系统**（设计 token + OPPO Sans 字体）。
- token 在 `ios/VoxCPMApp/Theme/`（AppColor / AppTheme / Color+Hex / Font+App），复用组件在 `ios/VoxCPMApp/Components/`。
- 主色靛蓝 `#3C4FC1`、页面底薄荷 `#EFF7F3`、主文字 `#2F3337`、次文字 `#9AA09F`。
- 字体 OPPO Sans 5 字重，统一经 `Font.app(size:weight:)`（5 个独立 family，不能 `.weight()` 派生）；ttf 在 `Resources/Fonts/`（~33MB，**已入库**），`UIAppFonts` 在 project.yml 注册。
- 圆角 16/20/24 continuous，浮动胶囊 TabBar，招牌弹簧 `spring(response:0.32, dampingFraction:0.86)`。

## 红线
- 别动端口 8000（Ego 后端）。
- 改 iOS 文件后必须 `xcodegen generate` 再构建，否则新文件不进工程。
- 仅原型：后端无鉴权、ATS 放开明文 HTTP，**勿直接上线**。
- 上游 VoxCPM clone 在 `../VoxCPM`（只读参考，别改）。
- 声音克隆涉及合规：仅克隆获授权的声音，标注 AI 生成。
