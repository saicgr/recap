#!/usr/bin/env python3
"""
i18n_fill_translations.py — port of Zealova's pipeline, scoped to Recap.

Reads lib/l10n/app_en.arb, fans out to all 35 non-en ARB files via Gemini
3.1 Flash Lite. Idempotent + resumable: cells already populated in a locale
ARB are skipped. Run cost: ~$0.05-0.10 for the full Recap surface.

Usage:
    GEMINI_API_KEY=...  python3 scripts/i18n_fill_translations.py

Options:
    --only LOCALES   Comma-separated subset (e.g. "es,fr,de") for quick tests.
    --dry-run        Show what would be translated; don't call the API.
    --batch N        Keys per API call (default 30).
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys
import time
from pathlib import Path
from typing import Dict, List

try:
    import requests  # type: ignore
except ImportError:
    sys.exit("Install requests first:  python3 -m pip install requests")

ROOT = Path(__file__).resolve().parent.parent
ARB_DIR = ROOT / "lib" / "l10n"
EN_ARB = ARB_DIR / "app_en.arb"

# Source of truth — must match the 36 locales in docs/i18n.
LOCALES_NON_EN = [
    "ar", "bn", "cs", "de", "es", "fi", "fr", "ha", "hi", "id", "it",
    "ja", "jv", "kn", "ko", "ml", "mr", "ms", "ne", "nl", "or", "pa",
    "pl", "pt", "ru", "sv", "sw", "ta", "te", "th", "tl", "tr", "ur",
    "vi", "zh",
]

LOCALE_NATIVE = {
    "ar": "Arabic (العربية)",
    "bn": "Bengali (বাংলা)",
    "cs": "Czech (Čeština)",
    "de": "German (Deutsch)",
    "es": "Spanish (Español)",
    "fi": "Finnish (Suomi)",
    "fr": "French (Français)",
    "ha": "Hausa",
    "hi": "Hindi (हिन्दी)",
    "id": "Indonesian (Bahasa Indonesia)",
    "it": "Italian (Italiano)",
    "ja": "Japanese (日本語)",
    "jv": "Javanese (Basa Jawa)",
    "kn": "Kannada (ಕನ್ನಡ)",
    "ko": "Korean (한국어)",
    "ml": "Malayalam (മലയാളം)",
    "mr": "Marathi (मराठी)",
    "ms": "Malay (Bahasa Melayu)",
    "ne": "Nepali (नेपाली)",
    "nl": "Dutch (Nederlands)",
    "or": "Odia (ଓଡ଼ିଆ)",
    "pa": "Punjabi (ਪੰਜਾਬੀ)",
    "pl": "Polish (Polski)",
    "pt": "Portuguese (Português)",
    "ru": "Russian (Русский)",
    "sv": "Swedish (Svenska)",
    "sw": "Swahili (Kiswahili)",
    "ta": "Tamil (தமிழ்)",
    "te": "Telugu (తెలుగు)",
    "th": "Thai (ไทย)",
    "tl": "Tagalog",
    "tr": "Turkish (Türkçe)",
    "ur": "Urdu (اردو)",
    "vi": "Vietnamese (Tiếng Việt)",
    "zh": "Simplified Chinese (简体中文)",
}

GEMINI_URL = (
    "https://generativelanguage.googleapis.com/v1beta/models/"
    "gemini-2.0-flash-lite:generateContent"
)


def load_arb(path: Path) -> dict:
    if not path.exists():
        return {"@@locale": path.stem.split("_", 1)[1]}
    return json.loads(path.read_text(encoding="utf-8"))


def save_arb(path: Path, data: dict) -> None:
    path.write_text(
        json.dumps(data, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def translatable_keys(en: dict) -> Dict[str, str]:
    """All non-metadata keys in the en ARB → their English values."""
    out = {}
    for k, v in en.items():
        if k.startswith("@") or k.startswith("@@"):
            continue
        if isinstance(v, str):
            out[k] = v
    return out


def needs_translation(target: dict, key: str, en_value: str) -> bool:
    """Skip if already populated AND not equal to the English source."""
    cur = target.get(key)
    if cur is None:
        return True
    if not isinstance(cur, str):
        return True
    if not cur.strip():
        return True
    # If the cell is verbatim English, retranslate (matches Zealova's policy).
    return cur.strip() == en_value.strip()


def translate_batch(
    api_key: str, batch: List[tuple[str, str]], locale: str
) -> Dict[str, str]:
    """Translate a list of (key, english) pairs into [locale]. Returns a dict
    keyed by the ARB key. Skips entries on any per-entry parse failure so
    other batches still land."""
    native = LOCALE_NATIVE[locale]
    pairs_block = "\n".join(f"{k}: {v}" for k, v in batch)
    prompt = (
        f"You are translating UI strings for the Recap meeting-recorder app "
        f"from English to {native}.\n\n"
        f"Rules:\n"
        f"  - Output ONLY a single JSON object mapping each key to the "
        f"translated value. No prose, no markdown fences.\n"
        f"  - Preserve placeholders verbatim — e.g. {{name}}, {{count}}, %s, %d.\n"
        f"  - Keep brand names untranslated: Recap, Gemma, Whisper, Apple, "
        f"Samsung, Notion, Slack, Google, YouTube, Render, Gemini, Ollama.\n"
        f"  - Match register: settings UI = neutral; CTAs = imperative.\n\n"
        f"Keys to translate:\n"
        f"{pairs_block}\n"
    )
    body = {
        "contents": [{"parts": [{"text": prompt}]}],
        "generationConfig": {
            "temperature": 0.2,
            "response_mime_type": "application/json",
        },
    }
    res = requests.post(
        GEMINI_URL,
        params={"key": api_key},
        json=body,
        timeout=60,
    )
    if res.status_code != 200:
        print(f"  ! API HTTP {res.status_code}: {res.text[:200]}")
        return {}
    payload = res.json()
    try:
        raw = payload["candidates"][0]["content"]["parts"][0]["text"]
    except (KeyError, IndexError):
        print(f"  ! Unexpected payload shape: {json.dumps(payload)[:200]}")
        return {}
    # Strip markdown fences if the model wrapped JSON in ``` despite the
    # response_mime_type hint.
    raw = re.sub(r"^```(?:json)?\s*|\s*```$", "", raw.strip())
    try:
        return json.loads(raw)
    except json.JSONDecodeError:
        print(f"  ! Failed to parse JSON: {raw[:200]}")
        return {}


def run_locale(
    api_key: str,
    locale: str,
    en_keys: Dict[str, str],
    batch_size: int,
    dry_run: bool,
) -> int:
    target_path = ARB_DIR / f"app_{locale}.arb"
    target = load_arb(target_path)
    target.setdefault("@@locale", locale)
    pending = [
        (k, v) for k, v in en_keys.items()
        if needs_translation(target, k, v)
    ]
    if not pending:
        print(f"  [{locale}] already complete ({len(en_keys)} keys)")
        return 0
    print(
        f"  [{locale}] {len(pending)}/{len(en_keys)} pending"
        f" — {LOCALE_NATIVE[locale]}"
    )
    if dry_run:
        return len(pending)
    landed = 0
    for i in range(0, len(pending), batch_size):
        batch = pending[i:i + batch_size]
        result = translate_batch(api_key, batch, locale)
        for k, _ in batch:
            translated = result.get(k)
            if isinstance(translated, str) and translated.strip():
                target[k] = translated.strip()
                landed += 1
        save_arb(target_path, target)  # save after every batch — resumable
        time.sleep(0.5)  # gentle on rate limits
    print(f"  [{locale}] landed {landed}/{len(pending)}")
    return landed


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--only", default="")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--batch", type=int, default=30)
    args = parser.parse_args()

    api_key = os.environ.get("GEMINI_API_KEY", "").strip()
    if not api_key and not args.dry_run:
        print("Set GEMINI_API_KEY in your env (or pass --dry-run to preview).")
        return 1

    if not EN_ARB.exists():
        print(f"Missing {EN_ARB}")
        return 1
    en = load_arb(EN_ARB)
    en_keys = translatable_keys(en)
    if not en_keys:
        print("English ARB has no translatable keys.")
        return 0
    print(f"English source: {len(en_keys)} translatable keys")

    locales = (
        [s.strip() for s in args.only.split(",") if s.strip()]
        if args.only
        else LOCALES_NON_EN
    )
    bad = [s for s in locales if s not in LOCALE_NATIVE]
    if bad:
        print(f"Unknown locales: {bad}")
        return 1

    total = 0
    for loc in locales:
        total += run_locale(api_key, loc, en_keys, args.batch, args.dry_run)
    print(f"\nDone — {total} cells translated across {len(locales)} locales.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
