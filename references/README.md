# Reference voices

Fish Speech discovers pre-registered voices from this directory.

Register a voice:

```bash
./scripts/register-voice.sh voice_a /path/to/recording.wav
```

## Layout

```
references/
└── voice_a/              # VOICE_ID — change in .env or scripts
    ├── sample.wav        # 30 s – 3 min, mono/stereo, 16–48 kHz
    └── sample.lab        # Exact transcript of sample.wav (one line)
```

## Recording guidelines

- **Duration:** 30 seconds minimum; 1–2 minutes ideal for POC.
- **Environment:** Quiet room, no music/TV, single speaker.
- **Delivery:** Natural pace, steady volume, brief pauses between sentences.
- **Format:** WAV preferred; FFmpeg can convert: `ffmpeg -i input.m4a -ar 44100 -ac 1 references/voice_a/sample.wav`

## Transcript (`sample.lab`)

The text must match what is spoken in `sample.wav`. The WebUI/API use this for alignment. If you do not have a transcript, use the WebUI once running — it can auto-transcribe with Whisper — then copy the result into `sample.lab`.

Example `sample.lab`:

```
This is a neutral reference transcript for a synthetic assistant voice profile.
```

## Permission

Only clone voices you own or have explicit permission to use.
