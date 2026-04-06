#!/usr/bin/env python3
import argparse
import json
import os
import sys


def print_json(obj):
    sys.stdout.write(json.dumps(obj, ensure_ascii=False))
    sys.stdout.flush()


def resolve_device(requested, torch_module):
    req = (requested or "auto").strip().lower()

    def detect_auto():
        if torch_module.cuda.is_available():
            return "cuda"
        if hasattr(torch_module.backends, "mps") and torch_module.backends.mps.is_available():
            return "mps"
        return "cpu"

    if req in ("", "auto"):
        return detect_auto(), None

    if req == "cuda":
        if torch_module.cuda.is_available():
            return "cuda", None
        return detect_auto(), "CUDA requested but not available; falling back automatically."

    if req == "mps":
        if hasattr(torch_module.backends, "mps") and torch_module.backends.mps.is_available():
            return "mps", None
        return detect_auto(), "MPS requested but not available; falling back automatically."

    if req == "cpu":
        return "cpu", None

    # OpenGL is not a backend used by Hugging Face Transformers/PyTorch for inference.
    if req == "opengl":
        return detect_auto(), "OpenGL backend is not supported for this model runtime; using auto device."

    return detect_auto(), f"Unknown device '{requested}', using auto device."


def main():
    parser = argparse.ArgumentParser(description="Local NLLB translation helper")
    parser.add_argument(
        "--src", required=True, help="NLLB source language code, e.g. eng_Latn"
    )
    parser.add_argument(
        "--tgt", required=True, help="NLLB target language code, e.g. deu_Latn"
    )
    parser.add_argument("--text", required=True, help="Text to translate")
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

    args = parser.parse_args()

    text = (args.text or "").strip()
    if not text:
        print_json({"ok": False, "error": "Input text is empty."})
        return 1

    try:
        from transformers import AutoTokenizer, AutoModelForSeq2SeqLM
        import torch
    except Exception as exc:
        print_json({"ok": False, "error": f"transformers import failed: {exc}"})
        return 2

    try:
        device, warning = resolve_device(args.device, torch)

        tokenizer = AutoTokenizer.from_pretrained(args.model, local_files_only=False)
        model = AutoModelForSeq2SeqLM.from_pretrained(
            args.model, local_files_only=False
        )
        model = model.to(device)
        model.eval()

        src_token_id = tokenizer.convert_tokens_to_ids(args.src)
        if src_token_id is None or src_token_id < 0:
            print_json(
                {
                    "ok": False,
                    "error": f"Source language token '{args.src}' is invalid for tokenizer.",
                }
            )
            return 3

        tokenizer.src_lang = args.src

        inputs = tokenizer(text, return_tensors="pt")
        inputs = {k: v.to(device) for k, v in inputs.items()}
        forced_bos_token_id = tokenizer.convert_tokens_to_ids(args.tgt)

        if forced_bos_token_id is None or forced_bos_token_id < 0:
            print_json({
                "ok": False,
                "error": f"Target language token '{args.tgt}' is invalid for tokenizer.",
            })
            return 3

        with torch.no_grad():
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
            print_json({"ok": False, "error": "Model returned empty translation."})
            return 4

        response = {
            "ok": True,
            "translated": translated,
            "device": device,
            "model": args.model,
        }
        if warning:
            response["warning"] = warning

        print_json(response)
        return 0
    except Exception as exc:
        print_json({"ok": False, "error": f"translation failed on device '{args.device}': {exc}"})
        return 5


if __name__ == "__main__":
    raise SystemExit(main())
