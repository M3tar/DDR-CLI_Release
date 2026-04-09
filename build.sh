#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}"
CLI_DIR="${ROOT_DIR}/CLI"
BIN_DIR="${ROOT_DIR}/bin"
BIN_PATH="${BIN_DIR}/ddr"
RUN_SCRIPT="${ROOT_DIR}/scripts/ddr-run.sh"
ENV_EXAMPLE="${ROOT_DIR}/config/ddr.env.example"
ENV_FILE="${ROOT_DIR}/config/ddr.env"
SKILL_TEMPLATE="${ROOT_DIR}/Skills/SKILL.md.example"
SKILL_FILE="${ROOT_DIR}/Skills/SKILL.md"
GO_CACHE_DIR="${ROOT_DIR}/.gocache"
GO_MOD_CACHE_DIR="${ROOT_DIR}/.gomodcache"

log() {
  printf '[build] %s\n' "$*"
}

fail() {
  printf '[build] 错误: %s\n' "$*" >&2
  exit 1
}

usage() {
  cat <<EOF
用法:
  ./build.sh

作用:
  1. 检查 Go 环境和目录结构
  2. 在 CLI/ 下执行 go mod tidy
  3. 构建 bin/ddr
  4. 初始化 config/ddr.env（若不存在）
  5. 为 ddr 和 ddr-run.sh 设置执行权限
  6. 用 --help 做本地非联网验证
  7. 默认使用项目本地的 Go 缓存目录，避免依赖系统全局缓存权限
EOF
}

if [[ $# -gt 0 ]]; then
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage >&2
      exit 1
      ;;
  esac
fi

command -v go >/dev/null 2>&1 || fail "未检测到 go，请先安装 Go 后再运行。"

for required in \
  "${CLI_DIR}/go.mod" \
  "${CLI_DIR}/main.go" \
  "${RUN_SCRIPT}" \
  "${ENV_EXAMPLE}" \
  "${SKILL_TEMPLATE}"
do
  [[ -f "${required}" ]] || fail "缺少必要文件: ${required}"
done

log "Go 环境: $(go version)"
log "检查目录结构完成"

mkdir -p "${BIN_DIR}"
mkdir -p "${GO_CACHE_DIR}" "${GO_MOD_CACHE_DIR}"

export GOCACHE="${GO_CACHE_DIR}"
export GOMODCACHE="${GO_MOD_CACHE_DIR}"

log "执行 go mod tidy"
(
  cd "${CLI_DIR}"
  go mod tidy
)

log "构建 CLI 到 ${BIN_PATH}"
(
  cd "${CLI_DIR}"
  go build -o "${BIN_PATH}" .
)

chmod +x "${BIN_PATH}" "${RUN_SCRIPT}"
log "已设置执行权限"

if [[ ! -f "${ENV_FILE}" ]]; then
  cp "${ENV_EXAMPLE}" "${ENV_FILE}"
  log "已初始化配置文件: ${ENV_FILE}"
else
  log "检测到已有配置文件，跳过初始化: ${ENV_FILE}"
fi

escaped_root="$(printf '%s\n' "${ROOT_DIR}" | sed 's/[\/&]/\\&/g')"
sed "s|__DDR_RELEASE_ROOT__|${escaped_root}|g" "${SKILL_TEMPLATE}" > "${SKILL_FILE}"
log "已生成技能文件: ${SKILL_FILE}"

log "验证 bin/ddr --help"
"${BIN_PATH}" --help >/dev/null

log "验证 scripts/ddr-run.sh --help"
"${RUN_SCRIPT}" --help >/dev/null

cat <<EOF

[build] 构建完成

下一步:
1. 编辑配置文件:
   ${ENV_FILE}

2. 填入真实配置项:
   DDR_URL
   DDR_COMPANY_ID
   DDR_TOKEN
   DDR_INSECURE

3. 执行真实查询，例如:
   ./scripts/ddr-run.sh staff list --search 待离职员工 -f json

说明:
- 本脚本只做本地构建和初始化，不会主动联网访问 DDR 服务
- 如果你修改了 CLI 源码，可以再次运行 ./build.sh 重新构建
EOF
