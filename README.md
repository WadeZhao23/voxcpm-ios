# VoxCPM App（iOS 前端 + Python 后端原型）

把 [OpenBMB VoxCPM2](https://github.com/OpenBMB/VoxCPM) 封装成本地 HTTP 服务，配一个 iOS App 前端，支持三种能力：

- 🌍 **多语言朗读** — 输入文本直接合成（30 语种，无需语言标签）
- 🎙️ **声音克隆** — 录制 / 上传一段参考音频，克隆其音色
- 🎨 **声音设计** — 用一句话描述凭空造一个音色

> ⚠️ VoxCPM2 是 2B 参数模型，**无法在 iPhone 本地运行**。所以采用「App 前端 + 推理后端」架构：后端跑在你的 Mac（或带 NVIDIA GPU 的机器）上，iOS App 通过 HTTP 调用。

```
┌─────────────┐      HTTP/JSON        ┌──────────────────────┐
│  iOS App    │ ───────────────────▶ │  FastAPI 后端         │
│ (SwiftUI)   │ ◀─────────────────── │  └─ VoxCPM2 模型      │
└─────────────┘      audio/wav        └──────────────────────┘
```

## 目录结构

```
voxcpm-app/
├── server/                 # Python 后端
│   ├── main.py             # FastAPI 接口
│   ├── voxcpm_engine.py    # VoxCPM2 推理封装
│   ├── requirements.txt
│   └── .env.example
└── ios/                    # iOS SwiftUI 前端
    ├── project.yml         # XcodeGen 工程描述
    └── VoxCPMApp/          # Swift 源码
```

## 一、启动后端

```bash
cd server
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt

# 启动（首次会从 HuggingFace 下载约数 GB 的 VoxCPM2 权重，请耐心等待）
uvicorn main:app --host 0.0.0.0 --port 8000
```

可选环境变量（见 `.env.example`）：`VOXCPM_DEVICE=auto|cpu|mps|cuda`、`VOXCPM_OPTIMIZE=false`。

> Mac 用 MPS 能跑但偏慢；想要流畅体验建议把后端放到带 NVIDIA GPU 的机器上。

冒烟测试：

```bash
curl http://localhost:8000/health
curl -X POST http://localhost:8000/api/tts \
  -H "Content-Type: application/json" \
  -d '{"text":"你好，这是一个测试。"}' --output test.wav
```

## 二、生成并运行 iOS App

需要先安装 [XcodeGen](https://github.com/yonyz/XcodeGen)（`brew install xcodegen`），然后：

```bash
cd ios
xcodegen generate      # 生成 VoxCPMApp.xcodeproj
open VoxCPMApp.xcodeproj
```

在 Xcode 里选模拟器，⌘R 运行。

- **模拟器**：默认后端地址 `http://localhost:8000` 即可（模拟器与 Mac 共享网络）。
- **真机**：在 App 的「设置」页把地址改成 Mac 的局域网 IP（如 `http://192.168.1.10:8000`，用 `ipconfig getifaddr en0` 查），手机与 Mac 同一 WiFi。

> 不想用 XcodeGen 也行：在 Xcode 新建一个 iOS App 工程，把 `VoxCPMApp/` 下所有 `.swift` 拖进去，并在 Target 的 Info 里加上 `NSMicrophoneUsageDescription` 和允许 HTTP 的 ATS 设置即可。

## 接口一览

| 方法 | 路径 | 说明 |
|---|---|---|
| GET | `/health` | 健康检查 |
| POST | `/api/tts` | 多语言朗读（JSON：`text`, `cfg_value`, `inference_timesteps`, `normalize`） |
| POST | `/api/design` | 声音设计（JSON：`text`, `description`, ...） |
| POST | `/api/clone` | 声音克隆（multipart：`reference_audio` 文件 + `text` + 可选 `control`） |

合成接口都直接返回 `audio/wav`。

## 注意事项

- 仅供原型 / 个人自用：后端无鉴权、ATS 放开了明文 HTTP，**切勿直接上线**。
- 声音克隆涉及伦理与合规，请仅克隆获得授权的声音，并标注 AI 生成内容。
- 想要高并发 / 低延迟，请改用 VoxCPM 官方的 [vLLM-Omni](https://github.com/vllm-project/vllm-omni) 部署（自带 OpenAI 兼容接口）。

## 致谢

本项目是对 [OpenBMB VoxCPM](https://github.com/OpenBMB/VoxCPM)（Apache-2.0）的应用封装：后端通过 `pip install voxcpm` 调用其推理能力，前端提供 iOS 界面。模型与权重版权归 OpenBMB 所有。

## License

[Apache-2.0](LICENSE)
