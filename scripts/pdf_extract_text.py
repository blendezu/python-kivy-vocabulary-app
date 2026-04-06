#!/usr/bin/env python3
import argparse
import json
import sys


def print_json(obj):
    sys.stdout.write(json.dumps(obj, ensure_ascii=False) + "\n")
    sys.stdout.flush()


def extract_text_from_pdf(path: str):
    try:
        from pypdf import PdfReader
    except Exception as exc:
        return {
            "ok": False,
            "error": "Missing dependency 'pypdf'. Install it in your runtime environment.",
            "details": str(exc),
        }

    try:
        reader = PdfReader(path)
        page_count = len(reader.pages)
        chunks = []

        for page in reader.pages:
            page_text = page.extract_text() or ""
            chunks.append(page_text)

        text = "\n\n".join(chunks).strip()
        if not text:
            return {
                "ok": False,
                "error": "No extractable text found in PDF. If this is a scanned PDF, OCR is required.",
                "pages": page_count,
            }

        return {
            "ok": True,
            "text": text,
            "pages": page_count,
        }
    except Exception as exc:
        return {
            "ok": False,
            "error": f"PDF extraction failed: {exc}",
        }


def main():
    parser = argparse.ArgumentParser(description="Extract text from PDF as JSON")
    parser.add_argument("--file", required=True, help="Absolute path to PDF file")
    args = parser.parse_args()

    res = extract_text_from_pdf(args.file)
    print_json(res)
    return 0 if res.get("ok") else 2


if __name__ == "__main__":
    raise SystemExit(main())
