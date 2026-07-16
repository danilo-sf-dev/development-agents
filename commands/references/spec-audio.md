# Reference: `/sdd.spec --audio`

**Used by**: `/sdd.spec --audio`.

## Flow

1. Explain that the recording becomes specification context.
2. Start the configured audio capture tool:

```bash
python3 development-agents/framework/tools/audio-capture/server.py
```

3. Transcribe the recording.
4. Store the transcription as `initial_context`.
5. Continue the normal functional-spec interview, using the transcription to
   make questions more specific.
6. If capture or transcription fails, ask the user to provide the description
   as text instead.

Audio input enriches the interview; it does not skip required clarification or
approval gates.
