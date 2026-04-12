#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./build_pdf_in_container.sh [--rebuild] [target.tex]

Examples:
  ./build_pdf_in_container.sh
  ./build_pdf_in_container.sh --rebuild
  ./build_pdf_in_container.sh main.tex
EOF
}

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="${PDF_BUILD_IMAGE:-torus-de-rham-cohomology-pdf-builder:latest}"
DOCKERFILE_PATH="${SCRIPT_DIR}/Dockerfile"
REBUILD=0
TARGET_TEX="main.tex"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --rebuild)
      REBUILD=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      if [[ "${TARGET_TEX}" != "main.tex" ]]; then
        printf 'error: too many arguments\n' >&2
        usage >&2
        exit 1
      fi
      TARGET_TEX="$1"
      shift
      ;;
  esac
done

if [[ "${TARGET_TEX}" != *.tex ]]; then
  printf 'error: target must be a .tex file: %s\n' "${TARGET_TEX}" >&2
  exit 1
fi

if [[ ! -f "${DOCKERFILE_PATH}" ]]; then
  printf 'error: dockerfile not found: %s\n' "${DOCKERFILE_PATH}" >&2
  exit 1
fi

if [[ ! -f "${SCRIPT_DIR}/${TARGET_TEX}" ]]; then
  printf 'error: tex file not found: %s\n' "${SCRIPT_DIR}/${TARGET_TEX}" >&2
  exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
  printf 'error: required command not found: docker\n' >&2
  exit 1
fi

if [[ "${REBUILD}" -eq 1 ]] || ! docker image inspect "${IMAGE_NAME}" >/dev/null 2>&1; then
  docker build -t "${IMAGE_NAME}" -f "${DOCKERFILE_PATH}" "${SCRIPT_DIR}"
fi

docker run --rm \
  --user "$(id -u):$(id -g)" \
  -e HOME=/tmp \
  -v "${SCRIPT_DIR}:/work" \
  -w /work \
  "${IMAGE_NAME}" \
  bash ./build_pdf.sh "${TARGET_TEX}"
