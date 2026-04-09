#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
BIN="${ROOT_DIR}/bin/ddr"
ENV_FILE="${ROOT_DIR}/config/ddr.env"

usage() {
  cat <<EOF
用法:
  ddr-run.sh [-c <env文件路径>] <ddr子命令> [参数...]

示例:
  ddr-run.sh device detail --device-id xxx
  ddr-run.sh -c ${ROOT_DIR}/config/ddr.env staff list
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -c|--config)
      if [[ $# -lt 2 ]]; then
        echo "缺少配置文件路径" >&2
        usage >&2
        exit 1
      fi
      ENV_FILE="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      break
      ;;
  esac
done

if [[ $# -lt 1 ]]; then
  usage >&2
  exit 1
fi

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "缺少配置文件: ${ENV_FILE}" >&2
  exit 1
fi

if [[ ! -x "${BIN}" ]]; then
  echo "缺少可执行文件或无执行权限: ${BIN}" >&2
  exit 1
fi

source "${ENV_FILE}"

args=(--url "${DDR_URL}" --company-id "${DDR_COMPANY_ID}" --token "${DDR_TOKEN}")
insecure_value="${DDR_INSECURE:-false}"
insecure_value="$(printf '%s' "${insecure_value}" | tr '[:upper:]' '[:lower:]')"
if [[ "${insecure_value}" == "true" || "${insecure_value}" == "1" || "${insecure_value}" == "yes" ]]; then
  args+=(--insecure)
fi

exec "${BIN}" "${args[@]}" "$@"
