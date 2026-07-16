# Reference: Fix Flags Detail

**Used by**: `/sdd.fix` flag docs.

## Flags and Options

| Flag | Description | Example |
|------|-------------|---------|
| `--file` | Read error from file | `/sdd.fix --file ./error.log` |
| `--dry-run` | Show fix plan without applying | `/sdd.fix --dry-run "error"` |
| `--batch` | One subagent per fix (prevents context exhaustion) | `/sdd.fix --batch` |
| `--code-only` | ⚠️ DANGEROUS: Fix code only | `/sdd.fix --code-only "error"` |
| `--layer` | ⚠️ DANGEROUS: Fix specific layer only | `/sdd.fix --layer technical "error"` |

> **Lazy-loaded**: When `--code-only` or `--layer` is present, Read `references/fix-dangerous-flags.md` before proceeding.

---
