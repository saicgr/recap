# scripts/

CI + dev utilities for Recap.

## `fetch_bundled_models.sh`

Downloads model files bundled into the APK/IPA so first-launch works with zero downloads. Currently:

- `assets/models/ggml-tiny.en.bin` (~75 MB) — Whisper tiny.en for instant-start live captions.

Run before `flutter build` (CI hook). Idempotent — skips already-present files.

```sh
./scripts/fetch_bundled_models.sh
```

## `i18n_fill_translations.py`

Translates `lib/l10n/app_en.arb` into all 35 non-en ARB files via Gemini 3.1 Flash Lite. Idempotent + resumable: cells already populated in a locale are skipped.

Estimated cost for a full Recap translation: $0.05-0.10.

```sh
# Preview without API calls
python3 scripts/i18n_fill_translations.py --dry-run

# Run a single locale (good for quick sanity check)
GEMINI_API_KEY=... python3 scripts/i18n_fill_translations.py --only es

# Full translation pass
GEMINI_API_KEY=... python3 scripts/i18n_fill_translations.py

# Smaller batches if you hit rate limits
GEMINI_API_KEY=... python3 scripts/i18n_fill_translations.py --batch 15
```

Notes:
- Get a Gemini API key at <https://aistudio.google.com/apikey>.
- The script saves after every batch — safe to Ctrl-C mid-run and resume.
- Brand names (Recap, Gemma, Whisper, Apple, Samsung, Notion, Slack, etc.) are preserved by the prompt.
- Placeholders (`{name}`, `{count}`, `%s`, `%d`) are preserved by the prompt.
- RTL locales (`ar`, `ur`) just produce RTL strings — Flutter's `Directionality.of(context)` handles layout.

After running, regenerate Dart sources:

```sh
flutter pub get  # auto-runs flutter gen-l10n when generate: true is set
```

## CI hook

GitHub Actions / Codemagic:

```yaml
- name: Bundle models
  run: ./scripts/fetch_bundled_models.sh
- name: Translate ARB
  if: github.event_name == 'workflow_dispatch'  # manual only — costs money
  env:
    GEMINI_API_KEY: ${{ secrets.GEMINI_API_KEY }}
  run: python3 scripts/i18n_fill_translations.py
- name: Flutter build
  run: flutter build apk
```
