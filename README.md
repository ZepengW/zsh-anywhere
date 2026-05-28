# zsh-anywhere

一个命令在任意机器安装/更新 zsh + oh-my-zsh，并按配置文件生成预置 `.zshrc`。

## 功能

- 自动检测 zsh，支持包管理器安装，失败后回退源码安装
- 自动安装/更新 oh-my-zsh（支持 global/cn 镜像策略）
- 按配置安装第三方插件（可配置插件仓库地址）
- 动态生成 `.zshrc`（主题、插件列表可配置）
- 可选择是否切换默认 shell 到 zsh

---

## 快速开始

```bash
git clone https://github.com/oliverck/zsh-anywhere.git
cd zsh-anywhere
bash zsh-anywhere.sh
```

兼容旧参数：

- `bash zsh-anywhere.sh 1`：使用 CN 镜像策略（默认）
- `bash zsh-anywhere.sh 0`：使用 global 镜像策略

---

## 配置化部署（推荐）

默认配置文件：`./configs/zsh-anywhere.conf`

可复制并自定义：

```bash
cp ./configs/zsh-anywhere.conf ./my-zsh.conf
bash zsh-anywhere.sh --config ./my-zsh.conf
```

支持参数：

- `--config FILE`：指定配置文件
- `--mirror cn|global`：覆盖配置文件中的镜像策略
- `--yes`：非交互模式（默认问题自动 yes）
- `-h, --help`：查看帮助

---

## 关键配置项说明

请查看 `configs/zsh-anywhere.conf`，其中已包含完整注释。重点字段：

- `MIRROR_MODE`：`cn` / `global`
- `AUTO_CONFIRM`：是否无交互
- `INSTALL_ZSH_IF_MISSING`：缺少 zsh 时是否自动安装
- `UPDATE_EXISTING_REPOS`：已存在仓库是否 `git pull`
- `SET_DEFAULT_SHELL_PROMPT`：是否询问切换默认 shell
- `ZSH_THEME`：默认主题
- `OMZ_PLUGINS`：oh-my-zsh 内置插件
- `THIRD_PARTY_PLUGINS`：第三方插件安装清单（含地址）
- `ZSHRC_TEMPLATE` / `ZSHRC_TARGET`：模板与目标文件路径

---

## 插件配置策略建议

- 内置插件放在 `OMZ_PLUGINS`（如 `git`、`docker`）
- 第三方插件放在 `THIRD_PARTY_PLUGINS`，统一由脚本安装到 `~/.oh-my-zsh/custom/plugins`
- 需要替换插件源地址时，只改配置文件，不改脚本

---

## 常见问题

### 网络问题/镜像问题

- 可用 `--mirror global` 切换到 GitHub 源
- 可在配置文件中直接替换 `OH_MY_ZSH_REPO_*` 或插件仓库地址

### 不想改默认 shell

设置 `SET_DEFAULT_SHELL_PROMPT="false"`，或运行时在提示里选择 `n`。
