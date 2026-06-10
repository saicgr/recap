# assets/

Drop a meeting recording here as `sample_meeting.wav` (16 kHz mono WAV).

The Home screen's `+` menu shows a debug-only **Load sample meeting** option
that copies this file into the meetings store and runs it through the same
transcription pipeline as a live recording. Lets you iterate on UI and
transcription without re-recording every time.

Quick way to make one from any audio file using ffmpeg:

```
ffmpeg -i your_meeting.m4a -ar 16000 -ac 1 -c:a pcm_s16le assets/sample_meeting.wav
```
