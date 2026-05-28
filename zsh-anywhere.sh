#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

CONFIG_FILE="$SCRIPT_DIR/configs/zsh-anywhere.conf"
MIRROR_MODE_OVERRIDE=""
AUTO_CONFIRM_OVERRIDE=""

print_help() {
  cat <<'USAGE'
Usage: sh zsh-anywhere.sh [0|1] [--config FILE] [--mirror cn|global] [--yes]

Options:
  0                     Use global mirror (compatibility mode)
  1                     Use CN mirror (compatibility mode, default)
  --config FILE         Use custom configuration file
  --mirror MODE         Force mirror mode: cn or global
  --yes                 Non-interactive mode, auto confirm prompts
  -h, --help            Show this help message
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    0)
      MIRROR_MODE_OVERRIDE="global"
      shift
      ;;
    1)
      MIRROR_MODE_OVERRIDE="cn"
      shift
      ;;
    --config)
      CONFIG_FILE="$2"
      shift 2
      ;;
    --mirror)
      MIRROR_MODE_OVERRIDE="$2"
      shift 2
      ;;
    --yes)
      AUTO_CONFIRM_OVERRIDE="true"
      shift
      ;;
    -h|--help)
      print_help
      exit 0
      ;;
    *)
      echo "Unknown argument: $1"
      print_help
      exit 1
      ;;
  esac
done

# Defaults (can be overwritten by config)
MIRROR_MODE="cn"
AUTO_CONFIRM="false"
INSTALL_ZSH_IF_MISSING="true"
SET_DEFAULT_SHELL_PROMPT="true"
UPDATE_EXISTING_REPOS="true"

OH_MY_ZSH_REPO_GLOBAL="https://github.com/ohmyzsh/ohmyzsh.git"
OH_MY_ZSH_REPO_CN="https://gitee.com/mirrors/oh-my-zsh.git"
ZSH_SOURCE_URL_GLOBAL="https://sourceforge.net/projects/zsh/files/latest/download"
ZSH_SOURCE_URL_CN="https://sourceforge.net/projects/zsh/files/latest/download"

ZSH_THEME="robbyrussell"
OMZ_PLUGINS=(git)
THIRD_PARTY_PLUGINS=(
  "zsh-autosuggestions|https://github.com/zsh-users/zsh-autosuggestions.git|https://gitee.com/mirrors/zsh-autosuggestions.git"
  "zsh-syntax-highlighting|https://github.com/zsh-users/zsh-syntax-highlighting.git|"
)

ZSHRC_TEMPLATE="$SCRIPT_DIR/configs/.zshrc"
ZSHRC_TARGET="$HOME/.zshrc"

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "Config file not found: $CONFIG_FILE"
  exit 1
fi

# shellcheck disable=SC1090
source "$CONFIG_FILE"

if [[ -n "$MIRROR_MODE_OVERRIDE" ]]; then
  MIRROR_MODE="$MIRROR_MODE_OVERRIDE"
fi

if [[ -n "$AUTO_CONFIRM_OVERRIDE" ]]; then
  AUTO_CONFIRM="$AUTO_CONFIRM_OVERRIDE"
fi

is_true() {
  case "${1,,}" in
    1|true|yes|y|on) return 0 ;;
    *) return 1 ;;
  esac
}

confirm() {
  local message="$1"

  if is_true "$AUTO_CONFIRM"; then
    return 0
  fi

  read -r -p "$message (y/n): " choice
  [[ "${choice,,}" == "y" || "${choice,,}" == "yes" ]]
}

log_step() {
  local current="$1"
  local total="$2"
  local message="$3"
  printf "\033[1;32mStep[%s/%s]\033[0m \033[1;33m%s\033[0m\n" "$current" "$total" "$message"
}

pick_url() {
  local global_url="$1"
  local cn_url="$2"

  if [[ "$MIRROR_MODE" == "cn" ]] && [[ -n "$cn_url" ]]; then
    echo "$cn_url"
  else
    echo "$global_url"
  fi
}

pick_fallback_url() {
  local global_url="$1"
  local cn_url="$2"

  if [[ "$MIRROR_MODE" == "cn" ]]; then
    echo "$global_url"
  else
    echo "$cn_url"
  fi
}

