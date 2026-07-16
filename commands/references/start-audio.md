# Reference: `/sdd.start --audio`

**Used by**: `/sdd.start --audio`.

## Flow

1. Run the standard `/sdd.start` initialization through Step 11 (feature folder + `meta.md`).
2. Explain that the recording becomes the saved description for `/sdd.spec`.
3. Start the configured audio capture tool:

```bash
python3 development-agents/framework/tools/audio-capture/server.py
```

4. Transcribe the recording.
5. Store the transcription in `meta.md` as the saved description / initial context.
6. Invoke `Skill("sdd.spec", args="--audio")` **or** continue with `/sdd.spec` using the saved transcription as initial context.
7. If capture or transcription fails, ask the user to provide the description as text instead.

Audio input enriches the start/spec interview; it does not skip required gates.
