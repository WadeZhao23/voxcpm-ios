"""VoxCPM2 推理引擎封装。

- 懒加载模型（首次请求时才下载/加载权重，约数 GB）
- 用一把锁串行化推理：原型阶段单卡/单进程，避免并发把显存打爆
- 三种能力共用底层 model.generate()，只是参数不同
"""
import io
import os
import sys
import threading

import soundfile as sf

_model = None
_model_lock = threading.Lock()   # 保护模型加载（只加载一次）
_infer_lock = threading.Lock()   # 串行化推理


def _env(key: str, default: str) -> str:
    v = os.environ.get(key)
    return v if v else default


def get_model():
    """懒加载 VoxCPM2。首次调用会从 HuggingFace 下载权重（约数 GB），请耐心等待。"""
    global _model
    if _model is not None:
        return _model
    with _model_lock:
        if _model is not None:
            return _model
        from voxcpm import VoxCPM

        model_id = _env("VOXCPM_MODEL_ID", "openbmb/VoxCPM2")
        device = _env("VOXCPM_DEVICE", "auto")              # auto / cpu / mps / cuda / cuda:0
        optimize = _env("VOXCPM_OPTIMIZE", "false").lower() == "true"      # Mac/MPS 建议关掉
        load_denoiser = _env("VOXCPM_LOAD_DENOISER", "false").lower() == "true"

        print(f"[engine] loading {model_id} (device={device}, optimize={optimize}) ...", file=sys.stderr)
        _model = VoxCPM.from_pretrained(
            model_id,
            load_denoiser=load_denoiser,
            optimize=optimize,
            device=None if device == "auto" else device,
        )
        print("[engine] model ready", file=sys.stderr)
        return _model


def _generate(**kwargs) -> bytes:
    """调用模型并把波形编码成 WAV 字节。"""
    model = get_model()
    with _infer_lock:
        wav = model.generate(**kwargs)
    sr = model.tts_model.sample_rate
    buf = io.BytesIO()
    sf.write(buf, wav, sr, format="WAV")
    buf.seek(0)
    return buf.read()


def is_loaded() -> bool:
    return _model is not None


def info() -> dict:
    """返回服务/模型状态，供客户端探测。"""
    data = {
        "model_id": _env("VOXCPM_MODEL_ID", "openbmb/VoxCPM2"),
        "device": _env("VOXCPM_DEVICE", "auto"),
        "loaded": _model is not None,
        "sample_rate": None,
    }
    if _model is not None:
        try:
            data["sample_rate"] = _model.tts_model.sample_rate
        except Exception:
            pass
    return data


def synthesize_tts(text: str, cfg_value: float = 2.0,
                   inference_timesteps: int = 10, normalize: bool = False) -> bytes:
    """多语言朗读：直接输入文本，无需语言标签。"""
    return _generate(
        text=text,
        cfg_value=cfg_value,
        inference_timesteps=inference_timesteps,
        normalize=normalize,
    )


def synthesize_design(text: str, description: str,
                      cfg_value: float = 2.0, inference_timesteps: int = 10) -> bytes:
    """声音设计：用 (描述)文本 的格式凭空造一个音色。"""
    prompt = f"({description}){text}" if description.strip() else text
    return _generate(text=prompt, cfg_value=cfg_value, inference_timesteps=inference_timesteps)


def synthesize_clone(text: str, reference_wav_path: str, control: str = None,
                     prompt_wav_path: str = None, prompt_text: str = None,
                     cfg_value: float = 2.0, inference_timesteps: int = 10) -> bytes:
    """声音克隆：给参考音频克隆音色，可选用 (控制指令) 调节风格。

    若同时给 prompt_wav_path + prompt_text，则走「极致克隆」（音频续写）。
    """
    final_text = f"({control}){text}" if control and control.strip() else text
    return _generate(
        text=final_text,
        reference_wav_path=reference_wav_path,
        prompt_wav_path=prompt_wav_path,
        prompt_text=prompt_text,
        cfg_value=cfg_value,
        inference_timesteps=inference_timesteps,
    )