clone_or_update_repo() {
  local target_dir="$1"
  local primary_url="$2"
  local fallback_url="$3"

  if [[ -d "$target_dir/.git" ]]; then
    echo "Repository already exists: $target_dir"
    if is_true "$UPDATE_EXISTING_REPOS"; then
      echo "Updating: $target_dir"
      git -C "$target_dir" pull --ff-only || echo "Warning: failed to update $target_dir"
    fi
    return 0
  fi

  echo "Cloning from: $primary_url"
  if git clone "$primary_url" "$target_dir"; then
    return 0
  fi

  if [[ -n "$fallback_url" ]] && [[ "$fallback_url" != "$primary_url" ]]; then
    echo "Primary clone failed, retry from fallback: $fallback_url"
    git clone "$fallback_url" "$target_dir"
  else
    return 1
  fi
}

try_install_zsh_with_package_manager() {
  if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update && sudo apt-get install -y zsh && return 0
  elif command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y zsh && return 0
  elif command -v yum >/dev/null 2>&1; then
    sudo yum install -y zsh && return 0
  elif command -v pacman >/dev/null 2>&1; then
    sudo pacman -Sy --noconfirm zsh && return 0
  elif command -v zypper >/dev/null 2>&1; then
    sudo zypper --non-interactive install zsh && return 0
  elif command -v apk >/dev/null 2>&1; then
    sudo apk add zsh && return 0
  elif command -v brew >/dev/null 2>&1; then
    brew install zsh && return 0
  fi

  return 1
}

install_zsh_from_source() {
  local zsh_source_url
  local tmp_dir

  zsh_source_url=$(pick_url "$ZSH_SOURCE_URL_GLOBAL" "$ZSH_SOURCE_URL_CN")
  tmp_dir=$(mktemp -d)
  trap 'rm -rf "$tmp_dir"' EXIT

  echo "Downloading zsh source: $zsh_source_url"
  if command -v curl >/dev/null 2>&1; then
    curl -L "$zsh_source_url" -o "$tmp_dir/zsh.tar.xz"
  elif command -v wget >/dev/null 2>&1; then
    wget -O "$tmp_dir/zsh.tar.xz" "$zsh_source_url"
  else
    echo "Error: curl or wget is required to download zsh source."
    return 1
  fi

  tar -xf "$tmp_dir/zsh.tar.xz" -C "$tmp_dir"
  local source_dir
  source_dir=$(find "$tmp_dir" -maxdepth 1 -type d -name 'zsh-*' | head -n 1)

  if [[ -z "$source_dir" ]]; then
    echo "Error: zsh source extraction failed."
    return 1
  fi

  (
    cd "$source_dir"
    ./configure --prefix="$HOME/.local"
    make
    make install
  )

  if [[ -f "$HOME/.profile" ]] && ! grep -q "$HOME/.local/bin" "$HOME/.profile"; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.profile"
  fi
}

ensure_zsh_installed() {
  if command -v zsh >/dev/null 2>&1; then
    echo "zsh is already installed"
    return 0
  fi

  if ! is_true "$INSTALL_ZSH_IF_MISSING"; then
    echo "zsh is missing and INSTALL_ZSH_IF_MISSING=false"
    return 1
  fi

  if ! confirm "zsh is not installed. Install now?"; then
    echo "zsh installation aborted."
    return 1
  fi

  if try_install_zsh_with_package_manager; then
    echo "zsh installed via package manager"
    return 0
  fi

  echo "Package manager install unavailable or failed, fallback to source build"
  install_zsh_from_source
  echo "zsh installed from source"
}

ensure_oh_my_zsh() {
  local primary_url
  local fallback_url

  primary_url=$(pick_url "$OH_MY_ZSH_REPO_GLOBAL" "$OH_MY_ZSH_REPO_CN")
  fallback_url=$(pick_fallback_url "$OH_MY_ZSH_REPO_GLOBAL" "$OH_MY_ZSH_REPO_CN")

  if [[ -d "$HOME/.oh-my-zsh/.git" ]]; then
    clone_or_update_repo "$HOME/.oh-my-zsh" "$primary_url" "$fallback_url"
    return 0
  fi

  if ! confirm "oh-my-zsh is not installed. Install now?"; then
    echo "oh-my-zsh installation aborted."
    return 1
  fi

  clone_or_update_repo "$HOME/.oh-my-zsh" "$primary_url" "$fallback_url"
}

