#!/bin/bash

NUM_STEP=4
CN=${1:-1} # flag to use mirror address of China
SOURCE_DIR=$(pwd)

printf "\033[1;32mStep[1/%d]\033[0m \033[1;33mCheck and Install Zsh\033[0m\n" $NUM_STEP
if ! command -v zsh &> /dev/null; then
    echo "zsh not found. Installing zsh..."
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
else
    echo "zsh is already installed"
fi

printf "\033[1;32mStep[2/%d]\033[0m \033[1;33mInstall oh-my-zsh\033[0m\n" $NUM_STEP
if [ ! -d "~/.oh-my-zsh" ]; then
    if [ $CN == '1' ]; then
        git clone https://gitee.com/oliverck/ohmyzsh.git ~/.oh-my-zsh
    else
        git clone https://github.com/ohmyzsh/ohmyzsh.git ~/.oh-my-zsh
    fi
else
    echo "oh-my-zsh is already installed ( | rm -rf ~/.oh-my-zsh | if you want to re-deploy)"
fi

printf "\033[1;32mStep[3/%d]\033[0m \033[1;33mInstall plugins of ZSH\033[0m\n" $NUM_STEP
cd ~/.oh-my-zsh/plugins
printf "\033[1;32mInstall plugin: zsh-autosuggestions\033[0m\n"
if [ ! -d "./zsh-autosuggestions" ]; then
    if [ $CN == '1' ]; then
        git clone https://gitee.com/oliverck/zsh-autosuggestions.git
    else
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
    # Get available shell programs from /etc/shells and remove comments
    available_shells=($(grep -v '^#' /etc/shells))

    # Check if "zsh" is in the list of available shells
    zsh_found=false
    for shell in "${available_shells[@]}"; do
        if [[ $shell == *"zsh"* ]]; then
            echo "zsh is available"
            chsh -s "$shell"
            echo "Set Zsh as the default shell"
            zsh_found=true
            break
        fi
    done

    # If zsh is not found, execute the specified program
    if [[ $zsh_found == false ]]; then
        echo "zsh not found in the system. Modifying the shell configuration file."
        echo "export SHELL=~/.local/bin/zsh" >> ~/.bashrc
        echo "exec ~/.local/bin/zsh -l" >> ~/.bashrc
        echo "Default shell updated in bashrc. Please restart the terminal to apply changes."
    fi
else
    echo "Default shell remains unchanged."
fi

printf "\033[1;32mzsh-anywhere installation finished.\033[0m\n"
printf "\033[1;32mThe default shell for the user is "
printf `echo $SHELL`
printf "\033[0m\n"

zsh
