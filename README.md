# DDR CLI Release

这是一个可直接分发的 DDR CLI 发布包。

它分成两层：

- 源码和模板：保留在当前目录下，面向开发者
- 最终交付物：统一生成到 `output/`，面向最终用户

也就是说，普通使用者在拿到这个目录后，只需要：

1. 运行 `./build.sh`
2. 进入 `output/`
3. 填写 `output/config/ddr.env`
4. 开始使用 CLI 或接入 AI

## 演示视频

[点击查看 DDR CLI 演示视频](assets/demo/cli-demo.mp4)

## 源码区 vs output 交付区

可以把这个目录理解成两部分：

### 1. 源码区

源码区就是当前目录里这些内容：

- `CLI/`
- `scripts/`
- `config/`
- `Skills/`
- `Templates/`
- `build.sh`

它们的用途是：

- 让开发者继续维护 CLI 源码
- 让发布脚本有地方读取模板和脚本源文件
- 支撑 `./build.sh` 重新生成最终交付物

如果你是在开发、改代码、改模板，就操作源码区。

### 2. output 交付区

`output/` 是运行 `./build.sh` 后生成的最终用户目录。

它的用途是：

- 给普通用户直接使用 CLI
- 给 AI 平台直接接入 `SKILL.md`
- 作为最终交付产物打包或分发

如果你只是使用 CLI 或接入 AI，请优先进入 `output/`，不要直接使用源码区里的脚本和模板。

一句话理解：

- 改代码，看源码区
- 真正使用，看 `output/`

## 目录说明

- `CLI/`
  - Go CLI 源码目录
- `build.sh`
  - 一键构建和初始化脚本
- `config/ddr.env.example`
  - 配置模板源码
- `scripts/ddr-run.sh`
  - 运行脚本源码
- `Skills/SKILL.md.example`
  - skill 模板源码
- `output/`
  - `./build.sh` 生成的最终交付目录

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
3. 重建 `output/` 交付目录
4. 构建 `output/bin/ddr`
5. 复制 `output/scripts/ddr-run.sh`
6. 初始化 `output/config/ddr.env`
7. 生成 `output/Skills/SKILL.md`
8. 生成 `output/README.md`
9. 用 `--help` 做本地非联网验证

说明：

- `build.sh` 不会主动访问真实 DDR 服务
- `output/config/ddr.env` 如果已存在，会被保留，不会覆盖

## 第二步：填写配置

进入：

```bash
cd output
```

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
DDR_INSECURE=true
```

说明：

- `DDR_TOKEN` 支持 3 种写法：
  - `DDR_TOKEN=abc123`
  - `DDR_TOKEN='Token abc123'`
  - `DDR_TOKEN='SERVAL abc123'`
- openapi 请求会按以下规则发送 `Authorization`：
  - 裸值 `abc123` -> `Authorization: Token abc123`
  - 显式 `Token abc123` -> 原样发送
  - 显式 `SERVAL abc123` -> 原样发送
- 如果在 `ddr.env` 里直接填写 `Token ...` 或 `SERVAL ...`，因为会被 shell `source`，带空格的值必须加引号
- 对很多内网、自签名或证书链不规范的 DDR 环境，建议默认保持 `DDR_INSECURE=true`
- 如果你的目标环境证书链完全正常，再改成 `false`

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

如果你只想用命令行，不需要 AI，那么只需要 `output/` 里的内容：

- `output/bin/ddr`
- `output/config/ddr.env`
- `output/scripts/ddr-run.sh`

常规流程就是：

```bash
./build.sh
cd ./output
vim ./config/ddr.env
./scripts/ddr-run.sh staff list -f json
```

## 需要 AI 自然语言接入的用户

如果你希望让 AI 直接通过自然语言查询 DDR，需要继续使用 `output/Skills/SKILL.md`。

### `Skills/SKILL.md` 是怎么来的

运行 `./build.sh` 后，会自动把源码模板：

```bash
Skills/SKILL.md.example
```

复制并转换成：

```bash
output/Skills/SKILL.md
```

区别是：

- `SKILL.md.example` 是模板
- `SKILL.md` 是当前机器可直接使用的版本
- 其中的命令路径会自动替换成你当前这台机器上的绝对路径

### 如何给 AI 使用这个 skill

常见有两种方式：

1. 直接把 `output/Skills/SKILL.md` 复制到 AI 的 skill 目录
2. 如果 AI 支持读取项目内 skill，也可以直接引用这个文件

例如某些环境会使用：

```bash
~/.agents/skills/ddr-manager/SKILL.md
```

如果需要手动复制，可以这样做：

```bash
mkdir -p ~/.agents/skills/ddr-manager
cp ./output/Skills/SKILL.md ~/.agents/skills/ddr-manager/SKILL.md
```

### AI 实际会调用什么

这个 skill 的核心目标是让 AI 调用 `output/` 下的运行脚本：

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