install_plugins() {
  local plugin_dir="$HOME/.oh-my-zsh/custom/plugins"
  local entry name global_url cn_url primary_url fallback_url

  mkdir -p "$plugin_dir"

  for entry in "${THIRD_PARTY_PLUGINS[@]}"; do
    IFS='|' read -r name global_url cn_url <<< "$entry"
    if [[ -z "$name" || -z "$global_url" ]]; then
      echo "Skip invalid plugin entry: $entry"
      continue
    fi

    primary_url=$(pick_url "$global_url" "$cn_url")
    fallback_url=$(pick_fallback_url "$global_url" "$cn_url")

    echo "Install plugin: $name"
    clone_or_update_repo "$plugin_dir/$name" "$primary_url" "$fallback_url"
  done
}

build_plugin_list() {
  local all_plugins=("${OMZ_PLUGINS[@]}")
  local entry name

  for entry in "${THIRD_PARTY_PLUGINS[@]}"; do
    IFS='|' read -r name _ <<< "$entry"
    if [[ -n "$name" ]]; then
      all_plugins+=("$name")
    fi
  done

  echo "${all_plugins[*]}"
}

escape_sed_replacement() {
  printf '%s' "$1" | sed -e 's/[\\/&]/\\&/g'
}

render_zshrc() {
  local plugins_string escaped_theme escaped_plugins

  if [[ ! -f "$ZSHRC_TEMPLATE" ]]; then
    echo "zshrc template not found: $ZSHRC_TEMPLATE"
    return 1
  fi

  plugins_string=$(build_plugin_list)
  escaped_theme=$(escape_sed_replacement "$ZSH_THEME")
  escaped_plugins=$(escape_sed_replacement "$plugins_string")

  sed \
    -e "s|__ZSH_THEME__|$escaped_theme|g" \
    -e "s|__ZSH_PLUGINS__|$escaped_plugins|g" \
    "$ZSHRC_TEMPLATE" > "$ZSHRC_TARGET"

  echo "Generated zshrc: $ZSHRC_TARGET"
}

try_set_default_shell() {
  local target_shell current_shell shell_name startup_file

  if ! is_true "$SET_DEFAULT_SHELL_PROMPT"; then
    return 0
  fi

  if ! confirm "Do you want to change the default shell to zsh?"; then
    echo "Default shell remains unchanged."
    return 0
  fi

  target_shell=$(command -v zsh || true)
  if [[ -z "$target_shell" ]]; then
    target_shell="$HOME/.local/bin/zsh"
  fi

  current_shell=$(getent passwd "$(whoami)" | cut -d: -f7)
  if [[ "$current_shell" == "$target_shell" ]]; then
    echo "Default shell is already zsh."
    return 0
  fi

  if command -v chsh >/dev/null 2>&1; then
    if chsh -s "$target_shell" "$(whoami)"; then
      echo "Default shell updated. Please re-login to apply."
      return 0
    fi
    echo "chsh failed, fallback to startup file bootstrap."
  fi

  shell_name=$(basename "$current_shell")
  startup_file=""
  case "$shell_name" in
    bash) startup_file="$HOME/.bashrc" ;;
    sh) startup_file="$HOME/.profile" ;;
    ksh) startup_file="$HOME/.kshrc" ;;
    fish) startup_file="$HOME/.config/fish/config.fish" ;;
    *)
      echo "Cannot detect startup file for shell: $shell_name"
      return 1
      ;;
  esac

  mkdir -p "$(dirname "$startup_file")"
  touch "$startup_file"

  if grep -q '### zsh-anywhere bootstrap ###' "$startup_file"; then
    echo "Bootstrap block already exists in $startup_file"
    return 0
  fi

  {
    echo ""
    echo "### zsh-anywhere bootstrap ###"
    echo "if [ -x \"$target_shell\" ]; then"
    echo "  exec \"$target_shell\""
    echo "fi"
  } >> "$startup_file"

  echo "Added zsh bootstrap to $startup_file"
}

main() {
  local total_steps=5

  if [[ "$MIRROR_MODE" != "cn" && "$MIRROR_MODE" != "global" ]]; then
    echo "Invalid MIRROR_MODE: $MIRROR_MODE (expected: cn/global)"
    exit 1
  fi

  log_step 1 "$total_steps" "Check and install zsh"
  ensure_zsh_installed

  log_step 2 "$total_steps" "Install or update oh-my-zsh"
  ensure_oh_my_zsh

  log_step 3 "$total_steps" "Install or update configured plugins"
  install_plugins

  log_step 4 "$total_steps" "Generate .zshrc from template"
  render_zshrc

  log_step 5 "$total_steps" "Set default shell (optional)"
  try_set_default_shell

  echo "Done. Open a new terminal to use your updated zsh environment."
}

main "$@"
