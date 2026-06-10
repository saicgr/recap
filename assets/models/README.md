# Bundled on-device models

Files in this directory are bundled into the APK / IPA so the app works on first launch with zero downloads. They are NOT checked into git (would balloon the repo); CI pulls them at build time from the official upstream releases.

## Files

| File | Source | Size | Purpose |
|---|---|---|---|
| `ggml-tiny.en.bin` | https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny.en.bin | ~75 MB | Whisper tiny.en — bundled so live captions work instantly on first launch (D15.1). Used for live captions on every tier; the larger `base.en` / `small.en` models download in the background after onboarding and take over for final transcription. |

## CI build step

`scripts/fetch_bundled_models.sh` runs before `flutter build` to populate this directory. The file is in `.gitignore` so a fresh clone won't have it; run the script locally or let CI handle it.

## Why bundle vs download-on-first-launch?

Voice Memos and Samsung Recorder work in 1 tap. Without the bundled model, Recap shows a "downloading 140 MB" wall before the first record. That kills first-impression conversion. Bundling tiny.en (75 MB) is the smallest payload that gets us to instant-start parity.
