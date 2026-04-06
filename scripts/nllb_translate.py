#!/usr/bin/env python3
import argparse
import json
import os
import sys


def print_json(obj):
    sys.stdout.write(json.dumps(obj, ensure_ascii=False) + "\n")
    sys.stdout.flush()


def resolve_device(requested, torch_module):
    req = (requested or "auto").strip().lower()

    def detect_auto():
        if torch_module.cuda.is_available():
            return "cuda"
        if (
            hasattr(torch_module.backends, "mps")
            and torch_module.backends.mps.is_available()
        ):
            return "mps"
        return "cpu"

    if req in ("", "auto"):
        return detect_auto(), None

    if req == "cuda":
        if torch_module.cuda.is_available():
            return "cuda", None
        return (
            detect_auto(),
            "CUDA requested but not available; falling back automatically.",
        )

    if req == "mps":
        if (
            hasattr(torch_module.backends, "mps")
            and torch_module.backends.mps.is_available()
        ):
            return "mps", None
        return (
            detect_auto(),
            "MPS requested but not available; falling back automatically.",
        )

    if req == "cpu":
        return "cpu", None

    # OpenGL is not a backend used by Hugging Face Transformers/PyTorch for inference.
    if req == "opengl":
        return (
            detect_auto(),
            "OpenGL backend is not supported for this model runtime; using auto device.",
        )

    return detect_auto(), f"Unknown device '{requested}', using auto device."


def load_translator(model_name, requested_device):
    from transformers import AutoTokenizer, AutoModelForSeq2SeqLM
    import torch

    device, warning = resolve_device(requested_device, torch)
    tokenizer = AutoTokenizer.from_pretrained(model_name, local_files_only=False)
    model = AutoModelForSeq2SeqLM.from_pretrained(model_name, local_files_only=False)
    model = model.to(device)
    model.eval()
    return tokenizer, model, device, warning, torch


def translate_once(tokenizer, model, torch_module, text, src_code, tgt_code, device):
    forced_bos_token_id = tokenizer.convert_tokens_to_ids(tgt_code)
    if forced_bos_token_id is None or forced_bos_token_id < 0:
        return {
            "ok": False,
            "error": f"Target language token '{tgt_code}' is invalid for tokenizer.",
        }

    tokenizer.src_lang = src_code
    inputs = tokenizer(text, return_tensors="pt")
    inputs = {k: v.to(device) for k, v in inputs.items()}

    with torch_module.no_grad():
        generated_tokens = model.generate(
            **inputs,
            forced_bos_token_id=forced_bos_token_id,
            max_new_tokens=256,
            num_beams=4,
            do_sample=False,
        )

    translated = tokenizer.batch_decode(generated_tokens, skip_special_tokens=True)[
        0
    ].strip()
    if not translated:
        return {"ok": False, "error": "Model returned empty translation."}

    return {"ok": True, "translated": translated}


def translate_multiline(
    tokenizer, model, torch_module, text, src_code, tgt_code, device
):
    src_token_id = tokenizer.convert_tokens_to_ids(src_code)
    if src_token_id is None or src_token_id < 0:
        return {
            "ok": False,
            "error": f"Source language token '{src_code}' is invalid for tokenizer.",
        }

    lines = text.split("\n")
    translated_lines = []

    for line in lines:
        segment = line.strip()
        if not segment:
            translated_lines.append("")
            continue

        item_result = translate_once(
            tokenizer, model, torch_module, segment, src_code, tgt_code, device
        )
        if not item_result.get("ok"):
            return item_result

        translated_lines.append(item_result.get("translated", ""))

    return {"ok": True, "translated": "\n".join(translated_lines)}


def run_server(args):
    try:
        tokenizer, model, device, warning, torch_module = load_translator(
            args.model, args.device
        )
    except Exception as exc:
        print_json({"ok": False, "error": f"worker init failed: {exc}"})
        return 10

    ready = {"ok": True, "device": device, "model": args.model}
    if warning:
        ready["warning"] = warning
    print_json(ready)

    for raw_line in sys.stdin:
        line = (raw_line or "").strip()
        if not line:
            continue

        try:
            req = json.loads(line)
        except Exception:
            print_json({"ok": False, "error": "Invalid JSON request."})
            continue

        text = str(req.get("text", ""))
        src = str(req.get("src", "")).strip()
        tgt = str(req.get("tgt", "")).strip()

        if not text.strip():
            print_json({"ok": False, "error": "Input text is empty."})
            continue
        if not src or not tgt:
            print_json(
                {"ok": False, "error": "Source and target language are required."}
            )
            continue
        if src == tgt:
            print_json(
                {"ok": True, "translated": text, "device": device, "model": args.model}
            )
            continue

        try:
            result = translate_multiline(
                tokenizer, model, torch_module, text, src, tgt, device
            )
            result["device"] = device
            result["model"] = args.model
            if warning:
                result["warning"] = warning
            print_json(result)
        except Exception as exc:
            print_json(
                {
                    "ok": False,
                    "error": f"translation failed on device '{device}': {exc}",
                    "device": device,
                    "model": args.model,
                }
            )

    return 0


def main():
    parser = argparse.ArgumentParser(description="Local NLLB translation helper")
    parser.add_argument(
        "--src",
        required=False,
        default="",
        help="NLLB source language code, e.g. eng_Latn",
    )
    parser.add_argument(
        "--tgt",
        required=False,
        default="",
        help="NLLB target language code, e.g. deu_Latn",
    )
    parser.add_argument("--text", required=False, default="", help="Text to translate")
    parser.add_argument(
        "--model",
        default=os.environ.get(
            "VOCA_NLLB_MODEL_PATH", "facebook/nllb-200-distilled-600M"
        ),
        help="Local model path or HF model id",
    )
    parser.add_argument(
        "--device",
        default=os.environ.get("VOCA_TRANSLATE_DEVICE", "auto"),
        help="Device override: auto|cuda|mps|cpu (opengl is not supported here)",
    )
    parser.add_argument(
        "--server",
        action="store_true",
        help="Run persistent stdin/stdout JSON line server mode",
    )

    args = parser.parse_args()

    if args.server:
        return run_server(args)

    if not args.src.strip() or not args.tgt.strip():
        print_json(
            {"ok": False, "error": "--src and --tgt are required in one-shot mode."}
        )
        return 1

    text = args.text or ""
    if not text.strip():
        print_json({"ok": False, "error": "Input text is empty."})
        return 1

    try:
        tokenizer, model, device, warning, torch = load_translator(
            args.model, args.device
        )
    except Exception as exc:
        print_json({"ok": False, "error": f"transformers/model init failed: {exc}"})
        return 2

    try:
        response = translate_multiline(
            tokenizer, model, torch, text, args.src, args.tgt, device
        )
        response["device"] = device
        response["model"] = args.model
        if warning:
            response["warning"] = warning

        print_json(response)
        if not response.get("ok"):
            return 4
        return 0
    except Exception as exc:
        print_json(
            {
                "ok": False,
                "error": f"translation failed on device '{args.device}': {exc}",
            }
        )
        return 5


if __name__ == "__main__":
    raise SystemExit(main())
