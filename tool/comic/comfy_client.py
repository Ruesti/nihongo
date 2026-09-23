#!/usr/bin/env python3
"""ComfyUI-HTTP-Client für die GPU-Box. Läuft AUF der Box (Port 8188 ist vom
NUC aus dicht). Nur Python-Standardbibliothek.

run(graph, prefix, out_dir) -> Liste der abgeholten Dateipfade.
"""
import json
import os
import time
import urllib.parse
import urllib.request

BASE = os.environ.get("COMFY", "http://127.0.0.1:8188")
COMFY_INPUT = os.path.expanduser(
    "~/ComfyUI-Easy-Install/ComfyUI-Easy-Install/ComfyUI/input")


def post(path, data):
    req = urllib.request.Request(BASE + path, data=json.dumps(data).encode(),
                                 headers={"Content-Type": "application/json"})
    return json.load(urllib.request.urlopen(req, timeout=30))


def wait(prompt_id, timeout=1200):
    end = time.time() + timeout
    while time.time() < end:
        hist = json.load(urllib.request.urlopen(BASE + "/history/" + prompt_id, timeout=30))
        if prompt_id in hist:
            status = hist[prompt_id]["status"]
            if status.get("status_str") == "error":
                raise RuntimeError("job error: " + json.dumps(status)[:500])
            if status.get("completed"):
                return hist[prompt_id]
        time.sleep(3)
    raise TimeoutError(prompt_id)


def fetch(filename, subfolder, dest):
    q = urllib.parse.urlencode({"filename": filename, "subfolder": subfolder, "type": "output"})
    with open(dest, "wb") as f:
        f.write(urllib.request.urlopen(BASE + "/view?" + q, timeout=180).read())


def run(graph, prefix, out_dir, client_id="cafe"):
    os.makedirs(out_dir, exist_ok=True)
    r = post("/prompt", {"prompt": graph, "client_id": client_id})
    if r.get("node_errors"):
        raise RuntimeError("node_errors %s: %s" % (prefix, json.dumps(r["node_errors"])[:800]))
    hist = wait(r["prompt_id"])
    got = []
    for node in hist.get("outputs", {}).values():
        for im in node.get("images", []):
            if im.get("type") == "output":
                dest = os.path.join(out_dir, "%s_%s" % (prefix, im["filename"]))
                fetch(im["filename"], im.get("subfolder", ""), dest)
                got.append(dest)
    return got


def t2i_graph(prompt, negative, seed, prefix, lora_strength=0.3, width=1216, height=832):
    """Basis-Text-zu-Bild, Rezept der Look-A-Finals (LoRA 0.3, 24 Steps, cfg 4)."""
    return {
        "1": {"class_type": "UnetLoaderGGUF", "inputs": {"unet_name": "qwen-image-Q4_K_M.gguf"}},
        "L": {"class_type": "LoraLoaderModelOnly", "inputs": {"model": ["1", 0],
              "lora_name": "shotengai_style_ckpt6.safetensors", "strength_model": lora_strength}},
        "2": {"class_type": "CLIPLoader", "inputs": {"clip_name": "qwen_2.5_vl_7b_fp8_scaled.safetensors", "type": "qwen_image"}},
        "3": {"class_type": "VAELoader", "inputs": {"vae_name": "qwen_image_vae.safetensors"}},
        "4": {"class_type": "CLIPTextEncode", "inputs": {"text": "shotengai_style, " + prompt, "clip": ["2", 0]}},
        "5": {"class_type": "CLIPTextEncode", "inputs": {"text": negative, "clip": ["2", 0]}},
        "6": {"class_type": "EmptySD3LatentImage", "inputs": {"width": width, "height": height, "batch_size": 1}},
        "7": {"class_type": "KSampler", "inputs": {"seed": seed, "steps": 24, "cfg": 4.0, "sampler_name": "euler",
              "scheduler": "simple", "denoise": 1.0, "model": ["L", 0], "positive": ["4", 0],
              "negative": ["5", 0], "latent_image": ["6", 0]}},
        "8": {"class_type": "VAEDecode", "inputs": {"samples": ["7", 0], "vae": ["3", 0]}},
        "9": {"class_type": "SaveImage", "inputs": {"filename_prefix": prefix, "images": ["8", 0]}},
    }


