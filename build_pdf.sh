#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./build_pdf.sh [target.tex]

Examples:
  ./build_pdf.sh
  ./build_pdf.sh main.tex
EOF
}

require_command() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    printf 'error: required command not found: %s\n' "$cmd" >&2
    exit 1
  fi
}

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
TARGET_TEX="${1:-main.tex}"

if [[ "${TARGET_TEX}" == "-h" || "${TARGET_TEX}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ "${TARGET_TEX}" != *.tex ]]; then
  printf 'error: target must be a .tex file: %s\n' "${TARGET_TEX}" >&2
  usage >&2
  exit 1
fi

if [[ "${TARGET_TEX}" = /* ]]; then
  TARGET_PATH="${TARGET_TEX}"
else
  TARGET_PATH="${SCRIPT_DIR}/${TARGET_TEX}"
fi

if [[ ! -f "${TARGET_PATH}" ]]; then
  printf 'error: tex file not found: %s\n' "${TARGET_PATH}" >&2
  exit 1
fi

TARGET_DIR="$(cd -- "$(dirname -- "${TARGET_PATH}")" && pwd)"
TARGET_FILE="$(basename -- "${TARGET_PATH}")"
JOB_NAME="${TARGET_FILE%.tex}"

cd "${TARGET_DIR}"

if command -v latexmk >/dev/null 2>&1; then
  latexmk -file-line-error -interaction=nonstopmode "${TARGET_FILE}"
elif command -v ptex2pdf >/dev/null 2>&1; then
  ptex2pdf -u -l "${TARGET_FILE}"
else
  require_command uplatex
  require_command dvipdfmx

  uplatex -interaction=nonstopmode -halt-on-error "${TARGET_FILE}"

  if [[ -f "${JOB_NAME}.aux" ]] && grep -q '^\\bibdata' "${JOB_NAME}.aux"; then
    require_command upbibtex
    upbibtex "${JOB_NAME}"
  fi

  if [[ -f "${JOB_NAME}.idx" ]] && command -v mendex >/dev/null 2>&1; then
    mendex -U "${JOB_NAME}.idx"
  fi

  uplatex -interaction=nonstopmode -halt-on-error "${TARGET_FILE}"
  uplatex -interaction=nonstopmode -halt-on-error "${TARGET_FILE}"
  dvipdfmx "${JOB_NAME}.dvi"
fi

PDF_PATH="${TARGET_DIR}/${JOB_NAME}.pdf"

if [[ ! -f "${PDF_PATH}" ]]; then
  printf 'error: pdf was not generated: %s\n' "${PDF_PATH}" >&2
  exit 1
fi

printf 'generated: %s\n' "${PDF_PATH}"
