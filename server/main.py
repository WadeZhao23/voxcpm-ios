"""VoxCPM App 后端：把 VoxCPM2 包成 HTTP 服务，供 iOS App 调用。

启动：
    uvicorn main:app --host 0.0.0.0 --port 8000

接口：
    GET  /health        健康检查
    POST /api/tts       多语言朗读 (JSON)
    POST /api/design    声音设计 (JSON)
    POST /api/clone     声音克隆 (multipart：参考音频 + 文本)
所有合成接口都直接返回 audio/wav 字节。
"""
import os
import tempfile

from fastapi import FastAPI, File, Form, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import Response
from pydantic import BaseModel
from starlette.concurrency import run_in_threadpool

import voxcpm_engine as engine

app = FastAPI(title="VoxCPM App Backend", version="0.1.0")

# 原型阶段允许所有来源跨域
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


class TTSRequest(BaseModel):
    text: str
    cfg_value: float = 2.0
    inference_timesteps: int = 10
    normalize: bool = False


class DesignRequest(BaseModel):
    text: str
    description: str
    cfg_value: float = 2.0
    inference_timesteps: int = 10


def _wav(data: bytes) -> Response:
    return Response(content=data, media_type="audio/wav")


@app.get("/health")
async def health():
    return {"status": "ok"}


@app.post("/api/tts")
async def tts(req: TTSRequest):
    if not req.text.strip():
        raise HTTPException(400, "text 不能为空")
    data = await run_in_threadpool(
        engine.synthesize_tts, req.text, req.cfg_value, req.inference_timesteps, req.normalize
    )
    return _wav(data)


@app.post("/api/design")
async def design(req: DesignRequest):
    if not req.text.strip():
        raise HTTPException(400, "text 不能为空")
    data = await run_in_threadpool(
        engine.synthesize_design, req.text, req.description, req.cfg_value, req.inference_timesteps
    )
    return _wav(data)


@app.post("/api/clone")
async def clone(
    text: str = Form(...),
    reference_audio: UploadFile = File(...),
    control: str = Form(""),
    cfg_value: float = Form(2.0),
    inference_timesteps: int = Form(10),
):
    if not text.strip():
        raise HTTPException(400, "text 不能为空")

    # 把上传的参考音频落到临时文件，交给模型，用完即删
    suffix = os.path.splitext(reference_audio.filename or "ref.wav")[1] or ".wav"
    with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as tmp:
        tmp.write(await reference_audio.read())
        ref_path = tmp.name
    try:
        data = await run_in_threadpool(
            engine.synthesize_clone,
            text, ref_path, control or None, None, None,
            float(cfg_value), int(inference_timesteps),
        )
    finally:
        try:
            os.unlink(ref_path)
        except OSError:
            pass
    return _wav(data)
