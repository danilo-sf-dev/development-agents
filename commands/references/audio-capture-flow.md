# Reference: Generic Audio Capture Flow

**Used by**: Any `/sdd.*` command that supports an `--audio` flag (`sdd.start`, `sdd.spec`, `sdd.go`, `sdd.cancel`, `sdd.backlog`, `sdd.reverse-eng`, `sdd.project`).

## Flow

1. Explain what the recording will be used for (see the "Maps to" row for this command in the table below).
2. Start the configured audio capture tool:

```bash
python3 development-agents/framework/tools/audio-capture/server.py
```

3. Transcribe the recording.
4. Feed the transcription into the command's normal input slot (see mapping below) and continue the **standard** workflow for that command — audio never skips validation, confirmations, or approval gates.
5. If capture or transcription fails, ask the user to provide the input as text instead.

## Per-command mapping

| Command | Transcription becomes |
|---------|------------------------|
| `/sdd.start --audio` | Feature description (same as typing it inline) |
| `/sdd.spec --audio` | `initial_context` for the interview (see `references/spec-audio.md` for spec-specific notes) |
| `/sdd.go --audio` | Feature description for the express flow |
| `/sdd.cancel --audio` | Feature name + cancellation reason (ask the user to state both, in that order) |
| `/sdd.backlog --audio` (with `add`) | The backlog item's title/description |
| `/sdd.reverse-eng --audio` (with `--focus`) | The `--focus` scope description (e.g. "focus on the payments module") |
| `/sdd.project --audio` | Free-form answers during the `sdd-project-wizard` interview |

Audio input is always an alternate way to provide text input — it never bypasses the command's normal checks.
