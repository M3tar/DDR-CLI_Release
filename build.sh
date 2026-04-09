#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}"
CLI_DIR="${ROOT_DIR}/CLI"
SOURCE_RUN_SCRIPT="${ROOT_DIR}/scripts/ddr-run.sh"
SOURCE_ENV_EXAMPLE="${ROOT_DIR}/config/ddr.env.example"
SKILL_TEMPLATE="${ROOT_DIR}/Skills/SKILL.md.example"
OUTPUT_README_TEMPLATE="${ROOT_DIR}/Templates/output.README.md.example"
GO_CACHE_DIR="${ROOT_DIR}/.gocache"
GO_MOD_CACHE_DIR="${ROOT_DIR}/.gomodcache"
OUTPUT_DIR="${ROOT_DIR}/output"
OUTPUT_BIN_DIR="${OUTPUT_DIR}/bin"
OUTPUT_BIN_PATH="${OUTPUT_BIN_DIR}/ddr"
OUTPUT_SCRIPTS_DIR="${OUTPUT_DIR}/scripts"
OUTPUT_RUN_SCRIPT="${OUTPUT_SCRIPTS_DIR}/ddr-run.sh"
OUTPUT_CONFIG_DIR="${OUTPUT_DIR}/config"
OUTPUT_ENV_EXAMPLE="${OUTPUT_CONFIG_DIR}/ddr.env.example"
OUTPUT_ENV_FILE="${OUTPUT_CONFIG_DIR}/ddr.env"
OUTPUT_SKILLS_DIR="${OUTPUT_DIR}/Skills"
OUTPUT_SKILL_FILE="${OUTPUT_SKILLS_DIR}/SKILL.md"
OUTPUT_README="${OUTPUT_DIR}/README.md"

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
  3. 生成统一的 output/ 交付目录
  4. 构建 output/bin/ddr
  5. 初始化 output/config/ddr.env（若不存在）
  6. 生成 output/Skills/SKILL.md
  7. 用 --help 做本地非联网验证
  8. 默认使用项目本地的 Go 缓存目录，避免依赖系统全局缓存权限
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
  "${SOURCE_RUN_SCRIPT}" \
  "${SOURCE_ENV_EXAMPLE}" \
  "${SKILL_TEMPLATE}" \
  "${OUTPUT_README_TEMPLATE}"
do
  [[ -f "${required}" ]] || fail "缺少必要文件: ${required}"
done

log "Go 环境: $(go version)"
log "检查目录结构完成"

mkdir -p "${GO_CACHE_DIR}" "${GO_MOD_CACHE_DIR}"
mkdir -p "${OUTPUT_BIN_DIR}" "${OUTPUT_SCRIPTS_DIR}" "${OUTPUT_CONFIG_DIR}" "${OUTPUT_SKILLS_DIR}"

export GOCACHE="${GO_CACHE_DIR}"
export GOMODCACHE="${GO_MOD_CACHE_DIR}"

log "执行 go mod tidy"
(
  cd "${CLI_DIR}"
  go mod tidy
)

log "构建 CLI 到 ${OUTPUT_BIN_PATH}"
(
  cd "${CLI_DIR}"
  go build -o "${OUTPUT_BIN_PATH}" .
)

cp "${SOURCE_RUN_SCRIPT}" "${OUTPUT_RUN_SCRIPT}"
cp "${SOURCE_ENV_EXAMPLE}" "${OUTPUT_ENV_EXAMPLE}"
chmod +x "${OUTPUT_BIN_PATH}" "${OUTPUT_RUN_SCRIPT}"
log "已刷新 output/ 下的可执行文件与脚本"

if [[ ! -f "${OUTPUT_ENV_FILE}" ]]; then
  cp "${OUTPUT_ENV_EXAMPLE}" "${OUTPUT_ENV_FILE}"
  log "已初始化配置文件: ${OUTPUT_ENV_FILE}"
else
  log "检测到已有配置文件，已保留: ${OUTPUT_ENV_FILE}"
fi

escaped_output_root="$(printf '%s\n' "${OUTPUT_DIR}" | sed 's/[\/&]/\\&/g')"
sed "s|__DDR_RELEASE_ROOT__|${escaped_output_root}|g" "${SKILL_TEMPLATE}" > "${OUTPUT_SKILL_FILE}"
log "已生成技能文件: ${OUTPUT_SKILL_FILE}"

sed "s|__DDR_OUTPUT_ROOT__|${escaped_output_root}|g" "${OUTPUT_README_TEMPLATE}" > "${OUTPUT_README}"
log "已生成交付说明: ${OUTPUT_README}"

log "验证 output/bin/ddr --help"
"${OUTPUT_BIN_PATH}" --help >/dev/null

log "验证 output/scripts/ddr-run.sh --help"
"${OUTPUT_RUN_SCRIPT}" --help >/dev/null

cat <<EOF

[build] 构建完成

下一步:
1. 进入 output 目录:
   cd ${OUTPUT_DIR}

2. 编辑配置文件:
   ${OUTPUT_ENV_FILE}

3. 填入真实配置项:
   DDR_URL
   DDR_COMPANY_ID
   DDR_TOKEN
   DDR_INSECURE

4. 执行真实查询，例如:
   ./scripts/ddr-run.sh staff list --search 待离职员工 -f json

说明:
- 本脚本会重建 output/ 下的大多数交付物
- output/config/ddr.env 会保留，不会被覆盖
- 本脚本不会主动联网访问 DDR 服务
- 如果你修改了 CLI 源码，可以再次运行 ./build.sh 重新构建
EOF
