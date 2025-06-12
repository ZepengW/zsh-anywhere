#!/bin/bash

NUM_STEP=4
CN=${1:-1} # flag to use mirror address of China
SOURCE_DIR=$(pwd)

printf "\033[1;32mStep[1/%d]\033[0m \033[1;33mCheck and Install Zsh\033[0m\n" $NUM_STEP
if command -v zsh >/dev/null 2>&1; then
    echo "zsh is already installed"
else
    read -p "Zsh is not installed. Do you want to install it? (y/n): " choice
    if [ "$choice" != "y" ]; then
        echo "Zsh installation aborted."
        exit 1
    fi
    rm -r tmp
    mkdir tmp
    if [ $CN -eq 1 ]; then
        wget -c -O ./tmp/zsh.tar.xz https://sourceforge.net/projects/zsh/files/latest/download
    else
        wget -c -O ./tmp/zsh.tar.xz https://sourceforge.net/projects/zsh/files/latest/download
    fi
    cd tmp
    tar -xf zsh.tar.xz
    cd zsh-*
    ./configure --prefix=$HOME/.local
    make && make install
    source ~/.profile
    echo "zsh installed successfully!"
fi

printf "\033[1;32mStep[2/%d]\033[0m \033[1;33mInstall oh-my-zsh\033[0m\n" $NUM_STEP
if [-d "~/.oh-my-zsh" ]; then
    read -p "oh-my-zsh is not installed. Do you want to install it? (y/n): " choice
    if [ "$choice" != "y" ]; then
        echo "oh-my-zsh installation aborted."
        exit 1
    fi
    if [ $CN == '1' ]; then
        echo "clone from https://gitee.com/oliverck/ohmyzsh.git"
        git clone https://gitee.com/oliverck/ohmyzsh.git ~/.oh-my-zsh
    else
        echo "clone from https://github.com/ohmyzsh/ohmyzsh.git"
        git clone https://github.com/ohmyzsh/ohmyzsh.git ~/.oh-my-zsh
    fi
else
    echo "oh-my-zsh is already installed ( | rm -rf ~/.oh-my-zsh | if you want to re-deploy)"
fi

printf "\033[1;32mStep[3/%d]\033[0m \033[1;33mInstall plugins of ZSH\033[0m\n" $NUM_STEP
cd ~/.oh-my-zsh/plugins
printf "\033[1;32mInstall plugin: zsh-autosuggestions\033[0m\n"
if [-d "./zsh-autosuggestions" ]; then
    read -p "zsh-autosuggestions is not installed. Do you want to install it? (y/n): " choice
    if [ "$choice" != "y" ]; then
        echo "zsh-autosuggestions installation aborted."
        exit 1
    fi
    if [ $CN == '1' ]; then
        echo "clone from https://gitee.com/oliverck/zsh-autosuggestions.git"
        git clone https://gitee.com/oliverck/zsh-autosuggestions.git
    else
        echo "clone from https://github.com/zsh-users/zsh-autosuggestions.git"
        git clone https://github.com/zsh-users/zsh-autosuggestions.git
    fi
else
    echo "zsh-autosuggestions is already installed"
fi

printf "\033[1;32mStep[4/%d]\033[0m \033[1;33mConfig .zshrc\033[0m\n" $NUM_STEP
cd $SOURCE_DIR
cp ./configs/.zshrc ~/

read -p "Do you want to change the default shell to zsh? (y/n): " choice

if [ "$choice" = "y" ]; then
    TARGET_SHELL=$(command -v zsh)
    USER_NAME=$(whoami)
    CURRENT_SHELL=$(getent passwd "$USER_NAME" | cut -d: -f7)

    echo "当前默认 shell: $CURRENT_SHELL"
    echo "目标 shell: $TARGET_SHELL"

    # 如果当前默认 shell 已经是 zsh，直接退出
    if [ "$CURRENT_SHELL" == "$TARGET_SHELL" ]; then
        echo "默认 shell 已是 zsh，无需更改。"
        exit 0
    fi

    # 检查 chsh 命令是否可用
    if command -v chsh >/dev/null 2>&1; then
        echo "尝试使用 chsh 更改默认 shell..."

        # 尝试修改默认 shell（需要输入密码）
        if echo "$TARGET_SHELL" | sudo chsh -s "$TARGET_SHELL" "$USER_NAME"; then
            echo "chsh 设置成功，请重新登录以生效。"
            exit 0
        else
            echo "chsh 设置失败，尝试修改启动脚本..."
        fi
    else
        echo "系统不支持 chsh 或 chsh 不可用，尝试修改启动脚本..."
    fi

    # 如果不能用 chsh，则尝试在当前 shell 启动脚本中写入启动 zsh
    SHELL_NAME=$(basename "$CURRENT_SHELL")
    STARTUP_FILE=""

    case "$SHELL_NAME" in
        bash)
            STARTUP_FILE="$HOME/.bashrc"
            ;;
        sh)
            STARTUP_FILE="$HOME/.profile"
            ;;
        ksh)
            STARTUP_FILE="$HOME/.kshrc"
            ;;
        fish)
            STARTUP_FILE="$HOME/.config/fish/config.fish"
            ;;
        *)
            echo "无法识别当前 shell，手动配置 zsh 启动"
            exit 1
            ;;
    esac
    LOCAL_SHELL="~/.local/bin/zsh"
    # 添加 zsh 启动命令（避免重复添加）
    if grep -q "$LOCAL_SHELL" "$STARTUP_FILE"; then
        echo "$STARTUP_FILE 中已存在 zsh 启动命令。"
    else
        echo "添加 zsh 启动命令到 $STARTUP_FILE ..."
        echo -e "\n# 自动添加：切换到 zsh\nif [ -x \"$LOCAL_SHELL\" ]; then\n  exec $LOCAL_SHELL\nfi" >> "$STARTUP_FILE"
        echo "已添加。请重新打开终端以使用 zsh。"
    fi
else
    echo "Default shell remains unchanged."
fi


