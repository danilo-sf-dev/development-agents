#!/usr/bin/env bash
# guard-approved-tests.sh — Deterministic enforcement for approved tests (Gate 2.5)
#
# Soft layer: markdown rules in sdd.build / sdd-implementer (agent may ignore).
# Hard layer: this script — exit 1 blocks pre-commit, CI, and explicit checks.
#
# Usage:
#   guard-approved-tests.sh [check] [--root PATH] [--json] [--staged-only] [--feature DIR]
#   guard-approved-tests.sh snapshot [--root PATH] --feature DIR [--json]
#
# Exit codes:
#   0 — OK (no violation, or nothing to guard)
#   1 — violation (approved test file changed)
#   2 — configuration / usage error

set -euo pipefail

MODE="check"
PROJECT_ROOT="."
OUTPUT_JSON=false
STAGED_ONLY=false
FEATURE_DIR=""

usage() {
  cat <<'EOF'
Usage:
  guard-approved-tests.sh [check] [--root PATH] [--json] [--staged-only] [--feature DIR]
  guard-approved-tests.sh snapshot [--root PATH] --feature DIR [--json]

Environment:
  SDD_GUARD_SKIP=1   Emergency bypass (logs warning; do not use in CI)
EOF
}

log_err() { echo "$*" >&2; }

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    log_err "ERROR: required command not found: $1"
    exit 2
  }
}

normalize_path() {
  echo "$1" | tr '\\' '/'
}

iso_now() {
  date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u +"%Y-%m-%dT%H:%M:%S"
}

file_sha256() {
  local f="$1"
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$f" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$f" | awk '{print $1}'
  else
    require_cmd openssl
    openssl dgst -sha256 "$f" | awk '{print $2}'
  fi
}

find_manifests() {
  local wip_root="$1"
  local feature_filter="${2:-}"

  if [[ ! -d "$wip_root" ]]; then
    return 0
  fi

  if [[ -n "$feature_filter" ]]; then
    local manifest="$feature_filter/4-tests/tests-manifest.json"
    [[ -f "$manifest" ]] && echo "$manifest"
    return 0
  fi

  find "$wip_root" -mindepth 2 -maxdepth 2 -path '*/4-tests/tests-manifest.json' 2>/dev/null || true
}

manifest_is_locked() {
  local manifest="$1"
  [[ "$(jq -r '.status // "pending"' "$manifest")" == "approved" ]]
}

collect_changed_files() {
  local root="$1"
  local staged_only="$2"

  if [[ "$staged_only" == "true" ]]; then
    git -C "$root" diff --cached --name-only --diff-filter=ACMR 2>/dev/null || true
  else
    {
      git -C "$root" diff --name-only --diff-filter=ACMR 2>/dev/null || true
      git -C "$root" diff --cached --name-only --diff-filter=ACMR 2>/dev/null || true
    } | sort -u
  fi
}

path_in_list() {
  local needle="$1"
  local haystack="$2"
  local normalized_needle
  normalized_needle=$(normalize_path "$needle")
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    [[ "$(normalize_path "$line")" == "$normalized_needle" ]] && return 0
  done <<< "$haystack"
  return 1
}

add_violation() {
  local key="$1"
  local -n _arr="$2"
  local existing
  for existing in "${_arr[@]}"; do
    [[ "$existing" == "$key" ]] && return 0
  done
  _arr+=("$key")
}

run_snapshot() {
  require_cmd jq
  local manifest="$1"
  local root="$2"
  local tmp now sha file abs
  tmp=$(mktemp)
  cp "$manifest" "$tmp"
  now=$(iso_now)

  while IFS= read -r file; do
    [[ -z "$file" || "$file" == "null" ]] && continue
    file=$(normalize_path "$file")
    abs="$root/$file"
    if [[ ! -f "$abs" ]]; then
      log_err "ERROR: test file missing for snapshot: $file"
      rm -f "$tmp"
      exit 2
    fi
    sha=$(file_sha256 "$abs")
    jq --arg f "$file" --arg sha "$sha" --arg at "$now" \
      '.tests |= map(if .file == $f then . + {sha256: $sha, snapshotted_at: $at} else . end)' \
      "$tmp" > "${tmp}.next"
    mv "${tmp}.next" "$tmp"
  done < <(jq -r '.tests[].file' "$manifest")

  jq --arg at "$now" '. + {guard_snapshot_at: $at}' "$tmp" > "$manifest"
  rm -f "$tmp"

  if [[ "$OUTPUT_JSON" == "true" ]]; then
    jq -n --arg manifest "$manifest" --argjson count "$(jq '.tests | length' "$manifest")" \
      '{ok: true, mode: "snapshot", manifest: $manifest, files: $count}'
  else
    echo "OK snapshot: $(jq '.tests | length' "$manifest") test file(s) in $manifest"
  fi
}

