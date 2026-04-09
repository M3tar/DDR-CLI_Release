# DDR CLI Release

这是一个可直接分发的 DDR CLI 发布包。

它的目标是让使用者在拿到这个目录后，不需要理解生成器、模板和 OpenAPI 细节，只需要：

1. 运行 `./build.sh`
2. 填写 `config/ddr.env`
3. 开始使用 CLI

如果需要，还可以继续把 `Skills/SKILL.md` 接入 AI，实现自然语言查询。

## 目录说明

- `CLI/`
  - Go CLI 源码目录
- `build.sh`
  - 一键构建和初始化脚本
- `bin/`
  - 构建后的可执行文件输出目录
- `config/ddr.env.example`
  - 配置模板
- `config/ddr.env`
  - 运行时配置文件，首次构建后会自动生成
- `scripts/ddr-run.sh`
  - CLI 运行入口脚本
- `Skills/SKILL.md.example`
  - skill 模板文件
- `Skills/SKILL.md`
  - 构建后自动生成的 skill 文件，路径会替换成当前机器的绝对路径

## 前提条件

你需要本机安装：

- `go`

检查命令：

```bash
go version
```

## 第一步：构建和初始化

进入当前目录后执行：

```bash
./build.sh
```

这个脚本会自动完成：

1. 检查 Go 环境
2. 在 `CLI/` 下执行 `go mod tidy`
3. 构建 `bin/ddr`
4. 初始化 `config/ddr.env`
5. 给 `bin/ddr` 和 `scripts/ddr-run.sh` 增加执行权限
6. 生成 `Skills/SKILL.md`
7. 用 `--help` 做本地非联网验证

说明：

- `build.sh` 不会主动访问真实 DDR 服务
- 它只负责把本地运行环境准备好

## 第二步：填写配置

编辑：

```bash
config/ddr.env
```

需要填写：

- `DDR_URL`
- `DDR_COMPANY_ID`
- `DDR_TOKEN`
- `DDR_INSECURE`

示例：

```env
DDR_URL=https://127.0.0.1:8443/openapi
DDR_COMPANY_ID=your-company-id
DDR_TOKEN=your-token
DDR_INSECURE=false
```

## 第三步：确认 CLI 可用

查看帮助：

```bash
./bin/ddr --help
./scripts/ddr-run.sh --help
./scripts/ddr-run.sh staff --help
./scripts/ddr-run.sh device --help
```

## 第四步：执行真实查询

查询员工列表：

```bash
./scripts/ddr-run.sh staff list --search 待离职员工 -f json
```

查询设备详情：

```bash
./scripts/ddr-run.sh device detail --device-id <设备ID>
```

审批操作：

```bash
./scripts/ddr-run.sh approval instance_action \
  --instance-id <审批ID> \
  --approval-status approved \
  --opinions 同意
```

## 只使用 CLI 的用户

如果你只想用命令行，不需要 AI，那么只需要这几样：

- `build.sh`
- `config/ddr.env`
- `bin/ddr`
- `scripts/ddr-run.sh`

常规流程就是：

```bash
./build.sh
vim ./config/ddr.env
./scripts/ddr-run.sh staff list -f json
```

## 需要 AI 自然语言接入的用户

如果你希望让 AI 直接通过自然语言查询 DDR，需要继续使用 `Skills/SKILL.md`。

### `Skills/SKILL.md` 是怎么来的

运行 `./build.sh` 后，会自动把：

```bash
Skills/SKILL.md.example
```

复制并转换成：

```bash
Skills/SKILL.md
```

区别是：

- `SKILL.md.example` 是模板
- `SKILL.md` 是当前机器可直接使用的版本
- 其中的命令路径会自动替换成你当前这台机器上的绝对路径

### 如何给 AI 使用这个 skill

常见有两种方式：

1. 直接把 `Skills/SKILL.md` 复制到 AI 的 skill 目录
2. 如果 AI 支持读取项目内 skill，也可以直接引用这个文件

例如某些环境会使用：

```bash
~/.agents/skills/ddr-manager/SKILL.md
```

如果需要手动复制，可以这样做：

```bash
mkdir -p ~/.agents/skills/ddr-manager
cp ./Skills/SKILL.md ~/.agents/skills/ddr-manager/SKILL.md
```

### AI 实际会调用什么

这个 skill 的核心目标是让 AI 调用：

```bash
./scripts/ddr-run.sh <ddr子命令> [参数...]
```

例如：

```bash
./scripts/ddr-run.sh staff list --search 待离职员工 -f json
```

### 自然语言联调建议

建议先这样提问：

```text
请按 ddr-manager skill 来查：查询待离职员工，返回 JSON，并告诉我你准备执行的命令
```

这样可以先确认两件事：

1. AI 是否选对了 DDR 命令
2. AI 是否真的在调用 `ddr-run.sh`

## 关于提权

如果 AI 当前会话需要真实访问 DDR 服务，可能会涉及提权执行。

建议规则：

- 如果当前会话已经具备权限，直接执行
- 如果当前会话没有权限，再请求你批准这一次命令
- 默认按单次确认处理，不假设长期授权

如果当前 AI 平台根本不支持提权，那么正确方式是：

1. 让 AI 先生成准确命令
2. 你在本机终端执行
3. 再把返回结果交给 AI 总结

## 常见问题

### 1. `./build.sh` 报错找不到 `go`

说明本机没有安装 Go，先安装 Go 再运行。

### 2. `./build.sh` 成功了，但真实查询失败

这通常不是构建问题，而是以下原因之一：

- `config/ddr.env` 里的参数不对
- `DDR_TOKEN` 已失效
- 目标环境需要 `DDR_INSECURE=true`
- 当前网络无法访问 DDR 服务

### 3. `Skills/SKILL.md` 为什么不是手写维护的

因为这个发布包需要适配不同机器上的实际路径。  
模板文件保留为 `SKILL.md.example`，构建时再生成当前机器可用的 `SKILL.md`，更稳。