def relight_graph(input_name, prompt, seed, prefix):
    """Umleuchten: Qwen-Image-Edit-2509 + Lightning-4step + Relight-LoRA (bewährt für
    die Anker A1–A7). input_name liegt in COMFY_INPUT. Keine Stil-LoRA — das Bild
    trägt den Look schon."""
    return {
        "1": {"class_type": "UnetLoaderGGUF", "inputs": {"unet_name": "Qwen-Image-Edit-2509-Q4_K_M.gguf"}},
        "2": {"class_type": "LoraLoaderModelOnly", "inputs": {"model": ["1", 0],
              "lora_name": "Qwen-Image-Edit-2509-Lightning-4steps-V1.0-bf16.safetensors", "strength_model": 1.0}},
        "3": {"class_type": "LoraLoaderModelOnly", "inputs": {"model": ["2", 0],
              "lora_name": "Qwen-Image-Edit-2509-Relight.safetensors", "strength_model": 1.0}},
        "4": {"class_type": "ModelSamplingAuraFlow", "inputs": {"model": ["3", 0], "shift": 3.0}},
        "5": {"class_type": "CLIPLoader", "inputs": {"clip_name": "qwen_2.5_vl_7b_fp8_scaled.safetensors", "type": "qwen_image"}},
        "6": {"class_type": "VAELoader", "inputs": {"vae_name": "qwen_image_vae.safetensors"}},
        "7": {"class_type": "LoadImage", "inputs": {"image": input_name}},
        "8": {"class_type": "FluxKontextImageScale", "inputs": {"image": ["7", 0]}},
        "9": {"class_type": "VAEEncode", "inputs": {"pixels": ["8", 0], "vae": ["6", 0]}},
        "10": {"class_type": "TextEncodeQwenImageEditPlus", "inputs": {"clip": ["5", 0], "prompt": prompt,
               "vae": ["6", 0], "image1": ["8", 0]}},
        "11": {"class_type": "TextEncodeQwenImageEditPlus", "inputs": {"clip": ["5", 0], "prompt": "", "vae": ["6", 0]}},
        "12": {"class_type": "KSampler", "inputs": {"seed": seed, "steps": 4, "cfg": 1.0, "sampler_name": "euler",
               "scheduler": "simple", "denoise": 1.0, "model": ["4", 0], "positive": ["10", 0],
               "negative": ["11", 0], "latent_image": ["9", 0]}},
        "13": {"class_type": "VAEDecode", "inputs": {"samples": ["12", 0], "vae": ["6", 0]}},
        "14": {"class_type": "SaveImage", "inputs": {"filename_prefix": prefix, "images": ["13", 0]}},
    }


def manga_graph(input_name, prompt, negative, seed, prefix, control="depth", denoise=0.7,
                strength=0.7, end_percent=0.8, lora_strength=1.5):
    """Manga-Durchgang (Spec Manga-Vollbild §2.2): img2img über dem Foto-Final mit
    Hausstil-LoRA und Struktur-Zügel (InstantX ControlNet-Union). control = "depth"
    (Standard, Uli 23.9.) oder "canny" (Ausweich). input_name liegt in COMFY_INPUT."""
    if control == "depth":
        pre = {"class_type": "DepthAnythingV2Preprocessor",
               "inputs": {"image": ["IN", 0], "resolution": 928}}
    elif control == "canny":
        pre = {"class_type": "CannyEdgePreprocessor",
               "inputs": {"image": ["IN", 0], "low_threshold": 100, "high_threshold": 200, "resolution": 928}}
    else:
        raise ValueError("control muss depth oder canny sein, nicht %r" % control)
    return {
        "1": {"class_type": "UnetLoaderGGUF", "inputs": {"unet_name": "qwen-image-Q4_K_M.gguf"}},
        "L": {"class_type": "LoraLoaderModelOnly", "inputs": {"model": ["1", 0],
              "lora_name": "shotengai_style_ckpt6.safetensors", "strength_model": lora_strength}},
        "2": {"class_type": "CLIPLoader", "inputs": {"clip_name": "qwen_2.5_vl_7b_fp8_scaled.safetensors", "type": "qwen_image"}},
        "3": {"class_type": "VAELoader", "inputs": {"vae_name": "qwen_image_vae.safetensors"}},
        "IN": {"class_type": "LoadImage", "inputs": {"image": input_name}},
        "EN": {"class_type": "VAEEncode", "inputs": {"pixels": ["IN", 0], "vae": ["3", 0]}},
        "4": {"class_type": "CLIPTextEncode", "inputs": {"text": "shotengai_style, " + prompt, "clip": ["2", 0]}},
        "5": {"class_type": "CLIPTextEncode", "inputs": {"text": negative, "clip": ["2", 0]}},
        "CN": {"class_type": "ControlNetLoader", "inputs": {"control_net_name": "Qwen-Image-InstantX-ControlNet-Union.safetensors"}},
        "PRE": pre,
        "CA": {"class_type": "ControlNetApplyAdvanced", "inputs": {"positive": ["4", 0], "negative": ["5", 0],
               "control_net": ["CN", 0], "image": ["PRE", 0], "strength": strength,
               "start_percent": 0.0, "end_percent": end_percent, "vae": ["3", 0]}},
        "7": {"class_type": "KSampler", "inputs": {"seed": seed, "steps": 24, "cfg": 4.0, "sampler_name": "euler",
              "scheduler": "simple", "denoise": denoise, "model": ["L", 0], "positive": ["CA", 0],
              "negative": ["CA", 1], "latent_image": ["EN", 0]}},
        "8": {"class_type": "VAEDecode", "inputs": {"samples": ["7", 0], "vae": ["3", 0]}},
        "9": {"class_type": "SaveImage", "inputs": {"filename_prefix": prefix, "images": ["8", 0]}},
    }


def upscale_graph(input_name, prefix, width, height):
    """4x-UltraSharp hoch, dann per Lanczos auf die Auslieferungsgröße (Spec §4.3)."""
    return {
        "1": {"class_type": "LoadImage", "inputs": {"image": input_name}},
        "2": {"class_type": "UpscaleModelLoader", "inputs": {"model_name": "4x-UltraSharp.pth"}},
        "3": {"class_type": "ImageUpscaleWithModel", "inputs": {"upscale_model": ["2", 0], "image": ["1", 0]}},
        "4": {"class_type": "ImageScale", "inputs": {"image": ["3", 0], "upscale_method": "lanczos",
              "width": width, "height": height, "crop": "disabled"}},
        "5": {"class_type": "SaveImage", "inputs": {"filename_prefix": prefix, "images": ["4", 0]}},
    }