run_check() {
  require_cmd jq
  local root="$1"
  local wip_root="$root/sdd/wip"
  local changed_files violations=() checked=0 manifest feature file stored_sha current_sha abs v

  changed_files=$(collect_changed_files "$root" "$STAGED_ONLY")

  while IFS= read -r manifest; do
    [[ -z "$manifest" ]] && continue
    manifest_is_locked "$manifest" || continue
    feature=$(jq -r '.feature // "unknown"' "$manifest")

    while IFS= read -r file; do
      [[ -z "$file" || "$file" == "null" ]] && continue
      file=$(normalize_path "$file")
      checked=$((checked + 1))

      if path_in_list "$file" "$changed_files"; then
        add_violation "$feature|$file|git-diff" violations
      fi

      stored_sha=$(jq -r --arg f "$file" '.tests[] | select(.file == $f) | .sha256 // empty' "$manifest")
      abs="$root/$file"
      if [[ -n "$stored_sha" && -f "$abs" ]]; then
        current_sha=$(file_sha256 "$abs")
        if [[ "$current_sha" != "$stored_sha" ]]; then
          add_violation "$feature|$file|hash-mismatch" violations
        fi
      fi
    done < <(jq -r '.tests[].file' "$manifest")
  done < <(find_manifests "$wip_root" "$FEATURE_DIR")

  if [[ ${#violations[@]} -gt 0 ]]; then
    if [[ "$OUTPUT_JSON" == "true" ]]; then
      printf '{ "ok": false, "mode": "check", "violations": ['
      local first=true feat reason
      for v in "${violations[@]}"; do
        IFS='|' read -r feat file reason <<< "$v"
        [[ "$first" == "true" ]] || printf ','
        first=false
        printf '{"feature":"%s","file":"%s","reason":"%s"}' "$feat" "$file" "$reason"
      done
      printf '], "remediation": "/sdd.test --refine" }\n'
    else
      echo "BLOCKED: approved test file(s) changed outside Gate 2.5 refine" >&2
      for v in "${violations[@]}"; do
        IFS='|' read -r feat file reason <<< "$v"
        echo "  - [$feat] $file ($reason)" >&2
      done
      echo "" >&2
      echo "Remediation: revert test changes, or run /sdd.test --refine for a new approval cycle." >&2
    fi
    exit 1
  fi

  if [[ "$OUTPUT_JSON" == "true" ]]; then
    jq -n --argjson checked "$checked" '{ok: true, mode: "check", files_checked: $checked, violations: []}'
  else
    echo "OK: no approved test violations (${checked} file(s) checked)"
  fi
}

# ── Parse args ────────────────────────────────────────────────────────────────

while [[ $# -gt 0 ]]; do
  case "$1" in
    check) MODE="check"; shift ;;
    snapshot) MODE="snapshot"; shift ;;
    --root) PROJECT_ROOT="${2:-}"; shift 2 ;;
    --json) OUTPUT_JSON=true; shift ;;
    --staged-only) STAGED_ONLY=true; shift ;;
    --feature)
      FEATURE_DIR="${2:-}"
      shift 2
      ;;
    -h|--help) usage; exit 0 ;;
    *) log_err "Unknown argument: $1"; usage; exit 2 ;;
  esac
done

if [[ "${SDD_GUARD_SKIP:-}" == "1" ]]; then
  log_err "WARN: SDD approved-tests guard skipped (SDD_GUARD_SKIP=1)"
  exit 0
fi

PROJECT_ROOT=$(cd "$PROJECT_ROOT" && pwd)

if [[ "$MODE" == "snapshot" ]]; then
  [[ -n "$FEATURE_DIR" ]] || { log_err "ERROR: snapshot requires --feature sdd/wip/<feature>"; exit 2; }
  [[ -f "$FEATURE_DIR/4-tests/tests-manifest.json" ]] || {
    log_err "ERROR: manifest not found: $FEATURE_DIR/4-tests/tests-manifest.json"
    exit 2
  }
  run_snapshot "$FEATURE_DIR/4-tests/tests-manifest.json" "$PROJECT_ROOT"
  exit 0
fi

if ! git -C "$PROJECT_ROOT" rev-parse --git-dir >/dev/null 2>&1; then
  if [[ "$OUTPUT_JSON" == "true" ]]; then
    echo '{"ok":true,"mode":"check","skipped":"not-a-git-repo"}'
  else
    echo "SKIP: not a git repository — guard not applicable"
  fi
  exit 0
fi

run_check "$PROJECT_ROOT"
